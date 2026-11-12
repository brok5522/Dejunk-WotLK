# Phase 0 validation record

Date: 2026-11-12. Repository base: `a749c4a` (initial README-only checkout).
Working branch: `phase-0/research-and-architecture`.

## Performed
- Inspected pinned Dejunk and original-client FrameXML mirror; recorded examined
  source file SHA-256 hashes and immutable commits. No upstream Lua was executed.
- Ran `python3 tools/check_phase0.py`: **PASS**: 31 required deliverables,
  26 Markdown files, 28 local links, 36 source digests and 153 API references.
- Ran `git diff --check` and `git diff --cached --check`: **PASS**.
- Ran `python3 -m py_compile tools/check_phase0.py`: **PASS**.
- Cross-checked downloaded source hashes against the committed manifest and
  inventory references against actual upstream lines using a local research check:
  **PASS**, all 36 digests and all 153 line references matched.
- CI workflow prepared to run foundation validation on pushes and PRs; GitHub CI
  has not been run by this session.

## Limits
No lua/lua5.1/luac/luac5.1 binary was found in the initial PATH. No interpreter
installation was needed because no runtime Lua is delivered. Lua syntax, rule,
service and in-game tests are **not run**, not counted as passing. No WoW client
is available here. Static FrameXML evidence does not prove behavior on the target
server or a modified private-server client. Client probes are a Phase 1 gate.

This validation checks documents and scaffold only, not completed addon behavior.
No sale, pickup, cursor clear, destruction, repair or item-open operation ran.

# Phase 1 validation record

Phase 0 above is historical. Phase 1 was explicitly authorized by the owner.
Branch: `phase-1/read-only-foundation`, based on Phase 0 commit `f644c09`.

## Toolchain
The system initially had no lua5.1/luac5.1. An official Debian binary package
`lua5.1_5.1.5-9_amd64.deb` was downloaded over HTTPS from
`https://deb.debian.org/debian/pool/main/l/lua5.1/` and extracted under
`/workspace/work/lua51`, without system installation or repository vendoring.
Package SHA-256: `2abaa116e03f4aaf34de634b447e7fa11569e27b33de342e93bbcf0857694015`.
Both binaries report Lua 5.1.5. CI installs distro lua5.1 separately.

## Checks performed
```sh
python3 tools/check.py --lua /workspace/work/lua51/usr/bin/lua5.1 --luac /workspace/work/lua51/usr/bin/luac5.1
python3 -m py_compile tools/check.py tools/check_phase0.py tools/package.py
git diff --check
git diff --cached --check
```

- **PASS:** exact Interface 30300 TOC, nine ordered runtime files, no omitted
  runtime files, and read-only/game-global boundary checks.
- **PASS:** actual Lua 5.1 syntax compilation for nine runtime and two test files.
- **PASS:** **42 behavioral cases, zero failures**, using isolated synthetic legacy
  tuples and mutation sentinels; no inventory mutation calls were made.
- **PASS:** research/source-manifest/API-inventory structure and local doc links.
- **PASS:** Python syntax compilation and tracked/staged whitespace checks.
- **PASS:** two deterministic diagnostic ZIP builds compared byte-for-byte;
  archive CRC, exact 12-entry single-folder layout, source content and refusal
  to overwrite existing outputs checked. Package smoke outputs stay outside Git.
- CI configured for all pushes/PRs; **GitHub CI not run in this session**.

## Remaining acceptance
**NOT RUN / PENDING:** real build-12340 startup/reload, legacy C API signatures
and nil-flag meanings, native report-panel UI/scroll/copy, localized tooltip
semantics and actual event delivery. No client is attached here. Test fixtures
do not establish game compatibility; report UI tests exercise fallback, not a
mock pretending to prove widget compatibility. See
[CLIENT-ACCEPTANCE.md](CLIENT-ACCEPTANCE.md) for the evidence checklist and the
[Persian guide](PHASE1.fa.md) for read-only instructions. Phase 2 must wait for
this evidence and separate owner authorization.

This build contains no sale, pickup, cursor-clear, destruction, repair, item-open
or SavedVariables implementation. The declared Phase 1 APIs are read-only.

