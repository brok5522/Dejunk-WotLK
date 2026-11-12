# Phase 2: configuration store, profiles and lists

Authorized by the owner. This phase covers persistent settings, character to
profile assignments, profile lifecycle, global/profile inclusion and exclusion
lists, and validated text import/export previews. It does not add classification
rules, configuration UI or inventory operations.

`DejunkWotLKDB` is declared as a single account SavedVariable. Schema version 1
starts with a protected `default` profile, empty global/profile lists and an
explicit character map. Character keys use realm, ASCII unit-separator, and
character name. Runtime access to identity stays behind the compatibility layer.

The store deep-copies and validates fields. Future schema versions enter
read-only mode. Collection and ID sizes are bounded. Profile copies are
independent; Default cannot be renamed, reset or deleted. Deleting a profile
moves assigned characters to Default. Mutations increment a revision and
persistence subscribers receive defensive snapshots.

List import accepts plain decimal IDs separated by whitespace, comma or
semicolon, rejects other text and oversized input, and returns a preview.
Commit rejects stale previews and applies additions atomically. Export sorts IDs.
No pasted data is evaluated as Lua.

Phase 2 validation and in-game checks have not been run. Prior Phase 1 results
do not validate this implementation. This branch is not ready to install pending
review and validation.
