# Dejunk-WotLK case study

This is project knowledge, not a universal specification for all addons.

## Reference and target

- Reference: moody/Dejunk **3.5.1**, pinned commit
  `04bafd5e411441ef5b51bb8ed10d208f2d7758f5`.
- Target: original WoW 3.3.5a/build 12340/Interface 30300/Lua 5.1.
- Published community beta: `v0.16.60-beta.1` in brok5522/Dejunk-WotLK.
- Publication source commit: `11b0a2dc04ba2a84a55632052f81a95f342f8785`.
- User-requested deviations: visible target label 3.3.5, adjusted legacy merchant
  placement, and explicit window-layer behavior for the original-client UI.

## Intended product semantics

Five screens: Lists, Global Options, Profile Options, Profiles and Keybindings.
Four lists: global/profile inclusions/exclusions. Separate Junk and Lootable
windows, per-item actions, minimap and merchant shortcuts, footer navigation.

Pinned filter precedence:

1. Enabled upper item-level and stack-price exclusions.
2. Profile Exclusions.
3. Profile Inclusions.
4. Global Exclusions.
5. Global Inclusions.
6. Remaining configured Exclude rules.
7. Configured Include rules; no match is kept.

Defaults include Poor quality; Auto Sell, Auto Repair and Safe Sell off; Safe
Destroy on. Include by Quality, Exclude Equipment Sets and Exclude Quest Items
are enabled in the pinned reference. Retail-only relic/warband/compartment
features do not belong in an original 3.3.5a port.

## Lessons and completed fixes

- A newly added transactions file was not reliably present/loaded in installations.
  Guard missing modules, verify TOC/load order and ship a clean folder. The port
  ultimately embedded the adapter in the always-loaded compatibility runtime.
- Layout library availability did not imply screen parity. Native templates,
  labels, icons, controls, footers, copy behavior and input routes needed explicit work.
- Four list panels gained proper scope colors, transport/loading icons, real item
  drops, bounded metadata polling and modifier transfer behavior.
- Search/name/number inputs had duplicate native borders. Plain custom EditBoxes
  fixed them. The Transport X needed an actual hit area.
- Escape required native special-frame registration and focused-input handling.
- Direct frame hiding desynchronized Waffle visibility. Reopen tests caught blank
  Lists through the minimap and direct Escape dismissal.
- Shared scroll tracks replaced decorative native arrow templates in five windows.
- The merchant button was moved away from the portrait and name; old default
  saved positions were migrated. Custom dragged positions were retained.
- A merchant-state local declared after a card factory caused the tooltip to read
  a global. Moving shared declarations before closures fixed context reporting.
- Footer labels became interactive; reopening preserves the selected page;
  profiles commands toggle their target screen.
- Action-specific sale selection skips destroy-only rows. Busy state, bounded
  settling, session/revision cancellation and failed-dispatch cap tests were added.
- Delayed repair rechecks the originating session and preference. Destroy intents
  are copied, single-use and invalidated by Cancel or settings changes.
- Root MIT alone was incomplete for artwork. Publication added Cash/Lorc and Font
  Awesome Creative Commons attribution alongside Waffle's MIT notice.

## Evidence available at publication

Local actual-Lua-5.1 checks: 64 runtime, 21 store, 8 service, 11 destroyer-model,
62 UI-model scenarios, plus UI-interaction and transaction/action-lifecycle fixtures.
These counts describe that snapshot, not a permanent quality threshold.

The owner supplied native-client screenshots and reported the principal UI and
merchant placement functioning on 0.16.59. The 0.16.60-beta.1 publication changed
metadata, docs/notices and packaging; it did not introduce another behavioral rewrite.
Both GitHub validation and release/cleanup workflows succeeded. The release ZIP
had 41 entries and SHA-256:
`6642e82341ec56ff1be3d5c96e13eae8876bfafc8e7b1b334f207faa4181d86d`.

## Explicit remaining limits

Do not say the port is exactly complete. At publication, Lootable acceptance in
client was not performed by the owner because no suitable item was available.
Localization, third-party bags, generic/cosmetic/fishing-pole and category-crosswalk
edge cases, parser semantics/progress, exact chat behavior and transaction outcome
observation remained under review. Classification is more conservative in some
unknown/protected cases; manual action eligibility can differ from upstream.

The research snapshots contain historical statements such as "not connected" or
"no vendored dependency" which were later superseded. Use the publication source
and current project evidence before applying an old statement to current code.
