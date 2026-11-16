# Fresh source review — 1.0.2, English client

Scope: original 3.3.5a English client; upstream Dejunk revision
`04bafd5e411441ef5b51bb8ed10d208f2d7758f5`; Bagnon revision
`27a08f89819311d772e7ec7a71a41eafb813f122`. Other game languages and
other bag addons are outside the owner's requested scope. This is an
incremental record, not a claim that every line has been reviewed.

## Transaction dispatch and confirmation

Reviewed `src/compat/runtime.lua` lines 1–185 and `src/core/bootstrap.lua`
lines 675–825 against upstream `src/services/confirmer.lua`, including guarded
sale/repair/loot/destruction, pending-sale tracking and sequential dispatch.
The prior fixes recheck slot identity and settings, keep the cursor untouched on
mismatch, and distinguish sale dispatch from observed outcome. Tests use fake APIs.

**Open parity finding:** upstream tracks attempted destruction, reports unlock
failure or five-second uncertainty, and reports confirmation when the item
leaves the bag. The production destroy callback currently prints only
`Destroy attempted.` after dispatch and has no equivalent pending-destroy
observer. Thus a successful API call is not confirmation of destruction, and
failure or uncertainty is not subsequently reported. This is source-observed;
no real item was destroyed to reproduce it. A fix needs fake-API production-path
tests for success, unlock, timeout, and cancellation, and must not treat an
unrelated cursor/slot change as proof without documenting the inference.

**Review boundary:** the remainder of runtime, store, rules, services, UI and the
reference code still require systematic line-by-line comparison. Vendored Waffle
has checksum/integration coverage, not an independent exhaustive security audit.
Actual 1.0.2 client acceptance, including Bagnon, remains outstanding.

**Fixed during review:** sale and destroy decisions were evaluated before the
adapter's final read, but that read compared identity without comparing all
rule inputs. A changed price, quality, level, binding or protection state could
therefore invalidate the earlier decision without preventing dispatch. The
adapter now rejects changed rule inputs before sale or pickup. Lua 5.1 fake-API
regressions verify changed metadata does not dispatch either action. This fix is
local and not yet published.

## Continuation: event bus, scheduler, bag cache and live binding probe

Reviewed all lines of `src/core/events.lua`, `src/core/scheduler.lua` and
`src/core/bag-cache.lua`, plus the live transaction adapter's binding read
(`src/compat/runtime.lua:ReadItem`) and upstream `src/items/bag-items-cache.lua`
at the pinned revision. The event bus snapshots listeners for dispatch; the
scheduler defers newly scheduled callbacks to the next advance and cancels jobs
by token. The bag cache invalidates by generation and rejects snapshots that
change while scanning. Its two 0.5-second retries are shorter than the upstream
five-second pending-data deadline: this remains a behavioral difference and
needs a realistic delayed-metadata fixture before any policy change.

**Fixed locally:** unlike the cache's binding probe, the live transaction
adapter previously did not reread the slot after the tooltip binding probe. If
that slot changed during the probe, the resulting identity and binding could
refer to different observations. It now reads the slot again and rejects any
identity, lock or rule-input change before returning an item. Fake-API tests
change the source item during the binding read and assert both sale and destroy
pickup are blocked. No live inventory action was performed. This fix has not
been released. The earlier rule-input revalidation fix is included in 1.0.3;
the previous paragraph calling it unpublished describes the older review state.

Validation: `python3 tools/check_phase0.py`, `python3 tools/check.py --lua
/workspace/work/lua51/usr/bin/lua5.1 --luac /workspace/work/lua51/usr/bin/luac5.1`
and `git diff --check` passed on this working tree. Original-client testing was
not performed. Pending-destroy outcome observation remains open.

## Continuation: delayed metadata and destroy outcome

The bag cache now retries incomplete reads for five seconds from its first
incomplete scan, with 0.5-second intervals and cancellation on logout. This
replaces the previous two retries. A fake item whose metadata becomes available
after 2.5 seconds resolves without a bag event; a permanently unavailable item
remains unknown and polling ends at the deadline. This is closer to upstream's
five-second pending deadline, but the port rescans all carried slots rather than
upstream's pending slots. Runtime performance and actual client timing remain
unverified.

For destruction, a production observer now tracks the dispatched attempt for five
seconds, prevents a second attempt during that window and reports a matching
`ITEM_UNLOCKED` as failure. On timeout it explicitly reports that the outcome
could not be confirmed. The original slot is emptied by pickup before deletion,
so slot disappearance alone is insufficient evidence to claim success; unlike
upstream, no successful-destruction confirmation is asserted. Fake production
callback tests cover timeout, unlock, duplicate attempts and no inventory
mutation. Full successful-outcome parity remains open pending reliable 3.3.5
client evidence. These changes are local and unpublished.

