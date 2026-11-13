assert(_VERSION=="Lua 5.1")
local H=dofile("tests/harness.lua")
local w=H.New():Load()
local Addon=w.addon
local passed=0
local function eq(a,b) assert(a==b,"expected "..tostring(b)..", got "..tostring(a)) end
local function test(fn) fn(); passed=passed+1 end
local function fixture()
  local item={state="OCCUPIED",bag=0,slot=1,itemId=123,link="|Hitem:123:0|h[Test]|h",count=2,
    locked=false,quest=false,refundable=false,inEquipmentSet=false,unitVendorPrice=5}
  local snapshot={valid=true,generation=4,currentGeneration=4,items={["0:1"]=item}}
  local intent={action="SELL",state="OCCUPIED",bag=0,slot=1,itemId=123,link=item.link,count=2,
    locked=false,bagGeneration=4,settingsRevision=9}
  local decision={action="SELL",result="JUNK",reasonCode="QUALITY"}
  local context={merchantOpen=true,sessionId="merchant-1",inCombat=false,cursorEmpty=true,
    safeContext=true,settingsRevision=9}
  return item,snapshot,intent,decision,context
end

test(function()
  local service,reason=Addon.SimulationSeller.New({AttemptSale=function() end})
  eq(service,nil); eq(reason,"SIMULATION_ADAPTER_REQUIRED")
  service,reason=Addon.SimulationRepair.New({AttemptRepair=function() end})
  eq(service,nil); eq(reason,"SIMULATION_ADAPTER_REQUIRED")
end)
test(function()
  local calls=0; local adapter={simulation=true,AttemptSale=function() calls=calls+1 end}
  local service=assert(Addon.SimulationSeller.New(adapter)); local _,snapshot,intent,decision,context=fixture()
  local output=assert(service:Attempt(intent,snapshot,decision,context))
  eq(output.status,"ATTEMPTED"); eq(calls,1); eq(service:GetAttemptCount(context.sessionId),1)
  eq(service:Observe(output.token,{sessionId=context.sessionId,sameItemAtSlot=true,moneyDelta=0}).status,"FAILED")
end)
test(function()
  local calls=0; local service=assert(Addon.SimulationSeller.New({simulation=true,AttemptSale=function() calls=calls+1 end}))
  local _,snapshot,intent,decision,context=fixture()
  context.safeSell=true
  context.safeSell=true
  for i=1,12 do
    local output=assert(service:Attempt(intent,snapshot,decision,context))
    eq(service:GetAttemptCount(context.sessionId),i)
    local observed=service:Observe(output.token,{sessionId=context.sessionId,sameItemAtSlot=false,moneyDelta=10})
    eq(observed.status,"OBSERVED")
  end
  local output,reason=service:Attempt(intent,snapshot,decision,context)
  eq(output,nil); eq(reason,"SESSION_CAP"); eq(calls,12)
end)
test(function()
  local service=assert(Addon.SimulationSeller.New({simulation=true,AttemptSale=function() end}))
  local _,snapshot,intent,decision,context=fixture()
  for i=1,13 do
    local output=assert(service:Attempt(intent,snapshot,decision,context))
    service:Observe(output.token,{sessionId=context.sessionId,sameItemAtSlot=false,moneyDelta=10})
  end
  eq(service:GetAttemptCount(context.sessionId),13)
end)
test(function()
  local calls=0; local service=assert(Addon.SimulationSeller.New({simulation=true,AttemptSale=function() calls=calls+1 end}))
  local _,snapshot,intent,decision,context=fixture()
  context.merchantOpen=false; local _,reason=service:Attempt(intent,snapshot,decision,context); eq(reason,"MERCHANT_UNAVAILABLE")
  context.merchantOpen=true; context.inCombat=true; _,reason=service:Attempt(intent,snapshot,decision,context); eq(reason,"CONTEXT_UNSAFE")
  context.inCombat=false; context.cursorEmpty=false; _,reason=service:Attempt(intent,snapshot,decision,context); eq(reason,"CONTEXT_UNSAFE")
  context.cursorEmpty=true; snapshot.generation=5; _,reason=service:Attempt(intent,snapshot,decision,context); eq(reason,"STALE_SNAPSHOT")
  snapshot.generation=4; context.settingsRevision=10; _,reason=service:Attempt(intent,snapshot,decision,context); eq(reason,"STALE_SETTINGS")
  context.settingsRevision=9; intent.link="different"; _,reason=service:Attempt(intent,snapshot,decision,context); eq(reason,"STALE_ITEM")
  eq(calls,0)
end)
test(function()
  local calls=0; local service=assert(Addon.SimulationSeller.New({simulation=true,AttemptSale=function() calls=calls+1 end}))
  local _,snapshot,intent,decision,context=fixture()
  local _,reason=service:Attempt({},snapshot,decision,context); eq(reason,"NOT_ELIGIBLE")
  intent.bag=5; _,reason=service:Attempt(intent,snapshot,decision,context); eq(reason,"INVALID_SLOT")
  intent.bag=0; _,reason=service:Attempt(intent,snapshot,false,context); eq(reason,"NOT_ELIGIBLE")
  eq(calls,0)
end)
test(function()
  local service=assert(Addon.SimulationSeller.New({simulation=true,AttemptSale=function() error("mock failure") end}))
  local _,snapshot,intent,decision,context=fixture(); local output=assert(service:Attempt(intent,snapshot,decision,context))
  assert(output.adapterError); eq(service:GetAttemptCount(context.sessionId),1)
  eq(service:Observe(output.token,{sessionId=context.sessionId,sameItemAtSlot=false,moneyDelta=0}).status,"AMBIGUOUS")
  local cancelled=assert(service:Attempt(intent,snapshot,decision,context)); assert(service:Cancel("MERCHANT_CLOSED"))
  local result,reason=service:Observe(cancelled.token,{sessionId=context.sessionId,sameItemAtSlot=false,moneyDelta=10})
  eq(result,nil); eq(reason,"UNKNOWN_TOKEN")
end)
test(function()
  local calls=0; local service=assert(Addon.SimulationRepair.New({simulation=true,AttemptRepair=function() calls=calls+1 end}))
  local context={merchantOpen=true,sessionId="repair-1",inCombat=false,safeContext=true,canRepair=true,cost=100,money=100}
  eq(assert(service:Attempt(context)).status,"ATTEMPTED"); eq(calls,1)
  local result,reason=service:Attempt(context); eq(result,nil); eq(reason,"ALREADY_ATTEMPTED")
  context.sessionId="repair-2"; context.money=99; result,reason=service:Attempt(context)
  eq(result,nil); eq(reason,"INSUFFICIENT_FUNDS"); eq(calls,1)
end)
print("SERVICE RESULT: "..passed.." passed")
