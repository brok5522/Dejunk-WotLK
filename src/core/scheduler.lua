local _, Addon = ...

function Addon.NewScheduler(onError, onPending)
  local scheduler = { now = 0, nextId = 0, jobs = {} }
  local function notify()
    if onPending then onPending(next(scheduler.jobs) ~= nil) end
  end
  function scheduler:After(delay, callback)
    assert(type(delay) == "number" and delay >= 0 and delay < math.huge, "invalid delay")
    assert(type(callback) == "function", "invalid callback")
    self.nextId = self.nextId + 1
    local id = self.nextId
    self.jobs[id] = { due = self.now + delay, callback = callback }
    local token = {}
    function token:Cancel()
      scheduler.jobs[id] = nil
      notify()
    end
    notify()
    return token
  end
  function scheduler:Advance(elapsed)
    if type(elapsed) ~= "number" or elapsed < 0 or elapsed >= math.huge or elapsed ~= elapsed then return end
    self.now = self.now + elapsed
    local due = {}
    for id, job in pairs(self.jobs) do
      if job.due <= self.now then due[#due + 1] = id end
    end
    table.sort(due)
    -- A callback's new timer is never executed in this same update.
    for _, id in ipairs(due) do
      local job = self.jobs[id]
      if job then
        self.jobs[id] = nil
        local ok = pcall(job.callback)
        if not ok and onError then onError("TIMER_FAILED") end
      end
    end
    notify()
  end
  function scheduler:CancelAll()
    self.jobs = {}
    notify()
  end
  return scheduler
end
