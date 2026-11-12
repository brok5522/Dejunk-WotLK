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

function Config.SwitchProfile(store,id)
  if not store then return false,"STORE_UNAVAILABLE" end
  if type(id)~="string" then return false,"INVALID_PROFILE" end
  return store:SwitchProfile(id)
end

return Config
