return function(env)
    local T       = env.EventsTab
    local Lib     = env.Library
    local Remotes = env.Remotes
    local LP      = env.LocalPlayer
    local allSeeds= env.getIndexSeeds
    local findSeed= env.findSeedTool

    -- ================================================================
    -- LEFT: World Events
    -- ================================================================
    local EventBox = T:AddLeftGroupbox("World Events")

    -- Auto Shoot Plant Rush
    EventBox:AddToggle("AutoShootPlantRush", {
        Text = "Auto Shoot Plant Rush", Default = false,
        Callback = function(val)
            _G.AutoPlantRush = val
            if not val then return end
            task.spawn(function()
                while _G.AutoPlantRush do
                    pcall(function()
                        local shootRemote = Remotes:FindFirstChild("PlantRush") and Remotes.PlantRush:FindFirstChild("Shoot")
                        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                        local runtime = workspace:FindFirstChild("InteractiveEvents")
                            and workspace.InteractiveEvents:FindFirstChild("PlantRush")
                            and workspace.InteractiveEvents.PlantRush:FindFirstChild("Runtime")
                        if shootRemote and hrp and runtime then
                            local origin = hrp.Position + Vector3.new(0, 1.5, 0)
                            for _, obj in ipairs(runtime:GetChildren()) do
                                if not _G.AutoPlantRush then break end
                                if obj:IsA("Model") and obj.PrimaryPart then
                                    local targetPos = obj.PrimaryPart.Position
                                    local dir = (targetPos - origin).Unit
                                    pcall(function() shootRemote:FireServer(origin, dir, targetPos) end)
                                    task.wait(0.05)
                                end
                            end
                        end
                    end)
                    task.wait(0.1)
                end
            end)
        end,
    })

    -- Auto Claim Plant Rush Boss Drops
    EventBox:AddToggle("AutoClaimBossDrops", {
        Text = "Auto Claim Plant Rush Boss Drops", Default = false,
        Callback = function(val)
            _G.AutoClaimPlantRushBossDrop = val
            if not val then return end
            task.spawn(function()
                while _G.AutoClaimPlantRushBossDrop do
                    pcall(function()
                        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                        if not hrp then return end
                        for _, obj in ipairs(workspace:GetChildren()) do
                            if not _G.AutoClaimPlantRushBossDrop then break end
                            if string.find(obj.Name, "PlantRushLocalDrop_", 1, true) then
                                local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                                if prompt then
                                    local part = obj:IsA("BasePart") and obj
                                        or obj:FindFirstChildWhichIsA("BasePart", true)
                                    if part then
                                        hrp.CFrame = part.CFrame; task.wait(0.1)
                                        if fireproximityprompt and _G.AutoClaimPlantRushBossDrop then
                                            fireproximityprompt(prompt); task.wait(0.2)
                                            Lib:Notify("Boss Drop Claimed: " .. obj.Name, 3)
                                        end
                                    end
                                end
                            end
                        end
                    end)
                    task.wait(0.5)
                end
            end)
        end,
    })

    -- ================================================================
    -- RIGHT: Queen Bee
    -- ================================================================
    local BeeBox = T:AddRightGroupbox("Queen Bee")

    -- Auto Collect Honeycomb
    BeeBox:AddToggle("AutoCollectHoneycomb", {
        Text = "Auto Collect Queen Bee Honeycomb", Default = false,
        Callback = function(val)
            _G.AutoCollectQueenBeeHoneycomb = val
            if not val then return end
            task.spawn(function()
                while _G.AutoCollectQueenBeeHoneycomb do
                    pcall(function()
                        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                        local honeycombs = workspace:FindFirstChild("InteractiveEvents")
                            and workspace.InteractiveEvents:FindFirstChild("QueenBee")
                            and workspace.InteractiveEvents.QueenBee:FindFirstChild("RuntimeHoneycombs")
                        if not hrp or not honeycombs then return end
                        for _, obj in ipairs(honeycombs:GetChildren()) do
                            if not _G.AutoCollectQueenBeeHoneycomb then break end
                            local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if prompt then
                                local part = obj:IsA("BasePart") and obj
                                    or (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)))
                                if part then
                                    hrp.CFrame = part.CFrame; task.wait(0.2)
                                    if fireproximityprompt and _G.AutoCollectQueenBeeHoneycomb then
                                        fireproximityprompt(prompt); task.wait(0.2)
                                    end
                                end
                            end
                        end
                    end)
                    task.wait(1)
                end
            end)
        end,
    })

    -- Auto Submit Honey Token
    local cachedJarPrompt, cachedJarCFrame = nil, nil
    local function getJarMachine()
        if cachedJarPrompt and cachedJarPrompt.Parent then return cachedJarPrompt, cachedJarCFrame end
        cachedJarPrompt, cachedJarCFrame = nil, nil
        local machine = workspace:FindFirstChild("InteractiveEvents")
            and workspace.InteractiveEvents:FindFirstChild("QueenBee")
            and workspace.InteractiveEvents.QueenBee:FindFirstChild("HoneyJarMachine")
            and workspace.InteractiveEvents.QueenBee.HoneyJarMachine:FindFirstChild("Honey Jar Machine")
        if not machine then return nil, nil end
        local prompt = machine:FindFirstChild("InsertPrompt")
        if not prompt then return nil, nil end
        local part = prompt.Parent
        if part and part:IsA("Attachment") then part = part.Parent end
        if not part then return nil, nil end
        cachedJarPrompt = prompt
        cachedJarCFrame = part.CFrame + Vector3.new(0, 3, 0)
        return cachedJarPrompt, cachedJarCFrame
    end

    local function hasHoneyToken()
        local function check(parent)
            if not parent then return false end
            for _, item in ipairs(parent:GetChildren()) do
                if item:IsA("Tool") and string.find(string.lower(item.Name), "honey token", 1, true) then
                    return true
                end
            end
            return false
        end
        return check(LP.Character) or check(LP:FindFirstChild("Backpack"))
    end

    BeeBox:AddToggle("AutoSubmitHoneyToken", {
        Text = "Auto Submit Honey Token", Default = false,
        Callback = function(val)
            _G.AutoSubmitQueenBeeHoneyToken = val
            if not val then return end
            task.spawn(function()
                while _G.AutoSubmitQueenBeeHoneyToken do
                    if not hasHoneyToken() then
                        task.wait(2)
                    else
                        local prompt, cf = getJarMachine()
                        if prompt and cf then
                            local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                hrp.CFrame = cf; task.wait(0.5)
                                if fireproximityprompt and _G.AutoSubmitQueenBeeHoneyToken then
                                    fireproximityprompt(prompt); task.wait(0.2)
                                end
                            end
                        else
                            task.wait(2)
                        end
                    end
                    task.wait(1)
                end
            end)
        end,
    })

    -- ================================================================
    -- LEFT: Seed Collector
    -- ================================================================
    local CollBox = T:AddLeftGroupbox("Seed Collector")

    local seedList = {"None"}; pcall(function() local v = allSeeds(); if v and #v > 0 then seedList = v end end)

    CollBox:AddDropdown("CollectorSeeds", {
        Values = seedList, Default = {}, Multi = true,
        Text = "Seeds to Submit",
        Callback = function(val)
            _G.TargetSeedCollectorSubmitSeeds = {}
            if type(val) == "table" then
                for _, v in pairs(val) do
                    local n = string.match(v, "%] (.+)") or v
                    _G.TargetSeedCollectorSubmitSeeds[n] = true
                end
            elseif val and val ~= "" then
                local n = string.match(val, "%] (.+)") or val
                _G.TargetSeedCollectorSubmitSeeds[n] = true
            end
        end,
    })

    CollBox:AddButton({Text="Clear Collector Targets", Func=function()
        _G.TargetSeedCollectorSubmitSeeds = {}
        Lib:Notify("Collector targets cleared.", 2)
    end})

    local COLLECTOR_RANGE = 15
    local function isSeedCollectorDone()
        local gui = LP:FindFirstChild("PlayerGui")
        local mainUI = gui and gui:FindFirstChild("MainUI")
        local menus = mainUI and mainUI:FindFirstChild("Menus")
        local frame = menus and menus:FindFirstChild("SeedCollectorFrame")
        local progress = frame and frame:FindFirstChild("Main")
            and frame.Main:FindFirstChild("Frame")
            and frame.Main.Frame:FindFirstChild("ProgressBarDaily")
            and frame.Main.Frame.ProgressBarDaily:FindFirstChild("Progress")
        if not progress or not progress:IsA("TextLabel") then return false end
        local text = progress.Text:gsub(",", "")
        local cur, max = string.match(text, "(%d+)%s*/%s*(%d+)")
        return cur and max and tonumber(cur) >= tonumber(max)
    end

    local function submitSeedToCollector(submitAll)
        local collector = workspace:FindFirstChild("SeedCollector")
        local attach = collector and collector:FindFirstChild("Attachment")
        local prompt = attach and attach:FindFirstChild("SubmitSeed")
        if not prompt then return false end
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end
        -- Teleport to collector if needed
        if (hrp.Position - attach.WorldCFrame.Position).Magnitude > COLLECTOR_RANGE then
            hrp.CFrame = attach.WorldCFrame; task.wait(1)
        end
        local targets = submitAll and {} or _G.TargetSeedCollectorSubmitSeeds or {}
        local submitted = false
        if submitAll then
            -- Submit all seeds in inventory
            for _, cont in ipairs({LP.Character, LP:FindFirstChild("Backpack")}) do
                if cont then
                    for _, item in ipairs(cont:GetChildren()) do
                        if item:IsA("Tool") and item:GetAttribute("InventoryCategory") == "Seeds" then
                            local tn = item:GetAttribute("trueName")
                            if tn then targets[tn] = true end
                        end
                    end
                end
            end
        end
        for seedName in pairs(targets) do
            if not _G.AutoSubmitSeedToCollector and not _G.AutoSubmitAllSeedsToCollector then break end
            if isSeedCollectorDone() then break end
            local tool = findSeed(seedName)
            if tool then
                if fireproximityprompt then
                    fireproximityprompt(prompt); task.wait(0.1)
                    submitted = true
                    if isSeedCollectorDone() then break end
                end
            end
        end
        return submitted
    end

    local function startCollectorLoop()
        task.spawn(function()
            while _G.AutoSubmitSeedToCollector or _G.AutoSubmitAllSeedsToCollector do
                if isSeedCollectorDone() then
                    task.wait(10)
                else
                    local ok = submitSeedToCollector(_G.AutoSubmitAllSeedsToCollector)
                    if not ok then task.wait(2) end
                end
                task.wait(1)
            end
        end)
    end

    CollBox:AddToggle("AutoSubmitSelected", {
        Text = "Auto Submit Selected Seeds", Default = false,
        Callback = function(val)
            _G.AutoSubmitSeedToCollector = val
            if val then
                _G.AutoSubmitAllSeedsToCollector = false
                pcall(function() Options.AutoSubmitAll:SetValue(false) end)
                startCollectorLoop()
            end
        end,
    })

    CollBox:AddToggle("AutoSubmitAll", {
        Text = "Auto Submit ALL Seeds", Default = false,
        Callback = function(val)
            _G.AutoSubmitAllSeedsToCollector = val
            if val then
                _G.AutoSubmitSeedToCollector = false
                pcall(function() Options.AutoSubmitSelected:SetValue(false) end)
                startCollectorLoop()
            end
        end,
    })
end
