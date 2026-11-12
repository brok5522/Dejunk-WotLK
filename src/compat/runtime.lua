local _, Addon = ...
local Runtime = {}
Addon.Runtime = Runtime

-- All interaction with WoW globals, frames and commands stays in this module.
function Runtime.New(environment)
  local api = environment or _G
  local runtime = { registration = {} }
  local frame, update, scanTooltip, reportFrame, reportEdit, configFrame, configSummary, poorButton
  local profileFrame,profileSummary,profileNameBox,profileList,profileButtons,profileScroll
  local readingTooltip = false

  function runtime:Inspect() return Addon.Client.Inspect(api) end
  function runtime:Print(message)
    local text = "[Dejunk-WotLK] " .. message
    if api.DEFAULT_CHAT_FRAME and type(api.DEFAULT_CHAT_FRAME.AddMessage) == "function" then
      api.DEFAULT_CHAT_FRAME:AddMessage(text)
    elseif type(api.print) == "function" then
      api.print(text)
    end
  end
  function runtime:CharacterKey()
    if type(api.UnitName) ~= "function" or type(api.GetRealmName) ~= "function" then return nil end
    local okName, name = pcall(api.UnitName, "player")
    local okRealm, realm = pcall(api.GetRealmName)
    if not okName or not okRealm or type(name) ~= "string" or type(realm) ~= "string" then return nil end
    return realm .. "\31" .. name
  end
  function runtime:Locale()
    if type(api.GetLocale) ~= "function" then return "unknown" end
    local ok, locale = pcall(api.GetLocale)
    return ok and type(locale) == "string" and locale or "unknown"
  end
  function runtime:NewAdapter()
    local reads = {}
    for _, name in ipairs(Addon.Client.Required) do reads[name] = api[name] end
    for _, name in ipairs(Addon.Client.Optional) do reads[name] = api[name] end
    for _, name in ipairs({ "ITEM_SOULBOUND", "ITEM_BIND_TO_ACCOUNT", "ITEM_BIND_ON_EQUIP", "ITEM_BIND_ON_USE" }) do
      reads[name] = api[name]
    end
    reads.ReadBindingLines = function(bag, slot)
      if readingTooltip or type(api.CreateFrame) ~= "function" then return nil end
      readingTooltip = true
      local ok, lines = pcall(function()
        if not scanTooltip then
          scanTooltip = api.CreateFrame("GameTooltip", "DejunkWotLKReadOnlyScanTooltip", api.UIParent, "GameTooltipTemplate")
        end
        scanTooltip:SetOwner(api.UIParent, "ANCHOR_NONE")
        scanTooltip:ClearLines()
        scanTooltip:SetBagItem(bag, slot)
        local result = {}
        for i = 1, math.min(scanTooltip:NumLines(), 60) do
          local line = api["DejunkWotLKReadOnlyScanTooltipTextLeft" .. i]
          if line and type(line.GetText) == "function" then
            result[#result + 1] = line:GetText()
          end
        end
        scanTooltip:Hide()
        return result
      end)
      readingTooltip = false
      if not ok then
        if scanTooltip then pcall(scanTooltip.Hide, scanTooltip) end
        return nil
      end
      return lines
    end
    return Addon.Legacy.New(reads)
  end
  function runtime:RegisterCommands(callback)
    api.SlashCmdList = api.SlashCmdList or {}
    api.SLASH_DEJUNKWOTLK1 = "/dejunkwotlk"
    api.SLASH_DEJUNKWOTLK2 = "/djw"
    api.SlashCmdList.DEJUNKWOTLK = callback
  end
  function runtime:Start(onEvent, onUpdate)
    if type(api.CreateFrame) ~= "function" then return false end
    local ok, result = pcall(api.CreateFrame, "Frame")
    if not ok or not result then return false end
    frame, update = result, onUpdate
    frame:SetScript("OnEvent", function(_, event, ...) onEvent(event, ...) end)
    for _, event in ipairs({
      "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_LOGOUT", "BAG_UPDATE",
      "ITEM_LOCK_CHANGED", "ITEM_LOCKED", "ITEM_UNLOCKED", "EQUIPMENT_SETS_CHANGED",
      "PLAYER_EQUIPMENT_CHANGED", "MERCHANT_SHOW", "MERCHANT_CLOSED", "UI_ERROR_MESSAGE"
    }) do
      local registered = pcall(frame.RegisterEvent, frame, event)
      self.registration[event] = registered and "registered" or "unavailable"
    end
    for _, event in ipairs({ "ADDON_LOADED", "PLAYER_LOGIN", "BAG_UPDATE" }) do
      if self.registration[event] ~= "registered" then
        frame:UnregisterAllEvents()
        frame:SetScript("OnEvent", nil)
        return false
      end
    end
    return true
  end
  function runtime:SetUpdating(pending)
    if frame then
      frame:SetScript("OnUpdate", pending and function(_, elapsed) update(elapsed) end or nil)
    end
  end
  function runtime:Stop()
    if frame then
      frame:SetScript("OnUpdate", nil)
      frame:SetScript("OnEvent", nil)
      frame:UnregisterAllEvents()
    end
  end

  function runtime:ShowConfig(callbacks)
    callbacks=callbacks or {}
    local ok=pcall(function()
      if not configFrame then
        configFrame=api.CreateFrame("Frame",nil,api.UIParent)
        configFrame:SetWidth(500); configFrame:SetHeight(300); configFrame:SetPoint("CENTER")
        configFrame:SetFrameStrata("DIALOG"); configFrame:EnableMouse(true)
        configFrame:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=32,insets={left=8,right=8,top=8,bottom=8}})
        local title=configFrame:CreateFontString(nil,"OVERLAY","GameFontNormal")
        title:SetPoint("TOPLEFT",20,-18); title:SetText("Dejunk-WotLK | Configuration and preview")
        local close=api.CreateFrame("Button",nil,configFrame,"UIPanelCloseButton")
        close:SetPoint("TOPRIGHT",-4,-4); close:SetScript("OnClick",function() configFrame:Hide() end)
        configSummary=configFrame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        configSummary:SetPoint("TOPLEFT",24,-58); configSummary:SetWidth(450); configSummary:SetJustifyH("LEFT")
        local function button(label,x,y,handler)
          local control=api.CreateFrame("Button",nil,configFrame,"UIPanelButtonTemplate")
          control:SetWidth(142); control:SetHeight(24); control:SetPoint("BOTTOMLEFT",configFrame,"BOTTOMLEFT",x,y)
          control:SetText(label); control:SetScript("OnClick",handler); return control
        end
        poorButton=button("Toggle Poor quality",22,20,function()
          if callbacks.togglePoor then callbacks.togglePoor() end
          self:ShowConfig(callbacks)
        end)
        button("Preview SELL",178,20,function() if callbacks.preview then callbacks.preview("sell") end end)
        button("Preview DESTROY",334,20,function() if callbacks.preview then callbacks.preview("destroy") end end)
        button("Profiles",178,54,function()
          configFrame:Hide()
          self:ShowProfiles(callbacks)
        end)
      end
      configSummary:SetText(callbacks.summary and callbacks.summary() or "Settings unavailable.")
      if poorButton and poorButton.SetText and callbacks.poorEnabled then
        poorButton:SetText(callbacks.poorEnabled() and "Disable Poor rule" or "Enable Poor rule")
      end
      configFrame:Show()
    end)
    if not ok then
      self:Print("Configuration panel unavailable; use /djw rules and /djw preview sell|destroy.")
      if callbacks.summary then self:Print(callbacks.summary()) end
    end
  end

  function runtime:ShowProfiles(callbacks)
    callbacks=callbacks or {}
    local ok=pcall(function()
      if not profileFrame then
        profileFrame=api.CreateFrame("Frame",nil,api.UIParent)
        profileFrame:SetWidth(420); profileFrame:SetHeight(360); profileFrame:SetPoint("CENTER")
        profileFrame:SetFrameStrata("DIALOG"); profileFrame:EnableMouse(true)
        profileFrame:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=32,insets={left=8,right=8,top=8,bottom=8}})
        local title=profileFrame:CreateFontString(nil,"OVERLAY","GameFontNormal")
        title:SetPoint("TOPLEFT",18,-18); title:SetText("Dejunk-WotLK | Profiles")
        local close=api.CreateFrame("Button",nil,profileFrame,"UIPanelCloseButton")
        close:SetPoint("TOPRIGHT",-4,-4); close:SetScript("OnClick",function() profileFrame:Hide() end)
        profileSummary=profileFrame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        profileSummary:SetPoint("TOPLEFT",22,-50); profileSummary:SetWidth(360); profileSummary:SetJustifyH("LEFT")
        profileScroll=api.CreateFrame("ScrollFrame",nil,profileFrame,"UIPanelScrollFrameTemplate")
        profileScroll:SetPoint("TOPLEFT",22,-72); profileScroll:SetPoint("BOTTOMRIGHT",-40,95)
        profileList=api.CreateFrame("Frame",nil,profileScroll); profileList:SetWidth(335); profileList:SetHeight(175); profileScroll:SetScrollChild(profileList); profileButtons={}
        profileNameBox=api.CreateFrame("EditBox",nil,profileFrame,"InputBoxTemplate")
        profileNameBox:SetWidth(190); profileNameBox:SetHeight(24); profileNameBox:SetPoint("BOTTOMLEFT",profileFrame,"BOTTOMLEFT",24,52)
        profileNameBox:SetAutoFocus(false); profileNameBox:SetMaxLetters(32); profileNameBox:SetScript("OnEscapePressed",function() profileNameBox:ClearFocus() end)
        local create=api.CreateFrame("Button",nil,profileFrame,"UIPanelButtonTemplate")
        create:SetWidth(100); create:SetHeight(24); create:SetPoint("LEFT",profileNameBox,"RIGHT",8,0); create:SetText("Create")
        create:SetScript("OnClick",function()
          local name=profileNameBox:GetText() or ""
          local id,reason=callbacks.createProfile and callbacks.createProfile(name)
          if id then profileNameBox:SetText("") else self:Print("Profile creation failed: "..tostring(reason)) end
          self:ShowProfiles(callbacks)
        end)
        local refresh=api.CreateFrame("Button",nil,profileFrame,"UIPanelButtonTemplate")
        refresh:SetWidth(110); refresh:SetHeight(24); refresh:SetPoint("BOTTOMRIGHT",profileFrame,"BOTTOMRIGHT",-18,16); refresh:SetText("Back")
        refresh:SetScript("OnClick",function() profileFrame:Hide(); self:ShowConfig(callbacks) end)
      end
      local profiles=callbacks.profiles and callbacks.profiles() or {}
      local row=0
      for _,child in ipairs(profileButtons) do child:Hide() end
      profileButtons={}
      for index,profile in ipairs(profiles) do
        local button=api.CreateFrame("Button",nil,profileList,"UIPanelButtonTemplate")
        button:SetWidth(315); button:SetHeight(24); button:SetPoint("TOPLEFT",profileList,"TOPLEFT",0,-row*28)
        button:SetText((profile.active and "[ACTIVE] " or "")..profile.name.."  ("..profile.id..")")
        button:SetScript("OnClick",function()
          local switched,reason=callbacks.switchProfile and callbacks.switchProfile(profile.id)
          self:Print(switched and ("Active profile: "..profile.name) or ("Profile switch failed: "..tostring(reason)))
          self:ShowProfiles(callbacks)
        end)
        profileButtons[#profileButtons+1]=button
        row=row+1
      end
      profileList:SetHeight(math.max(175,row*28))
      profileSummary:SetText("Select a profile to activate it:")
      profileFrame:Show()
    end)
    if not ok then self:Print("Profiles window unavailable; use /djw profiles list|create|switch.") end
  end

  -- A diagnostic copy panel, not the configuration UI planned for Phase 6.
  function runtime:ShowReport(text)
    local ok = pcall(function()
      if not reportFrame then
        local panel = api.CreateFrame("Frame", "DejunkWotLKReadOnlyReport", api.UIParent)
        panel:SetWidth(600); panel:SetHeight(420); panel:SetPoint("CENTER")
        panel:SetFrameStrata("DIALOG"); panel:EnableMouse(true)
        panel:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 8, right = 8, top = 8, bottom = 8 } })
        local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", 20, -18)
        title:SetText("Dejunk-WotLK diagnostics | Ctrl+A, Ctrl+C to copy | Escape to close")
        local close = api.CreateFrame("Button", nil, panel, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -4, -4)
        close:SetScript("OnClick", function() panel:Hide() end)
        local scroll = api.CreateFrame("ScrollFrame", "DejunkWotLKReadOnlyReportScroll", panel, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 20, -45); scroll:SetPoint("BOTTOMRIGHT", -40, 20)
        local edit = api.CreateFrame("EditBox", nil, scroll)
        edit:SetMultiLine(true); edit:SetAutoFocus(false); edit:SetFontObject(api.ChatFontNormal)
        edit:SetWidth(530); edit:SetHeight(340)
        edit:SetScript("OnEscapePressed", function() panel:Hide() end)
        scroll:SetScrollChild(edit)
        reportFrame, reportEdit = panel, edit
      end
      local _, newlines = text:gsub("\n", "")
      reportEdit:SetHeight(math.max(340, (newlines + 1) * 16))
      reportEdit:SetText(text)
      reportFrame:Show(); reportEdit:SetFocus(); reportEdit:HighlightText()
    end)
    if not ok then
      self:Print("Report panel unavailable; printing the report to chat.")
      for line in text:gmatch("[^\n]+") do self:Print(line) end
    end
  end
  return runtime
end
