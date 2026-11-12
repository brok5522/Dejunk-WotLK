local addonName, Addon = ...

-- The loader's private table avoids addon-global collisions. No game API here.
Addon.name = addonName
Addon.version = "0.7.0-dev"
Addon.phase = 6
Addon.UNKNOWN = "unknown"

function Addon.Copy(value)
  if type(value) ~= "table" then return value end
  local copy = {}
  for key, entry in pairs(value) do copy[key] = Addon.Copy(entry) end
  return copy
end
