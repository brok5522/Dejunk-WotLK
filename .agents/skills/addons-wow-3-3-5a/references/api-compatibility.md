# Original 3.3.5a API field guide

Target: original 3.3.5a/build 12340/Interface 30300. Evidence is the pinned community
FrameXML mirror in [research-index.md](research-index.md), the port source, and
reported client behavior. A community mirror can be incomplete; probe uncertain APIs.

## Target and language

- Read `GetBuildInfo()` as `version, build, buildDate, interface`. Parse numeric
  build/interface explicitly; do not accept Wrath Classic merely because it says Wrath.
- TOC target: `## Interface: 30300`. The in-window game label and addon release
  version are separate concepts. The owner requested a 3.3.5 label for Dejunk.
- Lua 5.1: use `unpack`, not an assumed `table.unpack`; preserve local scope and
  declaration order. No `goto`, newer operators or assumed modern standard library.
- Lua treats **0 as true**. Normalize legacy flags returned as 1/nil or 1/0.
- `pcall(f)` success with a nil return must be distinguishable from a thrown call.
  For arbitrary tuples preserve return count; `{pcall(f)}` alone cannot represent
  all trailing nils. Do not shift the payload indexes after adding pcall's success flag.

## Modern → legacy candidates

| Modern assumption | Original-client approach | Caveat |
|---|---|---|
| `C_Container.*` | Global container functions | Tuple shapes differ; do not forward modern tables unchanged |
| `C_AddOns.GetAddOnMetadata` | `GetAddOnMetadata` | Capability-check the executed path |
| `C_Item.GetItemInfo` | `GetItemInfo` | Metadata can be uncached; no modern numeric class returns assumed |
| `Settings.Register*` | `InterfaceOptions_AddCategory` | Custom UI can be hosted separately |
| `C_Timer` | Small cancellable `OnUpdate` scheduler | Not every upstream addon actually requires C_Timer |
| Modern equipment sets | `GetNumEquipmentSets`, `GetEquipmentSetInfo`, `GetEquipmentSetItemIDs` | ID membership is conservative with duplicates |
| `ItemLocation`, modern lock calls | Container slot/tuple plus verified identity | Never infer identity from slot alone |
| `C_Item.IsBound` | Localized hidden tooltip scan if needed | Tri-state; locale coverage requires evidence |
| `Enum.*` | Private verified constants/crosswalks | No global fake Enum namespace |
| `BAG_UPDATE_DELAYED` | Coalesce legacy bag/lock events | Verify names and payloads in original sources |
| Modern UI-error arguments | Normalize original `UI_ERROR_MESSAGE` first argument | Original first argument is the message |

These are migration starting points, not a complete compatibility catalogue.
`research-snapshot/api-symbols.csv` is a lexical inventory from one pinned addon;
a match there is neither a general API signature nor proof that a call executes.

## Bag and item reads

Original `GetContainerItemInfo(bag, slot)` is consumed as:

```lua
local texture, count, locked, quality, readable, lootable, link =
  GetContainerItemInfo(bag, slot)
```

Some modified clients expose extra returns; do not silently accept a Retail-style
record in the stock tuple adapter. Keep empty slots separate from occupied but
unknown items. An item ID/link without a texture is not evidence of an empty slot.

Stock `ContainerFrame.lua` permits interaction under `if (not locked)`. Thus a
successful **nil lock return means unlocked** for that legacy API. Do not apply
this rule to a missing function or a failed pcall. Similarly, successful falsey
quest-marker tuples and nil quest IDs are ordinary negative marker states in the
stock bag UI; failed or unavailable reads are still unknown.

`GetContainerItemPurchaseInfo` is consumed as:

```lua
local money, honor, arena, itemCount, refundSeconds =
  GetContainerItemPurchaseInfo(bag, slot)
```

Refund time is the **fifth** return, not fourth. The stock UI hides its refund
prompt for absent seconds after a successful read; a missing/throwing API is not
proof of no refund. `GetItemInfo` vendor price 0 is known no-value, not unknown.
Its first eleven legacy fields are name, link, quality, item level, required
level, type, subtype, max stack, equip location, texture and vendor price.

## Categories, binding and caching

- Original GetItemInfo returns localized type/subtype names. English comparisons
  break other locales. Auction label lists can help map labels, but the mapping
  of **list position to actual item subclass ID is not universally proven**.
  Do not assume every armor/weapon category is contiguous or shares Retail IDs.
- In Dejunk-WotLK the auction-label/index crosswalk is an internal implementation
  choice pending fuller client/locale verification. In particular fishing-pole,
  shield, generic and special-equipment behavior needs targeted fixtures.
- A tooltip scan must avoid recursion into its own hook. Use a dedicated hidden
  tooltip and localized binding strings; unknown binding is not unbound.
- Invalidate old snapshots immediately on bag/lock/equipment changes. Coalesce
  rescans and keep retrying uncached metadata for a bounded time/attempt count.
  Never let one missing item block all other rows indefinitely.
- Track generation/revision. A cache invalidated during its own scan must not
  publish itself as current. Expose copies so callers cannot mutate cached data.
- A bag scan for inventory cleanup should normally be bounded to carried bags
  0..4; bank/keyring/mail/equipment need separate explicit support.

## Adapters and probes

Use injected APIs for tests and the actual `_G` only at the runtime boundary.
Record the function availability, build, tuple return count/types and sanitized
values needed to resolve the uncertainty. Do not dump links, account identifiers
or complete SavedVariables to public logs. A probe must not invoke UseContainerItem,
PickupContainerItem, DeleteCursorItem or RepairAllItems just to discover behavior.
