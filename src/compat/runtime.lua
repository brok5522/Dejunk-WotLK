local _, Addon = ...
local Runtime = {}
Addon.Runtime = Runtime

-- All interaction with WoW globals, frames and commands stays in this module.
function Runtime.New(environment)
  local api = environment or _G
  local runtime = { registration = {} }
  local frame, update, scanTooltip, reportFrame, reportEdit, reportTitle, configFrame, configSummary, poorButton
  local configWaffleRoot
  local profileFrame,profileSummary,profileNameBox,profileList,profileButtons,profileScroll
  local listFrame,listSummary,listInput,listScopeButton,listKindButton,listSearch,listPanels
  local importFrame,importTitle,importEdit,importStatus,importCommitButton,importPreview,importScope,importKind
  local reportReturnTarget
  local rulesFrame,rulesSummary,ruleIdInput,ruleValueInput,ruleScopeButton,ruleResultButton,ruleFieldButton,ruleOpButton,ruleGroupButton
  local ruleDraftPredicates,ruleDraftProfileId={},nil
  local optionsFrame,optionsQualityButtons,optionsFields
  local readingTooltip = false
  local itemPresentationCache={}

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
    if Addon.Waffle then
      local ok=pcall(function()
        if not configWaffleRoot then
          local function button(parent,label,onClick)
            return {width=168,height=32,frameFactory=function(owner)
              local control=api.CreateFrame("Button",nil,owner,"UIPanelButtonTemplate")
              control:SetText(label); control:SetScript("OnClick",onClick)
              return control
            end}
          end
          local function text(parent,label,height)
            return {height=height or 24,frameFactory=function(owner)
              local region=owner:CreateFontString(nil,"ARTWORK","GameFontNormal")
              region:SetJustifyH("LEFT"); region:SetText(label)
              return region
            end}
          end
          configWaffleRoot=Addon.Waffle:Flex({
            width=800,height=640,direction="COLUMN",visibility="GONE",
            frameFactory=function()
              local panel=api.CreateFrame("Frame", "DejunkWotLK_MainWindow", api.UIParent)
              panel:SetFrameStrata("DIALOG"); panel:EnableMouse(true); panel:SetMovable(true)
              panel:RegisterForDrag("LeftButton")
              panel:SetScript("OnDragStart",function(self) self:StartMoving() end)
              panel:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end)
              panel:SetPoint("CENTER"); panel:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1,insets={left=1,right=1,top=1,bottom=1}})
              panel:SetBackdropColor(0.08,0.08,0.08,0.96); panel:SetBackdropBorderColor(0.45,0.45,0.45,1)
              panel:Hide(); return panel
            end
          })
          local title=configWaffleRoot:AddRow({height=38,padding=10,justify="SPACE_BETWEEN",frameFactory=function(parent)
            local bar=api.CreateFrame("Frame",nil,parent); bar:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8"}); bar:SetBackdropColor(0.16,0.16,0.16,1); return bar
          end})
          title:AddChild(text(nil,"Dejunk | Configuration",30))
          title:AddChild({width=28,height=28,frameFactory=function(parent)
            local close=api.CreateFrame("Button",nil,parent,"UIPanelCloseButton")
            close:SetScript("OnClick",function() configWaffleRoot:SetVisibility("GONE"); configWaffleRoot:Layout() end)
            return close
          end})
          local content=configWaffleRoot:AddRow({grow=1,padding=12,gap=12})
          local nav=content:AddColumn({width=185,gap=6})
          local main=content:AddColumn({grow=1,padding=10,gap=8,frameFactory=function(parent)
            local panel=api.CreateFrame("Frame",nil,parent); panel:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1,insets={left=1,right=1,top=1,bottom=1}}); panel:SetBackdropColor(0,0,0,0.45); panel:SetBackdropBorderColor(0.32,0.32,0.32,1); return panel
          end})
          nav:AttachComponent(Addon.Waffle:Flex(button(nil,"Overview",function() end)))
          nav:AttachComponent(Addon.Waffle:Flex(button(nil,"Profiles",function() configWaffleRoot:SetVisibility("GONE"); configWaffleRoot:Layout(); self:ShowProfiles(callbacks) end)))
          nav:AttachComponent(Addon.Waffle:Flex(button(nil,"Lists",function() configWaffleRoot:SetVisibility("GONE"); configWaffleRoot:Layout(); self:ShowLists(callbacks) end)))
          nav:AttachComponent(Addon.Waffle:Flex(button(nil,"Rules",function() configWaffleRoot:SetVisibility("GONE"); configWaffleRoot:Layout(); self:ShowRules(callbacks) end)))
          nav:AttachComponent(Addon.Waffle:Flex(button(nil,"Options",function() configWaffleRoot:SetVisibility("GONE"); configWaffleRoot:Layout(); self:ShowOptions(callbacks) end)))
          main:AttachComponent(Addon.Waffle:Flex(text(nil,"Active profile and safe preview",28)))
          main:AttachComponent(Addon.Waffle:Flex(text(nil,"Settings and inventory previews are read-only. No item action will be taken.",46)))
          main:AttachComponent(Addon.Waffle:Flex({height=26,frameFactory=function(parent)
            configSummary=parent:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); configSummary:SetJustifyH("LEFT"); configSummary:SetWordWrap(true); return configSummary
          end}))
          local controls=main:AddRow({height=34,gap=8,wrap=true})
          controls:AttachComponent(Addon.Waffle:Flex(button(nil,"Toggle Poor quality",function() if callbacks.togglePoor then callbacks.togglePoor() end; self:ShowConfig(callbacks) end)))
          controls:AttachComponent(Addon.Waffle:Flex(button(nil,"Preview SELL",function() if callbacks.preview then callbacks.preview("sell") end end)))
          controls:AttachComponent(Addon.Waffle:Flex(button(nil,"Preview DESTROY",function() if callbacks.preview then callbacks.preview("destroy") end end)))
        end
        configSummary:SetText(callbacks.summary and callbacks.summary() or "Settings unavailable.")
        configWaffleRoot:SetVisibility("VISIBLE"); configWaffleRoot:Layout()
        configFrame=configWaffleRoot:GetFrame()
        if configFrame and poorButton and poorButton.SetText and callbacks.poorEnabled then
          poorButton:SetText(callbacks.poorEnabled() and "Disable Poor rule" or "Enable Poor rule")
        end
      end)
      if ok then return end
      self:Print("Original Waffle configuration UI could not be opened; using the built-in fallback.")
    end
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
        button("Lists",22,54,function()
          configFrame:Hide()
          self:ShowLists(callbacks)
        end)
        button("Rules",334,54,function()
          configFrame:Hide()
          self:ShowRules(callbacks)
        end)
        button("Options",334,88,function()
          configFrame:Hide()
          self:ShowOptions(callbacks)
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
        -- The 3.3.5 scroll template builds scrollbar globals from its frame name.
        profileScroll=api.CreateFrame("ScrollFrame","DejunkWotLKProfileScrollFrame",profileFrame,"UIPanelScrollFrameTemplate")
        profileScroll:SetPoint("TOPLEFT",22,-72); profileScroll:SetPoint("BOTTOMRIGHT",-40,95)
        profileList=api.CreateFrame("Frame",nil,profileScroll); profileList:SetWidth(335); profileList:SetHeight(175); profileScroll:SetScrollChild(profileList); profileButtons={}
        profileNameBox=api.CreateFrame("EditBox",nil,profileFrame,"InputBoxTemplate")
        profileNameBox:SetWidth(190); profileNameBox:SetHeight(24); profileNameBox:SetPoint("BOTTOMLEFT",profileFrame,"BOTTOMLEFT",24,52)
        profileNameBox:SetAutoFocus(false); profileNameBox:SetMaxLetters(32); profileNameBox:SetScript("OnEscapePressed",function() profileNameBox:ClearFocus() end)
        local create=api.CreateFrame("Button",nil,profileFrame,"UIPanelButtonTemplate")
        create:SetWidth(80); create:SetHeight(24); create:SetPoint("LEFT",profileNameBox,"RIGHT",8,0); create:SetText("Create")
        create:SetScript("OnClick",function()
          local name=profileNameBox:GetText() or ""
          local id,reason=callbacks.createProfile and callbacks.createProfile(name)
          if id then profileNameBox:SetText("") else self:Print("Profile creation failed: "..tostring(reason)) end
          self:ShowProfiles(callbacks)
        end)
        local duplicate=api.CreateFrame("Button",nil,profileFrame,"UIPanelButtonTemplate")
        duplicate:SetWidth(90); duplicate:SetHeight(24); duplicate:SetPoint("LEFT",create,"RIGHT",8,0); duplicate:SetText("Duplicate")
        duplicate:SetScript("OnClick",function()
          local name=profileNameBox:GetText() or ""
          local id,reason=callbacks.duplicateProfile and callbacks.duplicateProfile(name)
          if id then profileNameBox:SetText("") else self:Print("Profile copy failed: "..tostring(reason)) end
          self:ShowProfiles(callbacks)
        end)
        local rename=api.CreateFrame("Button",nil,profileFrame,"UIPanelButtonTemplate")
        rename:SetWidth(90); rename:SetHeight(24); rename:SetPoint("BOTTOMLEFT",profileFrame,"BOTTOMLEFT",24,16); rename:SetText("Rename active")
        rename:SetScript("OnClick",function()
          local name=profileNameBox:GetText() or ""
          local renamed,reason=callbacks.renameActiveProfile and callbacks.renameActiveProfile(name)
          self:Print(renamed and "Profile renamed." or ("Rename failed: "..tostring(reason or "DEFAULT_PROFILE_PROTECTED")))
          self:ShowProfiles(callbacks)
        end)
        local function confirmAction(action)
          if type(api.StaticPopup_Show)~="function" then
            self:Print("Confirmation dialog unavailable; use /djw profile "..action.." <profileID>.")
            return
          end
          api.StaticPopupDialogs=api.StaticPopupDialogs or {}
          api.StaticPopupDialogs.DEJUNKWOTLK_PROFILE_CONFIRM={
            text="Are you sure you want to %s profile %s?",
            button1=api.YES or "Yes",button2=api.NO or "No",timeout=0,whileDead=1,hideOnEscape=1,
            OnAccept=function(dialog)
              local acceptedAction=dialog.data
              local changed,reason
              if acceptedAction=="reset" then changed,reason=callbacks.resetActiveProfile and callbacks.resetActiveProfile()
              else changed,reason=callbacks.deleteActiveProfile and callbacks.deleteActiveProfile() end
              self:Print(changed and (acceptedAction=="reset" and "Profile reset." or "Profile deleted.") or
                ((acceptedAction=="reset" and "Reset" or "Delete").." failed: "..tostring(reason or "DEFAULT_PROFILE_PROTECTED")))
              self:ShowProfiles(callbacks)
            end
          }
          api.StaticPopup_Show("DEJUNKWOTLK_PROFILE_CONFIRM",action,callbacks.activeProfileName and callbacks.activeProfileName() or "active",action)
        end
        local reset=api.CreateFrame("Button",nil,profileFrame,"UIPanelButtonTemplate")
        reset:SetWidth(75); reset:SetHeight(24); reset:SetPoint("LEFT",rename,"RIGHT",6,0); reset:SetText("Reset")
        reset:SetScript("OnClick",function() confirmAction("reset") end)
        local delete=api.CreateFrame("Button",nil,profileFrame,"UIPanelButtonTemplate")
        delete:SetWidth(75); delete:SetHeight(24); delete:SetPoint("LEFT",reset,"RIGHT",6,0); delete:SetText("Delete")
        delete:SetScript("OnClick",function() confirmAction("delete") end)
        local back=api.CreateFrame("Button",nil,profileFrame,"UIPanelButtonTemplate")
        back:SetWidth(85); back:SetHeight(24); back:SetPoint("BOTTOMRIGHT",profileFrame,"BOTTOMRIGHT",-18,16); back:SetText("Back")
        back:SetScript("OnClick",function() profileFrame:Hide(); self:ShowConfig(callbacks) end)
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
      if callbacks.activeProfileName then profileNameBox:SetText(callbacks.activeProfileName()) end
      profileFrame:Show()
    end)
    if not ok then self:Print("Profiles window unavailable; use /djw profiles list|create|switch.") end
  end

  function runtime:ShowLists(callbacks)
    callbacks=callbacks or {}
    local ok=pcall(function()
      if not listFrame then
        listFrame=api.CreateFrame("Frame",nil,api.UIParent)
        listFrame:SetWidth(720); listFrame:SetHeight(500); listFrame:SetPoint("CENTER")
        listFrame:SetFrameStrata("DIALOG"); listFrame:EnableMouse(true)
        listFrame:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=32,insets={left=8,right=8,top=8,bottom=8}})
        local title=listFrame:CreateFontString(nil,"OVERLAY","GameFontNormal")
        title:SetPoint("TOPLEFT",20,-18); title:SetText("Dejunk-WotLK | Inclusion and exclusion lists")
        local close=api.CreateFrame("Button",nil,listFrame,"UIPanelCloseButton")
        close:SetPoint("TOPRIGHT",-4,-4); close:SetScript("OnClick",function() listFrame:Hide() end)
        listSearch=api.CreateFrame("EditBox",nil,listFrame,"InputBoxTemplate")
        listSearch:SetWidth(400); listSearch:SetHeight(24); listSearch:SetPoint("TOPLEFT",24,-50)
        listSearch:SetAutoFocus(false); listSearch:SetMaxLetters(64)
        listSearch:SetScript("OnEscapePressed",function() listSearch:ClearFocus() end)
        listSearch:SetScript("OnTextChanged",function() self:ShowLists(callbacks) end)
        local searchLabel=listFrame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        searchLabel:SetPoint("LEFT",listSearch,"RIGHT",10,0); searchLabel:SetText("Search by item name or ID")
        listScopeButton=api.CreateFrame("Button",nil,listFrame,"UIPanelButtonTemplate")
        listScopeButton:SetWidth(130); listScopeButton:SetHeight(24); listScopeButton:SetPoint("TOPLEFT",24,-86)
        listScopeButton:SetScript("OnClick",function()
          listScopeButton.scope=listScopeButton.scope=="global" and "profile" or "global"
          self:ShowLists(callbacks)
        end)
        listKindButton=api.CreateFrame("Button",nil,listFrame,"UIPanelButtonTemplate")
        listKindButton:SetWidth(150); listKindButton:SetHeight(24); listKindButton:SetPoint("LEFT",listScopeButton,"RIGHT",10,0)
        listKindButton:SetScript("OnClick",function()
          listKindButton.kind=listKindButton.kind=="inclusions" and "exclusions" or "inclusions"
          self:ShowLists(callbacks)
        end)
        listInput=api.CreateFrame("EditBox",nil,listFrame,"InputBoxTemplate")
        listInput:SetWidth(120); listInput:SetHeight(24); listInput:SetPoint("LEFT",listKindButton,"RIGHT",12,0)
        listInput:SetAutoFocus(false); listInput:SetNumeric(true); listInput:SetMaxLetters(10)
        listInput:SetScript("OnEscapePressed",function() listInput:ClearFocus() end)
        local function listButton(label,x,handler)
          local b=api.CreateFrame("Button",nil,listFrame,"UIPanelButtonTemplate")
          b:SetWidth(90); b:SetHeight(24); b:SetPoint("LEFT",listInput,"RIGHT",x,0); b:SetText(label); b:SetScript("OnClick",handler); return b
        end
        listButton("Add",8,function() self:EditList(callbacks,true) end)
        listButton("Remove",104,function() self:EditList(callbacks,false) end)
        listPanels={}
        local panes={
          {scope="global",kind="inclusions",title="Inclusions (Global)",x=22,y=-132},
          {scope="global",kind="exclusions",title="Exclusions (Global)",x=365,y=-132},
          {scope="profile",kind="inclusions",title="Inclusions (Profile)",x=22,y=-300},
          {scope="profile",kind="exclusions",title="Exclusions (Profile)",x=365,y=-300}
        }
        for _,pane in ipairs(panes) do
          local paneScope,paneKind=pane.scope,pane.kind
          local box=api.CreateFrame("Frame",nil,listFrame)
          box:SetWidth(325); box:SetHeight(155); box:SetPoint("TOPLEFT",listFrame,"TOPLEFT",pane.x,pane.y)
          box:EnableMouse(true); box:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=10,insets={left=3,right=3,top=3,bottom=3}})
          box:SetBackdropColor(0,0,0,0.65)
          local heading=box:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
          heading:SetPoint("TOPLEFT",8,-7); heading:SetText(pane.title)
          local empty=box:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
          empty:SetPoint("TOPLEFT",8,-30); empty:SetWidth(300); empty:SetJustifyH("LEFT")
          local rows={}
          for rowIndex=1,6 do
            local row=api.CreateFrame("Button",nil,box)
            row:SetWidth(300); row:SetHeight(19); row:SetPoint("TOPLEFT",8,-27-(rowIndex-1)*20)
            local icon=row:CreateTexture(nil,"ARTWORK")
            icon:SetWidth(16); icon:SetHeight(16); icon:SetPoint("LEFT",0,0)
            local label=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
            label:SetPoint("LEFT",icon,"RIGHT",5,0); label:SetWidth(275); label:SetJustifyH("LEFT")
            row.icon=icon; row.label=label; row:SetScript("OnClick",function()
              listScopeButton.scope=paneScope; listKindButton.kind=paneKind; listInput:SetText(row.itemId)
              listScopeButton:SetText("Scope: "..paneScope)
              listKindButton:SetText(paneKind=="inclusions" and "Inclusions" or "Exclusions")
            end)
            rows[#rows+1]=row
          end
          listPanels[#listPanels+1]={scope=pane.scope,kind=pane.kind,empty=empty,rows=rows}
        end
        local back=api.CreateFrame("Button",nil,listFrame,"UIPanelButtonTemplate")
        back:SetWidth(110); back:SetHeight(24); back:SetPoint("BOTTOMRIGHT",listFrame,"BOTTOMRIGHT",-20,18); back:SetText("Back")
        back:SetScript("OnClick",function() listFrame:Hide(); self:ShowConfig(callbacks) end)
        local export=api.CreateFrame("Button",nil,listFrame,"UIPanelButtonTemplate")
        export:SetWidth(90); export:SetHeight(24); export:SetPoint("BOTTOMLEFT",listFrame,"BOTTOMLEFT",22,18); export:SetText("Export")
        export:SetScript("OnClick",function()
          local scope=listScopeButton.scope or "global"; local kind=listKindButton.kind or "inclusions"
          local text=callbacks.listItems and callbacks.listItems(scope,kind) or ""
          self:ShowReport(text=="" and "List is empty." or text,"List export: "..scope.." "..kind,"lists")
        end)
        local import=api.CreateFrame("Button",nil,listFrame,"UIPanelButtonTemplate")
        import:SetWidth(90); import:SetHeight(24); import:SetPoint("LEFT",export,"RIGHT",8,0); import:SetText("Import")
        import:SetScript("OnClick",function()
          importScope=listScopeButton.scope or "global"; importKind=listKindButton.kind or "inclusions"
          self:ShowListImport(callbacks)
        end)
        listScopeButton.scope="global"; listKindButton.kind="inclusions"
      end
      local scope=listScopeButton.scope or "global"
      local kind=listKindButton.kind or "inclusions"
      listScopeButton:SetText("Scope: "..scope)
      listKindButton:SetText(kind=="inclusions" and "Inclusions" or "Exclusions")
      local query=(listSearch:GetText() or ""):lower()
      for _,pane in ipairs(listPanels) do
        local raw=callbacks.listItems and callbacks.listItems(pane.scope,pane.kind) or ""
        local nameResolver=query:find("%D") and function(id)
          if itemPresentationCache[id] and itemPresentationCache[id].name then return itemPresentationCache[id].name end
          if type(api.GetItemInfo)=="function" then
            local values={pcall(api.GetItemInfo,tonumber(id))}
            if values[1] and type(values[2])=="string" then
              itemPresentationCache[id]=itemPresentationCache[id] or {}
              itemPresentationCache[id].name=values[2]; itemPresentationCache[id].texture=values[11]
              return values[2]
            end
          end
        end or nil
        local filtered=Addon.Config.FilterItemIds(raw,query,nameResolver)
        local total=#filtered
        for index,row in ipairs(pane.rows) do
          local item=filtered[index]
          if item then
            local presentation=itemPresentationCache[item.id] or {}
            if not presentation.name and type(api.GetItemInfo)=="function" then
              local values={pcall(api.GetItemInfo,tonumber(item.id))}
              if values[1] and type(values[2])=="string" then presentation.name=values[2]; presentation.texture=values[11] end
              itemPresentationCache[item.id]=presentation
            end
            row.itemId=item.id; row.label:SetText((presentation.name or item.name or "Item").." (#"..item.id..")")
            if presentation.texture then row.icon:SetTexture(presentation.texture); row.icon:Show() else row.icon:Hide() end
            row:Show()
          else row:Hide() end
        end
        pane.empty:SetText(total==0 and (query=="" and "This list is empty." or "No matches.") or
          (total>6 and ("... "..(total-6).." more; search to narrow or use /djw lists show "..pane.scope.." "..pane.kind) or ""))
        if total==0 or total>6 then pane.empty:Show() else pane.empty:Hide() end
      end
      listFrame:Show()
    end)
    if not ok then self:Print("Lists window unavailable; use /djw lists show|add|remove <global|profile> <inclusions|exclusions> <itemID>.") end
  end

  function runtime:EditList(callbacks,present)
    local scope=listScopeButton and listScopeButton.scope or "global"
    local kind=listKindButton and listKindButton.kind or "inclusions"
    local id=listInput and listInput:GetText() or ""
    local ok,reason=callbacks.editItem and callbacks.editItem(scope,kind,id,present)
    self:Print(ok and "List updated." or ("List update failed: "..tostring(reason)))
    self:ShowLists(callbacks)
  end

  function runtime:ShowListImport(callbacks)
    callbacks=callbacks or {}
    local ok=pcall(function()
      if not importFrame then
        importFrame=api.CreateFrame("Frame",nil,api.UIParent)
        importFrame:SetWidth(560); importFrame:SetHeight(390); importFrame:SetPoint("CENTER")
        importFrame:SetFrameStrata("DIALOG"); importFrame:EnableMouse(true)
        importFrame:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=32,insets={left=8,right=8,top=8,bottom=8}})
        importTitle=importFrame:CreateFontString(nil,"OVERLAY","GameFontNormal")
        importTitle:SetPoint("TOPLEFT",20,-18)
        local close=api.CreateFrame("Button",nil,importFrame,"UIPanelCloseButton")
        close:SetPoint("TOPRIGHT",-4,-4); close:SetScript("OnClick",function() importFrame:Hide() end)
        local help=importFrame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        help:SetPoint("TOPLEFT",24,-48); help:SetWidth(500); help:SetJustifyH("LEFT")
        help:SetText("Paste item IDs separated by spaces, commas, semicolons or new lines.")
        local scroll=api.CreateFrame("ScrollFrame","DejunkWotLKListImportScroll",importFrame,"UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT",importFrame,"TOPLEFT",28,-82); scroll:SetPoint("BOTTOMRIGHT",importFrame,"BOTTOMRIGHT",-48,94)
        scroll:EnableMouse(true)
        scroll:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=12,insets={left=4,right=4,top=4,bottom=4}})
        scroll:SetBackdropColor(0,0,0,0.9)
        importEdit=api.CreateFrame("EditBox",nil,scroll)
        importEdit:SetMultiLine(true); importEdit:SetAutoFocus(false); importEdit:SetMaxLetters(65536)
        importEdit:SetPoint("TOPLEFT",scroll,"TOPLEFT",8,-8); importEdit:SetWidth(455); importEdit:SetHeight(215)
        importEdit:SetFontObject(api.ChatFontNormal); importEdit:SetTextColor(1,1,1,1); importEdit:SetTextInsets(2,2,2,2)
        importEdit:EnableMouse(true); importEdit:EnableKeyboard(true)
        importEdit:SetScript("OnMouseDown",function() importEdit:SetFocus() end)
        importEdit:SetScript("OnEscapePressed",function() importEdit:ClearFocus() end)
        importEdit:SetScript("OnTextChanged",function()
          importPreview=nil
          if importCommitButton then importCommitButton:Disable() end
          if importStatus then importStatus:SetText("Review the IDs before importing.") end
        end)
        scroll:SetScrollChild(importEdit)
        importStatus=importFrame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        importStatus:SetPoint("BOTTOMLEFT",24,48); importStatus:SetWidth(360); importStatus:SetJustifyH("LEFT")
        local review=api.CreateFrame("Button",nil,importFrame,"UIPanelButtonTemplate")
        review:SetWidth(100); review:SetHeight(24); review:SetPoint("BOTTOMLEFT",importFrame,"BOTTOMLEFT",22,16); review:SetText("Review")
        review:SetScript("OnClick",function()
          local text=importEdit:GetText() or ""
          local preview,reason=callbacks.previewListImport and callbacks.previewListImport(importScope,importKind,text)
          if not preview then
            importPreview=nil; importCommitButton:Disable(); importStatus:SetText("Import rejected: "..tostring(reason))
          else
            importPreview=preview; importCommitButton:Enable()
            importStatus:SetText("Ready: "..#preview.add.." new IDs; "..#preview.existing.." already present.")
          end
        end)
        importCommitButton=api.CreateFrame("Button",nil,importFrame,"UIPanelButtonTemplate")
        importCommitButton:SetWidth(100); importCommitButton:SetHeight(24); importCommitButton:SetPoint("LEFT",review,"RIGHT",8,0); importCommitButton:SetText("Import")
        importCommitButton:Disable()
        importCommitButton:SetScript("OnClick",function()
          local committed,reason=callbacks.commitListImport and callbacks.commitListImport(importPreview)
          if committed then
            importStatus:SetText("Import complete."); importCommitButton:Disable(); importPreview=nil
            importEdit:SetText(""); importFrame:Hide(); self:ShowLists(callbacks)
          else importStatus:SetText("Import failed: "..tostring(reason)); importCommitButton:Disable(); importPreview=nil end
        end)
        local cancel=api.CreateFrame("Button",nil,importFrame,"UIPanelButtonTemplate")
        cancel:SetWidth(100); cancel:SetHeight(24); cancel:SetPoint("BOTTOMRIGHT",importFrame,"BOTTOMRIGHT",-20,16); cancel:SetText("Cancel")
        cancel:SetScript("OnClick",function() importFrame:Hide(); if listFrame then listFrame:Show() end end)
        close:SetScript("OnClick",function() importFrame:Hide(); if listFrame then listFrame:Show() end end)
      end
      importPreview=nil; importCommitButton:Disable()
      importEdit:SetText(""); importStatus:SetText("Review the IDs before importing.")
      local scope=importScope or "global"; local kind=importKind or "inclusions"
      local titleText="Import into "..scope.." "..kind
      -- The title region is the first FontString child created by this panel.
      importTitle:SetText(titleText)
      if listFrame then listFrame:Hide() end
      importFrame:Show(); importEdit:SetFocus()
    end)
    if not ok then self:Print("Import window unavailable; use /djw lists import <global|profile> <inclusions|exclusions> <IDs>.") end
  end

  function runtime:ShowRules(callbacks)
    callbacks=callbacks or {}
    local activeId=callbacks.activeProfileId and callbacks.activeProfileId() or nil
    if #ruleDraftPredicates>0 and ruleDraftProfileId and activeId and ruleDraftProfileId~=activeId then
      ruleDraftPredicates={}; ruleDraftProfileId=nil
      self:Print("Unsaved rule draft cleared because the active profile changed.")
    end
    local ok=pcall(function()
      if not rulesFrame then
        rulesFrame=api.CreateFrame("Frame",nil,api.UIParent)
        rulesFrame:SetWidth(540); rulesFrame:SetHeight(480); rulesFrame:SetPoint("CENTER")
        rulesFrame:SetFrameStrata("DIALOG"); rulesFrame:EnableMouse(true)
        rulesFrame:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=32,insets={left=8,right=8,top=8,bottom=8}})
        local title=rulesFrame:CreateFontString(nil,"OVERLAY","GameFontNormal")
        title:SetPoint("TOPLEFT",20,-18); title:SetText("Dejunk-WotLK | Custom rules")
        local help=rulesFrame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        help:SetPoint("TOPLEFT",24,-40); help:SetText("Add conditions, then Add rule. ALL=every condition; ANY=one condition.")
        local close=api.CreateFrame("Button",nil,rulesFrame,"UIPanelCloseButton")
        close:SetPoint("TOPRIGHT",-4,-4); close:SetScript("OnClick",function() rulesFrame:Hide() end)
        ruleScopeButton=api.CreateFrame("Button",nil,rulesFrame,"UIPanelButtonTemplate")
        ruleScopeButton:SetWidth(135); ruleScopeButton:SetHeight(24); ruleScopeButton:SetPoint("TOPLEFT",24,-62)
        ruleScopeButton:SetScript("OnClick",function()
          local order={"SELL","DESTROY","BOTH"}; local current=ruleScopeButton.value or "SELL"
          for i,v in ipairs(order) do if v==current then ruleScopeButton.value=order[i%#order+1]; break end end
          self:UpdateRules(callbacks)
        end)
        ruleResultButton=api.CreateFrame("Button",nil,rulesFrame,"UIPanelButtonTemplate")
        ruleResultButton:SetWidth(135); ruleResultButton:SetHeight(24); ruleResultButton:SetPoint("LEFT",ruleScopeButton,"RIGHT",10,0)
        ruleResultButton:SetScript("OnClick",function() ruleResultButton.value=ruleResultButton.value=="JUNK" and "KEEP" or "JUNK"; self:UpdateRules(callbacks) end)
        ruleFieldButton=api.CreateFrame("Button",nil,rulesFrame,"UIPanelButtonTemplate")
        ruleFieldButton:SetWidth(170); ruleFieldButton:SetHeight(24); ruleFieldButton:SetPoint("TOPLEFT",24,-100)
        ruleFieldButton:SetScript("OnClick",function()
          local order={"itemId","quality","itemLevel","unitVendorPrice","count"}; local current=ruleFieldButton.value or order[1]
          for i,v in ipairs(order) do if v==current then ruleFieldButton.value=order[i%#order+1]; break end end
          self:UpdateRules(callbacks)
        end)
        ruleOpButton=api.CreateFrame("Button",nil,rulesFrame,"UIPanelButtonTemplate")
        ruleOpButton:SetWidth(95); ruleOpButton:SetHeight(24); ruleOpButton:SetPoint("LEFT",ruleFieldButton,"RIGHT",10,0)
        ruleOpButton:SetScript("OnClick",function()
          local order={"EQ","LT","GT"}; local current=ruleOpButton.value or order[1]
          for i,v in ipairs(order) do if v==current then ruleOpButton.value=order[i%#order+1]; break end end
          self:UpdateRules(callbacks)
        end)
        ruleGroupButton=api.CreateFrame("Button",nil,rulesFrame,"UIPanelButtonTemplate")
        ruleGroupButton:SetWidth(120); ruleGroupButton:SetHeight(24); ruleGroupButton:SetPoint("LEFT",ruleOpButton,"RIGHT",8,0)
        ruleGroupButton:SetScript("OnClick",function()
          ruleGroupButton.value=ruleGroupButton.value=="ALL" and "ANY" or "ALL"
          self:UpdateRules(callbacks)
        end)
        local idLabel=rulesFrame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        idLabel:SetPoint("TOPLEFT",28,-129); idLabel:SetText("Rule ID (also used for removal)")
        local valueLabel=rulesFrame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        valueLabel:SetPoint("TOPLEFT",206,-129); valueLabel:SetText("Number")
        ruleIdInput=api.CreateFrame("EditBox",nil,rulesFrame,"InputBoxTemplate")
        ruleIdInput:SetWidth(150); ruleIdInput:SetHeight(24); ruleIdInput:SetPoint("TOPLEFT",26,-150)
        ruleIdInput:SetAutoFocus(false); ruleIdInput:SetMaxLetters(32)
        ruleValueInput=api.CreateFrame("EditBox",nil,rulesFrame,"InputBoxTemplate")
        ruleValueInput:SetWidth(110); ruleValueInput:SetHeight(24); ruleValueInput:SetPoint("LEFT",ruleIdInput,"RIGHT",18,0)
        ruleValueInput:SetAutoFocus(false); ruleValueInput:SetNumeric(true); ruleValueInput:SetMaxLetters(10)
        local addCondition=api.CreateFrame("Button",nil,rulesFrame,"UIPanelButtonTemplate")
        addCondition:SetWidth(120); addCondition:SetHeight(24); addCondition:SetPoint("LEFT",ruleValueInput,"RIGHT",12,0); addCondition:SetText("Add condition")
        addCondition:SetScript("OnClick",function()
          local value=tonumber(ruleValueInput:GetText())
          if not value or value<0 or value>2147483647 or value~=math.floor(value) or
              (ruleFieldButton.value=="quality" and value>7) then
            self:Print("Condition needs a valid whole number."); return
          end
          if #ruleDraftPredicates>=10 then self:Print("A rule can have at most 10 conditions."); return end
          ruleDraftProfileId=ruleDraftProfileId or (callbacks.activeProfileId and callbacks.activeProfileId())
          ruleDraftPredicates[#ruleDraftPredicates+1]={field=ruleFieldButton.value,op=ruleOpButton.value,value=value}
          ruleValueInput:SetText("")
          self:UpdateRules(callbacks)
        end)
        local addRule=api.CreateFrame("Button",nil,rulesFrame,"UIPanelButtonTemplate")
        addRule:SetWidth(105); addRule:SetHeight(24); addRule:SetPoint("BOTTOMLEFT",rulesFrame,"BOTTOMLEFT",249,18); addRule:SetText("Add rule")
        addRule:SetScript("OnClick",function()
          local currentProfileId=callbacks.activeProfileId and callbacks.activeProfileId() or nil
          if #ruleDraftPredicates>0 and ruleDraftProfileId and currentProfileId and ruleDraftProfileId~=currentProfileId then
            ruleDraftPredicates={}; ruleDraftProfileId=nil
            self:Print("Rule draft discarded because the active profile changed.")
            self:UpdateRules(callbacks)
            return
          end
          local predicates={}
          for _,predicate in ipairs(ruleDraftPredicates) do predicates[#predicates+1]=predicate end
          if #predicates==0 then
            local value=tonumber(ruleValueInput:GetText())
            if value and value>=0 and value<=2147483647 and value==math.floor(value) and
                (ruleFieldButton.value~="quality" or value<=7) then
              predicates[1]={field=ruleFieldButton.value,op=ruleOpButton.value,value=value}
            else self:Print("Add a condition with a valid whole number first."); return end
          end
          local group={id=ruleIdInput:GetText(),scope=ruleScopeButton.value,result=ruleResultButton.value,
            match=ruleGroupButton.value,predicates=predicates}
          local added,reason=callbacks.addRule and callbacks.addRule(group)
          if added then
            ruleDraftPredicates={}; ruleDraftProfileId=nil; ruleIdInput:SetText(""); ruleValueInput:SetText("")
            self:Print("Custom rule added.")
          else self:Print("Rule add failed: "..tostring(reason or "INVALID_RULE")) end
          self:UpdateRules(callbacks)
        end)
        rulesSummary=rulesFrame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        rulesSummary:SetPoint("TOPLEFT",26,-190); rulesSummary:SetWidth(480); rulesSummary:SetJustifyH("LEFT")
        local remove=api.CreateFrame("Button",nil,rulesFrame,"UIPanelButtonTemplate")
        remove:SetWidth(100); remove:SetHeight(24); remove:SetPoint("BOTTOMLEFT",rulesFrame,"BOTTOMLEFT",24,18); remove:SetText("Remove ID")
        ruleIdInput:SetScript("OnTextChanged",function()
          if (ruleIdInput:GetText() or "")=="" then remove:Disable() else remove:Enable() end
        end)
        remove:Disable()
        remove:SetScript("OnClick",function()
          local id=ruleIdInput:GetText(); local removed,reason=callbacks.removeRule and callbacks.removeRule(id)
          if removed then
            ruleIdInput:SetText("")
            self:Print("Custom rule removed.")
          else
            self:Print("Rule remove failed: "..tostring(reason or "UNKNOWN_RULE"))
          end
          self:UpdateRules(callbacks)
        end)
        local clearDraft=api.CreateFrame("Button",nil,rulesFrame,"UIPanelButtonTemplate")
        clearDraft:SetWidth(105); clearDraft:SetHeight(24); clearDraft:SetPoint("LEFT",remove,"RIGHT",8,0); clearDraft:SetText("Clear draft")
        clearDraft:SetScript("OnClick",function() ruleDraftPredicates={}; ruleDraftProfileId=nil; self:UpdateRules(callbacks) end)
        local back=api.CreateFrame("Button",nil,rulesFrame,"UIPanelButtonTemplate")
        back:SetWidth(100); back:SetHeight(24); back:SetPoint("BOTTOMRIGHT",rulesFrame,"BOTTOMRIGHT",-20,18); back:SetText("Back")
        back:SetScript("OnClick",function() rulesFrame:Hide(); self:ShowConfig(callbacks) end)
        ruleScopeButton.value="SELL"; ruleResultButton.value="JUNK"; ruleFieldButton.value="quality"
        ruleOpButton.value="EQ"; ruleGroupButton.value="ALL"
      end
      self:UpdateRules(callbacks)
      rulesFrame:Show()
    end)
    if not ok then self:Print("Rules window unavailable; use /djw rules list|add|remove.") end
  end

  function runtime:UpdateRules(callbacks)
    ruleScopeButton:SetText("Action: "..ruleScopeButton.value)
    ruleResultButton:SetText("Result: "..ruleResultButton.value)
    ruleFieldButton:SetText("Field: "..ruleFieldButton.value)
    ruleOpButton:SetText("Operator: "..ruleOpButton.value)
    ruleGroupButton:SetText("Group: "..ruleGroupButton.value)
    local rules=callbacks.listRules and callbacks.listRules() or {}
    local profileName=callbacks.activeProfileName and callbacks.activeProfileName() or "unknown"
    local lines={"Rules for active profile: "..tostring(profileName)}
    for i,rule in ipairs(rules) do
      if i>5 then lines[#lines+1]="... use /djw rules list for remaining rules"; break end
      local predicates={}
      for _,predicate in ipairs(rule.predicates or {}) do
        predicates[#predicates+1]=tostring(predicate.field).." "..tostring(predicate.op).." "..tostring(predicate.value)
      end
      local joiner=rule.match=="ANY" and " OR " or " AND "
      lines[#lines+1]=rule.id.." | "..rule.scope.." | "..rule.result.." | "..table.concat(predicates,joiner)
    end
    if #rules==0 then lines[#lines+1]="No custom rules yet." end
    if #ruleDraftPredicates>0 then
      local draft={}
      for _,predicate in ipairs(ruleDraftPredicates) do
        draft[#draft+1]=predicate.field.." "..predicate.op.." "..predicate.value
      end
      lines[#lines+1]="Draft ("..ruleGroupButton.value.."): "..table.concat(draft,"; ")
    end
    rulesSummary:SetText(table.concat(lines,"\n"))
  end

  function runtime:ShowOptions(callbacks)
    callbacks=callbacks or {}
    local ok=pcall(function()
      if not optionsFrame then
        optionsFrame=api.CreateFrame("Frame",nil,api.UIParent)
        optionsFrame:SetWidth(560); optionsFrame:SetHeight(420); optionsFrame:SetPoint("CENTER")
        optionsFrame:SetFrameStrata("DIALOG"); optionsFrame:EnableMouse(true)
        optionsFrame:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=32,insets={left=8,right=8,top=8,bottom=8}})
        local title=optionsFrame:CreateFontString(nil,"OVERLAY","GameFontNormal")
        title:SetPoint("TOPLEFT",20,-18); title:SetText("Dejunk-WotLK | Quality and thresholds")
        local close=api.CreateFrame("Button",nil,optionsFrame,"UIPanelCloseButton")
        close:SetPoint("TOPRIGHT",-4,-4); close:SetScript("OnClick",function() optionsFrame:Hide() end)
        local qualityTitle=optionsFrame:CreateFontString(nil,"OVERLAY","GameFontHighlight")
        qualityTitle:SetPoint("TOPLEFT",24,-52); qualityTitle:SetText("Click a quality to toggle its rule:")
        local labels={"Poor","Common","Uncommon","Rare","Epic","Legendary","Artifact","Heirloom"}
        optionsQualityButtons={}
        for quality=0,7 do
          local b=api.CreateFrame("Button",nil,optionsFrame,"UIPanelButtonTemplate")
          b:SetWidth(120); b:SetHeight(24)
          local col=quality%4; local row=math.floor(quality/4)
          b:SetPoint("TOPLEFT",24+col*128,-78-row*32)
          b:SetScript("OnClick",function()
            local opts=callbacks.options and callbacks.options() or {}; local enabled=not (opts.quality or {})[quality]
            local changed,reason=callbacks.setOption and callbacks.setOption("quality",{quality=quality,enabled=enabled})
            self:Print(changed and (labels[quality+1].." quality rule "..(enabled and "enabled." or "disabled.")) or ("Rule update failed: "..tostring(reason)))
            self:ShowOptions(callbacks)
          end)
          optionsQualityButtons[quality+1]=b
        end
        optionsFields={}
        local rows={
          {key="minItemLevel",label="Minimum item level"},
          {key="maxItemLevel",label="Maximum item level"},
          {key="maxStackVendorPrice",label="Maximum stack vendor value (copper)"}
        }
        for index,row in ipairs(rows) do
          local y=-160-(index-1)*48
          local label=optionsFrame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
          label:SetPoint("TOPLEFT",26,y); label:SetText(row.label)
          local input=api.CreateFrame("EditBox",nil,optionsFrame,"InputBoxTemplate")
          input:SetWidth(110); input:SetHeight(24); input:SetPoint("TOPLEFT",300,y+5)
          input:SetAutoFocus(false); input:SetMaxLetters(10)
          local apply=api.CreateFrame("Button",nil,optionsFrame,"UIPanelButtonTemplate")
          apply:SetWidth(90); apply:SetHeight(24); apply:SetPoint("LEFT",input,"RIGHT",10,0); apply:SetText("Apply")
          apply:SetScript("OnClick",function()
            local raw=(input:GetText() or ""):lower(); local value=raw=="off" and nil or tonumber(raw)
            local valid=raw=="off" or (value and value>=0 and value<=2147483647 and value==math.floor(value))
            local changed,reason=false,"INVALID_OPTION"
            if valid and callbacks.setOption then changed,reason=callbacks.setOption(row.key,value) end
            self:Print(changed and (row.label.." updated.") or ("Setting update failed: "..tostring(reason)))
            self:ShowOptions(callbacks)
          end)
          optionsFields[index]={key=row.key,input=input}
        end
        local back=api.CreateFrame("Button",nil,optionsFrame,"UIPanelButtonTemplate")
        back:SetWidth(110); back:SetHeight(24); back:SetPoint("BOTTOMRIGHT",optionsFrame,"BOTTOMRIGHT",-20,18); back:SetText("Back")
        back:SetScript("OnClick",function() optionsFrame:Hide(); self:ShowConfig(callbacks) end)
      end
      local opts=callbacks.options and callbacks.options() or {}
      local labels={"Poor","Common","Uncommon","Rare","Epic","Legendary","Artifact","Heirloom"}
      for quality=0,7 do
        local enabled=opts.quality and opts.quality[quality]
        optionsQualityButtons[quality+1]:SetText(labels[quality+1]..": "..(enabled and "ON" or "OFF"))
      end
      for _,entry in ipairs(optionsFields) do entry.input:SetText(tostring(opts[entry.key] or "off")) end
      optionsFrame:Show()
    end)
    if not ok then self:Print("Options window unavailable; use /djw rules list and /djw rules quality|minlevel|maxlevel|maxprice.") end
  end

  -- A diagnostic copy panel, not the configuration UI planned for Phase 6.
  function runtime:CloseReport()
    if reportFrame then reportFrame:Hide() end
    if reportReturnTarget=="lists" and listFrame then listFrame:Show()
    elseif reportReturnTarget=="config" and configFrame then configFrame:Show() end
    reportReturnTarget=nil
  end

  function runtime:ShowReport(text,titleText,returnTarget)
    local ok = pcall(function()
      if not reportFrame then
        local panel = api.CreateFrame("Frame", "DejunkWotLKReadOnlyReport", api.UIParent)
        panel:SetWidth(600); panel:SetHeight(420); panel:SetPoint("CENTER")
        panel:SetFrameStrata("DIALOG"); panel:EnableMouse(true)
        panel:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 8, right = 8, top = 8, bottom = 8 } })
        local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", 20, -18)
        reportTitle=title
        local close = api.CreateFrame("Button", nil, panel, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -4, -4)
        close:SetScript("OnClick", function() self:CloseReport() end)
        local scroll = api.CreateFrame("ScrollFrame", "DejunkWotLKReadOnlyReportScroll", panel, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 20, -45); scroll:SetPoint("BOTTOMRIGHT", -40, 20)
        local edit = api.CreateFrame("EditBox", nil, scroll)
        edit:SetMultiLine(true); edit:SetAutoFocus(false); edit:SetFontObject(api.ChatFontNormal)
        edit:SetWidth(530); edit:SetHeight(340)
        edit:SetScript("OnEscapePressed", function() self:CloseReport() end)
        scroll:SetScrollChild(edit)
        reportFrame, reportEdit = panel, edit
      end
      local _, newlines = text:gsub("\n", "")
      reportReturnTarget=returnTarget
      if returnTarget=="lists" and listFrame then listFrame:Hide()
      elseif returnTarget=="config" and configFrame then configFrame:Hide() end
      reportTitle:SetText((titleText or "Dejunk-WotLK diagnostics").." | Ctrl+A, Ctrl+C to copy | Escape to close")
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
