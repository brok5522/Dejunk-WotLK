local _, Addon = ...

-- Read-only integration surface matching the upstream DejunkApi contract.
-- Inventory mutation, transaction intent and internal state are never exposed.
local listeners = {}
local publicApi = {
  Events = {
    BagsUpdated = "Dejunk_BagsUpdated",
    StateUpdated = "Dejunk_StateUpdated"
  }
}

local function notify(event)
  local current = {}
  for index, listener in ipairs(listeners) do current[index] = listener end
  for _, listener in ipairs(current) do
    pcall(listener, event)
  end
end

local app = Addon.Application
if app and app.bus then
  app.bus:On("BagsUpdated", function() notify(publicApi.Events.BagsUpdated) end)
  app.bus:On("StateUpdated", function() notify(publicApi.Events.StateUpdated) end)
end

function publicApi:AddListener(listener)
  if type(listener) ~= "function" then return nil, "INVALID_LISTENER" end
  listeners[#listeners + 1] = listener
  local active = true
  return function()
    if not active then return nil end
    active = false
    for index = #listeners, 1, -1 do
      if listeners[index] == listener then
        table.remove(listeners, index)
        return listener
      end
    end
  end
end

function publicApi:IsJunk(bagId, slotId)
  if type(bagId) ~= "number" or bagId ~= math.floor(bagId) or bagId < 0 or bagId > 4 or
      type(slotId) ~= "number" or slotId ~= math.floor(slotId) or slotId < 1 or slotId > 128 then
    return false, "INVALID_SLOT"
  end
  if not app or type(app.ClassifySlot) ~= "function" then return false, "APP_UNAVAILABLE" end
  local ok, isJunk, reason = pcall(app.ClassifySlot, app, bagId, slotId)
  if not ok then return false, "CLASSIFICATION_FAILED" end
  return isJunk == true, reason
end

DejunkApi = publicApi
Addon.Api = publicApi
