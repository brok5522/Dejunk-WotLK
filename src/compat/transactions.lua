local _, Addon = ...
local Transactions = {}
Addon.Transactions = Transactions

local function call(api,name,...)
  local fn=api and api[name]
  if type(fn)~="function" then return false,"API_UNAVAILABLE:"..name end
  local result={pcall(fn,...)}
  if not result[1] then return false,"API_ERROR:"..name end
  table.remove(result,1)
  return true,unpack(result)
end

local function shown(frame)
  return frame and type(frame.IsShown)=="function" and frame:IsShown() or false
end

local function sameItem(current,expected)
  return type(current)=="table" and type(expected)=="table" and current.state=="OCCUPIED" and
    current.bag==expected.bag and current.slot==expected.slot and current.itemId==expected.itemId and
    current.link==expected.link and current.count==expected.count and current.locked==false
end

local function safeNonCursorContext(api)
  local ok,combat=call(api,"InCombatLockdown")
  if not ok or combat==true then return false,"IN_COMBAT" end
  local deadOk,dead=call(api,"UnitIsDeadOrGhost","player")
  if not deadOk or dead==true then return false,"PLAYER_UNAVAILABLE" end
  for _,name in ipairs({"TradeFrame","MailFrame","AuctionFrame","BankFrame","GuildBankFrame"}) do
    local frame=api[name]
    if frame and shown(frame) then return false,"CONFLICTING_FRAME:"..name end
  end
  return true
end

