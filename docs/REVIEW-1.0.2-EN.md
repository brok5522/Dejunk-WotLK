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

**Fixed locally:** the destroy callback tracks the dispatched attempt, checks
the original bag slot every 0.1 seconds, reports `Destroyed:` when that slot is
empty or holds a different item ID while the cursor is empty, reports unlock
failure, and reports `May not have destroyed:` after five seconds. This matches
the pinned reference's `Items:IsItemStillInBags` slot-ID criterion and adds a
cursor-empty guard; it is an observed outcome by those criteria, not a server
receipt. The cache is invalidated after dispatch, duplicate/conflicting actions
stay blocked while pending, and logout cancels the observer. Fake
production-path tests cover disappearance with an empty cursor, a nonempty
cursor, unlock, timeout, and duplicate dispatch. No real item was destroyed.

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
not performed. In-game confirmation of the destroy messages remains outstanding.

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
so this earlier implementation did not assert successful destruction. Fake
production callback tests covered timeout, unlock, duplicate attempts and no
inventory mutation. The later destroy-observer continuation below records the
added source-matching slot-ID check and its fake success fixture.

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

## Continuation: rules, saved options and public API

Compared the complete production evaluator `src/rules/evaluator.lua` with the
pinned upstream `src/junk-filter/junk-filter.lua` and `item-filters.lua`, and
reviewed default/cleaning paths in `src/store/store.lua` against upstream
`src/store/default-states.lua`. Filter order, scopes and strict threshold
comparisons match for the common supported path; this does not establish parity
for unavailable legacy metadata or every malformed stored value.

- **Fixed locally:** absent refund state was treated as non-refundable by the
  canonical evaluator while its bootstrap fallback treated it as unknown. Both
  now return `REFUND_UNKNOWN` for nil; a direct Lua fixture checks both paths.
- **Fixed locally:** old boolean `excludeUnboundEquipment` settings previously
  discarded the default quality map, silently disabling that filter's matching
  after load. The quality map is preserved and verified across a reload.
- **Fixed locally:** quality indexes serialized as strings were converted in
  the legacy quality map but not reflected in the active include-by-quality
  setting. Migration/reload fixtures cover string indexes.
- Compared all of `src/api.lua` with pinned upstream `DejunkApi.lua`. The public
  event values had `Dejunk_` prefixes whereas upstream emits `BagsUpdated` and
  `StateUpdated`. Corrected locally and added literal-value tests, not merely a
  self-referential constant assertion. Consumers hard-coding the previous port's
  non-reference strings must update; consumers using `DejunkApi.Events` follow
  the new values automatically.
- **Known difference:** upstream's public `IsJunk` uses the generic junk filter,
  whereas this port combines action-specific decisions, which can differ for
  currently refundable items. Upstream permits the Heirloom quality in its
  general junkable predicate, while the port explicitly protects it. Review and
  target-client acceptance are still needed; this report does not equate either
  difference with observed item loss.

Reviewed pure `src/services/preview.lua`, `lootable-items.lua`, `junk-items.lua`
and simulation-only `repair.lua`, along with the public API. This is not an
exhaustive comparison of all UI code or all 92 upstream modules. The large
`src/compat/runtime.lua` UI and the remaining upstream components/screens still
need line-level review before claiming completion. These new fixes are local;
1.0.5 remains the most recently published release. No live inventory action was
performed.

## Continuation: UI navigation, settings and action busy state

Compared `src/compat/runtime.lua` common UI helpers, minimap/merchant controls,
keybinding controller, Junk frame and global/profile option setup with the
corresponding pinned upstream files `ui/minimap-icon.lua`,
`ui/screens/merchant-button.lua`, `input/keybindings.lua`,
`ui/screens/junk-frame.lua`, `ui/screens/main-window/main-window.lua`,
`ui/screens/main-window/options/{global-options,profile-options,options-builder}.lua`
and `items/equipment-types.lua`. This is not a line-by-line review of every
screen and generic component: Lists/Profiles/detail rendering and legacy visual
behavior still need inspection and original-client acceptance.

- **Fixed locally:** the Junk gear previously closed Junk and always opened the
  main window. It now toggles Profile Options like the reference without closing
  Junk. UI fixture verifies both toggle directions and Junk visibility.
- **Fixed locally:** global Chat Messages detail and Bag Item Icons size controls
  remained active while the parent option was disabled. They now disable/enable
  with the parent while preserving selected values, with UI fixtures.
- **Fixed locally:** armor/weapon type checkboxes were rendered in auction-menu
  order rather than the reference's curated Wrath display order. The known IDs
  are now sorted in reference order; omitted/unavailable auction labels still
  need an original-client check.
- **Fixed locally:** operation guards prevented conflicting requests but the
  merchant/Junk controls could appear enabled while a sale or destruction result
  was still pending. Busy rendering now covers running and pending actions and
  restores controls when the last pending entry resolves; fake production tests
  check both timeout paths. Successful destruction is still not proven from
  the legacy slot observation, and remains a client-evidence gap.

Tests: actual Lua 5.1 full suite, phase-0 docs/source checks and reproducible ZIP
verification passed. No code here was installed in the game or published.

## Continuation: profiles and reference UI

Compared the profile card/popup paths in `src/compat/runtime.lua`, profile
operations in `src/store/store.lua`, and `Config.ListProfiles` with pinned
upstream `ui/screens/main-window/options/profiles.lua`,
`ui/components/profile-card.lua`, `store/profile-summaries.lua` and profile
reducers. The port uses pooled rows rather than the reference's card-list
component; equality of layout and mouse hit regions still requires client testing.

- **Fixed locally:** when a selected-profile duplication callback failed, the UI
  fell back to duplicating the active profile, potentially producing a copy of
  the wrong source. The fallback now runs only if the selected-profile callback
  is unavailable, not when it reports failure. UI test simulates a stale source.
- **Fixed locally:** assigning a character to its already-active profile no
  longer changes the store revision; upstream's activation handler returns
  early in that case. Store regression verifies the no-op.

These fixes, the earlier comparator, event-name corrections and UI changes are
unpublished. Existing 1.0.5 remains the latest release. Exact copy-failure and
focus behavior need target-client confirmation. Lists, transport, all remaining
shared UI widgets/components and parts of the bootstrap/runtime remain outside
this turn's complete line-by-line review; do not mark the overall comparison
complete based on this report.

