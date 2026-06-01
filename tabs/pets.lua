return function(env)
    local T        = env.PetsTab
    local Remotes  = env.Remotes
    local LP       = env.LocalPlayer
    local findPlot = env.findMyPlot

    local function parsePet(inst)
        if not inst then return nil end
        local key  = inst:GetAttribute("PetKey") or inst:GetAttribute("petKey")
        local name = inst:GetAttribute("TrueName") or inst:GetAttribute("trueName") or inst.Name
        local level= tonumber(inst:GetAttribute("PetLevel") or inst:GetAttribute("Level")) or 1
        local earn = tonumber(inst:GetAttribute("EarningsMultiplier") or inst:GetAttribute("Earnings")) or 0
        return {instance=inst,petKey=key,petName=name,level=level,earnings=earn}
    end

    local function getPlotPets()
        local r={}; local plot=findPlot(); if not plot then return r end
        for _,c in ipairs(plot:GetChildren()) do
            if string.sub(c.Name,1,4)=="Pet_" then
                local pet=parsePet(c)
                if pet then
                    if not pet.petKey then
                        local parts=string.split(c.Name,"_"); pet.petKey=parts[#parts]
                    end
                    table.insert(r,pet)
                end
            end
        end
        return r
    end

    local function getInvPets()
        local r,seen={},{}
        local function scan(p)
            if not p then return end
            for _,i in ipairs(p:GetChildren()) do
                if i:IsA("Tool") then
                    local pet=parsePet(i)
                    if pet and pet.petKey and not seen[pet.petKey] then
                        seen[pet.petKey]=true; table.insert(r,pet)
                    end
                end
            end
        end
        scan(LP.Character); scan(LP:FindFirstChild("Backpack"))
        return r
    end

    local function getTreatTypes()
        local t={}
        local gs=game:GetService("ReplicatedStorage"):FindFirstChild("GearStocks")
        local ps=gs and gs:FindFirstChild(LP.Name)
        if ps then
            for _,item in ipairs(ps:GetChildren()) do
                if string.find(item.Name,"Treat",1,true) then table.insert(t,item.Name) end
            end
        end
        table.sort(t); return t
    end

    local function unequipAll()
        local r=Remotes:FindFirstChild("Pets") and Remotes.Pets:FindFirstChild("UnequipPet")
        if not r then return false end
        for _,pet in ipairs(getPlotPets()) do
            for _=1,5 do pcall(function() r:FireServer(pet.petKey) end); task.wait(0.1) end
        end
        return true
    end

    -- ── Gerenciar Pets ────────────────────────────────────────
    local SecMgr = T:CreateSection("Gerenciar Pets")

    SecMgr:AddButton({Name="Desequipar Todos Pets", Callback=function()
        task.spawn(function()
            local pets=getPlotPets()
            if #pets==0 then env.Window:Notify({Title="Pets",Content="Nenhum pet no plot.",Duration=2}); return end
            if not unequipAll() then env.Window:Notify({Title="Pets",Content="Remote não encontrado.",Duration=3}); return end
            env.Window:Notify({Title="Pets",Content="Desequipados "..#pets.." pets.",Duration=3})
        end)
    end})

    SecMgr:AddButton({Name="Equipar 3 Melhores Pets (Earnings)", Callback=function()
        task.spawn(function()
            local invPets=getInvPets()
            if #invPets==0 then env.Window:Notify({Title="Pets",Content="Sem pets no inventário.",Duration=2}); return end
            local eq=Remotes:FindFirstChild("Pets") and Remotes.Pets:FindFirstChild("EquipPet")
            if not eq then return end
            local hum=LP.Character and LP.Character:FindFirstChild("Humanoid")
            if not hum then return end
            unequipAll(); task.wait(0.5)
            table.sort(invPets,function(a,b) return a.earnings>b.earnings end)
            local count=0
            for i=1,math.min(3,#invPets) do
                local pet=invPets[i]
                hum:EquipTool(pet.instance); task.wait(0.3)
                pcall(function() eq:FireServer() end)
                count=count+1; task.wait(0.3)
            end
            env.Window:Notify({Title="Pets",Content="Equipados "..count.." pets.",Duration=3})
        end)
    end})

    -- ── Alimentar Pets ────────────────────────────────────────
    local SecFeed = T:CreateSection("Alimentar Pets")

    local treats=getTreatTypes()
    SecFeed:AddDropdown({Name="Selecionar Treats",
        Options=#treats>0 and treats or {"Nenhum encontrado"}, Multi=true,
        Callback=function(sel)
            _G.TargetPetTreatNames={}
            for v in pairs(sel) do _G.TargetPetTreatNames[v]=true end
        end})

    local feedRunning=false
    SecFeed:AddToggle({Name="Auto Alimentar Pets", Default=false,
        Callback=function(val)
            _G.AutoFeedPets=val
            if not val or feedRunning then return end; feedRunning=true
            task.spawn(function()
                while _G.AutoFeedPets do
                    pcall(function()
                        local r=Remotes:FindFirstChild("UsePetTreat"); if not r then return end
                        local hum=LP.Character and LP.Character:FindFirstChild("Humanoid"); if not hum then return end
                        local pets=getPlotPets(); if #pets==0 then return end
                        if next(_G.TargetPetTreatNames)==nil then return end
                        for tn in pairs(_G.TargetPetTreatNames) do
                            local tt=nil
                            local function ft(p)
                                if not p then return end
                                for _,i in ipairs(p:GetChildren()) do
                                    if i:IsA("Tool") and string.find(i.Name,tn,1,true) then tt=i; return end
                                end
                            end
                            ft(LP.Character); ft(LP:FindFirstChild("Backpack"))
                            if tt then
                                hum:EquipTool(tt); task.wait(0.3)
                                for _,pet in ipairs(pets) do
                                    if not _G.AutoFeedPets then break end
                                    pcall(function() r:FireServer(pet.instance) end); task.wait(0.5)
                                end
                            end
                        end
                    end)
                    task.wait(3)
                end
                feedRunning=false
            end)
        end})

    -- ── Upgrade Pets ──────────────────────────────────────────
    local SecUpg = T:CreateSection("Upgrade Pets")

    SecUpg:AddInput({Name="Nível Máximo", Placeholder="10",
        Callback=function(val)
            local n=tonumber(val); _G.TargetPetUpgradeLevel=(n and n>=1) and math.floor(n) or 10
        end})

    local upgRunning=false
    SecUpg:AddToggle({Name="Auto Upgrade Pets", Default=false,
        Callback=function(val)
            _G.AutoUpgradePets=val
            if not val or upgRunning then return end; upgRunning=true
            task.spawn(function()
                while _G.AutoUpgradePets do
                    pcall(function()
                        local r=Remotes:FindFirstChild("Pets") and Remotes.Pets:FindFirstChild("UpgradePet")
                        if not r then return end
                        local maxLvl=_G.TargetPetUpgradeLevel or 10
                        for _,pet in ipairs(getPlotPets()) do
                            if not _G.AutoUpgradePets then break end
                            if pet.level<maxLvl then
                                if r:IsA("RemoteFunction") then pcall(function() r:InvokeServer(pet.petKey) end)
                                else pcall(function() r:FireServer(pet.petKey) end) end
                                task.wait(0.1)
                            end
                        end
                    end)
                    task.wait(2)
                end
                upgRunning=false
            end)
        end})

    -- ── Vender Pets ───────────────────────────────────────────
    local SecSell = T:CreateSection("Vender Pets")

    local function getAvailPets()
        local names,seen={},{}
        local af=game:GetService("ReplicatedStorage"):FindFirstChild("Assets")
        if af then
            local pf=af:FindFirstChild("Pets")
            if pf then
                for _,p in ipairs(pf:GetChildren()) do
                    if not seen[p.Name] then seen[p.Name]=true; table.insert(names,p.Name) end
                end
            end
        end
        table.sort(names); return #names>0 and names or {"Nenhum"}
    end

    SecSell:AddDropdown({Name="Pets para Vender", Options=getAvailPets(), Multi=true,
        Callback=function(sel)
            _G.TargetPetSellNames={}
            for v in pairs(sel) do _G.TargetPetSellNames[v]=true end
        end})

    local sellRunning=false
    SecSell:AddToggle({Name="Auto Vender Pets Selecionados", Default=false,
        Callback=function(val)
            _G.AutoSellPets=val
            if not val or sellRunning then return end; sellRunning=true
            task.spawn(function()
                while _G.AutoSellPets do
                    pcall(function()
                        local r=Remotes:FindFirstChild("SellPet"); if not r then return end
                        if next(_G.TargetPetSellNames)==nil then return end
                        for _,pet in ipairs(getInvPets()) do
                            if not _G.AutoSellPets then break end
                            local lname=string.lower(pet.petName or ""); local elig=false
                            for t in pairs(_G.TargetPetSellNames) do
                                if string.find(lname,string.lower(t),1,true) then elig=true; break end
                            end
                            if elig then pcall(function() r:InvokeServer(pet.petKey) end); task.wait(0.1) end
                        end
                    end)
                    task.wait(2)
                end
                sellRunning=false
            end)
        end})
end
