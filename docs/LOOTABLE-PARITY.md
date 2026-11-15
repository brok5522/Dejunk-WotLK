# Lootable scope on original 3.3.5a

Pinned upstream: `04bafd5e411441ef5b51bb8ed10d208f2d7758f5`.
`src/blizzard/blizzard.lua:281` assigns `item.lootable = t.hasLoot`.
`src/ui/screens/lootable-frame.lua:34` retains lootable non-ignored items.
Its row click checks busy state, slot identity and lock, then calls
`C_Container.UseContainerItem`. There is no upstream item-ID allowlist and no
automatic loop opening every item. Ignore applies to the whole item ID for the session.

The legacy adapter uses the sixth return of `GetContainerItemInfo` for the same
general container indication. Any flagged bag item is included, without needing
its ID in a list: boxes, gifts, rewards and other containers follow this path.
Locked containers may appear but cannot open until their requirements are met.

WotLK use-effect clams receive an explicit compatibility extension because their
open-and-loot spell can leave the container flag false. Supported identities:

| ID | Item | Reference |
|---|---|---|
| 5523 | Small Barnacled Clam | https://wotlk.evowow.com/?item=5523 |
| 5524 | Thick-shelled Clam | https://wotlk.evowow.com/?item=5524 |
| 7973 | Big-mouth Clam | https://wotlk.evowow.com/?item=7973 |
| 15874 | Soft-shelled Clam | https://wotlk.evowow.com/?item=15874 |
| 24476 | Jaggal Clam | https://wotlk.evowow.com/?item=24476 |
| 36781 | Darkwater Clam | https://wotlk.evowow.com/?item=36781 |
| 45909 | Giant Darkwater Clam | https://wotlk.cavernoftime.com/item=45909 |

This extension is deliberately identity-based: a Use tooltip alone also describes
food, potions, recipes and quest actions. Those must not become loot containers.
Custom-server spell-based containers without the native loot flag are not
automatically proven supported. No universal classification claim is made for them.
Starting with 0.16.64, an exact localized `ITEM_OPENABLE` tooltip instruction also
identifies unflagged containers. The stock English constant is defined in
build-12340 GlobalStrings.lua:4486. Tooltip color codes/whitespace are normalized;
partial matches and generic Use effects are excluded. The slot link/count and
lock are read again after scanning. Spell-only custom items with neither the flag
nor the standard instruction still require evidence.
Both cache construction and transaction rereads share this adapter, so the
recognized clam is not rejected at click time. Action dispatch still checks current
identity/count, lock, cursor, settings and context.

Offline coverage tests all seven clam IDs, an arbitrary flagged container and
ordinary non-loot consumables, using fake APIs only. Native-client acceptance
across all item types remains for owner testing.