function Transactions.New(api,readAdapter,getSettingsRevision)
  api=api or _G
  local adapter={live=true,api=api,readAdapter=readAdapter,getSettingsRevision=getSettingsRevision}

  function adapter:Capabilities()
    local result={}
    for _,name in ipairs({"UseContainerItem","PickupContainerItem","DeleteCursorItem","RepairAllItems",
      "GetCursorInfo","GetMoney","GetTime","InCombatLockdown","UnitIsDeadOrGhost"}) do
      result[name]=type(api[name])=="function"
    end
    return result
  end

  function adapter:ReadItem(bag,slot)
    if not self.readAdapter then return nil,"READ_ADAPTER_UNAVAILABLE" end
    local sets=self.readAdapter:ReadEquipmentSets()
    local item=self.readAdapter:ReadSlot(bag,slot,sets)
    if item and item.state=="OCCUPIED" then item.bound=self.readAdapter:ReadBinding(bag,slot) end
    return item
  end

  function adapter:ReadContext(sessionId,settingsRevision)
    local safe,reason=safeNonCursorContext(api)
    local cursorOk,cursorType=call(api,"GetCursorInfo")
    local cursorEmpty=cursorOk and cursorType==nil
    local timeOk,now=call(api,"GetTime")
    local merchantOpen=shown(api.MerchantFrame)
    local currentRevision=type(getSettingsRevision)=="function" and getSettingsRevision() or nil
    local combatOk,inCombat=call(api,"InCombatLockdown")
    return {
      sessionId=sessionId,settingsRevision=settingsRevision,
      now=timeOk and type(now)=="number" and now or 0,
      inCombat=not combatOk or inCombat==true,
      cursorEmpty=cursorEmpty,safeContext=safe,contextReason=reason,
      merchantOpen=merchantOpen,currentSettingsRevision=currentRevision
    }
  end

  function adapter:ReadRepairContext(sessionId,settingsRevision)
    local context=self:ReadContext(sessionId,settingsRevision)
    local canOk,canRepair=call(api,"CanMerchantRepair")
    local costOk,cost,repairAvailable=call(api,"GetRepairAllCost")
    local moneyOk,money=call(api,"GetMoney")
    context.canRepair=canOk and canRepair==true and costOk and repairAvailable==true
    context.cost=costOk and type(cost)=="number" and cost or nil
    context.money=moneyOk and type(money)=="number" and money or nil
    return context
  end

  function adapter:AttemptSale(token)
    local intent=type(token)=="table" and token.intent
    if type(intent)~="table" then return false,"INVALID_INTENT" end
    local current,reason=self:ReadItem(intent.bag,intent.slot)
    if not sameItem(current,intent) or current.refundable~=false or current.quest~=false or
        current.inEquipmentSet~=false or type(current.unitVendorPrice)~="number" or current.unitVendorPrice<=0 then
      return false,reason or "STALE_OR_PROTECTED_ITEM"
    end
    local context=self:ReadContext(token.sessionId,intent.settingsRevision)
    if not context.merchantOpen or context.cursorEmpty~=true or context.safeContext~=true or
        context.inCombat~=false or context.currentSettingsRevision~=intent.settingsRevision then
      return false,"UNSAFE_CONTEXT"
    end
    local ok,err=call(api,"UseContainerItem",intent.bag,intent.slot)
    return ok,err
  end

  function adapter:AttemptRepair(context)
    local latest=self:ReadRepairContext(context.sessionId,context.settingsRevision)
    if not latest.merchantOpen or latest.safeContext~=true or latest.cursorEmpty~=true or
        latest.inCombat~=false or latest.canRepair~=true or latest.cost~=context.cost or
        type(latest.money)~="number" or latest.money<latest.cost or
        latest.currentSettingsRevision~=context.settingsRevision then return false,"REPAIR_CONTEXT_CHANGED" end
    local ok,err=call(api,"RepairAllItems")
    return ok,err
  end

  function adapter:PickupContainerItem(item)
    local current,reason=self:ReadItem(item.bag,item.slot)
    local context=self:ReadContext(item.sessionId,item.settingsRevision)
    if not sameItem(current,item) or context.safeContext~=true or context.cursorEmpty~=true or
        context.inCombat~=false or context.currentSettingsRevision~=item.settingsRevision then
      return false,reason or "UNSAFE_DESTROY_CONTEXT"
    end
    local ok,err=call(api,"PickupContainerItem",item.bag,item.slot)
    return ok,err
  end

  -- The 3.3.5 cursor API exposes only type and item ID. The full link/count are
  -- proven by re-reading the original slot immediately before pickup and
  -- confirming that it became empty while the expected item ID reached cursor.
  function adapter:MatchesPickedUpItem(item)
    local context=self:ReadContext(item.sessionId,item.settingsRevision)
    local cursorOk,cursorType,cursorId=call(api,"GetCursorInfo")
    local source,reason=self:ReadItem(item.bag,item.slot)
    if context.safeContext~=true or context.inCombat~=false or not cursorOk or cursorType~="item" or
        cursorId~=item.itemId or not source or source.state~="EMPTY" then
      return false,reason or "CURSOR_OR_SLOT_MISMATCH"
    end
    return true
  end

  function adapter:DeletePickedUpItem(item)
    local matches,reason=self:MatchesPickedUpItem(item)
    if not matches then return false,reason end
    local ok,err=call(api,"DeleteCursorItem")
    return ok,err
  end

  function adapter:AttemptDestroy(item)
    local ok,reason=self:PickupContainerItem(item)
    if not ok then return false,reason end
    local matched,matchReason=self:MatchesPickedUpItem(item)
    if not matched then return false,matchReason or "CURSOR_MISMATCH_ITEM_LEFT_UNTOUCHED" end
    return self:DeletePickedUpItem(item)
  end

  function adapter:UseLootableItem(item)
    local current,reason=self:ReadItem(item.bag,item.slot)
    local context=self:ReadContext(nil,self.getSettingsRevision and self.getSettingsRevision())
    if not sameItem(current,item) or current.lootable~=true or context.cursorEmpty~=true or
        context.safeContext~=true or context.inCombat~=false or
        context.currentSettingsRevision~=item.settingsRevision then return false,reason or "UNSAFE_LOOT_CONTEXT" end
    local ok,err=call(api,"UseContainerItem",item.bag,item.slot)
    return ok,err
  end

  function adapter:Money()
    local ok,value=call(api,"GetMoney")
    return ok and type(value)=="number" and value or nil
  end
  function adapter:Latency()
    local ok,_,_,home,world=call(api,"GetNetStats")
    if not ok then return 0.2 end
    return math.max(0.2,(tonumber(home) or 0)/1000,(tonumber(world) or 0)/1000)
  end
  function adapter:Available(name) return type(api[name])=="function" end
  return adapter
end

return Transactions
