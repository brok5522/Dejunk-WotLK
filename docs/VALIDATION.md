# Validation and completion report

## First release — 1.0.0

Runtime retained from 0.16.65 after owner confirmation of Lootable layering,
bag visibility, startup keybindings, Auto Repair and clam detection. Release
metadata and bilingual installation links updated; license notices retained.
Actual Lua 5.1 regression and UI/action fixtures, historical-source checks,
diff whitespace and reproducible packaging pass. Remaining comparison limits
are explicitly preserved in RELEASE-1.0.0.md and PARITY.md. This release does
not constitute a new exhaustive source audit or prove untested native scenarios.

## Lootable layering — 0.16.65-beta.1

Owner confirmed bag visibility, keybindings after reload, Auto Repair and clam
detection; screenshot showed Lootable's rows hidden by the main LOW hierarchy.
Move Lootable to DIALOG, matching the existing separate Junk window layer policy.
UI fixture checks dimensions and layer; actual Lua 5.1 suites and packaging pass.
Native-client confirmation of this layer correction remains pending.

## Localized openable fallback — 0.16.64-beta.1

Added exact `ITEM_OPENABLE` matching through the existing recursion-guarded hidden
tooltip scanner. Rechecks slot link/count and refreshes lock after tooltip hooks.
French/color-format positive and generic/partial-text negative fixtures pass,
alongside the full actual Lua 5.1 suite and reproducible packaging. This extends
classification beyond IDs without labeling arbitrary Use effects as loot.
Native-client acceptance and nonstandard custom spell-only effects remain unverified.

## Lootable reference review — 0.16.63-beta.1

Pinned source uses `hasLoot` generically, without a clam list. The port preserves
the native tuple flag path for all IDs and extends spell-based WotLK clams to
seven identities. See LOOTABLE-PARITY.md for exact source and item references.
All seven and an arbitrary flagged container have read-only fixtures; ordinary
consumables remain excluded. Full actual Lua 5.1 and packaging checks pass.
No live item was opened during verification; custom-server unflagged spell items
remain outside the proven classification scope.

## Owner feedback fixes — 0.16.62-beta.1

Owner accepted client-test items 1, 3, 5 and 8; reported bag occlusion, startup
keybindings inactive until UI creation, Auto Repair failure and a Small Barnacled
Clam missing from Lootable, also reproducible without other addons.
Moved keybinding action creation to a reusable startup initializer; startup calls
it after action attachment. Repair flags accept legacy 1/true. Main window uses
LOW strata beneath stock MEDIUM bags. The known use-effect clam 5523 receives a
narrow legacy loot identity exception used by both snapshots and transaction rereads.
Ordinary consumables remain excluded. Numeric-repair and clam/food regression
fixtures pass along with the full actual-Lua-5.1 suite and deterministic packaging.
These are offline fixes; owner retest is pending. The clam exception does not
claim general detection of all spell-based openable items.

## Import commit review — 2026-11-15

Additional item-window review against upstream `lootable-frame.lua` and
`junk-items-cache.lua`: clear stale empty-state text when bag data invalidates,
clear Lootable's unavailable-data summary when valid data returns, and discard
its invalidated source snapshot. Junk name sorting now uses the reference's
case-sensitive name comparison. UI fixtures cover a locked Lootable row, busy
state, right-click refusal, exactly one left-click dispatch and recovery after
invalidation. All action checks use injected handlers, never live inventory.

Reviewed the list storage/import boundary against the pinned upstream list and
parser modules. The port still uses a preview/commit implementation rather than
upstream's asynchronous metadata parser; parser progress/message parity remains
open. Fixed a concrete robustness issue in `Store:CommitImport`: malformed or
sparse addition arrays are rejected without changing the destination, and list
capacity is counted once instead of rescanning the full destination for each ID.
Duplicate IDs consume capacity only once. A regression fixture checks malformed
input, atomic rejection and duplicate handling.

Compared `src/ui/screens/transport-frame.lua:94` in the pinned reference:
Transport accepts digit runs separated by arbitrary non-numeric characters and
skips zero/out-of-range IDs. `Store:ImportPreview` now follows that extraction
behavior instead of rejecting punctuation other than commas/semicolons. The
fixture includes punctuation, duplicate IDs, zero and overflow. Input remains
plain data. Asynchronous item metadata validation/progress is still different.

`python3 tools/check_phase0.py`, the full `tools/check.py` suite using actual
Lua 5.1, and `git diff --check` passed. Store scenarios increased from 21 to 22;
runtime 64, services 8, destroyer 11 and UI model 62 remain passing, as do
transaction/UI interaction fixtures and reproducible 41-entry packaging.
No live-client operation or new release was performed. This review does not
close the remaining source and client acceptance gaps listed in PARITY.md.

## Publication candidate 0.16.60-beta.1

Runtime behavior is unchanged from the owner-tested 0.16.59 candidate; only
release metadata changes. Root English and Persian README files, third-party
notices and artwork license links now ship in the addon ZIP. The package has
41 entries. Source ZIP artifacts are removed from tracking; downloads move to
GitHub Releases. The release workflow validates Lua 5.1, builds the artifact,
attaches SHA256SUMS.txt, and only then removes the explicitly inventoried old
download/test branches, using ref leases to preserve changed branches.

Local checks passed with Lua 5.1: runtime 64, store 21, services 8, destroyer 11,
UI model 62, action lifecycle/transaction and UI interaction fixtures;
reproducible ZIP/source/license/CRC checks passed. Native-client visual/lootable
acceptance and exact upstream parity still have the limitations in PARITY.md.
The release is a community beta, not a stable-parity claim.


## Merchant portrait avoidance: 0.16.59-dev

