-- tabs/shop.lua
return function(env)

    -- ==================== SHOP TAB ====================
    local GachaBox = env.ShopTab:AddLeftGroupbox("Seed Gacha")
    local GearBox  = env.ShopTab:AddRightGroupbox("Gear Shop")
    local EggBox   = env.ShopTab:AddLeftGroupbox("Egg Shop")

    -- Seed Gacha
    GachaBox:AddToggle("AutoRollBuyAll", {
        Text    = "Auto Roll & Buy ALL Seeds",
        Default = false,
        Callback = function(v) _G.AutoRollBuyAll = v end
    })

    local seedList = {"None"}
    local ok, seeds = pcall(function() return env.getIndexSeeds() end)
    if ok and seeds then for _, s in ipairs(seeds) do table.insert(seedList, s) end end

    GachaBox:AddDropdown("TargetSeedDrop", {
        Text    = "Target Seed",
        Values  = seedList,
        Default = 1,
        Callback = function(v) _G.TargetSeed = (v == "None") and nil or v end
    })

    GachaBox:AddToggle("AutoRollBuyTarget", {
        Text    = "Auto Roll & Buy Target Seed",
        Default = false,
        Callback = function(v) _G.AutoRollBuyTarget = v end
    })

    GachaBox:AddButton({
        Text = "Roll Once",
        Func = function()
            local stand = env.findNearestSeedStand and env.findNearestSeedStand()
            if not stand then print("[Shop] No seed stand found") return end
            local remote = env.Remotes and env.Remotes:FindFirstChild("RollSeed")
            if remote then remote:FireServer(stand) end
        end
    })

    -- Gear Shop
    GearBox:AddToggle("AutoBuyAllGear", {
        Text    = "Auto Buy All Available Gears",
        Default = false,
        Callback = function(v) _G.AutoBuyAllGear = v end
    })

    local gearList = {"None"}
    local ok2, gears = pcall(function() return env.getAvailableGears() end)
    if ok2 and gears then for _, g in ipairs(gears) do table.insert(gearList, g) end end

    GearBox:AddDropdown("TargetGearDrop", {
        Text    = "Target Gear",
        Values  = gearList,
        Default = 1,
        Callback = function(v) _G.TargetGear = (v == "None") and nil or v end
    })

    GearBox:AddToggle("AutoBuyTargetGear", {
        Text    = "Auto Buy Target Gear",
        Default = false,
        Callback = function(v) _G.AutoBuyTargetGear = v end
    })

    GearBox:AddButton({
        Text = "Buy All Gear Now",
        Func = function()
            local available = env.getAvailableGears and env.getAvailableGears() or {}
            for _, gearName in ipairs(available) do
                local stock = env.getGearStock and env.getGearStock(gearName) or 0
                if stock > 0 then
                    env.buyGear and env.buyGear(gearName)
                    task.wait(0.5)
                end
            end
        end
    })

    -- Egg Shop
    EggBox:AddToggle("AutoUnlockEggSlots", {
        Text    = "Auto Unlock Egg Slots",
        Default = false,
        Callback = function(v) _G.AutoUnlockEggSlots = v end
    })

    EggBox:AddToggle("AutoBuyAllEggs", {
        Text    = "Auto Buy All Eggs",
        Default = false,
        Callback = function(v) _G.AutoBuyAllEggs = v end
    })

    local eggTypeList = {"None"}
    local ok3, eggTypes = pcall(function() return env.getAvailableEggTypes() end)
    if ok3 and eggTypes then for _, e in ipairs(eggTypes) do table.insert(eggTypeList, e) end end

    EggBox:AddDropdown("TargetEggDrop", {
        Text    = "Target Egg Type",
        Values  = eggTypeList,
        Default = 1,
        Callback = function(v) _G.TargetEggType = (v == "None") and nil or v end
    })

    EggBox:AddToggle("AutoBuyTargetEgg", {
        Text    = "Auto Buy Target Egg",
        Default = false,
        Callback = function(v) _G.AutoBuyTargetEgg = v end
    })

    EggBox:AddButton({
        Text = "Buy All Eggs Now",
        Func = function()
            local available = env.getAvailableEggTypes and env.getAvailableEggTypes() or {}
            for _, eggType in ipairs(available) do
                env.buyEgg and env.buyEgg(eggType)
                task.wait(0.5)
            end
        end
    })

    -- ==================== STOCK TAB ====================
    if env.StockTab then
        local StockEggBox  = env.StockTab:AddLeftGroupbox("Egg Shop")
        local StockGearBox = env.StockTab:AddRightGroupbox("Gear Shop")

        local eggRestockLabel = StockEggBox:AddLabel("Restocks: ?")

        local eggLines = {}
        for i = 1, 6 do
            eggLines[i] = StockEggBox:AddLabel("")
        end

        local gearCountLabel = StockGearBox:AddLabel("In Stock: ?")

        local gearLines = {}
        for i = 1, 10 do
            gearLines[i] = StockGearBox:AddLabel("")
        end

        local function refreshStock()
            -- Egg restock timer
            local pm = workspace:FindFirstChild("PetMerchant")
            if pm then
                local sign = pm:FindFirstChild("MerchantSign")
                local sg   = sign and sign:FindFirstChildWhichIsA("SurfaceGui")
                local tl   = sg and sg:FindFirstChild("TimeLabel")
                eggRestockLabel:SetText("Restocks: " .. (tl and tl.Text or "?"))
            else
                eggRestockLabel:SetText("Restocks: (no merchant)")
            end

            -- Egg podiums
            local eggCount = 0
            for i = 1, 6 do
                local pod = pm and (
                    pm:FindFirstChild("Podium" .. i .. "Stock") or
                    pm:FindFirstChild("Podium" .. i)
                )
                local el = pod and pod:FindFirstChild("EggLabel",   true)
                local pl = pod and pod:FindFirstChild("PriceLabel", true)
                if el and el.Text ~= "" then
                    eggCount = eggCount + 1
                    if eggLines[eggCount] then
                        eggLines[eggCount]:SetText(
                            string.format("[%d] %s | %s", i, el.Text, pl and pl.Text or "?")
                        )
                    end
                end
            end
            for i = eggCount + 1, 6 do
                if eggLines[i] then eggLines[i]:SetText("") end
            end

            -- Gear stock
            local gearCount = 0
            if env.getAvailableGears and env.getGearStock and env.getGearPriceFromGui then
                for _, gearName in ipairs(env.getAvailableGears()) do
                    local stock = env.getGearStock(gearName)
                    if stock > 0 then
                        gearCount = gearCount + 1
                        if gearLines[gearCount] then
                            local price = env.getGearPriceFromGui(gearName)
                            gearLines[gearCount]:SetText(
                                string.format("[%dx] [%s] %s", stock, price, gearName)
                            )
                        end
                    end
                end
            end
            for i = gearCount + 1, 10 do
                if gearLines[i] then gearLines[i]:SetText("") end
            end
            gearCountLabel:SetText(
                gearCount == 0 and "No gear in stock" or ("In Stock (" .. gearCount .. "):")
            )
        end

        StockEggBox:AddButton({ Text = "Refresh", Func = refreshStock })

        task.spawn(function()
            task.wait(3)
            refreshStock()
        end)
    end

    -- ==================== AUTOMATION LOOPS ====================
    task.spawn(function()
        while task.wait(1) do
            -- Auto Roll & Buy All Seeds
            if _G.AutoRollBuyAll then
                local seeds2 = env.getIndexSeeds and env.getIndexSeeds() or {}
                for _, seedName in ipairs(seeds2) do
                    if not _G.AutoRollBuyAll then break end
                    env.buySeed and env.buySeed(seedName)
                    task.wait(0.5)
                end
            end

            -- Auto Roll & Buy Target Seed
            if _G.AutoRollBuyTarget and _G.TargetSeed then
                env.buySeed and env.buySeed(_G.TargetSeed)
                task.wait(0.5)
            end

            -- Auto Buy All Gear
            if _G.AutoBuyAllGear then
                local available = env.getAvailableGears and env.getAvailableGears() or {}
                for _, gearName in ipairs(available) do
                    if not _G.AutoBuyAllGear then break end
                    local stock = env.getGearStock and env.getGearStock(gearName) or 0
                    if stock > 0 then
                        env.buyGear and env.buyGear(gearName)
                        task.wait(0.5)
                    end
                end
            end

            -- Auto Buy Target Gear
            if _G.AutoBuyTargetGear and _G.TargetGear then
                local stock = env.getGearStock and env.getGearStock(_G.TargetGear) or 0
                if stock > 0 then
                    env.buyGear and env.buyGear(_G.TargetGear)
                    task.wait(0.5)
                end
            end

            -- Auto Buy All Eggs
            if _G.AutoBuyAllEggs then
                local available = env.getAvailableEggTypes and env.getAvailableEggTypes() or {}
                for _, eggType in ipairs(available) do
                    if not _G.AutoBuyAllEggs then break end
                    env.buyEgg and env.buyEgg(eggType)
                    task.wait(0.5)
                end
            end

            -- Auto Buy Target Egg
            if _G.AutoBuyTargetEgg and _G.TargetEggType then
                env.buyEgg and env.buyEgg(_G.TargetEggType)
                task.wait(0.5)
            end

            -- Auto Unlock Egg Slots
            if _G.AutoUnlockEggSlots then
                env.unlockEggSlot and env.unlockEggSlot()
                task.wait(1)
            end
        end
    end)

end
