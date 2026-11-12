local _, Addon = ...

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
      runtime:Print("Phase 2 ready. /djw report opens diagnostics; /djw help lists commands.")
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

  function app:Command(input)
    input = type(input) == "string" and input or ""
    local command, rest = input:match("^%s*(%S*)%s*(.-)%s*$")
    command = command:lower()
    if command == "" or command == "status" then
      runtime:Print(self.state .. " / " .. self.client.reason .. ". Read only; /djw help.")
    elseif command == "report" then
      runtime:ShowReport(self.diagnostics:Report(self))
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
      runtime:Print("Commands: /djw status | report (copy panel) | probe (chat) | slot <bag> <slot> | help")
      runtime:Print("Phase 2 stores profiles and lists. Selling, destroying and repair are unavailable.")
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
