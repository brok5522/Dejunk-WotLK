local _, Addon = ...
local Preview = {}
Addon.Preview = Preview

function Preview.EvaluateSnapshot(snapshot, settings, action)
  local results = {}
  if type(snapshot) ~= "table" or snapshot.valid ~= true or
      snapshot.generation ~= snapshot.currentGeneration then
    return results, "SNAPSHOT_INVALID"
  end
  for key, item in pairs(snapshot.items or {}) do
    local decision = Addon.Rules.Evaluate(item, action, settings)
    decision.slotKey = key
    decision.bag, decision.slot = item.bag, item.slot
    decision.itemId, decision.count, decision.link = item.itemId, item.count, item.link
    results[#results + 1] = decision
  end
  table.sort(results, function(a, b)
    if a.bag ~= b.bag then return (a.bag or -1) < (b.bag or -1) end
    return (a.slot or -1) < (b.slot or -1)
  end)
  return results
end

return Preview
