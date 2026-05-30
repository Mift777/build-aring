return function(env)
    local rarityWeights = {
        Common=1, Uncommon=2, Rare=3, Epic=4, Legendary=5,
        Secret=6, Prismatic=7, Divine=8, Exotic=9, Transcended=10
    }

    -- Compost machine config per floor
    local compostCfg = {
        [2] = {pullLeverId=2, machineName="CompostMachine"},
        [3] = {pullLeverId=3, machineName="CompostMachineTier2"},
    }

    local function matchesTarget(plantName, targetSet)
        if not plantName or plantName == "" then return false end
        if next(targetSet) == nil then return true end
        if targetSet[plantName] then return true end
        local lname = string.lower(plantName)
        for entry in pairs(targetSet) do
            if entry then
                local entryName = string.match(tostring(entry), "%] (.+)") or entry
                if string.lower(entryName) == lname then return true end
            end
        end
        return false
    end

    env.buildFloorTab = function(_, floor, T)
        local Lib            = env.Library
        local Remotes        = env.Remotes
        local LP             = env.LocalPlayer
        local getFloorPlot   = env.getFloorFarmPlot
        local getAllDirt      = env.getAllDirt
        local findSeed       = env.findSeedTool
        local findTool       = env.findToolByName
        local countTool      = env.countToolByName
        local haveMoney      = env.haveEnoughMoney
        local allSeeds       = env.getIndexSeeds
        local getMuts        = env.getMutationList
        local buildRarity    = env.buildRarityMaps
        local findCmptSeed   = env.findCompostSeedForFloor

        local P = "F" .. floor .. "_"

        -- Build rarity maps
        local seedEntries = {}; pcall(function() seedEntries = allSeeds() or {} end)
        local sortedRarities, seedToRarity = {}, {}
        pcall(function() sortedRarities, seedToRarity = buildRarity(seedEntries) end)

        local seedList = #seedEntries > 0 and seedEntries or {"None"}
        local mutList = {"Normal"}; pcall(function() mutList = getMuts() or mutList end)
        local sprayList = env.SprayTypes or {}
        local mutListNoNormal = {}
        for _, m in ipairs(mutList) do if m ~= "Normal" then table.insert(mutListNoNormal, m) end end

        -- ========================================================
        -- LEFT: Plants
        -- ========================================================
        local PlantsBox = T:AddLeftGroupbox("Plants [F" .. floor .. "]")
        local statusLabel = PlantsBox:AddLabel("Status: loading...")

        -- Auto-update plant status
        task.spawn(function()
            while true do
                task.wait(1.5)
                pcall(function()
                    local fp = getFloorPlot(floor)
                    if not fp then statusLabel:SetText("Plot not found."); return end
                    local dirts = getAllDirt(fp)
                    local planted = 0
                    for _, d in ipairs(dirts) do if d:GetAttribute("PlantLevel") ~= nil then planted = planted + 1 end end
                    statusLabel:SetText(string.format("Planted: %d / %d", planted, #dirts))
                end)
            end
        end)

        PlantsBox:AddDropdown(P .. "RaritySelect", {
            Values = sortedRarities, Default = {}, Multi = true,
            Text = "Target Rarities (Auto Plant)",
            Callback = function(val)
                _G[P .. "TargetAutoPlantRarities"] = {}
                if type(val) == "table" then
                    for _, r in pairs(val) do _G[P .. "TargetAutoPlantRarities"][r] = true end
                elseif val and val ~= "" then
                    _G[P .. "TargetAutoPlantRarities"][val] = true
                end
            end,
        })

        local autoPlantRunning = false
        PlantsBox:AddToggle(P .. "AutoPlant", {
            Text = "Auto Plant by Rarity", Default = false,
            Callback = function(val)
                _G[P .. "AutoPlantByRarity"] = val
                if not val or autoPlantRunning then return end
                autoPlantRunning = true
                task.spawn(function()
                    while _G[P .. "AutoPlantByRarity"] do
                        pcall(function()
                            local fp = getFloorPlot(floor)
                            if not fp then return end
                            local emptyDirts = {}
                            for _, child in ipairs(fp:GetChildren()) do
                                if string.match(child.Name, "^Plot%d+$") then
                                    local dirt = child:FindFirstChild("Dirt")
                                    if dirt and dirt:GetAttribute("PlantLevel") == nil then
                                        table.insert(emptyDirts, dirt)
                                    end
                                end
                            end
                            if #emptyDirts == 0 then return end
                            local targetRarities = _G[P .. "TargetAutoPlantRarities"] or {}
                            local function getBestSeed()
                                local candidates = {}
                                for _, cont in ipairs({LP.Character, LP:FindFirstChild("Backpack")}) do
                                    if cont then
                                        for _, item in ipairs(cont:GetChildren()) do
                                            if item:IsA("Tool") and item:GetAttribute("InventoryCategory") == "Seeds" then
                                                local tn = item:GetAttribute("trueName")
                                                if tn then
                                                    local r = seedToRarity[tn]
                                                    if r and (next(targetRarities) == nil or targetRarities[r]) then
                                                        table.insert(candidates, {name=tn, weight=rarityWeights[r] or 0})
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                                if #candidates > 0 then
                                    table.sort(candidates, function(a, b) return a.weight > b.weight end)
                                    return candidates[1].name
                                end
                                return nil
                            end
                            for _, dirt in ipairs(emptyDirts) do
                                if not _G[P .. "AutoPlantByRarity"] then break end
                                if dirt:GetAttribute("PlantLevel") == nil then
                                    local seedName = getBestSeed()
                                    if seedName then
                                        local tool = findSeed(seedName)
                                        if tool then
                                            pcall(function() Remotes.PlantSeed:FireServer(dirt) end)
                                            task.wait(0.2)
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

        PlantsBox:AddButton({
            Text = "Remove All Plants  [double-click]", DoubleClick = true,
            Func = function()
                task.spawn(function()
                    Lib:Notify("Removing F" .. floor .. " plants...", 5)
                    local fp = getFloorPlot(floor)
                    if not fp then Lib:Notify("Plot not found.", 3); return end
                    for _, d in ipairs(getAllDirt(fp)) do
                        if d:GetAttribute("PlantLevel") ~= nil then
                            pcall(function() Remotes.RemovePlant:FireServer(d) end)
                            task.wait(0.3)
                        end
                    end
                    Lib:Notify("Done.", 2)
                end)
            end,
        })

        -- ========================================================
        -- RIGHT: Plant Upgrade
        -- ========================================================
        local UpgBox = T:AddRightGroupbox("Plant Upgrade [F" .. floor .. "]")

        UpgBox:AddDropdown(P .. "UpgradePlants", {
            Values = seedList, Default = {}, Multi = true,
            Text = "Target Plants (empty = all)",
            Callback = function(val)
                _G.FloorUpgradeConfig[floor].TargetPlantNames = {}
                if type(val) == "table" then
                    for _, v in pairs(val) do _G.FloorUpgradeConfig[floor].TargetPlantNames[v] = true end
                elseif val and val ~= "" then
                    _G.FloorUpgradeConfig[floor].TargetPlantNames[val] = true
                end
            end,
        })

        UpgBox:AddInput(P .. "MaxUpgLevel", {
            Default = "10", Numeric = true, Finished = true,
            Text = "Max Upgrade Level",
            Callback = function(val)
                local n = tonumber(val)
                _G.FloorUpgradeConfig[floor].MaxLevel = (n and n >= 1) and math.floor(n) or 10
            end,
        })

        local upgradeRunning = false
        local function startUpgradeLoop()
            if upgradeRunning then return end
            upgradeRunning = true
            task.spawn(function()
                while _G.FloorUpgradeConfig[floor].AutoUpgrade or _G.FloorUpgradeConfig[floor].AutoAll do
                    pcall(function()
                        local fp = getFloorPlot(floor)
                        if not fp then return end
                        local cfg = _G.FloorUpgradeConfig[floor]
                        for _, dirt in ipairs(getAllDirt(fp)) do
                            if not (cfg.AutoUpgrade or cfg.AutoAll) then break end
                            local level = dirt:GetAttribute("PlantLevel")
                            if level then
                                local plantName = dirt:GetAttribute("PlantName") or ""
                                local shouldUpg = cfg.AutoAll or matchesTarget(plantName, cfg.TargetPlantNames)
                                if shouldUpg and level < (cfg.MaxLevel or 10) then
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
                upgradeRunning = false
            end)
        end

        UpgBox:AddToggle(P .. "AutoUpgradeSelected", {
            Text = "Auto Upgrade Selected", Default = false,
            Callback = function(val)
                _G.FloorUpgradeConfig[floor].AutoUpgrade = val
                if val then
                    _G.FloorUpgradeConfig[floor].AutoAll = false
                    pcall(function() Options[P .. "AutoUpgradeAll"]:SetValue(false) end)
                    startUpgradeLoop()
                end
            end,
        })

        UpgBox:AddToggle(P .. "AutoUpgradeAll", {
            Text = "Auto Upgrade ALL", Default = false,
            Callback = function(val)
                _G.FloorUpgradeConfig[floor].AutoAll = val
                if val then
                    _G.FloorUpgradeConfig[floor].AutoUpgrade = false
                    pcall(function() Options[P .. "AutoUpgradeSelected"]:SetValue(false) end)
                    startUpgradeLoop()
                end
            end,
        })

        -- ========================================================
        -- LEFT: Fertilization
        -- ========================================================
        local FertBox = T:AddLeftGroupbox("Fertilization [F" .. floor .. "]")

        FertBox:AddDropdown(P .. "FertPlants", {
            Values = seedList, Default = {}, Multi = true,
            Text = "Target Plants (empty = all)",
            Callback = function(val)
                _G.FloorFertilizeConfig[floor].TargetPlantNames = {}
                if type(val) == "table" then
                    for _, v in pairs(val) do _G.FloorFertilizeConfig[floor].TargetPlantNames[v] = true end
                elseif val and val ~= "" then
                    _G.FloorFertilizeConfig[floor].TargetPlantNames[val] = true
                end
            end,
        })

        FertBox:AddDropdown(P .. "FertTypes", {
            Values = env.FertilizerTypes or {}, Default = {}, Multi = true,
            Text = "Fertilizer Type (empty = any)",
            Callback = function(val)
                _G.FloorFertilizeConfig[floor].TargetFertilizerTypes = {}
                if type(val) == "table" then
                    for _, v in pairs(val) do _G.FloorFertilizeConfig[floor].TargetFertilizerTypes[v] = true end
                elseif val and val ~= "" then
                    _G.FloorFertilizeConfig[floor].TargetFertilizerTypes[val] = true
                end
            end,
        })

        local fertRunning = false
        local function startFertLoop()
            if fertRunning then return end
            fertRunning = true
            task.spawn(function()
                while _G.FloorFertilizeConfig[floor].AutoFertilize or _G.FloorFertilizeConfig[floor].AutoAll do
                    pcall(function()
                        local fp = getFloorPlot(floor)
                        if not fp then return end
                        local cfg = _G.FloorFertilizeConfig[floor]
                        local fertTool = env.findFertilizer and env.findFertilizer(cfg.TargetFertilizerTypes)
                        if not fertTool then return end
                        local hum = LP.Character and LP.Character:FindFirstChild("Humanoid")
                        if not hum then return end
                        for _, dirt in ipairs(getAllDirt(fp)) do
                            if not (cfg.AutoFertilize or cfg.AutoAll) then break end
                            if dirt:GetAttribute("PlantLevel") ~= nil and not dirt:GetAttribute("Fertilized") then
                                local plantName = dirt:GetAttribute("PlantName") or ""
                                local shouldFert = cfg.AutoAll or matchesTarget(plantName, cfg.TargetPlantNames)
                                if shouldFert then
                                    hum:EquipTool(fertTool); task.wait(0.1)
                                    pcall(function() Remotes.UseFertilizer:FireServer(dirt) end)
                                    task.wait(0.1)
                                    hum:UnequipTools()
                                    break
                                end
                            end
                        end
                    end)
                    task.wait(2)
                end
                fertRunning = false
            end)
        end

        FertBox:AddToggle(P .. "AutoFertSelected", {
            Text = "Auto Fertilize Selected", Default = false,
            Callback = function(val)
                _G.FloorFertilizeConfig[floor].AutoFertilize = val
                if val then
                    _G.FloorFertilizeConfig[floor].AutoAll = false
                    pcall(function() Options[P .. "AutoFertAll"]:SetValue(false) end)
                    startFertLoop()
                end
            end,
        })

        FertBox:AddToggle(P .. "AutoFertAll", {
            Text = "Auto Fertilize ALL", Default = false,
            Callback = function(val)
                _G.FloorFertilizeConfig[floor].AutoAll = val
                if val then
                    _G.FloorFertilizeConfig[floor].AutoFertilize = false
                    pcall(function() Options[P .. "AutoFertSelected"]:SetValue(false) end)
                    startFertLoop()
                end
            end,
        })

        -- ========================================================
        -- RIGHT: Spray
        -- ========================================================
        local SprayBox = T:AddRightGroupbox("Spray [F" .. floor .. "]")

        local sprayTargetPlants, sprayType = {}, nil
        local acidTargetPlants, acidMutations = {}, {}

        SprayBox:AddDropdown(P .. "SprayPlants", {
            Values = seedList, Default = {}, Multi = true,
            Text = "Target Plants (unmutated only)",
            Callback = function(val)
                sprayTargetPlants = {}
                if type(val) == "table" then for _, v in pairs(val) do sprayTargetPlants[v] = true end
                elseif val and val ~= "" then sprayTargetPlants[val] = true end
            end,
        })

        SprayBox:AddDropdown(P .. "SprayType", {
            Values = sprayList, Default = 1,
            Text = "Spray Type",
            Callback = function(val) sprayType = val end,
        })

        SprayBox:AddButton({
            Text = "Run Spray",
            Func = function()
                if not sprayType or sprayType == "" then Lib:Notify("Select a spray type!", 3); return end
                if next(sprayTargetPlants) == nil then Lib:Notify("Select target plants!", 3); return end
                task.spawn(function()
                    local fp = getFloorPlot(floor)
                    if not fp then Lib:Notify("Plot not found!", 3); return end
                    local remote = Remotes:FindFirstChild("UseSpray")
                    if not remote then Lib:Notify("UseSpray remote not found!", 3); return end
                    local tool = findTool(sprayType)
                    if not tool then Lib:Notify(sprayType .. " not in inventory!", 3); return end
                    local owned = countTool(sprayType)
                    local targets = {}
                    for _, d in ipairs(getAllDirt(fp)) do
                        local plant = d:GetAttribute("PlantName") or ""
                        local mut = d:GetAttribute("PlantMutation") or "Normal"
                        if matchesTarget(plant, sprayTargetPlants) and (mut == "Normal" or mut == "None" or mut == "") then
                            table.insert(targets, d)
                        end
                    end
                    Lib:Notify(string.format("Spraying %d plants (owned: %d)", math.min(owned, #targets), owned), 4)
                    if #targets == 0 or owned <= 0 then return end
                    local hum = LP.Character and LP.Character:FindFirstChild("Humanoid")
                    if not hum then return end
                    hum:EquipTool(tool); task.wait(0.25)
                    for i = 1, math.min(owned, #targets) do
                        pcall(function() remote:FireServer(targets[i]) end)
                        task.wait(1)
                    end
                    hum:UnequipTools()
                    Lib:Notify("Spray done!", 2)
                end)
            end,
        })

        SprayBox:AddDivider()

        SprayBox:AddDropdown(P .. "AcidPlants", {
            Values = seedList, Default = {}, Multi = true,
            Text = "Acid: Target Plants",
            Callback = function(val)
                acidTargetPlants = {}
                if type(val) == "table" then for _, v in pairs(val) do acidTargetPlants[v] = true end
                elseif val and val ~= "" then acidTargetPlants[val] = true end
            end,
        })

        SprayBox:AddDropdown(P .. "AcidMutations", {
            Values = mutListNoNormal, Default = {}, Multi = true,
            Text = "Acid: Mutations to Clear",
            Callback = function(val)
                acidMutations = {}
                if type(val) == "table" then for _, v in pairs(val) do acidMutations[v] = true end
                elseif val and val ~= "" then acidMutations[val] = true end
            end,
        })

        SprayBox:AddButton({
            Text = "Run Acid Spray (Clear Mutations)",
            Func = function()
                if next(acidTargetPlants) == nil then Lib:Notify("Select target plants!", 3); return end
                if next(acidMutations) == nil then Lib:Notify("Select mutations to clear!", 3); return end
                task.spawn(function()
                    local fp = getFloorPlot(floor)
                    if not fp then Lib:Notify("Plot not found!", 3); return end
                    local remote = Remotes:FindFirstChild("UseSpray")
                    if not remote then Lib:Notify("UseSpray remote not found!", 3); return end
                    local tool = findTool("Acid Spray")
                    if not tool then Lib:Notify("Acid Spray not in inventory!", 3); return end
                    local owned = countTool("Acid Spray")
                    local targets = {}
                    for _, d in ipairs(getAllDirt(fp)) do
                        local plant = d:GetAttribute("PlantName") or ""
                        local mut = d:GetAttribute("PlantMutation") or "Normal"
                        if matchesTarget(plant, acidTargetPlants) and mut ~= "Normal" and mut ~= "None" and mut ~= "" then
                            if acidMutations[mut] then table.insert(targets, d) end
                        end
                    end
                    Lib:Notify(string.format("Clearing %d mutations (owned: %d Acid)", math.min(owned, #targets), owned), 4)
                    if #targets == 0 or owned <= 0 then return end
                    local hum = LP.Character and LP.Character:FindFirstChild("Humanoid")
                    if not hum then return end
                    hum:EquipTool(tool); task.wait(0.25)
                    for i = 1, math.min(owned, #targets) do
                        pcall(function() remote:FireServer(targets[i]) end)
                        task.wait(1)
                    end
                    hum:UnequipTools()
                    Lib:Notify("Acid spray done!", 2)
                end)
            end,
        })

        -- ========================================================
        -- COMPOST (Floor 2 and 3 only)
        -- ========================================================
        if floor >= 2 and compostCfg[floor] then
            local cfg = compostCfg[floor]

            local CompBox = T:AddLeftGroupbox("Composter [F" .. floor .. "]")

            CompBox:AddDropdown(P .. "CompostSeeds", {
                Values = seedList, Default = {}, Multi = true,
                Text = "Select Seeds (Auto Compost Selected)",
                Callback = function(val)
                    _G[P .. "TargetCompostSeeds"] = {}
                    if type(val) == "table" then
                        for _, v in pairs(val) do
                            local n = string.match(v, "%] (.+)") or v
                            _G[P .. "TargetCompostSeeds"][n] = true
                        end
                    elseif val and val ~= "" then
                        local n = string.match(val, "%] (.+)") or val
                        _G[P .. "TargetCompostSeeds"][n] = true
                    end
                end,
            })

            CompBox:AddDropdown(P .. "CompostRarities", {
                Values = sortedRarities, Default = {}, Multi = true,
                Text = "Select Rarities (Auto Compost by Rarity)",
                Callback = function(val)
                    _G[P .. "TargetCompostRarities"] = {}
                    if type(val) == "table" then
                        for _, r in pairs(val) do _G[P .. "TargetCompostRarities"][r] = true end
                    elseif val and val ~= "" then
                        _G[P .. "TargetCompostRarities"][val] = true
                    end
                end,
            })

            CompBox:AddInput(P .. "CompostDelay", {
                Default = "60", Numeric = true, Finished = true,
                Text = "Insert Delay (seconds)",
                Callback = function(val)
                    local n = tonumber(val)
                    _G[P .. "CompostInsertDelay"] = (n and n >= 1) and math.floor(n) or 60
                end,
            })

            CompBox:AddInput(P .. "CompostMaxInsert", {
                Default = "0", Numeric = true, Finished = true,
                Text = "Max Seeds Per Insert (0 = all)",
                Callback = function(val)
                    local n = tonumber(val)
                    _G[P .. "MaxCompostInsertAmount"] = (n and n >= 0 and n % 1 == 0) and math.floor(n) or 0
                end,
            })

            CompBox:AddDivider()

            local compostRunning = false
            local function startCompostLoop()
                if compostRunning then return end
                compostRunning = true
                task.spawn(function()
                    while _G[P .. "AutoCompostSelected"] or _G[P .. "AutoCompostByRarity"] do
                        pcall(function()
                            local r = Remotes:FindFirstChild("Composter") and Remotes.Composter:FindFirstChild("InsertSeed")
                            if not r then return end
                            local tool, seedKey, qty = findCmptSeed(floor, seedToRarity)
                            if tool and seedKey and qty and qty > 0 then
                                r:InvokeServer(floor, seedKey, qty)
                            end
                        end)
                        task.wait(_G[P .. "CompostInsertDelay"] or 60)
                    end
                    compostRunning = false
                end)
            end

            CompBox:AddToggle(P .. "AutoCompostSelected", {
                Text = "Auto Compost Selected", Default = false,
                Callback = function(val)
                    _G[P .. "AutoCompostSelected"] = val
                    if val then
                        _G[P .. "AutoCompostByRarity"] = false
                        pcall(function() Options[P .. "AutoCompostByRarity"]:SetValue(false) end)
                        startCompostLoop()
                    end
                end,
            })

            CompBox:AddToggle(P .. "AutoCompostByRarity", {
                Text = "Auto Compost by Rarity", Default = false,
                Callback = function(val)
                    _G[P .. "AutoCompostByRarity"] = val
                    if val then
                        _G[P .. "AutoCompostSelected"] = false
                        pcall(function() Options[P .. "AutoCompostSelected"]:SetValue(false) end)
                        startCompostLoop()
                    end
                end,
            })

            CompBox:AddButton({
                Text = "Manual Insert (once)",
                Func = function()
                    local r = Remotes:FindFirstChild("Composter") and Remotes.Composter:FindFirstChild("InsertSeed")
                    if not r then Lib:Notify("Composter remote not found.", 3); return end
                    local tool, seedKey, qty = findCmptSeed(floor, seedToRarity)
                    if not tool then Lib:Notify("No matching seed found.", 3); return end
                    pcall(function() r:InvokeServer(floor, seedKey, qty) end)
                    Lib:Notify("Inserted " .. tostring(qty) .. " seed(s).", 2)
                end,
            })

            CompBox:AddDivider()

            CompBox:AddInput(P .. "PullLeverDelay", {
                Default = "60", Numeric = true, Finished = true,
                Text = "Pull Lever Delay (seconds)",
                Callback = function(val)
                    local n = tonumber(val)
                    _G[P .. "PullLeverDelay"] = (n and n >= 1) and math.floor(n) or 60
                end,
            })

            local leverRunning = false
            CompBox:AddToggle(P .. "AutoPullLever", {
                Text = "Auto Pull Lever", Default = false,
                Callback = function(val)
                    _G[P .. "AutoPullLever"] = val
                    if not val or leverRunning then return end
                    leverRunning = true
                    task.spawn(function()
                        while _G[P .. "AutoPullLever"] do
                            pcall(function()
                                local r = Remotes:FindFirstChild("Composter") and Remotes.Composter:FindFirstChild("PullLever")
                                if r then r:InvokeServer(cfg.pullLeverId) end
                            end)
                            task.wait(_G[P .. "PullLeverDelay"] or 60)
                        end
                        leverRunning = false
                    end)
                end,
            })
        end -- end compost section
    end -- end buildFloorTab
end
