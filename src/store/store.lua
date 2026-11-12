local _, Addon = ...
local Store = { VERSION = 1 }
Addon.Store = Store
local DEFAULT, MAX_PROFILES, MAX_IDS, MAX_IMPORT = "default", 50, 5000, 65536
local function copy(value) return Addon.Copy(value) end
local function validId(value)
  local id = tonumber(value)
  if id and id == math.floor(id) and id > 0 and id < 2147483648 then return id end
end
local function listValid(value)
  if type(value) ~= "table" then return false end
  local count = 0
  for id, enabled in pairs(value) do
    if not validId(id) or enabled ~= true then return false end
    count = count + 1; if count > MAX_IDS then return false end
  end
  return true
end
local function profile(id, name) return { id=id, name=name, inclusions={}, exclusions={}, options={quality={[0]=true}}, rules={} } end
local RULE_FIELDS = { itemId=true, quality=true, itemLevel=true, unitVendorPrice=true, count=true }
local function cleanRules(value)
  local result={}; if type(value)~="table" then return result end
  for _,group in ipairs(value) do
    if #result>=100 then break end
    if type(group)=="table" and type(group.id)=="string" and #group.id>0 and #group.id<=32 and
        (group.scope=="SELL" or group.scope=="DESTROY" or group.scope=="BOTH") and
        (group.result=="JUNK" or group.result=="KEEP") and
        (group.match=="ALL" or group.match=="ANY") and type(group.predicates)=="table" and
        #group.predicates>0 and #group.predicates<=10 then
      local out={id=group.id,scope=group.scope,result=group.result,match=group.match,predicates={}}
      local valid=true
      for _,predicate in ipairs(group.predicates) do
        local field=type(predicate)=="table" and predicate.field
        local op=type(predicate)=="table" and predicate.op
        local val=type(predicate)=="table" and predicate.value
        if not RULE_FIELDS[field] or (op~="EQ" and op~="LT" and op~="GT") or
            type(val)~="number" or val<0 or val>2147483647 or val~=math.floor(val) or
            (field=="quality" and val>7) then valid=false; break end
        out.predicates[#out.predicates+1]={field=field,op=op,value=val}
      end
      if valid then result[#result+1]=out end
    end
  end
  return result
end
local function cleanOptions(value)
  -- Match upstream's default includeByQuality rule: Poor items are junk for
  -- both SELL and DESTROY unless the user explicitly disabled quality 0.
  local out={quality={[0]=true}}
  if type(value)~="table" then return out end
  if type(value.quality)=="table" then
    for quality,enabled in pairs(value.quality) do
      quality=tonumber(quality)
      if quality and quality>=0 and quality<=7 and quality==math.floor(quality) and type(enabled)=="boolean" then
        out.quality[quality]=enabled
      end
    end
  end
  for _,key in ipairs({"minItemLevel","maxItemLevel","maxStackVendorPrice"}) do
    local n=value[key]
    if type(n)=="number" and n>=0 and n<=2147483647 and n==math.floor(n) then out[key]=n end
  end
  return out
end
local function fresh()
  return { schemaVersion=Store.VERSION, global={inclusions={},exclusions={},minimap={hide=false}},
    profiles={[DEFAULT]=profile(DEFAULT,"Default")}, characterProfiles={}, nextProfileId=1 }
end
local function cleanName(name)
  if type(name) ~= "string" then return nil end
  name=name:gsub("[%c|]",""):gsub("^%s+",""):gsub("%s+$","")
  if #name<1 or #name>32 then return nil end
  return name
end
local function cleanProfile(value,id)
  local name=type(value)=="table" and cleanName(value.name) or nil
  local out=profile(id,name or (id==DEFAULT and "Default" or "Profile"))
  if type(value)=="table" then
    if listValid(value.inclusions) then out.inclusions=copy(value.inclusions) end
    if listValid(value.exclusions) then out.exclusions=copy(value.exclusions) end
    out.options=cleanOptions(value.options)
    out.rules=cleanRules(value.rules)
  end
  if id==DEFAULT then out.name="Default" end
  return out
end
function Store.Initialize(saved,character)
  local state,mode,readonly=fresh(),"created",false
  if type(saved)=="table" then
    if type(saved.schemaVersion)=="number" and saved.schemaVersion>Store.VERSION then
      state,mode,readonly=fresh(),"future-readonly",true
      state.recovery=copy(saved)
    elseif saved.schemaVersion==Store.VERSION then
      mode="loaded"
      if type(saved.global)=="table" then
        for _,k in ipairs({"inclusions","exclusions"}) do if listValid(saved.global[k]) then state.global[k]=copy(saved.global[k]) end end
        if type(saved.global.minimap)=="table" and type(saved.global.minimap.hide)=="boolean" then state.global.minimap.hide=saved.global.minimap.hide end
      end
      if type(saved.profiles)=="table" then
        local n=0
        for id,value in pairs(saved.profiles) do
          if type(id)=="string" and #id<=40 and n<MAX_PROFILES then state.profiles[id]=cleanProfile(value,id); n=n+1 end
        end
      end
      state.profiles[DEFAULT]=cleanProfile(state.profiles[DEFAULT],DEFAULT)
      if type(saved.characterProfiles)=="table" then
        for key,id in pairs(saved.characterProfiles) do
          if type(key)=="string" and #key<=96 and type(id)=="string" and state.profiles[id] then state.characterProfiles[key]=id end
        end
      end
      if type(saved.nextProfileId)=="number" and saved.nextProfileId>=1 and saved.nextProfileId<2147483648 then state.nextProfileId=math.floor(saved.nextProfileId) end
      for id in pairs(state.profiles) do local n=tonumber(id:match("^profile%-(%d+)$")); if n and n>=state.nextProfileId then state.nextProfileId=n+1 end end
    else state.recovery=copy(saved); mode="recovered-invalid-schema" end
  end
  if character and not readonly and not state.characterProfiles[character] then state.characterProfiles[character]=DEFAULT end
  return setmetatable({state=state,character=character,readonly=readonly,mode=mode,revision=0,listeners={}}, {__index=Store})
end
function Store:OnChange(fn) self.listeners[#self.listeners+1]=fn end
function Store:Changed()
  if self.readonly then return false end
  self.revision=self.revision+1; local snapshot=copy(self.state)
  for _,fn in ipairs(self.listeners) do pcall(fn,snapshot) end
  return true
end
function Store:GetState() return copy(self.state) end
function Store:GetRevision() return self.revision end
function Store:GetActiveProfileId()
  local id=self.character and self.state.characterProfiles[self.character]
  return self.state.profiles[id] and id or DEFAULT
end
function Store:GetActiveProfile() return copy(self.state.profiles[self:GetActiveProfileId()]) end
function Store:AssignCharacter(key,id)
  if self.readonly or type(key)~="string" or #key>96 or not self.state.profiles[id] then return false end
  self.state.characterProfiles[key]=id; self:Changed(); return true
end
function Store:SwitchProfile(id) return self:AssignCharacter(self.character,id) end
function Store:CreateProfile(name,source)
  name=cleanName(name)
  if self.readonly or not name or source and not self.state.profiles[source] then return nil,"INVALID_PROFILE" end
  local count=0; for _ in pairs(self.state.profiles) do count=count+1 end; if count>=MAX_PROFILES then return nil,"PROFILE_LIMIT" end
  local id="profile-"..self.state.nextProfileId; self.state.nextProfileId=self.state.nextProfileId+1
  local out=source and cleanProfile(self.state.profiles[source],id) or profile(id,name); out.name=name
  self.state.profiles[id]=out
  if self.character then self.state.characterProfiles[self.character]=id end
  self:Changed(); return id
end
function Store:RenameProfile(id,name)
  name=cleanName(name); if self.readonly or id==DEFAULT or not name or not self.state.profiles[id] then return false end
  self.state.profiles[id].name=name; self:Changed(); return true
end
function Store:SetOption(key,value)
  if self.readonly then return false,"READ_ONLY" end
  local options=self.state.profiles[self:GetActiveProfileId()].options
  if key=="quality" then
    if type(value)~="table" then return false,"INVALID_OPTION" end
    local quality,enabled=value.quality,value.enabled
    if type(quality)~="number" or quality<0 or quality>7 or quality~=math.floor(quality) or type(enabled)~="boolean" then return false,"INVALID_OPTION" end
    options.quality[quality]=enabled
  elseif key=="minItemLevel" or key=="maxItemLevel" or key=="maxStackVendorPrice" then
    if value~=nil and (type(value)~="number" or value<0 or value>2147483647 or value~=math.floor(value)) then return false,"INVALID_OPTION" end
    options[key]=value
  else return false,"INVALID_OPTION" end
  self:Changed(); return true
end
function Store:AddRule(group)
  if self.readonly then return false,"READ_ONLY" end
  local profile=self.state.profiles[self:GetActiveProfileId()]
  for _,rule in ipairs(profile.rules) do if rule.id==group.id then return false,"DUPLICATE_RULE" end end
  local clean=cleanRules({group})[1]
  if not clean then return false,"INVALID_RULE" end
  if #profile.rules>=100 then return false,"RULE_LIMIT" end
  profile.rules[#profile.rules+1]=clean; self:Changed(); return true
end
function Store:RemoveRule(id)
  if self.readonly then return false,"READ_ONLY" end
  local profile=self.state.profiles[self:GetActiveProfileId()]
  for index,rule in ipairs(profile.rules) do
    if rule.id==id then table.remove(profile.rules,index); self:Changed(); return true end
  end
  return false,"UNKNOWN_RULE"
end
function Store:ResetProfile(id)
  if self.readonly or id==DEFAULT or not self.state.profiles[id] then return false end
  self.state.profiles[id]=profile(id,self.state.profiles[id].name); self:Changed(); return true
end
function Store:DeleteProfile(id)
  if self.readonly or id==DEFAULT or not self.state.profiles[id] then return false end
  self.state.profiles[id]=nil
  for key,value in pairs(self.state.characterProfiles) do if value==id then self.state.characterProfiles[key]=DEFAULT end end
  self:Changed(); return true
end
function Store:EditList(scope,kind,raw,present)
  if self.readonly or (kind~="inclusions" and kind~="exclusions") then return false,"INVALID_LIST" end
  local list=scope=="global" and self.state.global[kind] or scope=="profile" and self.state.profiles[self:GetActiveProfileId()][kind]
  local id=validId(raw); if not list then return false,"INVALID_SCOPE" end; if not id then return false,"INVALID_ITEM_ID" end
  if present then
    if list[id] then return false,"ALREADY_PRESENT" end
    local n=0; for _ in pairs(list) do n=n+1 end; if n>=MAX_IDS then return false,"LIST_LIMIT" end
    list[id]=true
  else if not list[id] then return false,"NOT_PRESENT" end; list[id]=nil end
  self:Changed(); return true
end
function Store:ImportPreview(scope,kind,text)
  if self.readonly or type(text)~="string" or #text>MAX_IMPORT then return nil,"IMPORT_LIMIT" end
  if kind~="inclusions" and kind~="exclusions" then return nil,"INVALID_LIST" end
  local current=scope=="global" and self.state.global[kind] or scope=="profile" and self.state.profiles[self:GetActiveProfileId()][kind]
  if not current then return nil,"INVALID_SCOPE" end
  if text:gsub("%d+",""):find("[^%s,;]+") then return nil,"INVALID_IMPORT_TEXT" end
  local seen,ids={},{}
  for token in text:gmatch("%d+") do local id=validId(token); if not id then return nil,"INVALID_ITEM_ID" end; if not seen[id] then seen[id]=true; ids[#ids+1]=id end; if #ids>MAX_IDS then return nil,"LIST_LIMIT" end end
  local result={scope=scope,kind=kind,revision=self.revision,add={},existing={}}
  for _,id in ipairs(ids) do local target=current[id] and result.existing or result.add; target[#target+1]=id end
  return result
end
function Store:CommitImport(preview)
  if self.readonly or type(preview)~="table" or preview.revision~=self.revision then return false,"STALE_PREVIEW" end
  local kind,scope=preview.kind,preview.scope
  if (kind~="inclusions" and kind~="exclusions") or (scope~="global" and scope~="profile") then return false,"INVALID_LIST" end
  local current=scope=="global" and self.state.global[kind] or self.state.profiles[self:GetActiveProfileId()][kind]
  if not current then return false,"INVALID_SCOPE" end
  local nextList=copy(current)
  for _,raw in ipairs(preview.add) do
    local id=validId(raw); if not id then return false,"INVALID_ITEM_ID" end
    if not nextList[id] then local n=0; for _ in pairs(nextList) do n=n+1 end; if n>=MAX_IDS then return false,"LIST_LIMIT" end; nextList[id]=true end
  end
  if scope=="global" then self.state.global[kind]=nextList else self.state.profiles[self:GetActiveProfileId()][kind]=nextList end
  self:Changed(); return true
end
function Store:ExportList(scope,kind)
  if kind~="inclusions" and kind~="exclusions" then return nil end
  local list=scope=="global" and self.state.global[kind] or scope=="profile" and self.state.profiles[self:GetActiveProfileId()][kind]
  if not list then return nil end
  local ids={}; for id in pairs(list) do ids[#ids+1]=tonumber(id) end; table.sort(ids)
  for i,id in ipairs(ids) do ids[i]=tostring(id) end; return table.concat(ids,"\n")
end
function Store:Serialize() if self.readonly then return nil,"FUTURE_SCHEMA_READ_ONLY" end; return copy(self.state) end
