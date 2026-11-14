local _, Addon = ...

function Addon.NewEventBus(onError)
  local listeners = {}
  local bus = {}
  function bus:On(event, callback)
    assert(type(event) == "string" and type(callback) == "function", "invalid listener")
    local entry = { callback = callback, active = true }
    listeners[event] = listeners[event] or {}
    local list = listeners[event]
    list[#list + 1] = entry
    return function()
      if not entry.active then return end
      entry.active = false
      for i = #list, 1, -1 do
        if list[i] == entry then table.remove(list, i) end
      end
    end
  end
  function bus:Emit(event, ...)
    local current = {}
    for i, entry in ipairs(listeners[event] or {}) do current[i] = entry end
    for _, entry in ipairs(current) do
      if entry.active then
        local ok = pcall(entry.callback, ...)
        if not ok and onError then onError("LISTENER_FAILED") end
      end
    end
  end
  return bus
end
