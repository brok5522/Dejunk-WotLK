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
