# Validation and completion report

Date: 2026-11-13. This report describes the current working tree, not a release.

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
   keybindings, profile/global option coverage, item presentation and game
   integrations remain incomplete, and some list controls are port scaffolding.
   The upstream cursor-item-to-list interaction is now restored in the UI
   adapter and covered by an isolated fixture. The generalized custom-rule
   editor has been retired from classification.
7. **Packaging:** deterministic development ZIP generation with overwrite
   protection. Earlier development ZIPs were uploaded to private review branches
   in the owner's GitHub repository; none is a release.
8. **Options state and thresholds:** migrated upstream global defaults into the
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
   A further client screenshot showed red Blizzard button art remained on Lists, profile actions and threshold Apply controls. The subsequent 3.3.5 client screenshot confirmed the red templates were removed but showed checkbox marks were not visible. Custom checkboxes now accept both boolean `true` and numeric `1` from `GetChecked`, and the interaction fixture exercises the numeric/`nil` return shape. All addon-created `UIPanelButtonTemplate` instances now use plain square controls with the upstream dark-grey background, gold label and black border; close controls use a grey X that highlights red on hover. The active-profile rename control is widened to prevent label truncation. UI interaction fixtures assert the screenshot-visible Lists and Apply buttons no longer use Blizzard red templates. This client appearance change has not yet been observed in game.
   The latest client screenshot exposed a WoW-specific positioning issue:
   native frames do not provide the mock-only `.point` field used by the width
   adjustment. The code now stores each quality row's vertical offset and each
   long description's horizontal offset explicitly; fixtures verify both are
   preserved during responsive layout. A fresh client screenshot is needed to
   confirm the corrected Profile Options rows appear inside their cards.

## Checks run for this report

Commands:

```sh
python3 tools/check.py --lua /workspace/work/lua51/usr/bin/lua5.1 --luac /workspace/work/lua51/usr/bin/luac5.1
python3 tools/check_phase0.py
git diff --check
```

Results: Lua 5.1 syntax for 24 files passed; runtime suite **59 passed, 0
failed**; store **21 passed**; service **8 passed**; destroyer **11 passed**;
UI model **62 passed**; UI interaction flows passed. TOC/API read-only boundary,
documentation and package checks passed. Two generated ZIPs were reproducible
and passed content, layout, CRC and overwrite checks. `tools/check_phase0.py`
passed its 31 required deliverables, 45 Markdown files, 54 local links, 39 source
digests and 153 API references. `git diff --check` passed. These offline checks
do not validate WoW rendering or inputs.

## Still required to complete the upstream port

1. Port the original Dejunk main window and associated list, profile/global
   options, keybinding and transport screens without redesign.
2. Port the original item presentation and integration points (tooltips, bag
   icons, junk/lootable frames, merchant controls and minimap behavior) using
   only APIs available in 3.3.5a.
3. Finish upstream seller and repair behavior, then upstream one-item destroy
   behavior. Current services are simulation-only; do not infer live safety or
   parity from their passing tests.
4. Run non-destructive UI and compatibility smoke checks in the original
   build-12340 client; capture errors and screenshots for layout/input review.
5. Complete transaction review and the separate authorization gate in
   `AGENTS.md` before wiring or testing any live inventory mutation.
6. Run the full regression/package checks again, review migration/recovery and
   licenses, and prepare a release candidate only after parity evidence exists.

### Client check status

**Client check:** the owner confirmed the minimum item level value survived
`/reload`. Screenshots then exposed threshold overlap, unsupported legacy EditBox
methods and options rendered as a detached overlay. The options screen has now
been corrected and all content screens follow the Waffle selector model. Offline
fixtures check screen exclusivity, sibling parenting, layout sizing, section
order, scroll content size and card bounds. The latest screen-controller change
still needs one consolidated visual check in WoW. No live sale, repair or delete
test was performed.

## Historical evidence

The prior phase-by-phase validation entries were consolidated here because
they recorded intermediate results as if they were current acceptance. Specific
legacy-client evidence remains in `docs/research/CLIENT-12340-*.md`; consult its
revision and limitations before relying on it. The screenshots in the project
history exposed real UI errors and layout problems, which is why current
automated model checks are not treated as proof of client correctness.
