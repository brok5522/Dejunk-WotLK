assert(_VERSION=="Lua 5.1")
local H=dofile("tests/harness.lua")
local Addon=H.New():Load().addon
local function eq(a,b) assert(a==b,"expected "..tostring(b)..", got "..tostring(a)) end
local item={state="OCCUPIED",bag=0,slot=1,itemId=77,link="|Hitem:77:0|h[Junk]|h",count=2,
  locked=false,quest=false,refundable=false,inEquipmentSet=false,unitVendorPrice=5,lootable=true}
local slot=Addon.Copy(item)
local reads={}
function reads:ReadEquipmentSets() return {known=true,ids={}} end
function reads:ReadSlot() return Addon.Copy(slot) end
function reads:ReadBinding() return true end
local api={combat=false,dead=false,cursor=nil,MerchantFrame={shown=true},sale=0,repair=0,pickup=0,delete=0,loot=0}
function api.MerchantFrame:IsShown() return self.shown end
function api.InCombatLockdown() return api.combat end
function api.UnitIsDeadOrGhost() return api.dead end
function api.GetCursorInfo() if api.cursor then return "item",api.cursor end end
function api.GetTime() return 1 end
function api.GetMoney() return 100 end
function api.GetNetStats() return 0,0,100,100 end
function api.CanMerchantRepair() return true end
function api.GetRepairAllCost() return 20,true end
function api.UseContainerItem() api.sale=api.sale+1 end
function api.RepairAllItems() api.repair=api.repair+1 end
function api.PickupContainerItem() api.pickup=api.pickup+1; api.cursor=77; slot={state="EMPTY",bag=0,slot=1} end
function api.DeleteCursorItem() api.delete=api.delete+1; api.cursor=nil end
local revision=9
local tx=Addon.Transactions.New(api,reads,function() return revision end)
local function intent()
  local value=tx:ReadItem(0,1); value.settingsRevision=revision; value.sessionId="test"; return value
end

local token={sessionId="test",intent=intent()}
local ok=tx:AttemptSale(token); eq(ok,true); eq(api.sale,1)
api.cursor=999
ok=tx:AttemptSale({sessionId="test",intent=intent()}); eq(ok,false); eq(api.sale,1)
api.cursor=nil; api.combat=true
ok=tx:AttemptSale({sessionId="test",intent=intent()}); eq(ok,false); eq(api.sale,1)
api.combat=false
local repair=tx:ReadRepairContext("test",revision)
ok=tx:AttemptRepair(repair); eq(ok,true); eq(api.repair,1)
local originalCanRepair,originalRepairCost=api.CanMerchantRepair,api.GetRepairAllCost
api.CanMerchantRepair=function() return 1 end
api.GetRepairAllCost=function() return 20,1 end
eq(tx:ReadRepairContext("test",revision).canRepair,true)
api.CanMerchantRepair,api.GetRepairAllCost=originalCanRepair,originalRepairCost
local loot=intent(); ok=tx:UseLootableItem(loot); eq(ok,true); eq(api.sale,2)
local destroy=intent(); ok=tx:PickupContainerItem(destroy); eq(ok,true); eq(api.pickup,1)
ok=tx:MatchesPickedUpItem(destroy); eq(ok,true)
ok=tx:DeletePickedUpItem(destroy); eq(ok,true); eq(api.delete,1)
revision=revision+1
ok=tx:UseLootableItem(loot); eq(ok,false); eq(api.sale,2)
print("PASS: transaction adapter fake-API safety and action checks")
local alwaysLoaded=H.New():Load()
local runtime=alwaysLoaded.addon.Runtime.New(alwaysLoaded.api)
local adapter,reason=runtime:NewTransactionAdapter({},function() return 1 end)
assert(type(adapter)=="table"); eq(reason,nil)
print("PASS: transaction adapter is initialized by the always-loaded runtime")
local selectionWorld=H.New()
selectionWorld.api.StaticPopupDialogs={}
local shownPopup
selectionWorld.api.StaticPopup_Show=function(id) shownPopup=selectionWorld.api.StaticPopupDialogs[id] end
selectionWorld:Load():Ready()
local candidates={
  {itemId=1,name="Sale only",count=1,destroy={result="KEEP"}},
  {itemId=2,name="Locked candidate",count=1,locked=true,destroy={result="JUNK"}},
  {itemId=3,name="Destroy eligible",count=1,locked=false,destroy={result="JUNK"}}
}
selectionWorld.app.GetJunkItems=function() return {items=candidates} end
local selected=selectionWorld.app.runtime.itemActionHandlers.destroyNext()
assert(selected and shownPopup and shownPopup.text:find("Destroy eligible",1,true),
  "Destroy Next did not skip sale-only and locked rows")
