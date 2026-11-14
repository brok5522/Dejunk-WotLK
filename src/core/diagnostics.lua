local _, Addon = ...

local function safe(value)
  if value == nil then return "unknown" end
  local text = tostring(value):gsub("[%c]", " "):gsub("|", "/")
  return text:sub(1, 180)
end

function Addon.NewDiagnostics()
  local diagnostics = { events = {}, errors = 0 }
  function diagnostics:RecordEvent(event, ...)
    local types = {}
    for i = 1, select("#", ...) do types[i] = type(select(i, ...)) end
    -- Values (including character names and UI error text) are never recorded.
    local record = event .. " args=" .. select("#", ...) .. ":" .. table.concat(types, ",")
    self.events[#self.events + 1] = record
    if #self.events > 32 then table.remove(self.events, 1) end
  end
  function diagnostics:Error() self.errors = self.errors + 1 end
  function diagnostics:SlotLines(item)
    local lines = { "slot probe (no item name, hyperlink or character data):" }
    for _, field in ipairs({
      "bag", "slot", "bagGeneration", "state", "reason", "itemId", "count", "quality",
      "itemLevel", "unitVendorPrice", "equipLoc", "itemType", "itemSubType", "metadata",
      "locked", "quest", "bound", "refundable", "refundSeconds", "inEquipmentSet",
      "containerShape", "itemInfoShape", "questShape", "purchaseShape"
    }) do lines[#lines + 1] = "  " .. field .. "=" .. safe(item[field]) end
    return lines
  end
  function diagnostics:Report(application)
    local client = application.client
    local snapshot = application.cache and application.cache:GetSnapshot()
    local lines = {
      "Dejunk-WotLK " .. Addon.version .. " | PHASE 1 | READ ONLY",
      "This is diagnostic evidence, not approval for inventory operations.",
      "state=" .. safe(application.state) .. " reason=" .. safe(client.reason),
      "version=" .. safe(client.version) .. " build=" .. safe(client.build) .. " interface=" .. safe(client.interface),
      "locale=" .. safe(application.runtime:Locale()) .. " callbackErrors=" .. self.errors,
      "capabilities:"
    }
    local names = {}
    for name in pairs(client.capabilities) do names[#names + 1] = name end
    table.sort(names)
    for _, name in ipairs(names) do lines[#lines + 1] = "  " .. name .. "=" .. safe(client.capabilities[name]) end
    lines[#lines + 1] = "event registration (registered does not prove event delivery):"
    names = {}
    for event in pairs(application.runtime.registration) do names[#names + 1] = event end
    table.sort(names)
    for _, name in ipairs(names) do lines[#lines + 1] = "  " .. name .. "=" .. application.runtime.registration[name] end
    if snapshot then
      lines[#lines + 1] = "cache generation=" .. snapshot.generation .. " current=" .. snapshot.currentGeneration ..
        " valid=" .. tostring(snapshot.valid) .. " occupied=" .. snapshot.occupied .. " unresolved=" .. snapshot.unknown
      lines[#lines + 1] = "equipmentSetsKnown=" .. safe(snapshot.equipmentSetsKnown) .. " count=" .. safe(snapshot.equipmentSetCount)
      for bag = 0, 4 do
        local container = snapshot.bags[bag]
        lines[#lines + 1] = "  bag=" .. bag .. " slots=" .. safe(container and container.size)
      end
    end
    if application.lastProbe then
      for _, line in ipairs(self:SlotLines(application.lastProbe)) do lines[#lines + 1] = line end
    end
    lines[#lines + 1] = "recent event payload types (last 32; values omitted):"
    for _, line in ipairs(self.events) do lines[#lines + 1] = "  " .. line end
    lines[#lines + 1] = "No inventory mutation APIs are implemented or called."
    return table.concat(lines, "\n")
  end
  return diagnostics
end
