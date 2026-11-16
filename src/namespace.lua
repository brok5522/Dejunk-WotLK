local addonName, Addon = ...

-- The loader's private table avoids addon-global collisions. No game API here.
Addon.name = addonName
Addon.version = "1.0.5"
Addon.phase = 6
Addon.UNKNOWN = "unknown"

function Addon.Copy(value)
  if type(value) ~= "table" then return value end
  local copy = {}
  for key, entry in pairs(value) do copy[key] = Addon.Copy(entry) end
  return copy
end

-- Compare the data read on either side of a binding tooltip probe. Binding
-- itself is returned by that probe and is intentionally not in this list.
function Addon.SameSlotObservation(a,b)
  if type(a)~="table" or type(b)~="table" then return false end
  for _,key in ipairs({"state","bag","slot","itemId","link","count","locked",
    "metadata","quality","itemLevel","itemType","itemSubType","equipLoc",
    "classId","subclassId","unitVendorPrice","quest","refundable",
    "inEquipmentSet","lootable"}) do
    if a[key]~=b[key] then return false end
  end
  return true
end
