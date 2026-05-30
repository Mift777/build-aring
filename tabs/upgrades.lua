return function(env)
    local T       = env.UpgradesTab
    local UpgTypes= env.UpgradeTypes
    local PlotUpgs= env.PlotUpgrades
    local getUpgCost  = env.getUpgradeCost
    local doUpgrade   = env.doPlotUpgrade
    local seedLuck    = env.upgradeSeedLuck
    local seedRolls   = env.upgradeSeedRolls
    local haveMoney   = env.haveEnoughMoney

    T:CreateSection("Plot Powerups")

    T:CreateDropdown({
        Name = "Powerups para Upgradar",
        Options = UpgTypes or {"SawRange","SawYield","SprinklerRange","SprinklerPower","SeedLuck","SeedRolls"},
        CurrentOption = {},
        MultipleOptions = true,
        Flag = "TargetPowerups",
        Callback = function(opts)
            _G.TargetPowerups={}
            for _,v in ipairs(opts) do _G.TargetPowerups[v]=true end
        end,
    })

    T:CreateToggle({
        Name="Auto Upgrade Powerups", CurrentValue=false, Flag="AutoUpgPowerups",
        Callback=function(val)
            _G.AutoUpgradePowerups=val
            if not val then return end
            task.spawn(function()
                while _G.AutoUpgradePowerups do
                    pcall(function()
                        for _,upg in ipairs(UpgTypes or {}) do
                            if not _G.AutoUpgradePowerups then break end
                            if _G.TargetPowerups and _G.TargetPowerups[upg] then
                                local cfg=PlotUpgs[upg]
                                if not cfg then goto continue end
                                if cfg.Type=="plot" then
                                    for floor=1,6 do
                                        if not _G.AutoUpgradePowerups then break end
                                        local cost=getUpgCost(upg,floor)
                                        if cost==nil then break end
                                        if cost=="MAX" then break end
                                        if haveMoney(cost,upg,tostring(cost)) then
                                            doUpgrade(upg,floor); task.wait(1)
                                        else break end
                                    end
                                elseif cfg.Type=="seedluck" then
                                    seedLuck(); task.wait(1)
                                elseif cfg.Type=="seedrolls" then
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
