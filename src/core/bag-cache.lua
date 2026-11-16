local _, Addon = ...

function Addon.NewBagCache(adapter, scheduler, bus)
  local cache = { generation = 0, active = false, pending = nil, retryDeadline = nil }
  local snapshot = { generation = 0, valid = false, bags = {}, items = {}, occupied = 0, unknown = 0 }

  function cache:GetSnapshot()
    local copy = Addon.Copy(snapshot)
    copy.valid = self.active and snapshot.valid and snapshot.generation == self.generation
    copy.currentGeneration = self.generation
    return copy
  end

  function cache:Queue(delay)
    if self.pending or not self.active then return end
    self.pending = scheduler:After(delay, function()
      self.pending = nil
      self:Refresh()
    end)
  end

  function cache:Invalidate(reason)
    if not self.active then return end
    self.generation = self.generation + 1
    self.retryDeadline = nil
    -- A pending metadata retry can be due much later than the normal bag
    -- refresh. Replace it so a real bag change is scanned promptly.
    if self.pending then self.pending:Cancel(); self.pending = nil end
    bus:Emit("BagsInvalidated", self.generation, reason)
    self:Queue(0.1)
  end

  function cache:Refresh()
    if not self.active then return end
    local generation = self.generation
    local nextSnapshot = {
      generation = generation, valid = true, bags = {}, items = {}, occupied = 0, unknown = 0
    }
    local sets = adapter:ReadEquipmentSets()
    nextSnapshot.equipmentSetsKnown = sets.known
    nextSnapshot.equipmentSetCount = sets.known and sets.count or nil
    local incomplete = false
    for bag = 0, 4 do
      local size = adapter:ReadBagSize(bag)
      nextSnapshot.bags[bag] = { size = size, known = size ~= nil }
      if size == nil then
        incomplete = true
        nextSnapshot.unknown = nextSnapshot.unknown + 1
      else
        for slot = 1, size do
          local item = adapter:ReadSlot(bag, slot, sets)
          if item.state=="OCCUPIED" and item.equipLoc and item.equipLoc~="" and type(adapter.ReadBinding)=="function" then
            local bound=adapter:ReadBinding(bag,slot)
            local after=adapter:ReadSlot(bag,slot,sets)
            if Addon.SameSlotObservation(item,after) and after.state=="OCCUPIED" then
              item.bound=bound
            else
              item.state,item.reason="UNKNOWN","PROBE_CHANGED"
            end
          end
          item.bagGeneration = generation
          nextSnapshot.items[bag .. ":" .. slot] = item
          if item.state == "OCCUPIED" then
            nextSnapshot.occupied = nextSnapshot.occupied + 1
          end
          if item.state == "UNKNOWN" or (item.state == "OCCUPIED" and item.metadata ~= "known") then
            incomplete = true
            nextSnapshot.unknown = nextSnapshot.unknown + 1
          end
        end
      end
    end
    nextSnapshot.valid = self.active and generation == self.generation
    snapshot = nextSnapshot
    bus:Emit("BagsUpdated", self:GetSnapshot())
    -- Keep retrying unresolved slots for up to five seconds from the first
    -- incomplete scan, matching the reference deadline without infinite polling.
    if incomplete and generation == self.generation then
      self.retryDeadline = self.retryDeadline or (scheduler.now + 5)
      local remaining = self.retryDeadline - scheduler.now
      if remaining > 0 then self:Queue(math.min(0.5, remaining)) end
    else
      self.retryDeadline = nil
    end
  end

  function cache:Start()
    if self.active then return end
    self.active = true
    self:Invalidate("LOGIN")
  end
  function cache:Stop()
    self.active = false
    self.generation = self.generation + 1
    if self.pending then self.pending:Cancel(); self.pending = nil end
  end
  return cache
end
