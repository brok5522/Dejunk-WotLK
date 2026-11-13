local _, Addon = ...
local Store = { VERSION = 2 }
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
local function profile(id, name) return { id=id, name=name, inclusions={}, exclusions={}, autoSell=false, autoRepair=false, options={quality={[0]=true},includeByQuality={enabled=true,scope="BOTH",qualities={poor=true,common=false,uncommon=false,rare=false,epic=false}},excludeAboveItemLevel={enabled=false,scope="BOTH",value=0,qualities={poor=true,common=true,uncommon=true,rare=true,epic=true}},excludeAbovePrice={enabled=false,scope="DESTROY",value=0,qualities={poor=true,common=true,uncommon=true,rare=true,epic=true}},excludeByEquipmentType={enabled=false,scope="BOTH",qualities={poor=true,common=true,uncommon=true,rare=true,epic=true},armor={},weapons={}},excludeEquipmentSets={enabled=true,scope="BOTH"},excludeQuestItems={enabled=true,scope="BOTH"},excludeUnboundEquipment={enabled=false,scope="BOTH",qualities={poor=true,common=true,uncommon=true,rare=true,epic=true}},includeBelowItemLevel={enabled=false,scope="BOTH",value=0,qualities={poor=true,common=false,uncommon=false,rare=false,epic=false}},includeBelowPrice={enabled=false,scope="SELL",value=0,qualities={poor=true,common=false,uncommon=false,rare=false,epic=false}},includeByEquipmentType={enabled=false,scope="BOTH",qualities={poor=true,common=false,uncommon=false,rare=false,epic=false},armor={},weapons={}}}, rules={} } end
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
  local out=profile("default","Default").options
  if type(value)~="table" then return out end
  if type(value.quality)=="table" then
    for quality,enabled in pairs(value.quality) do
      quality=tonumber(quality)
      if quality and quality>=0 and quality<=7 and quality==math.floor(quality) and type(enabled)=="boolean" then
        out.quality[quality]=enabled
      end
    end
  end
  local names={[0]="poor",[1]="common",[2]="uncommon",[3]="rare",[4]="epic"}
  for quality,name in pairs(names) do if value.quality and type(value.quality[quality])=="boolean" then out.includeByQuality.qualities[name]=value.quality[quality] end end
  for _,key in ipairs({"excludeEquipmentSets","excludeQuestItems","excludeUnboundEquipment"}) do
    if type(value[key])=="boolean" then out[key]=value[key] and {enabled=true,scope="BOTH"} or {enabled=false,scope="BOTH"} end
  end
  local legacyFilters={
    minItemLevel={key="includeBelowItemLevel",reason="JUNK"},
    maxItemLevel={key="excludeAboveItemLevel",reason="KEEP"},
    maxStackVendorPrice={key="excludeAbovePrice",reason="KEEP"}
  }
  for old,spec in pairs(legacyFilters) do
    local n=value[old]
    if type(n)=="number" and n>=0 and n<=2147483647 and n==math.floor(n) and value[spec.key]==nil then
      local all={poor=true,common=true,uncommon=true,rare=true,epic=true}
      out[spec.key]={enabled=true,scope=old=="maxStackVendorPrice" and "DESTROY" or "BOTH",value=n,qualities=all}
    end
  end
  local filterKeys={"excludeAboveItemLevel","excludeAbovePrice","excludeByEquipmentType","excludeEquipmentSets","excludeQuestItems","excludeUnboundEquipment","includeBelowItemLevel","includeBelowPrice","includeByEquipmentType","includeByQuality"}
  local qualityNames={"poor","common","uncommon","rare","epic"}
  for _,key in ipairs(filterKeys) do
    local source=value[key]
    if type(source)=="table" then
      local target=out[key]
      if type(target)~="table" then target={}; out[key]=target end
      if type(source.enabled)=="boolean" then target.enabled=source.enabled end
      if source.scope=="SELL" or source.scope=="DESTROY" or source.scope=="BOTH" then target.scope=source.scope end
      if type(source.value)=="number" and source.value>=0 and source.value<=2147483647 and source.value==math.floor(source.value) then target.value=source.value end
      if type(source.qualities)=="table" then
        target.qualities=target.qualities or {}
        for _,name in ipairs(qualityNames) do if type(source.qualities[name])=="boolean" then target.qualities[name]=source.qualities[name] end end
      end
      for _,field in ipairs({"armor","weapons"}) do
        if type(source[field])=="table" then
          target[field]={}
          for id,enabled in pairs(source[field]) do
            id=tonumber(id)
            if id and id>=0 and id<=100 and id==math.floor(id) and type(enabled)=="boolean" then target[field][id]=enabled end
          end
        end
      end
    end
  end
  return out
