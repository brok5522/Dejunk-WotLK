assert(_VERSION=="Lua 5.1")
local H=dofile("tests/harness.lua")
local a=H.New():Load().addon
local s=a.Store.Initialize({schemaVersion=2,profiles={default={options={quality=true},exclusions={[123]=true,["456"]=true,invalid=true}}}},"review")
assert(s:GetActiveProfile().exclusions[123] and s:GetActiveProfile().exclusions[456])
assert(s:Serialize().recovery.profiles.default.exclusions.invalid)
local reloaded=a.Store.Initialize(s:Serialize(),"review")
assert(reloaded:Serialize().recovery and reloaded:GetActiveProfile().exclusions[123])
assert(s:EditList("profile","exclusions",456,false))
assert(s:EditList("profile","inclusions",123,true))
assert(not s:GetActiveProfile().exclusions[123])
assert(s:EditList("global","exclusions",123,true))
assert(s:GetActiveProfile().inclusions[123],"cross-scope membership was removed")
assert(s:CommitImport(assert(s:ImportPreview("global","inclusions","123,789"))))
assert(not s:GetState().global.exclusions[123] and s:GetState().global.inclusions[789])
for _,key in ipairs({"excludeEquipmentSets","excludeUnboundEquipment"}) do
  assert(s:SetOption(key,{enabled=true,scope="SELL",qualities={poor=true,common=false}}))
  assert(s:SetOption(key,false)); assert(s:SetOption(key,true))
  assert(s:GetActiveProfile().options[key].scope=="SELL")
end
assert(s:SetOption("autoSell",true));assert(s:ResetProfile("default"))
assert(not s:GetActiveProfile().autoSell and not next(s:GetActiveProfile().inclusions))
local schemaWorld=H.New():Load();schemaWorld.api.DejunkWotLKDB={schemaVersion="2"};schemaWorld:Ready()
assert(schemaWorld.app.state=="READY" and schemaWorld.app.store:Serialize().recovery.schemaVersion=="2")
local w=H.New():Load();w:AddItem(0,1);w.tooltipLines={w.api.ITEM_SOULBOUND};w:Ready()
assert(w.app.store:SetOption("excludeUnboundEquipment",{enabled=true,scope="BOTH",qualities={poor=true}}))
w:Tick(0.2)
assert(#w.app:GetJunkItems().items==1 and w.app:GetSlotDecisions(0,1).result=="JUNK")
local visible,shows=false,0;local rt=w.app.runtime
rt.IsJunkFrameVisible=function() return visible end
rt.ShowJunkFrame=function() visible=true;shows=shows+1 end
rt.HideJunkFrame=function() visible=false end
assert(w.app.store:SetGlobalOption("autoJunkFrame",true));w:Fire("MERCHANT_SHOW")
assert(shows==1);rt:HideJunkFrame();w:Fire("BAG_UPDATE",0);w:Tick(0.2);assert(shows==1 and not visible)
w:Fire("MERCHANT_CLOSED");w:Fire("MERCHANT_SHOW");assert(shows==2)
local revision=1
local item={state="OCCUPIED",metadata="known",bag=0,slot=1,itemId=123,link="item:123",count=1,quality=1,
  locked=false,refundable=false,quest=false,inEquipmentSet=false,unitVendorPrice=5,settingsRevision=1,equipLoc="INVTYPE_CLOAK",classId=4,subclassId=1}
local slot=a.Copy(item)
local api={combat=false,dead=false,calls=0,MerchantFrame={IsShown=function() return true end}}
api.InCombatLockdown=function() return api.combat end
api.UnitIsDeadOrGhost=function() return api.dead end
api.GetCursorInfo=function() if slot.state=="EMPTY" then return "item",123 end end
api.GetTime=function() return 1 end
api.UseContainerItem=function() api.calls=api.calls+1 end
api.DeleteCursorItem=function() error("must not delete stale intent") end
local reads={ReadEquipmentSets=function() return {} end,ReadSlot=function() return a.Copy(slot) end,ReadBinding=function() return true end}
local tx=a.Transactions.New(api,reads,function() return revision end)
api.combat=1;assert(not tx:AttemptSale({intent=item}));api.combat=false
api.dead=1;assert(not tx:AttemptSale({intent=item}));api.dead=false;assert(api.calls==0)
for _,field in ipairs({"quest","inEquipmentSet"}) do
  slot[field]=true;local intent=tx:ReadItem(0,1)
  assert(tx:AttemptSale({intent=intent}));slot[field]=false
end
assert(api.calls==2)
slot={state="EMPTY"};revision=2
assert(not tx:MatchesPickedUpItem(item));assert(not tx:DeletePickedUpItem(item))
local result=a.Rules.Evaluate(item,"SELL",{profile={options={includeByEquipmentType={enabled=true,scope="BOTH",qualities={common=true},armor={[1]=true},weapons={}}}}})
assert(result.result=="KEEP","cloth type inclusion matched cloak")
local levelSettings={profile={options={includeBelowItemLevel={enabled=true,scope="BOTH",value=20,qualities={common=true}}}}}
item.itemLevel=10;item.classId=2;item.subclassId=20;item.equipLoc="INVTYPE_2HWEAPON"
assert(a.Rules.Evaluate(item,"SELL",levelSettings).result=="KEEP")
item.classId=4;item.subclassId=0;item.equipLoc="INVTYPE_CHEST"
assert(a.Rules.Evaluate(item,"SELL",levelSettings).result=="KEEP")
item.equipLoc="INVTYPE_FINGER"
assert(a.Rules.Evaluate(item,"SELL",levelSettings).result=="JUNK")
assert(w.mutations==0 and schemaWorld.mutations==0)
print("REVIEW REGRESSIONS: saved data, list semantics, scope, binding, lifecycle and transaction guards passed")

-- The legacy auction order is neither the class enum nor a contiguous subclass enum.
local c,sc=a.Legacy.ResolveItemType("Weapon","Staves"); assert(c==2 and sc==10)
c,sc=a.Legacy.ResolveItemType("Armor","Shields"); assert(c==4 and sc==6)
c,sc=a.Legacy.ResolveItemType("Weapon","Fishing Poles"); assert(c==2 and sc==20)
assert(a.Legacy.ResolveItemType("Unrecognized localized class","Cloth")==nil)
local reordered={GetAuctionItemClasses=function() return "Quest","Armor","Weapon" end,
  GetAuctionItemSubClasses=function(i) if i==2 then return "Shields","Cloth" else return "Staves","Fishing Poles" end end}
local armor=a.Legacy.GetEquipmentTypes(reordered,4); assert(armor[1].id==6 and armor[2].id==1)
local weapons=a.Legacy.GetEquipmentTypes(reordered,2); assert(#weapons==1 and weapons[1].id==10)

local redraws=0
w.app.runtime.UpdateBagIcons=function() redraws=redraws+1 end
assert(w.app.store:EditList("global","exclusions",987,true))
assert(redraws>0,"list changes did not refresh bag overlay settings")