## Continuation: lists, item list and transport source comparison

Read pinned upstream `src/lists/lists.lua`, `src/lists/list-item-parser.lua`,
`src/ui/components/item-list.lua`, and `src/ui/screens/transport-frame.lua`
against the port's store list functions, list rendering and transport handlers.
**Correction to earlier wording:** upstream inserts a newly added ID into its
in-memory list and schedules saving immediately, then asynchronously removes it
if parsing or sellability/destroyability checks fail. The 1.0.5 transport path
instead waits and atomically commits a batch only if every requested ID resolves;
that is safer on unresponsive servers but is a documented behavior difference,
not identical upstream semantics. Direct additions still follow the older port
path, and item quality eligibility is not checked by the 1.0.5 import validator.
Existing saved unknown IDs are retained in the port. Further redesign and native
client testing are required before claiming parser parity.

**Fixed locally:** pressing Import now releases the text input focus and clears
the selection, matching the upstream transport handler. The UI fixture checks
focus while keeping the transport window open. Other list/transport behavior was
reviewed at the source level, not fully proven in the native UI. All changes in
this section remain unpublished.

## Continuation: list title hit testing and combat binding flags

Compared `ui/components/list-panel.lua` and `ui/components/item-list.lua` with
`runtime:ShowLists`. The reference attaches Ctrl+Alt+right-click removal to its
clickable titled panel. The port's title was itself mouse-enabled but had no
mouse-up handler, leaving the documented shortcut unreachable when clicking the
title. The title and pane now share the modifier handler. Their mouse-down
handler only accepts left clicks for cursor-item addition; right-click does not
consume a cursor item. A UI fixture invokes the actual title scripts and checks
the other lists remain unchanged. `Store:ClearList` now performs the clear in a
single saved-state notification; fallback installations still have the old
per-item path. Store fixtures cover scope validation, atomic notification and
no-op clearing. No game inventory is modified by a list clear.

Compared `input/keybindings.lua` combat locking with the port's capture and
override paths. Legacy numeric `0` was truthy in Lua and incorrectly blocked key
capture, while an API error was not safely handled. All four keybinding paths now
share a protected check: nil/false/0 mean unlocked, all other values and API
errors mean locked. UI fixtures cover 0, 1 and normal combat events. The actual
client's key input capture remains subject to the owner's acceptance test.

These changes are local and unpublished. `tools/check.py` with actual Lua 5.1,
phase-0 checks and `git diff --check` pass. The overall line-by-line review is
still not complete; this section only reports the specific compared paths above.

## Continuation: list row reuse and scrolling

Compared the port's Lists row creation and scroll handling with pinned upstream
`src/ui/components/card-list.lua` and `item-list.lua`. The port previously
created a frame for every matching ID (up to the saved-list limit), while the
reference uses a fixed pool. The port now reuses a viewport-sized pool of rows,
repositions and rebinds them while scrolling, clamps after shrinking/filtering,
and supports clicking/dragging the list scrollbar track. It allocates at least
12 and at most 256 rows per pane, rather than always exactly the reference's
fixed card count; metadata sorting/lookup still processes the whole list.

A Lua 5.1 UI fixture supplies 300 entries, verifies at most 12 row buttons for
its 196-pixel viewport, scrolls to later entries without adding buttons, seeks
with the scrollbar and checks drag ends. Right-clicking a row while carrying an
item now neither consumes the cursor item nor removes the list entry; only a
left-click/drop adds it, consistent with the reference row handler. The fixture
exercises script calls and does not establish actual mouse routing, clipping or
layout on the original client. Changes are local and unpublished.

## Continuation: per-item import and refundable API classification

Rechecked the pinned upstream parser/list events and the public `DejunkApi`
against the 1.0.5 transport implementation. The prior all-or-nothing import
made one unavailable ID prevent unrelated valid IDs from being imported.
The local queue now validates at most 25 IDs per tick and commits resolved IDs
in bounded batches, reports unresolved and unsupported qualities separately,
and leaves already committed entries intact when another ID times out. It
cancels remaining work if the store revision changes; a fixture switches profile
after one ID resolves and verifies the other cannot leak into the new profile.
A successful item-info response must have the requested ID and a quality allowed
by the pinned source (Poor through Epic, or Heirloom); nil/failed information
is unavailable, not proof the ID does not exist. This is closer to the
reference's per-ID behavior but still differs: it commits after resolution,
while upstream queues/saves first then removes failed IDs, and direct additions
still use the existing synchronous path. Native 3.3.5 item-info behavior needs
owner acceptance. Local Lua 5.1 fake-API tests cover mixed success, unsupported,
timeout, bounded batches and profile-change cancellation.

**Fixed locally:** the generic public `DejunkApi:IsJunk` had reused the
sellability decision, causing a known refundable item selected only for selling
to be reported as not junk. Upstream's generic classification omits the
separate temporary refund block. Generic classification now preserves upstream
semantics when refundability is positively known; the explicit SELL decision and
transaction adapter still reject refundable items. Unknown refund state remains
unknown. A fake-API fixture verifies both outcomes and no mutation.

Equipment-set lookup remains conservative by item ID because the reviewed stock
3.3.5 FrameXML confirms `GetEquipmentSetItemIDs`, but not the reference's modern
per-slot set-location API. Duplicate copies of a set item can therefore be
protected together. This deliberate difference remains in the comparison, not a
claim of exact parity. No live inventory operations were performed.

## Continuation: threshold input and list parser recheck

Compared the upstream `ui/components/number-input.lua` handlers with the
profile threshold edit boxes in `src/compat/runtime.lua`: user input triggers a
0.5-second delayed save; Enter or loss of focus saves; Escape restores the
stored value before clearing focus; and hiding clears focus. The port also
supports multiple fields and Tab for prices. Their exact appearance, focus
routing and timing on the original game client remain unverified. This was a
review of those handlers, not an audit of every options control.