end
local function globalDefaults()
  return { inclusions={}, exclusions={}, minimap={hide=false}, minimapIcon={hide=false},
    safeSell=false, safeDestroy=true, merchantButton=true, autoJunkFrame=false,
    autoLootableFrame=false, chatMessages={enabled=true,detail="REDUCED"},
    itemIcons=false, itemIconStyle="SMALL", itemTooltips=true,
    keybindings={toggleMainWindow="",toggleJunkFrame="",toggleLootableFrame="",startSelling="",destroyNextItem="",addOrRemoveProfileInclusions="",addOrRemoveProfileExclusions="",addOrRemoveGlobalInclusions="",addOrRemoveGlobalExclusions=""},
    points={mainWindow={point="CENTER",relativePoint="CENTER",offsetX=0,offsetY=50},junkFrame={point="CENTER",relativePoint="CENTER",offsetX=0,offsetY=50},lootableFrame={point="CENTER",relativePoint="CENTER",offsetX=0,offsetY=50},transportFrame={point="CENTER",relativePoint="CENTER",offsetX=0,offsetY=50},merchantButton={point="TOPLEFT",relativeTo="MerchantFrame",relativePoint="TOPLEFT",offsetX=60,offsetY=-28}} }
end
local function cleanGlobal(value)
  local out=globalDefaults()
  if type(value)~="table" then return out end
  for _,key in ipairs({"inclusions","exclusions"}) do if listValid(value[key]) then out[key]=copy(value[key]) end end
  for _,key in ipairs({"safeSell","safeDestroy","merchantButton","autoJunkFrame","autoLootableFrame","itemIcons","itemTooltips"}) do
    if type(value[key])=="boolean" then out[key]=value[key] end
  end
  if value.itemIconStyle=="SMALL" or value.itemIconStyle=="LARGE" then out.itemIconStyle=value.itemIconStyle end
  if type(value.chatMessages)=="table" then
    if type(value.chatMessages.enabled)=="boolean" then out.chatMessages.enabled=value.chatMessages.enabled end
    if value.chatMessages.detail=="REDUCED" or value.chatMessages.detail=="VERBOSE" then out.chatMessages.detail=value.chatMessages.detail end
  end
  local bindings={"toggleMainWindow","toggleJunkFrame","toggleLootableFrame","startSelling","destroyNextItem","addOrRemoveProfileInclusions","addOrRemoveProfileExclusions","addOrRemoveGlobalInclusions","addOrRemoveGlobalExclusions"}
  if type(value.keybindings)=="table" then
    for _,key in ipairs(bindings) do
      local binding=value.keybindings[key]
      if type(binding)=="string" and #binding<=32 and binding:match("^[%w%-]*$") then out.keybindings[key]=binding end
    end
  end
  local anchors={TOPLEFT=true,TOP=true,TOPRIGHT=true,LEFT=true,CENTER=true,RIGHT=true,BOTTOMLEFT=true,BOTTOM=true,BOTTOMRIGHT=true}
  local points={"mainWindow","junkFrame","lootableFrame","transportFrame","merchantButton"}
  if type(value.points)=="table" then
    for _,key in ipairs(points) do
      local source,target=value.points[key],out.points[key]
      if type(source)=="table" then
        if anchors[source.point] then target.point=source.point end
        if anchors[source.relativePoint] then target.relativePoint=source.relativePoint end
        if type(source.relativeTo)=="string" and #source.relativeTo<=64 and source.relativeTo:match("^[%w_]+$") then target.relativeTo=source.relativeTo end
        for _,offset in ipairs({"offsetX","offsetY"}) do
          local number=source[offset]
          if type(number)=="number" and number==number and number>=-10000 and number<=10000 then target[offset]=number end
        end
      end
    end
  end
  local minimap=type(value.minimapIcon)=="table" and value.minimapIcon or value.minimap
  if type(minimap)=="table" and type(minimap.hide)=="boolean" then out.minimapIcon.hide=minimap.hide; out.minimap.hide=minimap.hide end
  return out
