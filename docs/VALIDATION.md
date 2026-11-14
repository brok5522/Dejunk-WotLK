# Validation and completion report

Date: 2026-11-14. This report describes the current working tree, not a release.
The exhaustive feature comparison is in [PARITY.md](PARITY.md).

## Current result

The automated compatibility and regression checks pass. The addon is **not
complete and is not release-ready**: the original Dejunk screens are not fully
ported, live selling/repair/destruction are intentionally disconnected, and the
current UI has not been exercised in the original client at this revision.

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
   rows; bag and saved-state updates refresh them. No action buttons are
   connected. UI fixtures check opening/toggling, reasons, and stale-row
   removal; target-client rendering still needs a consolidated check.
11. **Read-only Lootable window and command routing:** `/dejunk loot` shows
   positively flagged slots and `/dejunk profiles` opens Profiles. The saved
   Auto Lootable Frame option controls display on bag updates; it never opens
   items. Fixtures cover positive-flag filtering, invalid snapshot rejection,
   window toggle and original command routing. `/dejunk` and `/dejunk options`
   now toggle the settings window, with offline screen-state coverage.
12. **Auto Junk display:** during a merchant session the saved option can show
   the read-only candidate window; it closes at merchant close and when its
   auto-shown list becomes empty. Mock event fixtures assert no item mutation.
13. **Bag item tooltip reasons:** a single `GameTooltip:SetBagItem` post-hook
   reads the slot again and displays separate SELL/DESTROY decisions and reason
   codes when item tooltips are enabled. The hook skips the hidden binding scan
   tooltip and is registered once. Mock tooltip coverage is offline only.
14. **Transport export flow:** Export and Import now share the transport window;
   export fills a comma-separated list and selects the text for manual copying,
   while import keeps the review-before-commit path. UI fixtures cover both.
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

Results for current working tree `0.16.43-dev`:

- `check_phase0.py`: PASS (31 required deliverables, 46 Markdown files, 57
  local links, 41 source digests and 153 legacy API references).
- `check.py`: PASS (20 ordered runtime files; Lua 5.1 syntax for 27 files;
  runtime 64/64, store 21/21, services 8/8, destroyer 11/11, UI model 62/62;
  UI interaction fixtures passed, including keybinding capture/overrides;
  deterministic 27-entry ZIP verified).
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
Coin, trash, selling and destruction controls stay disabled because live
inventory actions require the separate owner review in `AGENTS.md`. Lootable
has an item count and eye-slash control; ignoring an item hides that item ID for
the current session. Item use stays disconnected. Lua fixtures cover sizes,
assets/states, stack value, session ignore and disabled actions. Merchant button
and live transaction/chat integrations remain absent.

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
2. Port and review seller, repair and one-stack destroy behavior. Current
   services are simulation-only. `AGENTS.md` requires review plus separate
   owner authorization before connecting any inventory mutation to the live
   client; no destructive test is needed for the next UI check.
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
