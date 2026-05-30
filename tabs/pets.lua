return function(env)
    local T         = env.PetsTab
    local Lib       = env.Library
    local Remotes   = env.Remotes
    local LP        = env.LocalPlayer
    local findPlot  = env.findMyPlot

    -- Parse pet attributes from an instance
    local function parsePet(inst)
        if not inst then return nil end
        local petKey  = inst:GetAttribute("PetKey") or inst:GetAttribute("petKey")
        local petName = inst:GetAttribute("TrueName") or inst:GetAttribute("trueName")
                     or inst:GetAttribute("PetName")  or inst:GetAttribute("petName")
                     or inst.Name
        local level   = tonumber(inst:GetAttribute("PetLevel") or inst:GetAttribute("petLevel")
                     or inst:GetAttribute("Level") or inst:GetAttribute("level")) or 1
        local earn    = tonumber(inst:GetAttribute("EarningsMultiplier") or inst:GetAttribute("earningsMultiplier")
                     or inst:GetAttribute("Earnings") or inst:GetAttribute("earnings")) or 0
        return {instance=inst, petKey=petKey, petName=petName, level=level, earnings=earn}
    end

    -- Pets deployed on the player's plot
    local function getPlotPets()
        local result = {}
        local plot = findPlot()
        if not plot then return result end
        for _, child in ipairs(plot:GetChildren()) do
            if string.sub(child.Name, 1, 4) == "Pet_" then
                local pet = parsePet(child)
                if pet then
                    if not pet.petKey then
                        local parts = string.split(child.Name, "_")
                        pet.petKey = parts[#parts]
                    end
                    table.insert(result, pet)
                end
            end
        end
        return result
    end

    -- Pets in inventory (Character + Backpack)
    local function getInventoryPets()
        local result, seen = {}, {}
        local function scan(parent)
            if not parent then return end
            for _, item in ipairs(parent:GetChildren()) do
                if item:IsA("Tool") then
                    local pet = parsePet(item)
                    if pet and pet.petKey and not seen[pet.petKey] then
                        seen[pet.petKey] = true
                        table.insert(result, pet)
                    end
                end
            end
        end
        scan(LP.Character)
        scan(LP:FindFirstChild("Backpack"))
        return result
    end

    -- Available pet treat names from GearStocks
    local function getTreatTypes()
        local treats = {}
        local gs = game:GetService("ReplicatedStorage"):FindFirstChild("GearStocks")
        local ps = gs and gs:FindFirstChild(LP.Name)
        if ps then
            for _, item in ipairs(ps:GetChildren()) do
                if string.find(item.Name, "Treat", 1, true) then
                    table.insert(treats, item.Name)
                end
            end
        end
        table.sort(treats)
        return treats
    end

    -- Unequip all plot pets
    local function unequipAll()
        local remote = Remotes:FindFirstChild("Pets") and Remotes.Pets:FindFirstChild("UnequipPet")
        if not remote then return false end
        local pets = getPlotPets()
        for _, pet in ipairs(pets) do
            for _ = 1, 5 do pcall(function() remote:FireServer(pet.petKey) end); task.wait(0.1) end
        end
        return true
    end

    -- ================================================================
    -- LEFT: Pet Management
    -- ================================================================
    local ManageBox = T:AddLeftGroupbox("Pet Management")

    ManageBox:AddButton({
        Text = "Unequip All Pets  [double-click]", DoubleClick = true,
        Func = function()
            task.spawn(function()
                local pets = getPlotPets()
                if #pets == 0 then Lib:Notify("No pets on plot.", 2); return end
                if not unequipAll() then Lib:Notify("UnequipPet remote not found.", 3); return end
                Lib:Notify("Unequipped " .. #pets .. " pet(s).", 3)
            end)
        end,
    })

    ManageBox:AddButton({
        Text = "Equip 3 Best Earnings Pets",
        Func = function()
            task.spawn(function()
                local invPets = getInventoryPets()
                if #invPets == 0 then Lib:Notify("No pets in inventory.", 2); return end
                local equipRemote = Remotes:FindFirstChild("Pets") and Remotes.Pets:FindFirstChild("EquipPet")
                if not equipRemote then Lib:Notify("EquipPet remote not found.", 3); return end
                local hum = LP.Character and LP.Character:FindFirstChild("Humanoid")
                if not hum then Lib:Notify("Character not found.", 2); return end
                unequipAll(); task.wait(0.5)
                table.sort(invPets, function(a, b) return a.earnings > b.earnings end)
                local count = 0
                for i = 1, math.min(3, #invPets) do
                    local pet = invPets[i]
                    -- Teleport to floor i position first
                    pcall(function()
                        if env.teleportDestinations and env.teleportDestinations[i] then
                            local cf = env.getDestinationCFrame and env.getDestinationCFrame(env.teleportDestinations[i])
                            if cf then env.teleportToCFrame(cf); task.wait(0.3) end
                        end
                    end)
                    hum:EquipTool(pet.instance); task.wait(0.3)
                    pcall(function() equipRemote:FireServer() end)
                    count = count + 1; task.wait(0.3)
                end
                Lib:Notify("Equipped " .. count .. " best pet(s).", 3)
            end)
        end,
    })

    -- ================================================================
    -- RIGHT: Pet Feeding
    -- ================================================================
    local FeedBox = T:AddRightGroupbox("Pet Feeding")

    local treatTypes = getTreatTypes()
    FeedBox:AddDropdown("PetTreatSelect", {
        Values = #treatTypes > 0 and treatTypes or {"No treats found"},
        Default = {}, Multi = true,
        Text = "Select Treats",
        Callback = function(val)
            _G.TargetPetTreatNames = {}
            if type(val) == "table" then
                for _, v in pairs(val) do _G.TargetPetTreatNames[v] = true end
            elseif val and val ~= "" then
                _G.TargetPetTreatNames[val] = true
            end
        end,
    })

    FeedBox:AddButton({
        Text = "Refresh Treat List",
        Func = function()
            local fresh = getTreatTypes()
            pcall(function() Options.PetTreatSelect:SetValues(#fresh > 0 and fresh or {"No treats found"}) end)
            Lib:Notify("Treat list refreshed.", 2)
        end,
    })

    local feedRunning = false
    FeedBox:AddToggle("AutoFeedPets", {
        Text = "Auto Feed Pets", Default = false,
        Callback = function(val)
            _G.AutoFeedPets = val
            if not val or feedRunning then return end
            feedRunning = true
            task.spawn(function()
                while _G.AutoFeedPets do
                    pcall(function()
                        local remote = Remotes:FindFirstChild("UsePetTreat")
                        if not remote then return end
                        local hum = LP.Character and LP.Character:FindFirstChild("Humanoid")
                        if not hum then return end
                        local pets = getPlotPets()
                        if #pets == 0 then return end
                        if next(_G.TargetPetTreatNames) == nil then return end
                        for treatName in pairs(_G.TargetPetTreatNames) do
                            local treatTool = nil
                            local function findTreat(parent)
                                if not parent then return end
                                for _, item in ipairs(parent:GetChildren()) do
                                    if item:IsA("Tool") and string.find(item.Name, treatName, 1, true) then
                                        treatTool = item; return
                                    end
                                end
                            end
                            findTreat(LP.Character); findTreat(LP:FindFirstChild("Backpack"))
                            if treatTool then
                                hum:EquipTool(treatTool); task.wait(0.3)
                                for _, pet in ipairs(pets) do
                                    if not _G.AutoFeedPets then break end
                                    pcall(function() remote:FireServer(pet.instance) end)
                                    task.wait(0.5)
                                end
                            end
                        end
                    end)
                    task.wait(3)
                end
                feedRunning = false
            end)
        end,
    })

    -- ================================================================
    -- LEFT: Pet Upgrade
    -- ================================================================
    local UpgBox = T:AddLeftGroupbox("Pet Upgrade")

    UpgBox:AddInput("PetMaxLevel", {
        Default = "10", Numeric = true, Finished = true,
        Text = "Max Upgrade Level",
        Callback = function(val)
            local n = tonumber(val)
            _G.TargetPetUpgradeLevel = (n and n >= 1) and math.floor(n) or 10
        end,
    })

    local upgradeRunning = false
    UpgBox:AddToggle("AutoUpgradePets", {
        Text = "Auto Upgrade Pets", Default = false,
        Callback = function(val)
            _G.AutoUpgradePets = val
            if not val or upgradeRunning then return end
            upgradeRunning = true
            task.spawn(function()
                while _G.AutoUpgradePets do
                    pcall(function()
                        local remote = Remotes:FindFirstChild("Pets") and Remotes.Pets:FindFirstChild("UpgradePet")
                        if not remote then return end
                        local pets = getPlotPets()
                        local maxLvl = _G.TargetPetUpgradeLevel or 10
                        for _, pet in ipairs(pets) do
                            if not _G.AutoUpgradePets then break end
                            if pet.level < maxLvl then
                                if remote:IsA("RemoteFunction") then
                                    pcall(function() remote:InvokeServer(pet.petKey) end)
                                else
                                    pcall(function() remote:FireServer(pet.petKey) end)
                                end
                                task.wait(0.1)
                            end
                        end
                    end)
                    task.wait(2)
                end
                upgradeRunning = false
            end)
        end,
    })

    -- ================================================================
    -- RIGHT: Pet Sell
    -- ================================================================
    local SellBox = T:AddRightGroupbox("Pet Sell")

    local function getAvailablePets()
        local names, seen = {}, {}
        local assets = game:GetService("ReplicatedStorage"):FindFirstChild("Assets")
        if assets then
            local pf = assets:FindFirstChild("Pets")
            if pf then
                for _, p in ipairs(pf:GetChildren()) do
                    if not seen[p.Name] then seen[p.Name] = true; table.insert(names, p.Name) end
                end
            end
        end
        table.sort(names)
        return #names > 0 and names or {"No pets found"}
    end

    SellBox:AddDropdown("PetSellSelect", {
        Values = getAvailablePets(), Default = {}, Multi = true,
        Text = "Select Pets to Sell",
        Callback = function(val)
            _G.TargetPetSellNames = {}
            if type(val) == "table" then
                for _, v in pairs(val) do _G.TargetPetSellNames[v] = true end
            elseif val and val ~= "" then
                _G.TargetPetSellNames[val] = true
            end
        end,
    })

    local sellRunning = false
    SellBox:AddToggle("AutoSellPets", {
        Text = "Auto Sell Selected Pets", Default = false,
        Callback = function(val)
            _G.AutoSellPets = val
            if not val or sellRunning then return end
            sellRunning = true
            task.spawn(function()
                while _G.AutoSellPets do
                    pcall(function()
                        local remote = Remotes:FindFirstChild("SellPet")
                        if not remote then return end
                        local invPets = getInventoryPets()
                        if next(_G.TargetPetSellNames) == nil then return end
                        for _, pet in ipairs(invPets) do
                            if not _G.AutoSellPets then break end
                            local eligible = false
                            if next(_G.TargetPetSellNames) ~= nil then
                                local lname = string.lower(pet.petName or "")
                                for target in pairs(_G.TargetPetSellNames) do
                                    if string.find(lname, string.lower(target), 1, true) then
                                        eligible = true; break
                                    end
                                end
                            end
                            if eligible then
                                pcall(function() remote:InvokeServer(pet.petKey) end)
                                task.wait(0.1)
                            end
                        end
                    end)
                    task.wait(2)
                end
                sellRunning = false
            end)
        end,
    })
end
