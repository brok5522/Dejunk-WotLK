# Original WotLK API compatibility

Evidence levels: **F** = observed in pinned 3.3.5 FrameXML source; **U** =
observed upstream incompatibility; **P** = proposed alternative requiring client
verification. FrameXML is a community mirror, not a runtime execution trace or
complete C API signature catalogue. No live-client compatibility is claimed.
See [sources](SOURCES.md). [api-symbols.csv](api-symbols.csv) inventories modern
namespace/method candidates with upstream file/line references; it is a lexical
inventory, not an exhaustive list of all globals or proof that every row fails.

| Upstream dependency / problem | WotLK alternative and evidence | Status / verification |
| --- | --- | --- |
| TOC modern interfaces; WOW_PROJECT_* flags | Interface 30300; GetBuildInfo version/build/interface, reject mismatched client | U/P; exact target check in Phase 1 |
| C_AddOns.GetAddOnMetadata | global GetAddOnMetadata | U/P; read-only startup probe |
| GetNormalizedRealmName, fastrandom | UnitName + GetRealmName, deterministic persisted profile ID counter | U/P; do not normalize realm into collisions |
| C_Container.GetContainerNumSlots/ItemID/ItemInfo | global functions; GetContainerItemInfo returns tuple, not table. Normalize texture,count,locked,quality,readable,lootable,link; use GetContainerItemLink if needed | F: ContainerFrame.lua:281, EquipmentManager.lua:282; extra tuple positions require probe |
| C_Container.GetContainerItemPurchaseInfo table.refundSeconds | global tuple money,honor,arena,itemCount,refundSec (fifth return) | F: ContainerFrame.lua:632; never treat unknown as non-refundable |
| C_Container.UseContainerItem / PickupContainerItem | global UseContainerItem / PickupContainerItem | F: ContainerFrame.lua:700, EquipmentManager.lua:97; planned executor only, never called in Phase 0 |
| C_Item.GetItemInfo and extra class/subclass numeric returns | global GetItemInfo; old localized itemType/itemSubType returns; build locale-safe lookup from legacy class tables/client categories; use link for ID | F: MailFrame.lua:91; P for classification mapping; do not assume return 12/13 exist |
| GetItemInfoInstant and modern uncached item handling | validate positive integer IDs; GetItemInfo + bounded retry on scheduler and bag refresh; unknown retained but ineligible | U/P; invalid/uncached IDs must not stall forever |
| ItemLocation; C_Item.IsLocked | third return of global GetContainerItemInfo | F: EquipmentManager.lua:284 |
| C_Item.IsBound / IsBoundToAccountUntilEquip | hidden GameTooltip:SetBagItem scan using localized ITEM_SOULBOUND and known binding strings | F: ContainerFrame.lua:774 and GlobalStrings.lua; P: tri-state scan, unknown protects, locales and account-bound heirlooms need testing |
| C_Item.GetCurrentItemLevel / GetDetailedItemLevelInfo | GetItemInfo base itemLevel (fourth return) | F: MailFrame.lua:91; P: document base-level semantics, no modern scaling |
| Enum.ItemQuality/Class/subclass | private constants for qualities (0–7) and verified WotLK categories; localized class mapping, not English comparisons | U/P; verify weapon/armor/quest and relic types in each supported locale |
| C_EquipmentSet IDs and locations | GetNumEquipmentSets, GetEquipmentSetInfo(index), GetEquipmentSetItemIDs(name); conservatively protect all matching item IDs across bags | F: PaperDollFrame.lua:1120,2224; P: duplicate IDs overprotected intentionally; refine only with verified location API |
| BAG_UPDATE_DELAYED, INVENTORY_SEARCH_UPDATE | coalesce BAG_UPDATE and ITEM_LOCK_CHANGED using OnUpdate, plus ITEM_LOCKED/UNLOCKED where observed; full rescan on login | F: ContainerFrame.lua, EquipmentManager.lua; P: event existence and payload probes; no dependence on absent events |
| UI_ERROR_MESSAGE(_,message) | legacy event's first argument is message | F: UIErrorsFrame.lua:14; normalize before seller cancellation |
| C_Timer assumption in future libraries | small cancellable OnUpdate scheduler | upstream already uses custom OnUpdate; do not incorrectly count C_Timer as an upstream requirement |
| Settings.Register* | InterfaceOptions_AddCategory with native options panel or launcher into own window | F: InterfaceOptionsFrame.lua:585 |
| BackdropTemplateMixin / Mixin | legacy frame:SetBackdrop; ordinary Lua composition | U/P; audit frame types and backdrop keys |
| SetColorTexture | texture:SetTexture(r,g,b,a) legacy solid-color path | U/P; test alpha and texture reset |
| SetPropagateMouseClicks/Motion, modern keyboard helpers | omit propagation APIs; explicit EnableMouse / OnKeyDown and legacy modifier state; Bindings.xml/SetBindingClick where appropriate | U/P; verify focus, Escape, wheel and conflicts out of combat |
| SOUNDKIT.ITEM_REPAIR | legacy sound name such as PlaySound("ITEM_REPAIR"), or omit optional sound | F: MerchantFrame.xml; audit exact string |
| Numeric texture file IDs (including LibDBIcon) | Interface\... texture paths or independently licensed .tga/.blp | U/P; verify in original client; never assume modern IDs resolve |
| Default bag frame = bag+1 assumption | enumerate visible ContainerFrame1..NUM_CONTAINER_FRAMES; use frame:GetID() bag and child button:GetID() slot | F: ContainerFrame.lua; P: bag open order and reused frames test |
| Third-party bag integrations | version-specific adapters for original-client Bagnon/ArkInventory/ElvUI releases | U/P; current upstream integrations are not compatible by name alone; default bags first |
| AddonCompartmentFrame / warband / artifact relic APIs | not applicable to 3.3.5a; no substitutes needed | U; omit controls and list as intentional N/A |
| Repair functions | CanMerchantRepair, GetRepairAllCost, GetMoney, RepairAllItems | F: MerchantFrame.lua/xml; P: personal funds, merchant generation, no automatic action by default |
| Tooltip extension | hooksecurefunc(GameTooltip,"SetBagItem",...) and legacy AddLine | upstream uses this already; F for SetBagItem; avoid recursive hidden scan hook |
| securecallfunction in CallbackHandler minor 8 | select audited historical CallbackHandler using a verified legacy protected-dispatch mechanism, or no library dependency | U/P; do not replace protected dispatch blindly with direct calls |