The owner's screenshot showed the button still covering the portrait/name.
Stock build-12340 MerchantFrame.xml places the portrait in the upper left,
the name at y=-17 and the first item row at y=-80. The 108×28 button now uses
TOPLEFT (210,-44), in the free band below the title and above the first item row.
Old default positions (60,-28) and (60,-44) are migrated when displayed;
custom dragged positions are preserved. New defaults and both reset paths use
the same new anchor. Offline UI coverage includes a legacy saved position.
In-game visual confirmation remains pending.

## Source audit and regression candidate: 0.16.58-dev

Reference checkout was verified again at immutable upstream commit
`04bafd5e411441ef5b51bb8ed10d208f2d7758f5`. Relevant comparisons:

| Upstream source | Checked behavior | Port change / evidence |
|---|---|---|
| `src/ui/screens/main-window/main-window.lua:356` | Three interactive footer segments | Profile/Junk/Lootable footer buttons and click fixtures; live count refresh follows bag/state changes |
| `src/ui/screens/main-window/main-window.lua:470` | Reopen on the selected page; targeted Profiles toggle | Page preservation and `/dejunk profiles` toggle, including repeated close/reopen fixtures |
| `src/ui/item-tooltip.lua:20` | Colored headings and readable reasons on separate lines | Shared decision tooltip formatter in the legacy runtime, exercised by bag and action tooltips |
| `src/ui/screens/main-window/options/global-options.lua` | Merchant option right-click reset and choice-label clicks | Reset without toggling the setting; Verbose and icon-size labels dispatch their controls |
| `src/ui/screens/main-window/options/options-builder.lua` and native scroll widgets | Plain tracks, wheel input and bounded scroll range | Shared legacy scroll control for Profiles, Options, Transport, Junk and Lootable; overflow/clamp fixture |
| `src/services/seller.lua:163` | Bounded cache settling, action-specific batches, busy lifecycle | 0.4-second cache wait; only sale-eligible rows dispatched; duplicate start rejected; end/cancel clears UI busy state |
| `src/services/seller.lua:183` | Safe Sell counts calls rather than successful outcomes | Twelve-call cap tested with mixed sale/destroy rows and failing fake API dispatches |
| `src/services/seller.lua:37` | Delayed merchant repair | Original session, option and settings revision are checked again; stale-session/disabled-option tests |
| `src/services/confirmer.lua` and `src/services/destroyer.lua` | Deliberate item-specific confirmation | Copied, single-use intent; Cancel/settings changes expire it; fixtures never perform live deletion |

The legacy item-card tooltip also had a lexical-scope bug: its closure read a
global `merchantButtonOpen` instead of the later-declared local. The shared
merchant state is now declared before card factories; a tooltip fixture proves
the active merchant context is visible.

Commands executed with actual Lua 5.1:

```sh
python3 tools/check_phase0.py
python3 tools/check.py --lua /workspace/work/lua51/usr/bin/lua5.1 --luac /workspace/work/lua51/usr/bin/luac5.1
git diff --check
```

All passed: runtime 64, store 21, services 8, destroyer 11, UI model 62,
transaction adapter/action-lifecycle fixtures and UI interaction fixtures.
Reproducible 38-entry packages passed content/CRC/layout checks. This is offline
evidence only. `docs/CLIENT-TEST-0.16.58.fa.md` records the next client checks.

Still not claimed complete: exact localization, third-party bag integrations,
special-equipment edge cases, import parser semantics/progress, seller outcome
observation and exact chat/session messages, plus final native-client layout and
input acceptance. The older table entries that said no filter decisions reached
actions were stale and have been corrected in PARITY.md.

## Window layering and merchant placement: 0.16.57-dev

The owner requested the visible header target 3.3.5 instead of upstream version
3.5.1. This is an explicit presentation exception; the pinned source remains
Dejunk 3.5.1. Junk and Transport use DIALOG strata on original WotLK so elevated
profile action buttons cannot draw over them. Main/Junk backgrounds are opaque;
the Junk settings gear dismisses Junk before opening Profile Options. Merchant
button uses MEDIUM strata, and its default/reset position is 16px below its old
placement to avoid the merchant name bar. Existing untouched old default points
are adjusted when displayed; custom dragged positions remain preserved.
The 0.16.56 minimap reopen fix is included. Lua 5.1 UI and regression checks
passed; in-game visual acceptance remains pending.

## Minimap reopen fix: 0.16.56-dev

The owner observed an empty selected Lists page after opening through the minimap.
ShowConfig/ToggleConfig hid child frames directly while their Waffle components
remained VISIBLE. Reopening the already-selected page skipped a visibility change.
Integrated pages now follow component visibility when closing/reopening the root;
ShowLists also restores its frame after a temporary transport hide. Regression
fixtures exercise three minimap close/reopen cycles and reopening after direct
Escape-style root hiding. Original-client retest is pending.

## Client feedback fixes: 0.16.55-dev

The owner reported missing Escape dismissal, a displaced/double-looking minimap
icon, failed item drops, doubled input borders and an uncloseable Transport
window on 0.16.54. Windows now register in legacy UISpecialFrames; the Transport
close button has an explicit 24px click area; list panels, scroll children and
rows handle OnReceiveDrag. Search, profile-name and threshold inputs use one
custom border without InputBoxTemplate. The minimap tracking border uses its
stock TOPLEFT anchor. Transport uses a flat border instead of a dialog border.
Offline UI tests cover registration, the close click area and actual drop events.
Original-client retest is pending. Modifier transfers passed the owner's test;
Lootable was not tested because no lootable item was available.

Date: 2026-11-14. This report describes the current working tree, not a release.
The exhaustive feature comparison is in [PARITY.md](PARITY.md).

