local _, Addon = ...
local Legacy = {}
Addon.Legacy = Legacy
local UNKNOWN = Addon.UNKNOWN

-- WotLK clams can use an open-and-loot spell instead of the container flag.
-- Ordinary containers are still recognized generically through tuple[6].
-- Item IDs keep this independent of client locale and exclude food/recipes.
local useEffectLootItems = {
  [5523]=true, -- Small Barnacled Clam
  [5524]=true, -- Thick-shelled Clam
  [7973]=true, -- Big-mouth Clam
  [15874]=true, -- Soft-shelled Clam (quest item)
  [24476]=true, -- Jaggal Clam
  [36781]=true, -- Darkwater Clam
  [45909]=true, -- Giant Darkwater Clam
}

local function plainTooltipLine(text)
  if type(text)~="string" then return nil end
  return text:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):match("^%s*(.-)%s*$")
end

local function integer(value, minimum, maximum)
  return type(value) == "number" and value == math.floor(value) and
    value >= minimum and value <= maximum
end
local function pack(...) return { n = select("#", ...), ... } end
local function read(api, name, ...)
  if type(api[name]) ~= "function" then return nil end
  local result = pack(pcall(api[name], ...))
  if not result[1] then return nil end
  local values = { n = result.n - 1 }
  for i = 2, result.n do values[i - 1] = result[i] end
  return values
end
local function shape(tuple)
  if not tuple then return "unavailable" end
  local types = {}
  for i = 1, tuple.n do types[i] = type(tuple[i]) end
  return tostring(tuple.n) .. ":" .. table.concat(types, ",")
end
local function boolean(value)
  if type(value) == "boolean" then return value end
  -- Some legacy C APIs use 1/nil. Nil remains unknown until client evidence.
  if value == 1 then return true end
  if value == 0 then return false end
  return UNKNOWN
end
-- The pinned 3.3.5 FrameXML uses `if (not locked)` to enable split-stack
-- interaction. A successful nil lock return is therefore the normal unlocked
-- state; API failure still stays unknown because `read` returns nil on failure.
local function lockedState(value)
  if value == nil then return false end
  return boolean(value)
end
local function idFromLink(link)
  if type(link) ~= "string" then return nil end
  local id = tonumber(link:match("item:(%d+):"))
  if integer(id, 1, 2147483647) then return id end
end
local function unknownSlot(bag, slot, reason)
  return {
    bag = bag, slot = slot, state = "UNKNOWN", reason = reason,
    locked = UNKNOWN, quest = UNKNOWN, bound = UNKNOWN, refundable = UNKNOWN,
    inEquipmentSet = UNKNOWN, metadata = UNKNOWN
  }
end

-- Canonical item IDs are not auction-list positions. Match known labels rather
-- than inferring IDs from a compressed/reordered auction tuple. Unknown localized
-- labels stay unknown; they must never silently select a different equipment type.
local classNames = {Weapon=2,Armor=4,Container=1,Consumable=0,Glyph=16,
  ["Trade Goods"]=7,Recipe=9,Gem=3,Miscellaneous=15,Quest=12,Quiver=11,Projectile=6}
local typeNames = {
  [2] = {["One-Handed Axes"]=0,["Two-Handed Axes"]=1,Bows=2,Guns=3,
    ["One-Handed Maces"]=4,["Two-Handed Maces"]=5,Polearms=6,
    ["One-Handed Swords"]=7,["Two-Handed Swords"]=8,Staves=10,
    ["Fist Weapons"]=13,Miscellaneous=14,Daggers=15,Thrown=16,
    Crossbows=18,Wands=19,["Fishing Poles"]=20},
  [4] = {Miscellaneous=0,Cloth=1,Leather=2,Mail=3,Plate=4,
    Cosmetic=5,Shields=6,Librams=7,Idols=8,Totems=9,Sigils=10}
}
function Legacy.ResolveItemType(itemType,itemSubType)
  local classId=classNames[itemType]
  return classId,typeNames[classId] and typeNames[classId][itemSubType]
