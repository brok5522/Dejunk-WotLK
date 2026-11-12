assert(_VERSION=="Lua 5.1")
local H=dofile("tests/harness.lua")
local w=H.New():Load(); local Addon=w.addon
local passed=0
local function eq(a,b) assert(a==b,"expected "..tostring(b)..", got "..tostring(a)) end
local function test(fn) fn(); passed=passed+1 end
local function fixture(overrides)
  local item={state="OCCUPIED",bag=0,slot=1,itemId=77,link="|Hitem:77:0:0|h[Junk]|h",count=3,
    locked=false,quest=false,refundable=false,inEquipmentSet=false,quality=0,equipLoc="",bound="unknown"}
  for k,v in pairs(overrides or {}) do item[k]=v end
  local snapshot={valid=true,generation=8,currentGeneration=8,items={["0:1"]=item}}
  local intent={action="DESTROY",state="OCCUPIED",bag=0,slot=1,itemId=item.itemId,link=item.link,
    count=item.count,locked=false,bagGeneration=8,settingsRevision=12}
  local decision={action="DESTROY",result="JUNK",reasonCode="QUALITY"}
  local context={confirmed=false,inCombat=false,cursorEmpty=true,safeContext=true,settingsRevision=12,now=100}
  return item,snapshot,intent,decision,context
end
local function mock()
  local adapter={simulation=true,pickups=0,deletes=0,cursor=nil}
  function adapter:SimulatePickup(item) self.pickups=self.pickups+1; self.cursor=Addon.Copy(item) end
  function adapter:ReadSimulatedCursor() return self.cursor and Addon.Copy(self.cursor) end
  function adapter:SimulateDelete() self.deletes=self.deletes+1; self.cursor=nil end
  return adapter
end
local function request(service,item,snapshot,intent,decision,context)
  return service:Request(intent,snapshot,decision,context)
end

