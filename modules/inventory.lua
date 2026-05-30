return function(env)
    local LocalPlayer     = env.LocalPlayer
    local Remotes         = env.Remotes
    local FertilizerTypes = env.FertilizerTypes
    local parseMoney      = env.parseMoney
    local haveEnoughMoney = env.haveEnoughMoney
    local getGearPrice    = env.getGearPriceFromGui

    local function findSeedTool(trueName)
        local char = LocalPlayer.Character
        if not char then return nil end
        local hum = char:FindFirstChild("Humanoid")
        if not hum then return nil end
        local equipped = char:FindFirstChildWhichIsA("Tool")
        if equipped and equipped:GetAttribute("InventoryCategory") == "Seeds" and equipped:GetAttribute("trueName") == trueName then
            return equipped
        end
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp then
            for _, item in ipairs(bp:GetChildren()) do
                if item:IsA("Tool") and item:GetAttribute("InventoryCategory") == "Seeds" and item:GetAttribute("trueName") == trueName then
                    hum:UnequipTools()
                    task.wait(0.1)
                    hum:EquipTool(item)
                    return item
                end
            end
        end
        return nil
    end

    local function findFertilizer()
        local function searchIn(parent)
            if not parent then return nil end
            for _, item in ipairs(parent:GetChildren()) do
                if item:IsA("Tool") then
                    for _, ftype in ipairs(FertilizerTypes) do
                        if string.find(item.Name, ftype, 1, true) then
                            local use = true
                            if next(_G.TargetFertilizerTypes) ~= nil then
                                use = _G.TargetFertilizerTypes[ftype] ~= nil
                            end
                            if use then return item end
                        end
                    end
                end
            end
            return nil
        end
        return searchIn(LocalPlayer.Character) or searchIn(LocalPlayer:FindFirstChild("Backpack"))
    end

    local function getSeedQuantity(tool)
        return tonumber(string.match(tool.Name, "%(x(%d+)%)")) or 1
    end

    local function clampInsertAmount(available)
        if _G.MaxCompostInsertAmount > 0 then
            return math.min(available, _G.MaxCompostInsertAmount)
        end
        return available
    end

    local function getCompostInsertRemote()
        if Remotes and Remotes:FindFirstChild("Composter") and Remotes.Composter:FindFirstChild("InsertSeed") then
            return Remotes.Composter.InsertSeed
        end
        return nil
    end

    local function findCompostSeed()
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if not bp then return nil end
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") and tool:GetAttribute("InventoryCategory") == "Seeds" then
                local plant    = tool:GetAttribute("Plant") or tool:GetAttribute("trueName")
                local mutation = tool:GetAttribute("Mutation") or "Normal"
                local skipSeed = next(_G.TargetCompostSeeds) ~= nil and not _G.TargetCompostSeeds[plant]
                local skipMut  = next(_G.TargetCompostMutations) ~= nil and not _G.TargetCompostMutations[mutation]
                if not skipSeed and not skipMut then
                    return tool
                end
            end
        end
        return nil
    end

    local function buyGear(gearName)
        if not Remotes or not Remotes:FindFirstChild("Gear") or not Remotes.Gear:FindFirstChild("Transaction") then return end
        local price = parseMoney(getGearPrice(gearName))
        if haveEnoughMoney(price, "Gear", gearName) then
            Remotes.Gear.Transaction:InvokeServer(gearName)
        end
    end

    local function buyEgg(slotInfo)
        if not slotInfo or not slotInfo.Slot or not slotInfo.Name then return false end
        local shopRemote = Remotes and Remotes:FindFirstChild("EggShop") and Remotes.EggShop:FindFirstChild("Transaction")
        local rollRemote = Remotes and Remotes:FindFirstChild("RollEgg")
        if not shopRemote or not rollRemote then return false end
        local ok = pcall(function() shopRemote:InvokeServer("BuyEgg", slotInfo.Slot) end)
        if not ok then return false end
        pcall(function() rollRemote:FireServer(slotInfo.Name) end)
        task.wait(0.1)
        pcall(function() rollRemote:FireServer(slotInfo.Name, "ClaimRolledPet") end)
        print("[LamduckHub] EggShop | " .. slotInfo.Name .. " | slot: " .. slotInfo.Slot)
        return true
    end

    env.findSeedTool          = findSeedTool
    env.findFertilizer        = findFertilizer
    env.getSeedQuantity       = getSeedQuantity
    env.clampInsertAmount     = clampInsertAmount
    env.getCompostInsertRemote= getCompostInsertRemote
    env.findCompostSeed       = findCompostSeed
    env.buyGear               = buyGear
    env.buyEgg                = buyEgg
end
