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
