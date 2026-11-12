assert(_VERSION=="Lua 5.1")
local H=dofile("tests/harness.lua")
local world=H.New():Load()
local Addon=world.addon
local uiFrames={}
local ui={UIParent={}}
setmetatable(ui,{__index=world.api})

local function object(kind,name,parent,template)
  local frame={kind=kind,name=name,parent=parent,template=template,scripts={},children={},enabled=true,text=""}
  function frame:SetWidth(value) self.width=value end
  function frame:SetHeight(value) self.height=value end
  function frame:SetPoint(...) self.point={...} end
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
  function frame:SetText(value)
    self.text=value
    if self.kind=="EditBox" and self.scripts.OnTextChanged then self.scripts.OnTextChanged(self) end
  end
  function frame:GetText() return self.text end
  function frame:GetWidth() return self.width end
  function frame:Enable() self.enabled=true end
  function frame:Disable() self.enabled=false end
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
  function frame:Click()
    assert(self.enabled~=false,"clicked disabled control")
    assert(self.scripts.OnClick,"control has no click handler")
    self.scripts.OnClick(self)
  end
  uiFrames[#uiFrames+1]=frame
  return frame
end
ui.CreateFrame=function(kind,name,parent,template) return object(kind,name,parent,template) end

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
runtime:ShowLists(listCallbacks)
assert(namedFrame("DejunkWotLKLists"),"lists window did not use the Waffle window factory")
local listFrame
for _,frame in ipairs(uiFrames) do if frame.kind=="Frame" and frame.width==720 then listFrame=frame end end
assert(listFrame and listFrame.shown)
control("Button","Export"):Click()
local report=uiFrames[#uiFrames]
while report and report.name~="DejunkWotLKReadOnlyReport" do report=report.parent end
assert(report and report.shown and listFrame.shown==false)
assert(namedFrame("DejunkWotLKReadOnlyReport"),"report window did not use the Waffle window factory")
local exported=lastControl("EditBox","6948")
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
assert(listStore:ExportList("global","inclusions")=="123\n456\n6948")

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
assert(namedFrame("DejunkWotLKProfiles"),"profiles window did not use the Waffle window factory")
runtime:ShowOptions({options=function() return {quality={}} end})
assert(namedFrame("DejunkWotLKOptions"),"options window did not use the Waffle window factory")

print("UI INTERACTION RESULT: rules, list import/export and report return flows passed")
