local _, Addon = ...
local Destroyer = {}
Addon.SimulationDestroyer = Destroyer

local function finite(value)
  return type(value)=="number" and value==value and value<math.huge and value>-math.huge
end
local function sameItem(a,b)
  return type(a)=="table" and type(b)=="table" and a.state=="OCCUPIED" and
    a.bag==b.bag and a.slot==b.slot and a.itemId==b.itemId and a.link==b.link and
    a.count==b.count and a.locked==false
end
local function safeItem(item)
  if not item then return false end
  if item.quality==5 or item.quality==7 then return false end
  return true
end
local function contextSafe(context, session)
  return type(context)=="table" and context.confirmed==true and context.inCombat==false and
    context.cursorEmpty==true and context.safeContext==true and
      context.settingsRevision==session.settingsRevision and finite(context.now) and
      context.now<=session.expiresAt
end

-- Simulation only. The addon runtime never creates this service or a live adapter.
function Destroyer.New(adapter)
  if type(adapter)~="table" or adapter.simulation~=true or
      type(adapter.SimulatePickup)~="function" or type(adapter.ReadSimulatedCursor)~="function" or
      type(adapter.SimulateDelete)~="function" then return nil,"SIMULATION_ADAPTER_REQUIRED" end
  local service={adapter=adapter,tokens={},nextToken=0}

  function service:Request(intent,snapshot,decision,context)
    if next(self.tokens) then return nil,"CONFIRMATION_PENDING" end
    if type(intent)~="table" or intent.action~="DESTROY" or type(decision)~="table" or
        decision.action~="DESTROY" or decision.result~="JUNK" then return nil,"NOT_ELIGIBLE" end
    if type(intent.bag)~="number" or intent.bag<0 or intent.bag>4 or intent.bag~=math.floor(intent.bag) or
        type(intent.slot)~="number" or intent.slot<1 or intent.slot>128 or intent.slot~=math.floor(intent.slot) then
      return nil,"INVALID_SLOT"
    end
    if type(context)~="table" or context.inCombat~=false or context.cursorEmpty~=true or
        context.safeContext~=true or not finite(context.now) then return nil,"CONTEXT_UNSAFE" end
    if type(context.settingsRevision)~="number" or type(intent.settingsRevision)~="number" or
        context.settingsRevision~=intent.settingsRevision then return nil,"STALE_SETTINGS" end
    if type(snapshot)~="table" or snapshot.valid~=true or snapshot.generation~=snapshot.currentGeneration or
        snapshot.generation~=intent.bagGeneration then return nil,"STALE_SNAPSHOT" end
    local item=snapshot.items and snapshot.items[intent.bag..":"..intent.slot]
    if not sameItem(item,intent) then return nil,"STALE_ITEM" end
    if not safeItem(item) then return nil,"SAFETY_PROTECTED" end
    self.nextToken=self.nextToken+1
    local id=self.nextToken
    self.tokens[id]={item=Addon.Copy(item),intent=Addon.Copy(intent),settingsRevision=context.settingsRevision,
      bagGeneration=snapshot.generation,expiresAt=context.now+30,consumed=false}
    return {status="CONFIRMATION_REQUIRED",token=id,itemId=item.itemId,count=item.count,link=item.link,expiresAt=context.now+30}
  end

  function service:Confirm(tokenId,snapshot,decision,context)
    local token=self.tokens[tokenId]
    if not token or token.consumed then return nil,"UNKNOWN_OR_USED_TOKEN" end
    token.consumed=true
    self.tokens[tokenId]=nil -- single-use before any adapter call
    if type(decision)~="table" or decision.action~="DESTROY" or decision.result~="JUNK" then
      return {status="CANCELLED",reason="NO_LONGER_ELIGIBLE"}
    end
    if type(context)=="table" and finite(context.now) and context.now>token.expiresAt then
      return {status="CANCELLED",reason="INTENT_EXPIRED"}
    end
    if not contextSafe(context,token) then return {status="CANCELLED",reason="CONTEXT_CHANGED"} end
    if type(snapshot)~="table" or snapshot.valid~=true or snapshot.generation~=snapshot.currentGeneration or
        snapshot.generation~=token.bagGeneration then return {status="CANCELLED",reason="STALE_SNAPSHOT"} end
    local live=snapshot.items and snapshot.items[token.intent.bag..":"..token.intent.slot]
    if not sameItem(live,token.item) or not safeItem(live) then return {status="CANCELLED",reason="STALE_ITEM"} end

    local ok,err=pcall(self.adapter.SimulatePickup,self.adapter,Addon.Copy(token.item))
    if not ok then return {status="AMBIGUOUS",reason="PICKUP_ERROR",detail=tostring(err)} end
    local cursorOk,cursor=pcall(self.adapter.ReadSimulatedCursor,self.adapter)
    if not cursorOk then return {status="AMBIGUOUS",reason="CURSOR_READ_ERROR"} end
    if not sameItem(cursor,token.item) then
      -- Unexpected cursor content is left untouched for the user.
      return {status="AMBIGUOUS",reason="CURSOR_IDENTITY_MISMATCH"}
    end
    if context.inCombat~=false or context.safeContext~=true or context.settingsRevision~=token.settingsRevision or
        not finite(context.now) or context.now>token.expiresAt then
      return {status="AMBIGUOUS",reason="CONTEXT_CHANGED_AFTER_PICKUP"}
    end
    local deleteOk,deleteErr=pcall(self.adapter.SimulateDelete,self.adapter,Addon.Copy(cursor))
    if not deleteOk then return {status="AMBIGUOUS",reason="DELETE_ERROR",detail=tostring(deleteErr)} end
    return {status="ATTEMPTED",reason="SIMULATED_DELETE_CALL"}
  end

  function service:Cancel(tokenId)
    if not self.tokens[tokenId] then return false end
    self.tokens[tokenId]=nil
    return true
  end
  return service
end

return Destroyer
