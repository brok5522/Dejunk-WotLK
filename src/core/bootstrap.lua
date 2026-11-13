local _, Addon = ...

-- Keep read-only preview functional if an older or partial installation omits
-- the two optional modules. The TOC still loads the canonical modules first;
-- these compact fallbacks are used only when their registrations are absent.
if type(Addon.Rules) ~= "table" or type(Addon.Rules.Evaluate) ~= "function" then
  local Rules = {}
  Addon.Rules = Rules
  local function unknown(value) return value == nil or value == Addon.UNKNOWN end
  local function result(kind, reason, action, ruleId)
    return { result=kind, reasonCode=reason, action=action, ruleId=ruleId }
  end
  local function junk(action, reason, item, ruleId)
    if action == "SELL" then
      if unknown(item.refundable) then return result("UNKNOWN", "REFUND_UNKNOWN", action, ruleId) end
      if item.refundable then return result("KEEP", "REFUNDABLE", action, ruleId) end
      if unknown(item.unitVendorPrice) then return result("UNKNOWN", "PRICE_UNKNOWN", action, ruleId) end
      if item.unitVendorPrice <= 0 then return result("KEEP", "NO_VENDOR_VALUE", action, ruleId) end
    end
    return result("JUNK", reason, action, ruleId)
  end
  local function applies(option,action)
    return type(option)=="table" and option.enabled==true and (option.scope=="BOTH" or option.scope==action)
  end
  local function selectedQuality(option,quality)
    local names={[0]="poor",[1]="common",[2]="uncommon",[3]="rare",[4]="epic"}
    return names[quality]~=nil and type(option.qualities)=="table" and option.qualities[names[quality]]==true
  end
  local function equipment(item)
    return type(item.equipLoc)=="string" and item.equipLoc~=""
  end
  local function selectedEquipmentType(item,option)
    if not equipment(item) then return false end
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
  function Rules.Evaluate(item, action, settings)
    settings=settings or {}
    if action ~= "SELL" and action ~= "DESTROY" then return result("UNKNOWN","INVALID_ACTION",action) end
    if type(item) ~= "table" or item.state == "UNKNOWN" then return result("UNKNOWN","ITEM_UNKNOWN",action) end
    if item.state == "EMPTY" then return result("KEEP","EMPTY_SLOT",action) end
    if item.state ~= "OCCUPIED" then return result("UNKNOWN","ITEM_UNKNOWN",action) end
    if type(item.itemId)~="number" or type(item.count)~="number" or item.count<1 or item.metadata~="known" then
      return result("UNKNOWN","METADATA_UNKNOWN",action)
    end
    if unknown(item.locked) then return result("UNKNOWN","LOCK_UNKNOWN",action) end
    if item.locked then return result("KEEP","LOCKED",action) end
    if item.quality==5 or item.quality==7 then return result("KEEP","LEGENDARY_OR_HEIRLOOM",action) end
    local profile,global=settings.profile or {},settings.global or {}
    local options=profile.options or {}
    local excludeLevel=options.excludeAboveItemLevel
    if applies(excludeLevel,action) and equipment(item) and selectedQuality(excludeLevel,item.quality) then
      if type(excludeLevel.value)~="number" or type(item.itemLevel)~="number" then return result("UNKNOWN","ITEM_LEVEL_UNKNOWN",action) end
      if item.itemLevel>excludeLevel.value then return result("KEEP","ABOVE_MAX_ITEM_LEVEL",action) end
    end
    local excludePrice=options.excludeAbovePrice
    if applies(excludePrice,action) and selectedQuality(excludePrice,item.quality) then
      if type(excludePrice.value)~="number" or type(item.unitVendorPrice)~="number" then return result("UNKNOWN","PRICE_UNKNOWN",action) end
      if item.unitVendorPrice>0 and item.unitVendorPrice*item.count>excludePrice.value then return result("KEEP","ABOVE_MAX_STACK_PRICE",action) end
    end
    if profile.exclusions and profile.exclusions[item.itemId] then return result("KEEP","PROFILE_EXCLUSION",action) end
    if profile.inclusions and profile.inclusions[item.itemId] then return junk(action,"PROFILE_INCLUSION",item) end
    if global.exclusions and global.exclusions[item.itemId] then return result("KEEP","GLOBAL_EXCLUSION",action) end
    if global.inclusions and global.inclusions[item.itemId] then return junk(action,"GLOBAL_INCLUSION",item) end
    local setOption=options.excludeEquipmentSets
    if setOption==true then setOption={enabled=true,scope="BOTH"} end
    if applies(setOption,action) then
      if unknown(item.inEquipmentSet) then return result("UNKNOWN","EQUIPMENT_SET_UNKNOWN",action) end
      if item.inEquipmentSet then return result("KEEP","EQUIPMENT_SET_ITEM",action) end
    end
    local unboundOption=options.excludeUnboundEquipment
    if unboundOption==true then unboundOption={enabled=true,scope="BOTH",qualities={poor=true,common=true,uncommon=true,rare=true,epic=true}} end
    if applies(unboundOption,action) and equipment(item) and selectedQuality(unboundOption,item.quality) then
      if unknown(item.bound) then return result("UNKNOWN","BINDING_UNKNOWN",action) end
      if item.bound==false then return result("KEEP","UNBOUND_EQUIPMENT",action) end
    end
    local excludeType=options.excludeByEquipmentType
    if applies(excludeType,action) and selectedQuality(excludeType,item.quality) then
      local selected=selectedEquipmentType(item,excludeType)
      if selected==nil then return result("UNKNOWN","EQUIPMENT_TYPE_UNKNOWN",action) end
      if selected then return result("KEEP","EXCLUDED_EQUIPMENT_TYPE",action) end
    end
    local quest=options.excludeQuestItems
    if quest==true then quest={enabled=true,scope="BOTH"} end
    if applies(quest,action) then
      if item.classId==12 or item.quest==true then return result("KEEP","QUEST_ITEM",action) end
      if item.classId==nil and unknown(item.quest) then return result("UNKNOWN","QUEST_UNKNOWN",action) end
    end
    local quality=options.includeByQuality
    if quality==nil and options.quality then quality={enabled=true,scope="BOTH",qualities={poor=options.quality[0],common=options.quality[1],uncommon=options.quality[2],rare=options.quality[3],epic=options.quality[4]}} end
    if applies(quality,action) and selectedQuality(quality,item.quality) then return junk(action,"QUALITY",item) end
    local includeLevel=options.includeBelowItemLevel
    if applies(includeLevel,action) and equipment(item) and selectedQuality(includeLevel,item.quality) then
      if type(includeLevel.value)~="number" or type(item.itemLevel)~="number" then return result("UNKNOWN","ITEM_LEVEL_UNKNOWN",action) end
      if item.itemLevel<includeLevel.value then return junk(action,"BELOW_MIN_ITEM_LEVEL",item) end
    end
    local includePrice=options.includeBelowPrice
    if applies(includePrice,action) and selectedQuality(includePrice,item.quality) then
      if type(includePrice.value)~="number" or type(item.unitVendorPrice)~="number" then return result("UNKNOWN","PRICE_UNKNOWN",action) end
      if item.unitVendorPrice>0 and item.unitVendorPrice*item.count<includePrice.value then return junk(action,"BELOW_MIN_STACK_PRICE",item) end
    end
    local includeType=options.includeByEquipmentType
    if applies(includeType,action) and selectedQuality(includeType,item.quality) then
      local selected=selectedEquipmentType(item,includeType)
      if selected==nil then return result("UNKNOWN","EQUIPMENT_TYPE_UNKNOWN",action) end
      if selected then return junk(action,"INCLUDED_EQUIPMENT_TYPE",item) end
    end
    return result("KEEP","NO_RULE_MATCH",action)
  end
