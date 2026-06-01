return function(env)
    local T          = env.UpgradesTab
    local UpgTypes   = env.UpgradeTypes
    local PlotUpgs   = env.PlotUpgrades
    local getUpgCost = env.getUpgradeCost
    local doUpgrade  = env.doPlotUpgrade
    local seedLuck   = env.upgradeSeedLuck
    local seedRolls  = env.upgradeSeedRolls
    local haveMoney  = env.haveEnoughMoney

    local Sec = T:CreateSection("Plot Powerups")

    Sec:AddDropdown({
        Name = "Powerups para Upgradar",
        Options = UpgTypes or {"SawRange","SawYield","SprinklerRange","SprinklerPower","SeedLuck","SeedRolls"},
        Multi = true,
        Callback = function(sel)
            _G.TargetPowerups={}
            for v in pairs(sel) do _G.TargetPowerups[v]=true end
        end,
    })

    Sec:AddToggle({
        Name = "Auto Upgrade Powerups",
        Default = false,
        Callback = function(val)
            _G.AutoUpgradePowerups=val
            if not val then return end
            task.spawn(function()
                while _G.AutoUpgradePowerups do
                    pcall(function()
                        for _,upg in ipairs(UpgTypes or {}) do
                            if not _G.AutoUpgradePowerups then break end
                            if _G.TargetPowerups and _G.TargetPowerups[upg] then
                                local cfg=PlotUpgs and PlotUpgs[upg]
                                if not cfg then
                                elseif cfg.Type=="plot" then
                                    for floor=1,6 do
                                        if not _G.AutoUpgradePowerups then break end
                                        local cost=getUpgCost and getUpgCost(upg,floor)
                                        if cost==nil or cost=="MAX" then break end
                                        if haveMoney and haveMoney(cost,upg,tostring(cost)) then
                                            if doUpgrade then doUpgrade(upg,floor) end
                                            task.wait(1)
                                        else break end
                                    end
                                elseif cfg.Type=="seedluck" then
                                    if seedLuck then seedLuck() end; task.wait(1)
                                elseif cfg.Type=="seedrolls" then
                                    if seedRolls then seedRolls() end; task.wait(1)
                                end
                            end
                        end
                    end)
                    task.wait(3)
                end
            end)
        end,
    })
end
