return function(env)
    local T       = env.UtilsTab
    local LP      = env.LocalPlayer
    local Remotes = env.Remotes
    local findPlot= env.findMyPlot

    T:CreateSection("Teleporte")

    T:CreateButton({Name="Ir para Meu Plot",Callback=function()
        if env.teleportToMyPlot then env.teleportToMyPlot() end
    end})

    local dests = {
        {label="Floor 1", yOffset=5},
        {label="Floor 2 (SecondFloor)", yOffset=35},
        {label="Floor 3 (ThirdFloor)",  yOffset=70},
    }

    for _,dest in ipairs(dests) do
        T:CreateButton({Name="Teleportar: "..dest.label, Callback=function()
            local plot=findPlot()
            local hrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if plot and hrp then
                hrp.CFrame=plot:GetPivot()*CFrame.new(0,dest.yOffset,0)
            end
        end})
    end

    T:CreateSection("Configurações")

    T:CreateToggle({Name="Esconder Outros Plots",CurrentValue=false,Flag="HideOtherPlots",
        Callback=function(val)
            _G.HideOtherPlots=val
            local map=workspace:FindFirstChild("Map")
            local pf=map and map:FindFirstChild("Plots")
            local light=game:GetService("Lighting")
            if not pf then return end
            local myName=nil
            local plot=findPlot(); if plot then myName=plot.Name end
            if val then
                for _,p in ipairs(pf:GetChildren()) do
                    if p.Name~=myName then p.Parent=light end
                end
            else
                for _,p in ipairs(light:GetChildren()) do
                    if string.find(p.Name,"Plot") and p.Name~=myName then p.Parent=pf end
                end
            end
        end})

    T:CreateToggle({Name="Skip Money Check",CurrentValue=false,Flag="SkipMoney",
        Callback=function(val) _G.SkipMoneyCheck=val end})

    T:CreateSection("Rejoin")

    T:CreateButton({Name="Rejoin Server",Callback=function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
    end})
end
