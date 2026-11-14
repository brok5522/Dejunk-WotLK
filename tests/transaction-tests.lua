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
