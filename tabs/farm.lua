return function(env)
    local T        = env.FarmTab
    local Remotes  = env.Remotes
    local LP       = env.LocalPlayer
    local findPlot = env.findMyPlot
    local findSeed = env.findSeedTool
    local pMoney   = env.parseMoney
    local haveMon  = env.haveEnoughMoney

    -- ── Auto Farming ──────────────────────────────────────────
    local SecAuto = T:CreateSection("Auto Farming")

    SecAuto:AddToggle({Name="Auto Vender Caixas", Default=false,
        Callback=function(val)
            _G.AutoSellCrates=val
            if not val then return end
            task.spawn(function()
                while _G.AutoSellCrates do
                    pcall(function()
                        if Remotes:FindFirstChild("SellCrates") then Remotes.SellCrates:FireServer() end
                    end)
                    task.wait(2)
                end
            end)
        end})

    SecAuto:AddToggle({Name="Auto Desbloquear Plots", Default=false,
        Callback=function(val)
            _G.AutoUnlockFarmPlots=val
            if not val then return end
            task.spawn(function()
                while _G.AutoUnlockFarmPlots do
                    local plot=findPlot()
                    if plot then
                        for _,d in ipairs(plot:GetDescendants()) do
                            if not _G.AutoUnlockFarmPlots then break end
                            if d.Name=="Dirt" then
                                pcall(function() Remotes.UnlockPlot:FireServer(d) end)
                                task.wait(2)
                            end
                        end
                    end
                    task.wait(2)
                end
            end)
        end})

    SecAuto:AddToggle({Name="Auto Expandir Farm Plot", Default=false,
        Callback=function(val)
            _G.AutoExpandFarmPlot=val
            if not val then return end
            task.spawn(function()
                while _G.AutoExpandFarmPlot do
                    pcall(function()
                        local map=workspace:FindFirstChild("Map")
                        local plots=map and map:FindFirstChild("Plots")
                        local ur=Remotes:FindFirstChild("UpgradeFarm")
                        if not plots or not ur then return end
                        for _,p in ipairs(plots:GetChildren()) do
                            if not _G.AutoExpandFarmPlot then break end
                            local txt=p:FindFirstChild("ExpandSign")
                                and p.ExpandSign:FindFirstChild("Screen")
                                and p.ExpandSign.Screen:FindFirstChild("SurfaceGui")
                                and p.ExpandSign.Screen.SurfaceGui:FindFirstChild("Expand")
                                and p.ExpandSign.Screen.SurfaceGui.Expand:FindFirstChild("Btn")
                                and p.ExpandSign.Screen.SurfaceGui.Expand.Btn:FindFirstChild("Txt")
                            if txt and haveMon(pMoney(txt.Text),"Expand") then ur:InvokeServer() end
                        end
                    end)
                    task.wait(2)
                end
            end)
        end})

    SecAuto:AddButton({Name="Remover Todas Plantas", Callback=function()
        task.spawn(function()
            local plot=findPlot(); if not plot then return end
            for _,d in ipairs(plot:GetDescendants()) do
                if d.Name=="Dirt" and d:GetAttribute("PlantLevel") then
                    pcall(function() Remotes.RemovePlant:FireServer(d) end); task.wait(0.3)
                end
            end
            env.Window:Notify({Title="Farm",Content="Plantas removidas!",Duration=2})
        end)
    end})

    -- ── Gerenciar Seeds ───────────────────────────────────────
    local SecSeed = T:CreateSection("Gerenciar Seeds")

    local seedList={"None"}
    pcall(function()
        local v=env.getIndexSeeds and env.getIndexSeeds() or {}
        if #v>0 then seedList=v end
    end)

    SecSeed:AddDropdown({Name="Seed para Plantar", Options=seedList, Multi=false,
        Callback=function(sel) _G.SelectedSeedTrueName=sel or "None" end})

    SecSeed:AddButton({Name="Plantar Seed Selecionada", Callback=function()
        if not _G.SelectedSeedTrueName or _G.SelectedSeedTrueName=="None" then
            env.Window:Notify({Title="Farm",Content="Selecione uma seed!",Duration=3}); return
        end
        task.spawn(function()
            local plot=findPlot(); if not plot then return end
            local planted=false
            for _,d in ipairs(plot:GetDescendants()) do
                if d.Name=="Dirt" and not d:GetAttribute("PlantLevel") then
                    local s=findSeed(_G.SelectedSeedTrueName)
                    if s then pcall(function() Remotes.PlantSeed:FireServer(d) end); task.wait(0.3); planted=true end
                end
            end
            env.Window:Notify({Title="Farm",Content=planted and "Plantado!" or "Sem seeds.",Duration=3})
        end)
    end})

    SecSeed:AddButton({Name="Descartar Seed Selecionada", Callback=function()
        if not _G.SelectedSeedTrueName or _G.SelectedSeedTrueName=="None" then return end
        if _G.IsDiscarding then return end
        _G.IsDiscarding=true
        local target=_G.SelectedSeedTrueName
        task.spawn(function()
            while _G.IsDiscarding do
                if _G.SelectedSeedTrueName~=target then break end
                local t=LP.Character and LP.Character:FindFirstChildWhichIsA("Tool")
                if t and t:GetAttribute("trueName")==target then
                    pcall(function()
                        if Remotes:FindFirstChild("DiscardSeed") then Remotes.DiscardSeed:FireServer() end
                    end)
                else findSeed(target); task.wait(0.2) end
                task.wait()
            end
            _G.IsDiscarding=false
        end)
    end})

    SecSeed:AddButton({Name="Parar Descarte", Callback=function()
        _G.IsDiscarding=false
        env.Window:Notify({Title="Farm",Content="Descarte parado.",Duration=2})
    end})
end
