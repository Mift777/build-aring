--[[
    ================================================================
    [ SCRIPT INFORMATION ]
    Project: Custom Script
    Author: OYB
    YouTube: https://www.youtube.com/channel/UCAlXXV1Hbvf7WbfXARuVtiQ
    
    [ TERMS AND CONDITIONS ]
    - You ARE allowed to use and modify this script for your own games.
    - You ARE NOT allowed to re-upload, redistribute, or claim 
      ownership of this script.
    - Removing or altering these credits is strictly prohibited.
    
    Copyright (c) 2026 OYB. All rights reserved.
    ================================================================
]]

-- ⚠️ IMPORTANT: Put this code at the VERY TOP of your Main Script (before obfuscating) ⚠️

local ProtectionConfig = {
    -- 🔴 CRITICAL: This MUST exactly match the 'Secret' value in your Key System's Config!
    -- If your Key System has: Secret = "Test"
    -- Then this must also be: SecretKey = "Test"
    SecretKey = "92513198",
    
    -- The name of your Hub (shown in the kick message if they try to bypass)
    HubName = "Arkham Hub"
}

-- Anti-Bypass Logic: Checks if the Key System successfully set the global variable
if not _G[ProtectionConfig.SecretKey] then
    local player = game:GetService("Players").LocalPlayer
    if player then
        player:Kick("\n🛡️ Unauthorized Execution 🛡️\n\nPlease use the official Key System to run " .. ProtectionConfig.HubName)
    end
    return -- Stops the rest of the script from loading!
end

-------------------------------------------------------------------------------
-- 👇 YOUR MAIN SCRIPT CODE STARTS HERE 👇
-------------------------------------------------------------------------------

print(ProtectionConfig.HubName .. " Loaded Successfully!"

local Helix = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Mift777/arkham-ui/main/helix2.lua?cb=" .. math.floor(tick())
))()

local BASE = "https://raw.githubusercontent.com/Mift777/build-aring/main/"

local env = {}

env.Window = Helix:CreateWindow({
    Title     = "Build A Ring Farm",
    Discord   = "discord.gg/GMWtZFPfbA",
    Width     = 560,
    Height    = 430,
    Accent    = Color3.fromRGB(75, 180, 140),
    ToggleKey = Enum.KeyCode.RightShift,
})

env.FarmTab     = env.Window:CreateTab("Farming",   4483362458)
env.Floor1Tab   = env.Window:CreateTab("Floor 1",   4483362458)
env.Floor2Tab   = env.Window:CreateTab("Floor 2",   4483362458)
env.Floor3Tab   = env.Window:CreateTab("Floor 3",   4483362458)
env.UpgradesTab = env.Window:CreateTab("Upgrades",  4483362458)
env.ShopTab     = env.Window:CreateTab("Shop",      4483362458)
env.PetsTab     = env.Window:CreateTab("Pets",      4483362458)
env.EventsTab   = env.Window:CreateTab("Events",    4483362458)
env.RewardsTab  = env.Window:CreateTab("Rewards",   4483362458)
env.UtilsTab    = env.Window:CreateTab("Utilities", 4483362458)

local function loadModule(path)
    local ok, err = pcall(function()
        local url = BASE .. path .. "?cb=" .. math.floor(tick())
        local fn = loadstring(game:HttpGet(url))()
        if fn then fn(env)
        else warn("[BAR] WARN: " .. path .. " retornou nil") end
    end)
    if not ok then warn("[BAR] FAIL: " .. path .. " | " .. tostring(err))
    else print("[BAR] OK: " .. path) end
end

loadModule("modules/services.lua")
loadModule("modules/config.lua")
loadModule("modules/utils.lua")
loadModule("modules/data.lua")
loadModule("modules/inventory.lua")
loadModule("modules/floorbuilder.lua")

loadModule("tabs/farm.lua")
loadModule("tabs/floor1.lua")
loadModule("tabs/floor2.lua")
loadModule("tabs/floor3.lua")
loadModule("tabs/upgrades.lua")
loadModule("tabs/shop.lua")
loadModule("tabs/pets.lua")
loadModule("tabs/events.lua")
loadModule("tabs/rewards.lua")
loadModule("tabs/utilities.lua")

if env.teleportToMyPlot then env.teleportToMyPlot() end
print("[BAR] Carregado!")
