# Validation strategy

## Phase 0 (available offline)
`python3 tools/check_phase0.py` checks required deliverables, local Markdown link
resolution, immutable source/checksum manifest, API inventory format, intended
scaffold and absence of executable addon artifacts. `git diff --check` checks
whitespace. This is a foundation check, not an addon test suite. CI runs the same
checks; no game credentials or network downloads are required by the validator.

## Phase 1 onward (not yet executed)
Use an actual Lua 5.1 interpreter/compiler. Add `luac5.1 -p` for every runtime and
test file, explicit TOC/XML graph checks, localization keys and a minimal offline
harness with legacy tuple APIs. No globally permissive modern API fallback mocks.
Pure modules must load with no WoW globals; only mocked adapter calls are allowed
for transaction tests. Every test run resets globals, store and scheduler state.

Required behavioral cases:
- Every rule/action scope, list conflict and precedence, exact thresholds,
  zero/nil prices, whole-stack prices, cloak/type exceptions and no-match keep.
- Unknown cache data, failed retry, locked slots, no vendor value, quest/set
  protection, same-ID distinct links, duplicate equipment-set items, locales and
  heirloom/account-bound handling.
- Profile copying without aliasing, deleted active profile, cross-character
  assignment, malformed/future schemas, idempotent migrations and import limits.
- Sell request away from vendor, merchant close/reopen/change during delay,
  12 attempted-stack cap across repeated starts, partial failure, refund, lock,
  failed call, event reordering, bag-update storms and settings change.
- Popup displayed then item moved/replaced/split/merged; same ID with different
  enchant/link/count; bag-generation change; cancellation and duplicate accept;
  cursor occupied before click or pickup failure; unexpected cursor identity.
- Timeout and ambiguous result: no retry and no false success. Unrelated bag
  moves and money changes must not prove sale/destruction.
- Repair capability/funds/cost change, repeat events and merchant generation.
- UI bag frame reuse/open ordering, overlays cleanup, tooltip scan recursion,
  nil font/texture, popup focus, Escape, scrolling, binding conflict and combat.

## Client verification gates
The execution environment has no WoW client. Original build 12340 must verify
startup, legacy function return shapes, localized strings, event payloads and
frame methods. Begin with read-only capability probes. Later, real transaction
checks require explicit owner authorization and a disposable test character and
items; never run automated tests against the owner's normal bags. Neither mocked
success nor Wrath Classic results establish original-client compatibility.

Release must include recorded client version, tested locale(s), bag addon version
if any, observed results, unresolved limitations, reproducible ZIP layout and
SavedVariables backup/recovery guidance. Check performance on full bags and event
storms with bounded scans/retries; set numeric budgets after measurement.