end

if type(Addon.Preview) ~= "table" or type(Addon.Preview.EvaluateSnapshot) ~= "function" then
  Addon.Preview = { EvaluateSnapshot=function(snapshot, settings, action)
    local rows={}
    if type(snapshot)~="table" or snapshot.valid~=true or snapshot.generation~=snapshot.currentGeneration then
      return rows,"SNAPSHOT_INVALID"
    end
    for key,item in pairs(snapshot.items or {}) do
      local row=Addon.Rules.Evaluate(item,action,settings)
      row.slotKey=key; row.bag,row.slot=item.bag,item.slot
      row.itemId,row.count,row.link=item.itemId,item.count,item.link
      rows[#rows+1]=row
    end
    table.sort(rows,function(a,b) if a.bag~=b.bag then return (a.bag or -1)<(b.bag or -1) end return (a.slot or -1)<(b.slot or -1) end)
    return rows
  end }
end

-- Retain report rendering when an older installation has the preview evaluator
-- but predates the formatted-report helper.
if type(Addon.Preview.Format) ~= "function" then
  function Addon.Preview.Format(rows,action)
    action=type(action)=="string" and action:upper() or ""
    if action~="SELL" and action~="DESTROY" then return nil,"INVALID_ACTION" end
    if type(rows)~="table" then return nil,"INVALID_PREVIEW" end
    local counts={JUNK=0,KEEP=0,UNKNOWN=0}
    local lines={"READ-ONLY "..action.." PREVIEW","No action will be taken.",""}
    for _,row in ipairs(rows) do
      local result=counts[row.result]~=nil and row.result or "UNKNOWN"
      counts[result]=counts[result]+1
      lines[#lines+1]=result.." | bag "..tostring(row.bag or "?").." slot "..tostring(row.slot or "?")..
        " | item "..tostring(row.itemId or "unknown").." x"..tostring(row.count or 1)..
        " | "..tostring(row.reasonCode or "UNKNOWN")
    end
    lines[#lines+1]=""
    lines[#lines+1]="Eligible: "..counts.JUNK.." | Keep: "..counts.KEEP.." | Unknown: "..counts.UNKNOWN
    return table.concat(lines,"\n"),counts
  end
end

-- The configuration model also has a bootstrap fallback for partial installs.
if type(Addon.Config) ~= "table" or type(Addon.Config.Summary) ~= "function" or
    type(Addon.Config.ToggleQuality) ~= "function" then
  Addon.Config={}
  local function count(values)
    local total=0
    for _ in pairs(type(values)=="table" and values or {}) do total=total+1 end
    return total
  end
  function Addon.Config.Summary(store)
    if not store then return "Profile store unavailable." end
    local profile=store:GetActiveProfile(); local options=profile.options or {}; local quality=options.quality or {}
    return table.concat({"Active profile: "..tostring(profile.name).." ("..tostring(profile.id)..")",
      "Poor quality rule: "..(quality[0] and "ON" or "OFF"),
      "Profile inclusions/exclusions: "..count(profile.inclusions).."/"..count(profile.exclusions)},"\n")
  end
  function Addon.Config.ToggleQuality(store,quality)
    if type(quality)~="number" or quality<0 or quality>4 or quality~=math.floor(quality) then return false,"INVALID_OPTION" end
    local options=store:GetActiveProfile().options or {}
    local enabled=not (options.quality or {})[quality]
    local ok,reason=store:SetOption("quality",{quality=quality,enabled=enabled})
    return ok,reason,enabled
  end
  function Addon.Config.ListProfiles(store)
    if not store then return nil,"STORE_UNAVAILABLE" end
    local state=store:GetState(); local active=store:GetActiveProfileId(); local profiles={}
    for id,value in pairs(state.profiles or {}) do profiles[#profiles+1]={id=id,name=value.name or id,active=id==active} end
    table.sort(profiles,function(a,b) return a.id<b.id end)
    return profiles
  end
  function Addon.Config.CreateProfile(store,name)
    if not store then return nil,"STORE_UNAVAILABLE" end
    return store:CreateProfile(name)
  end
  function Addon.Config.DuplicateProfile(store,name)
    if not store then return nil,"STORE_UNAVAILABLE" end
    return store:CreateProfile(name,store:GetActiveProfileId())
  end
  function Addon.Config.RenameActiveProfile(store,name)
    if not store then return false,"STORE_UNAVAILABLE" end
    return store:RenameProfile(store:GetActiveProfileId(),name)
  end
  function Addon.Config.ResetActiveProfile(store)
    if not store then return false,"STORE_UNAVAILABLE" end
    return store:ResetProfile(store:GetActiveProfileId())
  end
  function Addon.Config.DeleteActiveProfile(store)
    if not store then return false,"STORE_UNAVAILABLE" end
    return store:DeleteProfile(store:GetActiveProfileId())
  end
  function Addon.Config.SwitchProfile(store,id)
    if not store then return false,"STORE_UNAVAILABLE" end
    if type(id)~="string" then return false,"INVALID_PROFILE" end
    return store:SwitchProfile(id)
  end
  function Addon.Config.ListItems(store,scope,kind)
    if not store then return nil,"STORE_UNAVAILABLE" end
    return store:ExportList(scope,kind)
  end
  function Addon.Config.EditItem(store,scope,kind,itemId,present)
    if not store then return false,"STORE_UNAVAILABLE" end
    return store:EditList(scope,kind,itemId,present)
  end
  function Addon.Config.ListRules(store)
    if not store then return nil,"STORE_UNAVAILABLE" end
    return store:GetActiveProfile().rules or {}
  end
  function Addon.Config.AddRule(store,group)
    if not store then return false,"STORE_UNAVAILABLE" end
    return store:AddRule(group)
  end
  function Addon.Config.RemoveRule(store,id)
    if not store then return false,"STORE_UNAVAILABLE" end
    return store:RemoveRule(id)
  end
  function Addon.Config.SetOption(store,key,value)
    if not store then return false,"STORE_UNAVAILABLE" end
    return store:SetOption(key,value)
  end
  function Addon.Config.SetGlobalOption(store,key,value)
    if not store then return false,"STORE_UNAVAILABLE" end
    return store:SetGlobalOption(key,value)
  end
  function Addon.Config.GetGlobalOptions(store)
    if not store then return nil,"STORE_UNAVAILABLE" end
    return store:GetState().global or {}
  end
  function Addon.Config.GetOptions(store)
    if not store then return nil,"STORE_UNAVAILABLE" end
    return store:GetActiveProfile().options or {}
  end
  function Addon.Config.FilterItemIds(raw,query,resolveName)
    raw=type(raw)=="string" and raw or ""; query=type(query)=="string" and query:lower() or ""
    local result,seen={},{}
    for id in raw:gmatch("%d+") do
      if not seen[id] then
        seen[id]=true
        local name
        if type(resolveName)=="function" then local ok,value=pcall(resolveName,id); if ok and type(value)=="string" then name=value end end
        if query=="" or id:find(query,1,true) or (name and name:lower():find(query,1,true)) then result[#result+1]={id=id,name=name} end
      end
    end
    return result
  end
  function Addon.Config.SortListItems(items,resolveItem)
    local result,seen={},{}
    for _,entry in ipairs(type(items)=="table" and items or {}) do
      local id=type(entry)=="table" and tostring(entry.id or "") or tostring(entry)
      if id:match("^%d+$") and not seen[id] then
        seen[id]=true
        local item=type(entry)=="table" and entry or nil
        if (not item or item.quality==nil or item.name==nil) and type(resolveItem)=="function" then
          local ok,value=pcall(resolveItem,id); if ok and type(value)=="table" then item=value end
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
  function Addon.Config.PreviewListImport(store,scope,kind,text)
    if not store then return nil,"STORE_UNAVAILABLE" end
    return store:ImportPreview(scope,kind,text)
  end
  function Addon.Config.CommitListImport(store,preview)
    if not store then return false,"STORE_UNAVAILABLE" end
    return store:CommitImport(preview)
  end
end

function Addon.NewApplication(runtime)
  local app = {
    runtime = runtime, client = runtime:Inspect(), state = "WAITING_FOR_LOAD",
    loaded = false, loggedIn = false, diagnostics = Addon.NewDiagnostics()
  }
  local function failed() app.diagnostics:Error() end
  app.bus = Addon.NewEventBus(failed)
  app.scheduler = Addon.NewScheduler(failed, function(pending) runtime:SetUpdating(pending) end)

  local function activate()
    if app.loaded and app.loggedIn and app.state ~= "READY" and app.client.supported then
      app.state = "READY"
      app.cache:Start()
      runtime:Print("Development compatibility port ready. Previews are read-only; /djw help lists commands.")
    end
  end
  function app:HandleEvent(event, ...)
    if not self.client.supported or self.state == "STOPPED" then return end
    self.diagnostics:RecordEvent(event, ...)
    if event == "ADDON_LOADED" then
      if (...) == Addon.name then
        self.loaded = true
        if type(DejunkWotLKDB) == "table" and DejunkWotLKDB.schemaVersion and
            DejunkWotLKDB.schemaVersion > Addon.Store.VERSION then
          self.store = Addon.Store.Initialize(DejunkWotLKDB, nil)
        else
          self.store = Addon.Store.Initialize(DejunkWotLKDB, runtime:CharacterKey())
          if not self.store.readonly then
            self.store:OnChange(function(state) DejunkWotLKDB = state end)
            DejunkWotLKDB = self.store:Serialize()
          end
        end
        activate()
      end
    elseif event == "PLAYER_LOGIN" then
      self.loggedIn = true
      activate()
    elseif event == "PLAYER_LOGOUT" then
      if self.cache then self.cache:Stop() end
      self.scheduler:CancelAll()
      self.state = "STOPPED"
      runtime:Stop()
    elseif self.state == "READY" then
      if event == "BAG_UPDATE" or event == "ITEM_LOCK_CHANGED" or
          event == "ITEM_LOCKED" or event == "ITEM_UNLOCKED" or
          event == "EQUIPMENT_SETS_CHANGED" or event == "PLAYER_EQUIPMENT_CHANGED" then
        self.cache:Invalidate(event)
      end
      -- Merchant and error events are evidence only, never action triggers.
      self.bus:Emit(event, ...)
    end
  end

  function app:ProbeSlot(bag, slot)
    if self.state ~= "READY" then return nil end
    local generation = self.cache.generation
    local sets = self.adapter:ReadEquipmentSets()
    local item = self.adapter:ReadSlot(bag, slot, sets)
    if item.state == "OCCUPIED" then item.bound = self.adapter:ReadBinding(bag, slot) end
    local after = self.adapter:ReadSlot(bag, slot, sets)
    if generation ~= self.cache.generation or item.state ~= after.state or item.link ~= after.link or
        item.count ~= after.count or item.locked ~= after.locked then
      item.state, item.reason, item.bound = "UNKNOWN", "PROBE_CHANGED", Addon.UNKNOWN
    end
    item.bagGeneration = generation
    self.lastProbe = Addon.Copy(item)
    return Addon.Copy(item)
  end

  function app:Preview(action)
    local profile = self.store and self.store:GetActiveProfile() or {}
    local settings = {
      profile = profile,
      global = self.store and self.store:GetState().global or {},
      protectUnboundEquipment = true
    }
    return Addon.Preview.EvaluateSnapshot(self.cache:GetSnapshot(), settings, action)
  end

  function app:OpenConfig()
    local function profile()
      return self.store and self.store:GetActiveProfile() or nil
    end
    runtime:ShowConfig({
      summary=function() return Addon.Config.Summary(self.store) end,
      poorEnabled=function()
        local current=profile()
        return current and current.options and current.options.quality and current.options.quality[0]==true or false
      end,
      togglePoor=function()
        local ok,reason,enabled=Addon.Config.ToggleQuality(self.store,0)
        runtime:Print(ok and ("Poor quality rule "..(enabled and "enabled." or "disabled.")) or ("Rule update failed: "..tostring(reason)))
      end,
      profiles=function() return Addon.Config.ListProfiles(self.store) end,
      createProfile=function(name) return Addon.Config.CreateProfile(self.store,name) end,
      duplicateProfile=function(name) return Addon.Config.DuplicateProfile(self.store,name) end,
      duplicateProfileFrom=function(id,name) return Addon.Config.DuplicateProfileFrom(self.store,id,name) end,
      renameActiveProfile=function(name) return Addon.Config.RenameActiveProfile(self.store,name) end,
      renameProfile=function(id,name) return Addon.Config.RenameProfile(self.store,id,name) end,
      resetActiveProfile=function() return Addon.Config.ResetActiveProfile(self.store) end,
      resetProfile=function(id) return Addon.Config.ResetProfile(self.store,id) end,
      deleteActiveProfile=function() return Addon.Config.DeleteActiveProfile(self.store) end,
      deleteProfile=function(id) return Addon.Config.DeleteProfile(self.store,id) end,
      activeProfileName=function() return self.store:GetActiveProfile().name end,
      activeProfileId=function() return self.store:GetActiveProfileId() end,
      switchProfile=function(id) return Addon.Config.SwitchProfile(self.store,id) end,
      listItems=function(scope,kind) return Addon.Config.ListItems(self.store,scope,kind) end,
      editItem=function(scope,kind,id,present) return Addon.Config.EditItem(self.store,scope,kind,id,present) end,
      previewListImport=function(scope,kind,text) return Addon.Config.PreviewListImport(self.store,scope,kind,text) end,
      commitListImport=function(preview) return Addon.Config.CommitListImport(self.store,preview) end,
      listRules=function() return Addon.Config.ListRules(self.store) end,
      addRule=function(group) return Addon.Config.AddRule(self.store,group) end,
      removeRule=function(id) return Addon.Config.RemoveRule(self.store,id) end,
      options=function() return Addon.Config.GetOptions(self.store) end,
      setOption=function(key,value) return Addon.Config.SetOption(self.store,key,value) end,
      globalOptions=function() return Addon.Config.GetGlobalOptions(self.store) end,
      setGlobalOption=function(key,value) return Addon.Config.SetGlobalOption(self.store,key,value) end,
      preview=function(action)
        local requested=type(action)=="string" and action:upper() or ""
        if requested~="SELL" and requested~="DESTROY" then runtime:Print("Preview unavailable: INVALID_ACTION"); return end
        if self.state~="READY" then runtime:Print("Preview unavailable: "..self.state); return end
        local rows,reason=self:Preview(requested)
        if reason then runtime:Print("Preview unavailable: "..tostring(reason)); return end
        local report,counts=Addon.Preview.Format(rows,requested)
        if not report then runtime:Print("Preview unavailable: "..tostring(counts)); return end
        runtime:ShowReport(report,"Read-only preview: "..requested,"config")
      end
    })
  end

  function app:Command(input)
    input = type(input) == "string" and input or ""
    local command, rest = input:match("^%s*(%S*)%s*(.-)%s*$")
    command = command:lower()
    if command == "" or command == "status" then
      runtime:Print(self.state .. " / " .. self.client.reason .. ". Read only; /djw help.")
    elseif command == "profile" then
      if not self.store then runtime:Print("Profile store unavailable."); return end
      local action, args = rest:match("^(%S*)%s*(.-)%s*$"); action = (action or ""):lower()
      if action == "list" or action == "" then
        local state=self.store:GetState(); local ids={}; for id in pairs(state.profiles) do ids[#ids+1]=id end; table.sort(ids)
        runtime:Print("Active profile: " .. self.store:GetActiveProfile().name .. " (" .. self.store:GetActiveProfileId() .. ")")
        for _,id in ipairs(ids) do runtime:Print(id .. " — " .. state.profiles[id].name) end
      elseif action == "create" then local id,err=self.store:CreateProfile(args); runtime:Print(id and ("Created "..id) or ("Create failed: "..tostring(err)))
      elseif action == "switch" then runtime:Print(self.store:SwitchProfile(args) and "Profile switched." or "Unknown profile.")
      elseif action == "rename" then local id,name=args:match("^(%S+)%s+(.+)$"); runtime:Print(self.store:RenameProfile(id,name) and "Profile renamed." or "Rename failed.")
      elseif action == "delete" then runtime:Print(self.store:DeleteProfile(args) and "Profile deleted." or "Delete failed; Default is protected.")
      elseif action == "reset" then runtime:Print(self.store:ResetProfile(args) and "Profile reset." or "Reset failed; Default is protected.")
      else runtime:Print("Use /djw profile list | create <name> | switch <id> | rename <id> <name> | delete <id> | reset <id>") end
    elseif command == "lists" then
      if not self.store then runtime:Print("List store unavailable."); return end
      local action, scope, kind, args = rest:match("^(%S+)%s+(%S+)%s+(%S+)%s*(.-)%s*$")
      action,scope,kind=(action or ""):lower(),(scope or ""):lower(),(kind or ""):lower()
      if action == "show" or action == "export" then
        local exported=self.store:ExportList(scope,kind)
        if not exported then runtime:Print("Usage: /djw lists show <global|profile> <inclusions|exclusions>")
        elseif exported=="" then runtime:Print("List is empty.")
        else for line in exported:gmatch("[^\n]+") do runtime:Print(line) end end
      elseif action == "add" or action == "remove" then
        local id=tonumber(args); local ok,err=self.store:EditList(scope,kind,id,action=="add")
        runtime:Print(ok and "List updated." or ("List update failed: "..tostring(err)))
      elseif action == "import" then
        local preview,err=self.store:ImportPreview(scope,kind,args)
        if not preview then runtime:Print("Import rejected: "..tostring(err))
        else
          local ok,reason=self.store:CommitImport(preview)
          runtime:Print(ok and ("Imported "..#preview.add.." new IDs; "..#preview.existing.." already present.") or ("Import failed: "..tostring(reason)))
        end
      else runtime:Print("Use /djw lists show|add|remove|import <global|profile> <inclusions|exclusions> [IDs]") end
    elseif command == "rules" then
      if not self.store then runtime:Print("Rule store unavailable."); return end
      local action,args=rest:match("^(%S*)%s*(.-)%s*$"); action=(action or ""):lower()
      if action=="quality" then
        local quality,enabled=args:match("^(%d+)%s+(%S+)$"); quality=tonumber(quality); enabled=(enabled or ""):lower()
        local ok,err=false,"INVALID_OPTION"
        if quality and (enabled=="on" or enabled=="off") then ok,err=self.store:SetOption("quality",{quality=quality,enabled=enabled=="on"}) end
        runtime:Print(ok and "Quality rule updated." or ("Rule update failed: "..tostring(err)))
      elseif action=="list" or action=="" then
        local profile=self.store:GetActiveProfile(); local options=profile.options or {}
        runtime:Print("Quality indexes enabled (0-4): "..table.concat((function() local values={} for i=0,4 do if options.quality and options.quality[i] then values[#values+1]=tostring(i) end end return values end)(),","))
      else
      runtime:Print("Use /djw rules list | quality <0-4> on|off")
      end
    elseif command == "config" then
      self:OpenConfig()
    elseif command == "profiles" then
      local action,args=rest:match("^(%S*)%s*(.-)%s*$"); action=(action or ""):lower()
      if action=="create" then
        local id,reason=Addon.Config.CreateProfile(self.store,args)
        runtime:Print(id and ("Created and activated profile "..id..".") or ("Profile creation failed: "..tostring(reason)))
      elseif action=="switch" then
        local ok,reason=Addon.Config.SwitchProfile(self.store,args)
        runtime:Print(ok and ("Active profile: "..self.store:GetActiveProfile().name.." ("..args..")") or ("Profile switch failed: "..tostring(reason or "UNKNOWN_PROFILE")))
      elseif action=="list" or action=="" then
        local profiles=Addon.Config.ListProfiles(self.store)
        for _,profile in ipairs(profiles or {}) do runtime:Print((profile.active and "* " or "  ")..profile.id.." — "..profile.name) end
      else runtime:Print("Use /djw profiles list | create <name> | switch <id>") end
    elseif command == "help" then
      runtime:Print("Dejunk: /dejunk or /dejunk options opens the main settings window; /dejunk profiles lists profiles.")
      runtime:Print("SELL, DESTROY, repair, junk-frame and loot-frame actions are not connected in this development build.")
      runtime:Print("Development diagnostics: /djw status | /djw preview sell|destroy | /djw slot <bag> <slot> | /djw report.")
    elseif command == "report" then
      runtime:ShowReport(self.diagnostics:Report(self))
    elseif command == "preview" then
      local action = rest:upper()
      if action ~= "SELL" and action ~= "DESTROY" then
        runtime:Print("Usage: /djw preview sell|destroy (read only)")
        return
      end
      if self.state ~= "READY" then runtime:Print("Preview unavailable: " .. self.state); return end
      local rows, reason = self:Preview(action)
      if reason then runtime:Print("Preview unavailable: " .. reason); return end
      local counts = { JUNK=0, KEEP=0, UNKNOWN=0 }
      for _, row in ipairs(rows) do
        counts[row.result] = (counts[row.result] or 0) + 1
        runtime:Print(row.result .. " bag=" .. tostring(row.bag) .. " slot=" .. tostring(row.slot) ..
          " item=" .. tostring(row.itemId or "unknown") .. " reason=" .. row.reasonCode)
      end
      runtime:Print("Preview totals: eligible=" .. counts.JUNK .. " keep=" .. counts.KEEP .. " unknown=" .. counts.UNKNOWN .. ". No action taken.")
    elseif command == "probe" then
      for line in self.diagnostics:Report(self):gmatch("[^\n]+") do runtime:Print(line) end
    elseif command == "slot" then
      if self.state ~= "READY" then runtime:Print("Slot reads unavailable: " .. self.state); return end
      local bagText, slotText = rest:match("^(%d+)%s+(%d+)$")
      local bag, slot = tonumber(bagText), tonumber(slotText)
      if not bag or bag > 4 or not slot or slot < 1 or slot > 128 then
        runtime:Print("Usage: /djw slot <bag 0..4> <slot 1..bag size>")
        return
      end
      local item = self:ProbeSlot(bag, slot)
      for _, line in ipairs(self.diagnostics:SlotLines(item)) do runtime:Print(line) end
    else
      runtime:Print("Unknown command. Use /djw help for the command guide.")
    end
  end

  runtime:RegisterCommands(function(input) app:Command(input) end)
  if not app.client.supported then
    app.state = "DISABLED"
    runtime:Print("Disabled: " .. app.client.reason .. ". Requires original 3.3.5a, build 12340, Interface 30300.")
    return app
  end
  app.adapter = runtime:NewAdapter()
  app.cache = Addon.NewBagCache(app.adapter, app.scheduler, app.bus)
  local ok, started = pcall(runtime.Start, runtime,
    function(event, ...) app:HandleEvent(event, ...) end,
    function(elapsed) app.scheduler:Advance(elapsed) end)
  if not ok or not started then
    pcall(runtime.Stop, runtime)
    app.client.supported, app.client.reason, app.state = false, "EVENT_SETUP_FAILED", "DISABLED"
    runtime:Print("Disabled: EVENT_SETUP_FAILED. /djw report for diagnostics.")
  end
  return app
end

Addon.Application = Addon.NewApplication(Addon.Runtime.New())
