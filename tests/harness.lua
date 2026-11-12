local Harness = { worlds = {} }
local function noop() end

function Harness.New(options)
  options = options or {}
  local world = {
    sizes = { [0] = 2, 0, 0, 0, 0 }, slots = {}, messages = {}, reads = 0,
    mutations = 0, frames = {}, sets = {}, tooltipLines = {}, tooltipReads = 0
  }
  local env = setmetatable({}, { __index = _G })
  env._G = env
  world.api = env
  env.GetBuildInfo = function() return options.version or "3.3.5", options.build or "12340", "date", options.interface or 30300 end
  env.GetContainerNumSlots = function(bag) world.reads = world.reads + 1; return world.sizes[bag] end
  env.GetContainerItemInfo = function(bag, slot)
    world.reads = world.reads + 1
    local item = world.slots[bag .. ":" .. slot]
    if not item then return nil end
    return item.texture or "Interface\\Icons\\INV_Misc_QuestionMark", item.count, item.locked,
      item.quality or 0, false, item.lootable or false, item.link
  end
  env.GetContainerItemLink = function(bag, slot)
    world.reads = world.reads + 1
    local item = world.slots[bag .. ":" .. slot]
    return item and item.link
  end
  env.GetContainerItemID = function(bag, slot)
    local item = world.slots[bag .. ":" .. slot]
    return item and item.id
  end
  env.GetItemInfo = function(link)
    for _, item in pairs(world.slots) do
      if item.link == link then
        if item.uncached then return nil end
        return "Example", link, item.quality or 0, 10, 1, "Localized Class", "Localized Subclass",
          20, "INVTYPE_HEAD", "texture", item.price
      end
    end
  end
  env.GetContainerItemQuestInfo = function(bag, slot)
    local item = world.slots[bag .. ":" .. slot]
    if item then return item.quest, nil, nil end
    return nil, nil, nil
  end
  env.GetContainerItemPurchaseInfo = function(bag, slot)
    local item = world.slots[bag .. ":" .. slot]
    return 0, 0, 0, 0, item and item.refundSeconds
  end
  env.GetNumEquipmentSets = function() return #world.sets end
  env.GetEquipmentSetInfo = function(index) return world.sets[index].name, "texture" end
  env.GetEquipmentSetItemIDs = function(name)
    for _, entry in ipairs(world.sets) do if entry.name == name then return entry.ids end end
  end
  env.GetLocale = function() return "frFR" end
  env.ITEM_SOULBOUND, env.ITEM_BIND_TO_ACCOUNT = "Lie", "Lie au compte"
  env.ITEM_BIND_ON_EQUIP, env.ITEM_BIND_ON_USE = "Lie si equipe", "Lie si utilise"
  env.print = function(text) world.messages[#world.messages + 1] = text end
  env.SlashCmdList = {}
  env.CreateFrame = function(kind, name)
    if name and kind == "Frame" then error("diagnostic UI deliberately not mocked") end
    if kind == "GameTooltip" then
      local tooltip = { SetOwner = noop, ClearLines = noop, Hide = noop }
      function tooltip:SetBagItem()
        world.tooltipReads = world.tooltipReads + 1
        for i, text in ipairs(world.tooltipLines) do
          local value = text
          env[name .. "TextLeft" .. i] = { GetText = function() return value end }
        end
      end
      function tooltip:NumLines() return #world.tooltipLines end
      return tooltip
    end
    local frame = { scripts = {}, registered = {} }
    function frame:SetScript(event, handler) self.scripts[event] = handler end
    function frame:RegisterEvent(event)
      if options.badEvent == event then error("unsupported event") end
      self.registered[event] = true
    end
    function frame:UnregisterAllEvents() self.registered = {} end
    world.frames[#world.frames + 1] = frame
    return frame
  end
  for _, name in ipairs({
    "UseContainerItem", "PickupContainerItem", "DeleteCursorItem", "ClearCursor",
    "RepairAllItems", "SplitContainerItem", "EquipItemByName", "PickupInventoryItem"
  }) do
    env[name] = function() world.mutations = world.mutations + 1; error("forbidden mutation") end
  end
  function world:AddItem(bag, slot, overrides)
    local item = {
      id = 123, link = "|cffffffff|Hitem:123:0:0:0:0:0:0:0|h[Example]|h|r",
      count = 3, locked = false, price = 5, quest = false, refundSeconds = 0
    }
    for key, value in pairs(overrides or {}) do item[key] = value end
    self.slots[bag .. ":" .. slot] = item
    return item
  end
  function world:Load()
    self.addon = {}
    for line in io.lines("Dejunk-WotLK.toc") do
      if not line:match("^%s*#") and line:match("%S") then
        local path = line:gsub("\\", "/")
        if not (options.skipFiles and options.skipFiles[path]) then
          local chunk = assert(loadfile(path))
          setfenv(chunk, env)("Dejunk-WotLK", self.addon)
        end
      end
    end
    self.app = self.addon.Application
    return self
  end
  function world:Fire(event, ...)
    for _, frame in ipairs(self.frames) do
      if frame.registered[event] and frame.scripts.OnEvent then frame.scripts.OnEvent(frame, event, ...) end
    end
  end
  function world:Tick(elapsed)
    for _, frame in ipairs(self.frames) do
      if frame.scripts.OnUpdate then frame.scripts.OnUpdate(frame, elapsed) end
    end
  end
  function world:Ready()
    self:Fire("ADDON_LOADED", "Dejunk-WotLK")
    self:Fire("PLAYER_LOGIN")
    self:Tick(0.1)
    return self
  end
  function world:Command(command) env.SlashCmdList.DEJUNKWOTLK(command) end
  Harness.worlds[#Harness.worlds + 1] = world
  return world
end
return Harness
