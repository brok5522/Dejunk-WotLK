local _, Addon = ...
local Legacy = {}
Addon.Legacy = Legacy
local UNKNOWN = Addon.UNKNOWN

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

-- Only injected legacy read functions are used; no mutating methods exist.
function Legacy.New(api)
  local adapter = {}

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
    if integer(info[4], 0, 7) then item.quality = info[4] end
    local metadata = read(api, "GetItemInfo", link)
    item.itemInfoShape = shape(metadata)
    if metadata and type(metadata[1]) == "string" and type(metadata[2]) == "string" and
        metadata[2] == link and integer(metadata[3], 0, 7) and
        integer(metadata[4], 0, 2147483647) then
      item.metadata = "known"
      item.quality, item.itemLevel = metadata[3], metadata[4]
      item.itemType, item.itemSubType, item.equipLoc = metadata[6], metadata[7], metadata[9]
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
