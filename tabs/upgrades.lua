return function(env)
    local T         = env.UpgradesTab
    local Lib       = env.Library
    local Remotes   = env.Remotes
    local UpgTypes  = env.UpgradeTypes
    local PlotUpgs  = env.PlotUpgrades
    local getUpgCost= env.getUpgradeCost
    local doUpgrade = env.doPlotUpgrade
    local seedLuck  = env.upgradeSeedLuck
    local seedRolls = env.upgradeSeedRolls
    local haveMoney = env.haveEnoughMoney

    -- LEFT: Plot Powerups
    local PowBox = T:AddLeftGroupbox("Plot Powerups")

    PowBox:AddDropdown("TargetPowerupsDd", {
        Values = UpgTypes or {"SawRange","SawYield","SprinklerRange","SprinklerPower","SeedLuck","SeedRolls"},
        Default = {}, Multi = true,
        Text = "Select Powerups to Upgrade",
        Callback = function(val)
            _G.TargetPowerups = {}
            if type(val) == "table" then
                for _, v in pairs(val) do _G.TargetPowerups[v] = true end
            elseif val and val ~= "" then
                _G.TargetPowerups[val] = true
            end
        end,
    })

    PowBox:AddToggle("AutoUpgradePowerups", {
        Text = "Auto Upgrade Selected Powerups", Default = false,
        Callback = function(val)
            _G.AutoUpgradePowerups = val
            if not val then return end
            task.spawn(function()
                while _G.AutoUpgradePowerups do
                    pcall(function()
                        local money = env.getCurrentMoney and env.getCurrentMoney() or 0
                        for _, upg in ipairs(UpgTypes or {}) do
                            if not _G.AutoUpgradePowerups then break end
                            if _G.TargetPowerups and _G.TargetPowerups[upg] then
                                local cfg = PlotUpgs[upg]
                                if not cfg then goto continue end
                                if cfg.Type == "plot" then
                                    for floor = 1, 6 do
                                        if not _G.AutoUpgradePowerups then break end
                                        local cost = getUpgCost(upg, floor)
                                        if cost == nil then break end
                                        if cost == "MAX" then break end
                                        if haveMoney(cost, upg, tostring(cost)) then
                                            doUpgrade(upg, floor); task.wait(1)
                                            if not _G.SkipMoneyCheck then
                                                money = env.getCurrentMoney and env.getCurrentMoney() or 0
                                            end
                                        else break end
                                    end
                                elseif cfg.Type == "seedluck" then
                                    seedLuck(); task.wait(1)
                                elseif cfg.Type == "seedrolls" then
                                    seedRolls(); task.wait(1)
                                end
                                ::continue::
                            end
                        end
                    end)
                    task.wait(3)
                end
            end)
        end,
    })
end
