# Phase 0: research and architecture for original WotLK 3.3.5a

Modern Dejunk 3.5.1 relies on APIs and UI behavior absent from original build
12340. This PR pins the source baseline, documents legacy replacements and
uncertain client behavior, and prepares a safety-first architecture and phased
feature roadmap targeting Interface 30300 and Lua 5.1.

Includes permanent AGENTS instructions, dependency/license decisions, source
checksums and API inventory, repository scaffold, offline foundation checks and
CI, and Persian owner review instructions. No executable addon or inventory
operation is implemented. Phase 1 requires explicit owner approval.

Validation: `python3 tools/check_phase0.py` and `git diff --check` (see
`docs/VALIDATION.md` for actual results). No original-client or runtime tests;
there is no runtime in this PR. Review documented safety differences from upstream
and outstanding client probes before approving implementation.
