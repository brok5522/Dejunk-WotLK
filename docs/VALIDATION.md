# Validation and completion report

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