Validation after changes: actual Lua 5.1 full suite and deterministic ZIP
checks passed. No real-client item was destroyed.

## Continuation: seller busy state and item ordering

Compared the production `startSelling`, manual sell and destroy callbacks in
`src/core/bootstrap.lua` with the pinned `src/services/seller.lua` and
`src/services/destroyer.lua`. The reference uses `Addon:IsBusy()` to prevent
manual item actions during a seller run or an unconfirmed action. Previously,
the port prevented duplicate runs and duplicate same-slot sales but still let a
manual sale or destruction start while another run/confirmation was active.
The port now blocks conflicting manual actions and new sale runs while sales or
an attempted destruction await their outcome; a run's own sales remain allowed.
Production-path fake-API tests cover a running seller, a pending sale and pending
destruction. This change is local and has not been released.

Reviewed `src/services/junk-items.lua` against the pinned reference's
`src/junk-filter/junk-items-cache.lua` sort comparator. Both order by stack price,
quality, name and count; the port adds bag/slot tie-breakers for stable ordering.
The port's unknown-item and stale-snapshot exclusions are deliberate safety
behavior, rather than exact reference cache internals. A full in-client check is
still necessary. The seller's existing 0.4-second cache-settle timeout matches
`Seller.MAX_SETTLE_SECONDS` in the pinned reference; it is separate from the
five-second item metadata retry window.

Full Lua 5.1 checks, phase-0 checks and `git diff --check` passed; no live
inventory was mutated. Successful destruction still cannot be established from
slot disappearance alone, so its positive outcome remains an explicit parity
and client-evidence gap.

## Continuation: list transport, lootable frame and observation consistency

Compared the pinned reference's list parser and lootable-frame source with
`src/store/store.lua` import, `src/ui/config.lua` list filtering, and
`src/compat/runtime.lua` lootable presentation. Existing imported IDs are kept
when item metadata is unavailable, and digit-run parsing remains data-only.
The upstream parser validates new IDs asynchronously whereas this port stores
syntactically valid IDs immediately; invalid/unavailable IDs can remain in the
list. This remains an explicit parity gap, not a claim that the import is fully
validated against the server. The ignored-lootable session filter and automatic
show/hide path were reviewed; native behavior needs client acceptance.

**Fixed locally:** the live transaction probe had been strengthened earlier,
but bag-cache and public-slot probes only compared link/count/lock after reading
binding. Metadata, such as price or quality, could change while these values
remained the same. A shared pure observation comparator now checks identity,
metadata, price, quality, quest/refund/set state and lootable flag on both sides
of the binding read. Changed observations become `UNKNOWN`, allowing a retry
instead of exposing a mixed snapshot. Fake Lua 5.1 tests mutate the price during
the read and exercise both the direct probe and bag cache. No game inventory was
modified. This fix and the preceding audit changes are not published.

Validation: `tools/check.py` with actual Lua 5.1 passed all suites and the
reproducible ZIP check; phase-0 and whitespace checks passed. Native game
acceptance and the new-item asynchronous validation difference remain open.

## Continuation: bag changes during metadata retries

A BAG_UPDATE previously left a queued 0.5-second metadata retry in place, so a
newly changed bag could remain stale until that old retry was due. Invalidation
now cancels the old timer and queues the normal 0.1-second refresh. A Lua 5.1
fixture starts an unresolved metadata retry, changes the slot, fires BAG_UPDATE,
and verifies a fresh known snapshot after 0.1 seconds. The cached metadata and
original-client behavior remain separate from validation of newly imported IDs.

## Continuation: asynchronous transport import (unreleased)

The UI transport and `/djw lists import` paths now queue new item IDs and
request legacy `GetItemInfo` in batches of at most 25 per tick. A positive result
requires an item hyperlink carrying the expected ID. Each ID has five seconds
from its first request; if any remains unavailable, the whole new-ID import is
left uncommitted and the user may retry. Existing saved IDs are untouched. This
is deliberately not labeled “invalid”: the original 3.3.5 API cannot distinguish
an uncached or unreachable item from a nonexistent ID using this response alone.
The captured store revision cancels the import if the lists/settings/profile
change during validation; there is no partial commit. One import can run at a
time. A background completion refreshes only an already-visible Lists page and
does not reopen a closed window. Direct item-drop/list commands are separate and
still use the existing synchronous path; this is not complete parser parity.

Production callback tests exercise delayed availability, atomic commit, timeout,
stale changes, duplicate requests and a 25-ID batch. UI checks cover a closed
window. No WoW client was available for this validation. Reference behavior is
`src/lists/list-item-parser.lua` at pinned upstream revision, which additionally
uses the modern `GetItemInfoInstant` unavailable in the original target API.
