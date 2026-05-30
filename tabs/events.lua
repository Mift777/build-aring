return function(env)
    local T       = env.EventsTab
    local Lib     = env.Library
    local Remotes = env.Remotes
    local allSeeds= env.getIndexSeeds

    -- LEFT: World Events
    local EventBox = T:AddLeftGroupbox('World Events')

    EventBox:AddToggle('AutoShootPlantRush', {
        Text = 'Auto Shoot Plant Rush', Default = false,
        Callback = function(val) _G.AutoPlantRush = val end,
    })

    EventBox:AddToggle('AutoClaimBossDrops', {
        Text = 'Auto Claim Plant Rush Boss Drops', Default = false,
        Callback = function(val) _G.AutoClaimPlantRushBossDrop = val end,
    })

    task.spawn(function()
        while true do
            if _G.AutoPlantRush then
                pcall(function()
                    if Remotes:FindFirstChild('PlantRush') then Remotes.PlantRush:FireServer('Shoot') end
                end)
                task.wait(0.2)
            end
            if _G.AutoClaimPlantRushBossDrop then
                pcall(function()
                    if Remotes:FindFirstChild('ClaimBossDrop') then Remotes.ClaimBossDrop:FireServer() end
                end)
            end
            task.wait(1)
        end
    end)

    -- RIGHT: Queen Bee
    local BeeBox = T:AddRightGroupbox('Queen Bee')

    BeeBox:AddToggle('AutoCollectHoneycomb', {
        Text = 'Auto Collect Queen Bee Honeycomb', Default = false,
        Callback = function(val) _G.AutoCollectQueenBeeHoneycomb = val end,
    })

    BeeBox:AddToggle('AutoSubmitHoneyToken', {
        Text = 'Auto Submit Honey Token (Honey Pot)', Default = false,
        Callback = function(val) _G.AutoSubmitQueenBeeHoneyToken = val end,
    })

    task.spawn(function()
        while true do
            if _G.AutoCollectQueenBeeHoneycomb then
                pcall(function()
                    if Remotes:FindFirstChild('CollectHoneycomb') then Remotes.CollectHoneycomb:FireServer() end
                end)
            end
            if _G.AutoSubmitQueenBeeHoneyToken then
                pcall(function()
                    if Remotes:FindFirstChild('SubmitHoneyToken') then Remotes.SubmitHoneyToken:FireServer() end
                end)
            end
            task.wait(1)
        end
    end)

    -- LEFT: Seed Collector
    local CollBox = T:AddLeftGroupbox('Seed Collector')

    CollBox:AddDropdown('CollectorSeeds', {
        Values = allSeeds(), Default = {}, Multi = true,
        Text = 'Seeds to Submit',
        Callback = function(val) _G.TargetSeedCollectorSubmitSeeds = val end,
    })

    CollBox:AddToggle('AutoSubmitTargetSeeds', {
        Text = 'Auto Submit Targeted Seeds', Default = false,
        Callback = function(val) _G.AutoSubmitSeedToCollector = val end,
    })

    CollBox:AddToggle('AutoSubmitAllSeeds', {
        Text = 'Auto Submit ALL Seeds (Ignore Filter)', Default = false,
        Callback = function(val) _G.AutoSubmitAllSeedsToCollector = val end,
    })

    CollBox:AddButton({Text='Clear Collector Targets', Func=function()
        _G.TargetSeedCollectorSubmitSeeds = {}
        Lib:Notify('Collector targets cleared.', 2)
    end})

    task.spawn(function()
        while true do
            if _G.AutoSubmitAllSeedsToCollector then
                pcall(function()
                    if Remotes:FindFirstChild('SubmitAllSeeds') then Remotes.SubmitAllSeeds:FireServer() end
                end)
            end
            task.wait(5)
        end
    end)
end
