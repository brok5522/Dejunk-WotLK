local _, Addon = ...
local Seller = {}
Addon.SimulationSeller = Seller

local CAP = 12
local function itemAt(snapshot, bag, slot)
  return snapshot and snapshot.items and snapshot.items[bag .. ":" .. slot]
end
local function sameItem(a, b)
  return a and b and a.state == "OCCUPIED" and b.state == "OCCUPIED" and
    a.bag == b.bag and a.slot == b.slot and a.itemId == b.itemId and
    a.link == b.link and a.count == b.count and a.locked == false and b.locked == false
end

-- Deliberately simulation-only. Production runtime does not construct this service.
function Seller.New(adapter)
  if type(adapter) ~= "table" or adapter.simulation ~= true or
      type(adapter.AttemptSale) ~= "function" then return nil, "SIMULATION_ADAPTER_REQUIRED" end
  local service = { adapter=adapter, attempts={}, pending=nil, nextToken=0 }

  function service:Attempt(intent, snapshot, decision, context)
    context=context or {}
    if self.pending then return nil,"ACTION_PENDING" end
    if type(intent)~="table" or intent.action~="SELL" or type(decision)~="table" or
        decision.action~="SELL" or decision.result~="JUNK" then return nil,"NOT_ELIGIBLE" end
    if type(intent.bag)~="number" or intent.bag<0 or intent.bag>4 or intent.bag~=math.floor(intent.bag) or
        type(intent.slot)~="number" or intent.slot<1 or intent.slot>128 or intent.slot~=math.floor(intent.slot) then
      return nil,"INVALID_SLOT"
    end
    if context.merchantOpen~=true or type(context.sessionId)~="string" then return nil,"MERCHANT_UNAVAILABLE" end
    if context.inCombat==true or context.cursorEmpty~=true or context.safeContext~=true then return nil,"CONTEXT_UNSAFE" end
    if type(snapshot)~="table" or snapshot.valid~=true or snapshot.generation~=snapshot.currentGeneration or
        snapshot.generation~=intent.bagGeneration then return nil,"STALE_SNAPSHOT" end
    if context.settingsRevision~=intent.settingsRevision then return nil,"STALE_SETTINGS" end
    local item=itemAt(snapshot,intent.bag,intent.slot)
    if not sameItem(item,intent) then return nil,"STALE_ITEM" end
    if item.quest~=false or item.refundable~=false or item.inEquipmentSet~=false then return nil,"SAFETY_UNKNOWN" end
    if type(item.unitVendorPrice)~="number" or item.unitVendorPrice<=0 then return nil,"NO_VENDOR_VALUE" end
    local attempted=self.attempts[context.sessionId] or 0
    if attempted>=CAP then return nil,"SESSION_CAP" end

    self.attempts[context.sessionId]=attempted+1 -- count before adapter call, even if it fails
    self.nextToken=self.nextToken+1
    local token={id=self.nextToken,sessionId=context.sessionId,intent=Addon.Copy(intent),
      expectedValue=item.unitVendorPrice*item.count,attemptNumber=attempted+1}
    self.pending=token
    local ok,err=pcall(self.adapter.AttemptSale,self.adapter,Addon.Copy(token))
    if not ok then token.adapterError=tostring(err) end
    return {status="ATTEMPTED",token=token.id,attemptNumber=token.attemptNumber,
      adapterError=token.adapterError}
  end

  function service:Observe(tokenId,evidence)
    local token=self.pending
    if not token or token.id~=tokenId then return nil,"UNKNOWN_TOKEN" end
    self.pending=nil
    evidence=evidence or {}
    if evidence.sessionId~=token.sessionId then return {status="AMBIGUOUS",reason="SESSION_CHANGED"} end
    if evidence.sameItemAtSlot==true then return {status="FAILED",reason="ITEM_UNCHANGED"} end
    if evidence.sameItemAtSlot==false and evidence.moneyDelta==token.expectedValue and token.expectedValue>0 then
      return {status="OBSERVED",reason="MATCHED_SLOT_AND_VALUE"}
    end
    return {status="AMBIGUOUS",reason="INSUFFICIENT_EVIDENCE"}
  end

  function service:Cancel(reason)
    if not self.pending then return false end
    self.pending=nil
    return true,reason or "CANCELLED"
  end
  function service:GetAttemptCount(sessionId) return self.attempts[sessionId] or 0 end
  return service
end

return Seller