end
local function fresh()
  return { schemaVersion=Store.VERSION, global=globalDefaults(),
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
    out.autoSell=value.autoSell==true
    out.autoRepair=value.autoRepair==true
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
    elseif saved.schemaVersion==Store.VERSION or saved.schemaVersion==1 then
      mode=saved.schemaVersion==Store.VERSION and "loaded" or "migrated-v1"
      state.global=cleanGlobal(saved.global)
      if type(saved.profiles)=="table" then
        local n=0
        for id,value in pairs(saved.profiles) do
          if type(id)=="string" and #id<=40 and n<MAX_PROFILES then state.profiles[id]=cleanProfile(value,id); n=n+1 end
        end
      end
      state.profiles[DEFAULT]=cleanProfile(state.profiles[DEFAULT],DEFAULT)
      -- Phase-1 profiles used rules/options directly. Keep a full copy for
      -- recovery; rules remain serialized but no longer influence decisions.
      if saved.schemaVersion==1 then state.recovery=copy(saved) end
      if type(saved.characterProfiles)=="table" then
        for key,id in pairs(saved.characterProfiles) do
          if type(key)=="string" and #key<=96 and type(id)=="string" and state.profiles[id] then state.characterProfiles[key]=id end
        end
      end
      if type(saved.nextProfileId)=="number" and saved.nextProfileId>=1 and saved.nextProfileId<2147483648 then state.nextProfileId=math.floor(saved.nextProfileId) end
      for id in pairs(state.profiles) do local n=tonumber(id:match("^profile%-(%d+)$")); if n and n>=state.nextProfileId then state.nextProfileId=n+1 end end
    elseif saved.schemaVersion==nil then
      state.recovery=copy(saved); mode="recovered-unversioned"
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
    if type(quality)~="number" or quality<0 or quality>4 or quality~=math.floor(quality) or type(enabled)~="boolean" then return false,"INVALID_OPTION" end
    options.quality=options.quality or {}
    options.quality[quality]=enabled
    local names={[0]="poor",[1]="common",[2]="uncommon",[3]="rare",[4]="epic"}
    local name=names[quality]
    if name then
      options.includeByQuality=options.includeByQuality or {enabled=true,scope="BOTH",qualities={}}
      options.includeByQuality.qualities=options.includeByQuality.qualities or {}
      options.includeByQuality.qualities[name]=enabled
    end
  elseif key=="minItemLevel" or key=="maxItemLevel" or key=="maxStackVendorPrice" then
    if value~=nil and (type(value)~="number" or value<0 or value>2147483647 or value~=math.floor(value)) then return false,"INVALID_OPTION" end
    local target=key=="minItemLevel" and "includeBelowItemLevel" or key=="maxItemLevel" and "excludeAboveItemLevel" or "excludeAbovePrice"
    if value==nil then options[target]=nil
    else options[target]={enabled=true,scope=key=="maxStackVendorPrice" and "DESTROY" or "BOTH",value=value,qualities={poor=true,common=true,uncommon=true,rare=true,epic=true}} end
  elseif key=="excludeEquipmentSets" or key=="excludeQuestItems" or key=="excludeUnboundEquipment" then
    if type(value)=="boolean" then
      local previous=options[key]
      options[key]={enabled=value,scope="BOTH"}
      if key=="excludeUnboundEquipment" then
        options[key].qualities=type(previous)=="table" and copy(previous.qualities) or
          {poor=true,common=true,uncommon=true,rare=true,epic=true}
      end
    elseif type(value)=="table" and type(value.enabled)=="boolean" and (value.scope=="SELL" or value.scope=="DESTROY" or value.scope=="BOTH") then
      if key=="excludeUnboundEquipment" then
        if type(value.qualities)~="table" then return false,"INVALID_OPTION" end
        for _,name in ipairs({"poor","common","uncommon","rare","epic"}) do
          if value.qualities[name]~=nil and type(value.qualities[name])~="boolean" then return false,"INVALID_OPTION" end
        end
        options[key]=cleanOptions({[key]=value})[key]
      else
        options[key]={enabled=value.enabled,scope=value.scope}
      end
    else return false,"INVALID_OPTION" end
  elseif key=="autoSell" or key=="autoRepair" then
    if type(value)~="boolean" then return false,"INVALID_OPTION" end
    self.state.profiles[self:GetActiveProfileId()][key]=value
  elseif key=="excludeAboveItemLevel" or key=="excludeAbovePrice" or key=="excludeByEquipmentType" or
      key=="includeBelowItemLevel" or key=="includeBelowPrice" or key=="includeByEquipmentType" or key=="includeByQuality" then
    if type(value)~="table" or type(value.enabled)~="boolean" or
        (value.scope~="SELL" and value.scope~="DESTROY" and value.scope~="BOTH") then return false,"INVALID_OPTION" end
    if type(value.qualities)~="table" then return false,"INVALID_OPTION" end
    for _,name in ipairs({"poor","common","uncommon","rare","epic"}) do
      if value.qualities[name]~=nil and type(value.qualities[name])~="boolean" then return false,"INVALID_OPTION" end
    end
    if (key:find("ItemLevel",1,true) or key:find("Price",1,true)) and
        (type(value.value)~="number" or value.value<0 or value.value>2147483647 or value.value~=math.floor(value.value)) then
      return false,"INVALID_OPTION"
    end
    if (key=="excludeByEquipmentType" or key=="includeByEquipmentType") and
        (type(value.armor)~="table" or type(value.weapons)~="table") then return false,"INVALID_OPTION" end
    if key=="excludeByEquipmentType" or key=="includeByEquipmentType" then
      for _,field in ipairs({"armor","weapons"}) do
        for id,enabled in pairs(value[field]) do
          local numericId=tonumber(id)
          if not numericId or numericId<0 or numericId>100 or numericId~=math.floor(numericId) or type(enabled)~="boolean" then
            return false,"INVALID_OPTION"
          end
        end
      end
    end
    local checked=cleanOptions({[key]=value})[key]
    if not checked or checked.enabled~=value.enabled or checked.scope~=value.scope then return false,"INVALID_OPTION" end
    options[key]=checked
  else return false,"INVALID_OPTION" end
  self:Changed(); return true
end
function Store:SetGlobalOption(key,value)
  if self.readonly then return false,"READ_ONLY" end
  local booleans={safeSell=true,safeDestroy=true,merchantButton=true,autoJunkFrame=true,autoLootableFrame=true,itemIcons=true,itemTooltips=true}
  if booleans[key] and type(value)=="boolean" then self.state.global[key]=value
  elseif key=="itemIconStyle" and (value=="SMALL" or value=="LARGE") then self.state.global[key]=value
  elseif key=="chatMessages" and type(value)=="table" then
    local current=self.state.global.chatMessages
    if value.enabled~=nil and type(value.enabled)~="boolean" then return false,"INVALID_OPTION" end
    if value.detail~=nil and value.detail~="REDUCED" and value.detail~="VERBOSE" then return false,"INVALID_OPTION" end
    if value.enabled==nil and value.detail==nil then return false,"INVALID_OPTION" end
    if value.enabled~=nil then current.enabled=value.enabled end
    if value.detail~=nil then current.detail=value.detail end
  elseif key=="minimapIcon" and type(value)=="table" and type(value.hide)=="boolean" then
    self.state.global.minimapIcon.hide=value.hide; self.state.global.minimap.hide=value.hide
  elseif key=="keybindings" and type(value)=="table" then
    local names={toggleMainWindow=true,toggleJunkFrame=true,toggleLootableFrame=true,startSelling=true,destroyNextItem=true,
      addOrRemoveProfileInclusions=true,addOrRemoveProfileExclusions=true,addOrRemoveGlobalInclusions=true,addOrRemoveGlobalExclusions=true}
    local merged=copy(self.state.global.keybindings)
    for name,binding in pairs(value) do
      if not names[name] or type(binding)~="string" or #binding>32 or not binding:match("^[%w%-]*$") then return false,"INVALID_OPTION" end
      merged[name]=binding
    end
    self.state.global.keybindings=merged
  elseif key=="points" and type(value)=="table" then
    local names={mainWindow=true,junkFrame=true,lootableFrame=true,transportFrame=true,merchantButton=true}
    local anchors={TOPLEFT=true,TOP=true,TOPRIGHT=true,LEFT=true,CENTER=true,RIGHT=true,BOTTOMLEFT=true,BOTTOM=true,BOTTOMRIGHT=true}
    local merged=copy(self.state.global.points)
    for name,point in pairs(value) do
      if not names[name] or type(point)~="table" or not anchors[point.point] or not anchors[point.relativePoint] or
          type(point.offsetX)~="number" or type(point.offsetY)~="number" or point.offsetX~=point.offsetX or point.offsetY~=point.offsetY or
          math.abs(point.offsetX)>10000 or math.abs(point.offsetY)>10000 or
          (point.relativeTo~=nil and (type(point.relativeTo)~="string" or #point.relativeTo>64 or not point.relativeTo:match("^[%w_]+$"))) then return false,"INVALID_OPTION" end
      merged[name]=copy(point)
    end
    self.state.global.points=merged
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
  -- Reset settings and lists while preserving the profile identity/name.
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