## Read-only Phase 1 probe plan
Capture GetBuildInfo and presence/types of required globals; tuple arity and
values on known bags/items, localized class/binding strings, equipment sets and
merchant/error events. No pickup, use, cursor clearing, deletion, selling or
repair calls in probes. Publish sanitized results without character/account
identifiers. Until verified, refund/binding/set uncertainties block actions.

## Phase 1 implementation evidence (offline only)
The root TOC now uses Interface 30300. `src/compat/client.lua` accepts version
3.3.5 or 3.3.5a only with build 12340 and Interface 30300; missing required read
APIs disable startup. `legacy.lua` normalizes original tuple returns, reads
localized class/subclass labels without pretending they are numeric enums,
uses the fifth refund return, and protects uncertainty with explicit unknowns.
Equipment-set IDs are read conservatively. No class mapping or complete binding
classification is claimed yet: binding is an opt-in localized tooltip probe,
and absent text, missing APIs or nil flags stay unknown. Refund nil is also
unknown pending actual-client evidence. `runtime.lua` owns legacy frames and
all game access. `core/diagnostics.lua` reports tuple arity/types and event
argument types; report values exclude character names and hyperlinks.
The offline harness verifies these contracts with synthetic legacy APIs.
[Original-client verification](../CLIENT-ACCEPTANCE.md) remains pending.