test(function()
  local adapter=mock(); adapter.simulation=nil
  local service,reason=Addon.SimulationDestroyer.New(adapter); eq(service,nil); eq(reason,"SIMULATION_ADAPTER_REQUIRED")
end)
test(function()
  local item,snapshot,intent,decision,context=fixture(); local adapter=mock()
  local service=assert(Addon.SimulationDestroyer.New(adapter))
  local popup=assert(request(service,item,snapshot,intent,decision,context))
  eq(popup.status,"CONFIRMATION_REQUIRED"); eq(adapter.pickups,0); eq(adapter.deletes,0)
  local duplicate,reason=request(service,item,snapshot,intent,decision,context)
  eq(duplicate,nil); eq(reason,"CONFIRMATION_PENDING")
  context.confirmed=true
  local output=assert(service:Confirm(popup.token,snapshot,decision,context))
  eq(output.status,"ATTEMPTED"); eq(adapter.pickups,1); eq(adapter.deletes,1)
  local repeated,reason=service:Confirm(popup.token,snapshot,decision,context)
  eq(repeated,nil); eq(reason,"UNKNOWN_OR_USED_TOKEN"); eq(adapter.deletes,1)
end)
test(function()
  local item,snapshot,intent,decision,context=fixture(); local adapter=mock()
  local service=assert(Addon.SimulationDestroyer.New(adapter)); local popup=assert(request(service,item,snapshot,intent,decision,context))
  context.confirmed=true; snapshot.items["0:1"].link="|Hitem:77:1|h[Changed]|h"
  local result=assert(service:Confirm(popup.token,snapshot,decision,context))
  eq(result.status,"CANCELLED"); eq(result.reason,"STALE_ITEM"); eq(adapter.pickups,0)
end)
test(function()
  local item,snapshot,intent,decision,context=fixture(); local service=assert(Addon.SimulationDestroyer.New(mock()))
  local _,reason=request(service,item,snapshot,intent,decision,{inCombat=false,cursorEmpty=false,safeContext=true,settingsRevision=12})
  eq(reason,"CONTEXT_UNSAFE")
  context.cursorEmpty=true; snapshot.generation=9
  _,reason=request(service,item,snapshot,intent,decision,context); eq(reason,"STALE_SNAPSHOT")
end)
test(function()
  local item,snapshot,intent,decision,context=fixture(); local adapter=mock()
  local service=assert(Addon.SimulationDestroyer.New(adapter)); local popup=assert(request(service,item,snapshot,intent,decision,context))
  context.confirmed=true; context.now=131
  local result=assert(service:Confirm(popup.token,snapshot,decision,context))
  eq(result.status,"CANCELLED"); eq(result.reason,"INTENT_EXPIRED"); eq(adapter.pickups,0)
end)
test(function()
  local item,snapshot,intent,decision,context=fixture(); local adapter=mock()
  local service=assert(Addon.SimulationDestroyer.New(adapter)); local popup=assert(request(service,item,snapshot,intent,decision,context))
  context.confirmed=true; snapshot.items["0:1"].count=2
  local result=assert(service:Confirm(popup.token,snapshot,decision,context))
  eq(result.status,"CANCELLED"); eq(result.reason,"STALE_ITEM"); eq(adapter.pickups,0)
end)
test(function()
  local item,snapshot,intent,decision,context=fixture(); local adapter=mock()
  adapter.SimulatePickup=function(self,expected) self.pickups=self.pickups+1; self.cursor=Addon.Copy(expected); self.cursor.link="|Hitem:77:2|h[Unexpected]|h" end
  local service=assert(Addon.SimulationDestroyer.New(adapter)); local popup=assert(request(service,item,snapshot,intent,decision,context))
  context.confirmed=true; local result=assert(service:Confirm(popup.token,snapshot,decision,context))
  eq(result.status,"AMBIGUOUS"); eq(result.reason,"CURSOR_IDENTITY_MISMATCH")
  eq(adapter.deletes,0); eq(adapter.cursor.link,"|Hitem:77:2|h[Unexpected]|h")
end)
test(function()
  local item,snapshot,intent,decision,context=fixture(); local adapter=mock()
  adapter.SimulatePickup=function(self,expected) self.cursor=Addon.Copy(expected); context.inCombat=true end
  local service=assert(Addon.SimulationDestroyer.New(adapter)); local popup=assert(request(service,item,snapshot,intent,decision,context))
  context.confirmed=true; local result=assert(service:Confirm(popup.token,snapshot,decision,context))
  eq(result.status,"AMBIGUOUS"); eq(result.reason,"CONTEXT_CHANGED_AFTER_PICKUP"); eq(adapter.deletes,0)
end)
test(function()
  local item,snapshot,intent,decision,context=fixture(); local service=assert(Addon.SimulationDestroyer.New(mock()))
  item.quality=5; local _,reason=request(service,item,snapshot,intent,decision,context); eq(reason,"SAFETY_PROTECTED")
  item.quality=0; item.equipLoc="INVTYPE_HEAD"; item.bound="unknown"
  _,reason=request(service,item,snapshot,intent,decision,context); eq(reason,"SAFETY_PROTECTED")
  item.equipLoc=""; item.inEquipmentSet="unknown"
  _,reason=request(service,item,snapshot,intent,decision,context); eq(reason,"SAFETY_PROTECTED")
end)
test(function()
  local item,snapshot,intent,decision,context=fixture(); local adapter=mock()
  local service=assert(Addon.SimulationDestroyer.New(adapter)); local popup=assert(request(service,item,snapshot,intent,decision,context))
  context.confirmed=true; context.settingsRevision=13
  local result=assert(service:Confirm(popup.token,snapshot,decision,context))
  eq(result.status,"CANCELLED"); eq(result.reason,"CONTEXT_CHANGED"); eq(adapter.pickups,0)
end)
test(function()
  local item,snapshot,intent,decision,context=fixture(); local adapter=mock()
  local service=assert(Addon.SimulationDestroyer.New(adapter)); local popup=assert(request(service,item,snapshot,intent,decision,context))
  assert(service:Cancel(popup.token)); eq(service:Confirm(popup.token,snapshot,decision,context),nil)
  eq(adapter.pickups,0); eq(adapter.deletes,0)
end)
print("DESTROYER RESULT: "..passed.." passed")
