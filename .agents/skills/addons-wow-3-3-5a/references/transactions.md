# Inventory actions and delayed-work safety

These principles apply when an addon mutates inventory. They are not permission
to run live transactions. Use fake APIs for development. Never test real deletion;
respect separately authorized, bounded sale/repair/loot acceptance tests.

## Separate intent, classification and dispatch

A UI card renders a snapshot. Clicking it issues an intent, not proof that the
same item remains in the slot. Before execution re-read bag/slot, item ID, full
link, stack count, lock, relevant flags, settings revision and context. Stop if
identity or relevant state changed. Copy intent data rather than closing over a
mutable row that a renderer will reuse.

Check merchant state for sales and repair, cursor emptiness, combat/death and
conflicting trade/mail/auction states as required by the product. Missing data
needed for an enabled protection is UNKNOWN, not permission to act. Do not replace
the reference's list/filter precedence with a new unrequested policy.

The cursor is shared state. Never clear an unrelated cursor to make room. A failed
pickup or mismatching cursor after pickup must not trigger recovery deletion.
Original APIs may expose only cursor type/ID, not enough link/count evidence;
state that limitation explicitly.

## Sale runs

- Use action-specific sell candidates, not the combined sell/destroy display list.
- Preserve reference ordering. Dejunk sorts price/quality/name and sells eligible
  rows from the high-price end; skipping destroy-only rows matters to Safe Sell.
- Keep one active run. A second Start must not silently restart or create another
  queue. Expose busy state to the UI and block conflicting manual actions.
- Distinguish **examined candidates**, **dispatched API calls**, **successful API
  return**, and **observed sale**. A failed API dispatch can still count against
  a call cap. In this port AttemptSale returns an extra dispatched flag.
- Safe Sell caps dispatched calls per run, not display rows and not just successes.
- A dirty cache should settle before the next selection, but waits must be bounded
  (0.4 seconds in pinned Dejunk). Track attempts by slot/ID to avoid retry loops.
- Capture merchant session and settings revision. Cancel on closing/refusal,
  settings changes or unsafe context. Release timers and UI busy state on every
  finish/cancel path. Test errors as well as success.
- Slot disappearance or money delta alone does not establish a sale: moves,
  unrelated income and stack changes can explain them. If outcomes are not
  correlated, report attempts rather than claiming exact sales/profit.

## Delayed auto repair

Capture the merchant session and relevant settings when scheduling. On execution,
verify that the merchant is still open, the session still matches, Auto Repair is
still enabled, the cost is current and funds suffice. Closing/reopening quickly
must not turn an old timer into a repair in a new session. Do not assume guild
funds or silently add an unsupported funding option.

## Confirmation and destruction

One deliberate action requests one stack. Safe Destroy defaults on in Dejunk.
A confirmation should show the intended link/name/count/value and reason.

A copied intent must be single-use. Consume it on accept and invalidate it on
cancel, relevant settings changes and expiration rules. Re-read identity and
context on accept. Do not reuse an old callback for a newly populated slot.
Do not auto-delete on bag updates or merchant opening. If a user explicitly turns
off confirmation, that does not waive identity, cursor or context checks.

Fake tests can safely assert cancel, revision expiry, repeated acceptance,
slot/link/count changes and unexpected cursor behavior. Verify that real mutation
sentinels remain untouched; use a deliberately injected fake transaction adapter
for tests that need an attempted call.

## Lootable items

Only positively identified lootable stacks belong in that list. Revalidate the
original item and deliberately use it; never call UseContainerItem on an unknown
item merely because the UI is labelled Lootable. Ignore should affect all rows
with that ID for the session and refresh both window and footer count. Auto-show
preferences control visibility; they are not authorization to open items.
