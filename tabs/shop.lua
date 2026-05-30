return function(env)
    local T           = env.ShopTab
    local Lib         = env.Library
    local Remotes     = env.Remotes
    local LP          = env.LocalPlayer
    local allSeeds    = env.getIndexSeeds
    local getGears    = env.getAvailableGears
    local getEggTypes = env.getAvailableEggTypes
    local getCurrEggs = env.getCurrentEggSlots
    local getEggSlots = env.getEggSlotsInfo
    local getGearStk  = env.getGearStock
    local pMoney      = env.parseMoney
    local haveMoney   = env.haveEnoughMoney
    local findPlot    = env.findMyPlot
    local buyGear     = env.buyGear
    local buyEgg      = env.buyEgg
    local buildRarity = env.buildRarityMaps

    -- Build rarity maps for gacha
    local seedEntries = {}; pcall(function() seedEntries = allSeeds() or {} end)
    local sortedRarities, seedToRarity = {}, {}
    pcall(function() sortedRarities, seedToRarity = buildRarity(seedEntries) end)

    -- Gacha stand detection
    local function getStandPositions()
        local stands = {}
        local plot = findPlot()
        if plot then
            local roller = plot:FindFirstChild("SeedRoller")
            if roller then
                for i = 1, 6 do
                    local s = roller:FindFirstChild("Stand" .. i)
                    if s then stands[i] = s:GetPivot().Position end
                end
            end
        end
        return stands
    end

    local function getAvailableStands()
        local stands = getStandPositions()
        local avail = {}
        for _, m in ipairs(workspace:GetChildren()) do
            if m:IsA("Model") and m:FindFirstChild("BuySeed", true) then
                local mp = m:GetPivot().Position
                local nearIdx, minD = nil, math.huge
                for idx, pos in pairs(stands) do
                    local d = (Vector3.new(mp.X,0,mp.Z) - Vector3.new(pos.X,0,pos.Z)).Magnitude
                    if d < minD then minD = d; nearIdx = idx end
                end
                if nearIdx and minD < 15 then
                    local sg = m:FindFirstChild("SeedGui", true)
                    if sg then
                        for _, desc in ipairs(sg:GetDescendants()) do
                            if (desc:IsA("TextLabel") or desc:IsA("TextButton")) and string.find(tostring(desc.Text), "%$") then
                                avail[m.Name] = {standIdx=nearIdx, price=pMoney(desc.Text)}
                                break
                            end
                        end
                    end
                end
            end
        end
        return avail
    end

    local function shouldBuySeed(name)
        if _G.AutoRollAndBuyAll then return true end
        if _G.AutoRollAndBuySelected then
            if next(_G.TargetGachaSeeds) == nil then return false end
            return _G.TargetGachaSeeds[name] == true
        end
        if _G.AutoRollAndBuyByRarity then
            if next(_G.TargetGachaRarities) == nil then return false end
            local rarity = seedToRarity[name]
            return rarity ~= nil and _G.TargetGachaRarities[rarity] == true
        end
        return false
    end

    -- ================================================================
    -- LEFT: Seed Gacha
    -- ================================================================
    local GachaBox = T:AddLeftGroupbox("Seed Gacha (Roll & Buy)")

    local seedList = #seedEntries > 0 and seedEntries or {"None"}

    GachaBox:AddToggle("AutoRollBuyAll", {
        Text = "Auto Roll & Buy ALL Seeds", Default = false,
        Callback = function(val)
            _G.AutoRollAndBuyAll = val
            if val then
                _G.AutoRollAndBuySelected = false
                _G.AutoRollAndBuyByRarity = false
                pcall(function() Options.AutoRollBuySelected:SetValue(false) end)
                pcall(function() Options.AutoRollBuyByRarity:SetValue(false) end)
            end
        end,
    })

    GachaBox:AddDropdown("GachaSeeds", {
        Values = seedList, Default = {}, Multi = true,
        Text = "Seeds to Snipe (Selected)",
        Callback = function(val)
            _G.TargetGachaSeeds = {}
            if type(val) == "table" then
                for _, v in pairs(val) do
                    local n = string.match(v, "%] (.+)") or v
                    _G.TargetGachaSeeds[n] = true
                end
            elseif val and val ~= "" then
                local n = string.match(val, "%] (.+)") or val
                _G.TargetGachaSeeds[n] = true
            end
        end,
    })

    GachaBox:AddToggle("AutoRollBuySelected", {
        Text = "Auto Roll & Buy Selected Seeds", Default = false,
        Callback = function(val)
            _G.AutoRollAndBuySelected = val
            if val then
                _G.AutoRollAndBuyAll = false
                _G.AutoRollAndBuyByRarity = false
                pcall(function() Options.AutoRollBuyAll:SetValue(false) end)
                pcall(function() Options.AutoRollBuyByRarity:SetValue(false) end)
            end
        end,
    })

    GachaBox:AddDropdown("GachaRarities", {
        Values = sortedRarities, Default = {}, Multi = true,
        Text = "Rarities to Snipe",
        Callback = function(val)
            _G.TargetGachaRarities = {}
            if type(val) == "table" then
                for _, r in pairs(val) do _G.TargetGachaRarities[r] = true end
            elseif val and val ~= "" then
                _G.TargetGachaRarities[val] = true
            end
        end,
    })

    GachaBox:AddToggle("AutoRollBuyByRarity", {
        Text = "Auto Roll & Buy by Rarity", Default = false,
        Callback = function(val)
            _G.AutoRollAndBuyByRarity = val
            if val then
                _G.AutoRollAndBuyAll = false
                _G.AutoRollAndBuySelected = false
                pcall(function() Options.AutoRollBuyAll:SetValue(false) end)
                pcall(function() Options.AutoRollBuySelected:SetValue(false) end)
            end
        end,
    })

    -- Gacha main loop
    task.spawn(function()
        while true do
            if _G.AutoRollAndBuyAll or _G.AutoRollAndBuySelected or _G.AutoRollAndBuyByRarity then
                local avail = getAvailableStands()
                local bought = false
                for name, info in pairs(avail) do
                    if not (_G.AutoRollAndBuyAll or _G.AutoRollAndBuySelected or _G.AutoRollAndBuyByRarity) then break end
                    if shouldBuySeed(name) and haveMoney(info.price, "Seed", name) then
                        pcall(function() Remotes.BuySeed:FireServer(info.standIdx) end)
                        bought = true; task.wait(0.5)
                    end
                end
                if not bought then
                    -- Roll new seeds
                    pcall(function() Remotes.RollSeeds:FireServer() end)
                    task.wait(3.5)
                end
            end
            task.wait(0.5)
        end
    end)

    -- ================================================================
    -- RIGHT: Gear Shop
    -- ================================================================
    local GearBox = T:AddRightGroupbox("Gear Shop")

    local _, _, _, _ = nil, nil, nil, nil
    local allGears = {}
    pcall(function() allGears = getGears() or {} end)

    GearBox:AddToggle("AutoBuyAllGears", {
        Text = "Auto Buy All Available Gears", Default = false,
        Callback = function(val)
            _G.AutoBuyAllGears = val
            if val then
                _G.AutoBuySelectedGears = false
                pcall(function() Options.AutoBuySelectedGears:SetValue(false) end)
            end
            if not val then return end
            task.spawn(function()
                while _G.AutoBuyAllGears do
                    for _, gear in ipairs(allGears) do
                        if not _G.AutoBuyAllGears then break end
                        if getGearStk(gear) > 0 then
                            pcall(function() buyGear(gear) end); task.wait(0.1)
                        end
                    end
                    task.wait(0.5)
                end
            end)
        end,
    })

    local selectedGears = {}
    GearBox:AddDropdown("GearsToBuy", {
        Values = allGears, Default = {}, Multi = true,
        Text = "Select Gears to Buy",
        Callback = function(val)
            selectedGears = {}
            if type(val) == "table" then selectedGears = val
            elseif val and val ~= "" then selectedGears = {val} end
        end,
    })

    GearBox:AddToggle("AutoBuySelectedGears", {
        Text = "Auto Buy Selected Gears", Default = false,
        Callback = function(val)
            _G.AutoBuySelectedGears = val
            if val then
                _G.AutoBuyAllGears = false
                pcall(function() Options.AutoBuyAllGears:SetValue(false) end)
            end
            if not val then return end
            task.spawn(function()
                while _G.AutoBuySelectedGears do
                    for _, gear in ipairs(selectedGears) do
                        if not _G.AutoBuySelectedGears then break end
                        if getGearStk(gear) > 0 then
                            pcall(function() buyGear(gear) end); task.wait(0.1)
                        end
                    end
                    task.wait(0.5)
                end
            end)
        end,
    })

    -- ================================================================
    -- LEFT: Egg Shop
    -- ================================================================
    local EggBox = T:AddLeftGroupbox("Egg Shop")

    local eggTypes = {}; pcall(function() eggTypes = getEggTypes() or {} end)

    EggBox:AddToggle("AutoUnlockEggSlots", {
        Text = "Auto Unlock Egg Slots", Default = false,
        Callback = function(val)
            _G.AutoUnlockEggSlots = val
            if not val then return end
            task.spawn(function()
                while _G.AutoUnlockEggSlots do
                    pcall(function()
                        local r = Remotes:FindFirstChild("EggShop") and Remotes.EggShop:FindFirstChild("Transaction")
                        if not r then return end
                        local money = env.getCurrentMoney and env.getCurrentMoney() or 0
                        for _, slotInfo in ipairs(getEggSlots()) do
                            if not _G.AutoUnlockEggSlots then break end
                            local n = slotInfo.EggSlotNumber
                            if not _G.SessionUnlockedEggSlots[n] and haveMoney(slotInfo.UnlockPrice, "Egg Slot", "Slot " .. n) then
                                local ok = pcall(function() r:InvokeServer("UnlockSlot", n) end)
                                if ok then
                                    _G.SessionUnlockedEggSlots[n] = true
                                    task.wait(1.5)
                                    if not _G.SkipMoneyCheck then
                                        money = env.getCurrentMoney and env.getCurrentMoney() or 0
                                    end
                                end
                            end
                        end
                    end)
                    task.wait(5)
                end
            end)
        end,
    })

    EggBox:AddDropdown("EggsToBuy", {
        Values = eggTypes, Default = {}, Multi = true,
        Text = "Select Eggs to Buy",
        Callback = function(val)
            _G.TargetEggShopEggs = {}
            if type(val) == "table" then
                for _, v in pairs(val) do _G.TargetEggShopEggs[v] = true end
            elseif val and val ~= "" then
                _G.TargetEggShopEggs[val] = true
            end
        end,
    })

    EggBox:AddButton({Text="Refresh Egg List", Func=function()
        pcall(function()
            local fresh = getEggTypes()
            Options.EggsToBuy:SetValues(fresh)
        end)
        Lib:Notify("Egg list refreshed.", 2)
    end})

    local function startEggLoop()
        task.spawn(function()
            while _G.AutoBuySelectedEggs or _G.AutoBuyAllEggs do
                local slots = getCurrEggs()
                for _, slot in ipairs(slots) do
                    if not (_G.AutoBuySelectedEggs or _G.AutoBuyAllEggs) then break end
                    local eligible = _G.AutoBuyAllEggs or (_G.AutoBuySelectedEggs and _G.TargetEggShopEggs[slot.Name] == true)
                    if eligible then
                        pcall(function() buyEgg(slot) end); task.wait(0.2)
                    end
                end
                task.wait(1)
            end
        end)
    end

    EggBox:AddToggle("AutoBuySelectedEggs", {
        Text = "Auto Buy Selected Eggs", Default = false,
        Callback = function(val)
            _G.AutoBuySelectedEggs = val
            if val then
                _G.AutoBuyAllEggs = false
                pcall(function() Options.AutoBuyAllEggs:SetValue(false) end)
                startEggLoop()
            end
        end,
    })

    EggBox:AddToggle("AutoBuyAllEggs", {
        Text = "Auto Buy All Available Eggs", Default = false,
        Callback = function(val)
            _G.AutoBuyAllEggs = val
            if val then
                _G.AutoBuySelectedEggs = false
                pcall(function() Options.AutoBuySelectedEggs:SetValue(false) end)
                startEggLoop()
            end
        end,
    })
end
