return function(env)
    local T         = env.UpgradesTab
    local Lib       = env.Library
    local Remotes   = env.Remotes
    local UpgTypes  = env.UpgradeTypes
    local PlotUpgs  = env.PlotUpgrades
    local allSeeds  = env.getIndexSeeds
    local getMuts   = env.getMutationList
    local getUpgCost= env.getUpgradeCost
    local doUpgrade = env.doPlotUpgrade
    local seedLuck  = env.upgradeSeedLuck
    local seedRolls = env.upgradeSeedRolls
    local haveMoney = env.haveEnoughMoney
    local findFert  = env.findFertilizer

    local seedList = {"None"}; pcall(function() local v = allSeeds(); if v and #v > 0 then seedList = v end end)
local mutList  = {"None"}; pcall(function() local v = getMuts();  if v and #v > 0 then mutList  = v end end)
local fertList = (env.FertilizerTypes and #env.FertilizerTypes > 0) and env.FertilizerTypes or {"None"}
    -- LEFT: Plot Powerups
    local PowBox = T:AddLeftGroupbox('Plot Powerups')

    PowBox:AddDropdown('TargetPowerupsDd', {
        Values = {'SawRange','SawYield','SprinklerRange','SprinklerPower','SeedLuck','SeedRolls'},
        Default = {}, Multi = true,
        Text = 'Select Powerups to Upgrade',
        Callback = function(val) _G.TargetPowerups = val end,
    })

    PowBox:AddToggle('AutoUpgradePowerups', {
        Text = 'Auto Upgrade Selected Powerups', Default = false,
        Callback = function(val)
            _G.AutoUpgradePowerups = val
            if not val then return end
            task.spawn(function()
                while _G.AutoUpgradePowerups do
                    for _, upg in ipairs(UpgTypes) do
                        if not _G.AutoUpgradePowerups then break end
                        if _G.TargetPowerups and _G.TargetPowerups[upg] then
                            local cfg = PlotUpgs[upg]
                            if cfg.Type == 'plot' then
                                for floor = 1, 3 do
                                    local cost = getUpgCost(upg, floor)
                                    if cost == 'MAX' then break end
                                    if cost and haveMoney(cost, upg, tostring(cost)) then
                                        doUpgrade(upg, floor); task.wait(1)
                                    else break end
                                end
                            elseif cfg.Type == 'seedluck' then
                                seedLuck(); task.wait(1)
                            elseif cfg.Type == 'seedrolls' then
                                seedRolls(); task.wait(1)
                            end
                        end
                    end
                    task.wait(3)
                end
            end)
        end,
    })

    -- RIGHT: Flora Upgrade
    local UpgBox = T:AddRightGroupbox('Flora Upgrade')

    UpgBox:AddDropdown('UpgPlants', {
        Values = seedList, Default = {}, Multi = true,
        Text = 'Target Plants (Empty = All)',
        Callback = function(val) _G.TargetUpgradePlantNames = val end,
    })

    UpgBox:AddDropdown('UpgMuts', {
        Values = mutList, Default = {}, Multi = true,
        Text = 'Target Mutations (Empty = All)',
        Callback = function(val) _G.TargetUpgradeMutations = val end,
    })

    UpgBox:AddSlider('UpgPlantLevel', {
        Text = 'Target Plant Level',
        Default = 10, Min = 1, Max = 100, Rounding = 0,
        Callback = function(val) _G.TargetPlantUpgradeLevel = val end,
    })

    UpgBox:AddToggle('AutoUpgradePlants', {
        Text = 'Auto Upgrade Targeted Plants', Default = false,
        Callback = function(val)
            _G.AutoUpgradePlants = val
            if not val then return end
            task.spawn(function()
                while _G.AutoUpgradePlants do
                    pcall(function()
                        if Remotes:FindFirstChild('UpgradePlant') then
                            Remotes.UpgradePlant:FireServer()
                        end
                    end)
                    task.wait(2)
                end
            end)
        end,
    })

    UpgBox:AddButton({Text='Clear Upgrade Targets', Func=function()
        _G.TargetUpgradePlantNames = {}; _G.TargetUpgradeMutations = {}
        if Lib then Lib:Notify('Upgrade targets cleared.', 2) end
    end})

    -- LEFT: Flora Fertilization
    local FertBox = T:AddLeftGroupbox('Flora Fertilization')

    FertBox:AddDropdown('FertPlants', {
        Values = seedList, Default = {}, Multi = true,
        Text = 'Target Plants (Empty = All)',
        Callback = function(val) _G.TargetFertilizePlantNames = val end,
    })

    FertBox:AddDropdown('FertMuts', {
        Values = mutList, Default = {}, Multi = true,
        Text = 'Target Mutations (Empty = All)',
        Callback = function(val) _G.TargetFertilizeMutations = val end,
    })

    FertBox:AddDropdown('FertTypes', {
        Values = fertList, Default = {}, Multi = true,
        Text = 'Fertilizer Type (Empty = All)',
        Callback = function(val) _G.TargetFertilizerTypes = val end,
    })

    FertBox:AddToggle('AutoFertilize', {
        Text = 'Auto Fertilize Targeted Plants', Default = false,
        Callback = function(val)
            _G.AutoFertilize = val
            if not val then return end
            task.spawn(function()
                while _G.AutoFertilize do
                    local fert = findFert()
                    if fert then
                        pcall(function() Remotes.Fertilize:FireServer(fert) end)
                    end
                    task.wait(2)
                end
            end)
        end,
    })

    FertBox:AddButton({Text='Clear Fertilize Targets', Func=function()
        _G.TargetFertilizePlantNames = {}
        _G.TargetFertilizeMutations  = {}
        _G.TargetFertilizerTypes     = {}
        if Lib then Lib:Notify('Fertilize targets cleared.', 2) end
    end})
end
