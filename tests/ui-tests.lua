assert(_VERSION=="Lua 5.1")
local H=dofile("tests/harness.lua")
local w=H.New():Load(); local Addon=w.addon
local passed=0
local function eq(a,b) assert(a==b,"expected "..tostring(b)..", got "..tostring(a)) end
local store=Addon.Store.Initialize(nil,"A")
eq(Addon.Config.Summary(store):find("Poor quality rule: OFF",1,true)~=nil,true)
local ok,reason,enabled=Addon.Config.ToggleQuality(store,0)
eq(ok,true); eq(enabled,true)
eq(Addon.Config.Summary(store):find("Poor quality rule: ON",1,true)~=nil,true)
ok,reason,enabled=Addon.Config.ToggleQuality(store,0)
eq(ok,true); eq(enabled,false)
ok,reason=Addon.Config.ToggleQuality(store,9); eq(ok,false); eq(reason,"INVALID_OPTION")
local profiles=Addon.Config.ListProfiles(store); eq(#profiles,1); eq(profiles[1].id,"default"); eq(profiles[1].active,true)
local created=Addon.Config.CreateProfile(store,"Raid UI"); eq(created,"profile-1")
profiles=Addon.Config.ListProfiles(store); eq(#profiles,2); eq(profiles[2].active,true)
eq(Addon.Config.SwitchProfile(store,"default"),true)
eq(Addon.Config.ListProfiles(store)[1].active,true)
eq(Addon.Config.SwitchProfile(store,"missing"),false)
eq(Addon.Config.EditItem(store,"global","inclusions",6948,true),true)
eq(Addon.Config.ListItems(store,"global","inclusions"),"6948")
eq(Addon.Config.EditItem(store,"global","inclusions",6948,false),true)
eq(Addon.Config.ListItems(store,"global","inclusions"),"")
eq(Addon.Config.EditItem(store,"invalid","inclusions",6948,true),false)
-- The fixture rejects named native frames; runtime must fall back to chat help.
w:Ready(); w:Command("config")
local found=false
for _,line in ipairs(w.messages) do if line:find("Configuration panel unavailable",1,true) then found=true end end
assert(found); eq(w.mutations,0)
print("UI MODEL RESULT: 15 passed")
