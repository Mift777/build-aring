return function(env)
    local T         = env.FarmTab
    local Lib       = env.Library
    local Remotes   = env.Remotes
    local LP        = env.LocalPlayer
    local findPlot  = env.findMyPlot
    local findSeed  = env.findSeedTool
    local findCmpt  = env.findCompostSeed
    local getSeedQty= env.getSeedQuantity
    local clampIns  = env.clampInsertAmount
    local getCmpRem = env.getCompostInsertRemote
    local pMoney    = env.parseMoney
    local haveMoney = env.haveEnoughMoney
    local allSeeds  = env.getIndexSeeds
    local getMuts   = env.getMutationList

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
                pcall(function()
                    local plot = findPlot()
                    if not plot then return end
                    local unlockRemote = Remotes:FindFirstChild('UnlockPlot')
                    if not unlockRemote then return end
                    local char = LP.Character
                    local hrp  = char and char:FindFirstChild('HumanoidRootPart')
                    for _, d in ipairs(plot:GetDescendants()) do
                        if not _G.AutoUnlockFarmPlots then break end
                        if d.Name == 'Dirt' and #d:GetChildren() == 0 then
                            if hrp then
                                local pos = d:IsA('BasePart') and d.Position
                                    or (d:IsA('Model') and d.PrimaryPart and d.PrimaryPart.Position)
                                if pos then
                                    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
                                    task.wait(0.3)
                                end
                            end
                            unlockRemote:FireServer(d)
                            task.wait(1)
                        end
                    end
                end)
                task.wait(5)
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
                            if txt and txt:IsA('TextLabel') and haveMoney(pMoney(txt.Text), 'Plot Expansion') then
                                ur:InvokeServer()
                            end
                        end
                    end)
                    task.wait(2)
                end
            end)
        end,
    })

    AutoBox:AddSeparator()

    AutoBox:AddButton({
        Text = 'Remove All Plants  [double-click]',
        DoubleClick = true,
        Func = function()
            Lib:Notify('Removing all plants...', 10)
            local plot = findPlot()
            if not plot then return end
            for _, d in ipairs(plot:GetDescendants()) do
                if d.Name == 'Dirt' and d:GetAttribute('PlantLevel') ~= nil then
                    pcall(function() Remotes.RemovePlant:FireServer(d) end)
                    task.wait(0.3)
                end
            end
            Lib:Notify('All plants removed!', 3)
        end,
    })

    -- RIGHT: Seed Management
    local SeedBox = T:AddRightGroupbox('Seed Management')

    SeedBox:AddDropdown('SeedSelect', {
        Values = allSeeds(), Default = 1,
        Text = 'Seed Type to Plant',
        Callback = function(val) _G.SelectedSeedTrueName = val end,
    })

    SeedBox:AddButton({
        Text = 'Plant Selected Seed',
        Func = function()
            if _G.SelectedSeedTrueName == 'None' then
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
                Lib:Notify(planted and 'Planted all plots!' or 'Ran out of seeds.', 4)
            end)
        end,
    })

    SeedBox:AddButton({
        Text = 'Discard Selected Seed  [double-click]',
        DoubleClick = true,
        Func = function()
            if _G.SelectedSeedTrueName == 'None' then
                Lib:Notify('Select a seed type first.', 3); return
            end
            if _G.IsDiscarding then
                Lib:Notify('Discard already running.', 3); return
            end
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
        Func = function()
            _G.IsDiscarding = false
            Lib:Notify('Discard stopped.', 2)
        end,
    })

    -- RIGHT: Composter (second right box)
    local CompBox = T:AddRightGroupbox('Composter')

    CompBox:AddDropdown('CompSeeds', {
        Values = allSeeds(), Default = {}, Multi = true,
        Text = 'Target Seeds (Empty = All)',
        Callback = function(val) _G.TargetCompostSeeds = val end,
    })

    CompBox:AddDropdown('CompMuts', {
        Values = getMuts(), Default = {}, Multi = true,
        Text = 'Target Mutations (Empty = All)',
        Callback = function(val) _G.TargetCompostMutations = val end,
    })

    CompBox:AddDropdown('CompFloor', {
        Values = {'2', '3'}, Default = 1,
        Text = 'Composter Floor',
        Callback = function(val) _G.CompostFloor = tonumber(val) or 2 end,
    })

    CompBox:AddInput('CompMaxInsert', {
        Default = '0', Numeric = true, Finished = true,
        Text = 'Max Seeds Per Insert (0 = no limit)',
        Callback = function(val)
            local n = tonumber(val)
            if not n or n < 0 or n % 1 ~= 0 then
                _G.MaxCompostInsertAmount = 0
                Options.CompMaxInsert:SetValue('0')
            else
                _G.MaxCompostInsertAmount = math.floor(n)
            end
        end,
    })

    CompBox:AddInput('CompLeverDelay', {
        Default = '2', Numeric = true, Finished = true,
        Text = 'Pull Lever Delay (seconds)',
        Callback = function(val)
            local n = tonumber(val)
            _G.AutoPullComposterLeverDelaySeconds = (n and n >= 0) and n or 2
        end,
    })

    CompBox:AddSeparator()

    CompBox:AddToggle('AutoCompostAll', {
        Text = 'Auto Compost ALL Seeds  [DANGER!]',
        Default = false, Tooltip = 'Cannot be undone!',
        Callback = function(val) _G.AutoCompostAllSeeds = val end,
    })

    CompBox:AddToggle('AutoCompostFiltered', {
        Text = 'Auto Compost Filtered', Default = false,
        Callback = function(val)
            _G.AutoCompost = val
            if not val then return end
            task.spawn(function()
                while _G.AutoCompost do
                    local s = findCmpt()
                    if s then
                        local qty = clampIns(getSeedQty(s))
                        local r = getCmpRem()
                        if r then for i = 1, qty do r:FireServer(s); task.wait(0.1) end end
                    end
                    task.wait(0.5)
                end
            end)
        end,
    })

    CompBox:AddToggle('AutoPullLever', {
        Text = 'Auto Pull Composter Lever', Default = false,
        Callback = function(val)
            _G.AutoPullComposterLever = val
            if not val then return end
            task.spawn(function()
                while _G.AutoPullComposterLever do
                    pcall(function()
                        if Remotes:FindFirstChild('Composter') and Remotes.Composter:FindFirstChild('PullLever') then
                            Remotes.Composter.PullLever:FireServer()
                        end
                    end)
                    task.wait(_G.AutoPullComposterLeverDelaySeconds)
                end
            end)
        end,
    })

    CompBox:AddButton({
        Text = 'Manual Insert (once)',
        Func = function()
            local s = findCmpt(); if not s then return end
            local qty = clampIns(getSeedQty(s))
            local r = getCmpRem()
            if r then for i = 1, qty do r:FireServer(s); task.wait(0.1) end end
        end,
    })
end