Rechecked upstream `lists/lists.lua` and `lists/list-item-parser.lua`. New IDs
are saved immediately, then parsed in batches of at most 25; successful parsing
removes an ID from the opposite list and a failed or ineligible ID is removed.
Existing saved IDs have a separate longer parsing retry policy. The port's
bounded import resolves before committing, uses a time deadline rather than a
fixed number of attempts, and direct additions still bypass that import queue.
These are outstanding differences; the earlier import section's statement that
this is closer per ID does not mean it is identical. On 3.3.5, missing metadata
is not definitive evidence that an ID is invalid, so existing saved data is not
removed merely because a lookup fails.

This report is chronological: earlier status paragraphs describing changes as
unpublished or findings as open reflect the time at which they were written;
consult subsequent sections for corrections. Full comparison and target-client
acceptance are not complete.

## Continuation: direct list additions and slash commands

Compared list eligibility in upstream `src/items/items.lua` and the parsed-item
handler in `src/lists/lists.lua` with the configuration callback in
`src/core/bootstrap.lua`. A direct addition now rejects an item when legacy
`GetItemInfo` positively identifies a quality outside Poor–Epic or Heirloom;
removal is unaffected. Lua 5.1 regression tests cover supported and unsupported
additions and removal of an already saved unsupported item. Unavailable item
metadata still follows the existing synchronous addition path, so asynchronous
retry/removal of direct additions remains an open difference. This change does
not mutate inventory and has not been published.

Compared upstream `src/input/commands.lua` with `runtime:RegisterCommands` and
the corresponding bootstrap commands: `/dejunk` defaults to the options
toggle, supports options, junk, loot, profiles, sell, destroy and help, and
unrecognized commands show help. The port additionally exposes separate `/djw`
diagnostic commands. UI behavior and transaction effects have not been verified
in the original client in this review.

## Continuation: lootable frame, coin arithmetic and scheduler

Compared upstream `src/ui/screens/lootable-frame.lua` against
`src/services/lootable-items.lua`, the lootable methods in
`src/compat/runtime.lua`, and the update subscriptions in
`src/core/bootstrap.lua`. The upstream filters session-ignored IDs, disables
locked rows, opens only on left click and automatically hides an empty frame
when the automatic option is enabled. The port filters ignored IDs in runtime,
blocks left-click dispatch for locked rows, and has mock UI coverage for busy,
locked, ignore and manually emptied frame behavior. The transaction adapter
performs additional checks immediately before use. The port identifies some
legacy openable items using stock tooltip data and a curated list because 3.3.5
metadata differs. Frame layers, actual legacy item flags, presentation and
runtime interactions still require client evidence. Unlike the upstream fixed
five-card list, the port creates rows for available lootable entries; layout and
allocation are therefore not identical.

Compared upstream `src/utils/coins.lua` against the price field calculations in
`src/compat/runtime.lua`: both combine gold/silver/copper using 10000/100/1
and split using floor and modulo. The existing UI fixture verifies a price
assembled from all three fields. Original-client rendering remains unverified.

Compared upstream `src/utils/ticker-manager.lua` to `src/core/scheduler.lua`.
Both postpone timers created by a callback until a later update. The port uses
one-shot absolute deadlines and explicit rescheduling instead of the upstream
repeating and frame-bound ticker API; it also catches callback errors. These are
different primitives, so equivalence depends on each call site and is not
established by this comparison alone.

No complete per-line coverage ledger exists; this report cannot support a
numerical percentage of the total comparison. The review and client acceptance
remain incomplete. No live inventory operations were performed.

## Continuation: Safe Sell batch selection and confirmer

Compared the full pinned `src/services/seller.lua` run state and
`src/services/confirmer.lua` with production action handlers and observers in
`src/core/bootstrap.lua`. The reference's Safe Sell calls
`GetSellableJunkItems(..., 12)` on an ascending value-sorted list before taking
items from the end of that limited batch. The port had selected from the end of
the entire list first, so on a stable snapshot containing more than 12
sellable items it chose a different set. The port now restricts selection to the
first 12 eligible entries before selecting in reverse order. A Lua 5.1 fixture
checks the actual 12-to-1 selection order from 15 sellable plus 20 destroy-only
items, as well as the existing run cap and cancellation tests. No real inventory
operation was performed.

This does not establish complete seller equivalence: the reference captures a
batch, waits for cache settlement between batches and records attempted slots
only after dispatch; the port rebuilds its projection between attempts, marks a
candidate before dispatch and cancels the run if settings change. Those remain
explicit source differences, along with the previously documented conservative
destroy confirmation. Confirmation and ordering with real game events need the
owner's later client acceptance. Changes are local and unpublished.

## Continuation: destroyer and auditable coverage

Compared all of pinned `src/services/destroyer.lua` with the port's
`src/services/destroyer.lua` and the production destroy action in
`src/core/bootstrap.lua`. The reference selects the next destroyable item,
blocks while busy, checks identity and lock before prompting, and conditionally
shows the Safe Destroy popup. The reference then clears the cursor, picks up and
deletes the item after confirmation. The port's similarly named standalone
service is a simulation only; production uses bootstrap and the compatibility
transaction adapter instead. It deliberately refuses a pre-existing cursor
item and revalidates identity and context after confirmation. The previous
section describes why the resulting deletion cannot be positively confirmed
from slot disappearance alone. These safety and confirmation differences are
not proof of identical behavior; no real item was destroyed.

`python3 tools/review_coverage.py` now inventories English-scope upstream Lua
and the port's own Lua separately. It counts only complete files explicitly
listed in `docs/review-coverage.json` with matching SHA-256 and a review evidence
file. Partial work is counted as pending, so the result is a conservative
minimum, not a reconstruction of all earlier work. Physical-line counts include
comments and blanks and are not a measure of difficulty, parity, test coverage,
third-party library security, or client acceptance. Non-English locales,
vendored libraries, assets and tests are excluded from this specific metric.
The earlier informal 30–50% estimate was not measured and is superseded by these
reproducible counts.

## Continuation: equipment type and set cache; event dispatch

