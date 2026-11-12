# src/ui

Phase 6 provides native settings and profile windows, plus a list editor for
global/profile inclusions and exclusions in four panes, with search by item ID
or cached item name. Add/remove uses an item ID; each pane shows six matches at
a time. Clicking a row selects its ID and its corresponding scope/list for the
Add or Remove action. Icons and names use cached item metadata when available;
otherwise the row falls back to its item ID. The Lists page has bulk Import
and Export controls; imports preview new and existing IDs before the user
commits them. `/djw lists` remains available as a chat-command fallback.
The rules screen creates/removes single-predicate profile rules with action,
result, field and comparison controls. Poor-quality toggle and item previews
remain read-only. Options provide quality toggles and item-level/vendor-value
thresholds. Profile create/duplicate/rename are in the UI; reset/delete require
confirmation dialogs. Multi-condition groups remain future work; the import
dialog and copy panel need original-client review.