## Current result

The automated compatibility and regression checks pass. Sale, repair, loot and
confirmed destroy are connected through the guarded legacy transaction adapter.
The addon is still **not complete or release-ready**: several screens and
upstream interaction details differ, and the current build has not been
accepted in the original client. The numbered history below contains older
entries; the current feature-by-feature status is in `PARITY.md`.

### Steps completed in this development branch

1. **Reference and target:** pinned upstream Dejunk 3.5.1 at
   `04bafd5e411441ef5b51bb8ed10d208f2d7758f5`; set WoW 3.3.5a build 12340,
   Interface 30300 and Lua 5.1 as the compatibility target.
2. **Legacy compatibility foundation:** build guard, legacy container/item API
   adapters, cache invalidation and scheduling; unknown or failed reads fail
   closed. FrameXML research is documented under `docs/research/`.
3. **Storage and classification:** profile/list persistence, upstream-style
   defaults, precedence and filters; regression cases cover legacy item tuples,
   price/quality/equipment filters, item flags and unknown metadata.
4. **Read-only operations:** bag probes, classification and SELL/DESTROY
   previews. These produce reports only and never mutate inventory.
5. **Simulation kernels:** seller, repair and destroyer state-machine tests run
   against explicit fake adapters; none is wired to live game APIs.
6. **Main-window navigation correction:** Lists is the initial screen; Profiles,
   Global Options and Profile Options are separate screens hosted in the same
  Waffle main window. A client screenshot exposed options as a black overlay.
  All five content screens now use sibling Waffle components and one screen
  selector modeled on pinned upstream `MainWindow:SelectSidebarRow`; this removes
  manual child-dialog sizing and hides the previous screen from layout. Interaction
  fixtures cover Lists → Profile Options → Global Options → Profiles → Profile
  Options → Lists. This is still not the pinned upstream UI port: original
   keybindings now have an offline screen/controller; profile/global option
   coverage, item presentation and game integrations remain incomplete, and
   some overview controls are still port scaffolding.
   The upstream cursor-item-to-list interaction is now restored in the UI
   adapter and covered by an isolated fixture. The generalized custom-rule
   editor has been retired from classification.
7. **Packaging:** deterministic development ZIP generation with overwrite
   protection. Earlier development ZIPs were uploaded to private review branches
   in the owner's GitHub repository; none is a release.
8. **Safe upstream integrations:** added the legacy Interface Options category
   with entry points for the main page and profiles, plus the public read-only
   `DejunkApi` surface (`IsJunk`, removable `AddListener`, `BagsUpdated` and
   `StateUpdated`). Offline fixtures cover category routing, slot validation,
   event delivery and unsubscription. These are not yet verified in the game
   client; the API does not invoke inventory actions.
9. **Read-only junk candidate projection:** item names are retained from the
   verified legacy `GetItemInfo` tuple, and a pure snapshot projection now
   returns sorted SELL/DESTROY candidates with separate decisions and counts.
   Invalid snapshots and unknown slots do not become candidates. This prepares
   the source data for the missing item window, but is not an action service.
10. **Read-only Junk window:** `/dejunk junk` toggles a scrollable candidate list
   showing sell/destroy counts and reasons. Bag invalidation clears displayed
   rows; bag and saved-state updates refresh them. The exclude control updates
   profile/global exclusions; coin/trash and bottom controls dispatch through
   injectable handlers but remain unregistered in the live app. UI fixtures
   check handler dispatch with mocks, opening/toggling, reasons, icons, and
   stale-row removal; target-client rendering still needs a consolidated check.
11. **Read-only Lootable window and command routing:** `/dejunk loot` shows
   positively flagged slots and `/dejunk profiles` opens Profiles. The saved
   Auto Lootable Frame option controls display on bag updates; it never opens
   items. Fixtures cover positive-flag filtering, invalid snapshot rejection,
   window toggle and original command routing. `/dejunk` and `/dejunk options`
   now toggle the settings window, with offline screen-state coverage.
12. **Auto Junk display:** during a merchant session the saved option can show
   the read-only candidate window; it closes at merchant close and when its
   auto-shown list becomes empty. Mock event fixtures assert no item mutation.
20. **Merchant button shell:** the saved setting now shows a draggable button
   during merchant sessions, updates its candidate count, and supports the
   upstream Junk-frame shortcut and position reset. Start Selling and Destroy
   Next dispatch through injected handlers; the live app registers no handlers
   pending the end-of-task authorization.
13. **Bag item tooltip reasons:** a single `GameTooltip:SetBagItem` post-hook
   reads the slot again and displays separate SELL/DESTROY decisions and reason
   codes when item tooltips are enabled. The hook skips the hidden binding scan
   tooltip and is registered once. Mock tooltip coverage is offline only.
14. **Transport export flow:** Export and Import now share a draggable,
   position-persistent transport window; export fills a comma-separated list and
   selects the text for manual copying, while import keeps the
   review-before-commit path. UI fixtures cover both and verify saved position.
15. **Item card presentation:** Junk and Lootable windows now reuse scrollable
   cards with bag icon textures, quality accent on Junk items, quantity and
   action/location detail. UI fixtures assert icon and quality accent rendering.
16. **Window positions:** main, Junk and Lootable windows restore saved
   anchors/offsets and persist them after dragging. UI fixtures verify Junk frame
   drag persistence through the validated SavedVariables path.
17. **Main-window item entries:** added upstream Junk and Lootable list entry
   buttons to the overview. UI fixtures assert both are present; their read-only
   commands and windows are covered separately.
