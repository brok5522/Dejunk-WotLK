local addonName, Addon = ...
Addon = Addon or {}
local function message(text)
  text = '[' .. addonName .. '] ' .. text
  if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then DEFAULT_CHAT_FRAME:AddMessage(text)
  elseif type(print) == 'function' then print(text) end
end
local function inspect()
  if type(GetBuildInfo) ~= 'function' then return false, 'GetBuildInfo unavailable' end
  local ok, version, build, _, interface = pcall(GetBuildInfo)
  if not ok then return false, 'GetBuildInfo failed' end
  local supported = (version == '3.3.5' or version == '3.3.5a') and
    tonumber(build) == 12340 and tonumber(interface) == 30300
  return supported, 'client=' .. tostring(version) .. ' build=' .. tostring(build) ..
    ' interface=' .. tostring(interface)
end
Addon.Inspect = inspect
local frame = CreateFrame('Frame')
frame:RegisterEvent('ADDON_LOADED')
frame:RegisterEvent('PLAYER_LOGIN')
local loaded, loggedIn, started = false, false, false
local function activate()
  if started or not loaded or not loggedIn then return end
  started = true
  local supported, detail = inspect()
  message((supported and 'Original-client target detected; ' or 'Unsupported target; ') .. detail)
  -- No inventory action is performed. Add capabilities incrementally behind an adapter.
end
frame:SetScript('OnEvent', function(_, event, name)
  if event == 'ADDON_LOADED' and name == addonName then loaded = true end
  if event == 'PLAYER_LOGIN' then loggedIn = true end
  activate()
end)
local slashKey = addonName:upper():gsub('[^A-Z0-9]', '') .. 'PROBE'
_G['SLASH_' .. slashKey .. '1'] = '/addon335probe'
SlashCmdList[slashKey] = function()
  local supported, detail = inspect()
  message(tostring(supported) .. ' / ' .. detail)
end
