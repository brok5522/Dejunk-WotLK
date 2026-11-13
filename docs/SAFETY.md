# Inventory safety contract

Phase 0 shipped no runtime. Phase 1 ships only a read-only adapter, snapshots
and diagnostics; there are no inventory-mutating functions or SavedVariables.
The transaction requirements below apply to future phases. Phases 4 and 5 add
simulation-only seller, repair and destruction state machines. They require a
fake adapter marked `simulation=true`; the runtime has no production transaction
adapter and does not invoke them. This does not authorize testing on the owner's
live inventory.

## Mandatory gates before any sale or deletion
- Restrict scope to carried bags 0..4; exclude bank, equipped inventory, keyring,
  mail, trade and auction containers. Reject invalid coordinates.
- Reproduce upstream eligibility and filter order. The legacy adapter must not
  invent new user-visible protections or reorder list/filter outcomes. Preserve
  upstream quest/equipment-set/unbound option behavior and refund handling.
- Apply configured unbound-equipment and high-value/high-item-level protection;
  unknown data required by an enabled protection blocks the action. Legendary
  and heirloom items remain protected in v1; changing this needs a reviewed
  safety-policy change, not merely an inclusion list.
- Re-evaluate eligibility and re-read id, **full link and count** immediately
  before each call, including after popup acceptance. Any mismatch, new bag
  generation, rule revision, cursor change or expired user intent cancels.
- Block inventory mutation during combat, death, trade, mail, auction or other
  conflicting contexts until proven safe. Never clear or discard cursor contents.
  After pickup, verify cursor type and identity before deletion. If evidence
  differs, cancel; return only to a verified empty original slot if safe, otherwise
  leave the cursor for the user. Never delete to recover from an error.

## Selling and repair
Port the upstream seller state and cancellation behavior using only 3.3.5a APIs.
Auto-sell is off by default. Safe Sell is also off by default; when enabled it
limits sale calls according to the upstream behavior. Preserve the original
manual and automatic controls. Tests use mocks only until code review and
separate authorization for any real-client action test.

Auto-repair defaults off. Check CanMerchantRepair, current cost and personal
funds at execution; repair once per valid merchant session. Guild repair is a
separate future option, not an implicit fallback. Report repair cost separately
from sales; money change alone is not proof of an individual sale.

## Destruction and loot opening
One whole stack per explicit click/key/command; no automatic destruction and no
bulk destructive queue. Default confirmation shows link, count, vendor value and
reason. Even if confirmation is later disabled by the user, a fresh explicit
action and all gates remain mandatory. Popup callbacks consume a single-use
intent, expire on relevant changes and cannot act on stale slots. No retry after
uncertain deletion. The original client's own protected/confirmation behavior
must be respected, never bypassed. Loot opening also requires a deliberate user
action and an adapter-reviewed intent because UseContainerItem away from a vendor
can consume/equip/use rather than sell.

## Observability and evidence
Record bounded in-memory operation diagnostics without account identifiers.
Always separate attempted calls from observed changes and ambiguous results.
A move, split, stack merge or unrelated money delta cannot independently prove
success. Prefer conservative cancellation over preserving throughput. See
[testing](TESTING.md) for required adversarial scenarios and release gates.

The upstream Lists screen has one narrow cursor interaction: clicking a list
with an item deliberately held on the cursor adds the item ID and clears the
cursor, matching `src/ui/components/item-list.lua` at the pinned revision. This
is a list edit, not a sale or deletion. The compatibility UI only clears the
cursor after its list callback reports success; it does not pick up or use an
item. This legacy-client behavior still needs a consolidated in-client UI check.