18. **Options state and thresholds:** migrated upstream global defaults into the
   WotLK store, accepted legacy minimap state, validated global option writes,
   and added profile minimum/maximum item levels and minimum/maximum stack
   vendor value controls with per-filter scope and quality selection. Store
   round-trip/migration and UI interaction fixtures cover those changes. A
   later client screenshot showed the packed one-page threshold controls
   overlapping. Profile Options has now been restructured into the upstream
   General / Include / Exclude groups and scrollable option cards. Profile
   Options now includes the upstream panel and card descriptions, divider
   separated settings rows, card-wide toggles, per-filter applies-to/quality
   choices and gold/silver/copper price inputs. Exclusion cards and unbound
   quality controls fit within their card bounds. The heading retains the
   active profile name. Automated UI fixtures cover card bounds, settings
   interactions and coin conversion. A later screenshot showed the fifth
   quality chip and caption extending past the right edge at the user's
   resolution. Quality rows now recompute spacing from the Waffle page width;
   fixtures assert that cards, controls and clickable captions stay within the
   scroll content and that quality labels do not overlap. Client screenshots
   of v12/v13 exposed
   page overlap and incorrect checkbox styling: legacy CheckButton:SetText is
   unavailable, and expanding the checkbox width stretched its template
   texture. The port now keeps the checkbox at 24px, renders its caption in a
   separate clickable text region, hides and fades sibling pages, and gives
   Options an opaque panel background. UI fixtures reject CheckButton:SetText,
   exercise caption clicks, and verify page exclusivity. The corrected package
   still needs one client visual check. The Global Options page now follows the
   upstream Safety / Interface / Bags groups and exposes the corresponding
   persisted settings, including chat-detail and bag-icon-size choices. UI
   fixtures cover group order, card bounds and option writes. These settings
   do not yet connect merchant, minimap, bag, chat or frame integrations.
   Native controls approximate the pinned
   Waffle OptionCard/SettingsBox and SelectableRow visuals; other upstream screens and
   integrations remain unfinished.
   A further client screenshot showed red Blizzard button art remained on Lists, profile actions and threshold Apply controls. The subsequent 3.3.5 client screenshot confirmed the red templates were removed but showed checkbox marks were not visible. Custom checkboxes now accept both boolean `true` and numeric `1` from `GetChecked`, and the interaction fixture exercises the numeric/`nil` return shape. All addon-created `UIPanelButtonTemplate` instances now use plain square controls with the upstream dark-grey background, gold label and black border; close controls use a grey X that highlights red on hover. The active-profile rename control is widened to prevent label truncation. UI interaction fixtures assert the screenshot-visible Lists and Apply buttons no longer use Blizzard red templates. New profile cards use full action names and custom dark prompt panels with confirm/cancel actions; default-profile rename/delete remain disabled. The latest screenshots also showed search stopped after one character. Lists previously hid and relaid out the page on each text change; refresh now keeps the active page laid out. UI mocks cover full query preservation, page visibility and profile prompt actions, but these fixes need a client check.
   The latest client screenshot exposed a WoW-specific positioning issue:
   native frames do not provide the mock-only `.point` field used by the width
   adjustment. The code now stores each quality row's vertical offset and each
   long description's horizontal offset explicitly; fixtures verify both are
   preserved during responsive layout. A fresh client screenshot is needed to
   confirm the corrected Profile Options rows appear inside their cards.
14. **Read-only bag item icons:** the global Bag Item Icons option now draws
    overlays on junk candidates in visible stock ContainerFrames. SMALL uses a
    24px icon and LARGE fills the item button; BAG_UPDATE and lock changes
    rescan decisions and clear stale overlays. Unknown bag coordinates or
    failed API reads do not display an icon. Store-backed rules are queried
    through read-only slot probes; no item actions are connected. UI fixtures
    verify small/large appearance, disabled cleanup and classification-change
    cleanup. Third-party bag adapters and original-client rendering remain
    unverified.
19. **Keybindings screen and runtime overrides:** added the fifth main-window
   page with the upstream nine actions. Clicking a row starts capture; Escape
   cancels, right click clears, modifier and mouse-wheel keys are supported,
   and duplicate Dejunk assignments clear the older assignment. Changes are
   SavedVariables-backed. An owner-scoped `SetOverrideBindingClick` layer
   leaves the game's binding table alone, refreshes after combat, and stops
   capture on combat entry or page hide. Game-binding conflicts are disclosed;
   seller and destroy actions remain disconnected. Lua fixtures cover saving,
   override target, duplicate resolution, clear/cancel, game conflict notice,
   modifier/wheel/mouse input, tooltip-item list toggling without changing the
   cursor, combat restrictions and screen switching. The actual client's
   rendering and keyboard focus remain unverified.
   Follow-up client screenshots exposed the stock 3.3.5 scroll template error:
   three ScrollFrames (Lists and the junk/lootable windows) had no frame names,
   but the 3.3.5 `ScrollFrame_OnLoad` concatenates `self:GetName()` to resolve
   its scrollbar controls. They now have unique names. Keybinding labels also
   now call `GetBindingText(key)` exactly as the pinned upstream does; the
   `KEY_` argument was a localization prefix and could render a wrong label.
   Lua tests and syntax checks pass; this fix still needs a client screenshot.

## Checks run for this report

Commands:

```sh
python3 tools/check.py --lua /workspace/work/lua51/usr/bin/lua5.1 --luac /workspace/work/lua51/usr/bin/luac5.1
python3 tools/check_phase0.py
git diff --check
```

Results for current working tree `0.16.58-dev`:

- `check_phase0.py`: PASS (31 required deliverables, 46 Markdown files, 57
  local links, 54 source digests and 153 legacy API references).
