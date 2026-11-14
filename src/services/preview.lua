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

function Preview.Format(rows,action)
  action=type(action)=="string" and action:upper() or ""
  if action~="SELL" and action~="DESTROY" then return nil,"INVALID_ACTION" end
  if type(rows)~="table" then return nil,"INVALID_PREVIEW" end
  local counts={JUNK=0,KEEP=0,UNKNOWN=0}
  local lines={"READ-ONLY "..action.." PREVIEW","No action will be taken.",""}
  for _,row in ipairs(rows) do
    local result=counts[row.result]~=nil and row.result or "UNKNOWN"
    counts[result]=counts[result]+1
    lines[#lines+1]=result.." | bag "..tostring(row.bag or "?").." slot "..tostring(row.slot or "?")..
      " | item "..tostring(row.itemId or "unknown").." x"..tostring(row.count or 1)..
      " | "..tostring(row.reasonCode or "UNKNOWN")
  end
  lines[#lines+1]=""
  lines[#lines+1]="Eligible: "..counts.JUNK.." | Keep: "..counts.KEEP.." | Unknown: "..counts.UNKNOWN
  return table.concat(lines,"\n"),counts
end

return Preview