Compared the complete pinned `src/items/equipment-types.lua` and
`src/items/equipment-sets-cache.lua` with `src/compat/legacy.lua`, bag cache
snapshot construction and the original 3.3.5 `EquipmentManager.lua`. The port
maps English item class/subclass names to legacy numeric IDs and reorders them
to the reference's curated order; regression fixtures cover reordered auction
labels and several subclass IDs. The pinned reference enumerates set equipment
by item locations, then marks only player bag slots using
`EquipmentManager_UnpackLocation`. The stock 3.3.5 FrameXML contains that
unpacking helper, but the inspected legacy interface exposes only
`GetEquipmentSetItemIDs(setName)` for membership; it does not provide the
reference's per-slot location list. The port therefore marks IDs and can
conservatively protect duplicate copies. Exact slot parity remains unsupported
by the verified interface evidence and is an explicit gap.

Compared all of pinned `src/events/event-manager.lua` and `src/events/events.lua`
with `src/core/events.lua`, `src/compat/runtime.lua` and the app event routing.
The reference invokes handlers in registration order, supports once/wait-for-
first and game event registration, and lets handler errors propagate. The port
snapshots active listeners so additions wait for the next emission, supports
cancellation, and catches handler failures through its error hook. It does not
implement the same once/wait-for-first abstraction; startup and game events are
routed separately in runtime. This is a deliberate architecture difference;
call-site behavior still requires full cross-reference. The port's public event
names were corrected earlier to the reference values, while its namespaced
internal bus remains separate.

## Batch review: item model, bag cache, filters, parser and English strings

Reviewed the complete pinned files `src/input/keybindings.lua`,
`src/items/bag-items-cache.lua`, `src/items/items.lua`,
`src/junk-filter/item-filters.lua`, `src/junk-filter/junk-filter.lua`,
`src/junk-filter/junk-items-cache.lua`, `src/lists/list-item-parser.lua`,
`src/lists/lists.lua`, and `src/locales/_enUS.lua` against the corresponding port
paths and verified original-client API evidence where available. These files
are whole-file reviewed at the pinned commit; individual findings below remain
open unless explicitly described as fixed.

* **Bindings:** upstream uses the game's converted key chords, temporary
  override bindings, stops capture in combat, and applies each saved binding to
  one of nine commands. The port adapts this through runtime UI and legacy
  globals. Earlier fixes cover the combat return convention; exact modifier
  conversion, ignored-key behavior, duplicate handling, override priority and
  all command paths have not been proven equivalent in client 12340.
* **Bag cache:** upstream batches BAG_UPDATE bursts for up to two seconds,
  refreshes equipment sets, retries only unresolved item data until a five
  second deadline, signals settlement and provides a fresh slot read. The port
  rebuilds slots 0–4 on scheduled scans, invalidates immediately on bag events,
  retries whole snapshots up to five seconds, and uses generation checks. This
  differs in burst handling, retry cost, waiter semantics and public fresh-read
  methods. Stale generations and delayed metadata have mock coverage; equivalent
  event-burst timing and performance need target-client evidence.
* **Item data and filters:** source `Items` delegates sellability, equipment,
  quest class, item level, binding, refund and rarity checks to its Blizzard and
  item APIs. The port uses verified legacy container tuples, item-info metadata
  and tooltip reads, and returns UNKNOWN when required safety facts are missing.
  Its numeric IDs cover the English 3.3.5 classes reviewed, but equipment
  detection is approximated from class/subclass/inventory type rather than the
  source `IsEquippableItem` and cosmetic predicates. The port protects
  legendary/heirloom quality values which the Wrath source excludes from its
  supported junkable quality list; this is a deliberate safety difference.
* **Filter precedence:** confirmed source order: sellability gate, item level
  exclusion, stack-price exclusion, profile/global lists (profile exclusion,
  profile inclusion, global exclusion, global inclusion), equipment set,
  unbound, equipment type, quest, quality, minimum level, minimum price, and
  equipment type inclusion. Port evaluator follows these main stages. Retail
  artifact/warband features are absent from the original target. The port also
  retains a persisted custom-rule model outside upstream's option system; the
  normal UI/decision path's use of it must remain disabled for upstream parity.
* **Reason reporting:** upstream returns localized, composed reason strings per
  filter and distinguishes blocked sell candidates from non-junk. The port uses
  reason codes and English presentation mappings. This is structurally
  different and exact user-facing reason parity is not established.
* **Junk item cache:** source caches by bag/settings version, independently
  orders sell and destroy eligible lists, filters locked/stale rows for those
  operations, and returns bounded list prefixes. Port computes a sorted
  snapshot projection and dispatches through guarded live reads. Safe Sell
  prefix selection was corrected in the preceding section. Refresh frequency,
  list identity, locked item handling in the display, and cache invalidation
  remain different.
* **List parser and lists:** source saves new IDs immediately, processes up to
  25 every 0.1 seconds, distinguishes invalid IDs from unresolved existing
  metadata, retries saved IDs longer than new IDs, sorts resolved names, removes
  non-sellable/non-destroyable entries, maintains sibling/opposite lists and
  reports parse events. The port supports saved ID maps and sorted projections;
  imports use a separate bounded async queue, while direct additions remain
  synchronous. Existing unavailable IDs are retained. Retry-count versus
  deadline behavior, search ordering, progress, messages and opposite-list
  changes have known differences; do not call list parser parity complete.
* **English strings:** the source `_enUS.lua` is the English user-visible
  vocabulary for screens, tooltips and reasons. The port uses hard-coded
  English UI strings in runtime. Only reviewed screens' key labels have been
  compared; full key/value and format-placeholder parity has not been checked.

Coverage manifest now records these nine source files by SHA-256. Localized
strings are included only for `_enUS.lua`; other language files are outside the
owner's scope. This batch review does not assert that listed differences have
been fixed.

## Batch review: state, profiles and shared list UI components

Reviewed pinned upstream files `src/store/action-creators.lua`,
`src/store/action-types.lua`, `src/store/default-states.lua`,
`src/store/middlewares.lua`, `src/store/migrations.lua`,
`src/store/profile-summaries.lua`, `src/store/root-reducer.lua`,
`src/store/state-manager.lua`, `src/store/state-reconciler.lua`, plus
`src/ui/components/card-list.lua`, `item-list.lua`, `list-panel.lua` and
`text-input.lua`. Compared them to the port's `src/store/store.lua`,
`src/ui/config.lua`, list/input construction in `src/compat/runtime.lua`,
SavedVariables declaration, and migration/recovery tests.