- `check.py`: PASS (20 ordered runtime files; Lua 5.1 syntax for 28 files;
  runtime 64/64, store 21/21, services 8/8, destroyer 11/11, UI model 62/62;
  transaction adapter fake-API tests and UI interaction fixtures passed,
  including seller/destroyer dispatch, slash-command routing, keybinding
  capture/overrides, merchant-button behavior and transport positioning; the
  deterministic 38-entry ZIP verified).
- `git diff --check`: PASS.
- Original 3.3.5a client rendering/input check: NOT RUN in this environment.

The bag overlay fixture was also run directly with Lua 5.1 and passed.

## UI visual parity pass

Compared UI tokens against the pinned upstream `utils/colors.lua` and widget
components: backdrop #121212, dark grey #1E1E1E, blue #4FAFE3, gold #FFD100,
grey #9D9D9D; 24px item-card icons; 18px list/profile accent strips; normal
selected/hover row alphas; GameFontNormalSmall controls; dark input fields and
black borders. The UI now uses these values for legacy edit boxes, the
navigation hover, option labels, list row spacing, and the read-only junk and
lootable item cards. Item-card accents use the legacy quality color when the
client API supplies one; item names remain white like upstream.

The latest Profile Options comparison fixed the visual quality chips: their
checkbox border and checked mark now use the standard Poor/Common/Uncommon/Rare/
Epic quality colors instead of a single blue, and all five quality names are
written in full. Main option-card checkboxes now use their 18px layout size
(chips remain 12px), major option labels stay white when unchecked, and section
headings are white like the pinned upstream Option Builder. The main navigation
now follows upstream order: Lists, Global Options, Profile Options, Profiles,
Keybindings.
Lua 5.1 and UI fixtures pass; a client screenshot is still needed to confirm
WoW 3.3.5 rendering.

The Lists screen now follows the reference layout: a full-width “Search Lists”
field, four independently scrollable panels, red inclusion and green exclusion
title bars, quality-tinted item names and icons, and a per-panel transport icon
that switches between import and export. Manual scope/kind/ID controls were
removed from the screen; adding is done by dropping a cursor item into a list,
and right-click removes or moves entries. The window now also has the upstream
logo/version header and active-profile, junk-count, and lootable-count footer.
Upstream logo/transport artwork is included under its MIT attribution. Offline
UI fixtures check panel order/colors, transport flow, scrolling rows, and footer
rendering. The transport icon uses the upstream 14px size and overlay layer,
and is raised above its title bar. Lists now use bare legacy ScrollFrames with
wheel handling and a custom thumb that appears only when rows overflow; the
stock arrow template is removed so it cannot cover the transport button. UI
fixtures assert the bare scroll frame, track and visible transport control.
Original-client rendering still requires the user's next check.

Follow-up client screenshots showed bundled UI art missing even though its
texture controls existed. Asset paths used a hard-coded AddOn folder name;
they now use the actual name supplied by WoW when loading the AddOn, so a
renamed install folder still resolves its icons. Offline fixtures check the
resolved paths; a fresh client screenshot is needed to confirm the artwork.

The Junk and Lootable windows now use their upstream 350×400 and 250×250
dimensions. Junk has candidate counts, a stack-value summary, a Profile Options
shortcut, item-row coin/exclude/trash icons, and bottom action buttons. The
exclude control updates the selected profile list (Shift selects global).
Coin, trash and merchant controls dispatch through registered action handlers.
The lootable row opens the item on left click; eye-slash ignores the item ID for
the current session. Live calls use `src/compat/runtime.lua`; fake API
fixtures cover sale, repair, loot, cursor safety and destroy dispatch. Original
client acceptance and exact upstream transaction/chat parity remain pending.

The original 3.3.5a client visual check was not run. The main window still uses
port-built native screens and some list/profile/action widgets are development
scaffolding, so these changes improve shared component parity but do not claim
that every screen is pixel-identical to upstream.

The profile name field now requests focus after its modal ancestors are shown,
has explicit legacy EditBox styling, and accepts Enter/Escape. Option
checkboxes, their text hit targets and themed action buttons now explicitly
enable mouse input and register `LeftButtonUp`. UI fixtures assert visible-modal
focus and legacy click registration. The minimap option is now connected to a
native minimap button: left click opens settings, right click hides/shows it,
dragging updates the saved angle, and the state is validated and migrated by
the store. Offline UI and store fixtures cover those flows; live client input
and positioning remain unverified.

Follow-up client screenshots showed that the checked state still did not
visually follow Auto Sell/Auto Repair. The config read model returned only the
nested options table even though those two flags are stored at profile root;
`GetOptions` now includes both saved flags, including in bootstrap fallback.
Interactive controls are explicitly raised above their card surfaces, and
modal inputs/buttons above the modal blocker. New UI integration fixtures use
the real store/config callbacks to toggle both flags and apply an item level,
then assert persisted values and rendered checked state. The actual client
click path remains to be confirmed.

The follow-up screenshot showed that the lower filter controls appeared
inactive because their parent filter checkbox was off. Scope and quality
selectors are now editable while the filter is off, and Apply remains
clickable; applying a numeric threshold saves the entered value and enables
that filter. Store-backed UI fixtures verify scope and quality edits while
disabled and persistence after Apply across all four threshold cards. The
Include by quality scope and quality chips are also checked while their parent
filter is disabled. Numeric inputs explicitly take mouse and keyboard focus.

## Still required to complete the upstream port

1. Remaining non-transaction parity: exact upstream main/list/profile/options
   presentation, merchant button, third-party bag adapters, parser
   progress/messaging, and several
   command and state-migration details.
2. Review seller, repair, loot and one-stack destroy parity against upstream.
   These handlers now use the embedded transaction adapter; no destructive test
   is needed or permitted for development verification.
