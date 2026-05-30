return function(env)
    local rarityW = {Common=1,Uncommon=2,Rare=3,Epic=4,Legendary=5,
                     Secret=6,Prismatic=7,Divine=8,Exotic=9,Transcended=10}
    local compostCfg = {
        [2]={pullLeverId=2},
        [3]={pullLeverId=3},
    }

    local function matchesTarget(name, targetSet)
        if not name or name=="" then return false end
        if next(targetSet)==nil then return true end
        if targetSet[name] then return true end
        local lname = string.lower(name)
        for entry in pairs(targetSet) do
            local en = string.match(tostring(entry),"%] (.+)") or entry
            if string.lower(en)==lname then return true end
        end
        return false
    end

    env.buildFloorTab = function(_, floor, T)
        local Remotes   = env.Remotes
        local LP        = env.LocalPlayer
        local getPlot   = env.getFloorFarmPlot
        local getDirt   = env.getAllDirt
        local findSeed  = env.findSeedTool
        local findTool  = env.findToolByName
        local countTool = env.countToolByName
        local haveMoney = env.haveEnoughMoney
        local allSeeds  = env.getIndexSeeds
        local buildRar  = env.buildRarityMaps
        local findCmpt  = env.findCompostSeedForFloor

        local P = "F"..floor.."_"
        local seedEntries = {}; pcall(function() seedEntries=allSeeds() or {} end)
        local sortedRar, seedToRar = {}, {}
        pcall(function() sortedRar, seedToRar = buildRar(seedEntries) end)
        local seedList = #seedEntries>0 and seedEntries or {"None"}
        local mutList  = {"Normal"}; pcall(function() mutList=env.getMutationList() or mutList end)
        local mutNoNormal = {}
        for _,m in ipairs(mutList) do if m~="Normal" then table.insert(mutNoNormal,m) end end
        local sprayList = env.SprayTypes or {}

        -- ── PLANTS ──────────────────────────────────────────────
        T:CreateSection("Plantas [F"..floor.."]")

        local statusLabel = T:CreateLabel("Status: aguardando...")
        task.spawn(function()
            while true do
                task.wait(2)
                pcall(function()
                    local fp = getPlot(floor)
                    if not fp then statusLabel:Set("Plot não encontrado"); return end
                    local dirts = getDirt(fp)
                    local planted = 0
                    for _,d in ipairs(dirts) do
                        if d:GetAttribute("PlantLevel") then planted=planted+1 end
                    end
                    statusLabel:Set(string.format("Plantados: %d / %d", planted, #dirts))
                end)
            end
        end)

        T:CreateDropdown({
            Name = "Raridades Alvo (Auto Plant)",
            Options = sortedRar,
            CurrentOption = {},
            MultipleOptions = true,
            Flag = P.."RaritySelect",
            Callback = function(opts)
                _G[P.."TargetAutoPlantRarities"] = {}
                for _,r in ipairs(opts) do _G[P.."TargetAutoPlantRarities"][r]=true end
            end,
        })

        local autoPlantRunning = false
        T:CreateToggle({
            Name = "Auto Plant por Raridade",
            CurrentValue = false,
            Flag = P.."AutoPlant",
            Callback = function(val)
                _G[P.."AutoPlantByRarity"] = val
                if not val or autoPlantRunning then return end
                autoPlantRunning = true
                task.spawn(function()
                    while _G[P.."AutoPlantByRarity"] do
                        pcall(function()
                            local fp = getPlot(floor)
                            if not fp then return end
                            local emptyDirts = {}
                            for _,child in ipairs(fp:GetChildren()) do
                                if string.match(child.Name,"^Plot%d+$") then
                                    local dirt = child:FindFirstChild("Dirt")
                                    if dirt and not dirt:GetAttribute("PlantLevel") then
                                        table.insert(emptyDirts,dirt)
                                    end
                                end
                            end
                            if #emptyDirts==0 then return end
                            local targetRar = _G[P.."TargetAutoPlantRarities"] or {}
                            local function getBest()
                                local cands={}
                                for _,cont in ipairs({LP.Character,LP:FindFirstChild("Backpack")}) do
                                    if cont then
                                        for _,item in ipairs(cont:GetChildren()) do
                                            if item:IsA("Tool") and item:GetAttribute("InventoryCategory")=="Seeds" then
                                                local tn = item:GetAttribute("trueName")
                                                if tn then
                                                    local r=seedToRar[tn]
                                                    if r and (next(targetRar)==nil or targetRar[r]) then
                                                        table.insert(cands,{name=tn,weight=rarityW[r] or 0})
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                                if #cands>0 then
                                    table.sort(cands,function(a,b) return a.weight>b.weight end)
                                    return cands[1].name
                                end
                                return nil
                            end
                            for _,dirt in ipairs(emptyDirts) do
                                if not _G[P.."AutoPlantByRarity"] then break end
                                if not dirt:GetAttribute("PlantLevel") then
                                    local sn = getBest()
                                    if sn then
                                        local t = findSeed(sn)
                                        if t then pcall(function() Remotes.PlantSeed:FireServer(dirt) end); task.wait(0.2)
                                        else break end
                                    else break end
                                end
                            end
                        end)
                        task.wait(30)
                    end
                    autoPlantRunning = false
                end)
            end,
        })

        T:CreateButton({
            Name = "Remover Todas Plantas",
            Callback = function()
                task.spawn(function()
                    local fp = getPlot(floor)
                    if not fp then return end
                    for _,d in ipairs(getDirt(fp)) do
                        if d:GetAttribute("PlantLevel") then
                            pcall(function() Remotes.RemovePlant:FireServer(d) end)
                            task.wait(0.3)
                        end
                    end
                    env.Window:Notify({Title="F"..floor,Content="Plantas removidas!",Duration=2})
                end)
            end,
        })

        -- ── UPGRADE ─────────────────────────────────────────────
        T:CreateSection("Upgrade Plantas [F"..floor.."]")

        T:CreateDropdown({
            Name = "Plantas Alvo (vazio = todas)",
            Options = seedList,
            CurrentOption = {},
            MultipleOptions = true,
            Flag = P.."UpgradePlants",
            Callback = function(opts)
                _G.FloorUpgradeConfig[floor].TargetPlantNames = {}
                for _,v in ipairs(opts) do _G.FloorUpgradeConfig[floor].TargetPlantNames[v]=true end
            end,
        })

        T:CreateInput({
            Name = "Nível Máximo Upgrade",
            CurrentValue = "10",
            PlaceholderText = "10",
            RemoveTextAfterFocusLost = false,
            Flag = P.."MaxUpgLevel",
            Callback = function(val)
                local n = tonumber(val)
                _G.FloorUpgradeConfig[floor].MaxLevel = (n and n>=1) and math.floor(n) or 10
            end,
        })

        local upgRunning = false
        local function startUpgLoop()
            if upgRunning then return end
            upgRunning = true
            task.spawn(function()
                while _G.FloorUpgradeConfig[floor].AutoUpgrade or _G.FloorUpgradeConfig[floor].AutoAll do
                    pcall(function()
                        local fp  = getPlot(floor)
                        if not fp then return end
                        local cfg = _G.FloorUpgradeConfig[floor]
                        for _,dirt in ipairs(getDirt(fp)) do
                            if not (cfg.AutoUpgrade or cfg.AutoAll) then break end
                            local lvl = dirt:GetAttribute("PlantLevel")
                            if lvl then
                                local pn = dirt:GetAttribute("PlantName") or ""
                                local should = cfg.AutoAll or matchesTarget(pn,cfg.TargetPlantNames)
                                if should and lvl<(cfg.MaxLevel or 10) then
                                    local price = dirt:GetAttribute("UpgradePrice") or 0
                                    if haveMoney(price) then
                                        pcall(function() Remotes.UpgradePlant:InvokeServer(dirt) end)
                                        task.wait(0.1)
                                    end
                                end
                            end
                        end
                    end)
                    task.wait(0.1)
                end
                upgRunning = false
            end)
        end

        T:CreateToggle({Name="Auto Upgrade Selecionadas",CurrentValue=false,Flag=P.."AutoUpgSel",
            Callback=function(val)
                _G.FloorUpgradeConfig[floor].AutoUpgrade=val
                if val then _G.FloorUpgradeConfig[floor].AutoAll=false; startUpgLoop() end
            end})
        T:CreateToggle({Name="Auto Upgrade TODAS",CurrentValue=false,Flag=P.."AutoUpgAll",
            Callback=function(val)
                _G.FloorUpgradeConfig[floor].AutoAll=val
                if val then _G.FloorUpgradeConfig[floor].AutoUpgrade=false; startUpgLoop() end
            end})

        -- ── FERTILIZAR ──────────────────────────────────────────
        T:CreateSection("Fertilização [F"..floor.."]")

        T:CreateDropdown({
            Name="Plantas Alvo Fertilização",Options=seedList,CurrentOption={},MultipleOptions=true,
            Flag=P.."FertPlants",
            Callback=function(opts)
                _G.FloorFertilizeConfig[floor].TargetPlantNames={}
                for _,v in ipairs(opts) do _G.FloorFertilizeConfig[floor].TargetPlantNames[v]=true end
            end})

        T:CreateDropdown({
            Name="Tipo Fertilizante",Options=env.FertilizerTypes or {},CurrentOption={},MultipleOptions=true,
            Flag=P.."FertTypes",
            Callback=function(opts)
                _G.FloorFertilizeConfig[floor].TargetFertilizerTypes={}
                for _,v in ipairs(opts) do _G.FloorFertilizeConfig[floor].TargetFertilizerTypes[v]=true end
            end})

        local fertRunning = false
        local function startFertLoop()
            if fertRunning then return end
            fertRunning = true
            task.spawn(function()
                while _G.FloorFertilizeConfig[floor].AutoFertilize or _G.FloorFertilizeConfig[floor].AutoAll do
                    pcall(function()
                        local fp  = getPlot(floor)
                        if not fp then return end
                        local cfg = _G.FloorFertilizeConfig[floor]
                        local ft  = env.findFertilizer and env.findFertilizer(cfg.TargetFertilizerTypes)
                        if not ft then return end
                        local hum = LP.Character and LP.Character:FindFirstChild("Humanoid")
                        if not hum then return end
                        for _,dirt in ipairs(getDirt(fp)) do
                            if not (cfg.AutoFertilize or cfg.AutoAll) then break end
                            if dirt:GetAttribute("PlantLevel") and not dirt:GetAttribute("Fertilized") then
                                local pn = dirt:GetAttribute("PlantName") or ""
                                local should = cfg.AutoAll or matchesTarget(pn,cfg.TargetPlantNames)
                                if should then
                                    hum:EquipTool(ft); task.wait(0.1)
                                    pcall(function() Remotes.UseFertilizer:FireServer(dirt) end)
                                    task.wait(0.1); hum:UnequipTools(); break
                                end
                            end
                        end
                    end)
                    task.wait(2)
                end
                fertRunning=false
            end)
        end

        T:CreateToggle({Name="Auto Fertilizar Selecionadas",CurrentValue=false,Flag=P.."AutoFertSel",
            Callback=function(val)
                _G.FloorFertilizeConfig[floor].AutoFertilize=val
                if val then _G.FloorFertilizeConfig[floor].AutoAll=false; startFertLoop() end
            end})
        T:CreateToggle({Name="Auto Fertilizar TODAS",CurrentValue=false,Flag=P.."AutoFertAll",
            Callback=function(val)
                _G.FloorFertilizeConfig[floor].AutoAll=val
                if val then _G.FloorFertilizeConfig[floor].AutoFertilize=false; startFertLoop() end
            end})

        -- ── SPRAY ───────────────────────────────────────────────
        T:CreateSection("Spray [F"..floor.."]")

        local sprayTargets, sprayType = {}, nil
        local acidTargets, acidMuts   = {}, {}

        T:CreateDropdown({Name="Plantas Alvo Spray",Options=seedList,CurrentOption={},MultipleOptions=true,
            Flag=P.."SprayPlants",
            Callback=function(opts) sprayTargets={}; for _,v in ipairs(opts) do sprayTargets[v]=true end end})

        T:CreateDropdown({Name="Tipo de Spray",Options=sprayList,CurrentOption={},MultipleOptions=false,
            Flag=P.."SprayType",
            Callback=function(opts) sprayType=opts[1] or nil end})

        T:CreateButton({Name="Executar Spray",Callback=function()
            if not sprayType then
                env.Window:Notify({Title="Spray",Content="Selecione um tipo de spray!",Duration=3}); return
            end
            task.spawn(function()
                local fp = getPlot(floor); if not fp then return end
                local remote = Remotes:FindFirstChild("UseSpray"); if not remote then return end
                local tool   = findTool(sprayType); if not tool then
                    env.Window:Notify({Title="Spray",Content=sprayType.." não no inventário!",Duration=3}); return
                end
                local owned   = countTool(sprayType)
                local targets = {}
                for _,d in ipairs(getDirt(fp)) do
                    local pn  = d:GetAttribute("PlantName") or ""
                    local mut = d:GetAttribute("PlantMutation") or "Normal"
                    if matchesTarget(pn,sprayTargets) and (mut=="Normal" or mut=="None" or mut=="") then
                        table.insert(targets,d)
                    end
                end
                if #targets==0 or owned<=0 then
                    env.Window:Notify({Title="Spray",Content="Sem alvos ou spray insuficiente.",Duration=3}); return
                end
                local hum = LP.Character and LP.Character:FindFirstChild("Humanoid")
                if not hum then return end
                hum:EquipTool(tool); task.wait(0.25)
                for i=1,math.min(owned,#targets) do
                    pcall(function() remote:FireServer(targets[i]) end); task.wait(1)
                end
                hum:UnequipTools()
                env.Window:Notify({Title="Spray",Content="Spray concluído!",Duration=2})
            end)
        end})

        -- Acid Spray
        T:CreateDropdown({Name="Acid: Plantas Alvo",Options=seedList,CurrentOption={},MultipleOptions=true,
            Flag=P.."AcidPlants",
            Callback=function(opts) acidTargets={}; for _,v in ipairs(opts) do acidTargets[v]=true end end})
        T:CreateDropdown({Name="Acid: Mutações para Remover",Options=mutNoNormal,CurrentOption={},MultipleOptions=true,
            Flag=P.."AcidMuts",
            Callback=function(opts) acidMuts={}; for _,v in ipairs(opts) do acidMuts[v]=true end end})
        T:CreateButton({Name="Executar Acid Spray",Callback=function()
            task.spawn(function()
                local fp = getPlot(floor); if not fp then return end
                local remote = Remotes:FindFirstChild("UseSpray"); if not remote then return end
                local tool   = findTool("Acid Spray"); if not tool then
                    env.Window:Notify({Title="Acid",Content="Acid Spray não encontrado!",Duration=3}); return
                end
                local owned   = countTool("Acid Spray")
                local targets = {}
                for _,d in ipairs(getDirt(fp)) do
                    local pn  = d:GetAttribute("PlantName") or ""
                    local mut = d:GetAttribute("PlantMutation") or "Normal"
                    if matchesTarget(pn,acidTargets) and mut~="Normal" and mut~="None" and mut~="" and acidMuts[mut] then
                        table.insert(targets,d)
                    end
                end
                if #targets==0 or owned<=0 then return end
                local hum = LP.Character and LP.Character:FindFirstChild("Humanoid")
                if not hum then return end
                hum:EquipTool(tool); task.wait(0.25)
                for i=1,math.min(owned,#targets) do
                    pcall(function() remote:FireServer(targets[i]) end); task.wait(1)
                end
                hum:UnequipTools()
                env.Window:Notify({Title="Acid",Content="Mutações removidas!",Duration=2})
            end)
        end})

        -- ── COMPOST (F2 e F3 apenas) ────────────────────────────
        if floor>=2 and compostCfg[floor] then
            local cfg = compostCfg[floor]
            T:CreateSection("Composter [F"..floor.."]")

            T:CreateDropdown({Name="Seeds (Auto Compost Selecionadas)",Options=seedList,CurrentOption={},MultipleOptions=true,
                Flag=P.."CompostSeeds",
                Callback=function(opts)
                    _G[P.."TargetCompostSeeds"]={}
                    for _,v in ipairs(opts) do
                        local n=string.match(v,"%] (.+)") or v
                        _G[P.."TargetCompostSeeds"][n]=true
                    end
                end})

            T:CreateDropdown({Name="Raridades (Auto Compost por Raridade)",Options=sortedRar,CurrentOption={},MultipleOptions=true,
                Flag=P.."CompostRarities",
                Callback=function(opts)
                    _G[P.."TargetCompostRarities"]={}
                    for _,r in ipairs(opts) do _G[P.."TargetCompostRarities"][r]=true end
                end})

            T:CreateInput({Name="Delay Inserção (seg)",CurrentValue="60",PlaceholderText="60",
                RemoveTextAfterFocusLost=false,Flag=P.."CompostDelay",
                Callback=function(val)
                    local n=tonumber(val); _G[P.."CompostInsertDelay"]=(n and n>=1) and math.floor(n) or 60
                end})

            T:CreateInput({Name="Máx Seeds por Inserção (0=todos)",CurrentValue="0",PlaceholderText="0",
                RemoveTextAfterFocusLost=false,Flag=P.."CompostMax",
                Callback=function(val)
                    local n=tonumber(val); _G[P.."MaxCompostInsertAmount"]=(n and n>=0) and math.floor(n) or 0
                end})

            local cmptRunning = false
            local function startCmptLoop()
                if cmptRunning then return end
                cmptRunning=true
                task.spawn(function()
                    while _G[P.."AutoCompostSelected"] or _G[P.."AutoCompostByRarity"] do
                        pcall(function()
                            local r = Remotes:FindFirstChild("Composter") and Remotes.Composter:FindFirstChild("InsertSeed")
                            if not r then return end
                            local tool, key, qty = findCmpt(floor, seedToRar)
                            if tool and key and qty and qty>0 then
                                r:InvokeServer(floor, key, qty)
                            end
                        end)
                        task.wait(_G[P.."CompostInsertDelay"] or 60)
                    end
                    cmptRunning=false
                end)
            end

            T:CreateToggle({Name="Auto Compost Selecionadas",CurrentValue=false,Flag=P.."AutoCmptSel",
                Callback=function(val)
                    _G[P.."AutoCompostSelected"]=val
                    if val then _G[P.."AutoCompostByRarity"]=false; startCmptLoop() end
                end})
            T:CreateToggle({Name="Auto Compost por Raridade",CurrentValue=false,Flag=P.."AutoCmptRar",
                Callback=function(val)
                    _G[P.."AutoCompostByRarity"]=val
                    if val then _G[P.."AutoCompostSelected"]=false; startCmptLoop() end
                end})
            T:CreateButton({Name="Inserir Agora (1x)",Callback=function()
                local r = Remotes:FindFirstChild("Composter") and Remotes.Composter:FindFirstChild("InsertSeed")
                if not r then env.Window:Notify({Title="Compost",Content="Remote não encontrado",Duration=3}); return end
                local tool,key,qty = findCmpt(floor,seedToRar)
                if not tool then env.Window:Notify({Title="Compost",Content="Nenhuma seed encontrada",Duration=3}); return end
                pcall(function() r:InvokeServer(floor,key,qty) end)
                env.Window:Notify({Title="Compost",Content="Inseriu "..qty.." seed(s)",Duration=2})
            end})

            T:CreateInput({Name="Delay Pull Lever (seg)",CurrentValue="60",PlaceholderText="60",
                RemoveTextAfterFocusLost=false,Flag=P.."LeverDelay",
                Callback=function(val)
                    local n=tonumber(val); _G[P.."PullLeverDelay"]=(n and n>=1) and math.floor(n) or 60
                end})

            local levRunning=false
            T:CreateToggle({Name="Auto Pull Lever",CurrentValue=false,Flag=P.."AutoLever",
                Callback=function(val)
                    _G[P.."AutoPullLever"]=val
                    if not val or levRunning then return end
                    levRunning=true
                    task.spawn(function()
                        while _G[P.."AutoPullLever"] do
                            pcall(function()
                                local r = Remotes:FindFirstChild("Composter") and Remotes.Composter:FindFirstChild("PullLever")
                                if r then r:InvokeServer(cfg.pullLeverId) end
                            end)
                            task.wait(_G[P.."PullLeverDelay"] or 60)
                        end
                        levRunning=false
                    end)
                end})
        end
    end
end
