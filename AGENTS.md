# Permanent project instructions

## Scope and approval
- Target only the original World of Warcraft **3.3.5a, build 12340, Interface 30300, Lua 5.1**. Wrath Classic is a different API and is not evidence of compatibility.
- The owner explicitly said “ادامه بده” after Phase 2, authorizing continued development. Phase 3 scope is the pure rules engine, persisted declarative profile rules, and read-only bag preview. No inventory mutation, selling, repair, item use, or transaction pathways are authorized by that instruction. Continue through the roadmap without asking the owner to restate the project goal; stop before Phase 4 inventory transactions.
- Never perform destructive inventory operations during development or verification. Do not connect automation to a live character's inventory. Use mocks and read-only probes. Future real-client transaction tests require separate explicit authorization and disposable items.
- Do not publish releases, merge PRs, or enable automatic merging without owner authorization. Preserve existing user changes.

## Engineering
- Read README.md and docs/ROADMAP.md first, then the relevant architecture, safety and compatibility documents.
- Use Lua 5.1 syntax; do not assume LuaJIT, newer Lua, Retail or Classic services. Keep all game API access behind src/compat. No global C_* or Enum shims to disguise missing APIs.
- Prefer small modules and explicit TOC order. Pure rule and store modules must run without WoW. UI only renders state and issues commands; it never mutates inventory directly.
- Unknown item, lock, binding, quest, refund, price or equipment-set data must block the relevant unsafe action. Missing data is not equivalent to false or zero.
- Re-read slot identity, full item link, count, lock, cursor, rule revision and relevant context immediately before a transaction and after confirmation. Cancel stale intents; never silently redirect them to another slot.
- Destruction is one stack per deliberate user action, confirmation on by default, never automatic on bag updates or merchant opening. Never clear a pre-existing cursor item to make room.
- Default auto-sell and auto-repair off. Proposed port default Safe Sell on (12 attempted stacks per merchant session); document differences from upstream. Safety policy has priority over inclusion lists.
- Preserve SavedVariables; namespace DejunkWotLKDB, version schemas and migrate copies. Never execute imported text as Lua. No arbitrary user scripts for custom rules.
- Pin every vendored library by revision and checksum, audit transitive dependencies, keep required license notices. No unpinned latest externals. Phase 0 vendors no libraries or upstream runtime/assets.
- Evidence must include immutable source revisions and file/line references. Distinguish observed source behavior, proposed design and unverified client behavior.

## Validation and handoff
- Run `python3 tools/check_phase0.py` (research/document checks), `python3 tools/check.py` (TOC, read-only boundary, Lua 5.1 syntax and behavior), and `git diff --check`. The historical no-runtime Phase 0 check was retired after Phase 1 authorization. Use actual Lua 5.1, not only modern interpreters or modern API mocks.
- Record commands, results and skipped checks honestly in docs/VALIDATION.md. Never claim in-game compatibility from offline checks.
- Add meaningful tests for rules, safety, migrations and transactions as those modules are implemented. Required scenarios are in docs/TESTING.md.
- Update roadmap, compatibility and safety docs when decisions change. Explain results and remaining limitations to the owner in Persian, in non-programmer language.