* The source has immutable Wux state, reducer/action separation, schema v4
  migrations, reconciliation of defaults while preserving unknown keys,
  profile assignment by character, stable profile summaries and an active
  profile reset event. The port uses a mutable sanitized store, schema v2,
  copies at read boundaries, recovery copies for damaged/future data, and
  direct methods for profile CRUD. These are different persistence designs.
  Port tests cover legacy boolean options, old quality keys, damaged lists,
  future read-only schema, profile changes and reset defaults; they do not prove
  migration parity with source schema v4.
* Profile defaults were compared: poor-quality inclusion is enabled, auto sell
  and auto repair are disabled, safe sell is disabled, safe destroy is enabled,
  and list/profile scopes exist in both. Some source-only options (Warband and
  artifact relic) do not apply to original 3.3.5. The port has compatibility
  fields and aliases retained from earlier iterations; their upgrade behavior
  needs explicit migration fixtures for each released SavedVariables shape.
* Source reducer enforces immutable profile create/copy, rename restrictions,
  reset, deletion fallback and character assignment. Port implements analogous
  operations with mutable state and validation; exact edge semantics differ:
  source assigns a character while creating a profile in one batch, while port
  activates via a store-level assignment. Character key formation is handled
  separately by the port and must be checked against English client realm names.
* Source ProfileSummaries caches character/profile counts by immutable table
  identity; port recalculates summaries from copied state. This is primarily a
  performance/identity difference, not a known functional defect.
* Source card lists allocate a fixed card count, have an empty-state label,
  wheel scrolling and a slider; source ItemList clears cursor after drop and
  lets list-level clicks add cursor items. Port row pooling now bounds rows and
  supports scrollbar dragging, but allocation/empty-state behavior and hit
  routing differ. Source ListPanel exposes Ctrl+Alt+right-click clear on its
  title, import/export control, parse spinner, modifier transfers and opposite
  list semantics. Earlier fixes cover title clear, transport focus, pooling and
  right-click cursor preservation; native mouse routing remains unverified.
* Source TextInput lets clicking the entire field focus it, displays an overlay
  placeholder, reacts to programmatic text changes, and exits on Escape/Enter.
  Port implements these behaviors in runtime controls; exact placeholder,
  focus, and search-update behavior under the original client remains open.

Coverage manifest records all thirteen files above at the pinned SHA-256.
Findings describe source differences; they do not certify each behavior fixed.

## Batch review: reusable options, card and scrolling components

Reviewed the complete pinned source files `src/ui/components/check-chip-group.lua`,
`check-chip.lua`, `component-factory.lua`, `divider.lua`, `icon-button.lua`,
`item-card.lua`, `keybinding-card.lua`, `option-card.lua`, `profile-card.lua`,
`quality-toggles.lua`, `scroll-panel.lua`, `selectable-row.lua` and
`settings-box.lua` against their adaptations and shared builders in
`src/compat/runtime.lua`.

Source components use Waffle sizing, event-state helpers and shared factories;
the port constructs Blizzard frames directly. They share key behavior patterns:
quality chips update selected values, option cards toggle from broad hit regions,
profile cards provide activate/rename/copy/reset/delete, key cards enter capture,
and item cards expose tooltip/action icons with enabled-state dimming. The port
UI interaction fixtures exercise representative option, profile, keybinding,
list and item-card scripts. They cannot establish equivalent Waffle layout,
propagation, clipping, focus, hover or tooltip timing in the 3.3.5 frame system.

Specific parity differences observed: upstream ProfileCard protects the default
profile by disabling rename/delete while leaving duplicate/reset available; the
port renders equivalent icon actions but eligibility depends on runtime checks
and visual disabled state. Upstream ItemCard hides empty cards, preserves full
hyperlinks and quantity formatting, dims disabled item rows and passes mouse
through; port reuses read-only cards and row pools with custom text/actions.
Upstream OptionCard handles left toggles and optional right-click callbacks;
port option cards use larger custom hit frames and some labels/cards redraw the
entire options page after changes. Upstream ScrollPanel changes wheel step with
viewport range, has an intercept hook and a 30Hz layout ticker bound to
visibility; port scroll frames use fixed pixel stepping plus a custom draggable
track. These require exact-client interaction checks and remain unresolved.

The 13 upstream files are now whole-file recorded by SHA-256. The comparison
records behavior and gaps; it does not claim pixel or input parity.

## Batch review: item icons, item tooltips and minimap/transport presentation

Reviewed all of pinned `src/ui/item-icons.lua`, `src/ui/item-tooltip.lua`,
`src/ui/tooltip.lua`, `src/ui/minimap-icon.lua` and
`src/ui/screens/transport-frame.lua` against `RegisterBagIcons`,
`RegisterBagTooltips`, `UpdateMinimapIcon`, list import/export, and the 3.3.5
runtime implementation.

* **Item icons:** reference maintains a pooled icon frame per visible junk slot,
  refreshes on bag/state/lock/search/container events, hides overlays while bag
  search is active, and supports default bags plus ArkInventory, Bagnon and
  ElvUI plugins with precedence. The port refreshes stock container frames and
  adds a pinned-version Bagnon slot hook; it does not implement ArkInventory or
  ElvUI discovery. It skips active bag search only on the stock refresh path as
  currently wired, and has no equivalent plugin interface. Mock Bagnon and
  stock overlay tests pass, but real frame recycling and search state need
  client evidence. Other addons are out of requested scope; stock + Bagnon are
  the relevant requested targets.
* **Item tooltips:** reference hooks `GameTooltip.SetBagItem`, skips disabled
  options/empty slots, looks up the cached item and appends two localized
  heading/reason pairs, then calls Show. The port hooks the same legacy method,
  uses a fresh slot probe and two rule decisions, maps reason codes to English,
  and avoids recursive tooltip probing. It preserves safe uncertainty but
  reason wording and order differ; hook behavior and tooltip line wrapping need
  original-client evidence.
* **Tooltip wrapper:** reference proxies all GameTooltip methods through a
  cached metatable and applies color conventions in SetText/AddLine/AddDoubleLine.
  Port writes directly to GameTooltip and explicit frame code; there is no
  general wrapper. This is an architecture difference and may affect title
  color, wrapping and truncation across UI screens.
