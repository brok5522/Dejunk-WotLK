local _, Addon = ...
local Rules = {}
Addon.Rules = Rules

local UNKNOWN = Addon.UNKNOWN
local function isUnknown(value) return value == nil or value == UNKNOWN end
local function listHas(list, id) return type(list) == "table" and list[id] == true end
local function applies(option, action)
  return type(option)=="table" and option.enabled==true and
    (option.scope=="BOTH" or option.scope==action)
end
local function selectedQuality(option, quality)
  local names={[0]="poor",[1]="common",[2]="uncommon",[3]="rare",[4]="epic"}
  local name=names[quality]
  return name~=nil and type(option.qualities)=="table" and option.qualities[name]==true
end
local function isEquipment(item)
  return type(item.equipLoc)=="string" and item.equipLoc~=""
end
local function equipmentTypeSelected(item, option)
  if not isEquipment(item) then return false end
  if type(item.classId)~="number" then return nil end
  if item.classId==4 then
    if type(item.subclassId)~="number" or type(option.armor)~="table" then return nil end
    return option.armor[item.subclassId]==true
  end
  if item.classId==2 then
    if type(item.subclassId)~="number" or type(option.weapons)~="table" then return nil end
    return option.weapons[item.subclassId]==true
  end
  return false
end
local function decision(result, reason, action, ruleId)
  return { result=result, reasonCode=reason, action=action, ruleId=ruleId }
