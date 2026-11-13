local _, Addon = ...

-- Pure, read-only projection of one valid bag snapshot. It mirrors upstream's
-- combined sell/destroy junk collection and ordering without performing work.
local JunkItems = {}
Addon.JunkItems = JunkItems

local function less(a, b)
  local aPrice = type(a.unitVendorPrice) == "number" and a.unitVendorPrice * (a.count or 1) or 0
  local bPrice = type(b.unitVendorPrice) == "number" and b.unitVendorPrice * (b.count or 1) or 0
  if aPrice ~= bPrice then return aPrice < bPrice end
  if a.quality ~= b.quality then return (a.quality or -1) < (b.quality or -1) end
  local aName, bName = string.lower(a.name or ""), string.lower(b.name or "")
  if aName ~= bName then return aName < bName end
  if a.count ~= b.count then return (a.count or 0) < (b.count or 0) end
  if a.bag ~= b.bag then return (a.bag or -1) < (b.bag or -1) end
  return (a.slot or -1) < (b.slot or -1)
end

function JunkItems.Build(snapshot, settings)
  if type(snapshot) ~= "table" or snapshot.valid ~= true or
      snapshot.generation ~= snapshot.currentGeneration then
    return nil, "SNAPSHOT_INVALID"
  end
  local result = { generation = snapshot.generation, items = {}, sellable = 0, destroyable = 0 }
  for key, item in pairs(snapshot.items or {}) do
    if item.state == "OCCUPIED" then
      local sell = Addon.Rules.Evaluate(item, "SELL", settings)
      local destroy = Addon.Rules.Evaluate(item, "DESTROY", settings)
      if sell.result == "JUNK" or destroy.result == "JUNK" then
        local row = Addon.Copy(item)
        row.slotKey = key
        row.sell, row.destroy = sell, destroy
        result.items[#result.items + 1] = row
        if sell.result == "JUNK" then result.sellable = result.sellable + 1 end
        if destroy.result == "JUNK" then result.destroyable = result.destroyable + 1 end
      end
    end
  end
  table.sort(result.items, less)
  return result
end

return JunkItems
