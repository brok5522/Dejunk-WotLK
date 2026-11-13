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
   Waffle main window. A client screenshot exposed Profiles controls remaining
   visible over Lists; page switching now hides inactive screens, with an
   interaction fixture for that exact route. Options callbacks also follow the
   currently active page. This is still not the pinned upstream UI port: original
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
   interactions and coin conversion. Native 3.3.5 controls still approximate
   the pinned Waffle OptionCard/SettingsBox visuals; this layout has not been
   inspected in the client. Other upstream screens and integrations remain
   unfinished.

## Checks run for this report

Command:

```sh
python3 tools/check.py --lua /workspace/work/lua51/usr/bin/lua5.1 --luac /workspace/work/lua51/usr/bin/luac5.1
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
`/reload`. A later screenshot exposed overlap among the threshold rows. The
current scrollable grouped layout has not been run in WoW yet. Automated layout
fixtures now check section order, scroll content size and card bounds, but do not
prove rendering in the game. No live sale, repair or delete test was performed.

## Historical evidence

The prior phase-by-phase validation entries were consolidated here because
they recorded intermediate results as if they were current acceptance. Specific
legacy-client evidence remains in `docs/research/CLIENT-12340-*.md`; consult its
revision and limitations before relying on it. The screenshots in the project
history exposed real UI errors and layout problems, which is why current
automated model checks are not treated as proof of client correctness.
