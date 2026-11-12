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
      if unknown(item.unitVendorPrice) then return result("UNKNOWN", "PRICE_UNKNOWN", action, ruleId) end
      if item.unitVendorPrice <= 0 then return result("KEEP", "NO_VENDOR_VALUE", action, ruleId) end
    end
    return result("JUNK", reason, action, ruleId)
  end
  function Rules.MatchGroup(item, group, action)
    if type(group) ~= "table" then return false, true end
    if group.scope ~= "BOTH" and group.scope ~= action then return false, false end
    if (group.result ~= "JUNK" and group.result ~= "KEEP") or
        (group.match ~= "ALL" and group.match ~= "ANY") or type(group.predicates) ~= "table" or #group.predicates == 0 then
      return false, true
    end
    local yes, no, maybe = 0, 0, 0
    for _, predicate in ipairs(group.predicates) do
      if type(predicate) ~= "table" then return false, true end
      local actual, expected, op = item[predicate.field], predicate.value, predicate.op
      if unknown(actual) then maybe = maybe + 1
      elseif op == "EQ" then if actual == expected then yes=yes+1 else no=no+1 end
      elseif (op == "LT" or op == "GT") and type(actual) == "number" and type(expected) == "number" then
        if (op == "LT" and actual < expected) or (op == "GT" and actual > expected) then yes=yes+1 else no=no+1 end
      else return false, true end
    end
    if group.match == "ALL" then
      if no > 0 then return false, false end
      if maybe > 0 then return false, true end
      return yes == #group.predicates, false
    end
    if yes > 0 then return true, false end
    if maybe > 0 then return false, true end
    return false, false
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
    for _, gate in ipairs({
      {"locked","LOCK_UNKNOWN","LOCKED"}, {"quest","QUEST_UNKNOWN","QUEST_ITEM"},
      {"inEquipmentSet","EQUIPMENT_SET_UNKNOWN","EQUIPMENT_SET_ITEM"},
      {"refundable","REFUND_UNKNOWN","REFUNDABLE"}
    }) do
      local value=item[gate[1]]
      if unknown(value) then return result("UNKNOWN",gate[2],action) end
      if value then return result("KEEP",gate[3],action) end
    end
    if item.quality==5 or item.quality==7 then return result("KEEP","LEGENDARY_OR_HEIRLOOM",action) end
    if settings.maxItemLevel ~= nil then
      if type(settings.maxItemLevel)~="number" or type(item.itemLevel)~="number" then return result("UNKNOWN","ITEM_LEVEL_UNKNOWN",action) end
      if item.itemLevel>settings.maxItemLevel then return result("KEEP","ABOVE_MAX_ITEM_LEVEL",action) end
    end
    if settings.maxStackVendorPrice ~= nil then
      if type(settings.maxStackVendorPrice)~="number" or type(item.unitVendorPrice)~="number" then return result("UNKNOWN","PRICE_UNKNOWN",action) end
      if item.unitVendorPrice*item.count>settings.maxStackVendorPrice then return result("KEEP","ABOVE_MAX_STACK_PRICE",action) end
    end
    if item.equipLoc and item.equipLoc~="" and settings.protectUnboundEquipment~=false then
      if unknown(item.bound) then return result("UNKNOWN","BINDING_UNKNOWN",action) end
      if item.bound==false then return result("KEEP","UNBOUND_EQUIPMENT",action) end
    end
    local profile,global=settings.profile or {},settings.global or {}
    if profile.exclusions and profile.exclusions[item.itemId] then return result("KEEP","PROFILE_EXCLUSION",action) end
    if global.exclusions and global.exclusions[item.itemId] then return result("KEEP","GLOBAL_EXCLUSION",action) end
    for _, group in ipairs(profile.rules or {}) do
      local matches, uncertain=Rules.MatchGroup(item,group,action)
      if uncertain then return result("UNKNOWN","RULE_DATA_UNKNOWN",action,group.id) end
      if matches then
        if group.result=="JUNK" then return junk(action,"CUSTOM_RULE",item,group.id) end
        return result("KEEP","CUSTOM_RULE",action,group.id)
      end
    end
    if profile.inclusions and profile.inclusions[item.itemId] then return junk(action,"PROFILE_INCLUSION",item) end
    if global.inclusions and global.inclusions[item.itemId] then return junk(action,"GLOBAL_INCLUSION",item) end
    local options=profile.options or {}
    if options.quality and options.quality[item.quality] then return junk(action,"QUALITY",item) end
    if settings.minItemLevel ~= nil then
      if type(settings.minItemLevel)~="number" or type(item.itemLevel)~="number" then return result("UNKNOWN","ITEM_LEVEL_UNKNOWN",action) end
      if item.itemLevel<settings.minItemLevel then return junk(action,"BELOW_MIN_ITEM_LEVEL",item) end
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
      "Item level minimum: "..tostring(options.minItemLevel or "off"),
      "Item level maximum: "..tostring(options.maxItemLevel or "off"),
      "Maximum stack vendor value (copper): "..tostring(options.maxStackVendorPrice or "off"),
      "Custom rule groups: "..tostring(#(profile.rules or {})),
      "Profile inclusions/exclusions: "..count(profile.inclusions).."/"..count(profile.exclusions)},"\n")
  end
  function Addon.Config.ToggleQuality(store,quality)
    if type(quality)~="number" or quality<0 or quality>7 or quality~=math.floor(quality) then return false,"INVALID_OPTION" end
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
  function Addon.Config.GetOptions(store)
    if not store then return nil,"STORE_UNAVAILABLE" end
    return store:GetActiveProfile().options or {}
  end
  function Addon.Config.FilterItemIds(raw,query,resolveName)
    raw=type(raw)=="string" and raw or ""; query=type(query)=="string" and query:lower() or ""
    local result={}
    for id in raw:gmatch("%d+") do
      local name
      if type(resolveName)=="function" then local ok,value=pcall(resolveName,id); if ok and type(value)=="string" then name=value end end
      if query=="" or id:find(query,1,true) or (name and name:lower():find(query,1,true)) then result[#result+1]={id=id,name=name} end
    end
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
      runtime:Print("Phase 6 ready. Configuration and inventory previews are read-only; /djw help lists commands.")
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
      minItemLevel = profile.options and profile.options.minItemLevel,
      maxItemLevel = profile.options and profile.options.maxItemLevel,
      maxStackVendorPrice = profile.options and profile.options.maxStackVendorPrice,
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
      renameActiveProfile=function(name) return Addon.Config.RenameActiveProfile(self.store,name) end,
      resetActiveProfile=function() return Addon.Config.ResetActiveProfile(self.store) end,
      deleteActiveProfile=function() return Addon.Config.DeleteActiveProfile(self.store) end,
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
      elseif action=="minlevel" or action=="maxlevel" or action=="maxprice" then
        local raw=args:lower(); local value=raw=="off" and nil or tonumber(raw)
        local key=action=="minlevel" and "minItemLevel" or action=="maxlevel" and "maxItemLevel" or "maxStackVendorPrice"
        local ok,err=self.store:SetOption(key,value)
        if raw~="off" and (not value or value<0 or value~=math.floor(value)) then ok,err=false,"INVALID_OPTION" end
        runtime:Print(ok and "Threshold updated." or ("Rule update failed: "..tostring(err)))
      elseif action=="add" then
        local id,scope,result,match,field,op,value=args:match("^(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)$")
        local group={id=id,scope=scope and scope:upper(),result=result and result:upper(),match=match and match:upper(),
          predicates={{field=field,op=op and op:upper(),value=tonumber(value)}}}
        local ok,err=self.store:AddRule(group)
        runtime:Print(ok and "Custom rule added." or ("Rule add failed: "..tostring(err)))
      elseif action=="remove" then
        local ok,err=self.store:RemoveRule(args)
        runtime:Print(ok and "Custom rule removed." or ("Rule remove failed: "..tostring(err)))
      elseif action=="list" or action=="" then
        local profile=self.store:GetActiveProfile(); local options=profile.options or {}
        runtime:Print("Active rules for "..profile.name..": "..#(profile.rules or {}))
        for _,rule in ipairs(profile.rules or {}) do
          local predicate=rule.predicates[1]
          runtime:Print(rule.id.." "..rule.scope.." "..rule.result.." "..rule.match.." "..predicate.field.." "..predicate.op.." "..predicate.value)
        end
        runtime:Print("Item level min/max: "..tostring(options.minItemLevel or "off").."/"..tostring(options.maxItemLevel or "off").."; max stack copper: "..tostring(options.maxStackVendorPrice or "off"))
        runtime:Print("Quality indexes enabled (0-7): "..table.concat((function() local values={} for i=0,7 do if options.quality and options.quality[i] then values[#values+1]=tostring(i) end end return values end)(),","))
      else
        runtime:Print("Use /djw rules list | quality <0-7> on|off | minlevel|maxlevel|maxprice <value|off>")
        runtime:Print("Custom: /djw rules add <id> <SELL|DESTROY|BOTH> <JUNK|KEEP> <ALL|ANY> <itemId|quality|itemLevel|unitVendorPrice|count> <EQ|LT|GT> <number>")
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
      runtime:Print("Commands: /djw status | config | profiles list|create|switch | report | probe | slot <bag> <slot> | preview sell|destroy | rules | profile | lists | help")
      runtime:Print("Preview is read-only. Selling, destroying and repair are unavailable.")
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
