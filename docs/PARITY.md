# Upstream Dejunk parity audit

Baseline: Dejunk 3.5.1 at immutable commit
[`04bafd5e411441ef5b51bb8ed10d208f2d7758f5`](https://github.com/moody/Dejunk/tree/04bafd5e411441ef5b51bb8ed10d208f2d7758f5),
target: original WoW 3.3.5a, build 12340, Interface 30300, Lua 5.1. This is a
source-to-source feature inventory, not a claim of client acceptance. “Covered
offline” means there is code and a mock/model test; it does not prove in-game
behavior. No row marked partial or missing should be read as complete parity.

## Status summary

- **Offline foundation present:** client/build gate, conservative legacy reads,
  schema-backed profiles/lists/options, rule evaluation, read-only previews,
  and isolated seller/repair/destroy simulation kernels.
- **UI partially ported:** a Waffle-hosted configuration shell, Lists, Profiles,
  Global Options and Profile Options. Many controls are port-specific substitutes;
  client appearance and input are not accepted as final parity.
- **Missing from the usable addon:** actual merchant/item actions, merchant
  button, minimap integration, bag icon overlays, keybindings and exact
  upstream command behavior. The read-only public API and AddOns category are
  implemented; tooltips, transport and item windows are partial.
- **Intentionally not applicable on 3.3.5a:** artifact relic handling, warband
  equipment/bank, and the Retail Addon Compartment integration.

## Feature-by-feature matrix

| Upstream feature | Reference implementation | Current port | Status / exact remaining work |
|---|---|---|---|
| Client support and initialization | `Dejunk.toc`, `src/addon.lua`, `src/blizzard/blizzard.lua` | `Dejunk-WotLK.toc`, `src/compat/client.lua`, `src/core/bootstrap.lua` | **Implemented offline, client unverified.** Explicit build 12340/interface guard, ordered TOC, event startup and fail-closed behavior exist. Confirm target-client startup and API evidence once as a consolidated compatibility check. |
| Event lifecycle and scheduling | `src/events/event-manager.lua`, `src/utils/ticker-manager.lua` | `src/core/events.lua`, `src/core/scheduler.lua`, `src/core/bootstrap.lua` | **Implemented foundation.** Dispatch, cancellation, coalescing and lifecycle tests exist. Upstream event-driven product services/UI are not all subscribed or connected. |
| Bag, item and equipment-set metadata | `src/items/items.lua`, `src/items/bag-items-cache.lua`, `src/items/equipment-sets-cache.lua`, `src/items/equipment-types.lua` | `src/compat/legacy.lua`, `src/compat/runtime.lua`, `src/core/bag-cache.lua` | **Partial.** Legacy tuples, bag-scope checks, cache invalidation, equipment sets, categories and tri-state binding probes are modeled. No full upstream `Items` facade/junkable/sellable/destroyable API; binding/localized category behavior and all in-client probes need verification. Additional bag addons are absent. |
| Junk filter and order | `src/junk-filter/junk-filter.lua`, `src/junk-filter/item-filters.lua` | `src/rules/evaluator.lua` | **Mostly modeled offline, not live-wired.** Default quality, scopes, thresholds, equipment categories and list precedence have fixtures. Differences/risks: unknown state handling is deliberately stricter; upstream sell blockers (refund/no value) are not the same as generic classification; missing full item facade and live junk cache mean no upstream decisions reach actions. Retail-only filters are correctly omitted. |
| Junk item cache and ordering | `src/junk-filter/junk-items-cache.lua` | `src/services/junk-items.lua`, bag snapshot | **Read-only projection implemented; cache/UI integration partial.** Valid snapshots produce a deterministically sorted combined sell/destroy candidate list with per-action decisions and counts. Unknown items stay excluded. It is rebuilt on request rather than maintained on events; blocked-sale counts, next-item selection and incremental UI updates remain. |
| Saved state, profiles and migration | `src/store/default-states.lua`, `src/store/migrations.lua`, `src/store/state-reconciler.lua`, `src/store/profile-summaries.lua` | `src/store/store.lua` | **Core present, exact migration parity incomplete.** Versioned SavedVariables, character profile mapping, CRUD, reset/delete protection, settings and list persistence exist. Need compare every upstream schema/migration and summary field against fixtures; no upstream state layer API parity is claimed. |
| Global and profile options | `src/ui/screens/main-window/options/global-options.lua`, `profile-options.lua` | `src/compat/runtime.lua:ShowOptions`, `src/ui/config.lua`, `src/store/store.lua` | **Settings largely modeled; integrations partial.** Many upstream Safety/Interface/Bags and General/Include/Exclude settings persist and render. Auto Junk/Lootable displays and bag tooltip reasons now work. Merchant button, minimap and bag icon overlays are missing; chat messages do not drive action events. Exact upstream OptionCard/SettingsBox/chip visuals and all interactions are not implemented. |
| Four item lists | `src/lists/lists.lua`, `src/lists/list-item-parser.lua` | `src/store/store.lua`, `src/compat/runtime.lua:ShowLists` | **Partially implemented.** Four persisted lists, validated IDs, name/ID filtering, cursor-item addition, right-click removal/transfers, previewed bulk import and transport export exist. The screen still has scope/type/ID/Add/Remove development controls rather than upstream list selection and card interactions; async parser states/progress and exact item-card behavior are missing. Search and transfers need final in-client confirmation. |
| Profile lifecycle | `src/ui/screens/main-window/options/profiles.lua`, `src/ui/components/profile-card.lua` | `src/compat/runtime.lua:ShowProfiles`, `src/store/store.lua` | **Core actions implemented; UI partial.** Activate/create/duplicate/rename/reset/delete target individual profiles; default protection and confirmation exist. The compact text buttons and custom modal are substitutes for upstream icon buttons and tooltip cards; layout/overlap and exact semantics still need one client acceptance pass. |
| Main window navigation and overview | `src/ui/screens/main-window/main-window.lua` | `src/compat/runtime.lua:ShowConfig` | **Partial.** Waffle main shell and four configuration screens work in UI fixtures; `/dejunk` toggles it, dragged position persists, and Junk/Lootable entry buttons open read-only lists. Main overview content still lacks upstream totals, footer segments and remaining sidebar/screen components. |
| Keybindings | `src/input/keybindings.lua`, `src/ui/components/keybinding-card.lua` | State field exists in `src/store/store.lua`; no screen/controller | **Missing.** No capture/listen UI, conflict resolution, saved WoW binding registration, override owner, action handlers or keybinding sidebar page. Need select legacy-compatible binding mechanism from 3.3.5 evidence before implementation. |
| Slash commands | `src/input/commands.lua` | `src/compat/runtime.lua:RegisterCommands`, `src/core/bootstrap.lua:app:Command` | **Partial.** `/dejunk` toggles the main window; `profiles` opens Profiles; `junk`/`loot` open read-only lists; `help` lists a safety-specific subset. `sell`/`destroy` remain disconnected. `/djw` exposes additional development commands; exact upstream argument/error semantics and seller/destroyer behavior remain. |
| Seller and safe sell | `src/services/seller.lua` | `src/services/seller.lua` (simulation only) | **Simulation only.** Attempt validation, stale-slot/session checks, observation and 12-item Safe Sell fixture exist. No live `UseContainerItem`, merchant open/close session, sale outcome UI/messages, auto-sell or seller controller. This is blocked from live wiring until code review and separate owner authorization under `AGENTS.md`. |
| Repair | Merchant handler in upstream service/event modules; `CanMerchantRepair`, `GetRepairAllCost`, `GetMoney`, `RepairAllItems` | `src/services/repair.lua` (simulation only) | **Simulation only.** Funds/cost/session checks are tested, but no merchant subscription/UI, automatic repair or live repair call. Same separate review/authorization gate applies. |
| Destroy, confirmer and Safe Destroy | `src/services/destroyer.lua`, `src/services/confirmer.lua` | `src/services/destroyer.lua` (simulation only) | **Simulation only.** One-stack intent, confirmation token, expiry and stale-state mock checks exist. No junk-frame button or live `PickupContainerItem`/`DeleteCursorItem` path. The live action must revalidate exact slot/link/count/cursor immediately before deletion; separate owner review/authorization is required. |
| Junk frame | `src/ui/screens/junk-frame.lua` | `runtime:ToggleJunkFrame`, `runtime:UpdateJunkFrame` | **Read-only display partial.** `/dejunk junk` opens a scrollable item-card list with quality accent, icon, separate SELL/DESTROY decisions and reasons; bag invalidation clears stale rows and updates reuse card widgets. Drag position persists. Blocked-sale explanations, transactional controls/progress/status and settings shortcut remain. Live actions remain disconnected. |
| Lootable frame | `src/ui/screens/lootable-frame.lua` | `src/services/lootable-items.lua`, `runtime:ShowLootableFrame` | **Read-only display partial.** `/dejunk loot` lists stacks positively marked lootable with item cards; saved auto-open option shows/hides this window on bag updates. Drag position persists, but it cannot click or ignore stacks. Using the item is intentionally left to the player's normal bag UI because legacy `UseContainerItem` can consume/equip. |
| Merchant button and merchant behavior | `src/ui/screens/merchant-button.lua` plus upstream service listeners | No equivalent | **Missing.** Saved option exists but there is no merchant-frame button, drag/position persistence, merchant-state refresh, or action integration. |
| Minimap icon | `src/ui/minimap-icon.lua` | Saved option only in store/options | **Missing.** No minimap button, drag angle, tooltip, click routing or persistence. Retail addon-compartment behavior is N/A. |
| Bag item icons and tooltips | `src/ui/item-icons.lua`, `src/ui/item-tooltip.lua`, `src/ui/tooltip.lua` | `runtime:RegisterBagTooltips`; item overlay absent | **Partial.** Default `GameTooltip:SetBagItem` adds SELL/DESTROY reasons using fresh legacy slot reads. Bag-button icons, size control, overlay cleanup, tooltip localization and third-party bag adapters remain missing. |
| Transport/import/export window | `src/ui/screens/transport-frame.lua`, `src/lists/list-item-parser.lua` | `runtime:ShowListImport` in import/export modes | **Partial.** Export now opens the shared transport window, fills comma-separated IDs and provides Select all for copying; import validates a preview before committing. List routing is based on the currently selected list. Window positioning/persistence, upstream parse progress and exact messaging remain different. |
| Public API and events | `DejunkApi.lua`, `src/events/events.lua` | `src/api.lua`, `app:ClassifySlot`, shared event bus | **Implemented for the read-only upstream surface; client unverified.** `DejunkApi:IsJunk` checks the current bag/slot, and removable listeners receive bag/state updates. It does not expose mutation or a lootable query absent from the pinned API. Offline tests cover classification, invalid coordinates, notification and unsubscription. |
| Blizzard AddOns options category | `src/ui/blizzard/addon-category.lua` | `runtime:RegisterOptionsCategory`, registered after login | **Implemented; client unverified.** Legacy `InterfaceOptions_AddCategory` provides Open Dejunk and Open Profiles entries. Junk-frame navigation waits for its upstream frame. |
| Localization and assets | `src/locales/*`, `src/ui` assets | Mostly hard-coded English and native controls | **Missing/partial.** English-only strings, no upstream icon artwork or tooltip localization. Upstream assets/code must be license-reviewed before reuse; independently recreating the visual components remains required for parity. |
| Retail-only integrations | Warband, artifact relic, addon compartment | Not present | **Not applicable to original 3.3.5a.** Omit rather than emulate. |

## Exact settings inventory

The following list prevents “options are done” from being inferred from the
presence of a screen. `Persisted` means the store validates and saves a value;
`rendered` means the current settings page exposes a control; neither means the
game integration works.

### Global settings

| Upstream setting | Store/UI state | Runtime behavior |
|---|---|---|
| Safe Destroy (default on) | Persisted and rendered | No live destruction path; not enforced against a game action. |
| Safe Sell (default off, 12-item session cap) | Persisted and rendered | Cap exists in simulation tests only; live seller is absent. |
| Merchant Button and saved position | Setting persisted/rendered | No button or drag/reset-position handling. |
| Minimap Icon | Setting persisted/rendered | No minimap icon. |
| Auto Junk Frame | Setting persisted/rendered | Automatically shows the read-only Junk window when a merchant opens and candidates exist; hides it at merchant close or when an auto-shown list becomes empty. No sale action is triggered. |
| Auto Lootable Frame | Setting persisted/rendered | Automatically shows/hides the read-only lootable list on bag updates; opening items is manual. |
| Chat Messages (enabled, Reduced/Verbose) | Values persisted/rendered | No sale/repair/destroy/loot message integration. |
| Bag Item Tooltips | Setting persisted/rendered | Legacy `GameTooltip:SetBagItem` hook adds live SELL/DESTROY status and evaluator reason lines when enabled. Client layout/localization remains unverified. |
| Bag Item Icons and Small/Large size | Values persisted/rendered | No bag button overlay or sizing integration. |

### Profile settings

| Upstream setting | Store/UI state | Runtime behavior |
|---|---|---|
| Auto Repair (default off) | Persisted/rendered | No merchant repair integration. |
| Auto Sell (default off) | Persisted/rendered | No merchant seller integration. |
| Include by Quality (Poor on by default; per quality and action scope) | Persisted/rendered | Used by read-only evaluator/previews only. |
| Include below item level (per quality/action scope) | Persisted/rendered | Used by evaluator/previews only. |
| Include below stack vendor price (copper/silver/gold; per quality/action scope) | Persisted/rendered | Used by evaluator/previews only. |
| Include by equipment type (armor/weapon subclass; quality/action scope) | Persisted/rendered | Used by evaluator/previews only; legacy localized category mapping needs client evidence. |
| Exclude above item level (per quality/action scope) | Persisted/rendered | Used by evaluator/previews only. |
| Exclude above stack vendor price (per quality/action scope) | Persisted/rendered | Used by evaluator/previews only. |
| Exclude by equipment type (armor/weapon subclass; quality/action scope) | Persisted/rendered | Used by evaluator/previews only. |
| Exclude equipment sets | Persisted/rendered | Preview depends on legacy equipment-set reads; not connected to item action. |
| Exclude unbound equipment (per quality/action scope) | Persisted/rendered | Unknown binding blocks/classifies conservatively; no client locale acceptance. |
| Exclude quest items | Persisted/rendered | Evaluator/previews only; no action path. |

Additional port-owned custom rules are development scaffolding and are not an
upstream setting; they must not be presented as part of parity. Retail-only
warband and artifact-relic settings do not belong in the 3.3.5a port.

## Exact command and screen inventory

| Upstream command/screen | Expected behavior | Port status |
|---|---|---|
| `/dejunk` or `/dejunk options` | Toggle the main window | Toggles the main settings window. |
| `/dejunk profiles` | Open main window on Profiles | Opens the main window on Profiles; the separate `/djw profiles` command retains development list behavior. |
| `/dejunk junk` | Toggle junk-items frame | Toggles the read-only candidate display; no sales or destruction controls. |
| `/dejunk loot` | Toggle lootable-items frame | Toggles the read-only lootable list, with no item-opening action. |
| `/dejunk sell` | Start manual seller | Intentionally disconnected; prints help/disabled behavior. |
| `/dejunk destroy` | Request one destroy action | Intentionally disconnected. |
| `/dejunk help` | List upstream commands | Current help differs and warns about disabled functions. |
| Main window: Lists, Profiles, Global Options, Profile Options, Keybindings | Switch sibling content screens | Four content screens exist; Keybindings is missing; the main overview/footer and exact screen components differ. |
| Transport frame | Import/export list text using upstream flow | Shared import/export window exists; actions/copy are close but layout, parser progress and messages differ. |
| Junk frame / Lootable frame | Show item cards, counts, controls and progress | Read-only scrollable item cards and saved positions exist; item actions and seller/loot progress/status remain absent. |

## Review notes

The matrix covers every major source module in the pinned upstream `src/` tree;
the `Retail-only integrations` row accounts for the upstream Addon Compartment,
warband and artifact-relic modules/branches. Exact source responsibilities are
recorded in `docs/research/UPSTREAM.md`; API-level compatibility risks are in
`docs/research/COMPATIBILITY.md`. The code must still be inspected against the
source before each parity row is moved to complete.

## Upstream functions intentionally not connected

The source contains simulation-only seller, repair and destroyer modules, but
`src/core/bootstrap.lua` does not construct them or connect inventory mutation
globals. This is intentional under the project's permanent instruction: the
owner must review transaction code and separately authorize a real-client
operation test before those services can be connected. It is not a missing
offline test; it is a distinct review/authorization gate.

## Completion gates

1. Finish all non-transaction parity rows: keybindings, junk/loot frames, list
   transport, merchant/minimap/bag integrations, public API/events, commands,
   item caches and final upstream-like UI components.
2. Close source/API compatibility gaps with immutable 3.3.5 evidence and offline
   tests; do one consolidated non-destructive client check only where rendering
   or input cannot be established offline.
3. Review the seller/repair/destroyer code against the exact legacy APIs and
   safety invariants. Only after owner review and separate authorization may
   they be wired and exercised in-client; never use valuable items.
4. Re-run migrations/recovery, complete a parity-by-parity client acceptance
   pass, audit licenses, and package a release candidate. The current ZIPs are
   development builds, not a finished addon.
