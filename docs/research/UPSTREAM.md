# Upstream source analysis

Baseline: Dejunk **3.5.1**, master snapshot
`04bafd5e411441ef5b51bb8ed10d208f2d7758f5`, inspected 2026-11-12.
The TOC lists 120107, 120105, 50504, 20506, 16001 and 11509, not 30300.
Historical Wrath Classic flags do not establish original-client support. With
missing WOW_PROJECT globals, direct nil == nil comparisons can even select
multiple project flags as true; the port must identify the build explicitly.
Immutable links and evidence anchors are in [SOURCES.md](SOURCES.md).

## UI framework adoption

The WotLK port vendors the upstream Waffle 0.12.2 layout engine from the pinned
Dejunk revision above at `libs/Waffle.lua`; SHA-256:
`bd668fb59160f4f9bc4b2b13298c7ca93cbad9be017892b21eac089a3015d396`.
Its MIT notice is preserved in `libs/Waffle-LICENSE.txt`. The engine is Lua
layout code and uses the legacy `CreateFrame` API. The WotLK shell currently uses
Waffle for the primary settings window; the upstream screens/components and
modern-only integration layers have not yet been ported. Do not claim complete
upstream UI parity or original-client compatibility until those stages pass.

## Existing architecture
| Source area | Observed responsibility | Port treatment |
| --- | --- | --- |
| Dejunk.xml, src/addon.lua | Library and module load order, module registry, project flags, character key | New minimal bootstrap and explicit TOC; GetBuildInfo, legacy metadata and realm APIs |
| src/blizzard/blizzard.lua | Partial game API facade; throws on missing APIs | Replace with complete original-client adapter; direct APIs still exist outside this facade upstream |
| src/events, src/utils/ticker-manager.lua | Event dispatch and custom OnUpdate scheduling | Preserve design; normalize legacy event arguments and debounce BAG_UPDATE ourselves |
| src/items | Slot cache, equipment sets, item metadata | Rewrite data acquisition; tuple APIs, localized class/subclass names, unknown states |
| src/junk-filter | Action-specific tri-state filters and reason strings | Pure evaluator with stable reason codes; add safety gate before parity rules |
| src/store, libs/Wux.lua | Reducer/actions, SavedVariables reconciliation and schema migrations | Small versioned port store; do not reuse upstream SavedVariables globals |
| src/lists | Four item-ID lists; async item parsing; text import/export | Keep validated IDs; no GetItemInfoInstant assumptions or text execution |
| src/services | Seller state machine, destroy confirmation, outcome tracking, repair | New transaction boundary with stale-intent cancellation and mocks first |
| src/ui, libs/Waffle.lua | Custom layout/widgets/screens, bag overlays, tooltip, minimap | Legacy native-frame UI; audit all methods/templates and bag mapping |
| src/input, Bindings.xml, DejunkApi.lua | Commands, bindings, public query/events | Explicit bindings, combat restrictions, documented port API |
| test | Lua harness, mocks, rule/store/service/UI tests | Useful scenario reference; modern API mocks are not WotLK validation |

## Exact decision order observed
The filter first validates the slot and action eligibility. It then checks:
1. Exclude above item level, then exclude above stack price.
2. Profile exclusions, profile inclusions, global exclusions, global inclusions.
3. Other exclusions: equipment sets, unbound equipment, retail warband equipment,
   equipment type, quest items.
4. Inclusions: quality, below item level, below stack price, equipment type,
   retail artifact relics.
5. No match means not junk. Zero/no vendor price prevents selling. Refundability
   is an additional selling blocker, separate from classification.

This is **not** an unconditional global-exclusion-wins policy: upstream profile
inclusions can beat global exclusions and quest/set exclusions. The port keeps
list precedence within ordinary classification, but places mandatory safety
protection first; this deliberate difference must be visible in the UI.
Price comparisons use the whole stack, in copper, with strict above/below
comparisons. Quality options cover poor through epic; equipment type rules have
special cases (for example cloaks do not match the type selection).

## Default filter settings observed in `src/store/default-states.lua`

- `includeByQuality` is enabled for `BOTH`, with only `poor=true`; this makes
  Poor-quality items the stock junk classification without user-created rules.
- `excludeEquipmentSets` and `excludeQuestItems` are enabled for `BOTH`.
- `autoSell`, `autoRepair`, and global `safeSell` are off; global `safeDestroy`
  is on. Inclusions/exclusions and equipment-type lists start empty.
- All other level, stack-price, unbound-equipment, and equipment-type filters
  start disabled. Retail warband and artifact-relic filters do not apply to
  WotLK; EquipmentSet and quest protections remain safety checks in the port.

The WotLK store now defaults quality index 0 (Poor) on for new profiles and
when a saved profile has no explicit value. A stored `false` is preserved as an
explicit user choice. This adopts the upstream default declaratively; no upstream
code is copied or executed. Other port safety behavior remains stricter where
the legacy client cannot prove binding, quest, lock, or refund state.

## Observed service behavior and risks
- Seller waits for bags to settle, sells one stack per tick, tracks attempted
  slots and cancels on merchant close. Safe Sell caps 12 calls when enabled.
  Upstream default Safe Sell is off; auto-sell and auto-repair are off.
- Repair is in the merchant handler and uses personal money. Guild-bank repair
  is not implemented there and is not a required parity feature.
- Destroyer acts on one stack. Safe Destroy defaults on. `handleItem` checks
  slot existence/lock **before** showing a popup; its acceptance callback calls
  `attemptDestroy` without repeating those checks. `attemptDestroy` clears the
  cursor, picks up by slot and calls DeleteCursorItem. Copying this flow would
  permit a changed slot/cursor to affect the wrong item.
- Items:IsItemStillInBags compares only item ID at the old slot. Same-ID changes
  in link/count are not adequately represented for transaction intent.
- Confirmer infers completion from an item no longer matching its old slot;
  a move alone is not proof of sale or deletion. The port must distinguish an
  attempted operation from observed evidence and an ambiguous result.

## Scope interpretation
“Custom rules” means configurable declarative predicates with SELL/DESTROY/BOTH
scope, quality masks and thresholds, plus ordered user rule groups planned in
Phase 3. Upstream does not provide an arbitrary Lua rule editor. The port will
not execute user-supplied code. Rule builder semantics are documented before UI.
Lootable-item frame, merchant button, commands, keybindings, list import/export,
profile lifecycle and public integration API are included in the parity backlog,
although not all were named individually in the request. Retail-only systems
(artifact relics, warband bank, addon compartment) have no WotLK equivalent and
will be documented as not applicable, without fake controls.