end
function Legacy.GetEquipmentTypes(api,classId)
  local result={}
  local classes=read(api,"GetAuctionItemClasses")
  if not classes or not typeNames[classId] then return result end
  for index=1,classes.n do
    if classNames[classes[index]]==classId then
      local subclasses=read(api,"GetAuctionItemSubClasses",index)
      if subclasses then
        for subIndex=1,subclasses.n do
          local name=subclasses[subIndex]
          local id=typeNames[classId][name]
          if id~=nil and (id~=0 or classId==2) then
            if not (classId==2 and (id==14 or id==20)) and not (classId==4 and id==5) then
              result[#result+1]={id=id,name=name}
            end
          end
        end
      end
      break
    end
  end
  return result
end

-- Only injected legacy read functions are used; no mutating methods exist.
function Legacy.New(api)
  local adapter = {}
  local function resolveItemType(itemType,itemSubType)
    return Legacy.ResolveItemType(itemType,itemSubType)
  end

  function adapter:ReadBagSize(bag)
    if not integer(bag, 0, 4) then return nil end
    local values = read(api, "GetContainerNumSlots", bag)
    if values and integer(values[1], 0, 128) then return values[1] end
  end

  function adapter:ReadEquipmentSets()
    local sets = read(api, "GetNumEquipmentSets")
    local result = { known = false, ids = {}, count = 0 }
    if not sets or not integer(sets[1], 0, 100) then return result end
    for i = 1, sets[1] do
      local info = read(api, "GetEquipmentSetInfo", i)
      if not info or type(info[1]) ~= "string" or info[1] == "" then return result end
      local items = read(api, "GetEquipmentSetItemIDs", info[1])
      if not items or type(items[1]) ~= "table" then return result end
      for _, id in pairs(items[1]) do
        if integer(id, 1, 2147483647) then
          result.ids[id] = true
        elseif id ~= 0 and id ~= -1 and id ~= false then
          return result
        end
      end
    end
    result.known, result.count = true, sets[1]
    return result
  end

  function adapter:ReadSlot(bag, slot, equipmentSets)
    local item = unknownSlot(bag, slot, "INVALID_SLOT")
    local size = self:ReadBagSize(bag)
    if not size or not integer(slot, 1, size) then return item end
    local info = read(api, "GetContainerItemInfo", bag, slot)
    local links = read(api, "GetContainerItemLink", bag, slot)
    item.containerShape = shape(info)
    if not info or not links then item.reason = "READ_FAILED"; return item end
    if type(info[1]) == "table" then item.reason = "UNEXPECTED_API_SHAPE"; return item end
    local link = links[1] or info[7]
    if info[1] == nil then
      if link ~= nil or info[2] ~= nil then item.reason = "INCONSISTENT_SLOT"; return item end
      if type(api.GetContainerItemID) == "function" then
        local ids = read(api, "GetContainerItemID", bag, slot)
        if not ids or ids[1] ~= nil then item.reason = "INCONSISTENT_SLOT"; return item end
      end
      item.state, item.reason = "EMPTY", nil
      return item
    end
    local id = idFromLink(link)
    if not id or not integer(info[2], 1, 2147483647) then
      item.reason = "INCOMPLETE_SLOT"; return item
    end
    if info[7] ~= nil and info[7] ~= link then
      item.reason = "INCONSISTENT_SLOT"; return item
    end
    if type(api.GetContainerItemID) == "function" then
      local ids = read(api, "GetContainerItemID", bag, slot)
      if not ids or ids[1] ~= id then item.reason = "INCONSISTENT_SLOT"; return item end
    end
    item.state, item.reason = "OCCUPIED", nil
    item.itemId, item.link, item.count, item.texture = id, link, info[2], info[1]
    item.locked, item.readable, item.lootable = lockedState(info[3]), boolean(info[5]), boolean(info[6])
    if useEffectLootItems[id] then item.lootable=true end
    -- Some legacy/custom clients omit the loot flag but retain the stock,
    -- localized open-container instruction. Match that exact instruction,
    -- never generic Use text (which includes food, recipes and quest actions).
    if item.lootable~=true and type(api.ITEM_OPENABLE)=="string" and
        api.ITEM_OPENABLE~="" and type(api.ReadBindingLines)=="function" then
      local ok,lines=pcall(api.ReadBindingLines,bag,slot)
      if ok and type(lines)=="table" then
        local marker=plainTooltipLine(api.ITEM_OPENABLE)
        for _,line in ipairs(lines) do
          if plainTooltipLine(line)==marker then item.lootable=true; break end
        end
      end
      -- Tooltip population can execute hooks. Do not attach the previous
      -- item's loot eligibility to a slot replaced while those hooks ran.
      local latest=read(api,"GetContainerItemLink",bag,slot)
      local latestInfo=read(api,"GetContainerItemInfo",bag,slot)
      if not latest or latest[1]~=link or not latestInfo or latestInfo[2]~=item.count then
        return unknownSlot(bag,slot,"STALE_TOOLTIP_SLOT")
      end
      item.locked=lockedState(latestInfo[3])
    end
    if integer(info[4], 0, 7) then item.quality = info[4] end
    local metadata = read(api, "GetItemInfo", link)
    item.itemInfoShape = shape(metadata)
    if metadata and type(metadata[1]) == "string" and type(metadata[2]) == "string" and
        metadata[2] == link and integer(metadata[3], 0, 7) and
        integer(metadata[4], 0, 2147483647) then
      item.metadata = "known"
      item.name = metadata[1]
      item.quality, item.itemLevel = metadata[3], metadata[4]
      item.itemType, item.itemSubType, item.equipLoc = metadata[6], metadata[7], metadata[9]
      if integer(metadata[12],0,20) then item.classId=metadata[12] end
      if integer(metadata[13],0,100) then item.subclassId=metadata[13] end
      if item.classId==nil then
        local classId,subclassId=resolveItemType(item.itemType,item.itemSubType)
        if integer(classId,0,20) then item.classId=classId end
        if integer(subclassId,0,100) then item.subclassId=subclassId end
      end
      if integer(metadata[11], 0, 2147483647) then item.unitVendorPrice = metadata[11] end
    end
    local quest = read(api, "GetContainerItemQuestInfo", bag, slot)
    item.questShape = shape(quest)
    if quest and quest.n >= 2 then
      local questFlag = boolean(quest[1])
      if questFlag == true or (quest[2] ~= nil and quest[2] ~= false) then item.quest = true
      elseif (quest[1] == nil or quest[1] == false or quest[1] == 0) and
          (quest[2] == nil or quest[2] == false) then item.quest = false end
    end
    local purchase = read(api, "GetContainerItemPurchaseInfo", bag, slot, false)
    item.purchaseShape = shape(purchase)
    if purchase then
      -- Stock FrameXML hides the refund prompt when refundSec is absent, and
      -- successful zero-return reads on this client use that same no-refund path.
      if purchase[5] == nil then item.refundable = false
      elseif type(purchase[5]) == "number" and purchase[5] >= 0 and purchase[5] < math.huge then
        item.refundSeconds, item.refundable = purchase[5], purchase[5] > 0
      end
    end
    if equipmentSets and equipmentSets.known then
      item.inEquipmentSet = equipmentSets.ids[id] == true
    end
    return item
  end

  -- Explicit slot probe only; never used to decide transaction eligibility.
  function adapter:ReadBinding(bag, slot)
    local size = self:ReadBagSize(bag)
    if not size or not integer(slot, 1, size) then
      return UNKNOWN
    end
    if type(api.ReadBindingLines) ~= "function" then return UNKNOWN end
    local ok, lines = pcall(api.ReadBindingLines, bag, slot)
    if not ok or type(lines) ~= "table" then return UNKNOWN end
    local unbound = false
    for _, line in ipairs(lines) do
      if type(line) == "string" then
        if (type(api.ITEM_SOULBOUND) == "string" and line == api.ITEM_SOULBOUND) or
            (type(api.ITEM_BIND_TO_ACCOUNT) == "string" and line == api.ITEM_BIND_TO_ACCOUNT) then
          return true
        end
        if (type(api.ITEM_BIND_ON_EQUIP) == "string" and line == api.ITEM_BIND_ON_EQUIP) or
            (type(api.ITEM_BIND_ON_USE) == "string" and line == api.ITEM_BIND_ON_USE) then
          unbound = true
        end
      end
    end
    if unbound then return false end
    return UNKNOWN
  end

  return adapter
end