3. Run one consolidated, non-destructive UI and compatibility smoke check in
   the original build-12340 client. Current automated checks cannot prove the
   client's rendering, focus behavior or API behavior.
4. Re-run regression/package checks after any further port work and collect
   client evidence before claiming upstream parity.

### Client check status

**Client check:** the owner confirmed the minimum item level value survived
`/reload`. Screenshots then exposed threshold overlap, unsupported legacy EditBox
methods and options rendered as a detached overlay. The options screen has since
been corrected and all content screens follow the Waffle selector model. Offline
fixtures check screen exclusivity, sibling parenting, layout sizing, section
order, scroll content size, card bounds, profile prompts and multi-character
search behavior. The 0.16.15 screenshot confirmed the checkbox checked state is
visible; later profile, list search, layout and read-only item-window changes
are only covered by offline mocks. The next client check should be a single
consolidated review of Profiles (create, rename, duplicate, reset/delete prompts
and activation), Lists (multi-character search and pane sizing), both Options
pages, and Junk/Lootable windows. No live sale, repair or inventory deletion
test is required. No live mutation was performed.

## Historical evidence

The prior phase-by-phase validation entries were consolidated here because
they recorded intermediate results as if they were current acceptance. Specific
legacy-client evidence remains in `docs/research/CLIENT-12340-*.md`; consult its
revision and limitations before relying on it. The screenshots in the project
history exposed real UI errors and layout problems, which is why current
automated model checks are not treated as proof of client correctness.

## Visual parity follow-up (`0.16.53-dev`)

Compared all available screen implementations with the pinned UI sources:
Lists uses the exact search and transport icons; close controls use the upstream
X artwork; profile actions use the exact pencil/copy/reset/trash artwork in the
reference order; profile summaries color active inclusion/exclusion counts;
Keybindings use grey key boxes, white labels, red/green list names and the
reference descriptions; Lootable rows use the upstream 24px item icon, 32px
action button with a 14px ignore icon, five-row sizing, low frame strata and
gold/white title counts. The main window uses the reference 800×640 component
dimensions and 20px logo; the transport frame uses its 325×375 dimensions and two-button
Import/Export flow. Item quality stripes, locked-item handling and the merchant
button's count/version and Alt-destroy tooltips now follow the reference more
closely. `python3 tools/check.py` passed with actual Lua 5.1, all 64 runtime,
21 store, 8 service, 11 destroyer, 62 UI model and UI interaction fixtures;
ZIP reproducibility and layout checks passed. Exact styling/localization and
original-client rendering remain unverified in this environment.

Further UI corrections: Escape clears Lists search; profile action icons use
14px reference sizing and action-specific hover colors; quality/price options
show the reference pink caution text; right-click on an option card no longer
toggles it. Bag overlays use Dejunk artwork and small/large dark backgrounds,
cleared together with stale overlays. The minimap icon uses Dejunk artwork;
right-click requests Junk Items, Alt-right-click requests Destroy Next, and
Alt-left-click does not open settings. Lua 5.1 interaction and regression checks
passed; no original-client operation was performed.

## Comprehensive test candidate 0.16.54-dev

Destroy Next now skips sale-only and locked candidates instead of choosing the
first combined-list row. The Persian client test guide records installation,
UI/storage/keybinding/list checks, low-value sale/repair/loot checks, and
cancel-only destroy confirmation checks. No live inventory operation was run.
GitHub distribution uses an isolated test-candidate branch; main is not merged.

## Review-only verification — 2026-11-16

Snapshot: f416bdd52906d440ae060e194a15fb639f9e824b. No executable changes.
See [REVIEW-1.0.0.md](REVIEW-1.0.0.md) for open findings and coverage limits.

- `python3 tools/check_phase0.py`: passed (31 deliverables, 69 Markdown files,
  62 local links, 54 source digests and 153 API references at execution time).
- `python3 tools/check.py --lua /workspace/work/lua51/usr/bin/lua5.1 --luac /workspace/work/lua51/usr/bin/luac5.1`:
  passed; syntax for 28 files, 67 core fixtures, 22 store, 8 service, 11 destroyer,
  62 UI model fixtures, transaction and UI interaction checks; two reproducible
  41-entry archives built only in temporary storage.
- Profiles allocation probe using the existing UI fixture in memory: two
  identical refreshes each created 24 additional mock UI objects (finding 18).
- Final documentation validation: `git diff --check` passed; Phase 0 checks
  passed again with 63 local links after adding this note.
- Not run: original WoW client rendering, live inventory operations, live
  performance profiling. No package upload, GitHub release or runtime patch.

Passing existing tests does not resolve the review findings. In particular,
the Profiles probe demonstrates missing repeated-refresh coverage. Modifier
semantics in finding 12 were corrected against upstream, not changed in code.

### Settings review continuation

No executable files changed. Additional actual Lua 5.1 probes:

- Each of excludeEquipmentSets, excludeQuestItems and excludeUnboundEquipment
  initialized with SELL scope became BOTH after SetOption(false), SetOption(true).
  This reproduces finding 20 using the actual Store implementation.
- The existing UI interaction fixture passed; a probe appended in memory then
  used its persisted Store callbacks to disable includeBelowItemLevel, enter 61,
  and click Apply. Result: enabled=true, value=61 (finding 21). The earlier probe
  against an obsolete fixture variable was discarded, not counted as evidence.
- No live WoW operation or release upload. The full regression suite's earlier
  pass remains applicable to the unchanged executable snapshot; these probes
  expose missing or reference-inconsistent expectations in that suite.

### Application-path binding probe

