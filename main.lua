--[[
    Build A Ring Farm
    Modular rewrite — Linoria UI
--]]

local Library      = loadstring(game:HttpGet('https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua'))()
local ThemeManager = loadstring(game:HttpGet('https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/ThemeManager.lua'))()
local SaveManager  = loadstring(game:HttpGet('https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/SaveManager.lua'))()

local env = {}
env.Library      = Library
env.ThemeManager = ThemeManager
env.SaveManager  = SaveManager

env.Window = Library:CreateWindow({
    Title        = 'Build A Ring Farm',
    Center       = true,
    AutoShow     = true,
    TabPadding   = 8,
    MenuFadeTime = 0.2,
})

env.FarmTab      = env.Window:AddTab('Farming')
env.UpgradesTab  = env.Window:AddTab('Upgrades')
env.ShopTab      = env.Window:AddTab('Shop')
env.EventsTab    = env.Window:AddTab('Events')
env.RewardsTab   = env.Window:AddTab('Rewards')
env.UtilitiesTab = env.Window:AddTab('Utilities')
env.UISettingsTab= env.Window:AddTab('UI Settings')

local function loadModule(path)
    local ok, err = pcall(function()
        loadstring(readfile(path))(env)
    end)
    if not ok then
        warn('Arkham Hub Failed ' .. path .. ' | ' .. tostring(err))
    end
end

loadModule('build-aring/modules/services.lua')
loadModule('build-aring/modules/config.lua')
loadModule('build-aring/modules/utils.lua')
loadModule('build-aring/modules/data.lua')
loadModule('build-aring/modules/inventory.lua')

loadModule('build-aring/tabs/farm.lua')
loadModule('build-aring/tabs/upgrades.lua')
loadModule('build-aring/tabs/shop.lua')
loadModule('build-aring/tabs/events.lua')
loadModule('build-aring/tabs/rewards.lua')
loadModule('build-aring/tabs/utilities.lua')
loadModule('build-aring/tabs/configtab.lua')

SaveManager:SetLibrary(Library)
ThemeManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder('build-aring')
SaveManager:BuildConfigSection(env.UISettingsTab)
ThemeManager:ApplyToTab(env.UISettingsTab)
SaveManager:LoadAutoloadConfig()

if env.teleportToMyPlot then env.teleportToMyPlot() end

print('Arkham Hub Loaded.')
