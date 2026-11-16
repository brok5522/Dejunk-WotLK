> 1.0.1 update: see [audit fixes](FIXES-REVIEW-1.0.0.md) for the current
> implementation delta, including threshold input behavior, outcome observation
> and the remaining localization / third-party bag limitations.

# Upstream Dejunk parity audit

Baseline: Dejunk 3.5.1 at immutable commit
[`04bafd5e411441ef5b51bb8ed10d208f2d7758f5`](https://github.com/moody/Dejunk/tree/04bafd5e411441ef5b51bb8ed10d208f2d7758f5),
target: original WoW 3.3.5a, build 12340, Interface 30300, Lua 5.1. This is a
source-to-source feature inventory, not a claim of client acceptance. “Covered
offline” means there is code and a mock/model test; it does not prove in-game
behavior. No row marked partial or missing should be read as complete parity.

## Status summary

- **Offline foundation present:** client/build gate, conservative legacy reads,
  schema-backed profiles/lists/options, rule evaluation, previews, and
  transaction safety fixtures for the isolated legacy API adapter.
- **UI partially ported:** the Waffle-hosted shell now includes all five main
  pages, saved profile/options controls, list transport, keybindings and
  read-only item windows. Several controls still use native port-built widgets;
  visual/input parity is not accepted until current-build client review.
- **Connected, awaiting original-client acceptance:** manual/automatic sale,
  repair, deliberate loot opening and confirmed one-stack destroy now dispatch
  through guarded API calls. The merchant-frame button now has a safe display,
  drag/reset positioning and Junk-frame shortcut. The read-only public API and
  AddOns category are implemented. Bag overlays, tooltips, transport and item
  windows have read-only implementations with client verification pending.
- **Intentionally not applicable on 3.3.5a:** artifact relic handling, warband
  equipment/bank, and the Retail Addon Compartment integration.

## Feature-by-feature matrix

| Upstream feature | Reference implementation | Current port | Status / exact remaining work |
|---|---|---|---|
| Client support and initialization | `Dejunk.toc`, `src/addon.lua`, `src/blizzard/blizzard.lua` | `Dejunk-WotLK.toc`, `src/compat/client.lua`, `src/core/bootstrap.lua` | **Implemented offline, client unverified.** Explicit build 12340/interface guard, ordered TOC, event startup and fail-closed behavior exist. Confirm target-client startup and API evidence once as a consolidated compatibility check. |
| Event lifecycle and scheduling | `src/events/event-manager.lua`, `src/utils/ticker-manager.lua` | `src/core/events.lua`, `src/core/scheduler.lua`, `src/core/bootstrap.lua` | **Implemented foundation.** Dispatch, cancellation, coalescing and lifecycle tests exist. Upstream event-driven product services/UI are not all subscribed or connected. |
| Bag, item and equipment-set metadata | `src/items/items.lua`, `src/items/bag-items-cache.lua`, `src/items/equipment-sets-cache.lua`, `src/items/equipment-types.lua` | `src/compat/legacy.lua`, `src/compat/runtime.lua`, `src/core/bag-cache.lua` | **Partial.** Legacy tuples, bag-scope checks, cache invalidation, equipment sets, categories and tri-state binding probes are modeled. No full upstream `Items` facade/junkable/sellable/destroyable API; binding/localized category behavior and all in-client probes need verification. Additional bag addons are absent. |
| Junk filter and order | `src/junk-filter/junk-filter.lua`, `src/junk-filter/item-filters.lua` | `src/rules/evaluator.lua` | **Modeled and connected; client acceptance pending.** Default quality, scopes, thresholds, equipment categories and list precedence have fixtures. Differences/risks: unknown state handling is deliberately stricter; upstream sell blockers (refund/no value) are not the same as generic classification; the port evaluates its legacy snapshots rather than implementing the upstream Items facade; guarded action handlers re-evaluate these decisions before dispatch. Retail-only filters are correctly omitted. |
| Junk item cache and ordering | `src/junk-filter/junk-items-cache.lua` | `src/services/junk-items.lua`, bag snapshot | **Read-only projection implemented; cache/UI integration partial.** Valid snapshots produce a deterministically sorted combined sell/destroy candidate list with per-action decisions and counts. Unknown items stay excluded. It is rebuilt on request; bag/state events refresh visible windows and footer counts. Next-item selection respects action eligibility. Blocked-sale counts and incremental upstream cache internals remain different. |
| Saved state, profiles and migration | `src/store/default-states.lua`, `src/store/migrations.lua`, `src/store/state-reconciler.lua`, `src/store/profile-summaries.lua` | `src/store/store.lua` | **Core present, exact migration parity incomplete.** Versioned SavedVariables, character profile mapping, CRUD, reset/delete protection, settings and list persistence exist. Need compare every upstream schema/migration and summary field against fixtures; no upstream state layer API parity is claimed. |
| Global and profile options | `src/ui/screens/main-window/options/global-options.lua`, `profile-options.lua` | `src/compat/runtime.lua:ShowOptions`, `src/ui/config.lua`, `src/store/store.lua` | **Settings modeled; integrations partial.** Global Safety/Interface/Bags and profile General/Include/Exclude controls persist and render. Auto Junk/Lootable displays, bag tooltip reasons, bag overlays, minimap and merchant buttons are connected. Auto Repair/Sell settings trigger merchant actions. Chat messages and exact component styling/input remain different. Shared plain scroll tracks replace Blizzard arrow templates; original-client acceptance is pending. |
| Four item lists | `src/lists/lists.lua`, `src/lists/list-item-parser.lua` | `src/store/store.lua`, `src/compat/runtime.lua:ShowLists` | **List editing implemented; exact parity partial.** Four persisted lists, name/ID search, cursor-item addition, right-click removal/transfers, validated import and export transport exist. The screen uses the upstream 2×2 global/profile include/exclude panels, colored headings, quality-tinted item rows, per-panel transport icons and a loading spinner while item metadata resolves. Parser percentage/progress messages, exact item selection/tooltip flow and target-client verification remain. |
| Profile lifecycle | `src/ui/screens/main-window/options/profiles.lua`, `src/ui/components/profile-card.lua` | `src/compat/runtime.lua:ShowProfiles`, `src/store/store.lua` | **Core actions implemented; UI partial.** Activate/create/duplicate/rename/reset/delete target individual profiles; default protection and confirmation exist. The four profile actions now use compact icon controls with hover tooltips; upstream action artwork, colored active names and summary tooltips exist; exact layout and client input still need acceptance. |
| Main window navigation and overview | `src/ui/screens/main-window/main-window.lua` | `src/compat/runtime.lua:ShowConfig` | **Main shell implemented; overview partial.** All five sibling destinations work in UI fixtures; `/dejunk` toggles it, drag position persists, and the footer shows profile/junk/loot counts. Footer segments now navigate to Profiles or toggle Junk/Lootable; reopening preserves the selected page and profiles commands toggle their target page. Hidden development overview controls remain in the source but are not the initial or navigable product page. Current client rendering/input remains unverified. |
| Keybindings | `src/input/keybindings.lua`, `src/ui/components/keybinding-card.lua` | `src/compat/runtime.lua`, `src/store/store.lua`, `src/core/bootstrap.lua` | **Implemented offline; client unverified.** Sidebar page has nine upstream actions, key/mouse-wheel capture, Escape cancel, right-click clear, modifier chords, addon-key conflict resolution, game-binding conflict notice, SavedVariables persistence and owner-scoped `SetOverrideBindingClick`. List actions use the item currently shown by `GameTooltip`, matching upstream; cursor contents are left alone. Overrides refresh out of combat; capture stops on combat entry/page hide. Seller/destroy handlers are registered; original-client input focus, event behavior and layout still need verification. |
| Slash commands | `src/input/commands.lua` | `src/compat/runtime.lua:RegisterCommands`, `src/core/bootstrap.lua:app:Command` | **Partial.** `/dejunk` toggles the main window; `profiles` opens Profiles; `junk`/`loot` open item lists; `sell`/`destroy` dispatch actions. `/djw` exposes additional development commands; exact upstream argument/error semantics remain. |
| Seller and safe sell | `src/services/seller.lua` | `src/core/bootstrap.lua`, `src/compat/runtime.lua` | **Connected, parity partial.** Single-stack and sequential merchant sales re-read slot/rules and require empty cursor, valid merchant, safe context and unchanged settings. Safe Sell limits one run to 12 dispatched sale calls, including failed calls. Destroy-only rows are skipped, duplicate starts return BUSY, unresolved caches wait up to 0.4 seconds, and merchant closure/refusal/settings changes cancel the run. 1.0.1 observes slot disappearance with a five-second timeout and unlock failure; confirmed vendor-value summaries respect chat verbosity. Exact localized wording and original-client acceptance remain open. |
| Repair | Merchant handler in upstream service/event modules; `CanMerchantRepair`, `GetRepairAllCost`, `GetMoney`, `RepairAllItems` | `src/core/bootstrap.lua`, `src/compat/runtime.lua` | **Connected, parity partial.** Auto Repair stays opt-in and checks merchant, funds, current cost, cursor and safety immediately before repair. Delayed repair also checks its original merchant session, option and settings revision. Original-client acceptance and upstream chat/session parity remain open. |
| Destroy, confirmer and Safe Destroy | `src/services/destroyer.lua`, `src/services/confirmer.lua` | `src/core/bootstrap.lua`, `src/compat/runtime.lua` | **Connected, acceptance pending.** Explicit destroy opens a copied, single-use confirmation intent which expires on Cancel or settings changes, then revalidates current eligibility/settings/slot and verifies cursor type/item ID plus emptied source slot. It never clears a cursor and never auto-destroys. Deletion is not exercised in development. WotLK cursor API exposes only type and item ID, not full link/count after pickup. |
| Junk frame | `src/ui/screens/junk-frame.lua` | `runtime:ToggleJunkFrame`, `runtime:UpdateJunkFrame` | **Functional core, parity partial.** `/dejunk junk` shows item cards, red/white upstream-style counts, total stack vendor value, settings shortcut and 32px coin/exclude/trash controls. Exclude updates lists; item and bottom controls dispatch to live handlers with eligibility checks. Progress/status, exact upstream spacing and chat parity remain open. |
| Lootable frame | `src/ui/screens/lootable-frame.lua` | `src/services/lootable-items.lua`, `runtime:ShowLootableFrame` | **Functional core, parity partial.** Positively marked lootable stacks are listed; row click opens the item and eye-slash ignores its ID for the session. Saved auto-open and drag position work. Original-client acceptance remains pending. |
| Merchant button and merchant behavior | `src/ui/screens/merchant-button.lua` plus upstream service listeners | `runtime:UpdateMerchantButton`, merchant events in bootstrap | **Partial.** Saved option shows/hides an icon-and-count button on `MerchantFrame`; it persists drag position, supports Shift-right-click reset, right-click opens Junk, left-click sells, and Alt-right-click requests confirmed destroy. Client behavior and exact upstream anchoring remain unverified. |
| Minimap icon | `src/ui/minimap-icon.lua` | `runtime:UpdateMinimapIcon`, `src/store/store.lua` | **Implemented offline, client unverified.** Native WotLK minimap button opens the configuration, right-click toggles Junk Items, Alt-right-click requests Destroy Next, drag stores a validated angle and the global setting controls visibility. Uses upstream Dejunk artwork; client anchoring and drag feel still need review. Retail addon-compartment behavior is N/A. |
| Bag item icons and tooltips | `src/ui/item-icons.lua`, `src/ui/item-tooltip.lua`, `src/ui/tooltip.lua` | `runtime:RegisterBagTooltips`, `runtime:RegisterBagIcons`, `runtime:RefreshBagIcons` | **Partial.** Default `GameTooltip:SetBagItem` adds SELL/DESTROY reasons using fresh legacy slot reads. Read-only icon overlays support stock visible ContainerFrames and SMALL/LARGE style, and clear stale overlays on bag/item updates. Tooltips now use reference-style colored headings and readable reason lines instead of raw reason codes. Tooltip localization and third-party bag adapters remain missing. |
| Transport/import/export window | `src/ui/screens/transport-frame.lua`, `src/lists/list-item-parser.lua` | `runtime:ShowListImport` | **Partial.** The window uses upstream 325×375 dimensions, displays the chosen list IDs selected for copying, persists its drag position and uses the two Import/Export actions. Import validates before committing and refreshes the lists while keeping the window open. Parser progress, localization and original-client behavior remain different or unverified. |
| Public API and events | `DejunkApi.lua`, `src/events/events.lua` | `src/api.lua`, `app:ClassifySlot`, shared event bus | **Implemented for the read-only upstream surface; client unverified.** `DejunkApi:IsJunk` checks the current bag/slot, and removable listeners receive bag/state updates. It does not expose mutation or a lootable query absent from the pinned API. Offline tests cover classification, invalid coordinates, notification and unsubscription. |
| Blizzard AddOns options category | `src/ui/blizzard/addon-category.lua` | `runtime:RegisterOptionsCategory`, registered after login | **Implemented; client unverified.** Legacy `InterfaceOptions_AddCategory` provides Open Dejunk and Open Profiles entries. Junk-frame navigation waits for its upstream frame. |
| Localization and assets | `src/locales/*`, `src/ui` assets | English strings, upstream Dejunk UI icons | **Missing/partial.** English-only controls and tooltip text; logo, transport, gear, coins, ban, trash and ignore icons are included under upstream MIT attribution. Most visual components still use native recreated controls. |
| Retail-only integrations | Warband, artifact relic, addon compartment | Not present | **Not applicable to original 3.3.5a.** Omit rather than emulate. |

## Exact settings inventory

The following list prevents “options are done” from being inferred from the
presence of a screen. `Persisted` means the store validates and saves a value;
`rendered` means the current settings page exposes a control; neither means the
game integration works.

### Global settings

| Upstream setting | Store/UI state | Runtime behavior |
|---|---|---|
| Safe Destroy (default on) | Persisted and rendered | Destroy action always requires confirmation; option parity still needs review. |
| Safe Sell (default off, 12-item session cap) | Persisted and rendered | A sale run stops after 12 attempts when enabled. |
| Merchant Button and saved position | Setting persisted/rendered | Button appears during merchant sessions, updates candidate count, saves drag position and resets with Shift-right-click. Selling and confirmed destroy are wired; client parity remains unverified. |
| Minimap Icon | Setting persisted/rendered | Minimap icon is connected: click opens settings, right-click hides/shows it, dragging saves its angle. Target-client behavior still needs verification. |
| Auto Junk Frame | Setting persisted/rendered | Automatically shows the Junk window when a merchant opens and candidates exist; hides it at merchant close or when an auto-shown list becomes empty. |
| Auto Lootable Frame | Setting persisted/rendered | Automatically shows/hides the lootable list on bag updates; row click opens items. |
| Chat Messages (enabled, Reduced/Verbose) | Values persisted/rendered | Transaction messages are minimal and not yet matched to upstream verbosity. |
| Bag Item Tooltips | Setting persisted/rendered | Legacy `GameTooltip:SetBagItem` hook adds live SELL/DESTROY status and evaluator reason lines when enabled. Client layout/localization remains unverified. |
| Bag Item Icons and Small/Large size | Values persisted/rendered | Read-only overlays are connected to visible stock ContainerFrames; SMALL/LARGE sizes are applied. Third-party bag adapters and client rendering remain unverified. |

### Profile settings

| Upstream setting | Store/UI state | Runtime behavior |
|---|---|---|
| Auto Repair (default off) | Persisted/rendered | Merchant handler checks cost/funds and invokes guarded repair once on open. |
| Auto Sell (default off) | Persisted/rendered | Merchant handler starts a sequential guarded sale run. |
| Include by Quality (Poor on by default; per quality and action scope) | Persisted/rendered | Used by the evaluator, previews and guarded action dispatch; original-client acceptance pending. |
| Include below item level (per quality/action scope) | Persisted/rendered | Used by the evaluator, previews and guarded action dispatch; original-client acceptance pending. |
| Include below stack vendor price (copper/silver/gold; per quality/action scope) | Persisted/rendered | Used by the evaluator, previews and guarded action dispatch; original-client acceptance pending. |
| Include by equipment type (armor/weapon subclass; quality/action scope) | Persisted/rendered | Used by evaluator and action dispatch; English labels use canonical IDs without positional auction guesses; other locales need evidence. |
| Exclude above item level (per quality/action scope) | Persisted/rendered | Used by the evaluator, previews and guarded action dispatch; original-client acceptance pending. |
| Exclude above stack vendor price (per quality/action scope) | Persisted/rendered | Used by the evaluator, previews and guarded action dispatch; original-client acceptance pending. |
| Exclude by equipment type (armor/weapon subclass; quality/action scope) | Persisted/rendered | Used by the evaluator, previews and guarded action dispatch; original-client acceptance pending. |
| Exclude equipment sets | Persisted/rendered | Classification and action dispatch depend on legacy equipment-set reads; client acceptance pending. |
| Exclude unbound equipment (per quality/action scope) | Persisted/rendered | Unknown binding blocks/classifies conservatively; no client locale acceptance. |
| Exclude quest items | Persisted/rendered | Used by evaluator and guarded action dispatch; client acceptance pending. |

Additional port-owned custom rules are development scaffolding and are not an
upstream setting; they must not be presented as part of parity. Retail-only
warband and artifact-relic settings do not belong in the 3.3.5a port.

## Exact command and screen inventory

| Upstream command/screen | Expected behavior | Port status |
|---|---|---|
| `/dejunk` or `/dejunk options` | Toggle the main window | Toggles the main settings window. |
| `/dejunk profiles` | Open main window on Profiles | Opens the main window on Profiles; the separate `/djw profiles` command retains development list behavior. |
| `/dejunk junk` | Toggle junk-items frame | Toggles candidate display with sale and destroy controls. |
| `/dejunk loot` | Toggle lootable-items frame | Toggles lootable list; clicking a row requests a guarded item open. |
| `/dejunk sell` | Start manual seller | Starts a sequential sale run at a merchant. |
| `/dejunk destroy` | Request one destroy action | Requests confirmation for one eligible item. |
| `/dejunk help` | List upstream commands | Lists upstream command names and notes which live actions remain unavailable; unknown suffix falls back to help. |
| Main window: Lists, Profiles, Global Options, Profile Options, Keybindings | Switch sibling content screens | All five navigation destinations exist as sibling pages; Keybindings has offline capture/override support. Exact upstream card styling and target-client behavior remain unverified. |
| Transport frame | Import/export list text using upstream flow | Shared import/export window exists with persistent drag position; actions/copy are close but layout, parser progress and messages differ. |
| Junk frame / Lootable frame | Show item cards, counts, controls and progress | Scrollable item cards and saved positions exist; progress/status treatment still differs from upstream. |

## Review notes

The matrix covers every major source module in the pinned upstream `src/` tree;
the `Retail-only integrations` row accounts for the upstream Addon Compartment,
warband and artifact-relic modules/branches. Exact source responsibilities are
recorded in `docs/research/UPSTREAM.md`; API-level compatibility risks are in
`docs/research/COMPATIBILITY.md`. The code must still be inspected against the
source before each parity row is moved to complete.

## Transaction parity and remaining evidence

The application now registers sale, repair, loot and confirmed destroy
handlers. The only code that resolves mutation APIs is
`src/compat/runtime.lua`; the handlers re-read the slot and eligibility
before acting. Offline tests use fake APIs. The original 3.3.5a client was not
available for live acceptance, so behavior and UI remain unverified there.
Never run actual deletion in development verification.

## Completion gates

1. Finish all non-transaction parity rows: keybindings, junk/loot frames, list
   transport, merchant/minimap/bag integrations, public API/events, commands,
   item caches and final upstream-like UI components.
2. Close source/API compatibility gaps with immutable 3.3.5 evidence and offline
   tests; do one consolidated non-destructive client check only where rendering
   or input cannot be established offline.
3. Review seller/repair/loot/destroy parity against the pinned upstream source
   and exact legacy APIs. Exercise only harmless sale/repair/loot behavior in
   client acceptance; never use real deletion during development.
4. Re-run migrations/recovery, complete a parity-by-parity client acceptance
   pass, audit licenses, and package a release candidate. The current ZIPs are
   development builds, not a finished addon.