Actual Lua 5.1, existing tests/harness.lua, real Application/Store methods and
fake bag/tooltip APIs: a bound Poor head item with excludeUnboundEquipment on
was absent from GetJunkItems while GetSlotDecisions classified it JUNK/QUALITY
for selling and JUNK for destruction. Output: `BINDING_PROJECTION 0 JUNK QUALITY
JUNK`. Asserted zero inventory mutations. Finding 4 is now directly reproduced.
No executable changes or live-client tests were made during this continuation.

### Profile and recovery probes

Actual Lua 5.1 with existing harness and real Store/Application code:

- Default reset after enabling autoSell: `RESET_DEFAULT false true` (finding 22).
- Valid exclusion 123 plus one invalid saved key: after reload,
  `RECOVERY_LIST nil nil` for that exclusion and the recovery field (finding 23).
- ADDON_LOADED with schemaVersion="2": failed at bootstrap.lua:348 with
  "attempt to compare number with string" (additional reproduction of finding 1).
  Mutation count was asserted zero in the event-path probe.

Only review/validation documents changed. Existing passing runtime suites do not
cover these malformed-input and Default-reset expectations; no new release or
live operation was performed.

### Equipment predicate follow-up

Actual Lua 5.1 pure Rules.Evaluate probes used common-quality, level-10 items
and a level-20 inclusion threshold. Fishingpole (2/20, INVTYPE_2HWEAPON), Generic
armor (4/0, INVTYPE_CHEST), and a ring control (4/0, INVTYPE_FINGER) each returned
JUNK/BELOW_MIN_ITEM_LEVEL. Reference Items:IsItemEquipment exempts the first two
but deliberately accepts the ring. Finding 17 is now directly reproduced at
the evaluator boundary. Actual legacy API metadata and live inventory actions
were not tested. No executable source or test fixtures were changed.

### Merchant lifecycle follow-up

- Actual Lua 5.1 tests/transaction-tests.lua: passed existing checks, including
  merchant-close/settings cancellation, failed-dispatch Safe Sell counting,
  confirmation lifetime and delayed auto repair. All transaction APIs were fake.
- Application/cache probe after manually closing Auto Junk: BAG_UPDATE reopened
  it; output `AUTO_JUNK_MANUAL_CLOSE 2 true`, zero inventory mutations (24).
- Explicit inclusion with quest=true, then inEquipmentSet=true: Rules returned
  JUNK but AttemptSale returned false/STALE_OR_PROTECTED_ITEM; zero calls to
  fake UseContainerItem (7).
- No executable changes, live-client operation or publication.

### Final offline review closeout

Reran the complete `tools/check.py` with actual Lua/luac 5.1: exit 0; 67 core,
22 store, 8 service, 11 destroyer and 62 UI model fixtures passed, along with
transaction/UI interaction suites and reproducible 41-entry package validation.
Temporary output: /tmp/dejunk-review-closeout.log. No archives were published.
The review report is consolidated in numeric finding order with a final Persian
disposition and acceptance gates. Its 24 findings remain open; 15 have direct
reproductions. This closes the documented offline review round, not every-line
certification of all upstream/vendor code or in-client acceptance.

## Audit implementation — 2026-11-16

The later user instruction authorized implementing the findings. Current status
is in [FIXES-REVIEW-1.0.0.md](FIXES-REVIEW-1.0.0.md), separate from the historical
baseline review. Runtime, Store, cache, rules and production sale observation
have now changed. No live inventory operation was performed.

Added tests/review-regressions.lua to the mandatory check.py suite. It exercises
the actual Store, Application and transaction adapter with fake APIs. Updated
old test expectations where they encoded the defects (Default reset, opposite
membership, quest-class equipment predicate and Apply implicitly enabling a
filter). The stale-tooltip test now changes the adapter's binding read rather
than replacing CreateFrame after the tooltip has already been cached.

UI tests cover row reuse, scroll offset clamping, message levels and preserved
disabled threshold state. Transaction tests now exercise production observation:
dispatch is not confirmation, duplicate pending-slot requests are rejected,
unchanged slots time out, Unlock reports failure, disappearance confirms, and
confirmed run totals are emitted once. Confirmation reads only slot identity
instead of rescanning binding/equipment sets on every poll.

Full actual-Lua-5.1 check.py passed after these fixes, including the new review
suite; focused UI and transaction tests passed after follow-up additions.
Final rerun: check.py exited 0 (67 core, 22 store, 8 service, 11 destroyer,
62 UI-model tests, transaction/UI interaction and new review regressions).
Reproducible 41-entry package checks passed; git diff --check passed. Output was
saved to /tmp/dejunk-fix-final.log. Package checks created temporary archives
only. No new GitHub release asset has been published.

## 1.0.1 audit-fix release — 2026-11-16

Executed after the category and input fixes:

- `python3 tools/check_phase0.py`: passed research deliverables, links and pinned digests.
- `python3 tools/check.py --lua /workspace/work/lua51/usr/bin/lua5.1 --luac /workspace/work/lua51/usr/bin/luac5.1`:
  passed 67 core, 22 store, 8 service, 11 destroyer and 62 UI-model cases;
  production transaction, UI-interaction and review-regression fixtures passed.
- `git diff --check`: passed.
- Two independently built 41-entry ZIPs were byte-identical; checked runtime
  contents, CRC, layout, license notices and overwrite protection.
- No live WoW inventory calls or original-client visual tests were performed.

Category tests no longer encode the incorrect contiguous auction-ID assumption:
English label matching is order-independent and maps staff=10, shield=6,
fishing pole=20. Unsupported localized labels stay unknown. Threshold tests now
exercise enabled/disabled controls, delayed save, Enter and Escape. Native focus
handling, localization and third-party bag overlays still need client evidence.

## 1.0.2 — RichSteini Bagnon integration (2026-11-16)

