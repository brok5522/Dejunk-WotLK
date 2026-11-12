assert(_VERSION == "Lua 5.1", "Tests require actual Lua 5.1")
local H = dofile("tests/harness.lua")
local passed, failed = 0, 0
local function equal(actual, expected)
  assert(actual == expected, "expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function test(name, callback)
  local ok, err = pcall(callback)
  if ok then passed = passed + 1; print("PASS " .. name)
  else failed = failed + 1; print("FAIL " .. name .. ": " .. tostring(err)) end
end
local function populated(options)
  local w = H.New(options); w:AddItem(0, 1); return w:Load()
end

test("target accepts original 3.3.5 metadata", function()
  equal(populated().app.client.supported, true)
  equal(populated({ version = "3.3.5a", build = 12340 }).app.client.supported, true)
end)
for _, options in ipairs({ { build = 12341 }, { version = "3.4.3" }, { interface = 30403 } }) do
  test("wrong client fails closed " .. tostring(options.build or options.version or options.interface), function()
    local w = populated(options):Ready()
    equal(w.app.state, "DISABLED"); equal(w.reads, 0); equal(#w.frames, 0)
    w:Command("slot 0 1"); equal(w.reads, 0)
  end)
end
test("absent or throwing build API never reads bags", function()
  for _, build in ipairs({ false, function() error("unavailable") end }) do
    local w = H.New(); w.api.GetBuildInfo = build; w:Load():Ready()
    equal(w.app.state, "DISABLED"); equal(w.reads, 0)
  end
end)
test("missing mandatory API disables instead of using modern fallbacks", function()
  local w = H.New(); w.api.GetItemInfo = false; w:Load():Ready()
  equal(w.app.client.reason, "MISSING_API:GetItemInfo"); equal(w.reads, 0)
end)
test("activation waits for own ADDON_LOADED and login exactly once", function()
  local w = populated()
  w:Fire("ADDON_LOADED", "OtherAddon"); w:Tick(1); equal(w.reads, 0)
  w:Fire("PLAYER_LOGIN"); w:Tick(1); equal(w.reads, 0)
  w:Fire("ADDON_LOADED", "Dejunk-WotLK"); equal(w.reads, 0)
  w:Tick(0.1); equal(w.app.state, "READY"); assert(w.reads > 0)
  local generation = w.app.cache.generation
  w:Fire("PLAYER_LOGIN"); equal(w.app.cache.generation, generation)
end)
test("required event failure disables startup", function()
  local w = populated({ badEvent = "BAG_UPDATE" }):Ready()
  equal(w.app.client.reason, "EVENT_SETUP_FAILED"); equal(w.reads, 0)
end)
test("optional event failure appears in evidence without disabling", function()
  local w = populated({ badEvent = "ITEM_LOCKED" }):Ready()
  equal(w.app.state, "READY"); equal(w.app.runtime.registration.ITEM_LOCKED, "unavailable")
end)
test("tuple normalization and zero price stay numeric", function()
  local w = populated():Ready()
  local item = w.app.cache:GetSnapshot().items["0:1"]
  equal(item.state, "OCCUPIED"); equal(item.itemId, 123); equal(item.count, 3)
  equal(item.locked, false); equal(item.metadata, "known"); equal(item.unitVendorPrice, 5)
  equal(item.itemType, "Localized Class"); equal(item.refundable, false)
  w.slots["0:1"].price = 0
  equal(w.app.adapter:ReadSlot(0, 1).unitVendorPrice, 0)
end)
test("empty slots are distinct from unknown occupied slots", function()
  local w = populated():Ready()
  equal(w.app.adapter:ReadSlot(0, 2).state, "EMPTY")
  w.api.GetContainerItemInfo = function() return nil end
  -- The existing adapter captured the original API; a fresh adapter tests shape changes.
  equal(w.app.runtime:NewAdapter():ReadSlot(0, 1).reason, "INCONSISTENT_SLOT")
end)
test("bag scope rejects bank, keyring, bad coordinates and absurd sizes", function()
  local w = populated():Ready()
  local before = w.reads
  equal(w.app.adapter:ReadSlot(-1, 1).state, "UNKNOWN")
  equal(w.app.adapter:ReadBagSize(5), nil); equal(w.reads, before)
  equal(w.app.adapter:ReadSlot(0, 0).state, "UNKNOWN")
  equal(w.app.adapter:ReadSlot(0, 3).state, "UNKNOWN")
  w.sizes[0] = 100000; equal(w.app.adapter:ReadBagSize(0), nil)
end)
test("failed or missing bag size is not zero", function()
  local w = populated():Ready(); w.sizes[0] = nil
  w:Fire("BAG_UPDATE", 0); w:Tick(0.1)
  local snapshot = w.app.cache:GetSnapshot()
  equal(snapshot.bags[0].known, false); equal(snapshot.bags[0].size, nil)
  assert(snapshot.unknown > 0)
end)
test("modern table container shape is rejected", function()
  local w = H.New(); w.api.GetContainerItemInfo = function() return { itemID = 123 } end
  w:AddItem(0, 1); w:Load():Ready()
  equal(w.app.adapter:ReadSlot(0, 1).reason, "UNEXPECTED_API_SHAPE")
end)
test("nil lock and uncached metadata remain unknown", function()
  local w = populated(); local source = w.slots["0:1"]
  source.locked, source.uncached, source.price, source.quest, source.refundSeconds = nil, true, nil, nil, nil
  w:Ready()
  local item = w.app.cache:GetSnapshot().items["0:1"]
  equal(item.locked, "unknown"); equal(item.metadata, "unknown")
  equal(item.unitVendorPrice, nil); equal(item.quest, "unknown"); equal(item.refundable, "unknown")
end)
test("locked item is preserved as locked and never triggers pickup", function()
  local w = populated(); w.slots["0:1"].locked = true; w:Ready()
  equal(w.app.cache:GetSnapshot().items["0:1"].locked, true)
  w:Command("slot 0 1"); equal(w.mutations, 0)
end)
test("failed optional API reads remain unknown", function()
  local w = H.New(); w:AddItem(0, 1)
  w.api.GetContainerItemQuestInfo = function() error("failed") end
  w.api.GetContainerItemPurchaseInfo = false
  w:Load():Ready()
  local item = w.app.cache:GetSnapshot().items["0:1"]
  equal(item.quest, "unknown"); equal(item.refundable, "unknown")
end)
test("fifth purchase return is the refund timer", function()
  local w = populated(); w.slots["0:1"].refundSeconds = 120; w:Ready()
  local item = w.app.cache:GetSnapshot().items["0:1"]
  equal(item.refundable, true); equal(item.refundSeconds, 120)
  assert(item.purchaseShape:match("^5:"))
end)
test("same slot ID/link conflict is unknown", function()
  local w = H.New(); w:AddItem(0, 1)
  w.api.GetContainerItemID = function() return 456 end
  w:Load():Ready()
  equal(w.app.cache:GetSnapshot().items["0:1"].reason, "INCONSISTENT_SLOT")
end)
test("equipment set lookup conservatively protects every matching ID", function()
  local w = populated(); w:AddItem(0, 2)
  w.sets = { { name = "Private set name", ids = { 123, 0, -1 } } }; w:Ready()
  local snapshot = w.app.cache:GetSnapshot()
  equal(snapshot.items["0:1"].inEquipmentSet, true)
  equal(snapshot.items["0:2"].inEquipmentSet, true)
  assert(not w.app.diagnostics:Report(w.app):find("Private set name", 1, true))
end)
test("missing set API and partial failures do not imply no membership", function()
  local w = H.New(); w:AddItem(0, 1); w.api.GetNumEquipmentSets = false; w:Load():Ready()
  equal(w.app.cache:GetSnapshot().items["0:1"].inEquipmentSet, "unknown")
  local x = populated(); x.sets = { { name = "first", ids = { 123 } }, { name = "second", ids = false } }; x:Ready()
  equal(x.app.cache:GetSnapshot().items["0:1"].inEquipmentSet, "unknown")
end)
test("empty equipment set collection is known negative", function()
  local w = populated():Ready()
  equal(w.app.cache:GetSnapshot().items["0:1"].inEquipmentSet, false)
end)
test("localized binding probe is opt-in and tri-state", function()
  local w = populated():Ready(); equal(w.tooltipReads, 0)
  w.tooltipLines = { "item", w.api.ITEM_BIND_ON_EQUIP }
  equal(w.app:ProbeSlot(0, 1).bound, false)
  w.tooltipLines = { "item", w.api.ITEM_SOULBOUND }
  equal(w.app:ProbeSlot(0, 1).bound, true)
  w.tooltipLines = { "item", w.api.ITEM_BIND_TO_ACCOUNT }
  equal(w.app:ProbeSlot(0, 1).bound, true)
  w.tooltipLines = { "item", "unrecognized text" }
  equal(w.app:ProbeSlot(0, 1).bound, "unknown")
end)
test("changed slot during tooltip probe is marked stale", function()
  local w = populated():Ready()
  w.api.CreateFrame = function(kind)
    if kind ~= "GameTooltip" then error("unexpected UI") end
    return { SetOwner = function() end, ClearLines = function() end, Hide = function() end,
      SetBagItem = function() w.slots["0:1"].count = 9 end, NumLines = function() return 0 end }
  end
  equal(w.app:ProbeSlot(0, 1).reason, "PROBE_CHANGED")
end)
test("bag event immediately invalidates old snapshots", function()
  local w = populated():Ready()
  local before = w.app.cache:GetSnapshot()
  w:Fire("BAG_UPDATE", 0)
  equal(w.app.cache:GetSnapshot().valid, false)
  assert(w.app.cache.generation > before.generation)
  w:Tick(0.1); equal(w.app.cache:GetSnapshot().valid, true)
end)
test("event storms coalesce into a single scan", function()
  local w = populated():Ready(); local scans = 0
  w.app.bus:On("BagsUpdated", function() scans = scans + 1 end)
  for i = 1, 200 do w:Fire("BAG_UPDATE", 0) end
  local before = w.reads; equal(scans, 0)
  w:Tick(0.1); equal(scans, 1); assert(w.reads > before)
  before = w.reads; w:Tick(10); equal(w.reads, before)
end)
test("snapshots cannot mutate internal cache tables", function()
  local w = populated():Ready()
  local snapshot = w.app.cache:GetSnapshot()
  snapshot.items["0:1"].count = 900; snapshot.bags[0].size = 900
  equal(w.app.cache:GetSnapshot().items["0:1"].count, 3)
  equal(w.app.cache:GetSnapshot().bags[0].size, 2)
end)
test("uncached retry is bounded and resolves without a bag event", function()
  local w = populated(); w.slots["0:1"].uncached = true; w:Ready()
  w.slots["0:1"].uncached = false; w:Tick(0.5)
  equal(w.app.cache:GetSnapshot().items["0:1"].metadata, "known")
  equal(next(w.app.scheduler.jobs), nil)
end)
test("permanently uncached items stop retrying after two attempts", function()
  local w = populated(); w.slots["0:1"].uncached = true; w:Ready()
  w:Tick(0.5); w:Tick(0.5); local before = w.reads
  w:Tick(100); equal(w.reads, before); equal(next(w.app.scheduler.jobs), nil)
end)
test("logout cancels pending work and invalidates cache", function()
  local w = populated():Ready(); w:Fire("BAG_UPDATE", 0)
  w:Fire("PLAYER_LOGOUT"); local before = w.reads
  w:Tick(100); w:Fire("BAG_UPDATE", 0)
  equal(w.reads, before); equal(w.app.state, "STOPPED")
  equal(w.app.cache:GetSnapshot().valid, false); equal(next(w.app.scheduler.jobs), nil)
end)
test("scheduler supports cancellation, isolation, order and next-update callbacks", function()
  local w = populated(); local A = w.addon
  local errors, order = 0, {}
  local s = A.NewScheduler(function() errors = errors + 1 end)
  local cancelled = s:After(0, function() error("should not run") end)
  cancelled:Cancel(); cancelled:Cancel()
  s:After(0, function() order[#order + 1] = 1; s:After(0, function() order[#order + 1] = 3 end) end)
  s:After(0, function() order[#order + 1] = 2; error("callback") end)
  s:Advance(0); equal(table.concat(order), "12"); equal(errors, 1)
  s:Advance(0); equal(table.concat(order), "123")
  s:Advance(0/0); s:Advance(-1); equal(s.now, 0)
end)
test("bus tolerates unsubscribe and isolated callback failure", function()
  local w = populated(); local errors, calls = 0, 0
  local bus = w.addon.NewEventBus(function() errors = errors + 1 end)
  local off
  bus:On("test", function() off(); error("callback") end)
  off = bus:On("test", function() calls = calls + 1 end)
  bus:On("test", function(value) calls = calls + value end)
  bus:Emit("test", 2); equal(calls, 2); equal(errors, 1)
end)
test("legacy UI error shape remains first message argument", function()
  local w = populated():Ready(); local first, second
  w.app.bus:On("UI_ERROR_MESSAGE", function(a, b) first, second = a, b end)
  w:Fire("UI_ERROR_MESSAGE", "private-error-text")
  equal(first, "private-error-text"); equal(second, nil)
  local report = w.app.diagnostics:Report(w.app)
  assert(report:find("UI_ERROR_MESSAGE args=1:string", 1, true))
  assert(not report:find("private-error-text", 1, true))
end)
test("merchant events and unknown action commands perform no mutations", function()
  local w = populated():Ready()
  w:Fire("MERCHANT_SHOW"); w:Fire("MERCHANT_CLOSED")
  for _, command in ipairs({ "sell", "destroy", "repair", "loot", "help", "status" }) do w:Command(command) end
  equal(w.mutations, 0)
end)
test("invalid slot commands and prelogin probes do not read bags", function()
  local w = populated(); w:Command("slot 0 1"); equal(w.reads, 0)
  w:Ready(); local before = w.reads
  for _, command in ipairs({ "slot -1 1", "slot 5 1", "slot 0 0", "slot 0 129", "slot 0 1 extra" }) do w:Command(command) end
  equal(w.reads, before)
end)
test("diagnostics are bounded, sanitized, contain tuple evidence but no links", function()
  local w = populated():Ready(); w:Command("slot 0 1")
  for i = 1, 80 do w:Fire("UI_ERROR_MESSAGE", "do-not-record-player") end
  equal(#w.app.diagnostics.events, 32)
  local report = w.app.diagnostics:Report(w.app)
  assert(report:find("containerShape=7:", 1, true)); assert(report:find("itemId=123", 1, true))
  assert(not report:find("|Hitem", 1, true)); assert(not report:find("do-not-record-player", 1, true))
  w:Command("report") -- mock rejects report UI, verifies chat fallback
  assert(table.concat(w.messages):find("Report panel unavailable", 1, true))
end)
test("missing texture cannot hide an ID-only occupied slot", function()
  local w = H.New(); w:AddItem(0, 1)
  w.api.GetContainerItemInfo = function() return nil end
  w.api.GetContainerItemLink = function() return nil end
  w:Load():Ready()
  equal(w.app.cache:GetSnapshot().items["0:1"].state, "UNKNOWN")
end)
test("read failures do not abort scans of other slots", function()
  local w = H.New(); w:AddItem(0, 1); w:AddItem(0, 2)
  local original = w.api.GetContainerItemInfo
  w.api.GetContainerItemInfo = function(bag, slot)
    if slot == 1 then error("item read failed") end
    return original(bag, slot)
  end
  w:Load():Ready()
  local snapshot = w.app.cache:GetSnapshot()
  equal(snapshot.items["0:1"].state, "UNKNOWN")
  equal(snapshot.items["0:2"].state, "OCCUPIED")
end)
test("binding tooltip failure stays unknown without touching cursor", function()
  local w = populated():Ready()
  w.api.CreateFrame = function() error("missing tooltip template") end
  equal(w.app:ProbeSlot(0, 1).bound, "unknown"); equal(w.mutations, 0)
end)
test("lock and equipment changes invalidate snapshots", function()
  local w = populated():Ready()
  for _, event in ipairs({ "ITEM_LOCK_CHANGED", "ITEM_LOCKED", "ITEM_UNLOCKED", "EQUIPMENT_SETS_CHANGED", "PLAYER_EQUIPMENT_CHANGED" }) do
    w:Fire(event, 0, 1); equal(w.app.cache:GetSnapshot().valid, false)
    w:Tick(0.1); equal(w.app.cache:GetSnapshot().valid, true)
  end
end)
test("cache invalidated during an adapter scan cannot become valid", function()
  local w = populated():Ready()
  local original = w.app.adapter.ReadSlot
  local changed = false
  w.app.adapter.ReadSlot = function(self, ...)
    if not changed then changed = true; w:Fire("BAG_UPDATE", 0) end
    return original(self, ...)
  end
  w.app.cache:Refresh()
  equal(w.app.cache:GetSnapshot().valid, false)
  w:Tick(0.1); equal(w.app.cache:GetSnapshot().valid, true)
end)

test("all fixture worlds keep mutation sentinels untouched", function()
  for _, world in ipairs(H.worlds) do equal(world.mutations, 0) end
end)
print(string.format("RESULT: %d passed, %d failed", passed, failed))
if failed > 0 then os.exit(1) end
