return function(env)
    local LocalPlayer     = env.LocalPlayer
    local Remotes         = env.Remotes
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

    -- Find any tool by partial name match
    local function findToolByName(partialName)
        if not partialName or partialName == "" then return nil end
        local function search(parent)
            if not parent then return nil end
            for _, item in ipairs(parent:GetChildren()) do
                if item:IsA("Tool") and string.find(item.Name, partialName, 1, true) then
                    return item
                end
            end
            return nil
        end
        return search(LocalPlayer.Character) or search(LocalPlayer:FindFirstChild("Backpack"))
    end

    -- Count how many of a tool you have (handles (xN) format and attributes)
    local function countToolByName(partialName)
        if not partialName or partialName == "" then return 0 end
        local count = 0
        local function scan(parent)
            if not parent then return end
            for _, item in ipairs(parent:GetChildren()) do
                if item:IsA("Tool") and string.find(item.Name, partialName, 1, true) then
                    local n = string.match(item.Name, "%(x(%d+)%)")
                    if n then
                        count = count + tonumber(n)
                    else
                        local a = item:GetAttribute("Amount") or item:GetAttribute("Quantity") or item:GetAttribute("Uses")
                        if a and typeof(a) == "number" then
                            count = count + a
                        else
                            local v = item:FindFirstChild("Value") or item:FindFirstChild("Quantity") or item:FindFirstChild("Uses")
                            if v and (v:IsA("IntValue") or v:IsA("NumberValue")) then
                                count = count + v.Value
                            else
                                count = count + 1
                            end
                        end
                    end
                end
            end
        end
        scan(LocalPlayer.Character)
        scan(LocalPlayer:FindFirstChild("Backpack"))
        return count
    end

    local function findFertilizer(targetTypes)
        local function searchIn(parent)
            if not parent then return nil end
            for _, item in ipairs(parent:GetChildren()) do
                if item:IsA("Tool") then
                    for _, ftype in ipairs(env.FertilizerTypes or {}) do
                        if string.find(item.Name, ftype, 1, true) then
                            if not targetTypes or next(targetTypes) == nil then return item end
                            if targetTypes[ftype] then return item end
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
        if _G.MaxCompostInsertAmount and _G.MaxCompostInsertAmount > 0 then
            return math.min(available, _G.MaxCompostInsertAmount)
        end
        return available
    end

    local function clampInsertAmountForFloor(floor, available)
        local key = "F" .. floor .. "_MaxCompostInsertAmount"
        local max = _G[key] or 0
        if max > 0 then return math.min(available, max) end
        return available
    end

    local function getCompostInsertRemote()
        if Remotes and Remotes:FindFirstChild("Composter") and Remotes.Composter:FindFirstChild("InsertSeed") then
            return Remotes.Composter.InsertSeed
        end
        return nil
    end

    local function findCompostSeed(targetSeeds, targetMuts)
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if not bp then return nil end
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") and tool:GetAttribute("InventoryCategory") == "Seeds" then
                local plant    = tool:GetAttribute("Plant") or tool:GetAttribute("trueName")
                local mutation = tool:GetAttribute("Mutation") or "Normal"
                local skipSeed = targetSeeds and next(targetSeeds) ~= nil and not targetSeeds[plant]
                local skipMut  = targetMuts  and next(targetMuts)  ~= nil and not targetMuts[mutation]
                if not skipSeed and not skipMut then
                    return tool
                end
            end
        end
        return nil
    end

    -- Find compost seed for a floor using floor-specific rarity config
    local function findCompostSeedForFloor(floor, seedToRarity)
        local prefix = "F" .. floor .. "_"
        local byRarity    = _G[prefix .. "AutoCompostByRarity"]
        local bySelected  = _G[prefix .. "AutoCompostSelected"]
        local targetSeeds = _G[prefix .. "TargetCompostSeeds"] or {}
        local targetRarities = _G[prefix .. "TargetCompostRarities"] or {}
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if not bp then return nil end
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") and tool:GetAttribute("InventoryCategory") == "Seeds" then
                local plant    = tool:GetAttribute("Plant") or tool:GetAttribute("trueName")
                local mutation = tool:GetAttribute("Mutation") or "Normal"
                if plant then
                    local pass = true
                    if bySelected then
                        pass = targetSeeds[plant] == true
                    elseif byRarity then
                        if next(targetRarities) == nil then
                            pass = false
                        else
                            local rarity = seedToRarity and seedToRarity[plant]
                            pass = rarity ~= nil and targetRarities[rarity] == true
                        end
                    end
                    if pass then
                        local seedKey = tool:GetAttribute("seedKey")
                            or (tostring(plant) .. "_" .. tostring(tool:GetAttribute("Level") or 1) .. "_" .. tostring(mutation))
                        local qty = getSeedQuantity(tool)
                        local clamped = clampInsertAmountForFloor(floor, qty)
                        if clamped > 0 then return tool, seedKey, clamped end
                    end
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

    env.findSeedTool                = findSeedTool
    env.findToolByName              = findToolByName
    env.countToolByName             = countToolByName
    env.findFertilizer              = findFertilizer
    env.getSeedQuantity             = getSeedQuantity
    env.clampInsertAmount           = clampInsertAmount
    env.clampInsertAmountForFloor   = clampInsertAmountForFloor
    env.getCompostInsertRemote      = getCompostInsertRemote
    env.findCompostSeed             = findCompostSeed
    env.findCompostSeedForFloor     = findCompostSeedForFloor
    env.buyGear                     = buyGear
    env.buyEgg                      = buyEgg
end
