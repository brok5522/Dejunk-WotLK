# Phase 2: account store, per-character profiles and item lists

Adds `DejunkWotLKDB` schema v1 and a defensive store for global settings,
character-to-profile assignment, profile lifecycle, and global/profile inclusion
and exclusion lists. Import uses bounded decimal IDs, preview/revision checks and
an atomic commit; export is sorted plain text. Future schemas remain read-only.
Slash commands expose profile and list management. The phase contains no rule
evaluator or inventory operation.

Validation: actual Lua 5.1 syntax; 44 Phase 1 cases and 9 store cases; TOC,
read-only boundary, docs and reproducible 13-entry package checks. Real-client
SavedVariables persistence and slash command behavior should be checked with the
Persian guide. The existing read-only client smoke evidence does not cover this
new store.
