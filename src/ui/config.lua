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
    "Poor quality rule: "..((options.includeByQuality and options.includeByQuality.qualities and options.includeByQuality.qualities.poor) and "ON" or (quality[0] and "ON" or "OFF")),
    "Profile inclusions/exclusions: "..count(profile.inclusions).."/"..count(profile.exclusions),
  },"\n")
end

function Config.ToggleQuality(store,quality)
  if type(quality)~="number" or quality<0 or quality>4 or quality~=math.floor(quality) then
    return false,"INVALID_OPTION"
  end
  local enabled=not (store:GetActiveProfile().options.quality or {})[quality]
  local ok,reason=store:SetOption("quality",{quality=quality,enabled=enabled})
  return ok,reason,enabled
end

function Config.SetFilter(store,key,option)
  if not store then return false,"STORE_UNAVAILABLE" end
  return store:SetOption(key,option)
end
function Config.SetGlobalOption(store,key,value)
  if not store then return false,"STORE_UNAVAILABLE" end
  return store:SetGlobalOption(key,value)
end
function Config.GetGlobalOptions(store)
  if not store then return nil,"STORE_UNAVAILABLE" end
  return store:GetState().global or {}
end

function Config.GetQualityNames()
  return {"poor","common","uncommon","rare","epic"}
end

function Config.ListProfiles(store)
  if not store then return nil,"STORE_UNAVAILABLE" end
  local state=store:GetState()
  local active=store:GetActiveProfileId()
  local profiles={}
  for id,value in pairs(state.profiles or {}) do
    profiles[#profiles+1]={id=id,name=value.name or id,active=id==active,autoSell=value.autoSell==true,
      numInclusions=count(value.inclusions),numExclusions=count(value.exclusions)}
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

function Config.DuplicateProfileFrom(store,id,name)
  if not store then return nil,"STORE_UNAVAILABLE" end
  return store:CreateProfile(name,id)
end

function Config.RenameProfile(store,id,name)
  if not store then return false,"STORE_UNAVAILABLE" end
  return store:RenameProfile(id,name)
end

function Config.ResetProfile(store,id)
  if not store then return false,"STORE_UNAVAILABLE" end
  return store:ResetProfile(id)
end

function Config.DeleteProfile(store,id)
  if not store then return false,"STORE_UNAVAILABLE" end
  return store:DeleteProfile(id)
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
  local profile=store:GetActiveProfile()
  local options=profile.options or {}
  options.autoSell=profile.autoSell==true
  options.autoRepair=profile.autoRepair==true
  return options
end

function Config.FilterItemIds(raw,query,resolveName)
  raw=type(raw)=="string" and raw or ""
  query=type(query)=="string" and query:lower() or ""
  local result,seen={},{}
  for id in raw:gmatch("%d+") do
    if not seen[id] then
      seen[id]=true
      local name
      if type(resolveName)=="function" then
        local ok,value=pcall(resolveName,id)
        if ok and type(value)=="string" then name=value end
      end
      -- Names are optional while client metadata is still loading. Keep an item
      -- only when its ID matches until a name can actually be resolved.
      if query=="" or id:find(query,1,true) or (name and name:lower():find(query,1,true)) then
        result[#result+1]={id=id,name=name}
      end
    end
  end
  return result
end

-- The upstream Lists screen sorts parsed items by quality, then name. The
-- serialized list remains numeric for stable plain-text transport; only the
-- presentation model uses this comparator. Unknown metadata sorts last.
function Config.SortListItems(items,resolveItem)
  local result,seen={},{}
  for _,entry in ipairs(type(items)=="table" and items or {}) do
    local id=type(entry)=="table" and tostring(entry.id or "") or tostring(entry)
    if id:match("^%d+$") and not seen[id] then
      seen[id]=true
      local item=type(entry)=="table" and entry or nil
      if (not item or item.quality==nil or item.name==nil) and type(resolveItem)=="function" then
        local ok,value=pcall(resolveItem,id)
        if ok and type(value)=="table" then item=value end
      end
      result[#result+1]={id=id,name=item and type(item.name)=="string" and item.name or nil,
        quality=item and type(item.quality)=="number" and item.quality or nil}
    end
  end
  table.sort(result,function(a,b)
    local aq,bq=a.quality or math.huge,b.quality or math.huge
    if aq~=bq then return aq<bq end
    local an,bn=(a.name or ""):lower(),(b.name or ""):lower()
    if an~=bn then return an<bn end
    return tonumber(a.id)<tonumber(b.id)
  end)
  return result
end

function Config.PreviewListImport(store,scope,kind,text)
  if not store then return nil,"STORE_UNAVAILABLE" end
  return store:ImportPreview(scope,kind,text)
end

function Config.CommitListImport(store,preview)
  if not store then return false,"STORE_UNAVAILABLE" end
  return store:CommitImport(preview)
end

return Config
