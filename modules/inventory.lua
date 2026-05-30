return function(env)
    local LP      = env.LocalPlayer
    local Remotes = env.Remotes
    local parseMoney  = env.parseMoney
    local haveMoney   = env.haveEnoughMoney

    local function findSeedTool(trueName)
        local char = LP.Character
        local hum  = char and char:FindFirstChild("Humanoid")
        if not hum then return nil end
        local eq = char:FindFirstChildWhichIsA("Tool")
        if eq and eq:GetAttribute("trueName")==trueName then return eq end
        local bp = LP:FindFirstChild("Backpack")
        if bp then
            for _,item in ipairs(bp:GetChildren()) do
                if item:IsA("Tool") and item:GetAttribute("trueName")==trueName then
                    hum:UnequipTools(); task.wait(0.1)
                    hum:EquipTool(item); task.wait(0.3)
                    return item
                end
            end
        end
        return nil
    end

    local function findToolByName(partial)
        if not partial or partial=="" then return nil end
        local function s(p)
            if not p then return nil end
            for _,i in ipairs(p:GetChildren()) do
                if i:IsA("Tool") and string.find(i.Name,partial,1,true) then return i end
            end
        end
        return s(LP.Character) or s(LP:FindFirstChild("Backpack"))
    end

    local function countToolByName(partial)
        if not partial or partial=="" then return 0 end
        local count=0
        local function scan(p)
            if not p then return end
            for _,i in ipairs(p:GetChildren()) do
                if i:IsA("Tool") and string.find(i.Name,partial,1,true) then
                    local n=string.match(i.Name,"%(x(%d+)%)")
                    if n then count=count+tonumber(n)
                    else
                        local a=i:GetAttribute("Amount") or i:GetAttribute("Quantity") or i:GetAttribute("Uses")
                        if a and typeof(a)=="number" then count=count+a
                        else
                            local v=i:FindFirstChild("Value") or i:FindFirstChild("Quantity")
                            if v and (v:IsA("IntValue") or v:IsA("NumberValue")) then count=count+v.Value
                            else count=count+1 end
                        end
                    end
                end
            end
        end
        scan(LP.Character); scan(LP:FindFirstChild("Backpack"))
        return count
    end

    local function findFertilizer(targetTypes)
        local function s(p)
            if not p then return nil end
            for _,item in ipairs(p:GetChildren()) do
                if item:IsA("Tool") then
                    for _,ft in ipairs(env.FertilizerTypes or {}) do
                        if string.find(item.Name,ft,1,true) then
                            if not targetTypes or next(targetTypes)==nil then return item end
                            if targetTypes[ft] then return item end
                        end
                    end
                end
            end
        end
        return s(LP.Character) or s(LP:FindFirstChild("Backpack"))
    end

    local function getSeedQuantity(tool)
        return tonumber(string.match(tool.Name,"%(x(%d+)%)")) or 1
    end

    local function clampInsertAmountForFloor(floor, available)
        local max = _G["F"..floor.."_MaxCompostInsertAmount"] or 0
        return max>0 and math.min(available,max) or available
    end

    local function findCompostSeedForFloor(floor, seedToRarity)
        local p      = "F"..floor.."_"
        local bySel  = _G[p.."AutoCompostSelected"]
        local byRar  = _G[p.."AutoCompostByRarity"]
        local tSeeds = _G[p.."TargetCompostSeeds"] or {}
        local tRars  = _G[p.."TargetCompostRarities"] or {}
        local bp     = LP:FindFirstChild("Backpack")
        if not bp then return nil end
        for _,tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") and tool:GetAttribute("InventoryCategory")=="Seeds" then
                local plant = tool:GetAttribute("Plant") or tool:GetAttribute("trueName")
                local mut   = tool:GetAttribute("Mutation") or "Normal"
                if plant then
                    local pass = true
                    if bySel then
                        pass = tSeeds[plant]==true
                    elseif byRar then
                        if next(tRars)==nil then pass=false
                        else
                            local r = seedToRarity and seedToRarity[plant]
                            pass = r~=nil and tRars[r]==true
                        end
                    end
                    if pass then
                        local key = tool:GetAttribute("seedKey")
                            or (plant.."_"..(tool:GetAttribute("Level") or 1).."_"..mut)
                        local qty     = getSeedQuantity(tool)
                        local clamped = clampInsertAmountForFloor(floor,qty)
                        if clamped>0 then return tool, key, clamped end
                    end
                end
            end
        end
        return nil
    end

    local function buyGear(gearName)
        if not Remotes or not Remotes:FindFirstChild("Gear") then return end
        local tr = Remotes.Gear:FindFirstChild("Transaction")
        if tr then tr:InvokeServer(gearName) end
    end

    local function buyEgg(slotInfo)
        if not slotInfo then return false end
        local sh = Remotes and Remotes:FindFirstChild("EggShop") and Remotes.EggShop:FindFirstChild("Transaction")
        local ro = Remotes and Remotes:FindFirstChild("RollEgg")
        if not sh or not ro then return false end
        pcall(function() sh:InvokeServer("BuyEgg",slotInfo.Slot) end)
        pcall(function() ro:FireServer(slotInfo.Name) end)
        task.wait(0.1)
        pcall(function() ro:FireServer(slotInfo.Name,"ClaimRolledPet") end)
        return true
    end

    env.findSeedTool               = findSeedTool
    env.findToolByName             = findToolByName
    env.countToolByName            = countToolByName
    env.findFertilizer             = findFertilizer
    env.getSeedQuantity            = getSeedQuantity
    env.clampInsertAmountForFloor  = clampInsertAmountForFloor
    env.findCompostSeedForFloor    = findCompostSeedForFloor
    env.buyGear                    = buyGear
    env.buyEgg                     = buyEgg
end
