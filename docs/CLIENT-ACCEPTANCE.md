# Phase 1 original-client acceptance: PARTIAL — user evidence received

The owner supplied a build-12340 report and chat screenshots; see the sanitized
[occupied-slot record](research/CLIENT-12340-01.md) and
[empty-slot/event/reload follow-up](research/CLIENT-12340-02.md), and
[merchant event record](research/CLIENT-12340-03.md). The basic read-only smoke
sequence has user evidence and succeeded; broader acceptance remains partial.
No actual WoW client is available
in this development environment. Do not mark the remaining checks
passed based on the Lua fixtures or a Wrath Classic client. The owner can follow
[the Persian guide](PHASE1.fa.md); no executable `/run` macros are required.

Record client version/build/interface, locale, addon commit and whether the
client is modified. Do not include character/account/server names. Commands are
`/djw status`, `/djw slot <bag> <slot>`, `/djw report` and `/djw probe`.

| Evidence | Expected result | Actual |
| --- | --- | --- |
| Original 12340 startup and reload | READY after own ADDON_LOADED + login; no Lua errors | OBSERVED: startup report READY/zero callback errors; owner reload/status follow-up screenshot READY (command sequence not captured) |
| Wrong client (if separately available) | DISABLED and no bag scans | PENDING; offline fixtures passed |
| Known occupied and empty slot | Correct ID/count/lock/quality or EMPTY; no mutation | PARTIAL: occupied Hearthstone and EMPTY slot 16 observed; positive lock flag pending |
| Container and GetItemInfo signatures | Tuple arity/types match legacy layout; localized class labels and base level | OBSERVED for one enUS item: 7 container / 11 item-info returns |
| Uncached/unavailable metadata | UNKNOWN retained; at most two timed retries | PENDING; offline fixtures passed |
| Refund purchase tuple | Fifth return semantics; nil remains unknown until evidence justifies interpretation | PARTIAL: zero returns on Hearthstone; refundable-item semantics pending |
| Quest flag and binding strings | Explicit booleans or observed legacy 0/1; opt-in hidden tooltip probe; unknown text stays unknown | PARTIAL: three nil quest returns; bound=true on Hearthstone; positive quest/unbound cases pending |
| Equipment sets, if configured | Correct count; all matching bag item IDs protected conservatively | PARTIAL: count=0; configured-set membership not observed |
| Legacy UI_ERROR_MESSAGE, merchant and bag events | Report types/arity, e.g. first error argument string; no action on events | PARTIAL: bag/lock events and cache observed; MERCHANT_SHOW/CLOSED have zero args, repeated close harmless in sample; UI_ERROR_MESSAGE pending |
| Diagnostic report UI | Text selectable/copyable, scrolls, Escape/close work; chat fallback available | PARTIAL: text supplied and chat screenshots; native scroll/close not explicitly confirmed |
| Logout/reload behavior | No error; fresh startup, no persistent data | PARTIAL: READY screenshot supplied after reload/status request; full logout and post-reload diagnostics not captured |

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

## Handoff after the basic smoke checks
The requested owner checks are recorded without requiring inventory operations.
No runtime change or new addon download is needed. Keep the unobserved cases
above as explicit evidence gaps; do not infer safety booleans from absent data.
Phase 2 still requires separate owner authorization and review of this partial
acceptance. Inventory services remain out of scope.

## Phase 2 owner check
Owner reports backup, install, profile creation, global inclusion edit, and both
values persisting after `/reload` on the target client. Details are in
[Phase 2 client evidence 04](research/CLIENT-12340-04.md).
