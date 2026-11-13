local _, Addon = ...

-- Read-only view of legacy bag tuples marked lootable. Opening a stack remains
-- a deliberate action in the player's normal bag UI; this module never uses it.
local LootableItems = {}
Addon.LootableItems = LootableItems

function LootableItems.Build(snapshot)
  if type(snapshot) ~= "table" or snapshot.valid ~= true or
      snapshot.generation ~= snapshot.currentGeneration then
    return nil, "SNAPSHOT_INVALID"
  end
  local items = {}
  for _, item in pairs(snapshot.items or {}) do
    if item.state == "OCCUPIED" and item.lootable == true then items[#items + 1] = Addon.Copy(item) end
  end
  table.sort(items, function(a,b)
    if a.bag ~= b.bag then return (a.bag or -1) < (b.bag or -1) end
    return (a.slot or -1) < (b.slot or -1)
  end)
  return {generation=snapshot.generation,items=items,count=#items}
end

return LootableItems