* **Minimap:** reference registers a LibDataBroker object through LibDBIcon,
  delegates position database edits, uses Alt-sensitive tooltip/click behavior,
  and refreshes visibility on each state change. Port uses a custom 3.3.5 frame,
  radians/angle positioning and store callbacks, with simulated click/drag tests.
  The port now uses the reference radius and minimap-shape quadrant geometry, guarded when shape lookup is unavailable. Tooltip anchoring, drag feel, scale and border behavior remain client checks.
* **Transport:** reference shows a 325x375 movable window, exports IDs on open,
  selects all text, imports digit runs as silent per-item additions, clears focus
  and selection, and toggles closed when the same list button is pressed. The
  port parses into a bounded preview and asynchronous validation queue, exports
  sorted IDs, and has UI focus/import/export mock tests. This safer but distinct
  timing means partial imports, error messages and duplicate/opposite-list
  handling are not identical. Earlier review sections document that parser gap.

These five reference files are now recorded as whole-file, hash-verified
reviews. No original-client UI evidence was added in this batch.
## Batch review: main configuration screens and shared controls

Compared these complete upstream files at pinned commit `04bafd5e411441ef5b51bb8ed10d208f2d7758f5` against the current 3.3.5 port: `src/addon.lua`, `src/blizzard/blizzard.lua`, `src/ui/blizzard/addon-category.lua`, `src/ui/blizzard/addon-compartment.lua`, `src/ui/components/text.lua`, `src/ui/components/titled-panel.lua`, `src/ui/components/window.lua`, `src/ui/popup.lua`, `src/ui/screens/junk-frame.lua`, `src/ui/screens/main-window/main-window.lua`, all five `src/ui/screens/main-window/options/*.lua` files (global options, keybindings, options builder, profile options, profiles), `src/ui/screens/merchant-button.lua`, the three `src/ui/widgets/composites/{scrollable-title-frame,text-frame,title-frame}.lua` files, `src/ui/widgets/primitives/{button,checkbox,slider}.lua`, the `enabled`, `focused`, and `hovered` frame event modules plus `frame-event-state.lua`, `frame-events.lua`, `frame.lua`, `widgets.lua`, and `src/utils/colors.lua`. The review compares source responsibilities, all declared controls/settings/actions, and the corresponding runtime callbacks and frame construction; it is semantic whole-file review, not a claim that each line has a 3.3.5 counterpart.

**Main window.** Upstream window is a fixed 800x640 Waffle window with five sidebar pages, search-clearing on hide, four list panes, footer links to profile/junk/lootable screens, and Escape close behavior. The port builds this overall shell and the five destinations, carries forward search reset and Escape handling, and wires the footer destinations. It retains a port-only overview/preview panel and repeated standalone fallback pages; those are not part of the upstream main-window flow. The list panels are custom row pools and native scroll frames, not adaptations of upstream ListPanel/ItemList. Exact card sizing, event propagation, drag/drop, clipping, and initial hidden-page construction need original-client evidence.

**Global and profile options.** The upstream global page groups Safe Destroy/Safe Sell, merchant button with right-click position reset, minimap, auto Junk/Lootable windows, chat message detail, and bag tooltips/icons with dependent size choice. The port provides the matching global controls and callbacks, including merchant reset and option disabling when a parent toggle is off. The upstream profile page includes Auto Repair/Sell; quality, item-level, price, and equipment-type filters; equipment-set, quest-item, unbound, and above-price exclusions, with apply scopes and quality selections. The port builds corresponding fields in its manually positioned scroll content and legacy equipment-ID map. Its layout is bespoke and some controls redraw the whole page after a selection; the source uses reusable cards/chips and Waffle scrolling. The checkbox/control meanings broadly correspond, but lower-page clipping/scrolling and exact live saved-value refresh remain client checks.

**Keybindings.** Upstream card clicks start/stop capture, right-click clears a binding, other mouse inputs and wheel notches can be bound, Escape cancels, and capture is disabled during combat; a footer reports key conflicts and game bindings. The port has a capture page, wheel and mouse capture, Escape handling and combat stop, conflict refresh, and persisted overrides. Runtime rendering/refresh after `/reload` has had owner-reported fixes and tests, but original-client focus/priority and every modifier combination are not evidenced by this comparison.

**Profiles and popup flows.** Upstream profiles are ordered by name (default first), show counts and character usage, activate on click, and expose duplicate/reset plus guarded rename/delete; prompts use Blizzard StaticPopup validation and Yes/No alert confirmation. Port profile rows have corresponding actions and a protected default, sort default first then case-insensitive name, report results, and create a fullscreen modal blocker with Escape/cancel. This follows the visible action set but differs in popup size/stacking and error wording; long profile lists and modal stacking need client checks. `Config.ListProfiles` sorts by ID before runtime sorts the returned copy for display; no user-visible order defect remains in the Profiles page.

**Junk frame and merchant controls.** The upstream Junk frame is 350x400, seven visible item cards, gear to Profile Options, total-value title, sell/exclude/destroy row actions, item tooltip, and start/destroy buttons whose enablement follows merchant, cursor, locks and busy state. Port uses the same size and action set with pooled custom rows, gear navigation, tooltip reasons and read-only callback dispatch; item ordering/card hit geometry and source's item-list cursor behavior differ. Upstream merchant button is parented to MerchantFrame, grows its icon with count text, uses High strata, left sell/right junk/Alt-right destroy/Shift-right reset and hides outside the merchant. Port uses the same 108-pixel width and High strata, persists drag position, ignores unsupported modifier combinations and defaults to TOPLEFT (210,-44) to avoid the portrait/name area. The owner's screenshot history prompted that placement; target-client acceptance of the current position is not recorded in this audit.

**Shared primitives and Blizzard integrations.** Upstream Waffle text handles measured wrapping/truncation tooltips; titled panels share title-bar hit/tooltip behavior; generic windows implement drag/reset/ESC; TextFrame supplies multiline scroll/edit selection and clear. Primitive frame events track effective enabled state through ancestors, bubble focus, and watch hover; the port translates these behaviors into direct 3.3.5 frames and local scripts rather than this event-state machinery. Its list transport text edit supports select/export/import and Escape close. Such architecture is valid for the legacy API, but does not prove identical mouse propagation or focus callbacks. Upstream AddOn category and compartment integrations use post-Retail Settings/AddOnCompartment APIs; they are absent by design on 3.3.5a and are not counted as missing functionality. Blizzard wrapper source directly binds modern container/item APIs; the port substitutes the legacy API layer and should be judged against its separate compatibility evidence, not copied literally.