## Follow-up: owner client evidence
The owner supplied an enUS 3.3.5/build-12340/Interface-30300 report with READY,
zero callback errors and an occupied Hearthstone probe. Original-client startup,
that sample's tuple shapes and copied report output now have user evidence;
reload, empty-slot evidence, native-panel controls, positive safety states and
merchant/error event delivery remain pending. Exact source commit/client
modification status was not included. See
[the sanitized record](research/CLIENT-12340-01.md) and the updated acceptance table.

A regression fixture reconstructed from the reported public metadata/tuple
shapes verifies that nil lock/quest flags and a successful zero-return purchase
call remain unknown. No runtime code or safety policy changed. The full Lua 5.1
suite was rerun: **43 passed, zero failures**; TOC, boundary, documentation links,
syntax and deterministic package checks passed. Historical 42-case results above
refer to the initial Phase 1 implementation. No new addon download is required
for this documentation/test-only follow-up.

## Follow-up 02: empty-slot and event evidence
The owner's second report confirms EMPTY for bag 0 slot 16 with a successful
zero-return container call, current cache generation 21, eight occupied slots
and zero callback errors. BAG_UPDATE and ITEM_LOCK_CHANGED/LOCKED/UNLOCKED
payload shapes were delivered in the real-client history. A later READY
screenshot responded to the reload/status request; the reload command sequence
itself was not captured. See [evidence 02](research/CLIENT-12340-02.md).

Added a zero-return empty-slot regression case: empty probes must not query
metadata, quest/refund APIs or binding tooltips. **44 Lua 5.1 cases passed, zero
failures**; syntax, source boundary, documentation and ZIP checks also passed.
No runtime changes; no new download required. Remaining client checks are listed
in the acceptance table, and Phase 2 remains unauthorized.

## Follow-up 03: merchant events and basic smoke summary
The owner's third report records MERCHANT_SHOW and two MERCHANT_CLOSED events,
all with zero arguments, while READY, callbackErrors=0 and current cache
validity are preserved. This confirms delivery, not just registration. The
basic owner read-only smoke sequence is now successful for the reported enUS
12340 client; broader coverage remains partial. See
[evidence 03](research/CLIENT-12340-03.md) and the acceptance table for limitations.

This follow-up changes documentation only: no runtime or tests changed and no
new addon download is required. Research/document/link validation and whitespace
checks passed; the last behavioral result remains **44 passed**. No additional
broad runtime test run was needed for these documentation changes. Phase 2 has
not started and no inventory operation has been added or executed.

# Phase 2 status
The owner authorized Phase 2. Versioned storage, profile lifecycle, list edits and import/export previews are implemented on the local branch. Phase 1 results do not validate Phase 2. Phase 2 checks have not been run. Do not install this branch until validation is completed.

Phase 2 final run: 44 Phase 1 fixtures and 9 store cases passed with Lua 5.1. All 13 runtime/test Lua files compiled. TOC boundary, docs, package layout/CRC/reproducibility checks passed. Original-client SavedVariables persistence and slash command behavior remain for owner verification.

Owner Phase 2 client evidence: the user created `profile-1` named `Test`, added
item ID 6948 to global inclusions, ran `/reload`, and confirmed both the active
profile and list entry persisted. The evidence is recorded in
`docs/research/CLIENT-12340-04.md`. A reload persistence regression case now
models the same store serialization/reinitialization sequence.

# Phase 3: rules and read-only preview

Added a pure evaluator, validated profile rule persistence and `/djw preview
sell|destroy`. The preview reports each cached bag slot with KEEP/JUNK/UNKNOWN
and a stable reason; it refuses an invalidated snapshot. It has no inventory
mutation path. Rule protection and list precedence have table-driven coverage.

Lua 5.1 validation: **49 behavior cases passed, 0 failed; 11 store cases passed**.
All 15 runtime/test Lua files compiled. Source boundary and TOC checks passed;
deterministic 15-entry ZIP, CRC and overwrite-protection checks passed.
Original build-12340 verification of the new preview/rule commands is pending.