Reviewed Bagnon revision `27a08f89819311d772e7ec7a71a41eafb813f122`.
See BAGNON-COMPATIBILITY.md for immutable source paths and client acceptance steps.
No reference code is bundled and no live inventory action was executed.

`python3 tools/check_phase0.py`, the complete `tools/check.py` suite with actual
Lua/luac 5.1, and `git diff --check` passed. New UI fixtures cover pre-existing and
new Bagnon widgets, pooled Blizzard button reuse, delayed loading, one-time secure
hooks, original callbacks/drag scripts, cached-character and bank exclusion,
stale links, SMALL/LARGE/off styles and rule-driven clearing. A production-store
fixture confirms that list changes trigger overlay refresh. Reproducible 41-entry
ZIP validation also passed. Original-client Bagnon visuals are not tested here.

## Unreleased audit continuation — delayed metadata and destroy observer

Actual Lua 5.1 full `tools/check.py` passed with delayed metadata (2.5 seconds),
five-second retry deadline and production destroy timeout/unlock fixtures. The
latter mock dispatch and never delete inventory. Original-client acceptance and
successful-destruction confirmation remain unverified.

## Unreleased audit continuation — conflicting actions

Actual Lua 5.1 suite and phase-0 checks passed with production callback tests
for manual sell/destroy while a seller is running, a sale is awaiting outcome,
or a destruction attempt is awaiting outcome. No live actions were performed;
original-client acceptance remains required.

## Unreleased audit continuation — coherent slot observations

Actual Lua 5.1 tests pass for direct probes and cached bag reads when metadata
changes during the binding tooltip scan. Both paths reject mixed observations.
No real-client operations were used; target-client acceptance remains outstanding.

## Unreleased asynchronous import validation

Lua 5.1 production callback fixtures cover delayed item-info response, bounded
batching, atomic result, timeout and stale-revision cancellation. Unavailable data
is reported as unavailable rather than conclusively invalid. No original-client
acceptance has been run, and direct list-add paths do not use this queue.

## Unreleased rules/store/API comparison

Actual Lua 5.1 checks passed after adding canonical/fallback unknown-refund,
legacy boolean protection, string-key quality migration/reload and exact public
API event-value fixtures. These are offline checks; no target-client run occurred.

## Unreleased Junk/Options UI comparison

Lua 5.1 fixtures verify Junk gear toggle without closing Junk, global child
control enable/disable and remembered values, reference equipment-type ordering,
and action-control busy state during pending outcomes. The original client was
not used and the new changes are not yet published.

## Unreleased profile-review checks

Lua 5.1 UI and store fixtures cover failed selected-profile duplication without
copying a different active profile, and reselecting the active profile without
changing the store revision. Offline checks do not prove live-client behavior.

## Unreleased transport focus comparison

The UI fixture verifies pressing Import releases edit focus and keeps the
transport window open. The queue is atomic, unlike the upstream per-item parsing
flow; unresolved and eligibility cases remain documented differences.

## Unreleased list and keybinding comparison

Lua 5.1 UI fixtures exercise Ctrl+Alt+right-click on the list title, preserving a
cursor item on right-click and limiting changes to the chosen list. Store tests
cover one change notification and no-op empty clear. Keybinding tests cover
legacy numeric 0/1 combat flags. Live-client pointer routing and input remain
unverified.

## Unreleased list viewport check

A fake-UI Lua 5.1 test scrolls a 300-item list while confirming a fixed pool of
12 item-row buttons for the fixture viewport, scrollbar seeking, drag cleanup,
and right-click behavior with an item on the cursor. Native 3.3.5 scroll-frame
clipping, scaling and pointer hit-testing still need client acceptance.

## Unreleased per-item import and generic API checks

Actual Lua 5.1 tests exercise mixed valid/unavailable/unsupported import IDs,
25-ID batches, timeout and profile changes after partial success. They also
verify generic IsJunk can classify a known refundable SELL-only item while the
explicit sale decision remains blocked. Real client/server responses and the
owner's in-game acceptance remain untested.

### Local source-review continuation

With Lua 5.1, `python3 tools/check_phase0.py`, `python3 tools/check.py --lua
/workspace/work/lua51/usr/bin/lua5.1 --luac
/workspace/work/lua51/usr/bin/luac5.1`, and `git diff --check` passed after the
direct list eligibility change. Tests use mock game APIs; original-client
acceptance remains outstanding. The change is local and unpublished.

### Safe Sell source-review continuation

`python3 tools/check_phase0.py`, `python3 tools/check.py --lua
/workspace/work/lua51/usr/bin/lua5.1 --luac
/workspace/work/lua51/usr/bin/luac5.1`, and `git diff --check` passed after the
Safe Sell selection change. The new mock fixture checks which entries are
selected as well as the 12-attempt limit. No live game actions were executed.

## Remediation batch 1 — UI click and minimap parity

Commands run from the addon root:

```sh
python3 tools/check_phase0.py
python3 tools/check.py --lua /workspace/work/lua51/usr/bin/lua5.1 --luac /workspace/work/lua51/usr/bin/luac5.1
git diff --check
```

All passed with actual Lua 5.1. The interaction fixtures check merchant frame
strata, supported versus unsupported modifier combinations, reference minimap
radius/corner placement, and repeated merchant tooltip entry without duplicate
lines. The package checker built two identical 41-entry archives in temporary
storage. Original-client visual acceptance was not run.

## Unreleased destruction outcome observer

The production fake-API transaction suite now checks destroy disappearance,
unlock failure, five-second timeout, duplicate suppression and the cursor-empty
guard. It uses no live inventory. The offline result follows the upstream
original-slot item-ID criterion; target-client confirmation remains outstanding.
