# Inventory safety contract

Phase 0 executes no inventory operations and ships no runtime. Future operation
support does not authorize testing on the owner's live inventory.

## Mandatory gates before any sale or deletion
- Restrict scope to carried bags 0..4; exclude bank, equipped inventory, keyring,
  mail, trade and auction containers. Reject invalid coordinates.
- Require complete metadata, unlocked item, empty cursor and coherent snapshot.
  Protect quest items, equipment-set items and uncertain safety classifications
  before inclusion lists. Protect refundable items from both actions by default
  (stricter than upstream, which blocks them only from sale).
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
State machine: IDLE → WAITING_FOR_STABLE_BAGS → REVALIDATING → ATTEMPTING →
WAITING_FOR_EVIDENCE → IDLE or next candidate. At most one unacknowledged action.
Bounded waits, no busy loop, no automatic retries on ambiguity. Cancel on merchant
close/change, logout, combat, settings/profile change or API error. A timeout is
reported as uncertain, not success. Auto-sell is opt-in, once per merchant session.
Safe Sell defaults on and limits **attempted stacks** to 12 for the entire
merchant session, including repeated manual starts; no bypass through single-row
sales. The buyback window is not a guarantee against loss and must be explained.

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
