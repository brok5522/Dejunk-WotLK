assert(_VERSION=="Lua 5.1")
local H=dofile("tests/harness.lua")
local world=H.New():Load()
local Addon=world.addon
local uiFrames={}
local ui={UIParent={}}
setmetatable(ui,{__index=world.api})
local cursorItemId
ui.GetCursorInfo=function() if cursorItemId then return "item",cursorItemId end end
ui.ClearCursor=function() cursorItemId=nil end
ui.InterfaceOptions_AddCategory=function(panel) ui.registeredOptionsCategory=panel end
ui.overrideBindings={}
ui.ClearOverrideBindings=function(owner) owner.overrides={}; ui.overrideBindings[owner]=owner.overrides end
ui.SetOverrideBindingClick=function(owner,priority,key,buttonName)
  owner.overrides=owner.overrides or {}; owner.overrides[key]=buttonName; ui.overrideBindings[owner]=owner.overrides
end
ui.InCombatLockdown=function() return ui.combatLocked==true end
ui.GetTime=function() return ui.now or 10 end
ui.GetBindingAction=function(key) return key=="K" and "TOGGLEBACKPACK" or "" end
ui.GetBindingText=function(value,prefix)
  if prefix=="BINDING_NAME_" and value=="TOGGLEBACKPACK" then return "Toggle Backpack" end
  return value
end
ui.bindingWrites=0
ui.SetBinding=function() ui.bindingWrites=ui.bindingWrites+1 end
ui.SaveBindings=function() ui.bindingWrites=ui.bindingWrites+1 end

