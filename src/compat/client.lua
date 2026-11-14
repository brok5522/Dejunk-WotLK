local _, Addon = ...
local Client = {}
Addon.Client = Client

Client.Required = {
  "CreateFrame", "GetContainerNumSlots", "GetContainerItemInfo",
  "GetContainerItemLink", "GetItemInfo"
}
Client.Optional = {
  "GetContainerItemID", "GetContainerItemQuestInfo", "GetContainerItemPurchaseInfo",
  "GetNumEquipmentSets", "GetEquipmentSetInfo", "GetEquipmentSetItemIDs",
  "GetAuctionItemClasses", "GetAuctionItemSubClasses",
  "GetLocale", "GetAddOnMetadata", "CanMerchantRepair", "GetRepairAllCost",
  "GetMoney", "GetCursorInfo", "InCombatLockdown"
}

function Client.Inspect(api)
  local result = { supported = false, reason = "BUILD_UNAVAILABLE", capabilities = {} }
  for _, name in ipairs(Client.Required) do result.capabilities[name] = type(api[name]) end
  for _, name in ipairs(Client.Optional) do result.capabilities[name] = type(api[name]) end
  result.capabilities.GetBuildInfo = type(api.GetBuildInfo)
  if type(api.GetBuildInfo) ~= "function" then return result end
  local ok, version, build, _, interface = pcall(api.GetBuildInfo)
  if not ok then return result end
  result.version, result.build, result.interface = version, tonumber(build), tonumber(interface)
  if (version ~= "3.3.5" and version ~= "3.3.5a") or
      result.build ~= 12340 or result.interface ~= 30300 then
    result.reason = "WRONG_CLIENT"
    return result
  end
  for _, name in ipairs(Client.Required) do
    if result.capabilities[name] ~= "function" then
      result.reason = "MISSING_API:" .. name
      return result
    end
  end
  result.supported, result.reason = true, "SUPPORTED_READ_ONLY"
  return result
end
