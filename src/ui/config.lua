local _, Addon = ...
local Config = {}
Addon.Config = Config

local function count(tableValue)
  local total=0
  for _ in pairs(type(tableValue)=="table" and tableValue or {}) do total=total+1 end
  return total
end

function Config.Summary(store)
  if not store then return "Profile store unavailable." end
  local profile=store:GetActiveProfile()
  local options=profile.options or {}
  local quality=options.quality or {}
  return table.concat({
    "Active profile: "..tostring(profile.name).." ("..tostring(profile.id)..")",
    "Poor quality rule: "..(quality[0] and "ON" or "OFF"),
    "Item level minimum: "..tostring(options.minItemLevel or "off"),
    "Item level maximum: "..tostring(options.maxItemLevel or "off"),
    "Maximum stack vendor value (copper): "..tostring(options.maxStackVendorPrice or "off"),
    "Custom rule groups: "..tostring(#(profile.rules or {})),
    "Profile inclusions/exclusions: "..count(profile.inclusions).."/"..count(profile.exclusions),
  },"\n")
end

function Config.ToggleQuality(store,quality)
  if type(quality)~="number" or quality<0 or quality>7 or quality~=math.floor(quality) then
    return false,"INVALID_OPTION"
  end
  local enabled=not (store:GetActiveProfile().options.quality or {})[quality]
  local ok,reason=store:SetOption("quality",{quality=quality,enabled=enabled})
  return ok,reason,enabled
end

function Config.ListProfiles(store)
  if not store then return nil,"STORE_UNAVAILABLE" end
  local state=store:GetState()
  local active=store:GetActiveProfileId()
  local profiles={}
  for id,value in pairs(state.profiles or {}) do
    profiles[#profiles+1]={id=id,name=value.name or id,active=id==active}
  end
  table.sort(profiles,function(a,b) return a.id<b.id end)
  return profiles
end

function Config.CreateProfile(store,name)
  if not store then return nil,"STORE_UNAVAILABLE" end
  return store:CreateProfile(name)
end

function Config.DuplicateProfile(store,name)
  if not store then return nil,"STORE_UNAVAILABLE" end
  return store:CreateProfile(name,store:GetActiveProfileId())
end

function Config.RenameActiveProfile(store,name)
  if not store then return false,"STORE_UNAVAILABLE" end
  return store:RenameProfile(store:GetActiveProfileId(),name)
end

function Config.ResetActiveProfile(store)
  if not store then return false,"STORE_UNAVAILABLE" end
  return store:ResetProfile(store:GetActiveProfileId())
end

function Config.DeleteActiveProfile(store)
  if not store then return false,"STORE_UNAVAILABLE" end
  return store:DeleteProfile(store:GetActiveProfileId())
end

function Config.SwitchProfile(store,id)
  if not store then return false,"STORE_UNAVAILABLE" end
  if type(id)~="string" then return false,"INVALID_PROFILE" end
  return store:SwitchProfile(id)
end

function Config.ListItems(store,scope,kind)
  if not store then return nil,"STORE_UNAVAILABLE" end
  return store:ExportList(scope,kind)
end

function Config.EditItem(store,scope,kind,itemId,present)
  if not store then return false,"STORE_UNAVAILABLE" end
  return store:EditList(scope,kind,itemId,present)
end

function Config.ListRules(store)
  if not store then return nil,"STORE_UNAVAILABLE" end
  return store:GetActiveProfile().rules or {}
end

function Config.AddRule(store,group)
  if not store then return false,"STORE_UNAVAILABLE" end
  return store:AddRule(group)
end

function Config.RemoveRule(store,id)
  if not store then return false,"STORE_UNAVAILABLE" end
  return store:RemoveRule(id)
end

function Config.SetOption(store,key,value)
  if not store then return false,"STORE_UNAVAILABLE" end
  return store:SetOption(key,value)
end

function Config.GetOptions(store)
  if not store then return nil,"STORE_UNAVAILABLE" end
  return store:GetActiveProfile().options or {}
end

function Config.FilterItemIds(raw,query,resolveName)
  raw=type(raw)=="string" and raw or ""
  query=type(query)=="string" and query:lower() or ""
  local result={}
  for id in raw:gmatch("%d+") do
    local name
    if type(resolveName)=="function" then
      local ok,value=pcall(resolveName,id)
      if ok and type(value)=="string" then name=value end
    end
    if query=="" or id:find(query,1,true) or (name and name:lower():find(query,1,true)) then
      result[#result+1]={id=id,name=name}
    end
  end
  return result
end

return Config