**Specific source/port differences still open:** the main page contains an overview absent upstream; Waffle card and event propagation are represented by custom frames; keybinding conflict/capture behavior is only mock-tested; profile popups and long-list layout differ; Junk row ordering and cursor/list hit routing differ. Native game UI remains necessary to accept these differences. This batch makes no claims of pixel parity or live transaction validation and makes no inventory changes.

## Remediation checklist — batch 1

This 20-item queue captures the still-actionable port differences called out in
this review; it does not include Retail-only integrations or original-client
acceptance. A checked item means the code change and its offline regression test
are present. Client-only acceptance remains separate.

1. [x] Match the reference merchant button's High frame strata.
2. [x] Ignore unsupported merchant click modifier combinations; allow only the
   configured unmodified, Shift-right and Alt-right actions.
3. [x] Place the minimap button using the reference's radius and minimap-shape
   quadrant rules, with guarded shape lookup for legacy clients.
4. [x] Clear prior merchant tooltip lines before drawing its count and controls.
5. [x] Clear prior minimap tooltip lines before drawing its controls.
6. [x] Remove the port-only overview from the user-facing main-window flow.
7. [x] Match the main-window shell dimensions and page order, and remove the
   non-reference overview fallback presentation.
8. [x] Compare every key capture input and game-binding conflict path against
   the source and add production callback fixtures for uncovered cases.
9. [x] Compare keybinding cancellation, combat locking and override refresh
   lifecycle against the source in the supported legacy runtime.
10. [x] Match profile prompt validation, alert confirmations and close behavior
    while retaining original-client-compatible frames.
11. [x] Verify profile row count, scrolling and action hit areas for long lists.
12. [x] Match Junk item ordering, row sizing, enabled state and cursor/list hit
    routing to the upstream ItemList behavior.
13. [x] Match pooled list behavior with bounded custom 3.3.5 rows, scroll
    recycling and actions that follow the currently displayed item.
14. [x] Match scroll wheel step and slider behavior across Lists, Profiles,
    Options and item windows.
15. [x] Finish TextInput parity for focus, placeholder, programmatic changes,
    Enter and Escape in all edited fields.
16. [x] Align item reason headings, wording and line ordering with the English
    reference vocabulary, including threshold values and equipment subtypes.
17. [x] Verify bag search suppression and visible-frame refresh for stock bags
    and the requested Bagnon version.
18. [x] Match parser lifecycle where original 3.3.5 item metadata allows it;
    retain unknown IDs when this API cannot prove invalidity.
19. [x] Compare the 3.3.5 store migrations and saved option aliases against all
    supported release shapes, with explicit fixtures for each.
20. [x] Reduce whole-bag retry work and compare bag-cache invalidation timing
    with the reference without weakening stale-snapshot rejection.

Batch 1 completed 5 of 20 queued remediations (25%). Batch 2 compared key
capture inputs, game-binding conflict reporting, cancellation, combat locking
and override refresh with upstream `src/input/keybindings.lua` and its legacy
binding adapter. A regression now verifies the initiating click is not captured.
The main window now opens on Lists without exposing the port-only Overview and
preview controls; an option-page construction failure returns to Lists instead
of a blank Overview. Profile name prompts now trim whitespace and remove the
same control/pipe characters as store validation, retain focus and remain open
when the name is empty or too long. Profile rows refresh the scroll range after
list changes; a 13-profile fixture verifies expanded content and offset clamp
when it shrinks. Scroll wheel steps now follow the reference: adaptive 16–48 px
for ScrollPanel views, one profile card per notch, and 75% of the viewport for
Junk/Lootable windows; custom list rows continue to advance one row per notch.
Fixtures verify adaptive options scrolling and profile-card increments. These
items cover checklist entries 6, 8–11 and 14 (11 of 20, 55%).

Validation passed with `python3 tools/check_phase0.py`, actual Lua 5.1 via
`tools/check.py`, and `git diff --check`. The original WoW client was
unavailable, so no visual or live inventory operation acceptance is claimed.

## Continuation: cursor-aware Junk rows and text input behavior

Removed the now-empty Overview component as dead layout state. The main
configuration opens directly on Lists; failed option-page construction also
returns there. In the Junk window, a new legacy `CURSOR_UPDATE` listener
refreshes the currently visible rows. The row follows upstream enabled state:
it dims while an item is on the cursor, an item action is busy, or the source
item is locked; its Exclusions action disables in those states and rechecks the
cursor at click time. UI fixtures cover cursor pickup/clear refresh, the busy
state, and item-to-list routing. This closes the cursor/hit and enabled-state
part of checklist item 12; row virtualization/sizing comparison remains open.

Lists search now highlights its border while focused or hovered and restores it
on Enter/Escape. The custom rule ID/number inputs now release focus on Enter and
Escape; interaction tests verify those paths. Complete TextInput parity across
every legacy edit field remains open under item 15. These changes do not increase
the number of fully closed checklist items; progress remains 11 of 20 (55%).
All tests passed after this batch: `python3 tools/check_phase0.py`, full
`tools/check.py` on the actual Lua 5.1 interpreter (including UI interaction,
bag/Bagnon mocks and reproducible ZIP checks), and `git diff --check`. No WoW
client run or real inventory operation was performed.

## Continuation: stock bag refresh and Bagnon item search

Compared `src/compat/runtime.lua` with the pinned Bagnon `components/item.lua`:
`ItemSlot:UpdateSearch()` dims nonmatches to alpha 0.4 and matches back to 1.
The Bagnon integration now post-hooks `UpdateSearch` when present, suppresses
the addon icon on dimmed/nonmatching slots, and restores it on a match. It uses
`Update` as a compatibility fallback when that method is unavailable; the
existing `Free` post-hook still clears pooled textures without replacing
Bagnon's scripts. Added regressions for search mismatch/match and verified the
stock `ContainerFrame_Update` hook refreshes visible frames, removes stale icons
while hidden and restores them when shown. The fake hook fixture was corrected
to model WoW's two-argument global `hooksecurefunc` overload.

