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

local function object(kind,name,parent,template)
  local frame={kind=kind,name=name,parent=parent,template=template,scripts={},children={},enabled=true,text=""}
  function frame:SetWidth(value) self.width=value end
  function frame:SetHeight(value) self.height=value end
  function frame:SetAlpha(value) self.alpha=value end
  function frame:SetPoint(...) self.point={...} end
  function frame:SetAllPoints(relative) self.allPoints=relative end
  function frame:ClearAllPoints() self.point=nil end
  function frame:SetParent(parent) self.parent=parent end
  function frame:SetFrameStrata(value) self.strata=value end
  function frame:SetMovable(value) self.movable=value end
  function frame:RegisterForDrag(...) self.dragButtons={...} end
  function frame:StartMoving() self.moving=true end
  function frame:StopMovingOrSizing() self.moving=false end
  function frame:EnableMouse(value) self.mouse=value end
  function frame:EnableKeyboard(value) self.keyboard=value end
  function frame:SetBackdrop(value) self.backdrop=value end
  function frame:SetBackdropColor(...) self.backdropColor={...} end
  function frame:SetBackdropBorderColor(...) self.borderColor={...} end
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
  function frame:SetFocus() self.focused=true end
  function frame:SetVerticalScroll(value) self.verticalScroll=value end
  function frame:SetScript(event,callback) self.scripts[event]=callback end
  function frame:RegisterForClicks(...) self.registeredClicks={...} end
  function frame:SetText(value)
    if self.kind=="CheckButton" then error("legacy CheckButton has no SetText method") end
    self.text=value
    if self.kind=="EditBox" and self.scripts.OnTextChanged then self.scripts.OnTextChanged(self) end
  end
  function frame:SetChecked(value) self.checked=value end
  function frame:GetChecked() return self.checked end
  function frame:GetText() return self.text end
  function frame:GetWidth() return self.width end
  function frame:Enable() if self.kind=="EditBox" then error("legacy EditBox has no Enable method") end; self.enabled=true end
  function frame:Disable() if self.kind=="EditBox" then error("legacy EditBox has no Disable method") end; self.enabled=false end
  function frame:SetEnabled(value) if self.kind=="EditBox" then error("legacy EditBox has no SetEnabled method") end; self.enabled=value end
  function frame:Show() self.shown=true end
  function frame:Hide() self.shown=false end
  function frame:ClearFocus() self.focused=false end
  function frame:SetFocus() self.focused=true end
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
  function frame:Click(button)
    assert(self.enabled~=false,"clicked disabled control")
    assert(self.scripts.OnClick,"control has no click handler")
    self.scripts.OnClick(self,button or "LeftButton")
  end
  uiFrames[#uiFrames+1]=frame
  return frame
end
ui.CreateFrame=function(kind,name,parent,template) return object(kind,name,parent,template) end
ui.IsShiftKeyDown=function() return ui.shiftDown==true end
ui.IsControlKeyDown=function() return ui.controlDown==true end
ui.IsAltKeyDown=function() return ui.altDown==true end

local activeId="profile-1"
local activeName="Test"
local rules={}
local messages={}
local runtime=Addon.Runtime.New(setmetatable({print=function(message) messages[#messages+1]=message end},{__index=ui}))
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
  commitListImport=function(preview) return listStore:CommitImport(preview) end
}
runtime:ShowConfig(listCallbacks)
control("Button","Lists"):Click()
assert(namedFrame("DejunkWotLKLists"),"Lists page frame was not created")
local listFrame=namedFrame("DejunkWotLKLists")
local mainWindow=namedFrame("DejunkWotLK_MainWindow")
assert(listFrame and listFrame.width and listFrame.width>0 and listFrame.height and listFrame.height>0 and listFrame.shown,
  "Lists was not sized by the main Waffle layout")
assert(listFrame.alpha~=0,"Lists was made transparent by the legacy page visibility path")
assert(listFrame.backdrop==nil,"Lists page retained the extra nested window frame")
local ancestor=listFrame
while ancestor and ancestor~=mainWindow do ancestor=ancestor.parent end
assert(ancestor==mainWindow,"Lists screen was not embedded in the main Waffle window")
local inclusionRow
for _,frame in ipairs(uiFrames) do
  if frame.kind=="Button" and frame.listScope=="global" and frame.listKind=="inclusions" then inclusionRow=frame; break end
end
assert(inclusionRow and inclusionRow.scripts.OnMouseDown,"list item rows do not accept cursor items")
cursorItemId=6949
inclusionRow.scripts.OnMouseDown(inclusionRow)
assert(listStore:GetState().global.inclusions[6949]==true,"cursor item was not added to the list")
assert(cursorItemId==nil,"successful list drop did not clear the cursor item")
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
control("Button","Export"):Click()
local report=uiFrames[#uiFrames]
while report and report.name~="DejunkWotLKReadOnlyReport" do report=report.parent end
assert(report and report.shown and listFrame.shown==false)
assert(namedFrame("DejunkWotLKReadOnlyReport"),"report window did not use the Waffle window factory")
local exported=lastControl("EditBox","6948\n6949")
assert(exported.focused and exported.highlighted)
lastControl("Button",nil,"UIPanelCloseButton"):Click()
assert(listFrame.shown==true)

control("Button","Import"):Click()
assert(namedFrame("DejunkWotLKListImport"),"import window did not use the Waffle window factory")
assert(listFrame.shown==false)
local importInput
for _,frame in ipairs(uiFrames) do if frame.kind=="EditBox" and frame.width==455 then importInput=frame end end
assert(importInput)
importInput:SetText("123, 456")
control("Button","Review"):Click()
assert(lastControl("FontString","Ready: 2 new IDs; 0 already present."))
lastControl("Button","Import"):Click()
assert(listFrame.shown==true)
assert(listStore:ExportList("global","inclusions")=="123\n456\n6948\n6949")

local function listRow(scope,kind,id)
  for _,frame in ipairs(uiFrames) do
    if frame.kind=="Button" and frame.itemId==tostring(id) and frame.listScope==scope and frame.listKind==kind then return frame end
  end
  error("missing list row "..scope.."/"..kind.."/"..id)
end
local globalInclusionRow=listRow("global","inclusions",6948)
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
for _,message in ipairs(messages) do assert(not message:find("Waffle configuration UI failed",1,true)) end
control("Button","Preview SELL"):Click()
assert(configFrame.shown==false)
lastChild(report,"Button","UIPanelCloseButton"):Click()
assert(configFrame.shown==true)
runtime:ShowProfiles({profiles=function() return {} end,activeProfileId=function() return "default" end})
local profilesPage=namedFrame("DejunkWotLKProfiles")
assert(profilesPage,"profiles page was not created")
assert(profilesPage.parent==namedFrame("DejunkWotLKLists").parent,"Profiles page is outside the main configuration content")
assert(profilesPage.width and profilesPage.width>0 and profilesPage.height and profilesPage.height>0,
  "Profiles page was not sized by the main Waffle layout")
assert(profilesPage.alpha~=0,"Profiles page was made transparent by the legacy page visibility path")
assert(profilesPage.backdrop==nil,"Profiles page retained its own dialog backdrop")
assert(profilesPage.shown,"Profiles page was not visible when selected")
control("Button","Lists"):Click()
assert(profilesPage.shown==false and namedFrame("DejunkWotLKLists").shown,"Lists navigation left the Profiles page visible")
runtime:ShowProfiles({profiles=function() return {} end,activeProfileId=function() return "default" end})
local optionState={quality={[0]=true},includeByQuality={enabled=true,scope="BOTH",qualities={poor=true,common=false,uncommon=false,rare=false,epic=false}},includeBelowItemLevel={enabled=false,scope="BOTH",value=0,qualities={poor=true,common=false,uncommon=false,rare=false,epic=false}},includeBelowPrice={enabled=false,scope="SELL",value=0,qualities={poor=true,common=false,uncommon=false,rare=false,epic=false}},excludeAboveItemLevel={enabled=false,scope="BOTH",value=0,qualities={poor=true,common=true,uncommon=true,rare=true,epic=true}},excludeAbovePrice={enabled=false,scope="DESTROY",value=0,qualities={poor=true,common=true,uncommon=true,rare=true,epic=true}},includeByEquipmentType={enabled=false,scope="BOTH",qualities={poor=true,common=false,uncommon=false,rare=false,epic=false},armor={},weapons={}},excludeByEquipmentType={enabled=false,scope="BOTH",qualities={poor=true,common=true,uncommon=true,rare=true,epic=true},armor={},weapons={}},autoSell=false,autoRepair=false,excludeEquipmentSets={enabled=true,scope="BOTH"},excludeUnboundEquipment={enabled=false,scope="BOTH",qualities={poor=true,common=true,uncommon=true,rare=true,epic=true}},excludeQuestItems={enabled=true,scope="BOTH"}}
local globalOptionState={safeSell=false,safeDestroy=true}
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
  setGlobalOption=function(key,value) globalOptionState[key]=value; return true end,
  activeProfileName=function() return "Test" end}
runtime:ShowOptions(optionCallbacks,"profile")
local optionsPage=namedFrame("DejunkWotLKOptions")
assert(optionsPage,"options page was not created")
assert(optionsPage.parent==profilesPage.parent,"Options page is outside the main configuration content")
assert(optionsPage.width and optionsPage.width>0 and optionsPage.height and optionsPage.height>0,
  "Options page was not sized by the main Waffle layout")
assert(optionsPage.backdrop~=nil,"Options page is missing the opaque active-page background")
assert(optionsPage.backdropColor and optionsPage.backdropColor[4]==1,"Options page background is not opaque over inactive screens")
assert(optionsPage.scrollFrame and optionsPage.scrollFrame.template=="UIPanelScrollFrameTemplate","Profile options must use the legacy scroll-panel pattern")
assert(optionsPage.contentFrame and optionsPage.contentFrame.height>=2040,"Profile option groups must fit in the scroll content")
local sectionOrder={}
for _,frame in ipairs(uiFrames) do
  if frame.kind=="FontString" and frame.parent==optionsPage.contentFrame and
    (frame.text=="General" or frame.text=="Include" or frame.text=="Exclude") then sectionOrder[#sectionOrder+1]=frame.text end
end
assert(table.concat(sectionOrder,",")=="General,Include,Exclude","Profile settings are not grouped in upstream section order")
assert(optionsPage.pageTitle.text=="Dejunk | Profile Options (Test)","profile options heading did not identify the active profile")
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
assert(profilesPage.shown==false,"Profiles page remained visible while Options was selected")
local listsPage=namedFrame("DejunkWotLKLists")
assert(not listsPage or listsPage.shown==false,"Lists remained visible behind Profile Options")
assert(optionsPage.shown,"Profile Options did not become the active Waffle page")
assert(optionsPage.alpha~=0,"Profile Options was made transparent by the legacy page visibility path")
assert(control("CheckButton","Auto Sell").shown,"profile options were hidden on the Profile Options page")
assert(control("Button","Safe Sell: OFF").shown==false,"global options leaked into Profile Options")
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
assert(minimumPoor.width==24 and minimumPoor.labelHit.width==60,"threshold quality choice is not a compact checkbox with a clickable text label")
assert(minimumPoor.labelRegion and minimumPoor.labelRegion.text=="Poor","legacy checkbox label is not rendered through its own FontString")
local minScopeWidth
for _,frame in ipairs(uiFrames) do if frame==minimumScope then minScopeWidth=frame.width end end
assert(minScopeWidth==24 and minimumScope.labelHit.width==66,"threshold scope choice is not a compact checkbox with a clickable text label")
local minQualityRow={}
for _,frame in ipairs(uiFrames) do
  if frame.kind=="CheckButton" and frame.parent==optionsPage.contentFrame and frame.optionGroup=="includeBelowItemLevel" and frame.optionQuality then minQualityRow[#minQualityRow+1]=frame end
end
table.sort(minQualityRow,function(a,b) return a.point[2]<b.point[2] end)
assert(#minQualityRow==5,"minimum item level should have five quality controls")
for i=1,#minQualityRow-1 do
  assert(minQualityRow[i+1].point[2]-minQualityRow[i].point[2]>=92,"threshold quality choices overlap horizontally")
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
qualityCard.scripts.OnMouseDown(qualityCard)
assert(optionState.includeByQuality.enabled==false,"clicking the option card did not toggle its setting")
qualityCard.scripts.OnMouseDown(qualityCard)
assert(optionState.includeByQuality.enabled==true,"option card did not toggle back on")
control("CheckButton","Auto Sell"):Click(); assert(optionState.autoSell==true)
runtime:ShowOptions(optionCallbacks,"global")
assert(control("Button","Safe Sell: OFF").shown,"global options were hidden on the Global Options page")
assert(control("CheckButton","Auto Sell").shown==false,"profile options leaked into Global Options")
control("Button","Safe Sell: OFF"):Click(); assert(globalOptionState.safeSell==true)
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
listsWindow.scripts.OnUpdate(listsWindow,0.1)
assert(queries==50,"next metadata tick did not advance the bounded queue")
listsWindow.scripts.OnUpdate(listsWindow,29.9)
assert(listsWindow.scripts.OnUpdate==nil,"uncached item metadata polling did not time out")

print("UI INTERACTION RESULT: options, list transport, metadata polling and report navigation passed")
