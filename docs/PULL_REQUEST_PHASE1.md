# Phase 1: read-only foundation for original WotLK build 12340

The repository now has an installable diagnostic foundation targeting Interface
30300 and Lua 5.1. It validates the exact client before activating bag reads,
normalizes legacy tuple APIs, coalesces bag events into generation-based defensive
snapshots and retains incomplete safety data as unknown. Opt-in slot probes and
a copyable report collect sanitized API/event evidence for original-client checks.

Adds a private bootstrap, event bus, cancellable scheduler, dependency-free legacy
adapter/report bridge, 42 offline behavioral cases, actual Lua 5.1 syntax checks,
CI, deterministic diagnostic ZIP packaging and Persian installation instructions.
There is no sale/deletion/repair/item-use API or SavedVariables implementation.
The newly written port code uses MIT; no upstream runtime or artwork is bundled.

Validation: `python3 tools/check.py` with Lua/luac 5.1.5 passed; 42 cases passed;
research/docs, whitespace, Python compilation, ZIP reproducibility/CRC/layout
checks passed. Actual original-client startup, native report UI and API signature
acceptance remain PENDING; this is not a completed addon or release. See
`docs/VALIDATION.md` and `docs/CLIENT-ACCEPTANCE.md`.

Branch is based on Phase 0 commit f644c09. Merge the Phase 0 branch first if a
Phase-1-only diff is desired against the default branch. Do not proceed to Phase
2 until owner approval and recorded client acceptance.