Checklist item 17 is now closed offline; progress is 12 of 20 (60%). Target
client acceptance remains separate. Validation passed with `python3
tools/check_phase0.py`, full `tools/check.py` on Lua 5.1, and `git diff
--check`. Reproducible ZIP checks passed; the addon was not installed or
published, and no game client was available.

## Continuation: pooled list row parity

Rechecked the list pane against upstream `CardList`/`ItemList`: the port keeps a
viewport-sized row pool, repositions rows from the scroll offset, and routes
actions through each row's current item ID after recycling. Existing Lua UI
fixtures exercise a 300-item list, bounded frame count, scrolling/reuse, track
drag and mutation of the displayed item. Checklist item 13 is now closed for
these supported behaviors; legacy 3.3.5 uses local row frames instead of the
upstream Waffle `ItemCard` component. Progress is 13 of 20 (65%).

## Continuation: English tooltip reason vocabulary

Compared the port's reason-code labels with upstream `ui/item-tooltip.lua`,
`junk-filter/item-filters.lua` and the English list names. List decisions now
use the upstream `Lists > Inclusions/Exclusions (Profile/Global)` wording;
quality, refund, quest, equipment-set, unbound-equipment and threshold reasons
use the upstream option labels. Decisions now retain configured item-level or
whole-stack copper thresholds and the equipment subtype. Tooltips render those
values in the reference's parenthesized format, using the 3.3.5 coin formatter
for copper. The bootstrap fallback carries the same metadata. Fixtures cover
all six dynamic reason forms and compare canonical/fallback metadata. Item 16
is closed; checklist progress is 14 of 20 (70%). Validation passed with
`python3 tools/check_phase0.py`, full `tools/check.py` on Lua 5.1 (72 core,
26 store, 8 service, 11 destroyer, 62 UI model tests, UI interactions, Bagnon
and reproducible package checks), and `git diff --check`. No original WoW
client run was performed.

## Continuation: edit-field lifecycle coverage

Completed field-by-field checks for Lists search, the profile name modal,
multiline import/export, custom rule inputs, option thresholds and the report
panel. Added coverage that Enter submits a valid profile name, Escape cancels a
profile name without mutation, and Escape from the report editor returns to
the caller. Existing UI fixtures cover the other fields' focus, placeholder,
commit, delayed save, cancel/restore and export-selection behavior. Checklist
item 15 is closed; progress is 15 of 20 (75%). Lua 5.1 UI interaction tests
passed after the added cases.

## Continuation: legacy parser and saved-state compatibility

Compared the UI's metadata queue with upstream `list-item-parser.lua`. The
legacy path requests at most 25 list IDs per 0.1-second update, stops polling
after 30 seconds, and keeps unresolved IDs visible by their numeric ID. It
does not treat a missing `GetItemInfo` result as proof of a nonexistent item;
the original 3.3.5 client lacks the reference parser's `GetItemInfoInstant`
probe. Existing checks cover positive unsupported-quality rejection on direct
addition, removal of previously saved unsupported IDs, independent async
import resolution and the metadata timeout. Thus parser item 18 is closed for
the evidence available to this client; progress is 16 of 20 (80%).

Compared the store's supported schema 1 and 2 input shapes, legacy scalar
threshold aliases, boolean equipment filters, numeric-string quality keys,
old minimap naming, keybindings, profile assignment and profile ID allocation.
Added a migration round-trip fixture proving structured options win over old
aliases and profile IDs do not collide. Existing recovery tests cover malformed
lists, wrong schema types and future read-only data. This closes checklist item
19 for the port's released formats; upstream's Retail schema v4 is a different
saved-state model and is not directly loadable by the 3.3.5 addon. The expanded
store suite passes (27 cases).

## Continuation: Junk card pool and targeted cache retries

Compared the Junk window with upstream `junk-frame.lua` and `item-list.lua`.
The port now keeps seven 36-pixel cards, advances them in 38-pixel rows, and
rebinds their item and actions while scrolling. A 300-item fixture verifies the
seven-card bound, current-item action routing, and scroll reset after a shrink.
This closes item 12 for the supported presentation and interactions.

Compared cache invalidation and pending retries with upstream
`bag-items-cache.lua`. Bag events still invalidate the generation immediately
and replace delayed retries with a prompt full scan. Metadata retries now
re-read only unresolved slots (and rescan a bag if its size or equipment-set
membership changed); resolved observations are reused privately while public
snapshots remain deep copies. A regression confirms a known neighbor is not
re-read during an unresolved item's retry. Existing tests cover event-burst
coalescing, stale-generation rejection, retry deadlines and event preemption.
This closes item 20. Together with the Junk row pool and the legacy parser/store
fixtures, 19 of the 20 queued items are now closed (95%).

## Continuation: main-window shell parity

Compared the live main shell with upstream `main-window.lua`: both use an
800×640 root, a 25% navigation column, the same five page destinations in the
same order, and the same Lists-first initial page. Removed the 500×300 fallback
overview with its preview controls. When Waffle construction fails or its
components are absent, the addon now reports that UI construction failed and
does not substitute a differently sized partial main window. `ToggleConfig`
also reports failure instead of claiming success. Fixtures assert the exact
root dimensions, navigation order and failure behavior. Checklist item 7 is
closed for the legacy shell; page internals still use 3.3.5 native frames and
live client geometry remains for the owner's acceptance. The remediation queue
is 20 of 20 (100%) complete offline; this does not mean the entire addon has
pixel parity or has passed in-game client acceptance.

## Continuation: destroy outcome observer parity

Rechecked upstream `confirmer.lua` and `items.lua`: the reference reports
success when the attempted item ID no longer occupies its original bag slot,
reports unlock as failure, and reports a possible failure after five seconds.
The port now follows that lifecycle, polls the original slot every 0.1 seconds,
requires the cursor to be empty before reporting success, refreshes the cache
after dispatch, and cancels pending timers on logout. A fake production-path
regression verifies a missing slot with a retained cursor item is not reported
as deletion. The report uses the same slot-ID inference as upstream and is not
a server receipt; original-client acceptance remains necessary. Lua 5.1
transaction tests pass.
