# Phase 1 original-client acceptance: PENDING

No actual WoW client is available in this environment. Do not mark these checks
passed based on the Lua fixtures or a Wrath Classic client. The owner can follow
[the Persian guide](PHASE1.fa.md); no executable `/run` macros are required.

Record client version/build/interface, locale, addon commit and whether the
client is modified. Do not include character/account/server names. Commands are
`/djw status`, `/djw slot <bag> <slot>`, `/djw report` and `/djw probe`.

| Evidence | Expected result | Actual |
| --- | --- | --- |
| Original 12340 startup and reload | READY after own ADDON_LOADED + login; no Lua errors | PENDING |
| Wrong client (if separately available) | DISABLED and no bag scans | PENDING; offline fixtures passed |
| Known occupied and empty slot | Correct ID/count/lock/quality or EMPTY; no mutation | PENDING |
| Container and GetItemInfo signatures | Tuple arity/types match legacy layout; localized class labels and base level | PENDING |
| Uncached/unavailable metadata | UNKNOWN retained; at most two timed retries | PENDING; offline fixtures passed |
| Refund purchase tuple | Fifth return semantics; nil remains unknown until evidence justifies interpretation | PENDING |
| Quest flag and binding strings | Explicit booleans or observed legacy 0/1; opt-in hidden tooltip probe; unknown text stays unknown | PENDING |
| Equipment sets, if configured | Correct count; all matching bag item IDs protected conservatively | PENDING |
| Legacy UI_ERROR_MESSAGE, merchant and bag events | Report types/arity, e.g. first error argument string; no action on events | PENDING |
| Diagnostic report UI | Text selectable/copyable, scrolls, Escape/close work; chat fallback available | PENDING |
| Logout/reload behavior | No error; fresh startup, no persistent data | PENDING |

Use already-present items and equipment sets; do not move, split, equip, sell,
delete, open or otherwise consume items to generate evidence. A naturally
occurring lock/refund/uncached state may be unavailable; report NOT OBSERVED
rather than forcing inventory operations. Optional missing events must remain
visible in the report; registration is not proof of delivery. Obtain explicit
approval before expanding test scope beyond read-only observation.

A copied report is not stored by the addon. Inspect it before sharing: it includes
the selected item's ID/count/vendor value and localized category labels, but no
character/account identifiers, item links, raw tooltip lines or raw event values.
Resolve failures here before Phase 2 acceptance or any inventory-action work.
