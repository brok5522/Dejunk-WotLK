# src/ui

Phase 6 uses the pinned upstream Waffle layout engine from the original Dejunk
project for the main window and top-level configuration/report windows. The
interior screens are being migrated; their controls still use legacy-compatible
native WoW widgets while Waffle handles window creation and layout. Original
Waffle visual components that depend on APIs absent from 3.3.5a are not copied
blindly. Target-client verification is still required.

The current port-built configuration has an 800×640 Waffle root with a sidebar
and content region. Overview, Lists, Profiles, Global Options and Profile
Options are sibling Waffle screens. A single screen controller marks the
previous screen `GONE`, selects the new screen and lays out the root, following
the pinned upstream `MainWindow` controller flow. Embedded screens are no
longer manually sized dialog overlays.
Profile Options now follows the upstream screen's scrollable General, Include
and Exclude groups and card order. The cards include the panel description,
option descriptions, divider-separated settings lines, card-wide toggle
behavior, action-scope and quality chips, and gold/silver/copper inputs for
price limits. Controls cover quality, four item-level and stack-price
thresholds, and localized armor/weapon type filters. These are rebuilt with
legacy 3.3.5 widgets inside the project's Waffle main window; the upstream
quality rows and cards resize to the actual content width so the fifth quality
and its clickable caption stay inside the scroll panel at narrow resolutions.
OptionCard/SettingsBox visual components are not yet ported pixel-for-pixel,
and checkbox captions use separate clickable text regions because the legacy
CheckButton template has no `SetText` method. Checkboxes stay at their native
size so their template art is not stretched. Global Options now follows the
upstream Safety, Interface and Bags group order, with cards for the stored
options and choices for chat detail and icon size. These settings update saved
state, but merchant, minimap, bag icon/tooltip, chat and frame integrations are
not connected yet. The native OptionCard/SettingsBox visuals are not pixel
identical to Waffle, and target-client review remains pending.
The list editor provides
global/profile inclusions and exclusions in four panes, with search by item ID
or cached item name. Search treats input literally and de-duplicates repeated
IDs. List presentation sorts resolved items by quality and name, with unknown
metadata last; serialized import/export order remains numeric. Add/remove uses
an item ID; each pane shows six matches at a time. Clicking a row selects its ID
and its corresponding scope/list for the Add or Remove action. Icons and names
use cached item metadata when available; otherwise the row falls back to its
item ID. The Lists page has bulk Import and Export controls; imports preview new
and existing IDs before the user commits them. `/djw lists` remains available as
a chat-command fallback.
Right-click removal and Shift/Ctrl/Alt-right-click transfers now follow the
upstream list mapping. Left-click selection and explicit ID editing remain
temporary development controls and are not UI parity.
Uncached item metadata is requested in batches of at most 25 IDs per UI refresh;
the Lists frame polls only while open and stops after 30 seconds if data never
arrives. This avoids relying on a newer item-info completion event.
SELL and DESTROY previews open a read-only report with one decision per bag
slot and totals for eligible, kept and unknown items. Closing the report
returns to the configuration window. This screen is development scaffolding,
not the original Dejunk main window. Its former custom-rule controls are being
removed because they do not exist in upstream Dejunk. Options and reports also
need to be replaced by/adapted from the pinned upstream screen components.
The main window's sidebar styling, exact upstream components, keybinding screen,
item presentation, junk/lootable frames and game integrations remain unfinished.
Profile/list widgets are not accepted as full UI parity until original-client
review.