shownPopup=nil; candidates={candidates[1],candidates[2]}
local empty,emptyReason=selectionWorld.app.runtime.itemActionHandlers.destroyNext()
assert(empty==false and emptyReason=="NO_JUNK_ITEMS" and shownPopup==nil)
assert(selectionWorld.mutations==0,"selection test mutated the fake inventory")
print("PASS: Destroy Next selects an eligible unlocked row without inventory mutations")

local saleWorld=H.New():Load():Ready()
local app=saleWorld.app
assert(app.store:SetGlobalOption("safeSell",true))
local candidates,bySlot={},{}
for id=1,35 do
  local sellable=id<=15
  local candidate={state="OCCUPIED",bag=0,slot=id,itemId=id,link="item:"..id,count=1,locked=false,
    sell={result=sellable and "JUNK" or "KEEP"},destroy={result="JUNK"}}
  candidates[#candidates+1]=candidate; bySlot[id]=candidate
end
app.GetJunkItems=function() return {items=candidates,sellable=15,destroyable=35} end
saleWorld.addon.Rules.Evaluate=function(item,action) return {result=item.sell.result,action=action} end
app.transactions.ReadItem=function(_,bag,slot) return saleWorld.addon.Copy(bySlot[slot]) end
app.transactions.Latency=function() return 0.01 end
local attempts={}
app.transactions.AttemptSale=function(_,token) attempts[#attempts+1]=token.intent.itemId; return true end
saleWorld:Fire("MERCHANT_SHOW")
assert(app.runtime.itemActionHandlers.startSelling())
local duplicate,duplicateReason=app.runtime.itemActionHandlers.startSelling()
assert(duplicate==false and duplicateReason=="BUSY","a second start restarted the running sale")
assert(app.runtime.itemActionsBusy,"runtime was not marked busy during a sale run")
for _=1,30 do saleWorld:Tick(0.1) end
assert(#attempts==12,"Safe Sell counted non-sale candidates or exceeded twelve sale attempts")
for _,id in ipairs(attempts) do assert(id<=15,"a destroy-only candidate reached the sale adapter") end
assert(not app.saleRun and not app.runtime.itemActionsBusy,"sale completion did not clear busy state")
assert(app.runtime.itemActionHandlers.startSelling())
saleWorld:Fire("MERCHANT_CLOSED")
saleWorld:Tick(0.2)
assert(#attempts==12 and not app.saleRun and not app.runtime.itemActionsBusy,"closing the merchant did not cancel the pending sale")
saleWorld:Fire("MERCHANT_SHOW")
assert(app.runtime.itemActionHandlers.startSelling())
assert(app.store:SetGlobalOption("safeSell",false))
saleWorld:Tick(0.2)
assert(#attempts==12 and not app.saleRun,"settings changes did not cancel a pending sale")
assert(app.store:SetGlobalOption("safeSell",true))
local failedDispatches=0
saleWorld:Tick(6) -- Previous successful dispatch mocks left slots unchanged: expire their confirmations.
app.transactions.AttemptSale=function() failedDispatches=failedDispatches+1; return false,"API_FAILED",true end
assert(app.runtime.itemActionHandlers.startSelling())
for _=1,30 do saleWorld:Tick(0.1) end
assert(failedDispatches==12 and not app.saleRun,"failed API dispatches escaped the Safe Sell cap")
assert(saleWorld.mutations==0,"sale-run fixtures touched the inventory mutation sentinels")
print("PASS: sale runs filter action eligibility, cap attempts, reject duplicate starts and cancel safely")

local confirmationWorld=H.New()
local popup
confirmationWorld.api.StaticPopupDialogs={}
confirmationWorld.api.StaticPopup_Show=function(id) popup=confirmationWorld.api.StaticPopupDialogs[id] end
confirmationWorld:Load():Ready()
local confirmationApp=confirmationWorld.app
local readAttempts=0
confirmationApp.transactions.ReadItem=function() readAttempts=readAttempts+1; return nil end
local target={itemId=777,name="Confirmation fixture",count=1,destroy={result="JUNK"}}
assert(confirmationApp.runtime.itemActionHandlers.destroyItem(target))
popup.OnCancel(); popup.OnAccept()
assert(readAttempts==0,"cancelled destroy confirmation remained executable")
assert(confirmationApp.runtime.itemActionHandlers.destroyItem(target))
assert(confirmationApp.store:SetGlobalOption("safeSell",true))
popup.OnAccept()
assert(readAttempts==0,"destroy confirmation did not expire after settings changed")
assert(confirmationApp.runtime.itemActionHandlers.destroyItem(target))
popup.OnAccept(); popup.OnAccept()
assert(readAttempts==1,"destroy confirmation was not single-use")
assert(confirmationWorld.mutations==0)
print("PASS: destroy confirmations expire on cancellation/settings changes and are single-use")

local repairWorld=H.New():Load():Ready()
assert(repairWorld.app.store:SetOption("autoRepair",true))
local repairs=0
repairWorld.app.transactions.ReadRepairContext=function() return {canRepair=true,cost=1,money=10} end
repairWorld.app.transactions.AttemptRepair=function() repairs=repairs+1; return true end
repairWorld:Fire("MERCHANT_SHOW"); repairWorld:Fire("MERCHANT_CLOSED"); repairWorld:Tick(0.2)
assert(repairs==0,"delayed repair survived the merchant closing")
repairWorld:Fire("MERCHANT_SHOW")
assert(repairWorld.app.store:SetOption("autoRepair",false))
repairWorld:Tick(0.2)
assert(repairs==0,"delayed repair survived disabling Auto Repair")
assert(repairWorld.app.store:SetOption("autoRepair",true))
repairWorld:Fire("MERCHANT_SHOW"); repairWorld:Tick(0.2)
assert(repairs==1 and repairWorld.mutations==0)
print("PASS: delayed auto repair follows the current merchant session and preference")

local observedWorld=H.New():Load();observedWorld:AddItem(0,1);observedWorld:Ready()
local observedApp=observedWorld.app
observedApp.transactions.AttemptSale=function() return true end -- dispatch is not proof of sale
observedWorld:Fire("MERCHANT_SHOW")
local function messageContains(fragment)
  for _,message in ipairs(observedWorld.messages) do if message:find(fragment,1,true) then return true end end
  return false
end
local function sellObserved()
  return observedApp.runtime.itemActionHandlers.sellItem(observedApp:ProbeSlot(0,1))
end
assert(sellObserved())
assert(not messageContains("Sold:"),"dispatch was reported as confirmed")
assert(not sellObserved(),"pending slot was dispatched twice")
observedWorld:Tick(5.1)
assert(messageContains("Sale could not be confirmed:"))
observedWorld.messages={}
assert(sellObserved());observedWorld:Fire("ITEM_UNLOCKED",0,1)
assert(messageContains("Failed to sell:"));observedWorld:Tick(6)
assert(not messageContains("Sale could not be confirmed:"),"failed sale retained its timeout")
observedWorld.messages={}
assert(sellObserved());observedWorld.slots["0:1"]=nil;observedWorld:Tick(0.2)
assert(messageContains("Sold:"));assert(not next(observedApp.pendingSales))
observedWorld:Tick(6);assert(not messageContains("Sale could not be confirmed:"))
observedWorld.messages={}
observedWorld:AddItem(0,1);observedWorld:Fire("BAG_UPDATE",0);observedWorld:Tick(0.2)
assert(observedApp.runtime.itemActionHandlers.startSelling());observedWorld:Tick(0.2)
observedWorld.slots["0:1"]=nil;observedWorld:Fire("BAG_UPDATE",0)
for _=1,5 do observedWorld:Tick(0.2) end
assert(messageContains("Items sold: 1 | Vendor value: 15 copper"),"confirmed run was not summarized")
assert(not observedApp.saleRun and not next(observedApp.pendingSales))
assert(observedWorld.mutations==0)
print("PASS: production sale observation distinguishes dispatch, timeout, unlock failure and disappearance")