local function object(kind,name,parent,template)
  local frame={kind=kind,name=name,parent=parent,template=template,scripts={},children={},enabled=true,text=""}
  function frame:SetWidth(value) self.width=value end
  function frame:GetScript(name) return self.scripts[name] end
  function frame:SetHeight(value) self.height=value end
  function frame:SetAlpha(value) self.alpha=value end
  function frame:SetPoint(...) self.point={...} end
  function frame:GetPoint(index) if index==nil or index==1 then return unpack(self.point or {}) end end
  function frame:SetAllPoints(relative) self.allPoints=relative end
  function frame:ClearAllPoints() self.point=nil end
  function frame:SetParent(parent) self.parent=parent end
  function frame:SetFrameStrata(value) self.strata=value end
  function frame:SetFrameLevel(value) self.frameLevel=value end
  function frame:SetMovable(value) self.movable=value end
  function frame:RegisterForDrag(...) self.dragButtons={...} end
  function frame:StartMoving() self.moving=true end
  function frame:StopMovingOrSizing() self.moving=false end
  function frame:EnableMouse(value) self.mouse=value end
  function frame:EnableMouseWheel(value) self.mouseWheel=value end
  function frame:EnableKeyboard(value) self.keyboard=value end
  function frame:SetBackdrop(value) self.backdrop=value end
  function frame:SetBackdropColor(...) self.backdropColor={...} end
  function frame:SetBackdropBorderColor(...) self.borderColor={...} end
  function frame:SetBackdrop(value) self.backdrop=value end
  function frame:SetAutoFocus(value) self.autoFocus=value end
  function frame:SetMaxLetters(value) self.maxLetters=value end
  function frame:SetNumeric(value) self.numeric=value end
  function frame:SetFontObject(value) self.fontObject=value end
  function frame:SetTextColor(...) self.textColor={...} end
  function frame:SetTextInsets(...) self.textInsets={...} end
  function frame:SetJustifyH(value) self.justify=value end
  function frame:SetJustifyV(value) self.justifyV=value end
  function frame:SetWordWrap(value) self.wordWrap=value end
  function frame:SetMultiLine(value) self.multiline=value end
  function frame:SetScrollChild(child) self.scrollChild=child end
  function frame:SetScrollChildRect() end
  function frame:SetTextHeight(value) self.textHeight=value end
  function frame:SetFocus() self.focused=true; self.focusedWhileVisible=self.shown==true and self.parent and self.parent.shown==true end
  function frame:SetVerticalScroll(value) self.verticalScroll=value end
  function frame:GetVerticalScroll() return self.verticalScroll or 0 end
  function frame:SetScript(event,callback) self.scripts[event]=callback end
  function frame:RegisterForClicks(...) self.registeredClicks={...} end
  function frame:RegisterEvent(event) self.registeredEvents=self.registeredEvents or {}; self.registeredEvents[event]=true end
  function frame:SetText(value)
    if self.kind=="CheckButton" then error("legacy CheckButton has no SetText method") end
    self.text=value
    if self.kind=="EditBox" and self.scripts.OnTextChanged then self.scripts.OnTextChanged(self) end
  end
  function frame:SetChecked(value) self.checked=value end
  function frame:GetChecked() if ui.numericChecked then return self.checked and 1 or nil end; return self.checked end
  function frame:GetText() return self.text end
  function frame:GetWidth() return self.width end
  function frame:GetHeight() return self.height or 0 end
  function frame:GetParent() return self.parent end
  function frame:GetFrameLevel()
    if self.frameLevel~=nil then return self.frameLevel end
    if self.parent and type(self.parent.GetFrameLevel)=="function" then return self.parent:GetFrameLevel()+1 end
    return 1
  end
  function frame:Enable() if self.kind=="EditBox" then error("legacy EditBox has no Enable method") end; self.enabled=true end
  function frame:Disable() if self.kind=="EditBox" then error("legacy EditBox has no Disable method") end; self.enabled=false end
  function frame:SetEnabled(value) if self.kind=="EditBox" then error("legacy EditBox has no SetEnabled method") end; self.enabled=value end
  function frame:Show() self.shown=true end
  function frame:Hide() self.shown=false end
  function frame:IsShown() return self.shown==true end
  function frame:GetID() return self.id end
  function frame:GetName() return self.name end
  function frame:ClearFocus() self.focused=false end
  function frame:SetFocus() self.focused=true; self.focusedWhileVisible=self.shown==true and self.parent and self.parent.shown==true end
  function frame:HighlightText() self.highlighted=true end
  function frame:CreateFontString(fontName,layer,template)
    local child=object("FontString",fontName,self)
    child.layer,child.template=layer,template
    self.children[#self.children+1]=child
    return child
  end
  function frame:CreateTexture(textureName,layer,template)
    local child=object("Texture",textureName,self,template)
    child.layer=layer; self.children[#self.children+1]=child; return child
  end
  function frame:SetTexture(value) self.texture=value end
  function frame:SetNormalTexture(value) self.normalTexture=value end
  function frame:SetPushedTexture(value) self.pushedTexture=value end
  function frame:SetHighlightTexture(value) self.highlightTexture=value end
  function frame:GetFontString() return self.fontString end
  function frame:SetVertexColor(...) self.vertexColor={...} end
  function frame:Click(button)
    assert(self.enabled~=false,"clicked disabled control")
    assert(self.scripts.OnClick,"control has no click handler")
    self.scripts.OnClick(self,button or "LeftButton")
  end
  uiFrames[#uiFrames+1]=frame
  return frame
end
ui.CreateFrame=function(kind,name,parent,template) return object(kind,name,parent,template) end
ui.MerchantFrame=object("Frame","MerchantFrame",ui); ui.MerchantFrame:Show()
ui.NUM_CONTAINER_FRAMES=1
ui.MAX_CONTAINER_ITEMS=36
ui.GetContainerNumSlots=function(bag) return bag==0 and 1 or 0 end
ui.ContainerFrame1=object("Frame","ContainerFrame1",ui); ui.ContainerFrame1.id=0; ui.ContainerFrame1:Show()
ui.ContainerFrame1Item1=object("Button","ContainerFrame1Item1",ui.ContainerFrame1); ui.ContainerFrame1Item1.id=1
ui.Minimap=object("Frame","Minimap",ui)
function ui.Minimap:GetCenter() return 100,100 end
function ui.Minimap:GetEffectiveScale() return 1 end
ui.GetCursorPosition=function() return 180,100 end
ui.IsShiftKeyDown=function() return ui.shiftDown==true end
ui.IsControlKeyDown=function() return ui.controlDown==true end
ui.IsAltKeyDown=function() return ui.altDown==true end

local activeId="profile-1"
local activeName="Test"
local rules={}
local messages={}
local runtime=Addon.Runtime.New(setmetatable({print=function(message) messages[#messages+1]=message end},{__index=ui}))
local bagTooltipHook,hookCount
ui.GameTooltip={lines={},AddLine=function(self,text) self.lines[#self.lines+1]={text=text} end,
  AddDoubleLine=function(self,left,right) self.lines[#self.lines+1]={left=left,right=right} end,
  SetOwner=function(self,owner) self.owner=owner end,
  SetText=function(self,text) self.text=text end,
  SetBagItem=function(self,bag,slot) self.bag,self.slot=bag,slot end,
  Hide=function(self) self.shown=false end,
  Show=function(self) self.shown=true end,
  GetItem=function(self) return self.itemName,self.itemLink end}
ui.hooksecurefunc=function(target,name,hook)
  if target==ui.GameTooltip and name=="SetBagItem" then
    bagTooltipHook=hook; hookCount=(hookCount or 0)+1
  elseif target=="ContainerFrame_Update" then
    ui.containerUpdateHook=hook
  elseif target==ui and name=="ContainerFrame_Update" then
    ui.containerUpdateHook=hook
  else error("unexpected secure hook") end
end
ui.ContainerFrame_Update=function() end
assert(runtime:RegisterBagTooltips(function()
  return {result="JUNK",reasonCode="QUALITY"},{result="KEEP",reasonCode="EXCLUDED"}
end),"legacy bag tooltip hook did not register")
bagTooltipHook(ui.GameTooltip,0,1)
assert(ui.GameTooltip.shown and ui.GameTooltip.lines[2].text:find("Dejunk",1,true) and
  ui.GameTooltip.lines[3].text:find("Selling",1,true) and
  ui.GameTooltip.lines[4].text:find("Included by quality",1,true) and
  ui.GameTooltip.lines[5].text:find("Not Destroying",1,true),"bag tooltip omitted readable filter decisions")
assert(runtime:RegisterBagTooltips(function() end) and hookCount==1,"bag tooltip hook registered more than once")
assert(runtime:RegisterBagIcons(function()
  return {result="JUNK"},{result="KEEP"}
end),"bag icon provider did not register")
assert(runtime:UpdateBagIcons({itemIcons=true,itemIconStyle="SMALL"}) and
  ui.ContainerFrame1Item1.dejunkWotLKIconOverlay.shown,"small junk overlay did not appear")
assert(ui.ContainerFrame1Item1.dejunkWotLKIconOverlay.texture=="Interface\\AddOns\\Dejunk-WotLK\\assets\\dejunk-icon",
  "junk overlay texture did not load")
runtime:UpdateBagIcons({itemIcons=true,itemIconStyle="LARGE"})
assert(ui.ContainerFrame1Item1.dejunkWotLKIconBackground.shown and
  ui.ContainerFrame1Item1.dejunkWotLKIconBackground.vertexColor[4]==0.75,
  "large bag overlay omitted the reference dark background")
assert(ui.ContainerFrame1Item1.dejunkWotLKIconOverlay.allPoints==ui.ContainerFrame1Item1,
  "large overlay did not fill the item button")
runtime:RegisterBagIcons(function() return {result="KEEP"},{result="KEEP"} end)
assert(not ui.ContainerFrame1Item1.dejunkWotLKIconOverlay.shown,"stale junk overlay was not cleared")
assert(not ui.ContainerFrame1Item1.dejunkWotLKIconBackground.shown,"stale bag overlay background was not cleared")
runtime:UpdateBagIcons({itemIcons=false})
assert(not ui.ContainerFrame1Item1.dejunkWotLKIconOverlay.shown,"disabled item icons remained visible")
local savedWindowPoint
runtime:SetWindowPointHandlers(function(key)
  if key=="junkFrame" then return {point="TOPLEFT",relativePoint="TOPLEFT",offsetX=25,offsetY=-30} end
end,function(key,value) savedWindowPoint={key=key,value=value}; return true end)
local openedCategoryTarget
assert(runtime:RegisterOptionsCategory(function(screen) openedCategoryTarget=screen end),
  "legacy AddOns category was not registered")
assert(ui.registeredOptionsCategory==runtime:GetOptionsCategory() and ui.registeredOptionsCategory.name=="Dejunk",
  "AddOns category did not register the named Dejunk panel")
local openOptions,openProfiles
for _,frame in ipairs(uiFrames) do
  if frame.kind=="Button" and frame.text=="Open Dejunk" then openOptions=frame end
  if frame.kind=="Button" and frame.text=="Open Profiles" then openProfiles=frame end
end
assert(openOptions and openProfiles,"AddOns category is missing the main or profile entry")
openOptions:Click(); assert(openedCategoryTarget=="main")
openProfiles:Click(); assert(openedCategoryTarget=="profiles")
local callbacks={
  activeProfileId=function() return activeId end,
  activeProfileName=function() return activeName end,
  listRules=function() return rules end,
  addRule=function(rule) rules[#rules+1]=rule; return true end,
  removeRule=function(id)
    for index,rule in ipairs(rules) do if rule.id==id then table.remove(rules,index); return true end end
    return false,"UNKNOWN_RULE"
  end
}
local function control(kind,text)
  for _,frame in ipairs(uiFrames) do if frame.kind==kind and frame.text==text then return frame end end
  error("missing "..kind.." with text "..tostring(text))
end
local function lastControl(kind,text,template)
  for index=#uiFrames,1,-1 do
    local frame=uiFrames[index]
    if frame.kind==kind and (text==nil or frame.text==text) and (not template or frame.template==template) then return frame end
  end
  error("missing latest "..kind.." with text "..tostring(text))
end
local function lastChild(parent,kind,template)
  for index=#uiFrames,1,-1 do
    local frame=uiFrames[index]
    if frame.parent==parent and frame.kind==kind and (not template or frame.template==template) then return frame end
  end
  error("missing child control")
end
local function namedFrame(name)
  for _,frame in ipairs(uiFrames) do if frame.name==name then return frame end end
end

local minimapState={minimapIcon={hide=false,angle=220}}
local savedMinimapOptions,openFromMinimap=0,0
assert(runtime:UpdateMinimapIcon(minimapState,
  function(_,value) for key,entry in pairs(value) do minimapState.minimapIcon[key]=entry end; savedMinimapOptions=savedMinimapOptions+1; return true end,
  function() openFromMinimap=openFromMinimap+1 end,
  function() return minimapState end))
local minimapButton=namedFrame("DejunkWotLKMinimapButton")
assert(minimapButton and minimapButton.shown and minimapButton.dragButtons[1]=="LeftButton",
  "minimap icon did not appear with a movable button")
minimapButton.scripts.OnClick(minimapButton,"LeftButton")
assert(openFromMinimap==1,"minimap icon click did not open the addon")
minimapButton.scripts.OnClick(minimapButton,"RightButton")
assert(minimapState.minimapIcon.hide==false and minimapButton.shown==true and
  messages[#messages]:find("Junk items are unavailable",1,true),
  "minimap right click hid the icon instead of requesting the Junk window")
minimapState.minimapIcon.hide=false
assert(runtime:UpdateMinimapIcon(minimapState),"minimap icon could not be shown again")
minimapButton.scripts.OnDragStart(minimapButton)
minimapButton.scripts.OnUpdate(minimapButton,0.016)
minimapButton.scripts.OnDragStop(minimapButton)
assert(math.abs(minimapState.minimapIcon.angle)<0.01 and savedMinimapOptions>=1,
  "minimap dragging did not save its normalized position")
assert(runtime:ToggleJunkFrame({sellable=1,destroyable=2,items={{itemId=123,name="Example",count=2,quality=0,unitVendorPrice=3,texture="Interface\\Icons\\INV_Misc_Junk_01",
  sell={reasonCode="QUALITY"},destroy={reasonCode="QUALITY"}},
  {itemId=456,name="Another",count=1,sell={reasonCode="KEEP"},destroy={reasonCode="QUALITY"}}}}),
  "read-only Junk frame failed to open")
local junkWindow=namedFrame("DejunkWotLKJunkFrame")
assert(junkWindow and junkWindow.shown,"Junk frame did not become visible")
assert(junkWindow.width==350 and junkWindow.height==400 and junkWindow.strata=="DIALOG" and junkWindow.settingsButton and
  junkWindow.startSellingButton and junkWindow.startSellingButton.enabled==false and
  junkWindow.destroyNextButton and junkWindow.destroyNextButton.enabled==false,
  "Junk window controls or upstream dimensions are missing / unsafe actions are enabled")
local junkHeader
for _,frame in ipairs(uiFrames) do
  if frame.kind=="Frame" and frame.parent==junkWindow and frame.height==34 and frame.backdrop then junkHeader=frame end
end
assert(junkHeader,"Junk window title bar was not created")
assert(junkWindow.point[1]=="TOPLEFT" and junkWindow.point[4]==25 and junkWindow.point[5]==-30,
  "Junk frame did not restore its saved point")
junkWindow.point={"BOTTOMRIGHT",ui.UIParent,"BOTTOMRIGHT",-50,60}
junkWindow.scripts.OnDragStop(junkWindow)
assert(savedWindowPoint and savedWindowPoint.key=="junkFrame" and savedWindowPoint.value.point=="BOTTOMRIGHT" and
  savedWindowPoint.value.offsetX==-50 and savedWindowPoint.value.offsetY==60,"dragged Junk frame point did not persist")
local junkDetail
local staleJunkRow
for _,frame in ipairs(uiFrames) do
  if frame.kind=="FontString" and frame.text=="Price unavailable" then junkDetail=frame end
  if frame.kind=="FontString" and frame.text and frame.text:find("[Another]",1,true) then staleJunkRow=frame end
end
assert(junkDetail,"Junk frame omitted the unavailable-price hint")
assert(staleJunkRow,"Junk frame omitted later candidate rows")
local junkIcon,qualityAccent
for _,frame in ipairs(uiFrames) do
  if frame.kind=="Texture" and frame.texture=="Interface\\Icons\\INV_Misc_Junk_01" then junkIcon=frame end
  if frame.kind=="Texture" and frame.vertexColor and frame.vertexColor[1]==157/255 and frame.vertexColor[2]==157/255 then qualityAccent=frame end
end
assert(junkIcon and qualityAccent and qualityAccent.texture=="Interface\\Buttons\\WHITE8x8",
  "Junk card omitted item icon or visible quality accent")
local expectedActionIcons={
  ["Interface\\AddOns\\Dejunk-WotLK\\assets\\coins-icon"]=false,
  ["Interface\\AddOns\\Dejunk-WotLK\\assets\\ban-icon"]=true,
  ["Interface\\AddOns\\Dejunk-WotLK\\assets\\trash-icon"]=false
}
for texture,expectedEnabled in pairs(expectedActionIcons) do
  local found=false
  for _,frame in ipairs(uiFrames) do
    if frame.kind=="Texture" and frame.texture==texture then
      found=true
      assert(frame.parent.action.enabled==expectedEnabled,"Junk row action state is incorrect for "..texture)
    end
  end
  assert(found,"Junk row is missing upstream action icon "..texture)
end
local totalPrice
for _,frame in ipairs(uiFrames) do if frame.kind=="FontString" and frame.text=="6 copper" then totalPrice=frame end end
assert(totalPrice,"Junk item stack value was not rendered")
local junkValuePanel
for _,frame in ipairs(uiFrames) do
  if frame.kind=="Button" and frame.parent==junkWindow and frame.height==40 and frame.backdrop then junkValuePanel=frame end
end
assert(junkValuePanel and totalPrice.parent==junkValuePanel,"Junk total value is not in the upstream summary panel")
local previousCallbacks=runtime.configCallbacks
local listEdits={}
runtime.configCallbacks={editItem=function(scope,kind,id,present)
  listEdits[#listEdits+1]={scope=scope,kind=kind,id=id,present=present}; return true
end,junkItems=function() return {sellable=1,destroyable=2,items={{itemId=123},{itemId=456}}} end}
cursorItemId=999; local junkCard
for _,frame in ipairs(uiFrames) do if frame.kind=="Frame" and frame.item and frame.item.itemId==123 then junkCard=frame end end
assert(junkCard and junkCard.scripts.OnMouseUp,"Junk item row cannot accept a cursor item")
junkCard.scripts.OnMouseUp(junkCard,"LeftButton")
assert(listEdits[1] and listEdits[1].scope=="profile" and listEdits[1].kind=="inclusions" and
  listEdits[1].id==999 and cursorItemId==nil,"Junk item row did not add and clear the cursor item safely")
ui.controlDown=true; ui.altDown=true; junkValuePanel:Click("RightButton"); ui.controlDown=false; ui.altDown=false
assert(listEdits[2] and listEdits[2].kind=="exclusions" and listEdits[2].id==123 and listEdits[3].id==456,
  "Junk total bar did not add all candidates to exclusions")
runtime.configCallbacks=previousCallbacks
runtime:UpdateJunkFrame({sellable=0,destroyable=0,items={}})
assert(staleJunkRow.parent.shown==false,"stale Junk frame cards were not cleared")
local junkEmpty=false
for _,frame in ipairs(uiFrames) do if frame.kind=="FontString" and frame.text=="No junk items." and frame.shown then junkEmpty=true end end
assert(junkEmpty,"empty Junk frame state was not shown")
assert(runtime:ToggleJunkFrame({sellable=0,destroyable=0,items={}}) and junkWindow.shown==false,
  "Junk frame toggle did not hide the existing window")
local merchantItems={sellable=1,destroyable=1,items={{itemId=777,name="Merchant test",quality=0,count=1,bag=0,slot=1,
  sell={result="JUNK",reasonCode="QUALITY"},destroy={result="JUNK",reasonCode="QUALITY"}}}}
local savedMerchantPoint={point="TOPLEFT",relativeTo="MerchantFrame",relativePoint="TOPLEFT",offsetX=60,offsetY=-28}
runtime:SetWindowPointHandlers(function(key) return key=="merchantButton" and savedMerchantPoint end,
  function(key,value) if key=="merchantButton" then savedMerchantPoint=value; return true end return false end)
assert(runtime:UpdateMerchantButton({merchantButton=true},merchantItems,true),"merchant button did not initialize")
local merchantButton=namedFrame("DejunkWotLKMerchantButton")
assert(merchantButton.point[4]==210 and merchantButton.point[5]==-44,
  "legacy merchant position was not moved out of the portrait area")
assert(merchantButton and merchantButton.parent==ui.MerchantFrame and merchantButton.shown,
  "enabled merchant button did not appear on the open merchant frame")
assert(merchantButton.width==108 and merchantButton.height==28 and
  merchantButton.children[1].texture=="Interface\\AddOns\\Dejunk-WotLK\\assets\\dejunk-icon" and
  merchantButton.children[2].text=="(1/1)","merchant button did not match upstream icon and count layout")
ui.GameTooltip.lines={}; merchantButton.scripts.OnEnter(merchantButton)
assert(ui.GameTooltip.lines[1].left=="Dejunk (1/1)" and ui.GameTooltip.lines[1].right=="3.3.5",
  "merchant tooltip omitted the upstream item counts or version")
ui.GameTooltip.lines={}; ui.altDown=true; merchantButton.scripts.OnEnter(merchantButton); ui.altDown=false
assert(ui.GameTooltip.bag==0 and ui.GameTooltip.slot==1 and ui.GameTooltip.lines[2].right=="Destroy",
  "holding Alt over the merchant button did not preview the next destroyable item")
merchantButton:SetPoint("BOTTOM",ui.MerchantFrame,"BOTTOM",25,18)
merchantButton.scripts.OnDragStop(merchantButton)
assert(savedMerchantPoint and savedMerchantPoint.point=="BOTTOM" and savedMerchantPoint.relativeTo=="MerchantFrame" and
  savedMerchantPoint.offsetX==25 and savedMerchantPoint.offsetY==18,"merchant button drag position did not persist")
ui.shiftDown=true; merchantButton:Click("RightButton"); ui.shiftDown=false
assert(savedMerchantPoint.point=="TOPLEFT" and savedMerchantPoint.relativeTo=="MerchantFrame" and
  savedMerchantPoint.offsetX==210 and savedMerchantPoint.offsetY==-44,"merchant button reset did not restore upstream default position")
merchantButton:Click("RightButton")
assert(junkWindow.shown,"merchant button right-click did not toggle the Junk frame")
merchantButton:Click("RightButton")
assert(not junkWindow.shown,"merchant button second right-click did not close the Junk frame")
merchantButton:Click("LeftButton")
assert(messages[#messages]:find("Selling is unavailable",1,true),"merchant button started or failed to explain the gated live seller")
assert(runtime:UpdateMerchantButton({merchantButton=false},merchantItems,true) and not merchantButton.shown,
  "disabled merchant-button option did not hide its merchant control")
local requestedActions={}
runtime:SetItemActionHandlers({
  sellItem=function(item) requestedActions.sellItem=item.itemId; return true end,
  destroyItem=function(item) requestedActions.destroyItem=item.itemId; return true end,
  startSelling=function() requestedActions.startSelling=true; return true end,
  destroyNext=function() requestedActions.destroyNext=true; return true end
})
local actionData={sellable=1,destroyable=1,items={{itemId=778,name="Action test",quality=0,count=1,unitVendorPrice=5,
  sell={result="JUNK",reasonCode="QUALITY"},destroy={result="JUNK",reasonCode="QUALITY"}}}}
runtime:UpdateMerchantButton({merchantButton=true},actionData,true)
runtime:UpdateJunkFrame(actionData)
local sellRowButton,destroyRowButton
for _,candidate in ipairs(uiFrames) do
  if candidate.kind=="Button" and candidate.action and candidate.parent and candidate.parent.item and candidate.parent.item.itemId==778 then
    if candidate.action.key=="sellItem" then sellRowButton=candidate end
    if candidate.action.key=="destroyItem" then destroyRowButton=candidate end
  end
end
assert(sellRowButton and destroyRowButton and sellRowButton.enabled and destroyRowButton.enabled,
  "eligible mock action callbacks did not enable their matching row controls")
ui.GameTooltip.lines={}; sellRowButton.scripts.OnEnter(sellRowButton)
local sellHint=false
for _,line in ipairs(ui.GameTooltip.lines) do if line.text=="Click to sell this stack." then sellHint=true end end
assert(sellHint,"sell tooltip did not see the current merchant session")
runtime:SetItemActionsBusy(true)
assert(not sellRowButton.enabled and not destroyRowButton.enabled and not junkWindow.startSellingButton.enabled,
  "a sale run left competing action controls enabled")
runtime:SetItemActionsBusy(false)
assert(junkWindow.destroyNextButton.labelRegion.textColor[1]>0.8 and
  junkWindow.destroyNextButton.labelRegion.textColor[2]<0.4,
  "Destroy Next Item button did not use the upstream red label color")
sellRowButton:Click("LeftButton"); destroyRowButton:Click("LeftButton")
junkWindow.startSellingButton:Click("LeftButton"); junkWindow.destroyNextButton:Click("LeftButton")
assert(requestedActions.sellItem==778 and requestedActions.destroyItem==778 and
  requestedActions.startSelling==true and requestedActions.destroyNext==true,
  "Junk frame controls did not dispatch to their injected action handlers")
runtime:UpdateMerchantButton({merchantButton=true},actionData,true)
merchantButton:Click("LeftButton")
ui.altDown=true; merchantButton:Click("RightButton"); ui.altDown=false
assert(requestedActions.startSelling==true and requestedActions.destroyNext==true,
  "merchant shortcut did not dispatch selling and destroy-next actions")
assert(not runtime:ToggleLootableFrame({count=0,items={}}),"empty lootable window should not open")
assert(runtime:ToggleLootableFrame({count=1,items={{itemId=6948,name="Hearthstone",count=1,bag=0,slot=1}}}),
  "read-only Lootable frame failed to open")
local lootableWindow=namedFrame("DejunkWotLKLootableFrame")
assert(lootableWindow and lootableWindow.shown and runtime:IsLootableFrameVisible(),"Lootable frame did not become visible")
assert(lootableWindow.width==250 and lootableWindow.height==250 and lootableWindow.strata=="LOW",
  "Lootable frame does not use the upstream dimensions or frame strata")
local ignoreIcon
for _,frame in ipairs(uiFrames) do
  if frame.kind=="Texture" and frame.texture=="Interface\\AddOns\\Dejunk-WotLK\\assets\\eye-slash-icon" then ignoreIcon=frame end
end
assert(ignoreIcon and ignoreIcon.parent.parent.enabled==true,"Lootable row ignore control is missing")
assert(ignoreIcon.width==14 and ignoreIcon.height==14 and ignoreIcon.parent.width==32 and
  ignoreIcon.parent.height==32 and ignoreIcon.parent.parent.icon.width==24 and ignoreIcon.parent.parent.height==34 and
  ignoreIcon.parent.parent.accent.texture=="Interface\\Buttons\\WHITE8x8",
  "Lootable item or ignore icons do not match the reference sizing")
ignoreIcon.parent.scripts.OnClick(ignoreIcon.parent)
assert(not ignoreIcon.parent.parent.shown,"ignoring a lootable item did not remove its row")
assert(not runtime:ShowLootableFrame({count=1,items={{itemId=6948,name="Hearthstone",count=1,bag=0,slot=1}}}),
  "session-ignored item reappeared in Lootable frame")
runtime:UpdateLootableFrame({count=0,items={}})
assert(runtime:IsLootableFrameVisible(),"manual Lootable frame unexpectedly closed when its list emptied")
assert(runtime:ToggleLootableFrame({count=0,items={}}) and not runtime:IsLootableFrameVisible(),
  "Lootable frame toggle did not hide the existing window")
local function editBox(width)
  for _,frame in ipairs(uiFrames) do if frame.kind=="EditBox" and frame.width==width then return frame end end
  error("missing edit box width "..tostring(width))
end
local function summaryText()
  for _,frame in ipairs(uiFrames) do
    if frame.kind=="FontString" and type(frame.text)=="string" and frame.text:find("Rules for active profile:",1,true) then return frame.text end
  end
end

runtime:ShowRules(callbacks)
assert(namedFrame("DejunkWotLKRules"),"rules window did not use the Waffle window factory")
local actionButton=control("Button","Action: SELL")
actionButton:Click(); assert(control("Button","Action: DESTROY"))
actionButton:Click(); assert(control("Button","Action: BOTH"))
actionButton:Click(); assert(control("Button","Action: SELL"))
local resultButton=control("Button","Result: JUNK")
resultButton:Click(); assert(control("Button","Result: KEEP"))
resultButton:Click(); assert(control("Button","Result: JUNK"))
local opButton=control("Button","Operator: EQ")
opButton:Click(); assert(control("Button","Operator: LT"))
opButton:Click(); assert(control("Button","Operator: GT"))
opButton:Click(); assert(control("Button","Operator: EQ"))
control("Button","Group: ALL"):Click()
editBox(110):SetText("8")
control("Button","Add condition"):Click()
assert(#rules==0 and summaryText():find("Draft",1,true)==nil)
editBox(110):SetText("0")
control("Button","Add condition"):Click()

assert(summaryText():find("Draft (ANY): quality EQ 0",1,true))
local fieldButton=control("Button","Field: quality")
for _=1,4 do fieldButton:Click() end
assert(control("Button","Field: itemId"))
editBox(110):SetText("6948")
control("Button","Add condition"):Click()
assert(summaryText():find("quality EQ 0; itemId EQ 6948",1,true))
editBox(150):SetText("compound-ui")
control("Button","Add rule"):Click()
assert(#rules==1 and rules[1].id=="compound-ui")
assert(rules[1].match=="ANY" and #rules[1].predicates==2)
assert(rules[1].predicates[1].value==0 and rules[1].predicates[2].value==6948)
assert(editBox(150):GetText()=="")
assert(control("Button","Remove ID").enabled==false)

editBox(150):SetText("compound-ui")
control("Button","Remove ID"):Click()
assert(#rules==0 and editBox(150):GetText()=="")

for _=1,10 do
  editBox(110):SetText("6948")
  control("Button","Add condition"):Click()
end
editBox(110):SetText("6948")
control("Button","Add condition"):Click()
assert(messages[#messages]:find("at most 10 conditions",1,true))
control("Button","Clear draft"):Click()
assert(summaryText():find("Draft",1,true)==nil)

editBox(110):SetText("0")
control("Button","Add condition"):Click()
activeId="profile-2"; activeName="Other"
editBox(150):SetText("must-not-leak")
control("Button","Add rule"):Click()
assert(#rules==0)
assert(summaryText():find("Draft",1,true)==nil)
assert(messages[#messages]:find("discarded because the active profile changed",1,true))

local listStore=Addon.Store.Initialize(nil,"Lists test")
assert(listStore:EditList("global","inclusions",6948,true))
local listCallbacks={
  listItems=function(scope,kind) return listStore:ExportList(scope,kind) end,
  editItem=function(scope,kind,id,present) return listStore:EditList(scope,kind,id,present) end,
  previewListImport=function(scope,kind,text) return listStore:ImportPreview(scope,kind,text) end,
  commitListImport=function(preview) return listStore:CommitImport(preview) end,
  activeProfileName=function() return "Test" end,
  keybindings=function() return listStore:GetState().global.keybindings end,
  setKeybindings=function(patch) return listStore:SetGlobalOption("keybindings",patch) end,
  junkItems=function() return {sellable=6,destroyable=7,items={}} end,
  lootableItems=function() return {count=0,items={}} end
}
runtime:ShowConfig(listCallbacks)
local footerProfile,footerJunk,footerLootable,brandVersion
for _,frame in ipairs(uiFrames) do
  if frame.kind=="FontString" then
    if frame.text and frame.text:find("Active Profile:",1,true) then footerProfile=frame end
    if frame.text and frame.text:find("|cffffd100Junk Items|r",1,true) then footerJunk=frame end
    if frame.text and frame.text:find("|cffffd100Lootable Items|r",1,true) then footerLootable=frame end
    if frame.text=="3.3.5" then brandVersion=frame end
  end
end
assert(footerProfile and footerProfile.text:find("Test",1,true) and footerJunk and footerJunk.text:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):find("6/7",1,true) and
  footerLootable and footerLootable.text:find("0",1,true) and brandVersion,
  "main-window upstream header/version or status footer is missing: "..tostring(footerProfile and footerProfile.text).." / "..
  tostring(footerJunk and footerJunk.text).." / "..tostring(footerLootable and footerLootable.text).." / "..tostring(brandVersion and brandVersion.text))
local brandIcon
for _,frame in ipairs(uiFrames) do
  if frame.kind=="Texture" and frame.texture=="Interface\\AddOns\\Dejunk-WotLK\\assets\\dejunk-icon" and frame.width==20 then brandIcon=frame end
end
assert(brandIcon,"main window is missing the upstream 20px brand icon")
namedFrame("DejunkWotLKFooter_profile"):Click()
assert(namedFrame("DejunkWotLKProfiles").shown,"active-profile footer did not open Profiles")
runtime:ToggleConfig(listCallbacks); runtime:ToggleConfig(listCallbacks)
assert(namedFrame("DejunkWotLKProfiles").shown,"reopening the main window forgot the previous page")
runtime:ToggleProfiles(listCallbacks)
assert(not namedFrame("DejunkWotLK_MainWindow").shown,"profiles toggle did not close an already selected Profiles screen")
runtime:ToggleProfiles(listCallbacks)
assert(namedFrame("DejunkWotLKProfiles").shown,"profiles toggle did not reopen Profiles")
namedFrame("DejunkWotLKFooter_junk"):Click()
assert(junkWindow.shown,"junk-count footer did not toggle the Junk frame")
namedFrame("DejunkWotLKFooter_junk"):Click()
assert(not junkWindow.shown,"junk-count footer did not toggle back off")
namedFrame("DejunkWotLKFooter_lootable"):Click()
assert(messages[#messages]:find("No lootable items.",1,true),"empty lootable footer did not explain its result")
control("Button","Lists"):Click()
assert(namedFrame("DejunkWotLKLists"),"Lists page frame was not created")
assert(lastControl("Button","X").template==nil,"configuration close still uses a red Blizzard template")
assert(lastControl("Button","X").icon and lastControl("Button","X").icon.texture=="Interface\\AddOns\\Dejunk-WotLK\\assets\\x-icon" and
  lastControl("Button","X").icon.vertexColor and lastControl("Button","X").icon.vertexColor[1]>0.3,
  "Waffle grey close icon styling was not applied")
local listSearch,lastListInput
for _,candidate in ipairs(uiFrames) do
  if candidate.kind=="EditBox" and candidate.parent==namedFrame("DejunkWotLKLists") then
    if not listSearch then listSearch=candidate else lastListInput=candidate end
  end
end
local listFrame=namedFrame("DejunkWotLKLists")
local mainWindow=namedFrame("DejunkWotLK_MainWindow")
runtime:UpdateMinimapIcon(minimapState,nil,function() runtime:ToggleConfig(listCallbacks) end)
for cycle=1,3 do
  minimapButton:Click("LeftButton")
  assert(not mainWindow.shown,"minimap did not close the main window")
  minimapButton:Click("LeftButton")
  assert(mainWindow.shown and listFrame.shown,"minimap reopen left the selected Lists page hidden")
end
mainWindow:Hide()
mainWindow.scripts.OnHide(mainWindow)
minimapButton:Click("LeftButton")
assert(mainWindow.shown and listFrame.shown,"reopening after Escape/direct hide left Lists blank")
local navOrder={}
for _,candidate in ipairs(uiFrames) do
  if candidate.kind=="Button" and
    (candidate.text=="Lists" or candidate.text=="Global Options" or candidate.text=="Profile Options" or candidate.text=="Profiles" or candidate.text=="Keybindings") then
    local ancestor=candidate.parent
    while ancestor and ancestor~=mainWindow do ancestor=ancestor.parent end
    if ancestor==mainWindow then navOrder[#navOrder+1]=candidate.text end
  end
end
assert(table.concat(navOrder,",")=="Lists,Global Options,Profile Options,Profiles,Keybindings",
  "main navigation order does not match the upstream screen order")
assert(listFrame and listFrame.width and listFrame.width>0 and listFrame.height and listFrame.height>0 and listFrame.shown,
  "Lists was not sized by the main Waffle layout")
assert(listFrame.alpha~=0,"Lists was made transparent by the legacy page visibility path")
local listPanelCount=0
local listPanes={}
for _,frame in ipairs(uiFrames) do
  if frame.kind=="Frame" and frame.parent==listFrame and frame.titleBar then
    listPanelCount=listPanelCount+1
    assert(frame.backdrop and frame.backdrop.edgeSize==1,"list panel is not a square Waffle panel")
    assert(frame.heading and frame.transportButton,"list panel is missing its title or transport control")
    assert(frame.spinner and frame.spinner.texture=="Interface\\AddOns\\Dejunk-WotLK\\assets\\spinner-icon" and
      frame.spinner.width==14 and frame.spinner.height==14,"list panel is missing the upstream loading spinner")
    local transportIcon
    for _,child in ipairs(frame.transportButton.children or {}) do
      if child.kind=="Texture" then transportIcon=child; break end
    end
    assert(transportIcon and transportIcon.texture=="Interface\\AddOns\\Dejunk-WotLK\\assets\\transport-icon" and
      transportIcon.width==14 and transportIcon.height==14 and transportIcon.layer=="OVERLAY" and transportIcon.shown==true,
      "list transport control is missing the upstream-sized visible export/import icon")
    assert(frame.scrollFrame and frame.scrollFrame.template==nil and frame.scrollTrack,
      "list panel is still using the legacy arrow template instead of the upstream scroll track")
    assert(frame.transportButton.frameLevel>frame.titleBar:GetFrameLevel(),
      "list transport icon button is behind its title bar")
    assert(frame.heading.textColor and frame.heading.textColor[1]~=1,
      "list panel title does not use its inclusion/exclusion color")
    listPanes[frame.listScope..":"..frame.listKind]=frame
  end
end
assert(listPanelCount==4,"Lists screen should show four Waffle list panels (found "..listPanelCount..")")
assert(listPanes["global:inclusions"] and listPanes["global:exclusions"] and
  listPanes["profile:inclusions"] and listPanes["profile:exclusions"],"list panels are missing a scope or kind")
assert(listFrame.backdrop==nil,"Lists page retained the extra nested window frame")
assert(listSearch.height==28 and listSearch.fontObject=="GameFontNormal" and listSearch.width>400 and
  listSearch.backdropColor and listSearch.backdropColor[1]==30/255,
  "list search input does not match the upstream control size and palette")
assert(listSearch.template==nil,"search still inherits the Blizzard input border")
assert(not lastListInput,"Lists page still shows the non-upstream numeric item ID control")
local ancestor=listFrame
while ancestor and ancestor~=mainWindow do ancestor=ancestor.parent end
assert(ancestor==mainWindow,"Lists screen was not embedded in the main Waffle window")
local inclusionRow
for _,frame in ipairs(uiFrames) do
  if frame.kind=="Button" and frame.listScope=="global" and frame.listKind=="inclusions" then inclusionRow=frame; break end
end
assert(inclusionRow and inclusionRow.scripts.OnMouseDown,"list item rows do not accept cursor items")
cursorItemId=6949
assert(inclusionRow.scripts.OnReceiveDrag,"list row has no actual drop receiver")
inclusionRow.scripts.OnReceiveDrag(inclusionRow)
assert(listStore:GetState().global.inclusions[6949]==true,"cursor item was not added to the list")
assert(cursorItemId==nil,"successful list drop did not clear the cursor item")
for id=7000,7008 do assert(listStore:EditList("global","inclusions",id,true)) end
runtime:ShowLists(listCallbacks)
local visibleListRows=0
for _,frame in ipairs(uiFrames) do
  if frame.kind=="Button" and frame.listScope=="global" and frame.listKind=="inclusions" and frame.itemId then
    visibleListRows=visibleListRows+1
  end
end
assert(visibleListRows>=11,"scrollable list did not create rows for entries beyond the first seven")
for id=7000,7008 do assert(listStore:EditList("global","inclusions",id,false)) end
runtime:ShowLists(listCallbacks)
control("Button","Profile Options"):Click()
assert(mainWindow.shown and listFrame.shown==false,"Profile Options navigation did not leave Lists")
local firstOptionsPage=namedFrame("DejunkWotLKOptions")
assert(firstOptionsPage and firstOptionsPage.parent==listFrame.parent,"Profile Options was created outside the main content panel")
control("Button","Global Options"):Click()
assert(firstOptionsPage.shown and listFrame.shown==false,"Global Options navigation restored or left Lists visible")
control("Button","Profile Options"):Click()
assert(firstOptionsPage.shown and listFrame.shown==false,"switching back to Profile Options left a stale page visible")
control("Button","Profiles"):Click()
assert(firstOptionsPage.shown==false and namedFrame("DejunkWotLKProfiles").shown,"Profiles navigation left the Options Waffle page visible")
control("Button","Profile Options"):Click()
assert(firstOptionsPage.shown and namedFrame("DejunkWotLKProfiles").shown==false,"Profile Options navigation left Profiles visible")
control("Button","Lists"):Click()
assert(mainWindow.shown and listFrame.shown and firstOptionsPage.shown==false,
  "Lists navigation did not restore Lists and hide the Options Waffle page")

control("Button","Keybindings"):Click()
local keybindingPage=namedFrame("DejunkWotLKKeybindings")
local mainWindowBinding
for _,frame in ipairs(uiFrames) do if frame.kind=="Button" and frame.name and frame.name:find("_toggleMainWindow",1,true) and not frame.name:find("Action_",1,true) then mainWindowBinding=frame; break end end
assert(keybindingPage and keybindingPage.shown and mainWindowBinding,
  "Keybindings screen or its controls were not created as a sibling page: "..tostring(keybindingPage and keybindingPage.shown).." / "..tostring(mainWindowBinding and mainWindowBinding.shown).." / "..tostring(mainWindowBinding and mainWindowBinding.kind))
local listBindingLabel,startSellingDetail
for _,frame in ipairs(uiFrames) do
  if frame.kind=="FontString" and frame.text and frame.text:find("Inclusions|r",1,true) then listBindingLabel=frame end
  if frame.kind=="FontString" and frame.text=="Sells junk items while a merchant window is open." then startSellingDetail=frame end
end
assert(listBindingLabel and listBindingLabel.text:find("|cffe34f4f",1,true),"keybinding inclusion label is missing upstream red coloring")
assert(startSellingDetail,"Start Selling keybinding description is missing")
assert(mainWindowBinding.labelRegion and mainWindowBinding.labelRegion.textColor[1]<0.8,
  "unbound key display is not grey like upstream")
mainWindowBinding:Click("LeftButton")
assert(keybindingPage.keyboard==true and mainWindowBinding.text:find("Press a key",1,true),
  "left-click did not start key capture")
keybindingPage.scripts.OnKeyDown(keybindingPage,"UNKNOWN")
assert(keybindingPage.keyboard==true and listStore:GetState().global.keybindings.toggleMainWindow=="",
  "unknown key input was bound instead of ignored")
keybindingPage.scripts.OnKeyDown(keybindingPage,"K")
local savedKeys=listStore:GetState().global.keybindings
assert(savedKeys.toggleMainWindow=="K" and keybindingPage.keyboard==false,
  "captured key was not saved or capture did not stop")
local gameBindingWarning=false
for _,child in ipairs(keybindingPage.children or {}) do if child.kind=="FontString" and child.text and child.text:find("Toggle Backpack",1,true) then gameBindingWarning=true end end
assert(gameBindingWarning,"game binding conflict was not disclosed to the user")
local owner=namedFrame("DejunkWotLKKeybindingOwner")
assert(owner and owner.overrides.K=="DejunkWotLKKeybindingAction_toggleMainWindow",
  "saved key was not installed as an owner-scoped override binding")
assert(ui.bindingWrites==0,"keybinding changed the game's saved bindings")
requestedActions.startSelling=nil; requestedActions.destroyNext=nil
namedFrame("DejunkWotLKKeybindingAction_startSelling").scripts.OnClick()
namedFrame("DejunkWotLKKeybindingAction_destroyNextItem").scripts.OnClick()
assert(requestedActions.startSelling==true and requestedActions.destroyNext==true,
  "seller/destroyer keybindings did not dispatch through their injected action handlers")
local junkWindowBinding
for _,frame in ipairs(uiFrames) do if frame.kind=="Button" and frame.name and frame.name:find("_toggleJunkFrame",1,true) and not frame.name:find("Action_",1,true) then junkWindowBinding=frame; break end end
junkWindowBinding:Click("LeftButton")
keybindingPage.scripts.OnKeyDown(keybindingPage,"K")
savedKeys=listStore:GetState().global.keybindings
assert(savedKeys.toggleJunkFrame=="K" and savedKeys.toggleMainWindow=="" and owner.overrides.K=="DejunkWotLKKeybindingAction_toggleJunkFrame",
  "duplicate key did not replace the older addon binding")
junkWindowBinding:Click("RightButton")
assert(listStore:GetState().global.keybindings.toggleJunkFrame=="" and owner.overrides.K==nil,
  "right-click did not clear an addon binding")
junkWindowBinding:Click("LeftButton")
ui.controlDown=true; ui.shiftDown=true; ui.altDown=true
keybindingPage.scripts.OnKeyDown(keybindingPage,"M")
ui.controlDown=false; ui.shiftDown=false; ui.altDown=false
assert(listStore:GetState().global.keybindings.toggleJunkFrame=="ALT-CTRL-SHIFT-M",
  "modifier chord was not captured in legacy binding format")
local lootWindowBinding
for _,frame in ipairs(uiFrames) do if frame.kind=="Button" and frame.name and frame.name:find("_toggleLootableFrame",1,true) and not frame.name:find("Action_",1,true) then lootWindowBinding=frame; break end end
lootWindowBinding:Click("LeftButton")
assert(keybindingPage.mouseWheel==true,"mouse wheel capture was not enabled")
keybindingPage.scripts.OnMouseWheel(keybindingPage,1)
assert(listStore:GetState().global.keybindings.toggleLootableFrame=="MOUSEWHEELUP" and keybindingPage.mouseWheel==false,
  "mouse wheel key was not captured or capture did not disable")
lootWindowBinding:Click("LeftButton")
lootWindowBinding:Click("Button4")
assert(listStore:GetState().global.keybindings.toggleLootableFrame=="BUTTON4",
  "mouse button input on a keybinding row was not captured")
local globalListBinding
for _,frame in ipairs(uiFrames) do if frame.kind=="Button" and frame.name and frame.name:find("_addOrRemoveGlobalInclusions",1,true) and not frame.name:find("Action_",1,true) then globalListBinding=frame; break end end
globalListBinding:Click("LeftButton")
keybindingPage.scripts.OnKeyDown(keybindingPage,"[")
assert(listStore:GetState().global.keybindings.addOrRemoveGlobalInclusions=="[",
  "punctuation key supported by the game binding UI was not saved")
cursorItemId=7000
ui.GameTooltip.itemName="Hearthstone"
ui.GameTooltip.itemLink="|cffffffff|Hitem:6948:0:0:0:0:0:0:0:80|h[Hearthstone]|h|r"
local globalInclusionAction
for _,frame in ipairs(uiFrames) do if frame.name=="DejunkWotLKKeybindingAction_addOrRemoveGlobalInclusions" then globalInclusionAction=frame; break end end
assert(globalInclusionAction,"global inclusion key action button was not created")
globalInclusionAction:Click()
assert(listStore:GetState().global.inclusions[6948]==nil and cursorItemId==7000,
  "list keybinding did not toggle the tooltip item or changed the cursor item")
cursorItemId=nil; ui.GameTooltip.itemName=nil; ui.GameTooltip.itemLink=nil
assert(listStore:EditList("global","inclusions",6948,true),"test setup could not restore the original global list fixture")
globalListBinding:Click("RightButton")
mainWindowBinding:Click("LeftButton")
keybindingPage.scripts.OnKeyDown(keybindingPage,"ESCAPE")
assert(listStore:GetState().global.keybindings.toggleMainWindow=="" and keybindingPage.keyboard==false,
  "Escape did not cancel key capture without changing the binding")
ui.combatLocked=true
mainWindowBinding:Click("LeftButton")
assert(keybindingPage.keyboard==false,"key capture started during combat")
ui.combatLocked=false
mainWindowBinding:Click("LeftButton")
assert(keybindingPage.keyboard==true,"key capture did not start after leaving combat")
ui.combatLocked=true
keybindingPage.scripts.OnEvent(keybindingPage,"PLAYER_REGEN_DISABLED")
assert(keybindingPage.keyboard==false,"entering combat did not cancel active key capture")
ui.combatLocked=false
mainWindowBinding:Click("LeftButton")
ui.combatLocked=true
keybindingPage.scripts.OnKeyDown(keybindingPage,"Y")
assert(listStore:GetState().global.keybindings.toggleMainWindow=="" and keybindingPage.keyboard==false,
  "captured key changed SavedVariables after combat began")
ui.combatLocked=false
control("Button","Lists"):Click()
assert(keybindingPage.shown==false and listFrame.shown==true,"Keybindings page remained visible after switching screens")
ui.combatLocked=true
assert(listStore:SetGlobalOption("keybindings",{toggleMainWindow="J"}))
owner.scripts.OnEvent(owner,"PLAYER_REGEN_ENABLED")
assert(owner.overrides.J==nil,"override binding was refreshed while combat locked")
ui.combatLocked=false
owner.scripts.OnEvent(owner,"PLAYER_REGEN_ENABLED")
assert(owner.overrides.J=="DejunkWotLKKeybindingAction_toggleMainWindow",
  "saved keybinding was not reinstalled after combat")

local searchBox
for _,frame in ipairs(uiFrames) do
  if frame.kind=="EditBox" and frame.parent==listFrame and frame.maxLetters==64 then searchBox=frame; break end
end
assert(searchBox,"Lists search box was not created")
local searchIcon
for _,frame in ipairs(uiFrames) do
  if frame.kind=="Texture" and frame.parent==searchBox and frame.texture=="Interface\\AddOns\\Dejunk-WotLK\\assets\\search-icon" then searchIcon=frame end
end
assert(searchIcon and searchIcon.width==14,"Lists is missing the upstream search icon")
searchBox:SetFocus(); searchBox:SetText("2"); searchBox:SetText("23")
assert(searchBox:GetText()=="23" and searchBox.focused and listFrame.shown,
  "refreshing Lists while typing lost the search text, focus or selected page")
searchBox.scripts.OnEscapePressed(searchBox)
assert(searchBox:GetText()=="" and not searchBox.focused and listFrame.shown,
  "Escape did not clear Lists search and release focus while preserving the page")
local savedTransportPoint
runtime:SetWindowPointHandlers(function(key) return key=="transportFrame" and savedTransportPoint end,
  function(key,value) if key=="transportFrame" then savedTransportPoint=value; return true end return false end)
listPanes["global:inclusions"].transportButton:Click()
local transportFrame=namedFrame("DejunkWotLKListImport")
local transportClose=namedFrame("DejunkWotLKListTransportClose")
assert(transportClose.width==24 and transportClose.height==24,"transport close button has no click area")
local escapeNames={}
for _,name in ipairs(runtime.api.UISpecialFrames) do escapeNames[name]=true end
assert(escapeNames.DejunkWotLK_MainWindow and escapeNames.DejunkWotLKListImport and
  escapeNames.DejunkWotLKJunkFrame,"windows were not registered with the legacy Escape handler")
assert(transportFrame.shown and listFrame.shown==false and transportFrame.movable and
  transportFrame.dragButtons[1]=="LeftButton","transport frame is not movable like the upstream window")
assert(transportFrame.width==325 and transportFrame.height==375,"transport frame does not match upstream dimensions")
transportFrame:SetPoint("BOTTOMRIGHT",ui.UIParent,"BOTTOMRIGHT",-30,40)
transportFrame.scripts.OnDragStop(transportFrame)
assert(savedTransportPoint and savedTransportPoint.point=="BOTTOMRIGHT" and savedTransportPoint.offsetX==-30 and
  savedTransportPoint.offsetY==40,"transport frame drag position did not persist")
assert(namedFrame("DejunkWotLKListImport").shown and listFrame.shown==false)
local exported=lastControl("EditBox","6948,6949")
assert(exported.focused,"transport export did not select the chosen list")
assert(exported.highlighted,"transport export did not select the IDs for copying")
exported.scripts.OnEscapePressed(exported)
assert(not transportFrame.shown and listFrame.shown,"Escape in the transport input did not dismiss the window")
listPanes["global:inclusions"].transportButton:Click()
namedFrame("DejunkWotLKListTransportClose"):Click()
assert(listFrame.shown==true)

listPanes["global:inclusions"].transportButton:Click()
assert(namedFrame("DejunkWotLKListImport"),"import window did not use the Waffle window factory")
assert(listFrame.shown==false)
local importInput
for _,frame in ipairs(uiFrames) do if frame.kind=="EditBox" and frame.width==245 then importInput=frame end end
assert(importInput)
importInput:SetText("123, 456")
control("Button","Import"):Click()
assert(namedFrame("DejunkWotLKListImport").shown,
  "successful import did not keep the transport window open")
assert(listStore:ExportList("global","inclusions")=="123\n456\n6948\n6949")
assert(messages[#messages]:find("Imported 2 item IDs.",1,true),"transport import did not report its result")
listPanes["global:inclusions"].transportButton:Click()
control("Button","Export"):Click()
local reexported=lastControl("EditBox","123,456,6948,6949")
assert(reexported.highlighted,"transport Export button did not refill and select the target list")
namedFrame("DejunkWotLKListTransportClose"):Click()

local function listRow(scope,kind,id)
  for _,frame in ipairs(uiFrames) do
    if frame.kind=="Button" and frame.itemId==tostring(id) and frame.listScope==scope and frame.listKind==kind then return frame end
  end
  error("missing list row "..scope.."/"..kind.."/"..id)
end
local globalInclusionRow=listRow("global","inclusions",6948)
assert(globalInclusionRow.accent.texture=="Interface\\Buttons\\WHITE8x8",
  "Lists item quality stripe has no visible texture")
ui.shiftDown=true; globalInclusionRow:Click("RightButton"); ui.shiftDown=false
assert(listStore:ExportList("global","exclusions")=="6948")
ui.controlDown=true; listRow("global","inclusions",6948):Click("RightButton"); ui.controlDown=false
assert(listStore:ExportList("profile","exclusions")=="6948")
ui.altDown=true; listRow("global","inclusions",6948):Click("RightButton"); ui.altDown=false
assert(listStore:ExportList("profile","inclusions")=="6948")
listRow("global","inclusions",6948):Click("RightButton")
assert(listStore:ExportList("global","inclusions")=="123\n456\n6949")
assert(listStore:EditList("global","exclusions",6948,false))
assert(listStore:EditList("profile","exclusions",6948,false))
assert(listStore:EditList("profile","inclusions",6948,false))

runtime:ShowConfig({
  summary=function() return "Active profile: Test" end,
  poorEnabled=function() return true end,
  preview=function(action)
    runtime:ShowReport("READ-ONLY "..action:upper().." PREVIEW\nNo action will be taken.","Read-only preview: "..action,"config")
  end
})
local configFrame
configFrame=namedFrame("DejunkWotLK_MainWindow")
assert(configFrame and configFrame.shown)
assert(control("Button","Junk Items") and control("Button","Lootable Items"),
  "main window omitted the upstream item-list entry buttons")
for _,message in ipairs(messages) do assert(not message:find("Waffle configuration UI failed",1,true)) end
control("Button","Preview SELL"):Click()
assert(configFrame.shown==false)
local reportClose=lastChild(namedFrame("DejunkWotLKReadOnlyReport"),"Button")
assert(reportClose.text=="X")
reportClose:Click()
assert(configFrame.shown==true)
local selectedProfile
local profileOperations={}
local profileCallbacks={
  profiles=function() return {{id="default",name="Default",active=true,numInclusions=0,numExclusions=0},
    {id="profile-1",name="Test",active=false,numInclusions=1,numExclusions=2,characterKeys={"Realm\31Test"}}} end,
  currentCharacterKey=function() return "Realm\31Test" end,
  activeProfileId=function() return "default" end,activeProfileName=function() return "Default" end,
  switchProfile=function(id) selectedProfile=id; return true end,
  createProfile=function(name) profileOperations.create={name=name}; return "created" end,
  duplicateProfileFrom=function(id,name) profileOperations.duplicate={id=id,name=name}; return "copy" end,
  renameProfile=function(id,name) profileOperations.rename={id=id,name=name}; return true end,
  resetProfile=function(id) profileOperations.reset=id; return true end,
  deleteProfile=function(id) profileOperations.delete=id; return true end
}
runtime:ShowProfiles(profileCallbacks)
local profilesPage=namedFrame("DejunkWotLKProfiles")
assert(profilesPage,"profiles page was not created")
assert(profilesPage.parent==namedFrame("DejunkWotLKLists").parent,"Profiles page is outside the main configuration content")
assert(profilesPage.width and profilesPage.width>0 and profilesPage.height and profilesPage.height>0,
  "Profiles page was not sized by the main Waffle layout")
assert(profilesPage.alpha~=0,"Profiles page was made transparent by the legacy page visibility path")
assert(profilesPage.backdrop==nil,"Profiles page retained its own dialog backdrop")
assert(profilesPage.shown,"Profiles page was not visible when selected")
assert(profilesPage.pageTitle.text=="Profiles (|cffffffffDefault|r)","Profiles panel title did not show the active profile")
assert(profilesPage.width>0,"Profiles screen did not receive a layout width")
local profilesDescription
for _,frame in ipairs(uiFrames) do
  if frame.kind=="FontString" and frame.text and frame.text:find("A profile holds a character's options and lists",1,true) then profilesDescription=frame end
end
assert(profilesDescription,"Profiles page is missing the upstream explanation")
local expectedQualityColors={
  poor={157/255,157/255,157/255}, common={1,1,1}, uncommon={30/255,1,0},
  rare={0,112/255,221/255}, epic={163/255,53/255,238/255}
}
for _,frame in ipairs(uiFrames) do
  if frame.kind=="CheckButton" and frame.qualityRow==true and frame.optionQuality then
    local expected=expectedQualityColors[frame.optionQuality]
    local border=frame.optionVisual and frame.optionVisual.box.borderColor
    assert(expected and border and math.abs(border[1]-expected[1])<0.00001 and
      math.abs(border[2]-expected[2])<0.00001 and math.abs(border[3]-expected[3])<0.00001,
      "quality checkbox did not use its upstream quality color: "..tostring(frame.optionQuality))
  end
end
assert(lastControl("Button","New Profile").template==nil,"New Profile still uses a red Blizzard template")
local profileActionControls={}
for _,frame in ipairs(uiFrames) do
  if frame.kind=="Button" and frame.profileId=="default" and frame.profileAction then
    profileActionControls[frame.profileAction]=frame
  end
end
local protectedRename,protectedDelete
protectedRename=profileActionControls.rename; protectedDelete=profileActionControls.delete
assert(protectedRename and protectedRename.enabled==false,"default profile rename must be disabled")
assert(protectedDelete and protectedDelete.enabled==false,"default profile delete must be disabled")
for _,action in ipairs({"rename","duplicate","reset","delete"}) do
  local control=assert(profileActionControls[action],"profile icon action is missing: "..action)
  assert(control.icon and control.icon.texture and control.width==32,"profile action did not render as an icon: "..action)
end
assert(profileActionControls.rename.point[4]<profileActionControls.duplicate.point[4] and
  profileActionControls.duplicate.point[4]<profileActionControls.reset.point[4] and
  profileActionControls.reset.point[4]<profileActionControls.delete.point[4],
  "profile icons are not ordered Rename, Duplicate, Reset, Delete from left to right")
local testProfileCard
for _,frame in ipairs(uiFrames) do if frame.kind=="Button" and frame.parent and frame.parent.kind=="Frame" and frame.profileId=="profile-1" and frame.height==48 then testProfileCard=frame end end
assert(testProfileCard,"profile selection card was not created")
local testProfileSummary
for _,frame in ipairs(uiFrames) do
  if frame.kind=="FontString" and frame.parent==testProfileCard and frame.text:find("Inclusions",1,true) then testProfileSummary=frame; break end
end
assert(testProfileSummary and testProfileSummary.point and testProfileSummary.point[2]==-132,
  "profile summary does not leave clear space for its action buttons")
assert(testProfileSummary.text:find("|cff9d9d9dInclusions|r: |cffffffff1|r",1,true) and
  testProfileSummary.text:find("|cff9d9d9dExclusions|r: |cffffffff2|r",1,true),
  "inactive profile summary does not use upstream grey labels and white counts")
ui.GameTooltip.lines={}; testProfileCard.scripts.OnEnter(testProfileCard)
assert(ui.GameTooltip.text=="Test" and ui.GameTooltip.lines[1].left=="Inclusions" and
  ui.GameTooltip.lines[4].text:find("Used By",1,true) and ui.GameTooltip.lines[5].text:find("Realm - Test",1,true),
  "profile hover summary did not show counts and its assigned character")
testProfileCard.scripts.OnLeave(testProfileCard)
testProfileCard:Click()
assert(selectedProfile=="profile-1","profile card did not activate the profile represented by that card")
local function profileAction(action,id)
  for index=#uiFrames,1,-1 do
    local frame=uiFrames[index]
    if frame.kind=="Button" and frame.profileId==id and frame.profileAction==action then return frame end
  end
  error("missing profile action "..action.." for "..id)
end
for _,action in ipairs({"rename","duplicate","reset","delete"}) do
  local control=profileAction(action,"profile-1")
  assert(control.icon and control.icon.texture and control.width==32,
    "profile action is missing its upstream-style icon: "..action)
end
local createProfileButton=lastControl("Button","New Profile")
createProfileButton:Click()
local profilePopup=profilesPage.profilePopup
assert(profilePopup and profilePopup.shown and profilePopup.backdrop and profilePopup.editBox.shown,
  "profile name dialog was not rendered as an addon-styled prompt")
assert(profilePopup.blocker.shown and profilePopup.strata=="FULLSCREEN_DIALOG" and profilePopup.blocker.frameLevel==1000,
  "profile prompt did not render above the main window as a modal")
assert(profilePopup.editBox.focused and profilePopup.editBox.focusedWhileVisible,
  "profile name input did not receive focus after the modal became visible")
assert(profilePopup.editBox.backdrop and profilePopup.editBox.fontObject=="GameFontNormalSmall",
  "profile name input has no visible legacy edit field styling")
assert(profilePopup.editBox.textColor and profilePopup.editBox.textColor[1]==1,
  "profile name input text color does not match upstream")
assert(profilePopup.acceptButton:GetFrameLevel()>profilePopup:GetFrameLevel() and
  profilePopup.cancelButton:GetFrameLevel()>profilePopup:GetFrameLevel(),
  "profile modal buttons do not sit above the full-screen mouse blocker")
profilePopup.editBox:SetText("Fresh")
profilePopup.acceptButton:Click()
assert(profileOperations.create and profileOperations.create.name=="Fresh","New Profile dialog did not create the entered name")
profileAction("duplicate","profile-1"):Click()
profilePopup.editBox:SetText("Test Copy")
profilePopup.acceptButton:Click()
assert(profileOperations.duplicate and profileOperations.duplicate.id=="profile-1" and profileOperations.duplicate.name=="Test Copy",
  "profile card duplicate did not copy the selected profile")
profileAction("rename","profile-1"):Click()
profilePopup.editBox:SetText("Renamed")
profilePopup.acceptButton:Click()
assert(profileOperations.rename and profileOperations.rename.id=="profile-1" and profileOperations.rename.name=="Renamed",
  "profile card rename did not target the selected profile")
profileAction("reset","profile-1"):Click()
assert(profilePopup.shown and not profilePopup.editBox.shown and profilePopup.acceptButton.text=="Yes",
  "profile confirmation did not switch the themed popup into confirmation mode")
profilePopup.acceptButton:Click()
assert(profileOperations.reset=="profile-1","profile reset did not target the selected profile")
profileAction("delete","profile-1"):Click()
profilePopup.acceptButton:Click()
assert(profileOperations.delete=="profile-1","profile delete did not target the selected profile")
assert(protectedRename.icon and protectedDelete.icon,"default profile action icons are missing")
control("Button","Lists"):Click()
assert(profilesPage.shown==false and namedFrame("DejunkWotLKLists").shown,"Lists navigation left the Profiles page visible")
runtime:ShowProfiles({profiles=function() return {} end,activeProfileId=function() return "default" end,activeProfileName=function() return "Default" end})
local optionState={quality={[0]=true},includeByQuality={enabled=true,scope="BOTH",qualities={poor=true,common=false,uncommon=false,rare=false,epic=false}},includeBelowItemLevel={enabled=false,scope="BOTH",value=0,qualities={poor=true,common=false,uncommon=false,rare=false,epic=false}},includeBelowPrice={enabled=false,scope="SELL",value=0,qualities={poor=true,common=false,uncommon=false,rare=false,epic=false}},excludeAboveItemLevel={enabled=false,scope="BOTH",value=0,qualities={poor=true,common=true,uncommon=true,rare=true,epic=true}},excludeAbovePrice={enabled=false,scope="DESTROY",value=0,qualities={poor=true,common=true,uncommon=true,rare=true,epic=true}},includeByEquipmentType={enabled=false,scope="BOTH",qualities={poor=true,common=false,uncommon=false,rare=false,epic=false},armor={},weapons={}},excludeByEquipmentType={enabled=false,scope="BOTH",qualities={poor=true,common=true,uncommon=true,rare=true,epic=true},armor={},weapons={}},autoSell=false,autoRepair=false,excludeEquipmentSets={enabled=true,scope="BOTH"},excludeUnboundEquipment={enabled=false,scope="BOTH",qualities={poor=true,common=true,uncommon=true,rare=true,epic=true}},excludeQuestItems={enabled=true,scope="BOTH"}}
local globalOptionState={safeSell=false,safeDestroy=true,merchantButton=true,minimapIcon={hide=false},
  autoJunkFrame=false,autoLootableFrame=false,chatMessages={enabled=true,detail="REDUCED"},
  itemTooltips=true,itemIcons=false,itemIconStyle="SMALL"}
local optionCallbacks={options=function() return optionState end,globalOptions=function() return globalOptionState end,
  setOption=function(key,value)
    if key=="quality" then
      local qualityNames={[0]="poor",[1]="common",[2]="uncommon",[3]="rare",[4]="epic"}
      optionState.quality[value.quality]=value.enabled; optionState.includeByQuality.qualities[qualityNames[value.quality]]=value.enabled
    elseif key=="includeByQuality" then optionState.includeByQuality=value
    elseif key=="excludeEquipmentSets" and type(value)=="boolean" then optionState[key]={enabled=value,scope="BOTH"}
    elseif key=="excludeUnboundEquipment" and type(value)=="boolean" then optionState[key].enabled=value
    else optionState[key]=value end
    return true
  end,
  setGlobalOption=function(key,value)
    if key=="chatMessages" then for field,setting in pairs(value) do globalOptionState.chatMessages[field]=setting end
    else globalOptionState[key]=value end
    return true
  end,
  activeProfileName=function() return "Test" end}
runtime:ShowOptions(optionCallbacks,"profile")
local optionsPage=namedFrame("DejunkWotLKOptions")
assert(optionsPage,"options page was not created")
assert(optionsPage.parent==profilesPage.parent,"Options page is outside the main configuration content")
assert(optionsPage.width and optionsPage.width>0 and optionsPage.height and optionsPage.height>0,
  "Options page was not sized by the main Waffle layout")
assert(optionsPage.backdrop~=nil,"Options page is missing the opaque active-page background")
assert(optionsPage.backdropColor and optionsPage.backdropColor[4]==1,"Options page background is not opaque over inactive screens")
assert(optionsPage.scrollFrame and optionsPage.scrollFrame.template==nil and optionsPage.scrollFrame.scrollTrack,"Profile options must use the plain legacy scroll track")
local optionsScroll=optionsPage.scrollFrame
local previousHeight=optionsScroll.height
optionsScroll:SetHeight(160); optionsScroll.scrollTrack:SetHeight(160)
optionsScroll:SetVerticalScroll(0)
optionsScroll.scripts.OnMouseWheel(optionsScroll,-1)
assert(optionsScroll:GetVerticalScroll()==28 and optionsScroll.scrollTrack.shown,
  "plain option scrollbar did not move or reveal its overflow track")
optionsScroll.scripts.OnMouseWheel(optionsScroll,-10000)
assert(optionsScroll:GetVerticalScroll()==optionsPage.contentFrame:GetHeight()-160,
  "plain option scrollbar exceeded its content range")
optionsScroll.scripts.OnMouseWheel(optionsScroll,10000)
assert(optionsScroll:GetVerticalScroll()==0,"plain option scrollbar did not clamp at the top")
optionsScroll.height=previousHeight
assert(optionsPage.contentFrame and optionsPage.contentFrame.height>=2040,"Profile option groups must fit in the scroll content")
assert(optionsPage.contentFrame.width and optionsPage.contentFrame.width>=420,"Profile options content was not sized to its page")
local sectionOrder={}
for _,frame in ipairs(uiFrames) do
  if frame.kind=="FontString" and frame.parent==optionsPage.contentFrame and
    (frame.text=="General" or frame.text=="Include" or frame.text=="Exclude") then sectionOrder[#sectionOrder+1]=frame.text end
end
assert(table.concat(sectionOrder,",")=="General,Include,Exclude","Profile settings are not grouped in upstream section order")
assert(optionsPage.pageTitle.text=="Profile Options (|cffffffffTest|r)","profile options heading did not identify the active profile")
assert(optionsPage.pageTitle.textColor and optionsPage.pageTitle.textColor[1]>0.3,
  "upstream blue title color was not applied")
assert(optionsPage.pageDescription.text=="These options only apply to characters using the active profile.","upstream profile-options panel description is missing")
local cards={}
for _,frame in ipairs(uiFrames) do
  if frame.kind=="Frame" and frame.optionCard==true and frame.parent==optionsPage.contentFrame and frame.height and frame.point and frame.point[5] then
    if frame.shown~=false then cards[#cards+1]=frame end
  end
end
table.sort(cards,function(a,b) return -a.point[5] < -b.point[5] end)
for i=1,#cards-1 do
  assert(-cards[i].point[5]+cards[i].height<=-cards[i+1].point[5],"profile option cards overlap vertically")
end
for _,card in ipairs(cards) do
  assert(card.point[4]+card.width<=optionsPage.contentFrame.width,"profile option card extends beyond the scroll content width")
end
for _,frame in ipairs(uiFrames) do
  if frame.kind=="CheckButton" and frame.parent==optionsPage.contentFrame and frame.qualityRow then
    assert(frame:GetFrameLevel()>frame.parent:GetFrameLevel(),
      "Profile Options checkbox can be obscured by its option-card background")
    assert(frame.mouse==true and frame.registeredClicks and frame.registeredClicks[1]=="LeftButtonUp",
      "legacy quality checkbox is not explicitly mouse-clickable")
    assert(frame.labelHit.mouse==true and frame.labelHit.registeredClicks and frame.labelHit.registeredClicks[1]=="LeftButtonUp",
      "legacy quality label is not explicitly mouse-clickable")
    assert(frame.qualityRowY~=nil and frame.point[3]==frame.qualityRowY,
      "responsive quality row lost its saved vertical position")
    assert(frame.point[2]+frame.width+2+frame.labelHit.width<=optionsPage.contentFrame.width-10,
      "quality option and clickable label extend beyond the option card width")
  end
end
assert(profilesPage.shown==false,"Profiles page remained visible while Options was selected")
local listsPage=namedFrame("DejunkWotLKLists")
assert(not listsPage or listsPage.shown==false,"Lists remained visible behind Profile Options")
assert(optionsPage.shown,"Profile Options did not become the active Waffle page")
assert(optionsPage.alpha~=0,"Profile Options was made transparent by the legacy page visibility path")
assert(control("CheckButton","Auto Sell").shown,"profile options were hidden on the Profile Options page")
assert(control("CheckButton","Auto Sell").registeredClicks[1]=="LeftButtonUp",
  "Auto Sell checkbox has no explicit legacy click registration")
assert(control("CheckButton","Safe Sell").shown==false,"global options leaked into Profile Options")
local enableMinimum
for _,frame in ipairs(uiFrames) do
  if frame.kind=="CheckButton" and frame.parent==optionsPage.contentFrame and frame.optionLabel=="Include below item level" then enableMinimum=frame; break end
end
assert(enableMinimum,"threshold option card toggle was not created")
enableMinimum:Click()
assert(optionsPage.shown,"Profile Options refresh hid the page after the first setting click")
local thresholdEdit
for _,frame in ipairs(uiFrames) do if frame.kind=="EditBox" and frame.parent==optionsPage.contentFrame and frame.thresholdKey=="includeBelowItemLevel" then thresholdEdit=frame; break end end
assert(thresholdEdit,"profile threshold editor was not created")
thresholdEdit:SetText("60")
local applyThreshold,afterEditor
for _,frame in ipairs(uiFrames) do
  if frame==thresholdEdit then afterEditor=true
  elseif afterEditor and frame.kind=="Button" and frame.text=="Apply" and frame.parent==optionsPage.contentFrame then applyThreshold=frame; break end
end
assert(applyThreshold,"profile threshold Apply control was not created")
assert(applyThreshold.template==nil,"profile Apply still uses the red Blizzard button template")
applyThreshold:Click()
assert(optionState.includeBelowItemLevel.enabled and optionState.includeBelowItemLevel.value==60,"minimum item level did not persist through the UI")
local minimumScope,afterApply
for _,frame in ipairs(uiFrames) do
  if frame==applyThreshold then afterApply=true
  elseif afterApply and frame.kind=="CheckButton" and frame.parent==optionsPage.contentFrame and frame.scopeKey=="includeBelowItemLevel" and frame.scopeValue=="SELL" then minimumScope=frame; break end
end
assert(minimumScope,"threshold scope control was not created")
minimumScope.labelHit:Click()
assert(optionState.includeBelowItemLevel.scope=="SELL","threshold action scope did not update through the UI")
local minimumPoor
for _,frame in ipairs(uiFrames) do if frame.kind=="CheckButton" and frame.parent==optionsPage.contentFrame and frame.optionGroup=="includeBelowItemLevel" and frame.optionQuality=="poor" then minimumPoor=frame end end
assert(minimumPoor,"threshold quality control was not created")
assert(minimumPoor.width==12 and minimumPoor.labelHit.width>=20 and minimumPoor.labelHit.width<=78,
  "threshold quality chip does not match the compact Waffle checkbox dimensions")
assert(minimumPoor.labelRegion and minimumPoor.labelRegion.text=="Poor","legacy checkbox label is not rendered through its own FontString")
assert(minimumPoor.optionVisual and minimumPoor.optionVisual.box.borderColor[1]>0.3 and minimumPoor.optionVisual.fill.vertexColor[1]>0.3,
  "Waffle blue checkbox treatment was not rendered")
assert(minimumPoor.optionVisual.box.backdrop and minimumPoor.optionVisual.box.backdrop.edgeSize==1,
  "Waffle square checkbox border was not rendered")
local minScopeWidth
for _,frame in ipairs(uiFrames) do if frame==minimumScope then minScopeWidth=frame.width end end
assert(minScopeWidth==12 and minimumScope.labelHit.width==80,"threshold scope chip does not match the compact Waffle checkbox dimensions")
local minQualityRow={}
for _,frame in ipairs(uiFrames) do
  if frame.kind=="CheckButton" and frame.parent==optionsPage.contentFrame and frame.optionGroup=="includeBelowItemLevel" and frame.optionQuality then minQualityRow[#minQualityRow+1]=frame end
end
table.sort(minQualityRow,function(a,b) return a.point[2]<b.point[2] end)
assert(#minQualityRow==5,"minimum item level should have five quality controls")
for i=1,#minQualityRow-1 do
  assert(minQualityRow[i].point[2]+minQualityRow[i].width+2+minQualityRow[i].labelHit.width<=minQualityRow[i+1].point[2],
    "threshold quality choice labels overlap horizontally")
end
minimumPoor.labelHit:Click()
assert(optionState.includeBelowItemLevel.qualities.poor==false,"threshold quality selection did not update through the UI")
local setScope
for _,frame in ipairs(uiFrames) do if frame.kind=="CheckButton" and frame.parent==optionsPage.contentFrame and frame.scopeKey=="excludeEquipmentSets" and frame.scopeValue=="SELL" then setScope=frame end end
assert(setScope,"equipment set scope control was not created")
setScope:Click()
assert(optionState.excludeEquipmentSets.scope=="SELL","equipment set scope did not update through the UI")
local unboundPoor
for _,frame in ipairs(uiFrames) do
  if frame.kind=="CheckButton" and frame.parent==optionsPage.contentFrame and frame.optionLabel=="Exclude unbound equipment" then frame:Click(); break end
end
assert(optionState.excludeUnboundEquipment.enabled,"unbound equipment option card did not enable")
for _,frame in ipairs(uiFrames) do if frame.kind=="CheckButton" and frame.parent==optionsPage.contentFrame and frame.optionGroup=="excludeUnboundEquipment" and frame.optionLabel=="Poor" then unboundPoor=frame end end
assert(unboundPoor,"unbound equipment quality control was not created")
unboundPoor:Click()
assert(optionState.excludeUnboundEquipment.qualities.poor==false,"unbound equipment quality did not update through the UI")
local priceEdit
for _,frame in ipairs(uiFrames) do
  if frame.kind=="EditBox" and frame.parent==optionsPage.contentFrame and frame.thresholdKey=="includeBelowPrice" and frame.thresholdPart==3 then priceEdit=frame; break end
end
assert(priceEdit,"minimum stack price editor was not created")
for _,frame in ipairs(uiFrames) do
  if frame.kind=="CheckButton" and frame.parent==optionsPage.contentFrame and frame.optionLabel=="Include below price" then frame:Click(); break end
end
priceEdit:SetText("3")
for _,frame in ipairs(uiFrames) do
  if frame.kind=="EditBox" and frame.parent==optionsPage.contentFrame and frame.thresholdKey=="includeBelowPrice" and frame.thresholdPart==1 then frame:SetText("1") end
  if frame.kind=="EditBox" and frame.parent==optionsPage.contentFrame and frame.thresholdKey=="includeBelowPrice" and frame.thresholdPart==2 then frame:SetText("2") end
end
local applyPrice,afterPriceEdit
for _,frame in ipairs(uiFrames) do
  if frame==priceEdit then afterPriceEdit=true
  elseif afterPriceEdit and frame.kind=="Button" and frame.text=="Apply" and frame.parent==optionsPage.contentFrame then applyPrice=frame; break end
end
assert(applyPrice,"minimum stack price Apply control was not created")
applyPrice:Click()
assert(optionState.includeBelowPrice.enabled and optionState.includeBelowPrice.value==10203,"minimum stack price did not persist through UI")
local includeTypes
for _,frame in ipairs(uiFrames) do
  if frame.kind=="CheckButton" and frame.parent==optionsPage.contentFrame and frame.optionLabel=="Include by equipment type" then includeTypes=frame; break end
end
assert(includeTypes,"include equipment type option card was not created")
includeTypes:Click()
assert(optionState.includeByEquipmentType.enabled,"include equipment type option did not enable")
local clothType
for _,frame in ipairs(uiFrames) do
  if frame.kind=="CheckButton" and frame.parent==optionsPage.contentFrame and frame.optionLabel=="Cloth" then clothType=frame; break end
end
assert(clothType,"localized Armor subclass controls were not built from the 3.3.5 API")
clothType:Click()
assert(optionState.includeByEquipmentType.armor[1]==true,"Armor subclass selection did not persist")
local fishingPoles
for _,frame in ipairs(uiFrames) do
  if frame.kind=="CheckButton" and frame.parent==optionsPage.contentFrame and frame.optionLabel=="Fishing Poles" then fishingPoles=frame; break end
end
assert(fishingPoles,"localized weapon subclass controls were not built from the 3.3.5 API")
fishingPoles:Click()
assert(optionState.includeByEquipmentType.weapons[10]==true,"weapon subclass selection did not persist")
control("CheckButton","Include by quality"):Click()
assert(optionState.includeByQuality.enabled==false and optionState.includeByQuality.qualities.poor==true,"quality rule toggle did not preserve the quality selection")
control("CheckButton","Include by quality"):Click()
assert(optionState.includeByQuality.enabled==true,"quality rule could not be re-enabled")
local qualityCard
for _,frame in ipairs(cards) do if frame.point and frame.point[5]==-208 then qualityCard=frame; break end end
assert(qualityCard and qualityCard.scripts.OnMouseDown,"upstream option card click behavior was not provided")
qualityCard.scripts.OnMouseDown(qualityCard,"RightButton")
assert(optionState.includeByQuality.enabled==true,"right-click unexpectedly toggled the quality option")
qualityCard.scripts.OnMouseDown(qualityCard,"LeftButton")
assert(optionState.includeByQuality.enabled==false,"clicking the option card did not toggle its setting")
qualityCard.scripts.OnMouseDown(qualityCard,"LeftButton")
assert(optionState.includeByQuality.enabled==true,"option card did not toggle back on")
control("CheckButton","Auto Sell"):Click(); assert(optionState.autoSell==true)
runtime:ShowOptions(optionCallbacks,"global")
assert(control("CheckButton","Safe Sell").shown and control("CheckButton","Safe Destroy").shown,
  "global safety option cards were hidden on the Global Options page")
assert(control("CheckButton","Auto Sell").shown==false,"profile options leaked into Global Options")
local globalHeadings={}
for _,frame in ipairs(uiFrames) do
  if frame.kind=="FontString" and frame.parent==optionsPage.contentFrame and (frame.text=="Safety" or frame.text=="Interface" or frame.text=="Bags") then
    globalHeadings[#globalHeadings+1]=frame.text
  end
end
assert(table.concat(globalHeadings,",")=="Safety,Interface,Bags","Global Options groups do not match the upstream order")
local globalCards={}
for _,frame in ipairs(uiFrames) do
  if frame.kind=="Frame" and frame.optionCard and frame.parent==optionsPage.contentFrame and frame.shown and frame.point and frame.point[5] and frame.point[4] then
    globalCards[#globalCards+1]=frame
    assert(frame.point[4]+frame.width<=optionsPage.contentFrame.width,"global option card extends beyond the scroll content width")
  end
  if frame.kind=="FontString" and frame.optionDescription and frame.shown and frame.point and frame.point[2] then
    assert(frame.optionDescriptionX==frame.point[2],"option description did not retain its WotLK-safe horizontal coordinate")
    assert(frame.optionDescriptionX+frame.width<=optionsPage.contentFrame.width,
      "option description extends beyond the scroll content width")
  end
end
assert(#globalCards>=8,"Global Options did not create the upstream Safety, Interface and Bags option cards")
assert(control("CheckButton","Merchant Button").shown and control("CheckButton","Bag Item Icons").shown,
  "upstream Interface and Bags global option cards were not created")
assert(optionsPage.pageDescription.text=="These options apply to every character, regardless of active profile.",
  "Global Options panel description is missing")
assert(control("CheckButton","Verbose").shown==true and control("CheckButton","Small").shown==true,
  "global option detail and icon-size choices were not created")
control("CheckButton","Merchant Button"):Click()
assert(globalOptionState.merchantButton==false,"merchant button option did not persist")
local resetPoint
runtime:SetWindowPointHandlers(function() end,function(key,value)
  if key=="merchantButton" then resetPoint=value; return true end
  return false
end)
control("CheckButton","Merchant Button").labelHit:Click("RightButton")
assert(resetPoint and resetPoint.offsetX==210 and resetPoint.offsetY==-44 and globalOptionState.merchantButton==false,
  "right-clicking Merchant Button options did not reset its position without toggling it")
control("CheckButton","Verbose").labelHit:Click()
assert(globalOptionState.chatMessages.detail=="VERBOSE","chat detail choice did not persist")
control("CheckButton","Large").labelHit:Click()
assert(globalOptionState.itemIconStyle=="LARGE","clicking the icon-size label did not save its choice")
control("CheckButton","Safe Sell"):Click(); assert(globalOptionState.safeSell==true)
runtime:ShowOptions(optionCallbacks,"profile")
control("CheckButton","Poor"):Click(); assert(optionState.includeByQuality.qualities.poor==false)
control("CheckButton","Exclude unbound equipment"):Click(); assert(optionState.excludeUnboundEquipment.enabled==false)

local ids={}; for id=1001,1030 do ids[#ids+1]=tostring(id) end
local queries=0
ui.GetItemInfo=function() queries=queries+1; return nil end
runtime:ShowLists({listItems=function(scope,kind)
  return scope=="global" and kind=="inclusions" and table.concat(ids,"\n") or ""
end})
local listsWindow=namedFrame("DejunkWotLKLists")
assert(listsWindow and listsWindow.scripts.OnUpdate)
assert(profilesPage.shown==false,"Profiles page remained visible while Lists was selected")
assert(queries==25,"metadata query batch exceeded 25 items")
assert(listPanes["global:inclusions"].spinner.shown and not listPanes["global:exclusions"].spinner.shown,
  "list metadata spinner did not match the pane that is still loading")
listsWindow.scripts.OnUpdate(listsWindow,0.1)
assert(queries==50,"next metadata tick did not advance the bounded queue")
listsWindow.scripts.OnUpdate(listsWindow,29.9)
assert(listsWindow.scripts.OnUpdate==nil,"uncached item metadata polling did not time out")
assert(not listPanes["global:inclusions"].spinner.shown,"list loading indicator stayed active after metadata timeout")

print("UI INTERACTION RESULT: options, keybindings, item windows, list transport, metadata polling and report navigation passed")

-- Original 3.3.5 CheckButton:GetChecked may return 1/nil instead of booleans.
globalOptionState.safeSell=false
ui.numericChecked=true
runtime:ShowOptions(optionCallbacks,"global")
local checkedGlobal,uncheckedGlobal
for _,frame in ipairs(uiFrames) do
  if frame.kind=="CheckButton" and frame.globalOptionKey=="safeDestroy" then checkedGlobal=frame
  elseif frame.kind=="CheckButton" and frame.globalOptionKey=="safeSell" then uncheckedGlobal=frame end
end
assert(checkedGlobal and checkedGlobal.optionVisual.fill.shown==true,
  "legacy numeric GetChecked result did not draw the checked state")
assert(uncheckedGlobal and uncheckedGlobal.optionVisual.fill.shown==false,
  "legacy numeric GetChecked result drew an unchecked state as checked")
ui.numericChecked=false
local mainWindow=namedFrame("DejunkWotLK_MainWindow")
assert(mainWindow and mainWindow.shown,"main settings window is not visible before toggle test")
runtime:ToggleConfig(runtime.configCallbacks)
assert(mainWindow.shown==false,"original command toggle did not hide the main window")
runtime:ToggleConfig(runtime.configCallbacks)
assert(mainWindow.shown==true,"original command toggle did not reopen the main window")

-- Exercise the real store/config/UI path: checkboxes and Apply must render the
-- values persisted by the active profile, not a mock-only parallel state.
local persistedUiStore=Addon.Store.Initialize(nil,"UI\31Tester")
local persistedCallbacks={
  options=function() return Addon.Config.GetOptions(persistedUiStore) end,
  setOption=function(key,value) return Addon.Config.SetOption(persistedUiStore,key,value) end,
  globalOptions=function() return Addon.Config.GetGlobalOptions(persistedUiStore) end,
  setGlobalOption=function(key,value) return Addon.Config.SetGlobalOption(persistedUiStore,key,value) end,
  activeProfileName=function() return persistedUiStore:GetActiveProfile().name end
}
runtime:ShowOptions(persistedCallbacks,"profile")
local persistedAutoSell=lastControl("CheckButton","Auto Sell")
assert(persistedAutoSell:GetChecked()==false,"new profile Auto Sell should start unchecked")
persistedAutoSell:Click()
assert(persistedUiStore:GetActiveProfile().autoSell==true and lastControl("CheckButton","Auto Sell"):GetChecked()==true,
  "Auto Sell visual state did not follow the persisted profile value")
local persistedRepair=lastControl("CheckButton","Auto Repair")
persistedRepair:Click()
assert(persistedUiStore:GetActiveProfile().autoRepair==true and lastControl("CheckButton","Auto Repair"):GetChecked()==true,
  "Auto Repair visual state did not follow the persisted profile value")
local persistedLevelToggle=lastControl("CheckButton","Include below item level")
assert(persistedLevelToggle:GetChecked()==false,"new threshold filter should start disabled")
local persistedLevelScope,persistedLevelQuality
for _,frame in ipairs(uiFrames) do
  if frame.kind=="CheckButton" and frame.scopeKey=="includeBelowItemLevel" and frame.scopeValue=="SELL" then persistedLevelScope=frame end
  if frame.kind=="CheckButton" and frame.optionGroup=="includeBelowItemLevel" and frame.optionQuality=="poor" then persistedLevelQuality=frame end
end
assert(persistedLevelScope and persistedLevelScope.enabled~=false and persistedLevelQuality and persistedLevelQuality.enabled~=false,
  "disabled threshold filter blocked configuration of its scope or qualities")
persistedLevelScope:Click(); persistedLevelQuality:Click()
local offState=persistedUiStore:GetActiveProfile().options.includeBelowItemLevel
assert(offState.enabled==false and offState.scope=="SELL" and offState.qualities.poor==false,
  "threshold scope and qualities could not be edited while the filter was disabled")
local persistedLevelEdit,persistedLevelApply
for _,frame in ipairs(uiFrames) do
  if frame.kind=="EditBox" and frame.thresholdKey=="includeBelowItemLevel" then persistedLevelEdit=frame end
  if frame.kind=="Button" and frame.thresholdKey=="includeBelowItemLevel" then persistedLevelApply=frame end
end
assert(persistedLevelEdit and persistedLevelApply,"item-level input or Apply button is missing")
assert(persistedLevelApply.enabled~=false,"Apply is disabled while the threshold filter is off")
persistedLevelEdit.scripts.OnMouseDown(persistedLevelEdit)
assert(persistedLevelEdit.focused,"threshold input did not receive focus on click")
persistedLevelEdit:SetText("47")
persistedLevelApply:Click()
local appliedThreshold=persistedUiStore:GetActiveProfile().options.includeBelowItemLevel
assert(appliedThreshold.value==47 and appliedThreshold.enabled==true and appliedThreshold.scope=="SELL" and appliedThreshold.qualities.poor==false,
  "Profile Options Apply did not persist and enable the configured threshold")
local moreThresholds={
  {key="includeBelowPrice",value=1234,scope="SELL",parts={"0","12","34"}},
  {key="excludeAboveItemLevel",value=58,scope="DESTROY",parts={"58"}},
  {key="excludeAbovePrice",value=3210,scope="BOTH",parts={"0","32","10"}}
}
for _,spec in ipairs(moreThresholds) do
  local scopeChoice,qualityChoice,label,apply
  local inputs={}
  for _,frame in ipairs(uiFrames) do
    if frame.kind=="CheckButton" and frame.thresholdKey==spec.key then label=frame end
    if frame.kind=="CheckButton" and frame.scopeKey==spec.key and frame.scopeValue==spec.scope then scopeChoice=frame end
    if frame.kind=="CheckButton" and frame.optionGroup==spec.key and frame.optionQuality=="poor" then qualityChoice=frame end
    if frame.kind=="EditBox" and frame.thresholdKey==spec.key then inputs[frame.thresholdPart]=frame end
    if frame.kind=="Button" and frame.thresholdKey==spec.key then apply=frame end
  end
  assert(label and scopeChoice and qualityChoice and apply,"missing threshold controls for "..spec.key)
  assert(apply.enabled~=false and scopeChoice.enabled~=false and qualityChoice.enabled~=false,
    "disabled filter blocked editing controls for "..spec.key)
  scopeChoice:Click(); qualityChoice:Click()
  for part,value in ipairs(spec.parts) do assert(inputs[part],"missing threshold part "..part); inputs[part]:SetText(value) end
  apply:Click()
  local result=persistedUiStore:GetActiveProfile().options[spec.key]
  assert(result.enabled==true and result.scope==spec.scope and result.value==spec.value and result.qualities.poor==false,
    "threshold controls did not persist full state for "..spec.key)
end
local qualityRule=Addon.Config.GetOptions(persistedUiStore).includeByQuality
qualityRule.enabled=false
assert(Addon.Config.SetOption(persistedUiStore,"includeByQuality",qualityRule))
runtime:ShowOptions(persistedCallbacks,"profile")
local includeQualityTitle,includeQualityScope,includeQualityPoor
for _,frame in ipairs(uiFrames) do
  if frame.kind=="CheckButton" and frame.optionLabel=="Include by quality" then includeQualityTitle=frame end
  if frame.kind=="CheckButton" and frame.scopeKey=="includeByQuality" and frame.scopeValue=="SELL" then includeQualityScope=frame end
  if frame.kind=="CheckButton" and frame.optionGroup=="includeByQuality" and frame.optionQuality=="poor" then includeQualityPoor=frame end
end
assert(includeQualityTitle and includeQualityScope and includeQualityPoor and includeQualityScope.enabled~=false and includeQualityPoor.enabled~=false,
  "Include by quality subcontrols were disabled with the parent filter")
includeQualityScope:Click(); includeQualityPoor:Click()
local savedQualityRule=Addon.Config.GetOptions(persistedUiStore).includeByQuality
assert(savedQualityRule.enabled==false and savedQualityRule.scope=="SELL" and savedQualityRule.qualities.poor==false,
  "Include by quality scope and quality were not saved while its filter was off")
includeQualityTitle:Click()
assert(Addon.Config.GetOptions(persistedUiStore).includeByQuality.enabled==true and
  lastControl("CheckButton","Include by quality"):GetChecked()==true,
  "Include by quality did not activate or render its persisted state")
