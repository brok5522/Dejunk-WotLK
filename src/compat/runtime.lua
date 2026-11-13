local _, Addon = ...
local Runtime = {}
Addon.Runtime = Runtime

-- All interaction with WoW globals, frames and commands stays in this module.
function Runtime.New(environment)
  local api = environment or _G
  local runtime = { registration = {} }
  local theme={blue={79/255,175/255,227/255},grey={157/255,157/255,157/255},white={1,1,1},dark={30/255,30/255,30/255},gold={1,209/255,0},black={0,0,0}}
  local function setTextColor(region,color)
    if region and region.SetTextColor and theme[color] then region:SetTextColor(theme[color][1],theme[color][2],theme[color][3],1) end
  end
  local function raiseForMouseInput(frame,offset)
    if not frame or type(frame.GetParent)~="function" or type(frame.SetFrameLevel)~="function" then return end
    local parent=frame:GetParent()
    if not parent or type(parent.GetFrameLevel)~="function" then return end
    local level=parent:GetFrameLevel()
    if type(level)=="number" then frame:SetFrameLevel(level+(offset or 10)) end
  end
  local function styleThemedButton(button,label)
    button:EnableMouse(true)
    if type(button.RegisterForClicks)=="function" then button:RegisterForClicks("LeftButtonUp") end
    raiseForMouseInput(button,10)
    button:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
    local text=button:CreateFontString(nil,"ARTWORK","GameFontNormal")
    text:SetPoint("LEFT",7,0); text:SetPoint("RIGHT",-7,0); text:SetJustifyH("CENTER")
    button.labelRegion=text
    button.SetText=function(self,value) self.text=value; text:SetText(value) end
    button:SetText(label or "")
    local function refresh(hovered)
      button:SetBackdropColor(theme.dark[1],theme.dark[2],theme.dark[3],hovered and 0.95 or 0.75)
      button:SetBackdropBorderColor(0,0,0,1)
      setTextColor(text,hovered and "white" or "gold")
    end
    button:SetScript("OnEnter",function() refresh(true) end)
    button:SetScript("OnLeave",function() refresh(false) end)
    refresh(false)
    return button
  end
  local function styleCloseButton(button)
    button:EnableMouse(true)
    if type(button.RegisterForClicks)=="function" then button:RegisterForClicks("LeftButtonUp") end
    raiseForMouseInput(button,10)
    button:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8"})
    local text=button:CreateFontString(nil,"ARTWORK","GameFontNormal")
    text:SetPoint("CENTER"); text:SetText("X")
    button.text="X"; button.labelRegion=text
    local function refresh(hovered)
      button:SetBackdropColor(227/255,79/255,79/255,hovered and 0.75 or 0)
      button:SetBackdropBorderColor(0,0,0,0)
      setTextColor(text,hovered and "white" or "grey")
    end
    button:SetScript("OnEnter",function() refresh(true) end)
    button:SetScript("OnLeave",function() refresh(false) end)
    refresh(false)
    return button
  end
  local function createReadOnlyItemCard(parent,width,height,y)
    local card=api.CreateFrame("Frame",nil,parent)
    card:SetWidth(width); card:SetHeight(height); card:SetPoint("TOPLEFT",10,-y)
    card:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8"}); card:SetBackdropColor(1,1,1,0.035)
    local accent=card:CreateTexture(nil,"ARTWORK")
    accent:SetTexture("Interface\\Buttons\\WHITE8x8"); accent:SetWidth(3); accent:SetPoint("TOPLEFT"); accent:SetPoint("BOTTOMLEFT")
    local icon=card:CreateTexture(nil,"ARTWORK")
    icon:SetWidth(32); icon:SetHeight(32); icon:SetPoint("LEFT",9,0)
    local label=card:CreateFontString(nil,"ARTWORK","GameFontNormalSmall")
    label:SetPoint("TOPLEFT",icon,"TOPRIGHT",8,-4); label:SetWidth(width-64); label:SetJustifyH("LEFT")
    local detail=card:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
    detail:SetPoint("TOPLEFT",label,"BOTTOMLEFT",0,-2); detail:SetWidth(width-64); detail:SetJustifyH("LEFT")
    card.icon,card.accent,card.label,card.detail=icon,accent,label,detail
    return card
  end
  local frame, update, scanTooltip, reportFrame, reportEdit, reportTitle, configFrame, configSummary, poorButton
  local optionsCategoryFrame,optionsCategoryButtons
  local bagTooltipHooked=false
  local minimapButton,minimapAngle,minimapSetGlobalOption,minimapOpenConfig,minimapGetGlobalOptions
  local junkFrame,junkTitle,junkSummary,junkScroll,junkRows,junkRowsContent,junkEmptyRow,junkVisible
  local lootableFrame,lootableTitle,lootableSummary,lootableScroll,lootableRows,lootableRowsContent,lootableEmptyRow,lootableVisible
  local configWaffleRoot
  local configContentComponent,configOverviewComponent,mainContentFrame
  local optionsPageComponent,profilePageComponent,listPageComponent
  local configScreens,selectedConfigScreen={},nil
  local mainWindowVisible=false
  local getWindowPoint,saveWindowPoint
  local configNavButtons={}
  local optionsOptionCards,optionsCardDividers,optionsQualityRows,optionsResponsiveDescriptions
  local optionsGlobalControls,optionsGlobalChoices
  local profileFrame,profileSummary,profileList,profileButtons,profileScroll
  local profileWaffleRoot,listsWaffleRoot,importWaffleRoot,optionsWaffleRoot,reportWaffleRoot
  local listFrame,listSummary,listInput,listScopeButton,listKindButton,listSearch,listSearchPlaceholder,listSearchClear,listPanels
  local importFrame,importTitle,importHelp,importEdit,importStatus,importCommitButton,importReviewButton,importSelectButton,importCancelButton,importPreview,importScope,importKind
  local reportReturnTarget
  local rulesFrame,rulesSummary,ruleIdInput,ruleValueInput,ruleScopeButton,ruleResultButton,ruleFieldButton,ruleOpButton,ruleGroupButton
  local ruleDraftPredicates,ruleDraftProfileId={},nil
  local optionsFrame,optionsContentFrame,optionsScrollFrame,optionsProfileDecorations,optionsGlobalDecorations,optionsQualityButtons,optionsFields,optionsThresholdFields,optionsScopeFields,optionsEnableFields,optionsUnboundQualityFields,optionsEquipmentTypeFields
  local optionsCallbacks
  local readingTooltip = false
  local itemPresentationCache={}
  local listMetadataIds,listMetadataSignature,listMetadataCursor={},nil,1
  local listMetadataElapsed,listMetadataAge=0,0

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
    for _, name in ipairs({ "ITEM_SOULBOUND", "ITEM_BIND_TO_ACCOUNT", "ITEM_BIND_ON_EQUIP", "ITEM_BIND_ON_USE",
      "GetAuctionItemClasses", "GetAuctionItemSubClasses" }) do
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
    api.SLASH_DEJUNK1 = "/dejunk"
    api.SlashCmdList.DEJUNK = function(input)
      local command=type(input)=="string" and input:match("^%s*(%S*)") or ""
      if command=="" or command:lower()=="options" then callback("toggle-config")
      elseif command:lower()=="profiles" then callback("open-profiles")
      else callback(input) end
    end
  end
  function runtime:RegisterOptionsCategory(onOpen)
    if optionsCategoryFrame then return true end
    if type(api.InterfaceOptions_AddCategory)~="function" or type(api.CreateFrame)~="function" then return false,"OPTIONS_CATEGORY_UNAVAILABLE" end
    local ok,panel=pcall(api.CreateFrame,"Frame","DejunkWotLKOptionsCategory",api.UIParent)
    if not ok or not panel then return false,"OPTIONS_CATEGORY_FRAME_FAILED" end
    optionsCategoryFrame=panel; optionsCategoryButtons={}
    panel.name="Dejunk"
    panel:SetWidth(650); panel:SetHeight(260)
    local title=panel:CreateFontString(nil,"ARTWORK","GameFontNormalLarge")
    title:SetPoint("TOPLEFT",16,-16); title:SetText("Dejunk"); setTextColor(title,"blue")
    local description=panel:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
    description:SetPoint("TOPLEFT",title,"BOTTOMLEFT",0,-10)
    description:SetText("Open Dejunk settings and profile management.")
    local function addButton(label,y,screen)
      local button=styleThemedButton(api.CreateFrame("Button",nil,panel),label)
      button:SetWidth(250); button:SetHeight(30); button:SetPoint("TOPLEFT",16,y)
      button:SetScript("OnClick",function() if type(onOpen)=="function" then onOpen(screen) end end)
      optionsCategoryButtons[#optionsCategoryButtons+1]=button
    end
    addButton("Open Dejunk",-72,"main")
    addButton("Open Profiles",-112,"profiles")
    local added,reason=pcall(api.InterfaceOptions_AddCategory,panel)
    if not added then optionsCategoryFrame=nil; return false,tostring(reason) end
    return true
  end
  function runtime:GetOptionsCategory() return optionsCategoryFrame end
  function runtime:SetWindowPointHandlers(getter,saver)
    getWindowPoint=type(getter)=="function" and getter or nil
    saveWindowPoint=type(saver)=="function" and saver or nil
  end
  local function setSavedPoint(target,key)
    local point=type(getWindowPoint)=="function" and getWindowPoint(key) or nil
    target:ClearAllPoints()
    if type(point)=="table" then
      target:SetPoint(point.point or "CENTER",api.UIParent,point.relativePoint or "CENTER",point.offsetX or 0,point.offsetY or 0)
    else target:SetPoint("CENTER",api.UIParent,"CENTER",0,0) end
  end
  local function saveCurrentPoint(target,key)
    if type(saveWindowPoint)~="function" or type(target.GetPoint)~="function" then return end
    local point,relativeTo,relativePoint,x,y=target:GetPoint(1)
    if not point or type(x)~="number" or type(y)~="number" then return end
    saveWindowPoint(key,{point=point,relativeTo=relativeTo==api.UIParent and "UIParent" or nil,
      relativePoint=relativePoint or point,offsetX=x,offsetY=y})
  end
  local function normalizeAngle(value)
    value=tonumber(value) or 220
    value=value%360
    if value<0 then value=value+360 end
    return value
  end
  local function positionMinimapButton()
    if not minimapButton or not api.Minimap then return end
    local angle=math.rad(minimapAngle or 220)
    local radius=80
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER",api.Minimap,"CENTER",math.cos(angle)*radius,math.sin(angle)*radius)
  end
  function runtime:UpdateMinimapIcon(globalOptions,setGlobalOption,openConfig,getGlobalOptions)
    if type(api.CreateFrame)~="function" or not api.Minimap then return false,"MINIMAP_UNAVAILABLE" end
    globalOptions=type(globalOptions)=="table" and globalOptions or {}
    minimapSetGlobalOption=type(setGlobalOption)=="function" and setGlobalOption or minimapSetGlobalOption
    minimapOpenConfig=type(openConfig)=="function" and openConfig or minimapOpenConfig
    minimapGetGlobalOptions=type(getGlobalOptions)=="function" and getGlobalOptions or minimapGetGlobalOptions
    local state=type(globalOptions.minimapIcon)=="table" and globalOptions.minimapIcon or {hide=false,angle=220}
    minimapAngle=normalizeAngle(state.angle)
    if not minimapButton then
      local ok,button=pcall(api.CreateFrame,"Button","DejunkWotLKMinimapButton",api.Minimap)
      if not ok or not button then return false,"MINIMAP_BUTTON_FAILED" end
      minimapButton=button; button:SetWidth(32); button:SetHeight(32); button:EnableMouse(true)
      button:SetFrameStrata("MEDIUM"); button:SetMovable(true)
      if type(button.RegisterForClicks)=="function" then button:RegisterForClicks("LeftButtonUp","RightButtonUp") end
      if type(button.RegisterForDrag)=="function" then button:RegisterForDrag("LeftButton") end
      local border=button:CreateTexture(nil,"OVERLAY")
      border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder"); border:SetWidth(54); border:SetHeight(54); border:SetPoint("CENTER",0,0)
      local icon=button:CreateTexture(nil,"BACKGROUND")
      icon:SetTexture("Interface\\Icons\\INV_Misc_Gear_01"); icon:SetWidth(18); icon:SetHeight(18); icon:SetPoint("CENTER",0,0)
      button.icon=icon
      if type(button.SetHighlightTexture)=="function" then button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight") end
      button:SetScript("OnEnter",function(self)
        if api.GameTooltip then
          api.GameTooltip:SetOwner(self,"ANCHOR_LEFT"); api.GameTooltip:SetText("Dejunk")
          api.GameTooltip:AddLine("Click to open settings",1,1,1); api.GameTooltip:AddLine("Right-click to hide",0.65,0.65,0.65)
          api.GameTooltip:AddLine("Drag to move",0.65,0.65,0.65); api.GameTooltip:Show()
        end
      end)
      button:SetScript("OnLeave",function() if api.GameTooltip then api.GameTooltip:Hide() end end)
      button:SetScript("OnClick",function(_,mouseButton)
        if mouseButton=="RightButton" then
          local current=type(minimapGetGlobalOptions)=="function" and minimapGetGlobalOptions() or {}
          local currentIcon=type(current.minimapIcon)=="table" and current.minimapIcon or {}
          local changed,reason=minimapSetGlobalOption and minimapSetGlobalOption("minimapIcon",{hide=not currentIcon.hide,angle=minimapAngle})
          if changed then runtime:UpdateMinimapIcon(minimapGetGlobalOptions and minimapGetGlobalOptions(),minimapSetGlobalOption,minimapOpenConfig,minimapGetGlobalOptions)
          else runtime:Print("Minimap icon update failed: "..tostring(reason or "UNAVAILABLE")) end
        elseif type(minimapOpenConfig)=="function" then
          minimapOpenConfig()
        end
      end)
      button:SetScript("OnDragStart",function()
        button:SetScript("OnUpdate",function()
          if type(api.GetCursorPosition)~="function" or type(api.Minimap.GetCenter)~="function" then return end
          local cx,cy=api.Minimap:GetCenter(); local scale=api.Minimap.GetEffectiveScale and api.Minimap:GetEffectiveScale() or 1
          if type(cx)~="number" or type(cy)~="number" or type(scale)~="number" or scale<=0 then return end
          local px,py=api.GetCursorPosition(); if type(px)~="number" or type(py)~="number" then return end
          px,py=px/scale-cx,py/scale-cy
          if math.atan2 then minimapAngle=normalizeAngle(math.deg(math.atan2(py,px)))
          elseif px~=0 then
            local angle=math.deg(math.atan(py/px)); if px<0 then angle=angle+180 elseif py<0 then angle=angle+360 end
            minimapAngle=normalizeAngle(angle)
          else minimapAngle=py>=0 and 90 or 270 end
          positionMinimapButton()
        end)
      end)
      button:SetScript("OnDragStop",function()
        button:SetScript("OnUpdate",nil)
        if type(minimapSetGlobalOption)=="function" then
          local saved,reason=minimapSetGlobalOption("minimapIcon",{angle=minimapAngle})
          if not saved then runtime:Print("Minimap position was not saved: "..tostring(reason or "UNAVAILABLE")) end
        end
      end)
    end
    positionMinimapButton()
    if state.hide==true then minimapButton:Hide() else minimapButton:Show() end
    return true
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
  local function createWaffleWindow(name,width,height)
    if not Addon.Waffle then return nil,nil end
    local ok,root,window=pcall(function()
      local component=Addon.Waffle:Flex({width=width,height=height,direction="COLUMN",visibility="GONE",
        frameFactory=function()
          local panel=api.CreateFrame("Frame",name,api.UIParent)
          panel:SetFrameStrata("DIALOG"); panel:EnableMouse(true); panel:SetPoint("CENTER")
          panel:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=32,insets={left=8,right=8,top=8,bottom=8}})
          return panel
        end})
      component:SetVisibility("VISIBLE"); component:Layout()
      return component,component:GetFrame()
    end)
    return ok and root or nil,ok and window or nil
  end
  local function getCursorItemId()
    if type(api.GetCursorInfo)~="function" then return nil end
    local ok,kind,itemId=pcall(api.GetCursorInfo)
    itemId=tonumber(itemId)
    if ok and kind=="item" and itemId and itemId>0 and itemId<2147483648 and itemId==math.floor(itemId) then
      return itemId
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
    runtime.configCallbacks=callbacks
    if Addon.Waffle then
      local ok,waffleError=pcall(function()
        if not configWaffleRoot then
          local function button(parent,label,onClick)
            return {width=168,height=32,frameFactory=function(owner)
              local control=api.CreateFrame("Button",nil,owner)
              control:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
              local region=control:CreateFontString(nil,"ARTWORK","GameFontNormal")
              region:SetPoint("LEFT",8,0); region:SetPoint("RIGHT",-8,0); region:SetJustifyH("CENTER")
              region:SetText(label); setTextColor(region,"white")
              control.text=label; control.label=region
              local function refresh(hovered)
                local gold=theme.gold
                control:SetBackdropColor(hovered and gold[1] or 30/255,hovered and gold[2] or 30/255,hovered and gold[3] or 30/255,hovered and 0.25 or 0.75)
                control:SetBackdropBorderColor(hovered and gold[1] or 0,hovered and gold[2] or 0,hovered and gold[3] or 0,1)
                setTextColor(region,hovered and "white" or "gold")
              end
              control:SetScript("OnEnter",function() refresh(true) end)
              control:SetScript("OnLeave",function() refresh(false) end)
              control:SetScript("OnClick",onClick); refresh(false)
              return control
            end}
          end
          local function navButton(key,label,onClick)
            return {width=168,height=32,frameFactory=function(owner)
              local control=api.CreateFrame("Button",nil,owner)
              control:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8"})
              control:SetBackdropBorderColor(0,0,0,0)
              local region=control:CreateFontString(nil,"ARTWORK","GameFontNormal")
              region:SetPoint("LEFT",8,0); region:SetPoint("RIGHT",-8,0); region:SetJustifyH("LEFT")
              region:SetText(label)
              control.label=region; control.text=label
              local selected=false
              local function refresh(hovered)
                if selected then
                  control:SetBackdropColor(theme.blue[1],theme.blue[2],theme.blue[3],0.1)
                  setTextColor(region,"blue")
                elseif hovered then
                  control:SetBackdropColor(1,1,1,0.1)
                  setTextColor(region,"white")
                else
                  control:SetBackdropColor(0,0,0,0)
                  setTextColor(region,"grey")
                end
              end
              control.SetSelected=function(self,value) selected=value==true; self.selected=selected; refresh(false) end
              control:SetScript("OnEnter",function() refresh(true) end)
              control:SetScript("OnLeave",function() refresh(false) end)
              control:SetScript("OnClick",onClick)
              configNavButtons[key]=control
              refresh(false)
              return control
            end}
          end
          local function text(parent,label,height,color)
            return {height=height or 24,frameFactory=function(owner)
              local region=owner:CreateFontString(nil,"ARTWORK","GameFontNormal")
              region:SetJustifyH("LEFT"); region:SetText(label); if color then setTextColor(region,color) end
              return region
            end}
          end
          configWaffleRoot=Addon.Waffle:Flex({
            width=800,height=640,direction="COLUMN",visibility="GONE",
            defaultFrameFactory=function(parent) return api.CreateFrame("Frame",nil,parent) end,
            frameFactory=function()
              local panel=api.CreateFrame("Frame", "DejunkWotLK_MainWindow", api.UIParent)
              panel:SetFrameStrata("DIALOG"); panel:EnableMouse(true); panel:SetMovable(true)
              panel:RegisterForDrag("LeftButton")
              panel:SetScript("OnDragStart",function(self) self:StartMoving() end)
              panel:SetScript("OnDragStop",function(self) self:StopMovingOrSizing(); saveCurrentPoint(self,"mainWindow") end)
              setSavedPoint(panel,"mainWindow"); panel:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1,insets={left=1,right=1,top=1,bottom=1}})
              panel:SetBackdropColor(18/255,18/255,18/255,0.95); panel:SetBackdropBorderColor(0,0,0,1)
              panel:Hide(); return panel
            end
          })
          local title=configWaffleRoot:AddRow({height=32,padding=8,justify="SPACE_BETWEEN",frameFactory=function(parent)
            local bar=api.CreateFrame("Frame",nil,parent); bar:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8"}); bar:SetBackdropColor(30/255,30/255,30/255,1); return bar
          end})
          title:AddChild(text(nil,"Dejunk",30,"blue"))
          title:AddChild({width=28,height=28,frameFactory=function(parent)
            local close=styleCloseButton(api.CreateFrame("Button",nil,parent))
            close:SetWidth(24); close:SetHeight(24)
            close:SetScript("OnClick",function() configWaffleRoot:SetVisibility("GONE"); configWaffleRoot:Layout(); mainWindowVisible=false end)
            return close
          end})
          local content=configWaffleRoot:AddRow({grow=1,padding=8,gap=8})
          local nav=content:AddColumn({width="25%",padding=4,gap=4,frameFactory=function(parent)
            return api.CreateFrame("Frame",nil,parent)
          end})
          local main=content:AddColumn({grow=1,padding=8,gap=8,frameFactory=function(parent)
            return api.CreateFrame("Frame",nil,parent)
          end})
          configContentComponent=main
          local overview=main:AddColumn({grow=1,gap=8})
          configOverviewComponent=overview
          configScreens.overview=overview
          nav:AttachComponent(Addon.Waffle:Flex(navButton("lists","Lists",function()
            self:ShowLists(runtime.configCallbacks)
          end)))
          nav:AttachComponent(Addon.Waffle:Flex(navButton("profiles","Profiles",function()
            self:ShowProfiles(runtime.configCallbacks)
          end)))
          nav:AttachComponent(Addon.Waffle:Flex(navButton("globalOptions","Global Options",function()
            self:ShowOptions(runtime.configCallbacks,"global")
          end)))
          nav:AttachComponent(Addon.Waffle:Flex(navButton("profileOptions","Profile Options",function()
            self:ShowOptions(runtime.configCallbacks,"profile")
          end)))
          overview:AttachComponent(Addon.Waffle:Flex(text(nil,"Dejunk",28,"blue")))
          overview:AttachComponent(Addon.Waffle:Flex(text(nil,"Settings and inventory previews are read-only. No item action will be taken.",46)))
          overview:AttachComponent(Addon.Waffle:Flex({height=26,frameFactory=function(parent)
            configSummary=parent:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); configSummary:SetJustifyH("LEFT"); configSummary:SetWordWrap(true); return configSummary
          end}))
          local controls=overview:AddRow({height=34,gap=8,wrap=true})
          controls:AttachComponent(Addon.Waffle:Flex(button(nil,"Toggle Poor quality",function() local current=runtime.configCallbacks or {}; if current.togglePoor then current.togglePoor() end; self:ShowConfig(current) end)))
          controls:AttachComponent(Addon.Waffle:Flex(button(nil,"Preview SELL",function() local current=runtime.configCallbacks or {}; if current.preview then current.preview("sell") end end)))
          controls:AttachComponent(Addon.Waffle:Flex(button(nil,"Preview DESTROY",function() local current=runtime.configCallbacks or {}; if current.preview then current.preview("destroy") end end)))
          local itemWindows=overview:AddRow({height=34,gap=8,wrap=true})
          itemWindows:AttachComponent(Addon.Waffle:Flex(button(nil,"Junk Items",function()
            local current=runtime.configCallbacks or {}; local items,reason=current.junkItems and current.junkItems()
            if items then self:ToggleJunkFrame(items) else self:Print("Junk items unavailable: "..tostring(reason)) end
          end)))
          itemWindows:AttachComponent(Addon.Waffle:Flex(button(nil,"Lootable Items",function()
            local current=runtime.configCallbacks or {}; local items,reason=current.lootableItems and current.lootableItems()
            if items then
              if not self:ToggleLootableFrame(items) then self:Print("No lootable items.") end
            else self:Print("Lootable items unavailable: "..tostring(reason)) end
          end)))
        end
        configWaffleRoot:SetVisibility("VISIBLE"); configWaffleRoot:Layout(); mainWindowVisible=true
        configFrame=configWaffleRoot:GetFrame()
        mainContentFrame=configContentComponent and configContentComponent:GetFrame() or nil
        if configOverviewComponent then configOverviewComponent:SetVisibility("GONE") end
        if listFrame then listFrame:Hide() end
        if profileFrame then profileFrame:Hide() end
        if optionsFrame then optionsFrame:Hide() end
        configSummary:SetText(callbacks.summary and callbacks.summary() or "Settings unavailable.")
        if configFrame and poorButton and poorButton.SetText and callbacks.poorEnabled then
          poorButton:SetText(callbacks.poorEnabled() and "Disable Poor rule" or "Enable Poor rule")
        end
      end)
      if ok then self:ShowLists(callbacks); return end
      self:Print("Original Waffle configuration UI failed: "..tostring(waffleError).."; using the built-in fallback.")
    end
    local ok=pcall(function()
      if not configFrame then
        configFrame=api.CreateFrame("Frame",nil,api.UIParent)
        configFrame:SetWidth(500); configFrame:SetHeight(300); setSavedPoint(configFrame,"mainWindow")
        configFrame:SetFrameStrata("DIALOG"); configFrame:EnableMouse(true); configFrame:SetMovable(true)
        configFrame:RegisterForDrag("LeftButton")
        configFrame:SetScript("OnDragStart",function(self) if self.StartMoving then self:StartMoving() end end)
        configFrame:SetScript("OnDragStop",function(self) if self.StopMovingOrSizing then self:StopMovingOrSizing() end; saveCurrentPoint(self,"mainWindow") end)
        configFrame:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=32,insets={left=8,right=8,top=8,bottom=8}})
        local title=configFrame:CreateFontString(nil,"OVERLAY","GameFontNormal")
        title:SetPoint("TOPLEFT",20,-18); title:SetText("Dejunk-WotLK | Configuration and preview")
        local close=styleCloseButton(api.CreateFrame("Button",nil,configFrame))
        close:SetPoint("TOPRIGHT",-4,-4); close:SetScript("OnClick",function() configFrame:Hide(); mainWindowVisible=false end)
        configSummary=configFrame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        configSummary:SetPoint("TOPLEFT",24,-58); configSummary:SetWidth(450); configSummary:SetJustifyH("LEFT")
        local function button(label,x,y,handler)
          local control=styleThemedButton(api.CreateFrame("Button",nil,configFrame))
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
        button("Options",334,88,function()
          configFrame:Hide()
          self:ShowOptions(callbacks)
        end)
        button("Junk Items",22,88,function()
          local items,reason=callbacks.junkItems and callbacks.junkItems()
          if items then self:ToggleJunkFrame(items) else self:Print("Junk items unavailable: "..tostring(reason)) end
        end)
        button("Lootable Items",178,88,function()
          local items,reason=callbacks.lootableItems and callbacks.lootableItems()
          if items then self:ToggleLootableFrame(items) else self:Print("Lootable items unavailable: "..tostring(reason)) end
        end)
      end
      configSummary:SetText(callbacks.summary and callbacks.summary() or "Settings unavailable.")
      if poorButton and poorButton.SetText and callbacks.poorEnabled then
        poorButton:SetText(callbacks.poorEnabled() and "Disable Poor rule" or "Enable Poor rule")
      end
      configFrame:Show(); mainWindowVisible=true
    end)
    if not ok then
      self:Print("Configuration panel unavailable; use /djw rules and /djw preview sell|destroy.")
      if callbacks.summary then self:Print(callbacks.summary()) end
    end
  end

  local function setConfigPageVisible(page,visible)
    if not page then return end
    if (page==listFrame and listPageComponent) or
        (page==profileFrame and profilePageComponent) or
        (page==optionsFrame and optionsPageComponent) then return end
    if page.SetAlpha then page:SetAlpha(visible and 1 or 0) end
    if visible then page:Show() else page:Hide() end
  end
  local function selectConfigScreen(key)
    selectedConfigScreen=key
    mainWindowVisible=true
    for screenKey,component in pairs(configScreens) do
      component:SetVisibility(screenKey==key and "VISIBLE" or "GONE")
    end
    local selectedNav=key
    if key=="options" then selectedNav=optionsFrame and optionsFrame.scope=="global" and "globalOptions" or "profileOptions" end
    for navKey,button in pairs(configNavButtons) do button:SetSelected(navKey==selectedNav) end
    if configWaffleRoot then configWaffleRoot:SetVisibility("VISIBLE"); configWaffleRoot:Layout() end
  end

  function runtime:ToggleConfig(callbacks)
    if mainWindowVisible then
      if configWaffleRoot then configWaffleRoot:SetVisibility("GONE"); configWaffleRoot:Layout()
      elseif configFrame then configFrame:Hide() end
      if profileFrame and not profileWaffleRoot then profileFrame:Hide() end
      if listFrame and not listsWaffleRoot then listFrame:Hide() end
      if optionsFrame and not optionsWaffleRoot then optionsFrame:Hide() end
      mainWindowVisible=false
      return false
    end
    self:ShowConfig(callbacks or self.configCallbacks or {})
    return true
  end
  local function getMainConfigContent()
    if not configContentComponent then return nil end
    local content=configContentComponent:GetFrame()
    if content then mainContentFrame=content end
    return content
  end

  function runtime:ShowProfiles(callbacks)
    callbacks=callbacks or {}
    runtime.configCallbacks=callbacks
    if not configWaffleRoot then self:ShowConfig(callbacks) end
    if configWaffleRoot and configContentComponent and configOverviewComponent then
      selectConfigScreen(nil)
      setConfigPageVisible(listFrame,false)
      setConfigPageVisible(profileFrame,false)
      setConfigPageVisible(optionsFrame,false)
      mainContentFrame=getMainConfigContent()
    end
    setConfigPageVisible(listFrame,false)
    setConfigPageVisible(profileFrame,false)
    setConfigPageVisible(optionsFrame,false)
    local ok,optionsError=pcall(function()
      if not profileFrame then
        mainContentFrame=getMainConfigContent()
        if mainContentFrame then
          profileFrame=api.CreateFrame("Frame","DejunkWotLKProfiles",mainContentFrame)
          profilePageComponent=configContentComponent:AddColumn({frame=profileFrame,grow=1,gap=8,visibility="GONE"})
          configScreens.profiles=profilePageComponent
        else
          profileWaffleRoot,profileFrame=createWaffleWindow("DejunkWotLKProfiles",420,360)
          profileFrame=profileFrame or api.CreateFrame("Frame",nil,api.UIParent)
        end
        if not mainContentFrame then
          profileFrame:SetWidth(420); profileFrame:SetHeight(360); profileFrame:SetPoint("CENTER"); profileFrame:SetFrameStrata("DIALOG")
        end
        profileFrame:EnableMouse(true)
        if not mainContentFrame then profileFrame:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=32,insets={left=8,right=8,top=8,bottom=8}}) end
        local title=profileFrame:CreateFontString(nil,"OVERLAY","GameFontNormal")
        title:SetPoint("TOPLEFT",18,-18); title:SetText("Dejunk | Profiles"); setTextColor(title,"blue")
        profileFrame.pageTitle=title
        if not mainContentFrame then
          local close=styleCloseButton(api.CreateFrame("Button",nil,profileFrame))
          close:SetPoint("TOPRIGHT",-4,-4); close:SetScript("OnClick",function() profileFrame:Hide() end)
        end
        profileSummary=profileFrame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        profileSummary:SetPoint("TOPLEFT",22,-50); profileSummary:SetWidth(360); profileSummary:SetJustifyH("LEFT"); setTextColor(profileSummary,"grey")
        profileScroll=api.CreateFrame("ScrollFrame","DejunkWotLKProfileScrollFrame",profileFrame,"UIPanelScrollFrameTemplate")
        profileScroll:SetPoint("TOPLEFT",22,-72); profileScroll:SetPoint("BOTTOMRIGHT",-18,75)
        profileList=api.CreateFrame("Frame",nil,profileScroll); profileList:SetWidth(500); profileList:SetHeight(175); profileScroll:SetScrollChild(profileList); profileButtons={}
        local popupBlocker=api.CreateFrame("Frame","DejunkWotLKProfilePopupBlocker",api.UIParent)
        popupBlocker:SetAllPoints(api.UIParent); popupBlocker:SetFrameStrata("FULLSCREEN_DIALOG"); popupBlocker:SetFrameLevel(1000)
        popupBlocker:EnableMouse(true); popupBlocker:SetScript("OnMouseDown",function() end); popupBlocker:Hide()
        local profilePopup=api.CreateFrame("Frame","DejunkWotLKProfilePopup",popupBlocker)
        profilePopup:SetWidth(390); profilePopup:SetHeight(158); profilePopup:SetPoint("CENTER",popupBlocker,"CENTER",0,0)
        profilePopup:SetFrameStrata("FULLSCREEN_DIALOG"); profilePopup:EnableMouse(true)
        raiseForMouseInput(profilePopup,1)
        profilePopup:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
        profilePopup:SetBackdropColor(theme.dark[1],theme.dark[2],theme.dark[3],0.98)
        profilePopup:SetBackdropBorderColor(1,1,1,0.3); profilePopup:Hide()
        local function hideProfilePopup() profilePopup:Hide(); popupBlocker:Hide() end
        local popupMessage=profilePopup:CreateFontString(nil,"OVERLAY","GameFontNormal")
        popupMessage:SetPoint("TOPLEFT",14,-14); popupMessage:SetWidth(332); popupMessage:SetJustifyH("CENTER"); setTextColor(popupMessage,"white")
        local popupEdit=api.CreateFrame("EditBox",nil,profilePopup,"InputBoxTemplate")
        popupEdit:SetWidth(220); popupEdit:SetHeight(26); popupEdit:SetPoint("TOP",profilePopup,"TOP",0,-50)
        popupEdit:SetAutoFocus(false); popupEdit:SetMaxLetters(32)
        raiseForMouseInput(popupEdit,10)
        popupEdit:SetFontObject("GameFontHighlight")
        popupEdit:SetTextInsets(8,8,0,0)
        popupEdit:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
        popupEdit:SetBackdropColor(0,0,0,0.9); popupEdit:SetBackdropBorderColor(0.55,0.55,0.55,1)
        popupEdit:EnableMouse(true)
        if type(popupEdit.RegisterForClicks)=="function" then popupEdit:RegisterForClicks("LeftButtonUp") end
        local executeProfileName
        popupEdit:SetScript("OnEnterPressed",function(self) self:ClearFocus(); executeProfileName() end)
        popupEdit:SetScript("OnEscapePressed",function(self) self:ClearFocus(); hideProfilePopup() end)
        local popupAccept=styleThemedButton(api.CreateFrame("Button",nil,profilePopup),"Accept")
        popupAccept:SetWidth(112); popupAccept:SetHeight(26); popupAccept:SetPoint("BOTTOMLEFT",16,14)
        local popupCancel=styleThemedButton(api.CreateFrame("Button",nil,profilePopup),"Cancel")
        popupCancel:SetWidth(112); popupCancel:SetHeight(26); popupCancel:SetPoint("BOTTOMRIGHT",-16,14)
        local popupMode,popupAction,popupProfile
        executeProfileName=function()
          local current=runtime.configCallbacks or callbacks
          local name=popupEdit:GetText() or ""
          local id,reason
          if popupAction=="create" then id,reason=current.createProfile and current.createProfile(name)
          elseif popupAction=="duplicate" then
            id,reason=current.duplicateProfileFrom and current.duplicateProfileFrom(popupProfile.id,name)
            if not id and current.duplicateProfile then id,reason=current.duplicateProfile(name) end
          else id,reason=current.renameProfile and current.renameProfile(popupProfile.id,name) end
          local verb=popupAction=="create" and "Create" or popupAction=="duplicate" and "Duplicate" or "Rename"
          self:Print(id and (verb=="Create" and "Profile created." or verb=="Duplicate" and "Profile duplicated." or "Profile renamed.") or
            (verb.." failed: "..tostring(reason or "UNAVAILABLE")))
          hideProfilePopup(); self:ShowProfiles(current)
        end
        local function executeProfileConfirm()
          local current=runtime.configCallbacks or callbacks
          local changed,reason
          if popupAction=="reset" then changed,reason=current.resetProfile and current.resetProfile(popupProfile.id)
          else changed,reason=current.deleteProfile and current.deleteProfile(popupProfile.id) end
          self:Print(changed and (popupAction=="reset" and "Profile reset." or "Profile deleted.") or
            ((popupAction=="reset" and "Reset" or "Delete").." failed: "..tostring(reason or "DEFAULT_PROFILE_PROTECTED")))
          hideProfilePopup(); self:ShowProfiles(current)
        end
        popupAccept:SetScript("OnClick",function() if popupMode=="name" then executeProfileName() else executeProfileConfirm() end end)
        popupCancel:SetScript("OnClick",hideProfilePopup)
        profileFrame.profilePopup=profilePopup
        profilePopup.blocker=popupBlocker; profilePopup.editBox=popupEdit; profilePopup.acceptButton=popupAccept; profilePopup.cancelButton=popupCancel
        local function showNamePrompt(action,profile)
          popupMode="name"; popupAction=action; popupProfile=profile
          popupMessage:SetText(action=="create" and "Enter a name for the new profile:" or (action=="duplicate" and "Copy profile: " or "Rename profile: ")..(profile and profile.name or ""))
          popupEdit:SetText(profile and profile.name or "")
          popupAccept:SetText("Accept"); popupCancel:SetText("Cancel"); popupBlocker:Show(); profilePopup:Show(); popupEdit:Show()
          -- 3.3.5 drops SetFocus when called while an ancestor is hidden.
          popupEdit:SetFocus()
          if popupEdit.HighlightText then popupEdit:HighlightText() end
        end
        profileFrame.showNamePrompt=showNamePrompt
        local function confirmAction(action,profile)
          popupMode="confirm"; popupAction=action; popupProfile=profile
          popupMessage:SetText("Are you sure you want to "..action.." profile "..profile.name.."?")
          popupEdit:Hide(); popupAccept:SetText("Yes"); popupCancel:SetText("No"); popupBlocker:Show(); profilePopup:Show()
        end
        profileFrame.confirmProfileAction=confirmAction
        local create=styleThemedButton(api.CreateFrame("Button",nil,profileFrame),"New Profile")
        create:SetWidth(130); create:SetHeight(28); create:SetPoint("BOTTOMLEFT",profileFrame,"BOTTOMLEFT",22,16)
        create:SetScript("OnClick",function() showNamePrompt("create") end)
        profileFrame.newProfileButton=create
      end
      local profiles=callbacks.profiles and callbacks.profiles() or {}
      local activeName=callbacks.activeProfileName and callbacks.activeProfileName() or nil
      if profileFrame.pageTitle then
        profileFrame.pageTitle:SetText("Dejunk | Profiles"..(activeName and (" ("..activeName..")") or ""))
        setTextColor(profileFrame.pageTitle,"blue")
      end
      table.sort(profiles,function(a,b)
        if a.id=="default" then return true end
        if b.id=="default" then return false end
        return string.lower(a.name or a.id)<string.lower(b.name or b.id)
      end)
      local row=0
      for _,child in ipairs(profileButtons) do child:Hide() end
      profileButtons={}
      for index,profile in ipairs(profiles) do
        local profileEntry=profile
        local button=api.CreateFrame("Button",nil,profileList)
        button.profileId=profile.id
        button:SetWidth(470); button:SetHeight(48); button:SetPoint("TOPLEFT",profileList,"TOPLEFT",0,-row*52)
        button:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8"}); button:SetBackdropBorderColor(0,0,0,0)
        button:SetBackdropColor(1,1,1,0.03)
        local accent=button:CreateTexture(nil,"ARTWORK"); accent:SetTexture("Interface\\Buttons\\WHITE8x8")
        accent:SetWidth(3); accent:SetPoint("TOPLEFT"); accent:SetPoint("BOTTOMLEFT")
        accent:SetVertexColor(theme.blue[1],theme.blue[2],theme.blue[3],profile.active and 1 or 0)
        local name=button:CreateFontString(nil,"ARTWORK","GameFontNormal")
        name:SetPoint("TOPLEFT",12,-7); name:SetPoint("RIGHT",-172,0); name:SetJustifyH("LEFT")
        name:SetText(profile.name); setTextColor(name,profile.active and "blue" or "white")
        local summary=button:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
        summary:SetPoint("BOTTOMLEFT",name,"BOTTOMLEFT",0,-15); summary:SetPoint("RIGHT",-172,0); summary:SetJustifyH("LEFT")
        local bits={}
        if profile.autoSell then bits[#bits+1]="Auto Sell" end
        bits[#bits+1]="Inclusions: "..tostring(profile.numInclusions or 0)
        bits[#bits+1]="Exclusions: "..tostring(profile.numExclusions or 0)
        summary:SetText(table.concat(bits,"  ·  ")); setTextColor(summary,"grey")
        button:SetScript("OnEnter",function(self) self:SetBackdropColor(1,1,1,0.06) end)
        button:SetScript("OnLeave",function(self) self:SetBackdropColor(1,1,1,0.03) end)
        button:SetScript("OnClick",function()
          local current=runtime.configCallbacks or callbacks
          local switched,reason=current.switchProfile and current.switchProfile(profileEntry.id)
          self:Print(switched and ("Active profile: "..profileEntry.name) or ("Profile switch failed: "..tostring(reason)))
          self:ShowProfiles(callbacks)
        end)
        local actions={{"Rename","rename",66},{"Duplicate","duplicate",74},{"Reset","reset",58},{"Delete","delete",62}}
        local right=-5
        for _,entry in ipairs(actions) do
          local action,label,width=entry[2],entry[1],entry[3]
          local actionButton=styleThemedButton(api.CreateFrame("Button",nil,button),label)
          actionButton:SetWidth(width); actionButton:SetHeight(22); actionButton:SetPoint("RIGHT",button,"RIGHT",right,0)
          actionButton.profileAction=action; actionButton.profileId=profile.id
          if (action=="rename" or action=="delete") and profile.id=="default" then
            actionButton:Disable(); actionButton:SetAlpha(0.35)
          end
          actionButton:SetScript("OnClick",function()
            if action=="rename" or action=="duplicate" then profileFrame.showNamePrompt(action,profileEntry)
            else profileFrame.confirmProfileAction(action,profileEntry) end
          end)
          right=right-width-3
        end
        profileButtons[#profileButtons+1]=button
        row=row+1
      end
      profileList:SetHeight(math.max(175,row*52))
      profileSummary:SetText("Select a profile to activate it:")
      setConfigPageVisible(listFrame,false)
      setConfigPageVisible(optionsFrame,false)
      if profilePageComponent and configWaffleRoot then
        selectConfigScreen("profiles")
      else setConfigPageVisible(profileFrame,true) end
    end)
    if not ok then self:Print("Profiles window unavailable; use /djw profiles list|create|switch.") end
  end

  function runtime:ShowLists(callbacks)
    callbacks=callbacks or {}
    runtime.configCallbacks=callbacks
    if not configWaffleRoot then self:ShowConfig(callbacks) end
    if configWaffleRoot and configContentComponent and configOverviewComponent and selectedConfigScreen~="lists" then
      selectConfigScreen(nil)
      setConfigPageVisible(listFrame,false)
      setConfigPageVisible(profileFrame,false)
      setConfigPageVisible(optionsFrame,false)
      mainContentFrame=getMainConfigContent()
    end
    setConfigPageVisible(profileFrame,false)
    setConfigPageVisible(optionsFrame,false)
    local ok=pcall(function()
      if not listFrame then
        mainContentFrame=getMainConfigContent()
        if mainContentFrame then
          listFrame=api.CreateFrame("Frame","DejunkWotLKLists",mainContentFrame)
          listPageComponent=configContentComponent:AddColumn({frame=listFrame,grow=1,gap=8,visibility="GONE"})
          configScreens.lists=listPageComponent
        else
          listsWaffleRoot,listFrame=createWaffleWindow("DejunkWotLKLists",540,540)
          listFrame=listFrame or api.CreateFrame("Frame","DejunkWotLKLists",api.UIParent)
        end
        if not mainContentFrame then listFrame:SetWidth(540); listFrame:SetHeight(540); listFrame:SetPoint("CENTER") end
        listFrame:EnableMouse(true)
        listSearch=api.CreateFrame("EditBox",nil,listFrame,"InputBoxTemplate")
        listSearch:SetWidth(350); listSearch:SetHeight(24); listSearch:SetPoint("TOPLEFT",12,-14)
        listSearch:SetAutoFocus(false); listSearch:SetMaxLetters(64)
        if listSearch.SetTextInsets then listSearch:SetTextInsets(24,24,0,0) end
        local searchIcon=listSearch:CreateTexture(nil,"ARTWORK")
        searchIcon:SetTexture("Interface\\Common\\UI-Searchbox-Icon"); searchIcon:SetWidth(14); searchIcon:SetHeight(14); searchIcon:SetPoint("LEFT",6,0)
        listSearchPlaceholder=listSearch:CreateFontString(nil,"OVERLAY","GameFontDisableSmall")
        listSearchPlaceholder:SetPoint("LEFT",24,0); listSearchPlaceholder:SetText("Search by item name or ID"); setTextColor(listSearchPlaceholder,"grey")
        listSearchClear=styleCloseButton(api.CreateFrame("Button",nil,listSearch))
        listSearchClear:SetWidth(18); listSearchClear:SetHeight(18); listSearchClear:SetPoint("RIGHT",-3,0)
        listSearchClear:SetScript("OnClick",function() listSearch:SetText(""); listSearch:ClearFocus() end)
        listSearchClear:Hide()
        listSearch:SetScript("OnEscapePressed",function() listSearch:ClearFocus() end)
        listSearch:SetScript("OnTextChanged",function() self:ShowLists(callbacks) end)
        listScopeButton=styleThemedButton(api.CreateFrame("Button",nil,listFrame))
        listScopeButton:SetWidth(100); listScopeButton:SetHeight(24); listScopeButton:SetPoint("TOPLEFT",12,-48)
        listScopeButton:SetScript("OnClick",function()
          listScopeButton.scope=listScopeButton.scope=="global" and "profile" or "global"
          self:ShowLists(callbacks)
        end)
        listKindButton=styleThemedButton(api.CreateFrame("Button",nil,listFrame))
        listKindButton:SetWidth(110); listKindButton:SetHeight(24); listKindButton:SetPoint("LEFT",listScopeButton,"RIGHT",8,0)
        listKindButton:SetScript("OnClick",function()
          listKindButton.kind=listKindButton.kind=="inclusions" and "exclusions" or "inclusions"
          self:ShowLists(callbacks)
        end)
        listInput=api.CreateFrame("EditBox",nil,listFrame,"InputBoxTemplate")
        listInput:SetWidth(72); listInput:SetHeight(24); listInput:SetPoint("LEFT",listKindButton,"RIGHT",8,0)
        listInput:SetAutoFocus(false); listInput:SetNumeric(true); listInput:SetMaxLetters(10)
        listInput:SetScript("OnEscapePressed",function() listInput:ClearFocus() end)
        local function listButton(label,x,handler)
          local b=styleThemedButton(api.CreateFrame("Button",nil,listFrame))
          b:SetWidth(label=="Add" and 60 or 66); b:SetHeight(24); b:SetPoint("LEFT",listInput,"RIGHT",x,0); b:SetText(label); b:SetScript("OnClick",handler); return b
        end
        listButton("Add",8,function() self:EditList(callbacks,true) end)
        listButton("Remove",76,function() self:EditList(callbacks,false) end)
        listPanels={}
        local listWidth=listFrame:GetWidth() or 540
        local paneWidth=math.max(220,math.floor((listWidth-36)/2))
        local paneHeight=192
        local panes={
          {scope="global",kind="inclusions",title="Inclusions (Global)",x=8,y=-84},
          {scope="global",kind="exclusions",title="Exclusions (Global)",x=paneWidth+20,y=-84},
          {scope="profile",kind="inclusions",title="Inclusions (Profile)",x=8,y=-(84+paneHeight+12)},
          {scope="profile",kind="exclusions",title="Exclusions (Profile)",x=paneWidth+20,y=-(84+paneHeight+12)}
        }
        for _,pane in ipairs(panes) do
          local paneScope,paneKind=pane.scope,pane.kind
          local box=api.CreateFrame("Frame",nil,listFrame)
          box:SetWidth(paneWidth); box:SetHeight(paneHeight); box:SetPoint("TOPLEFT",listFrame,"TOPLEFT",pane.x,pane.y)
          box:EnableMouse(true); box:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
          box:SetBackdropColor(1,1,1,0.03); box:SetBackdropBorderColor(1,1,1,0.22)
          local function addCursorItem()
            local itemId=getCursorItemId()
            if not itemId then return false end
            local added,reason=callbacks.editItem and callbacks.editItem(paneScope,paneKind,itemId,true)
            if added then
              if type(api.ClearCursor)=="function" then pcall(api.ClearCursor) end
              self:Print("Item added to "..paneScope.." "..paneKind..".")
            else
              self:Print("List update failed: "..tostring(reason or "UNAVAILABLE"))
            end
            self:ShowLists(callbacks)
            return true
          end
          box:SetScript("OnMouseDown",function() addCursorItem() end)
          local heading=box:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
          heading:SetPoint("TOPLEFT",8,-7); heading:SetText(pane.title); setTextColor(heading,"white")
          local empty=box:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
          empty:SetPoint("TOPLEFT",8,-30); empty:SetWidth(paneWidth-16); empty:SetJustifyH("LEFT"); setTextColor(empty,"grey")
          local rows={}
          for rowIndex=1,7 do
            local row=api.CreateFrame("Button",nil,box)
            row:SetWidth(paneWidth-16); row:SetHeight(20); row:SetPoint("TOPLEFT",8,-27-(rowIndex-1)*21)
            row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8"}); row:SetBackdropBorderColor(0,0,0,0)
            local icon=row:CreateTexture(nil,"ARTWORK")
            icon:SetWidth(18); icon:SetHeight(18); icon:SetPoint("LEFT",3,0)
            local label=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
            label:SetPoint("LEFT",icon,"RIGHT",5,0); label:SetWidth(paneWidth-52); label:SetJustifyH("LEFT"); setTextColor(label,"white")
            local accent=row:CreateTexture(nil,"ARTWORK")
            accent:SetWidth(2); accent:SetPoint("TOPLEFT"); accent:SetPoint("BOTTOMLEFT")
            row.icon=icon; row.label=label; row.accent=accent; row.listScope=paneScope; row.listKind=paneKind
            row:SetScript("OnEnter",function(self) self:SetBackdropColor(1,1,1,0.06) end)
            row:SetScript("OnLeave",function(self) self:SetBackdropColor(1,1,1,0) end)
            if type(row.RegisterForClicks)=="function" then row:RegisterForClicks("LeftButtonUp","RightButtonUp") end
            row:SetScript("OnMouseDown",function()
              if getCursorItemId() then row.cursorHandled=addCursorItem() end
            end)
            row:SetScript("OnClick",function(_,mouseButton)
              if row.cursorHandled then row.cursorHandled=false; return end
              if mouseButton=="RightButton" and row.itemId and callbacks.editItem then
                local targetScope,targetKind=paneScope,paneKind
                local shift=type(api.IsShiftKeyDown)=="function" and api.IsShiftKeyDown()
                local control=type(api.IsControlKeyDown)=="function" and api.IsControlKeyDown()
                local alt=type(api.IsAltKeyDown)=="function" and api.IsAltKeyDown()
                if shift then targetKind=paneKind=="inclusions" and "exclusions" or "inclusions"
                elseif control then targetScope=paneScope=="global" and "profile" or "global"; targetKind=paneKind=="inclusions" and "exclusions" or "inclusions"
                elseif alt then targetScope=paneScope=="global" and "profile" or "global"
                else
                  local removed,reason=callbacks.editItem(paneScope,paneKind,row.itemId,false)
                  self:Print(removed and "Item removed from list." or ("List update failed: "..tostring(reason)))
                  self:ShowLists(callbacks)
                  return
                end
                local added,reason=callbacks.editItem(targetScope,targetKind,row.itemId,true)
                self:Print(added and "Item moved to list." or ("List update failed: "..tostring(reason)))
                self:ShowLists(callbacks)
                return
              end
              listScopeButton.scope=paneScope; listKindButton.kind=paneKind; listInput:SetText(row.itemId or "")
              listScopeButton:SetText("Scope: "..paneScope)
              listKindButton:SetText(paneKind=="inclusions" and "Inclusions" or "Exclusions")
            end)
            rows[#rows+1]=row
          end
          listPanels[#listPanels+1]={scope=pane.scope,kind=pane.kind,empty=empty,rows=rows}
        end
        local export=styleThemedButton(api.CreateFrame("Button",nil,listFrame))
        export:SetWidth(90); export:SetHeight(24); export:SetPoint("BOTTOMLEFT",listFrame,"BOTTOMLEFT",22,18); export:SetText("Export")
        export:SetScript("OnClick",function()
          local scope=listScopeButton.scope or "global"; local kind=listKindButton.kind or "inclusions"
          importScope,importKind=scope,kind
          self:ShowListImport(callbacks,"export")
        end)
        local import=styleThemedButton(api.CreateFrame("Button",nil,listFrame))
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
      if listSearchPlaceholder then if query=="" then listSearchPlaceholder:Show() else listSearchPlaceholder:Hide() end end
      if listSearchClear then if query=="" then listSearchClear:Hide() else listSearchClear:Show() end end
      local raws,allIds,seenIds={}, {}, {}
      for index,pane in ipairs(listPanels) do
        local raw=callbacks.listItems and callbacks.listItems(pane.scope,pane.kind) or ""
        raws[index]=raw
        for id in raw:gmatch("%d+") do
          if not seenIds[id] then seenIds[id]=true; allIds[#allIds+1]=id end
        end
      end
      local signature=table.concat(allIds,"\31")
      if signature~=listMetadataSignature then
        listMetadataSignature=signature; listMetadataIds=allIds; listMetadataCursor=1
        listMetadataAge,listMetadataElapsed=0,0
      end
      -- WotLK has no reliable item-info completion event. Follow upstream's
      -- bounded queue behavior: request at most 25 IDs per refresh tick.
      local metadataPending=false
      if type(api.GetItemInfo)=="function" and #listMetadataIds>0 then
        for _=1,math.min(25,#listMetadataIds) do
          local id=listMetadataIds[listMetadataCursor]
          listMetadataCursor=listMetadataCursor%#listMetadataIds+1
          local cached=itemPresentationCache[id]
          if not (cached and cached.name) then
            local values={pcall(api.GetItemInfo,tonumber(id))}
            if values[1] and type(values[2])=="string" then
              itemPresentationCache[id]={name=values[2],quality=values[4],texture=values[11]}
            else
              metadataPending=true
            end
          end
        end
        if not metadataPending then
          for _,id in ipairs(listMetadataIds) do
            local cached=itemPresentationCache[id]
            if not (cached and cached.name) then metadataPending=true; break end
          end
        end
      end
      for index,pane in ipairs(listPanels) do
        local nameResolver=query:find("%D") and function(id)
          local item=itemPresentationCache[id]
          return item and item.name
        end or nil
        local filtered=Addon.Config.SortListItems(Addon.Config.FilterItemIds(raws[index],query,nameResolver),function(id)
          return itemPresentationCache[id]
        end)
        local total=#filtered
        for index,row in ipairs(pane.rows) do
          local item=filtered[index]
          if item then
            local presentation=itemPresentationCache[item.id] or {}
            row.itemId=item.id; row.label:SetText((presentation.name or item.name or "Item").." (#"..item.id..")")
            if presentation.texture then row.icon:SetTexture(presentation.texture); row.icon:Show() else row.icon:Hide() end
            if type(api.GetItemQualityColor)=="function" and presentation.quality then
              local colorOk,r,g,b=pcall(api.GetItemQualityColor,presentation.quality)
              if colorOk and type(r)=="number" and type(g)=="number" and type(b)=="number" then row.accent:SetVertexColor(r,g,b,1); row.accent:Show()
              else row.accent:Hide() end
            else row.accent:Hide() end
            row:Show()
          else row:Hide() end
        end
        pane.empty:SetText(total==0 and (query=="" and "This list is empty." or "No matches.") or
          (total>6 and ("... "..(total-6).." more; search to narrow or use /djw lists show "..pane.scope.." "..pane.kind) or ""))
        if total==0 or total>6 then pane.empty:Show() else pane.empty:Hide() end
      end
      if metadataPending and listMetadataAge<30 then
        listFrame:SetScript("OnUpdate",function(_,elapsed)
          listMetadataElapsed=listMetadataElapsed+elapsed
          if listMetadataElapsed<0.1 then return end
          listMetadataAge=listMetadataAge+listMetadataElapsed; listMetadataElapsed=0
          if listMetadataAge>=30 then listFrame:SetScript("OnUpdate",nil); return end
          self:ShowLists(callbacks)
        end)
      else
        listFrame:SetScript("OnUpdate",nil)
      end
      setConfigPageVisible(profileFrame,false)
      setConfigPageVisible(optionsFrame,false)
      if listPageComponent and configWaffleRoot then
        if selectedConfigScreen~="lists" then selectConfigScreen("lists") end
      else setConfigPageVisible(listFrame,true) end
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

  function runtime:ShowListImport(callbacks,mode)
    callbacks=callbacks or {}
    local ok=pcall(function()
      if not importFrame then
        importWaffleRoot,importFrame=createWaffleWindow("DejunkWotLKListImport",520,420)
        importFrame=importFrame or api.CreateFrame("Frame",nil,api.UIParent)
        importFrame:SetWidth(560); importFrame:SetHeight(390); importFrame:SetPoint("CENTER")
        importFrame:SetFrameStrata("DIALOG"); importFrame:EnableMouse(true)
        importFrame:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=32,insets={left=8,right=8,top=8,bottom=8}})
        importTitle=importFrame:CreateFontString(nil,"OVERLAY","GameFontNormal")
        importTitle:SetPoint("TOPLEFT",20,-18)
        local close=styleCloseButton(api.CreateFrame("Button",nil,importFrame))
        close:SetPoint("TOPRIGHT",-4,-4); close:SetScript("OnClick",function() importFrame:Hide() end)
        importHelp=importFrame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        importHelp:SetPoint("TOPLEFT",24,-48); importHelp:SetWidth(500); importHelp:SetJustifyH("LEFT")
        importHelp:SetText("Paste item IDs separated by spaces, commas, semicolons or new lines.")
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
        local review=styleThemedButton(api.CreateFrame("Button",nil,importFrame))
        review:SetWidth(100); review:SetHeight(24); review:SetPoint("BOTTOMLEFT",importFrame,"BOTTOMLEFT",22,16); review:SetText("Review")
        importReviewButton=review
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
        importCommitButton=styleThemedButton(api.CreateFrame("Button",nil,importFrame))
        importCommitButton:SetWidth(100); importCommitButton:SetHeight(24); importCommitButton:SetPoint("LEFT",review,"RIGHT",8,0); importCommitButton:SetText("Import")
        importCommitButton:Disable()
        importCommitButton:SetScript("OnClick",function()
          local committed,reason=callbacks.commitListImport and callbacks.commitListImport(importPreview)
          if committed then
            importStatus:SetText("Import complete."); importCommitButton:Disable(); importPreview=nil
            importEdit:SetText(""); importFrame:Hide()
            if selectedConfigScreen=="lists" then selectedConfigScreen=nil end
            self:ShowLists(callbacks)
          else importStatus:SetText("Import failed: "..tostring(reason)); importCommitButton:Disable(); importPreview=nil end
        end)
        importSelectButton=styleThemedButton(api.CreateFrame("Button",nil,importFrame))
        importSelectButton:SetWidth(100); importSelectButton:SetHeight(24); importSelectButton:SetPoint("LEFT",review,"RIGHT",8,0); importSelectButton:SetText("Select all")
        importSelectButton:SetScript("OnClick",function() importEdit:SetFocus(); importEdit:HighlightText(0,#(importEdit:GetText() or "")) end)
        local cancel=styleThemedButton(api.CreateFrame("Button",nil,importFrame))
        cancel:SetWidth(100); cancel:SetHeight(24); cancel:SetPoint("BOTTOMRIGHT",importFrame,"BOTTOMRIGHT",-20,16); cancel:SetText("Cancel")
        importCancelButton=cancel
        cancel:SetScript("OnClick",function() importFrame:Hide(); if listFrame then listFrame:Show() end end)
        close:SetScript("OnClick",function() importFrame:Hide(); if listFrame then listFrame:Show() end end)
      end
      importPreview=nil; importCommitButton:Disable()
      local scope=importScope or "global"; local kind=importKind or "inclusions"
      local isExport=mode=="export"
      local titleText=(isExport and "Export " or "Import into ")..scope.." "..kind
      -- The title region is the first FontString child created by this panel.
      importTitle:SetText(titleText)
      if isExport then
        local exported=callbacks.listItems and callbacks.listItems(scope,kind) or ""
        importEdit:SetText((exported:gsub("[\r\n]+",",")))
        importHelp:SetText("Select all, then copy the item IDs.")
        importStatus:SetText("Select all, then copy the item IDs.")
        importReviewButton:Hide(); importCommitButton:Hide(); importSelectButton:Show(); importCancelButton:SetText("Close")
      else
        importEdit:SetText(""); importStatus:SetText("Review the IDs before importing.")
        importHelp:SetText("Paste item IDs separated by spaces, commas, semicolons or new lines.")
        importReviewButton:Show(); importCommitButton:Show(); importSelectButton:Hide(); importCancelButton:SetText("Cancel")
      end
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
        rulesWaffleRoot,rulesFrame=createWaffleWindow("DejunkWotLKRules",540,480)
        rulesFrame=rulesFrame or api.CreateFrame("Frame",nil,api.UIParent)
        rulesFrame:SetWidth(540); rulesFrame:SetHeight(480); rulesFrame:SetPoint("CENTER")
        rulesFrame:SetFrameStrata("DIALOG"); rulesFrame:EnableMouse(true)
        rulesFrame:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=32,insets={left=8,right=8,top=8,bottom=8}})
        local title=rulesFrame:CreateFontString(nil,"OVERLAY","GameFontNormal")
        title:SetPoint("TOPLEFT",20,-18); title:SetText("Dejunk-WotLK | Custom rules")
        local help=rulesFrame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        help:SetPoint("TOPLEFT",24,-40); help:SetText("Add conditions, then Add rule. ALL=every condition; ANY=one condition.")
        local close=styleCloseButton(api.CreateFrame("Button",nil,rulesFrame))
        close:SetPoint("TOPRIGHT",-4,-4); close:SetScript("OnClick",function() rulesFrame:Hide() end)
        ruleScopeButton=styleThemedButton(api.CreateFrame("Button",nil,rulesFrame))
        ruleScopeButton:SetWidth(135); ruleScopeButton:SetHeight(24); ruleScopeButton:SetPoint("TOPLEFT",24,-62)
        ruleScopeButton:SetScript("OnClick",function()
          local order={"SELL","DESTROY","BOTH"}; local current=ruleScopeButton.value or "SELL"
          for i,v in ipairs(order) do if v==current then ruleScopeButton.value=order[i%#order+1]; break end end
          self:UpdateRules(callbacks)
        end)
        ruleResultButton=styleThemedButton(api.CreateFrame("Button",nil,rulesFrame))
        ruleResultButton:SetWidth(135); ruleResultButton:SetHeight(24); ruleResultButton:SetPoint("LEFT",ruleScopeButton,"RIGHT",10,0)
        ruleResultButton:SetScript("OnClick",function() ruleResultButton.value=ruleResultButton.value=="JUNK" and "KEEP" or "JUNK"; self:UpdateRules(callbacks) end)
        ruleFieldButton=styleThemedButton(api.CreateFrame("Button",nil,rulesFrame))
        ruleFieldButton:SetWidth(170); ruleFieldButton:SetHeight(24); ruleFieldButton:SetPoint("TOPLEFT",24,-100)
        ruleFieldButton:SetScript("OnClick",function()
          local order={"itemId","quality","itemLevel","unitVendorPrice","count"}; local current=ruleFieldButton.value or order[1]
          for i,v in ipairs(order) do if v==current then ruleFieldButton.value=order[i%#order+1]; break end end
          self:UpdateRules(callbacks)
        end)
        ruleOpButton=styleThemedButton(api.CreateFrame("Button",nil,rulesFrame))
        ruleOpButton:SetWidth(95); ruleOpButton:SetHeight(24); ruleOpButton:SetPoint("LEFT",ruleFieldButton,"RIGHT",10,0)
        ruleOpButton:SetScript("OnClick",function()
          local order={"EQ","LT","GT"}; local current=ruleOpButton.value or order[1]
          for i,v in ipairs(order) do if v==current then ruleOpButton.value=order[i%#order+1]; break end end
          self:UpdateRules(callbacks)
        end)
        ruleGroupButton=styleThemedButton(api.CreateFrame("Button",nil,rulesFrame))
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
        local addCondition=styleThemedButton(api.CreateFrame("Button",nil,rulesFrame))
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
        local addRule=styleThemedButton(api.CreateFrame("Button",nil,rulesFrame))
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
            self:Print("Rule saved.")
          else self:Print("Rule add failed: "..tostring(reason or "INVALID_RULE")) end
          self:UpdateRules(callbacks)
        end)
        rulesSummary=rulesFrame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        rulesSummary:SetPoint("TOPLEFT",26,-190); rulesSummary:SetWidth(480); rulesSummary:SetJustifyH("LEFT")
        local remove=styleThemedButton(api.CreateFrame("Button",nil,rulesFrame))
        remove:SetWidth(100); remove:SetHeight(24); remove:SetPoint("BOTTOMLEFT",rulesFrame,"BOTTOMLEFT",24,18); remove:SetText("Remove ID")
        ruleIdInput:SetScript("OnTextChanged",function()
          if (ruleIdInput:GetText() or "")=="" then remove:Disable() else remove:Enable() end
        end)
        remove:Disable()
        remove:SetScript("OnClick",function()
          local id=ruleIdInput:GetText(); local removed,reason=callbacks.removeRule and callbacks.removeRule(id)
          if removed then
            ruleIdInput:SetText("")
            self:Print("Rule removed.")
          else
            self:Print("Rule remove failed: "..tostring(reason or "UNKNOWN_RULE"))
          end
          self:UpdateRules(callbacks)
        end)
        local clearDraft=styleThemedButton(api.CreateFrame("Button",nil,rulesFrame))
        clearDraft:SetWidth(105); clearDraft:SetHeight(24); clearDraft:SetPoint("LEFT",remove,"RIGHT",8,0); clearDraft:SetText("Clear draft")
        clearDraft:SetScript("OnClick",function() ruleDraftPredicates={}; ruleDraftProfileId=nil; self:UpdateRules(callbacks) end)
        local back=styleThemedButton(api.CreateFrame("Button",nil,rulesFrame))
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

  local function refreshOptionCheckVisual(check)
    local visual=check.optionVisual
    if not visual then return end
    local enabled=check.optionEnabled~=false
    local checkState=check:GetChecked()
    local checked=checkState==true or checkState==1
    visual.box:SetBackdropColor(checked and theme.blue[1] or theme.dark[1],checked and theme.blue[2] or theme.dark[2],checked and theme.blue[3] or theme.dark[3],enabled and (checked and 0.5 or 0.25) or 0.5)
    visual.box:SetBackdropBorderColor(theme.blue[1],theme.blue[2],theme.blue[3],enabled and (checked and 1 or 0.75) or 0.35)
    visual.fill:SetVertexColor(theme.blue[1],theme.blue[2],theme.blue[3],enabled and 1 or 0.75)
    if checked then visual.fill:Show() else visual.fill:Hide() end
    visual.box:SetAlpha(enabled and 1 or 0.5)
    if check.labelRegion then setTextColor(check.labelRegion,checked and "white" or "grey") end
  end
  local function setOptionCheckText(check,labelText)
    check.optionLabel=labelText
    check.text=labelText
    if check.labelRegion then check.labelRegion:SetText(labelText) end
    refreshOptionCheckVisual(check)
  end
  local function setOptionCheckChecked(check,value)
    check:SetChecked(value)
    refreshOptionCheckVisual(check)
  end
  local function setOptionCheckHandler(check,handler)
    check:SetScript("OnClick",function(self,button)
      handler(self,button)
      refreshOptionCheckVisual(self)
    end)
    check.optionClickHandler=handler
    if check.labelHit then
      check.labelHit:SetScript("OnClick",function()
        handler(check,"LeftButton")
        refreshOptionCheckVisual(check)
      end)
    end
  end
  local function setOptionCheckEnabled(check,enabled)
    check.optionEnabled=enabled==true
    if enabled then check:Enable() else check:Disable() end
    if check.labelHit then
      if enabled then check.labelHit:Enable() else check.labelHit:Disable() end
    end
    refreshOptionCheckVisual(check)
  end
  function runtime:ShowOptions(callbacks,scope)
    callbacks=callbacks or {}
    runtime.configCallbacks=callbacks; optionsCallbacks=callbacks
    scope=scope=="global" and "global" or "profile"
    if not configWaffleRoot then self:ShowConfig(callbacks) end
    if configWaffleRoot and configContentComponent and configOverviewComponent then
      selectConfigScreen(nil)
      setConfigPageVisible(listFrame,false)
      setConfigPageVisible(profileFrame,false)
      setConfigPageVisible(optionsFrame,false)
      mainContentFrame=getMainConfigContent()
    end
    setConfigPageVisible(listFrame,false)
    setConfigPageVisible(profileFrame,false)
    setConfigPageVisible(optionsFrame,false)
    local ok,optionsError=xpcall(function()
      if not optionsFrame then
        mainContentFrame=getMainConfigContent()
        if mainContentFrame then
          optionsFrame=api.CreateFrame("Frame","DejunkWotLKOptions",mainContentFrame)
          optionsPageComponent=configContentComponent:AddColumn({frame=optionsFrame,grow=1,gap=8,visibility="GONE"})
          configScreens.options=optionsPageComponent
        else
          optionsWaffleRoot,optionsFrame=createWaffleWindow("DejunkWotLKOptions",560,420)
          optionsFrame=optionsFrame or api.CreateFrame("Frame",nil,api.UIParent)
        end
        if not mainContentFrame then
          optionsFrame:SetWidth(560); optionsFrame:SetHeight(440); optionsFrame:SetPoint("CENTER"); optionsFrame:SetFrameStrata("DIALOG")
        end
        optionsFrame:EnableMouse(true)
        if not mainContentFrame then optionsFrame:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=32,insets={left=8,right=8,top=8,bottom=8}})
        else
          optionsFrame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",tile=true,tileSize=8})
          optionsFrame:SetBackdropColor(0,0,0,1)
        end
        local title=optionsFrame:CreateFontString(nil,"OVERLAY","GameFontNormal")
        title:SetPoint("TOPLEFT",20,-18); optionsFrame.pageTitle=title; setTextColor(title,"blue")
        local description=optionsFrame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        description:SetPoint("TOPLEFT",20,-40)
        local mainWidth=mainContentFrame and mainContentFrame.GetWidth and mainContentFrame:GetWidth() or 0
        description:SetWidth(mainWidth>80 and mainWidth-50 or (mainContentFrame and 520 or 500))
        description:SetText("These options only apply to characters using the active profile."); setTextColor(description,"grey")
        optionsFrame.pageDescription=description
        if not mainContentFrame then
          local close=styleCloseButton(api.CreateFrame("Button",nil,optionsFrame))
          close:SetPoint("TOPRIGHT",-4,-4); close:SetScript("OnClick",function() optionsFrame:Hide() end)
        end
        optionsScrollFrame=api.CreateFrame("ScrollFrame","DejunkWotLKOptionsScroll",optionsFrame,"UIPanelScrollFrameTemplate")
        optionsScrollFrame:SetPoint("TOPLEFT",optionsFrame,"TOPLEFT",14,-64)
        optionsScrollFrame:SetPoint("BOTTOMRIGHT",optionsFrame,"BOTTOMRIGHT",-30,42)
        optionsContentFrame=api.CreateFrame("Frame",nil,optionsScrollFrame)
        optionsContentFrame:SetWidth(mainWidth>100 and mainWidth-90 or (mainContentFrame and 520 or 490))
        optionsContentFrame:SetHeight(2040)
        optionsScrollFrame:SetScrollChild(optionsContentFrame)
        optionsFrame.scrollFrame=optionsScrollFrame; optionsFrame.contentFrame=optionsContentFrame
        optionsProfileDecorations={}; optionsGlobalDecorations={}
        optionsOptionCards={}; optionsCardDividers={}; optionsQualityRows={}; optionsResponsiveDescriptions={}
        optionsGlobalControls={}; optionsGlobalChoices={}
        local optionCheckSerial=0
        local function createOptionCheck(labelText,x,y,hitWidth)
          optionCheckSerial=optionCheckSerial+1
          local size=hitWidth and 12 or 18
          local check=api.CreateFrame("CheckButton","DejunkWotLKOptionCheck"..optionCheckSerial,optionsContentFrame)
          check:SetWidth(size); check:SetHeight(size); check:SetPoint("TOPLEFT",x,y)
          raiseForMouseInput(check,10)
          check:EnableMouse(true)
          if type(check.RegisterForClicks)=="function" then check:RegisterForClicks("LeftButtonUp") end
          check.optionEnabled=true
          local box=api.CreateFrame("Frame",nil,check)
          box:SetWidth(12); box:SetHeight(12); box:SetPoint("CENTER",check,"CENTER",0,0)
          box:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
          box:EnableMouse(false)
          local fill=box:CreateTexture(nil,"ARTWORK")
          fill:SetTexture("Interface\\Buttons\\WHITE8x8")
          fill:SetPoint("TOPLEFT",3,-3); fill:SetPoint("BOTTOMRIGHT",-3,3)
          check.optionVisual={box=box,fill=fill}
          local labelHit=api.CreateFrame("Button",nil,check)
          labelHit:SetWidth(math.max(16,(hitWidth or 220)-size-2)); labelHit:SetHeight(20)
          labelHit:SetPoint("LEFT",check,"RIGHT",2,0)
          raiseForMouseInput(labelHit,2)
          labelHit:EnableMouse(true)
          if type(labelHit.RegisterForClicks)=="function" then labelHit:RegisterForClicks("LeftButtonUp") end
          local label=labelHit:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
          label:SetPoint("LEFT",labelHit,"LEFT",0,0)
          check.labelRegion=label
          check.labelHit=labelHit
          setOptionCheckText(check,labelText)
          return check
        end
        local function addScopeChoices(key,x,y,step,defaultValue)
          local choices={{value="SELL",label="Selling"},{value="DESTROY",label="Destroying"},{value="BOTH",label="Both"}}
          local rows={}
          for index,choice in ipairs(choices) do
            local control=createOptionCheck(choice.label,x+(index-1)*step,y,step-4)
            control.scopeKey=key; control.scopeValue=choice.value
            setOptionCheckHandler(control,function()
              local currentCallbacks=optionsCallbacks or callbacks
              local current=currentCallbacks.options and currentCallbacks.options() or {}
              local previous=current[key] or defaultValue or {enabled=true,scope="BOTH",qualities={}}
              local value={}
              for field,fieldValue in pairs(previous) do value[field]=fieldValue end
              value.scope=choice.value
              local changed,reason=currentCallbacks.setOption and currentCallbacks.setOption(key,value)
              self:Print(changed and (key.." scope updated.") or ("Option update failed: "..tostring(reason)))
              self:ShowOptions(currentCallbacks,"profile")
            end)
            rows[#rows+1]=control
          end
          optionsScopeFields[#optionsScopeFields+1]={key=key,choices=rows}
          return rows
        end
        local function addSection(titleText,y,isGlobal)
          local heading=optionsContentFrame:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
          heading:SetPoint("TOPLEFT",18,y); heading:SetText(titleText); setTextColor(heading,"blue")
          local group=isGlobal and optionsGlobalDecorations or optionsProfileDecorations
          group[#group+1]=heading
          return heading
        end
        local function addOptionCard(y,height,isGlobal)
          local card=api.CreateFrame("Frame",nil,optionsContentFrame)
          card.optionCard=true
          raiseForMouseInput(card,1)
          card:SetPoint("TOPLEFT",optionsContentFrame,"TOPLEFT",10,y)
          card:SetWidth(math.max(380,optionsContentFrame:GetWidth()-20)); card:SetHeight(height)
          card:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",tile=true,tileSize=8})
          card:SetBackdropColor(1,1,1,0.03)
          local group=isGlobal and optionsGlobalDecorations or optionsProfileDecorations
          group[#group+1]=card
          optionsOptionCards[#optionsOptionCards+1]=card
          return card
        end
        local optionCardFrames={}
        addSection("General",-8)
        optionCardFrames.autoRepair=addOptionCard(-30,64)
        optionCardFrames.autoSell=addOptionCard(-104,64)
        addSection("Include",-184)
        optionCardFrames.includeByQuality=addOptionCard(-208,112)
        optionCardFrames.includeBelowItemLevel=addOptionCard(-330,150)
        optionCardFrames.includeBelowPrice=addOptionCard(-490,150)
        optionCardFrames.includeByEquipmentType=addOptionCard(-650,330)
        addSection("Exclude",-994)
        optionCardFrames.excludeAboveItemLevel=addOptionCard(-1018,150)
        optionCardFrames.excludeAbovePrice=addOptionCard(-1178,150)
        optionCardFrames.excludeByEquipmentType=addOptionCard(-1338,330)
        optionCardFrames.excludeEquipmentSets=addOptionCard(-1678,100)
        optionCardFrames.excludeQuestItems=addOptionCard(-1788,72)
        optionCardFrames.excludeUnboundEquipment=addOptionCard(-1870,150)
        local function bindCardClick(key,handler)
          local card=optionCardFrames[key]
          if not card then return end
          card:EnableMouse(true)
          card:SetScript("OnMouseDown",function() handler() end)
        end
        local function addProfileText(text,x,y,width)
          local label=optionsContentFrame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
          label:SetPoint("TOPLEFT",x,y); if width then label:SetWidth(width) end
          label:SetJustifyH("LEFT"); label:SetText(text); setTextColor(label,"grey")
          if width and width>=400 then
            label.optionDescription=true; label.optionDescriptionX=x
            optionsResponsiveDescriptions[#optionsResponsiveDescriptions+1]=label
          end
          optionsProfileDecorations[#optionsProfileDecorations+1]=label
          return label
        end
        local function addGlobalText(text,x,y,width)
          local label=optionsContentFrame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
          label:SetPoint("TOPLEFT",x,y); if width then label:SetWidth(width) end
          label:SetJustifyH("LEFT"); label:SetText(text); setTextColor(label,"grey")
          if width and width>=400 then
            label.optionDescription=true; label.optionDescriptionX=x
            optionsResponsiveDescriptions[#optionsResponsiveDescriptions+1]=label
          end
          optionsGlobalDecorations[#optionsGlobalDecorations+1]=label
          return label
        end
        local function addCardDivider(y)
          local divider=api.CreateFrame("Frame",nil,optionsContentFrame)
          divider:SetPoint("TOPLEFT",optionsContentFrame,"TOPLEFT",24,y)
          divider:SetWidth(mainContentFrame and 510 or 420); divider:SetHeight(1)
          divider:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8"})
          divider:SetBackdropColor(1,1,1,0.12)
          optionsProfileDecorations[#optionsProfileDecorations+1]=divider
          optionsCardDividers[#optionsCardDividers+1]=divider
          return divider
        end
        local qualityTitle=createOptionCheck("Include by quality",24,-216)
        optionsFrame.qualityTitle=qualityTitle
        local function toggleQualityFilter()
          local currentCallbacks=optionsCallbacks or callbacks
          local current=currentCallbacks.options and currentCallbacks.options() or {}
          local previous=current.includeByQuality or {enabled=true,scope="BOTH",qualities={poor=true,common=false,uncommon=false,rare=false,epic=false}}
          local value={enabled=not previous.enabled,scope=previous.scope or "BOTH",qualities=previous.qualities}
          local changed,reason=currentCallbacks.setOption and currentCallbacks.setOption("includeByQuality",value)
          self:Print(changed and "Include by quality updated." or ("Option update failed: "..tostring(reason)))
          self:ShowOptions(currentCallbacks,"profile")
        end
        setOptionCheckHandler(qualityTitle,toggleQualityFilter)
        bindCardClick("includeByQuality",toggleQualityFilter)
        local labels={"Poor","Common","Uncommon","Rare","Epic"}
        local qualityCaptions={"Poor","Com","Unc","Rare","Epic"}
        local qualityStep=92
        optionsQualityButtons={}
        for quality=0,4 do
          local b=createOptionCheck(qualityCaptions[quality+1],110+quality*qualityStep,-296,88)
          b.optionGroup="includeByQuality"; b.optionQuality=labels[quality+1]:lower(); b.qualityRow=true
          b.qualityRowY=-296
          optionsQualityRows[#optionsQualityRows+1]=b
          setOptionCheckHandler(b,function()
            local currentCallbacks=optionsCallbacks or callbacks
            local opts=currentCallbacks.options and currentCallbacks.options() or {}
            local values=(opts.includeByQuality and opts.includeByQuality.qualities) or {}
            local enabled=not (values[labels[quality+1]:lower()] or false)
            local current=opts.includeByQuality or {enabled=true,scope="BOTH",qualities={}}
            current.qualities=current.qualities or {}; current.qualities[labels[quality+1]:lower()]=enabled
            local changed,reason=currentCallbacks.setOption and currentCallbacks.setOption("includeByQuality",current)
            if changed then currentCallbacks.setOption("quality",{quality=quality,enabled=enabled}) end
            self:Print(changed and (labels[quality+1].." quality "..(enabled and "enabled." or "disabled.")) or ("Option update failed: "..tostring(reason)))
            self:ShowOptions(currentCallbacks,optionsFrame.scope)
          end)
          optionsQualityButtons[quality+1]=b
        end
        optionsFields={}
        local optionRows={
          {key="autoRepair",label="Auto Repair",x=24,y=-38},
          {key="autoSell",label="Auto Sell",x=24,y=-112},
          {key="excludeEquipmentSets",label="Exclude equipment sets",x=24,y=-1686},
          {key="excludeQuestItems",label="Exclude quest items",x=24,y=-1796},
          {key="excludeUnboundEquipment",label="Exclude unbound equipment",x=24,y=-1878}
        }
        for index,row in ipairs(optionRows) do
          local button=createOptionCheck(row.label,row.x,row.y)
          local function toggleOption()
            local currentCallbacks=optionsCallbacks or callbacks
            local opts=currentCallbacks.options and currentCallbacks.options() or {}; local value=opts[row.key]
            local enabled=type(value)=="table" and value.enabled or value==true
            local changed,reason=currentCallbacks.setOption and currentCallbacks.setOption(row.key,not enabled)
            self:Print(changed and (row.label.." updated.") or ("Option update failed: "..tostring(reason)))
            self:ShowOptions(currentCallbacks,optionsFrame.scope)
          end
          setOptionCheckHandler(button,toggleOption)
          bindCardClick(row.key,toggleOption)
          optionsFields[index]={key=row.key,button=button,label=row.label}
        end
        addProfileText("Automatically repair upon interacting with a merchant.",24,-58,510)
        addProfileText("Automatically sell items upon interacting with a merchant.",24,-132,510)
        addProfileText("Include items of the selected qualities.",52,-238,470)
        addProfileText("Include equipment with an item level below a set value.",52,-360,470)
        addProfileText("Include items below the selected stack vendor value.",52,-520,470)
        addProfileText("Include equipment of the selected armor and weapon types.",52,-680,470)
        addProfileText("Exclude equipment with an item level above a set value.",52,-1048,470)
        addProfileText("Exclude items above the selected stack vendor value.",52,-1208,470)
        addProfileText("Exclude equipment of the selected armor and weapon types.",52,-1368,470)
        addProfileText("Exclude equipment saved to an equipment set.",52,-1708,470)
        addProfileText("Exclude items classified by the game as quest items.",52,-1818,470)
        addProfileText("Exclude equipment that is not bound.",52,-1900,470)
        optionsThresholdFields={}
        optionsScopeFields={}
        addCardDivider(-262); addCardDivider(-384); addCardDivider(-544); addCardDivider(-704)
        addCardDivider(-1032); addCardDivider(-1192); addCardDivider(-1352); addCardDivider(-1728); addCardDivider(-1920)
        addProfileText("Applies to",24,-270,78)
        addScopeChoices("includeByQuality",110,-270,98,{enabled=true,scope="BOTH",qualities={poor=true,common=false,uncommon=false,rare=false,epic=false}})
        addProfileText("Qualities",24,-296,78)
        addScopeChoices("excludeEquipmentSets",110,-1742,98,{enabled=true,scope="BOTH"})
        addProfileText("Applies to",24,-1742,78)
        addScopeChoices("excludeUnboundEquipment",110,-1934,98,{enabled=false,scope="BOTH",qualities={poor=true,common=true,uncommon=true,rare=true,epic=true}})
        addProfileText("Applies to",24,-1934,78)
        optionsEnableFields={}
        optionsUnboundQualityFields={}
        local unboundQualityTitle=optionsContentFrame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        unboundQualityTitle:SetPoint("TOPLEFT",24,-1960); unboundQualityTitle:SetText("Qualities")
        optionsUnboundQualityFields.title=unboundQualityTitle
        for quality=1,5 do
          local q=quality
          local name=({"Poor","Com","Unc","Rare","Epic"})[quality]
          local button=createOptionCheck(name,110+(quality-1)*92,-1960,88)
          button.optionGroup="excludeUnboundEquipment"; button.optionQuality=({"poor","common","uncommon","rare","epic"})[quality]
          button.qualityRow=true; button.qualityRowY=-1960
          optionsQualityRows[#optionsQualityRows+1]=button
          setOptionCheckHandler(button,function()
            local currentCallbacks=optionsCallbacks or callbacks
            local current=currentCallbacks.options and currentCallbacks.options() or {}
            local previous=current.excludeUnboundEquipment or {enabled=false,scope="BOTH",qualities={poor=true,common=true,uncommon=true,rare=true,epic=true}}
            local qualities={}
            for _,name in ipairs({"poor","common","uncommon","rare","epic"}) do qualities[name]=not previous.qualities or previous.qualities[name]~=false end
            local name=({"poor","common","uncommon","rare","epic"})[q]; qualities[name]=not qualities[name]
            local value={enabled=previous.enabled==true,scope=previous.scope or "BOTH",qualities=qualities}
            local changed,reason=currentCallbacks.setOption and currentCallbacks.setOption("excludeUnboundEquipment",value)
            self:Print(changed and "Unbound equipment quality updated." or ("Option update failed: "..tostring(reason)))
            self:ShowOptions(currentCallbacks,"profile")
          end)
          optionsUnboundQualityFields[quality]=button
        end
        local thresholds={{key="includeBelowItemLevel",label="Include below item level"},{key="includeBelowPrice",label="Include below price"},{key="excludeAboveItemLevel",label="Exclude above item level"},{key="excludeAbovePrice",label="Exclude above price"}}
        local qualityKeys={"poor","common","uncommon","rare","epic"}
        local qualityLabels={"Poor","Com","Unc","Rare","Epic"}
        for index,row in ipairs(thresholds) do
          local cardTop=({-330,-490,-1018,-1178})[index]
          local valueY,scopeY,qualityY=cardTop-54,cardTop-80,cardTop-106
          local label=createOptionCheck(row.label,24,cardTop-8)
          local function toggleThreshold()
            local currentCallbacks=optionsCallbacks or callbacks
            local current=currentCallbacks.options and currentCallbacks.options() or {}
            local previous=current[row.key] or {scope=(row.key=="includeBelowPrice" or row.key=="excludeAbovePrice") and "DESTROY" or "BOTH",value=0,qualities={poor=true,common=true,uncommon=true,rare=true,epic=true}}
            local value={enabled=not previous.enabled,scope=previous.scope,value=previous.value or 0,qualities=previous.qualities}
            local changed,reason=currentCallbacks.setOption and currentCallbacks.setOption(row.key,value)
            self:Print(changed and (row.label.." updated.") or ("Option update failed: "..tostring(reason)))
            self:ShowOptions(currentCallbacks,"profile")
          end
          setOptionCheckHandler(label,toggleThreshold)
          bindCardClick(row.key,toggleThreshold)
          local valueLabel=addProfileText(row.key:find("Price") and "Price" or "Item level",24,valueY,78)
          local scopeLabel=addProfileText("Applies to",24,scopeY,78)
          local qualityLabel=addProfileText("Qualities",24,qualityY,78)
          local edits={}
          local isPrice=row.key=="includeBelowPrice" or row.key=="excludeAbovePrice"
          local editWidths=isPrice and {42,34,34} or {78}
          local coinIcons={"Interface\\MoneyFrame\\UI-GoldIcon","Interface\\MoneyFrame\\UI-SilverIcon","Interface\\MoneyFrame\\UI-CopperIcon"}
          local x=110
          for part,width in ipairs(editWidths) do
            local edit=api.CreateFrame("EditBox",nil,optionsContentFrame,"InputBoxTemplate")
            edit:SetWidth(width); edit:SetHeight(22); edit:SetAutoFocus(false); edit:SetNumeric(true); edit:SetMaxLetters(part==1 and isPrice and 6 or (isPrice and 2 or 10))
            raiseForMouseInput(edit,10)
            edit:SetPoint("TOPLEFT",x,valueY)
            edit.thresholdKey=row.key; edit.thresholdPart=part
            edit:SetScript("OnEnterPressed",function(self) self:ClearFocus() end)
            edit:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
            edits[part]=edit
            if isPrice then
              local icon=edit:CreateTexture(nil,"ARTWORK")
              icon:SetWidth(14); icon:SetHeight(14); icon:SetTexture(coinIcons[part]); icon:SetPoint("LEFT",edit,"RIGHT",2,0)
              x=x+62
            end
          end
          local edit=edits[#edits]
          local apply=styleThemedButton(api.CreateFrame("Button",nil,optionsContentFrame))
          apply.thresholdKey=row.key
          apply:SetWidth(68); apply:SetHeight(22); apply:SetText("Apply")
          if isPrice then apply:SetPoint("TOPLEFT",x+4,valueY) else apply:SetPoint("LEFT",edit,"RIGHT",8,0) end
          apply:SetScript("OnClick",function()
            local currentCallbacks=optionsCallbacks or callbacks
            local number
            if isPrice then
              local gold=tonumber(edits[1]:GetText()) or 0
              local silver=tonumber(edits[2]:GetText()) or 0
              local copper=tonumber(edits[3]:GetText()) or 0
              number=gold*10000+silver*100+copper
            else
              local raw=edit:GetText(); number=raw~="" and tonumber(raw) or 0
            end
            local current=currentCallbacks.options and currentCallbacks.options() or {}
            local previous=current[row.key] or {scope=(row.key=="excludeAbovePrice" or row.key=="includeBelowPrice") and "DESTROY" or "BOTH",qualities={poor=true,common=true,uncommon=true,rare=true,epic=true}}
            local value={enabled=previous.enabled==true,scope=previous.scope or "BOTH",value=number or previous.value or 0,qualities=previous.qualities or {poor=true,common=true,uncommon=true,rare=true,epic=true}}
            local changed,reason=currentCallbacks.setOption and currentCallbacks.setOption(row.key,value)
            self:Print(changed and (row.label.." updated.") or ("Option update failed: "..tostring(reason)))
            self:ShowOptions(currentCallbacks,"profile")
          end)
          local scopeChoices=addScopeChoices(row.key,110,scopeY,98,
            {enabled=true,scope=(row.key=="excludeAbovePrice" or row.key=="includeBelowPrice") and "DESTROY" or "BOTH",value=0,qualities={poor=true,common=true,uncommon=true,rare=true,epic=true}})
          local qualityButtons={}
          for quality=1,5 do
            local q=quality
            local qualityName=({"Poor","Common","Uncommon","Rare","Epic"})[quality]
            local button=createOptionCheck(({"Poor","Com","Unc","Rare","Epic"})[quality],110+(quality-1)*92,qualityY,88)
            button.optionGroup=row.key; button.optionQuality=qualityKeys[q]
            button.qualityRow=true; button.qualityRowY=qualityY
            optionsQualityRows[#optionsQualityRows+1]=button
            setOptionCheckHandler(button,function()
              local currentCallbacks=optionsCallbacks or callbacks
              local current=currentCallbacks.options and currentCallbacks.options() or {}
              local previous=current[row.key] or {}
              local qualities={poor=true,common=true,uncommon=true,rare=true,epic=true}
              for _,name in ipairs(qualityKeys) do if type(previous.qualities)~="table" or previous.qualities[name]==nil then qualities[name]=true else qualities[name]=previous.qualities[name] end end
              qualities[qualityKeys[q]]=not qualities[qualityKeys[q]]
              local value={enabled=previous.enabled==true,scope=previous.scope or ((row.key=="excludeAbovePrice" or row.key=="includeBelowPrice") and "DESTROY" or "BOTH"),value=previous.value or 0,qualities=qualities}
              local changed,reason=currentCallbacks.setOption and currentCallbacks.setOption(row.key,value)
              self:Print(changed and (row.label.." quality updated.") or ("Option update failed: "..tostring(reason)))
              self:ShowOptions(currentCallbacks,"profile")
            end)
            qualityButtons[quality]=button
          end
          optionsThresholdFields[index]={key=row.key,edit=edit,edits=edits,isPrice=isPrice,label=label,apply=apply,scopeChoices=scopeChoices,qualityButtons=qualityButtons,valueLabel=valueLabel,scopeLabel=scopeLabel,qualityLabel=qualityLabel}
        end
        optionsEquipmentTypeFields={}
        local function readAuctionSubclasses(classId)
          if type(api.GetAuctionItemClasses)~="function" or type(api.GetAuctionItemSubClasses)~="function" then return {} end
          local ok,classes=pcall(function() return {api.GetAuctionItemClasses()} end)
          if not ok or type(classes)~="table" or not classes[classId+1] then return {} end
          local success,values=pcall(function() return {api.GetAuctionItemSubClasses(classId+1)} end)
          if not success or type(values)~="table" then return {} end
          local result={}
          for index,name in ipairs(values) do if type(name)=="string" and name~="" then result[#result+1]={id=index-1,name=name} end end
          return result
        end
        local function typeDefaults()
          return {enabled=false,scope="BOTH",qualities={poor=true,common=false,uncommon=false,rare=false,epic=false},armor={},weapons={}}
        end
        local function copyMap(value)
          local result={}
          if type(value)=="table" then for id,enabled in pairs(value) do if type(id)=="number" and type(enabled)=="boolean" then result[id]=enabled end end end
          return result
        end
        local function createEquipmentTypeCard(key,titleText,top)
          local field={key=key}
          local toggle=createOptionCheck(titleText,24,top-8)
          local function toggleEquipmentType()
            local currentCallbacks=optionsCallbacks or callbacks
            local current=currentCallbacks.options and currentCallbacks.options() or {}
            local previous=current[key] or typeDefaults()
            local value={enabled=not previous.enabled,scope=previous.scope or "BOTH",qualities=previous.qualities or typeDefaults().qualities,
              armor=previous.armor or {},weapons=previous.weapons or {}}
            local changed,reason=currentCallbacks.setOption and currentCallbacks.setOption(key,value)
            self:Print(changed and (titleText.." updated.") or ("Option update failed: "..tostring(reason)))
            self:ShowOptions(currentCallbacks,"profile")
          end
          setOptionCheckHandler(toggle,toggleEquipmentType)
          bindCardClick(key,toggleEquipmentType)
          field.toggle=toggle
          field.scopeChoices=addScopeChoices(key,110,top-264,98,typeDefaults())
          local armorLabel=optionsContentFrame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
          armorLabel:SetPoint("TOPLEFT",24,top-64); armorLabel:SetText("Armor")
          local weaponLabel=optionsContentFrame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
          weaponLabel:SetPoint("TOPLEFT",24,top-134); weaponLabel:SetText("Weapons")
          field.labels={armorLabel,weaponLabel}
          field.typeButtons={}
          local function addTypeButtons(classId,property,y,width,step,columns)
            local types=readAuctionSubclasses(classId)
            if #types==0 then
              local unavailable=optionsContentFrame:CreateFontString(nil,"OVERLAY","GameFontDisableSmall")
              unavailable:SetPoint("TOPLEFT",24,y); unavailable:SetText("Equipment type list unavailable")
              field.labels[#field.labels+1]=unavailable
              return
            end
            for index,itemType in ipairs(types) do
              local position=index-1
              local column=position%columns; local row=math.floor(position/columns)
              local button=createOptionCheck(itemType.name,24+column*step,y-row*24,step-4)
              setOptionCheckHandler(button,function()
                local currentCallbacks=optionsCallbacks or callbacks
                local current=currentCallbacks.options and currentCallbacks.options() or {}
                local previous=current[key] or typeDefaults()
                local armor=copyMap(previous.armor); local weapons=copyMap(previous.weapons)
                local selected=property=="armor" and armor or weapons
                selected[itemType.id]=not selected[itemType.id]
                local value={enabled=previous.enabled,scope=previous.scope,qualities=previous.qualities,armor=armor,weapons=weapons}
                local changed,reason=currentCallbacks.setOption and currentCallbacks.setOption(key,value)
                self:Print(changed and (itemType.name.." selection updated.") or ("Option update failed: "..tostring(reason)))
                self:ShowOptions(currentCallbacks,"profile")
              end)
              field.typeButtons[#field.typeButtons+1]={button=button,item=itemType,property=property}
            end
          end
          addTypeButtons(4,"armor",top-86,96,104,5)
          addTypeButtons(2,"weapons",top-156,170,176,3)
          local qualityLabel=optionsContentFrame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
          qualityLabel:SetPoint("TOPLEFT",24,top-290); qualityLabel:SetText("Qualities")
          field.labels[#field.labels+1]=qualityLabel
          field.qualityButtons={}
          local qualityKeys={"poor","common","uncommon","rare","epic"}
          for index,name in ipairs(qualityKeys) do
            local button=createOptionCheck(({"Poor","Com","Unc","Rare","Epic"})[index],110+(index-1)*92,top-290,88)
            button.optionGroup=key; button.optionQuality=name
            button.qualityRow=true; button.qualityRowY=top-290
            optionsQualityRows[#optionsQualityRows+1]=button
            setOptionCheckHandler(button,function()
              local currentCallbacks=optionsCallbacks or callbacks
              local current=currentCallbacks.options and currentCallbacks.options() or {}
              local previous=current[key] or typeDefaults()
              local qualities={poor=true,common=false,uncommon=false,rare=false,epic=false}
              for _,qualityName in ipairs(qualityKeys) do
                if type(previous.qualities)=="table" and previous.qualities[qualityName]~=nil then qualities[qualityName]=previous.qualities[qualityName] end
              end
              qualities[name]=not qualities[name]
              local value={enabled=previous.enabled,scope=previous.scope,qualities=qualities,armor=previous.armor,weapons=previous.weapons}
              local changed,reason=currentCallbacks.setOption and currentCallbacks.setOption(key,value)
              self:Print(changed and (titleText.." quality updated.") or ("Option update failed: "..tostring(reason)))
              self:ShowOptions(currentCallbacks,"profile")
            end)
            field.qualityButtons[index]={button=button,name=name}
          end
          optionsEquipmentTypeFields[#optionsEquipmentTypeFields+1]=field
        end
        createEquipmentTypeCard("includeByEquipmentType","Include by equipment type",-650)
        createEquipmentTypeCard("excludeByEquipmentType","Exclude by equipment type",-1338)
        local function addGlobalToggle(key,labelText,description,top,height,read,encode)
          local card=addOptionCard(top,height or 64,true)
          optionCardFrames[key]=card
          local button=createOptionCheck(labelText,24,top-8)
          button.globalOptionKey=key
          optionsGlobalDecorations[#optionsGlobalDecorations+1]=button
          addGlobalText(description,52,top-34,470)
          local function toggle()
            local currentCallbacks=optionsCallbacks or callbacks
            local global=currentCallbacks.globalOptions and currentCallbacks.globalOptions() or {}
            local enabled=not read(global)
            local value=encode and encode(global,enabled) or enabled
            local changed,reason=currentCallbacks.setGlobalOption and currentCallbacks.setGlobalOption(key,value)
            self:Print(changed and (labelText.." updated.") or ("Option update failed: "..tostring(reason)))
            self:ShowOptions(currentCallbacks,"global")
          end
          setOptionCheckHandler(button,toggle)
          bindCardClick(key,toggle)
          optionsGlobalControls[#optionsGlobalControls+1]={key=key,label=labelText,button=button,read=read}
          return card
        end
        local function globalEnabled(key)
          return function(global) return global[key]==true end
        end
        addSection("Safety",-8,true)
        addGlobalToggle("safeDestroy","Safe Destroy","Require confirmation before destroying an item.",-30,64,globalEnabled("safeDestroy"))
        addGlobalToggle("safeSell","Safe Sell","Only sell up to 12 items at a time.",-104,64,globalEnabled("safeSell"))
        addSection("Interface",-178,true)
        addGlobalToggle("merchantButton","Merchant Button","Enable a button on the merchant frame.",-200,64,globalEnabled("merchantButton"))
        addGlobalToggle("minimapIcon","Minimap Icon","Enable an icon on the minimap.",-274,64,
          function(global) return type(global.minimapIcon)=="table" and global.minimapIcon.hide~=true end,
          function(global,enabled) return {hide=not enabled} end)
        addGlobalToggle("autoJunkFrame","Auto Junk Frame","Automatically show the Junk frame at a merchant when you have junk items, and close it once you don't.",-348,64,globalEnabled("autoJunkFrame"))
        addGlobalToggle("autoLootableFrame","Auto Lootable Frame","Automatically show the Lootable Items frame when you have items to loot, and close it once you don't.",-422,64,globalEnabled("autoLootableFrame"))
        addGlobalToggle("chatMessages","Chat Messages","Enable chat messages.",-496,112,
          function(global) return type(global.chatMessages)~="table" or global.chatMessages.enabled~=false end,
          function(global,enabled) return {enabled=enabled} end)
        addCardDivider(-546)
        addGlobalText("Detail",24,-554,78)
        local function addGlobalChoice(key,field,choices,x,y)
          local entry={key=key,field=field,controls={}}
          for index,choice in ipairs(choices) do
            local control=createOptionCheck(choice.label,x+(index-1)*100,y,96)
            optionsGlobalDecorations[#optionsGlobalDecorations+1]=control
            control:SetScript("OnClick",function()
              local currentCallbacks=optionsCallbacks or callbacks
              local value=field and {[field]=choice.value} or choice.value
              local changed,reason=currentCallbacks.setGlobalOption and currentCallbacks.setGlobalOption(key,value)
              self:Print(changed and (choice.label.." updated.") or ("Option update failed: "..tostring(reason)))
              self:ShowOptions(currentCallbacks,"global")
            end)
            entry.controls[#entry.controls+1]={button=control,value=choice.value,label=choice.label}
          end
          optionsGlobalChoices[#optionsGlobalChoices+1]=entry
        end
        addGlobalChoice("chatMessages","detail",{{value="REDUCED",label="Reduced"},{value="VERBOSE",label="Verbose"}},110,-554)
        addSection("Bags",-626,true)
        addGlobalToggle("itemTooltips","Bag Item Tooltips","Add Dejunk information to the tooltips of items in your bags.",-650,64,globalEnabled("itemTooltips"))
        addGlobalToggle("itemIcons","Bag Item Icons","Overlay an icon on junk items in your bags.",-724,112,globalEnabled("itemIcons"))
        addCardDivider(-774)
        addGlobalText("Size",24,-782,78)
        addGlobalChoice("itemIconStyle",nil,{{value="SMALL",label="Small"},{value="LARGE",label="Large"}},110,-782)
        local back=styleThemedButton(api.CreateFrame("Button",nil,optionsFrame))
        back:SetWidth(110); back:SetHeight(24); back:SetPoint("BOTTOMRIGHT",optionsFrame,"BOTTOMRIGHT",-20,18); back:SetText("Back")
        back:SetScript("OnClick",function() optionsFrame:Hide(); self:ShowConfig(callbacks) end)
        if mainContentFrame then back:Hide() end
      end
      local opts=callbacks.options and callbacks.options() or {}
      local qualityRule=opts.includeByQuality or {enabled=true}
      optionsFrame.scope=scope
      local activeProfile=callbacks.activeProfileName and callbacks.activeProfileName() or nil
      optionsFrame.pageTitle:SetText(scope=="global" and "Dejunk | Global Options" or
        ("Dejunk | Profile Options"..(activeProfile and (" ("..activeProfile..")") or "")))
      setTextColor(optionsFrame.pageTitle,"blue")
      optionsFrame.pageDescription:SetText(scope=="profile" and
        "These options only apply to characters using the active profile." or
        "These options apply to every character, regardless of active profile.")
      setTextColor(optionsFrame.pageDescription,"grey")
      optionsFrame.pageDescription:Show()
      if scope=="global" then optionsFrame.qualityTitle:Hide() else optionsFrame.qualityTitle:Show() end
      for _,entry in ipairs(optionsProfileDecorations or {}) do if scope=="profile" then entry:Show() else entry:Hide() end end
      for _,entry in ipairs(optionsGlobalDecorations or {}) do if scope=="global" then entry:Show() else entry:Hide() end end
      for _,entry in ipairs(optionsFields) do
        if (entry.global==true)==(scope=="global") then entry.button:Show() else entry.button:Hide() end
      end
      for _,button in ipairs(optionsQualityButtons) do
        if scope=="profile" then button:Show() else button:Hide() end
        setOptionCheckEnabled(button,qualityRule.enabled~=false)
      end
      for _,entry in ipairs(optionsThresholdFields) do
        if scope=="profile" then entry.label:Show(); entry.apply:Show()
        else entry.label:Hide(); entry.apply:Hide() end
        for _,input in ipairs(entry.edits) do if scope=="profile" then input:Show() else input:Hide() end end
        local option=opts[entry.key]
        local thresholdLabel=entry.key=="includeBelowItemLevel" and "Include below item level" or
          entry.key=="includeBelowPrice" and "Include below price" or
          entry.key=="excludeAboveItemLevel" and "Exclude above item level" or "Exclude above price"
        setOptionCheckChecked(entry.label,type(option)=="table" and option.enabled==true)
        setOptionCheckText(entry.label,thresholdLabel)
        if type(option)=="table" and option.enabled then entry.apply:Enable()
        else entry.apply:Disable() end
        -- WoW 3.3.5 EditBox has no Enable/Disable/SetEnabled methods. Keep
        -- threshold inputs editable; Apply remains disabled until enabled.
        local storedValue=type(option)=="table" and tonumber(option.value) or 0
        if entry.isPrice then
          local gold=math.floor(storedValue/10000)
          local silver=math.floor((storedValue%10000)/100)
          local copper=storedValue%100
          entry.edits[1]:SetText(tostring(gold)); entry.edits[2]:SetText(tostring(silver)); entry.edits[3]:SetText(tostring(copper))
        else
          entry.edit:SetText(tostring(storedValue))
        end
        local optionScope=type(option)=="table" and option.scope or ((entry.key=="excludeAbovePrice" or entry.key=="includeBelowPrice") and "DESTROY" or "BOTH")
        for _,control in ipairs(entry.scopeChoices) do
          setOptionCheckChecked(control,control.scopeValue==optionScope)
          if scope=="profile" then control:Show() else control:Hide() end
          setOptionCheckEnabled(control,type(option)=="table" and option.enabled==true)
        end
        for quality,button in ipairs(entry.qualityButtons) do
          local name=({"poor","common","uncommon","rare","epic"})[quality]
          local enabled=type(option)~="table" or type(option.qualities)~="table" or option.qualities[name]~=false
          setOptionCheckChecked(button,enabled)
          setOptionCheckText(button,({"Poor","Com","Unc","Rare","Epic"})[quality])
          if scope=="profile" then button:Show() else button:Hide() end
          setOptionCheckEnabled(button,type(option)=="table" and option.enabled==true)
        end
      end
      for _,entry in ipairs(optionsScopeFields) do
        local option=opts[entry.key]
        local selectedScope=type(option)=="table" and option.scope or "BOTH"
        for _,control in ipairs(entry.choices) do
          setOptionCheckChecked(control,control.scopeValue==selectedScope)
          if scope=="profile" then control:Show() else control:Hide() end
          setOptionCheckEnabled(control,type(option)=="table" and option.enabled==true)
        end
      end
      setOptionCheckChecked(optionsFrame.qualityTitle,qualityRule.enabled~=false)
      local unbound=opts.excludeUnboundEquipment
      if scope=="profile" then optionsUnboundQualityFields.title:Show() else optionsUnboundQualityFields.title:Hide() end
      for quality,button in ipairs(optionsUnboundQualityFields) do
        local name=({"poor","common","uncommon","rare","epic"})[quality]
        local enabled=type(unbound)~="table" or type(unbound.qualities)~="table" or unbound.qualities[name]~=false
        setOptionCheckChecked(button,enabled)
        setOptionCheckText(button,({"Poor","Com","Unc","Rare","Epic"})[quality])
        if scope=="profile" then button:Show() else button:Hide() end
        setOptionCheckEnabled(button,type(unbound)=="table" and unbound.enabled==true)
      end
      for _,entry in ipairs(optionsEquipmentTypeFields or {}) do
        local option=opts[entry.key] or {enabled=false,scope="BOTH",qualities={},armor={},weapons={}}
        local label=entry.key=="includeByEquipmentType" and "Include by equipment type" or "Exclude by equipment type"
          setOptionCheckChecked(entry.toggle,option.enabled==true)
          setOptionCheckText(entry.toggle,label)
        if scope=="profile" then entry.toggle:Show() else entry.toggle:Hide() end
        for _,control in ipairs(entry.scopeChoices) do
          setOptionCheckChecked(control,control.scopeValue==(option.scope or "BOTH"))
          if scope=="profile" then control:Show() else control:Hide() end
          setOptionCheckEnabled(control,option.enabled==true)
        end
        for _,frame in ipairs(entry.labels) do if scope=="profile" then frame:Show() else frame:Hide() end end
        for _,control in ipairs(entry.typeButtons) do
          local selected=control.property=="armor" and option.armor or option.weapons
          local enabled=type(selected)=="table" and selected[control.item.id]==true
          setOptionCheckChecked(control.button,enabled)
          setOptionCheckText(control.button,control.item.name)
          if scope=="profile" then control.button:Show() else control.button:Hide() end
          setOptionCheckEnabled(control.button,option.enabled==true)
        end
        for _,control in ipairs(entry.qualityButtons) do
          local enabled=type(option.qualities)~="table" or option.qualities[control.name]~=false
          setOptionCheckChecked(control.button,enabled)
          setOptionCheckText(control.button,({poor="Poor",common="Com",uncommon="Unc",rare="Rare",epic="Epic"})[control.name] or control.name)
          if scope=="profile" then control.button:Show() else control.button:Hide() end
          setOptionCheckEnabled(control.button,option.enabled==true)
        end
      end
      local labels={"Poor","Common","Uncommon","Rare","Epic"}
      for quality=0,4 do
        local qualities=opts.includeByQuality and opts.includeByQuality.qualities or opts.quality or {}
        local enabled=qualities[labels[quality+1]:lower()]
        if enabled==nil then enabled=opts.quality and opts.quality[quality] end
        setOptionCheckChecked(optionsQualityButtons[quality+1],enabled==true)
        setOptionCheckText(optionsQualityButtons[quality+1],({"Poor","Com","Unc","Rare","Epic"})[quality+1])
      end
      local global=callbacks.globalOptions and callbacks.globalOptions() or {}
      self:UpdateMinimapIcon(global,callbacks.setGlobalOption,function() self:ToggleConfig(callbacks) end,callbacks.globalOptions)
      for _,entry in ipairs(optionsFields) do
        local source=entry.global and global or opts; local value=source[entry.key]
        local enabled=type(value)=="table" and value.enabled or value==true
        if entry.global then entry.button:SetText(entry.label..": "..(enabled and "ON" or "OFF"))
        else
          setOptionCheckChecked(entry.button,enabled==true)
          setOptionCheckText(entry.button,entry.label)
        end
      end
      for _,entry in ipairs(optionsGlobalControls or {}) do
        setOptionCheckChecked(entry.button,entry.read(global)==true)
        setOptionCheckText(entry.button,entry.label)
      end
      for _,entry in ipairs(optionsGlobalChoices or {}) do
        local state=global[entry.key]
        local selected=entry.field and type(state)=="table" and state[entry.field] or state
        for _,choice in ipairs(entry.controls) do setOptionCheckChecked(choice.button,choice.value==selected) end
      end
      local activeProfile=callbacks.activeProfileName and callbacks.activeProfileName() or nil
      optionsFrame.pageTitle:SetText(scope=="global" and "Dejunk | Global Options" or
        ("Dejunk | Profile Options"..(activeProfile and (" ("..activeProfile..")") or "")))
      setTextColor(optionsFrame.pageTitle,"blue")
      setConfigPageVisible(listFrame,false)
      setConfigPageVisible(profileFrame,false)
      if optionsPageComponent and configWaffleRoot then
        selectConfigScreen("options")
        local pageWidth=optionsFrame:GetWidth()
        if pageWidth and pageWidth>120 then
          local contentWidth=math.max(420,pageWidth-44)
          optionsContentFrame:SetWidth(contentWidth)
          optionsFrame.pageDescription:SetWidth(pageWidth-50)
          for _,card in ipairs(optionsOptionCards or {}) do card:SetWidth(contentWidth-20) end
          for _,divider in ipairs(optionsCardDividers or {}) do divider:SetWidth(contentWidth-56) end
          for _,description in ipairs(optionsResponsiveDescriptions or {}) do
            local x=description.optionDescriptionX or 0
            description:SetWidth(math.max(100,contentWidth-x-20))
          end
          local qualityStep=math.min(92,(contentWidth-120)/5)
          for _,control in ipairs(optionsQualityRows or {}) do
            local order=({poor=0,common=1,uncommon=2,rare=3,epic=4})[control.optionQuality]
            if order then
              control:ClearAllPoints()
              control:SetPoint("TOPLEFT",110+order*qualityStep,control.qualityRowY or 0)
              control.labelHit:SetWidth(math.max(16,qualityStep-14))
            end
          end
        end
      else
        setConfigPageVisible(optionsFrame,true)
      end
    end,function(err)
      if api.debugstack then return tostring(err).."\n"..api.debugstack(2,8,8) end
      return tostring(err)
    end)
    if not ok then
      self:Print("Options window error: "..tostring(optionsError).."; use /djw rules list and /djw rules quality|minlevel|maxlevel|maxprice.")
      if optionsFrame then optionsFrame:Hide() end
      selectConfigScreen("overview")
    end
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
        reportWaffleRoot,reportFrame=createWaffleWindow("DejunkWotLKReadOnlyReport",600,420)
        local panel = reportFrame or api.CreateFrame("Frame", "DejunkWotLKReadOnlyReport", api.UIParent)
        panel:SetWidth(600); panel:SetHeight(420); panel:SetPoint("CENTER")
        panel:SetFrameStrata("DIALOG"); panel:EnableMouse(true)
        panel:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 8, right = 8, top = 8, bottom = 8 } })
        local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", 20, -18)
        reportTitle=title
        local close = styleCloseButton(api.CreateFrame("Button", nil, panel))
        close:SetWidth(24); close:SetHeight(24)
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

  function runtime:UpdateJunkFrame(data)
    if not junkFrame then return false end
    for _,row in ipairs(junkRows or {}) do row:Hide() end
    if type(data)~="table" then
      junkSummary:SetText("Bag data unavailable. Refreshing…")
      junkRowsContent:SetHeight(1)
      return false
    end
    junkSummary:SetText("Sell candidates: "..tostring(data.sellable or 0).."   Destroy candidates: "..tostring(data.destroyable or 0))
    if #data.items==0 then
      if not junkEmptyRow then
        junkEmptyRow=junkRowsContent:CreateFontString(nil,"ARTWORK","GameFontHighlight")
        junkEmptyRow:SetPoint("TOPLEFT",12,-8); junkEmptyRow:SetWidth(500); junkEmptyRow:SetJustifyH("LEFT")
      end
      junkEmptyRow:SetText("No junk items."); junkEmptyRow:Show(); junkRowsContent:SetHeight(32)
      return true
    end
    if junkEmptyRow then junkEmptyRow:Hide() end
    for index,item in ipairs(data.items) do
      local card=junkRows[index]
      if not card then
        card=createReadOnlyItemCard(junkRowsContent,510,44,(index-1)*48+4)
        junkRows[index]=card
      end
      local sell=item.sell and item.sell.reasonCode or "UNKNOWN"
      local destroy=item.destroy and item.destroy.reasonCode or "UNKNOWN"
      card.icon:SetTexture(item.texture or "Interface\\Icons\\INV_Misc_QuestionMark")
      local colors={[0]={1,0.35,0.35},[1]={0.85,0.85,0.85},[2]={0.25,0.85,0.3},[3]={0.25,0.55,1},[4]={0.7,0.35,1}}
      local color=colors[item.quality] or {0.7,0.7,0.7}
      card.accent:SetVertexColor(color[1],color[2],color[3],1)
      card.label:SetText((item.name or ("Item #"..tostring(item.itemId))).." (#"..tostring(item.itemId)..") x"..tostring(item.count or 1))
      card.detail:SetText("Sell: "..tostring(sell).."   Destroy: "..tostring(destroy))
      card:Show()
    end
    junkRowsContent:SetHeight(math.max(32,#data.items*48))
    return true
  end

  function runtime:ToggleJunkFrame(data)
    if not junkFrame then
      junkFrame=api.CreateFrame("Frame","DejunkWotLKJunkFrame",api.UIParent)
      junkFrame:SetFrameStrata("DIALOG"); junkFrame:SetWidth(560); junkFrame:SetHeight(430)
      setSavedPoint(junkFrame,"junkFrame"); junkFrame:EnableMouse(true); junkFrame:SetMovable(true)
      junkFrame:RegisterForDrag("LeftButton")
      junkFrame:SetScript("OnDragStart",function(self) if self.StartMoving then self:StartMoving() end end)
      junkFrame:SetScript("OnDragStop",function(self) if self.StopMovingOrSizing then self:StopMovingOrSizing() end; saveCurrentPoint(self,"junkFrame") end)
      junkFrame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
      junkFrame:SetBackdropColor(0,0,0,0.94); junkFrame:SetBackdropBorderColor(0.35,0.35,0.35,1)
      junkFrame:SetScript("OnShow",function() junkVisible=true end)
      junkFrame:SetScript("OnHide",function() junkVisible=false end)
      local header=api.CreateFrame("Frame",nil,junkFrame); header:SetHeight(34); header:SetPoint("TOPLEFT",0,0); header:SetPoint("TOPRIGHT",0,0)
      header:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8"}); header:SetBackdropColor(30/255,30/255,30/255,1)
      junkTitle=header:CreateFontString(nil,"ARTWORK","GameFontNormal")
      junkTitle:SetPoint("LEFT",12,0); junkTitle:SetText("Junk Items"); setTextColor(junkTitle,"blue")
      local close=api.CreateFrame("Button",nil,header); close:SetWidth(26); close:SetHeight(26); close:SetPoint("RIGHT",-5,0)
      styleCloseButton(close); close:SetScript("OnClick",function() junkFrame:Hide(); junkVisible=false end)
      junkSummary=junkFrame:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
      junkSummary:SetPoint("TOPLEFT",14,-43); junkSummary:SetText("Scanning bags…")
      junkScroll=api.CreateFrame("ScrollFrame",nil,junkFrame,"UIPanelScrollFrameTemplate")
      junkScroll:SetPoint("TOPLEFT",12,-66); junkScroll:SetPoint("BOTTOMRIGHT",-30,12)
      junkRowsContent=api.CreateFrame("Frame",nil,junkScroll); junkRowsContent:SetWidth(510); junkRowsContent:SetHeight(1)
      junkScroll:SetScrollChild(junkRowsContent); junkRows={}
    end
    self:UpdateJunkFrame(data)
    if junkVisible then junkFrame:Hide(); junkVisible=false else junkFrame:Show(); junkVisible=true end
    return true
  end

  function runtime:ShowJunkFrame(data)
    if junkVisible then return self:UpdateJunkFrame(data) end
    return self:ToggleJunkFrame(data)
  end

  function runtime:HideJunkFrame()
    if junkFrame then junkFrame:Hide() end
    junkVisible=false
  end

  function runtime:IsJunkFrameVisible() return junkVisible==true end

  function runtime:UpdateLootableFrame(data)
    if not lootableFrame then return false end
    for _,row in ipairs(lootableRows or {}) do row:Hide() end
    if type(data)~="table" then
      lootableSummary:SetText("Bag data unavailable. Refreshing…")
      lootableRowsContent:SetHeight(1)
      return false
    end
    lootableSummary:SetText("Lootable stacks: "..tostring(data.count or 0))
    if #data.items==0 then
      if not lootableEmptyRow then
        lootableEmptyRow=lootableRowsContent:CreateFontString(nil,"ARTWORK","GameFontHighlight")
        lootableEmptyRow:SetPoint("TOPLEFT",10,-8); lootableEmptyRow:SetWidth(300); lootableEmptyRow:SetJustifyH("LEFT")
      end
      lootableEmptyRow:SetText("No lootable items."); lootableEmptyRow:Show(); lootableRowsContent:SetHeight(32)
      return true
    end
    if lootableEmptyRow then lootableEmptyRow:Hide() end
    for index,item in ipairs(data.items) do
      local card=lootableRows[index]
      if not card then
        card=createReadOnlyItemCard(lootableRowsContent,300,40,(index-1)*44+4)
        lootableRows[index]=card
      end
      card.icon:SetTexture(item.texture or "Interface\\Icons\\INV_Misc_QuestionMark")
      card.label:SetText((item.name or ("Item #"..tostring(item.itemId))).." (#"..tostring(item.itemId)..") x"..tostring(item.count or 1))
      card.detail:SetText("Bag "..tostring(item.bag).." / Slot "..tostring(item.slot))
      card:Show()
    end
    lootableRowsContent:SetHeight(math.max(32,#data.items*44))
    return true
  end

  function runtime:ShowLootableFrame(data)
    if not lootableFrame then
      lootableFrame=api.CreateFrame("Frame","DejunkWotLKLootableFrame",api.UIParent)
      lootableFrame:SetFrameStrata("DIALOG"); lootableFrame:SetWidth(350); lootableFrame:SetHeight(330)
      setSavedPoint(lootableFrame,"lootableFrame"); lootableFrame:EnableMouse(true); lootableFrame:SetMovable(true)
      lootableFrame:RegisterForDrag("LeftButton")
      lootableFrame:SetScript("OnDragStart",function(self) if self.StartMoving then self:StartMoving() end end)
      lootableFrame:SetScript("OnDragStop",function(self) if self.StopMovingOrSizing then self:StopMovingOrSizing() end; saveCurrentPoint(self,"lootableFrame") end)
      lootableFrame:SetScript("OnShow",function() lootableVisible=true end)
      lootableFrame:SetScript("OnHide",function() lootableVisible=false end)
      lootableFrame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
      lootableFrame:SetBackdropColor(0,0,0,0.94); lootableFrame:SetBackdropBorderColor(0.35,0.35,0.35,1)
      local header=api.CreateFrame("Frame",nil,lootableFrame); header:SetHeight(34); header:SetPoint("TOPLEFT",0,0); header:SetPoint("TOPRIGHT",0,0)
      header:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8"}); header:SetBackdropColor(30/255,30/255,30/255,1)
      lootableTitle=header:CreateFontString(nil,"ARTWORK","GameFontNormal")
      lootableTitle:SetPoint("LEFT",12,0); lootableTitle:SetText("Lootable Items"); setTextColor(lootableTitle,"blue")
      local close=api.CreateFrame("Button",nil,header); close:SetWidth(26); close:SetHeight(26); close:SetPoint("RIGHT",-5,0)
      styleCloseButton(close); close:SetScript("OnClick",function() lootableFrame:Hide(); lootableVisible=false end)
      lootableSummary=lootableFrame:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
      lootableSummary:SetPoint("TOPLEFT",14,-43); lootableSummary:SetText("Scanning bags…")
      lootableScroll=api.CreateFrame("ScrollFrame",nil,lootableFrame,"UIPanelScrollFrameTemplate")
      lootableScroll:SetPoint("TOPLEFT",12,-66); lootableScroll:SetPoint("BOTTOMRIGHT",-30,12)
      lootableRowsContent=api.CreateFrame("Frame",nil,lootableScroll); lootableRowsContent:SetWidth(300); lootableRowsContent:SetHeight(1)
      lootableScroll:SetScrollChild(lootableRowsContent); lootableRows={}
    end
    self:UpdateLootableFrame(data)
    lootableFrame:Show(); lootableVisible=true
    return true
  end

  function runtime:HideLootableFrame()
    if lootableFrame then lootableFrame:Hide() end
    lootableVisible=false
  end

  function runtime:ToggleLootableFrame(data)
    if lootableVisible then self:HideLootableFrame(); return true end
    if type(data)=="table" and (data.count or 0)>0 then return self:ShowLootableFrame(data) end
    return false
  end

  function runtime:IsLootableFrameVisible() return lootableVisible==true end

  function runtime:RegisterBagTooltips(getDecisions)
    if bagTooltipHooked then return true end
    local tooltip=api.GameTooltip
    if type(api.hooksecurefunc)~="function" or not tooltip or type(tooltip.AddLine)~="function" or
        type(tooltip.AddDoubleLine)~="function" then return false,"TOOLTIP_HOOK_UNAVAILABLE" end
    local ok,reason=pcall(api.hooksecurefunc,tooltip,"SetBagItem",function(frame,bag,slot)
      if readingTooltip or type(getDecisions)~="function" then return end
      local success,sell,destroy=pcall(getDecisions,bag,slot)
      if not success or not sell or not destroy then return end
      frame:AddLine(" ")
      local sellJunk=sell.result=="JUNK"
      local destroyJunk=destroy.result=="JUNK"
      frame:AddDoubleLine(sellJunk and "Selling" or "Not selling",tostring(sell.reasonCode or "UNKNOWN"),
        sellJunk and 1 or 0.45,sellJunk and 0.25 or 0.9,sellJunk and 0.25 or 0.45,1,1,1)
      frame:AddDoubleLine(destroyJunk and "Destroying" or "Not destroying",tostring(destroy.reasonCode or "UNKNOWN"),
        destroyJunk and 1 or 0.45,destroyJunk and 0.25 or 0.9,destroyJunk and 0.25 or 0.45,1,1,1)
      frame:Show()
    end)
    if not ok then return false,tostring(reason) end
    bagTooltipHooked=true
    return true
  end
  return runtime
end
