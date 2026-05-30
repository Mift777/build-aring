--[[
    Build A Ring Farm
    Original by Lamduck | Modular - GitHub loader
--]]

local BASE = "https://raw.githubusercontent.com/Mift777/build-aring/main/"

local Library      = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/SaveManager.lua"))()

local env = {}
env.Library      = Library
env.ThemeManager = ThemeManager
env.SaveManager  = SaveManager

env.Window = Library:CreateWindow({
    Title        = "Build A Ring Farm",
    Center       = true,
    AutoShow     = true,
    TabPadding   = 8,
    MenuFadeTime = 0.2,
})

env.FarmTab       = env.Window:AddTab("Farming")
env.UpgradesTab   = env.Window:AddTab("Upgrades")
env.ShopTab       = env.Window:AddTab("Shop")
env.EventsTab     = env.Window:AddTab("Events")
env.RewardsTab    = env.Window:AddTab("Rewards")
env.UtilitiesTab  = env.Window:AddTab("Utilities")
env.UISettingsTab = env.Window:AddTab("UI Settings")

local function loadModule(path)
    local ok, err = pcall(function()
        loadstring(game:HttpGet(BASE .. path))(env)
    end)
    if not ok then
        print("[ArkhamHub] FAIL: " .. path .. " | " .. tostring(err))
    else
        print("[ArkhamHub] OK: " .. path)
    end
end

-- Core
loadModule("modules/services.lua")
loadModule("modules/config.lua")
loadModule("modules/utils.lua")
loadModule("modules/data.lua")
loadModule("modules/inventory.lua")

-- Tabs
loadModule("tabs/farm.lua")
loadModule("tabs/upgrades.lua")
loadModule("tabs/shop.lua")
loadModule("tabs/events.lua")
loadModule("tabs/rewards.lua")
loadModule("tabs/utilities.lua")
loadModule("tabs/configtab.lua")

-- SaveManager / ThemeManager
SaveManager:SetLibrary(Library)
ThemeManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("LamduckHub")
SaveManager:BuildConfigSection(env.UISettingsTab)
ThemeManager:ApplyToTab(env.UISettingsTab)
SaveManager:LoadAutoloadConfig()

if env.teleportToMyPlot then env.teleportToMyPlot() end

print("[ArkhamHub] Loaded.")
