return function(env)
    local T       = env.EventsTab
    local Remotes = env.Remotes
    local LP      = env.LocalPlayer
    local allSeeds= env.getIndexSeeds
    local findSeed= env.findSeedTool

    T:CreateSection("Plant Rush")

    T:CreateToggle({Name="Auto Atirar Plant Rush",CurrentValue=false,Flag="AutoPlantRush",
        Callback=function(val)
            _G.AutoPlantRush=val
            if not val then return end
            task.spawn(function()
                while _G.AutoPlantRush do
                    pcall(function()
                        local sr=Remotes:FindFirstChild("PlantRush") and Remotes.PlantRush:FindFirstChild("Shoot")
                        local hrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                        local rt=workspace:FindFirstChild("InteractiveEvents")
                            and workspace.InteractiveEvents:FindFirstChild("PlantRush")
                            and workspace.InteractiveEvents.PlantRush:FindFirstChild("Runtime")
                        if sr and hrp and rt then
                            local origin=hrp.Position+Vector3.new(0,1.5,0)
                            for _,obj in ipairs(rt:GetChildren()) do
                                if not _G.AutoPlantRush then break end
                                if obj:IsA("Model") and obj.PrimaryPart then
                                    local tp=obj.PrimaryPart.Position
                                    local dir=(tp-origin).Unit
                                    pcall(function() sr:FireServer(origin,dir,tp) end)
                                    task.wait(0.05)
                                end
                            end
                        end
                    end)
                    task.wait(0.1)
                end
            end)
        end})

    T:CreateToggle({Name="Auto Coletar Boss Drops",CurrentValue=false,Flag="AutoBossDrops",
        Callback=function(val)
            _G.AutoClaimPlantRushBossDrop=val
            if not val then return end
            task.spawn(function()
                while _G.AutoClaimPlantRushBossDrop do
                    pcall(function()
                        local hrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                        if not hrp then return end
                        for _,obj in ipairs(workspace:GetChildren()) do
                            if not _G.AutoClaimPlantRushBossDrop then break end
                            if string.find(obj.Name,"PlantRushLocalDrop_",1,true) then
                                local prompt=obj:FindFirstChildWhichIsA("ProximityPrompt",true)
                                if prompt then
                                    local part=obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart",true)
                                    if part then
                                        hrp.CFrame=part.CFrame; task.wait(0.1)
                                        if fireproximityprompt and _G.AutoClaimPlantRushBossDrop then
                                            fireproximityprompt(prompt); task.wait(0.2)
                                        end
                                    end
                                end
                            end
                        end
                    end)
                    task.wait(0.5)
                end
            end)
        end})

    T:CreateSection("Queen Bee")

    T:CreateToggle({Name="Auto Coletar Honeycomb",CurrentValue=false,Flag="AutoHoneycomb",
        Callback=function(val)
            _G.AutoCollectQueenBeeHoneycomb=val
            if not val then return end
            task.spawn(function()
                while _G.AutoCollectQueenBeeHoneycomb do
                    pcall(function()
                        local hrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                        local hc=workspace:FindFirstChild("InteractiveEvents")
                            and workspace.InteractiveEvents:FindFirstChild("QueenBee")
                            and workspace.InteractiveEvents.QueenBee:FindFirstChild("RuntimeHoneycombs")
                        if not hrp or not hc then return end
                        for _,obj in ipairs(hc:GetChildren()) do
                            if not _G.AutoCollectQueenBeeHoneycomb then break end
                            local prompt=obj:FindFirstChildWhichIsA("ProximityPrompt",true)
                            if prompt then
                                local part=obj:IsA("BasePart") and obj
                                    or (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart",true)))
                                if part then
                                    hrp.CFrame=part.CFrame; task.wait(0.2)
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
        end})

    local _jarPrompt, _jarCF = nil, nil
    local function getJarMachine()
        if _jarPrompt and _jarPrompt.Parent then return _jarPrompt, _jarCF end
        _jarPrompt, _jarCF = nil, nil
        local m=workspace:FindFirstChild("InteractiveEvents")
            and workspace.InteractiveEvents:FindFirstChild("QueenBee")
            and workspace.InteractiveEvents.QueenBee:FindFirstChild("HoneyJarMachine")
            and workspace.InteractiveEvents.QueenBee.HoneyJarMachine:FindFirstChild("Honey Jar Machine")
        local p=m and m:FindFirstChild("InsertPrompt")
        if not p then return nil,nil end
        local part=p.Parent; if part and part:IsA("Attachment") then part=part.Parent end
        if not part then return nil,nil end
        _jarPrompt=p; _jarCF=part.CFrame+Vector3.new(0,3,0)
        return _jarPrompt, _jarCF
    end

    local function hasHoneyToken()
        local function c(p)
            if not p then return false end
            for _,i in ipairs(p:GetChildren()) do
                if i:IsA("Tool") and string.find(string.lower(i.Name),"honey token",1,true) then return true end
            end
            return false
        end
        return c(LP.Character) or c(LP:FindFirstChild("Backpack"))
    end

    T:CreateToggle({Name="Auto Submeter Honey Token",CurrentValue=false,Flag="AutoHoneyToken",
        Callback=function(val)
            _G.AutoSubmitQueenBeeHoneyToken=val
            if not val then return end
            task.spawn(function()
                while _G.AutoSubmitQueenBeeHoneyToken do
                    if not hasHoneyToken() then task.wait(2)
                    else
                        local prompt,cf=getJarMachine()
                        if prompt and cf then
                            local hrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                hrp.CFrame=cf; task.wait(0.5)
                                if fireproximityprompt and _G.AutoSubmitQueenBeeHoneyToken then
                                    fireproximityprompt(prompt); task.wait(0.2)
                                end
                            end
                        else task.wait(2) end
                    end
                    task.wait(1)
                end
            end)
        end})

    T:CreateSection("Seed Collector")

    local seedList={"None"}; pcall(function()
        local v=allSeeds(); if v and #v>0 then seedList=v end
    end)

    T:CreateDropdown({Name="Seeds para Submeter",Options=seedList,CurrentOption={},MultipleOptions=true,
        Flag="CollectorSeeds",
        Callback=function(opts)
            _G.TargetSeedCollectorSubmitSeeds={}
            for _,v in ipairs(opts) do
                local n=string.match(v,"%] (.+)") or v; _G.TargetSeedCollectorSubmitSeeds[n]=true
            end
        end})

    T:CreateButton({Name="Limpar Alvos Collector",Callback=function()
        _G.TargetSeedCollectorSubmitSeeds={}
        env.Window:Notify({Title="Collector",Content="Alvos limpos.",Duration=2})
    end})

    local function isSeedCollectorDone()
        local gui=LP:FindFirstChild("PlayerGui")
        local progress = gui and gui:FindFirstChild("MainUI")
            and gui.MainUI:FindFirstChild("Menus")
            and gui.MainUI.Menus:FindFirstChild("SeedCollectorFrame")
            and gui.MainUI.Menus.SeedCollectorFrame:FindFirstChild("Main")
            and gui.MainUI.Menus.SeedCollectorFrame.Main:FindFirstChild("Frame")
            and gui.MainUI.Menus.SeedCollectorFrame.Main.Frame:FindFirstChild("ProgressBarDaily")
            and gui.MainUI.Menus.SeedCollectorFrame.Main.Frame.ProgressBarDaily:FindFirstChild("Progress")
        if not progress or not progress:IsA("TextLabel") then return false end
        local text=progress.Text:gsub(",","")
        local cur,max=string.match(text,"(%d+)%s*/%s*(%d+)")
        return cur and max and tonumber(cur)>=tonumber(max)
    end

    local function submitToCollector(submitAll)
        local coll=workspace:FindFirstChild("SeedCollector")
        local att=coll and coll:FindFirstChild("Attachment")
        local prompt=att and att:FindFirstChild("SubmitSeed")
        if not prompt then return false end
        local hrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end
        if (hrp.Position-att.WorldCFrame.Position).Magnitude>15 then
            hrp.CFrame=att.WorldCFrame; task.wait(1)
        end
        local targets=submitAll and {} or _G.TargetSeedCollectorSubmitSeeds or {}
        if submitAll then
            for _,cont in ipairs({LP.Character,LP:FindFirstChild("Backpack")}) do
                if cont then
                    for _,item in ipairs(cont:GetChildren()) do
                        if item:IsA("Tool") and item:GetAttribute("InventoryCategory")=="Seeds" then
                            local tn=item:GetAttribute("trueName")
                            if tn then targets[tn]=true end
                        end
                    end
                end
            end
        end
        local submitted=false
        for seedName in pairs(targets) do
            if not _G.AutoSubmitSeedToCollector and not _G.AutoSubmitAllSeedsToCollector then break end
            if isSeedCollectorDone() then break end
            local tool=findSeed(seedName)
            if tool and fireproximityprompt then
                fireproximityprompt(prompt); task.wait(0.1); submitted=true
                if isSeedCollectorDone() then break end
            end
        end
        return submitted
    end

    local function startCollLoop()
        task.spawn(function()
            while _G.AutoSubmitSeedToCollector or _G.AutoSubmitAllSeedsToCollector do
                if isSeedCollectorDone() then task.wait(10)
                else
                    local ok=submitToCollector(_G.AutoSubmitAllSeedsToCollector)
                    if not ok then task.wait(2) end
                end
                task.wait(1)
            end
        end)
    end

    T:CreateToggle({Name="Auto Submeter Seeds Selecionadas",CurrentValue=false,Flag="AutoSubmitSel",
        Callback=function(val)
            _G.AutoSubmitSeedToCollector=val
            if val then _G.AutoSubmitAllSeedsToCollector=false; startCollLoop() end
        end})

    T:CreateToggle({Name="Auto Submeter TODAS Seeds",CurrentValue=false,Flag="AutoSubmitAll",
        Callback=function(val)
            _G.AutoSubmitAllSeedsToCollector=val
            if val then _G.AutoSubmitSeedToCollector=false; startCollLoop() end
        end})
end
