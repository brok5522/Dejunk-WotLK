local _, Addon = ...
local Repair = {}
Addon.SimulationRepair = Repair

function Repair.New(adapter)
  if type(adapter)~="table" or adapter.simulation~=true or
      type(adapter.AttemptRepair)~="function" then return nil,"SIMULATION_ADAPTER_REQUIRED" end
  local service={adapter=adapter,repairedSessions={}}
  function service:Attempt(context)
    context=context or {}
    if context.merchantOpen~=true or type(context.sessionId)~="string" then return nil,"MERCHANT_UNAVAILABLE" end
    if context.inCombat==true or context.safeContext~=true then return nil,"CONTEXT_UNSAFE" end
    if self.repairedSessions[context.sessionId] then return nil,"ALREADY_ATTEMPTED" end
    if context.canRepair~=true then return nil,"REPAIR_UNAVAILABLE" end
    if type(context.cost)~="number" or context.cost<=0 then return nil,"INVALID_REPAIR_COST" end
    if type(context.money)~="number" or context.money<context.cost then return nil,"INSUFFICIENT_FUNDS" end
    self.repairedSessions[context.sessionId]=true
    local ok,err=pcall(self.adapter.AttemptRepair,self.adapter,{sessionId=context.sessionId,cost=context.cost})
    return {status="ATTEMPTED",cost=context.cost,adapterError=not ok and tostring(err) or nil}
  end
  return service
end

return Repair
