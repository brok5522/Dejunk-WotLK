# Development roadmap and feature parity

Phases 0, 1 and 2 are complete; the owner also verified Phase 3 preview output.
Phases 4 and 5 mock-only seller, repair and destruction kernels are implemented
and tested. No transaction code is connected to live game APIs.
Broader acceptance is **partial**, with explicit unobserved cases in
docs/CLIENT-ACCEPTANCE.md. Later phases are ordered by dependency; estimates
are intentionally withheld until original-client API probes resolve uncertainty.
Each phase ends with a reviewable PR, updated evidence and owner acceptance.
No phase implies permission to perform live inventory operations.

| Phase | Deliverables | Acceptance / exit gate |
| --- | --- | --- |
| 0 — Research and foundation | Pinned upstream and legacy sources, API/dependency audit, architecture, safety policy, roadmap, AGENTS, scaffold, offline CI | Offline checks pass; limitations recorded; owner reviews and approves Phase 1 |
| 1 — Read-only client foundation (implemented; basic client smoke observed, broader acceptance partial) | Lua 5.1 harness, metadata-only target guard then bootstrap, Interface 30300 TOC, events/scheduler, readonly capability probes, normalized bag snapshots | Wrong builds rejected, nil/uncached/locked cases covered; original 12340 startup and read-only evidence recorded; no mutation adapter enabled |
| 2 — Store, profiles and lists (complete) | Versioned DB, defaults, four lists and import/export parser; profile create/duplicate/switch/rename/reset/delete and character assignment | Offline fixtures pass; owner confirmed reload persistence for profile and global list |
| 3 — Rules and preview (implemented; client observed) | Action scopes and precedence plus safety gates; declarative profile rules, explanation codes, equipment/quest/refund/binding protection; read-only bag preview | 50 behavior cases, 11 store cases pass; owner observed 1 JUNK, 1 UNKNOWN, 14 KEEP; no transaction path |
| 4 — Safe selling and repair (simulation only) | Mock-only transaction kernel; stale identity/settings rejection, repeated-start 12-attempt session cap, ambiguity handling, merchant/context cancellation, mock repair gates | 7 service cases plus other suites pass; no production adapter or inventory call; explicit authorization needed before real-client tests |
| 5 — Single-stack destruction (simulation only) | Frozen one-stack intent, mandatory confirmation callback, identity/generation/settings revalidation, cursor identity check; no live adapter | 11 destroyer cases pass for stale/split/replaced items, expiration, empty cursor, unexpected cursor and double confirmation; no real delete call or client test |
| 6 — Complete UI and integrations | All config screens, profiles, searchable lists and import/export, custom rule builder, junk/loot frames, tooltips, bag icons, minimap, commands/bindings, public query/events API | Every backlog row below has UI and behavioral evidence; localization/focus/scroll/combat checks; default bag mapping proven; third-party versions individually tested |
| 7 — Release candidate | Performance limits, diagnostics, full regression, upgrade/recovery docs, packaging/license manifest, install/user docs, release checklist | Actual 12340 acceptance recorded; clean Lua 5.1 checks and tests; correct single-folder ZIP; owner approves publication separately |

## Feature acceptance backlog
| Feature | Phase | Required behavior / evidence |
| --- | --- | --- |
| Automatic and manual selling | 4 | Opt-in automation, eligibility reasons, refund protection, merchant-session cancellation, 12-stack cap |
| Safe destruction | 5 | Single stack, explicit action, confirmation on, stale intent and cursor tests |
| Custom rules | 3 + 6 | Declarative all/any predicates and order; SELL/DESTROY/BOTH scope; no executable imports |
| Inclusion/exclusion lists | 2 + 3 + 6 | Global/profile lists, search, drag/drop and bindings, validated import/export, precedence tests |
| Quality, level, price, equipment rules | 3 + 6 | Stack copper thresholds and strict boundaries, per-quality toggles, verified classes including WotLK relics |
| Quest, unbound and equipment sets | 1 + 3 | Tri-state read-only evidence; mandatory quest/set gate; duplicate set IDs conservatively protected |
| Profiles | 2 + 6 | Shared per-account profiles, character assignments, lifecycle and migration persistence |
| Auto-repair | 4 | Off by default, personal funds, capability/cost checks, once per session |
| Bag icons | 6 | Small/large, hide/update correctly on swaps, frame reuse and bag open order; default UI first |
| Minimap and merchant buttons | 4 + 6 | Position persistence/reset, click modifiers, tooltip preview, no unsafe action from hover |
| Item tooltips | 3 + 6 | Separate sell/destroy reasons, uncached/locked states, no recursion or mutation |
| Full configuration | 6 | Profile/global options, lists, rules, profiles, keybindings and diagnostics; working legacy navigation |
| Junk items window | 3 + 6 | Counts/value, per-row reasons, sell/destroy/exclude, auto-show only when configured |
| Lootable items window | 6 | One user-triggered open at a time, session ignore, opt-in auto-show, no background item use |
| Commands and bindings | 6 | /dejunk, sell, destroy, junk, loot, profiles, help; list toggles; conflict and combat behavior |
| Public API | 6 | Read-only bag classification plus documented bag/state change events; stable names, no direct write bypass |
| Chat and presentation | 6 | Reduced/verbose output, confirmed versus ambiguous results, counts/stack values, localization fallback |
| Retail-only features | N/A | Artifact relics, warband and addon compartment omitted with explanation |
| Third-party bags | 6 / follow-up | Version-specific Bagnon, ArkInventory and ElvUI compatibility only after actual evidence; otherwise documented unsupported |

## Deliberate differences and unresolved research
Safe Sell defaults on and applies per merchant session. Quest/equipment-set and
refundable protections precede list inclusions. Legendary/heirloom items are
protected in v1. Upstream defaults and precedence remain documented separately.
Legacy tooltip binding certainty, class/subclass localization, refund semantics,
equipment-set identity, original client protected actions, texture availability,
and third-party bag versions remain evidence gates. Until resolved, retain
UNKNOWN/unsupported state instead of guessing or quietly disabling safeguards.
