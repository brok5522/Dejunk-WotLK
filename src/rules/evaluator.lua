local _, Addon = ...
local Rules = {}
Addon.Rules = Rules

local UNKNOWN = Addon.UNKNOWN
local function isUnknown(value) return value == nil or value == UNKNOWN end
local function listHas(list, id) return type(list) == "table" and list[id] == true end
local function decision(result, reason, action, ruleId)
  return { result=result, reasonCode=reason, action=action, ruleId=ruleId }
end
local function junkDecision(action, reason, item, ruleId)
  if action == "SELL" then
    if isUnknown(item.unitVendorPrice) then return decision("UNKNOWN", "PRICE_UNKNOWN", action, ruleId) end
    if item.unitVendorPrice <= 0 then return decision("KEEP", "NO_VENDOR_VALUE", action, ruleId) end
  end
  return decision("JUNK", reason, action, ruleId)
end

-- Pure decision function. It has no game API access and cannot trigger actions.
function Rules.Evaluate(item, action, settings)
  settings = settings or {}
  if action ~= "SELL" and action ~= "DESTROY" then
    return decision("UNKNOWN", "INVALID_ACTION", action)
  end
  if type(item) ~= "table" or item.state == "UNKNOWN" then
    return decision("UNKNOWN", "ITEM_UNKNOWN", action)
  end
  if item.state == "EMPTY" then return decision("KEEP", "EMPTY_SLOT", action) end
  if item.state ~= "OCCUPIED" then return decision("UNKNOWN", "ITEM_UNKNOWN", action) end
  if type(item.itemId)~="number" or item.itemId<1 or item.itemId~=math.floor(item.itemId) or
      type(item.count)~="number" or item.count<1 or item.count~=math.floor(item.count) or
      item.metadata ~= "known" then
    return decision("UNKNOWN", "METADATA_UNKNOWN", action)
  end
  if isUnknown(item.locked) then return decision("UNKNOWN", "LOCK_UNKNOWN", action) end
  if item.locked then return decision("KEEP", "LOCKED", action) end
  if isUnknown(item.quest) then return decision("UNKNOWN", "QUEST_UNKNOWN", action) end
  if item.quest then return decision("KEEP", "QUEST_ITEM", action) end
  if isUnknown(item.inEquipmentSet) then return decision("UNKNOWN", "EQUIPMENT_SET_UNKNOWN", action) end
  if item.inEquipmentSet then return decision("KEEP", "EQUIPMENT_SET_ITEM", action) end
  if isUnknown(item.refundable) then return decision("UNKNOWN", "REFUND_UNKNOWN", action) end
  if item.refundable then return decision("KEEP", "REFUNDABLE", action) end
  if item.equipLoc and item.equipLoc ~= "" and settings.protectUnboundEquipment ~= false then
    if isUnknown(item.bound) then return decision("UNKNOWN", "BINDING_UNKNOWN", action) end
    if item.bound == false then return decision("KEEP", "UNBOUND_EQUIPMENT", action) end
  end

  -- Price exclusions are safety-style ordinary exclusions and precede lists.
  local maxLevel = settings.maxItemLevel
  if maxLevel ~= nil then
    if type(maxLevel)~="number" then return decision("UNKNOWN", "INVALID_SETTINGS", action) end
    if isUnknown(item.itemLevel) then return decision("UNKNOWN", "ITEM_LEVEL_UNKNOWN", action) end
    if item.itemLevel > maxLevel then return decision("KEEP", "ABOVE_MAX_ITEM_LEVEL", action) end
  end
  local maxStackPrice = settings.maxStackVendorPrice
  if maxStackPrice ~= nil then
    if type(maxStackPrice)~="number" then return decision("UNKNOWN", "INVALID_SETTINGS", action) end
    if isUnknown(item.unitVendorPrice) then return decision("UNKNOWN", "PRICE_UNKNOWN", action) end
    if item.unitVendorPrice * item.count > maxStackPrice then
      return decision("KEEP", "ABOVE_MAX_STACK_PRICE", action)
    end
  end

  local profile = settings.profile or {}
  local global = settings.global or {}
  if listHas(profile.exclusions, item.itemId) then return decision("KEEP", "PROFILE_EXCLUSION", action) end
  if listHas(global.exclusions, item.itemId) then return decision("KEEP", "GLOBAL_EXCLUSION", action) end

  -- Custom ordered groups are intentionally data-only; malformed groups fail closed.
  for _, group in ipairs(profile.rules or {}) do
    local match, uncertain = Rules.MatchGroup(item, group, action)
    if uncertain then return decision("UNKNOWN", "RULE_DATA_UNKNOWN", action, group.id) end
    if match then
      if group.result == "JUNK" then return junkDecision(action, "CUSTOM_RULE", item, group.id) end
      return decision("KEEP", "CUSTOM_RULE", action, group.id)
    end
  end

  if listHas(profile.inclusions, item.itemId) then return junkDecision(action, "PROFILE_INCLUSION", item) end
  if listHas(global.inclusions, item.itemId) then return junkDecision(action, "GLOBAL_INCLUSION", item) end

  local options = profile.options or {}
  if options.quality and item.quality ~= nil and options.quality[item.quality] == true then
    return junkDecision(action, "QUALITY", item)
  end
  if settings.minItemLevel ~= nil then
    if type(settings.minItemLevel)~="number" then return decision("UNKNOWN", "INVALID_SETTINGS", action) end
    if isUnknown(item.itemLevel) then return decision("UNKNOWN", "ITEM_LEVEL_UNKNOWN", action) end
    if item.itemLevel < settings.minItemLevel then
      return junkDecision(action, "BELOW_MIN_ITEM_LEVEL", item)
    end
  end
  return decision("KEEP", "NO_RULE_MATCH", action)
end

function Rules.MatchGroup(item, group, action)
  if type(group) ~= "table" then return false, true end
  if group.scope ~= "BOTH" and group.scope ~= action then return false, false end
  if (group.result ~= "JUNK" and group.result ~= "KEEP") or
      (group.match ~= "ALL" and group.match ~= "ANY") or type(group.predicates) ~= "table" or
      #group.predicates == 0 then return false, true end
  local matched, unknown, mismatched = 0, 0, 0
  for _, predicate in ipairs(group.predicates) do
    if type(predicate) ~= "table" then return false, true end
    local value, op, expected = predicate.field, predicate.op, predicate.value
    local actual = item[value]
    if isUnknown(actual) then unknown = unknown + 1
    elseif op == "EQ" then if actual == expected then matched = matched + 1 else mismatched=mismatched+1 end
    elseif op == "LT" or op == "GT" then
      if type(actual) ~= "number" or type(expected) ~= "number" then return false, true end
      if (op == "LT" and actual < expected) or (op == "GT" and actual > expected) then matched = matched + 1 else mismatched=mismatched+1 end
    else return false, true end
  end
  if group.match == "ALL" then
    if mismatched > 0 then return false, false end
    if unknown > 0 then return false, true end
    return matched == #group.predicates, false
  end
  if matched > 0 then return true, false end
  if unknown > 0 then return false, true end
  return false, false
end

return Rules