end
local function junkDecision(action, reason, item, ruleId)
  if action == "SELL" then
    if item.refundable==UNKNOWN then return decision("UNKNOWN", "REFUND_UNKNOWN", action, ruleId) end
    if item.refundable then return decision("KEEP", "REFUNDABLE", action, ruleId) end
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
  -- WotLK has Poor through Epic; newer quality categories are outside this
  -- client's item model.
  if item.quality == 5 or item.quality == 7 then
    return decision("KEEP", "LEGENDARY_OR_HEIRLOOM", action)
  end

  -- Upstream exclusion thresholds precede the four ordered lists.
  local profile = settings.profile or {}
  local global = settings.global or {}
  local options=profile.options or {}
  local excludeLevel=options.excludeAboveItemLevel
  if applies(excludeLevel,action) and isEquipment(item) and selectedQuality(excludeLevel,item.quality) then
    if type(excludeLevel.value)~="number" then return decision("UNKNOWN","INVALID_SETTINGS",action) end
    if isUnknown(item.itemLevel) then return decision("UNKNOWN", "ITEM_LEVEL_UNKNOWN", action) end
    if item.itemLevel > excludeLevel.value then return decision("KEEP", "ABOVE_MAX_ITEM_LEVEL", action) end
  end
  local excludePrice=options.excludeAbovePrice
  if not excludePrice and type(settings.maxStackVendorPrice)=="number" then
    excludePrice={enabled=true,scope="SELL",value=settings.maxStackVendorPrice,qualities={poor=true,common=true,uncommon=true,rare=true,epic=true}}
  end
  if applies(excludePrice,action) and selectedQuality(excludePrice,item.quality) then
    if type(excludePrice.value)~="number" then return decision("UNKNOWN","INVALID_SETTINGS",action) end
    if isUnknown(item.unitVendorPrice) then return decision("UNKNOWN", "PRICE_UNKNOWN", action) end
    if item.unitVendorPrice>0 and item.unitVendorPrice * item.count > excludePrice.value then
      return decision("KEEP", "ABOVE_MAX_STACK_PRICE", action)
    end
  end

  if listHas(profile.exclusions, item.itemId) then return decision("KEEP", "PROFILE_EXCLUSION", action) end
  if listHas(profile.inclusions, item.itemId) then return junkDecision(action, "PROFILE_INCLUSION", item) end
  if listHas(global.exclusions, item.itemId) then return decision("KEEP", "GLOBAL_EXCLUSION", action) end
  if listHas(global.inclusions, item.itemId) then return junkDecision(action, "GLOBAL_INCLUSION", item) end

  -- Upstream order: ordinary lists are evaluated before these profile filters.
  local equipmentSetOption=options.excludeEquipmentSets
  if equipmentSetOption==true then equipmentSetOption={enabled=true,scope="BOTH"} end
  if applies(equipmentSetOption,action) then
    if isUnknown(item.inEquipmentSet) then return decision("UNKNOWN", "EQUIPMENT_SET_UNKNOWN", action) end
    if item.inEquipmentSet then return decision("KEEP", "EQUIPMENT_SET_ITEM", action) end
  end
  local unboundOption=options.excludeUnboundEquipment
  if unboundOption==true then unboundOption={enabled=true,scope="BOTH",qualities={poor=true,common=true,uncommon=true,rare=true,epic=true}} end
  if applies(unboundOption,action) and isEquipment(item) and selectedQuality(unboundOption,item.quality) then
    if isUnknown(item.bound) then return decision("UNKNOWN", "BINDING_UNKNOWN", action) end
    if item.bound==false then return decision("KEEP", "UNBOUND_EQUIPMENT", action) end
  end

  local excludeType=options.excludeByEquipmentType
  if applies(excludeType,action) and selectedQuality(excludeType,item.quality) then
    local selected=equipmentTypeSelected(item,excludeType)
    if selected==nil then return decision("UNKNOWN","EQUIPMENT_TYPE_UNKNOWN",action) end
    if selected then return decision("KEEP","EXCLUDED_EQUIPMENT_TYPE",action) end
  end
  local questOption=options.excludeQuestItems
  if questOption==true then questOption={enabled=true,scope="BOTH"} end
  -- The legacy client represents the quest-item class as numeric ID 12.
  if applies(questOption,action) then
    if item.classId==12 or item.quest==true then return decision("KEEP", "QUEST_ITEM", action) end
    if item.classId==nil and isUnknown(item.quest) then return decision("UNKNOWN","QUEST_UNKNOWN",action) end
  end
  local includeQuality=options.includeByQuality
  if includeQuality==nil and options.quality then
    includeQuality={enabled=true,scope="BOTH",qualities={poor=options.quality[0],common=options.quality[1],uncommon=options.quality[2],rare=options.quality[3],epic=options.quality[4]}}
  end
  if applies(includeQuality,action) and selectedQuality(includeQuality,item.quality) then
    return junkDecision(action,"QUALITY",item)
  end
  local includeLevel=options.includeBelowItemLevel
  if not includeLevel and type(settings.minItemLevel)=="number" then
    includeLevel={enabled=true,scope="BOTH",value=settings.minItemLevel,qualities={poor=true,common=true,uncommon=true,rare=true,epic=true}}
  end
  if applies(includeLevel,action) and isEquipment(item) and selectedQuality(includeLevel,item.quality) then
    if type(includeLevel.value)~="number" then return decision("UNKNOWN","INVALID_SETTINGS",action) end
    if isUnknown(item.itemLevel) then return decision("UNKNOWN", "ITEM_LEVEL_UNKNOWN", action) end
    if item.itemLevel < includeLevel.value then
      return junkDecision(action, "BELOW_MIN_ITEM_LEVEL", item)
    end
  end
  local includePrice=options.includeBelowPrice
  if applies(includePrice,action) and selectedQuality(includePrice,item.quality) then
    if type(includePrice.value)~="number" then return decision("UNKNOWN","INVALID_SETTINGS",action) end
    if isUnknown(item.unitVendorPrice) then return decision("UNKNOWN","PRICE_UNKNOWN",action) end
    if item.unitVendorPrice>0 and item.unitVendorPrice*item.count<includePrice.value then return junkDecision(action,"BELOW_MIN_STACK_PRICE",item) end
  end
  local includeType=options.includeByEquipmentType
  if applies(includeType,action) and selectedQuality(includeType,item.quality) then
    local selected=equipmentTypeSelected(item,includeType)
    if selected==nil then return decision("UNKNOWN","EQUIPMENT_TYPE_UNKNOWN",action) end
    if selected then return junkDecision(action,"INCLUDED_EQUIPMENT_TYPE",item) end
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
