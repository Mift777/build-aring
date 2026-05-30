return function(env)
    local T         = env.FarmTab
    local Lib       = env.Library
    local Remotes   = env.Remotes
    local LP        = env.LocalPlayer
    local findPlot  = env.findMyPlot
    local findSeed  = env.findSeedTool
    local pMoney    = env.parseMoney
    local haveMoney = env.haveEnoughMoney

    -- LEFT: Auto Farming
    local AutoBox = T:AddLeftGroupbox('Auto Farming')

    AutoBox:AddToggle('AutoSellCrates', {
        Text = 'Auto Sell Crates', Default = false,
        Callback = function(val)
            _G.AutoSellCrates = val
            if not val then return end
            task.spawn(function()
                while _G.AutoSellCrates do
                    pcall(function()
                        if Remotes:FindFirstChild('SellCrates') then Remotes.SellCrates:FireServer() end
                    end)
                    task.wait(2)
                end
            end)
        end,
    })

    AutoBox:AddToggle('AutoUnlockPlots', {
        Text = 'Auto Unlock Farm Plots', Default = false,
        Callback = function(val)
            _G.AutoUnlockFarmPlots = val
            if not val then return end
            task.spawn(function()
                while _G.AutoUnlockFarmPlots do
                    local plot = findPlot()
                    if plot then
                        -- Iterate ALL descendants, fire for every Dirt (no break - same as original)
                        for _, d in ipairs(plot:GetDescendants()) do
                            if not _G.AutoUnlockFarmPlots then break end
                            if d.Name == 'Dirt' then
                                pcall(function() Remotes.UnlockPlot:FireServer(d) end)
                                task.wait(2)
                            end
                        end
                    end
                    task.wait(2)
                end
            end)
        end,
    })

    AutoBox:AddToggle('AutoExpandPlot', {
        Text = 'Auto Expand Farm Plot', Default = false,
        Callback = function(val)
            _G.AutoExpandFarmPlot = val
            if not val then return end
            task.spawn(function()
                while _G.AutoExpandFarmPlot do
                    pcall(function()
                        local map = workspace:FindFirstChild('Map')
                        if not map then return end
                        local plots = map:FindFirstChild('Plots')
                        local ur = Remotes:FindFirstChild('UpgradeFarm')
                        if not plots or not ur then return end
                        for _, p in ipairs(plots:GetChildren()) do
                            if not _G.AutoExpandFarmPlot then break end
                            local txt = p:FindFirstChild('ExpandSign')
                                and p.ExpandSign:FindFirstChild('Screen')
                                and p.ExpandSign.Screen:FindFirstChild('SurfaceGui')
                                and p.ExpandSign.Screen.SurfaceGui:FindFirstChild('Expand')
                                and p.ExpandSign.Screen.SurfaceGui.Expand:FindFirstChild('Btn')
                                and p.ExpandSign.Screen.SurfaceGui.Expand.Btn:FindFirstChild('Txt')
                            if txt and (txt:IsA('TextLabel') or txt:IsA('TextButton')) and haveMoney(pMoney(txt.Text), 'Plot Expansion') then
                                ur:InvokeServer()
                            end
                        end
                    end)
                    task.wait(2)
                end
            end)
        end,
    })

    AutoBox:AddButton({
        Text = 'Remove All Plants  [double-click]', DoubleClick = true,
        Func = function()
            task.spawn(function()
                Lib:Notify('Removing all plants...', 10)
                local plot = findPlot()
                if not plot then Lib:Notify('Plot not found.', 3); return end
                for _, d in ipairs(plot:GetDescendants()) do
                    if d.Name == 'Dirt' and d:GetAttribute('PlantLevel') ~= nil then
                        pcall(function() Remotes.RemovePlant:FireServer(d) end)
                        task.wait(0.3)
                    end
                end
                Lib:Notify('All plants removed!', 3)
            end)
        end,
    })

    -- RIGHT: Seed Management
    local SeedBox = T:AddRightGroupbox('Seed Management')

    local seedList = {'None'}
    pcall(function()
        local v = env.getIndexSeeds and env.getIndexSeeds() or {}
        if #v > 0 then seedList = v end
    end)

    SeedBox:AddDropdown('SeedSelect', {
        Values = seedList, Default = 1,
        Text = 'Seed Type to Plant',
        Callback = function(val) _G.SelectedSeedTrueName = val end,
    })

    SeedBox:AddButton({
        Text = 'Plant Selected Seed',
        Func = function()
            if not _G.SelectedSeedTrueName or _G.SelectedSeedTrueName == 'None' then
                Lib:Notify('Select a seed type first.', 3); return
            end
            task.spawn(function()
                local plot = findPlot()
                if not plot then Lib:Notify('Plot not found.', 3); return end
                local planted = false
                for _, d in ipairs(plot:GetDescendants()) do
                    if d.Name == 'Dirt' and not d:GetAttribute('PlantLevel') then
                        local s = findSeed(_G.SelectedSeedTrueName)
                        if s then
                            pcall(function() Remotes.PlantSeed:FireServer(d) end)
                            task.wait(0.3); planted = true
                        end
                    end
                end
                Lib:Notify(planted and 'Planted!' or 'No seeds left.', 3)
            end)
        end,
    })

    SeedBox:AddButton({
        Text = 'Discard Selected Seed  [double-click]',
        DoubleClick = true,
        Func = function()
            if not _G.SelectedSeedTrueName or _G.SelectedSeedTrueName == 'None' then
                Lib:Notify('Select a seed type first.', 3); return
            end
            if _G.IsDiscarding then Lib:Notify('Discard already running.', 3); return end
            _G.IsDiscarding = true
            local target = _G.SelectedSeedTrueName
            Lib:Notify('Discarding ' .. target, 3)
            local char = LP.Character
            if char and char:FindFirstChildWhichIsA('Humanoid') then
                char.Humanoid:UnequipTools()
            end
            task.spawn(function()
                while _G.IsDiscarding do
                    if _G.SelectedSeedTrueName ~= target then break end
                    local t = LP.Character and LP.Character:FindFirstChildWhichIsA('Tool')
                    if t and t:GetAttribute('trueName') == target then
                        pcall(function()
                            if Remotes:FindFirstChild('DiscardSeed') then Remotes.DiscardSeed:FireServer() end
                        end)
                    else
                        findSeed(target); task.wait(0.2)
                    end
                    task.wait()
                end
                _G.IsDiscarding = false
            end)
        end,
    })

    SeedBox:AddButton({
        Text = 'Stop Discard',
        Func = function() _G.IsDiscarding = false; Lib:Notify('Discard stopped.', 2) end,
    })
end
