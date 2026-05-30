return function(env)
    local T           = env.ShopTab
    local Lib         = env.Library
    local Remotes     = env.Remotes
    local allSeeds    = env.getIndexSeeds
    local getGears    = env.getAvailableGears
    local getEggTypes = env.getAvailableEggTypes
    local getCurrEggs = env.getCurrentEggSlots
    local getEggSlots = env.getEggSlotsInfo
    local getGearStk  = env.getGearStock
    local getShopInfo = env.getFullShopInfo
    local pMoney      = env.parseMoney
    local haveMoney   = env.haveEnoughMoney
    local findPlot    = env.findMyPlot
    local buyGear     = env.buyGear
    local buyEgg      = env.buyEgg

    -- LEFT: Seed Gacha
    local GachaBox = T:AddLeftGroupbox("Seed Gacha (Roll & Buy)")

    GachaBox:AddToggle("AutoRollBuyAll", {
        Text = "Auto Roll & Buy ALL Seeds", Default = false,
        Callback = function(val) _G.AutoRollAndBuyAll = val end,
    })

    GachaBox:AddDropdown("GachaSeeds", {
        Values = allSeeds(), Default = {}, Multi = true,
        Text = "Seeds to Snipe",
        Callback = function(val) _G.TargetGachaSeeds = val end,
    })

    GachaBox:AddToggle("AutoRollBuySelected", {
        Text = "Auto Roll & Buy SELECTED", Default = false,
        Callback = function(val) _G.AutoRollAndBuySelected = val end,
    })

    task.spawn(function()
        while true do
            if _G.AutoRollAndBuyAll or _G.AutoRollAndBuySelected then
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
                local avail = {}
                for _, m in ipairs(workspace:GetChildren()) do
                    if m:IsA("Model") and m:FindFirstChild("BuySeed", true) then
                        local mp = m:GetPivot().Position
                        local near, minD = nil, math.huge
                        for idx, pos in pairs(stands) do
                            local d = (Vector3.new(mp.X,0,mp.Z) - Vector3.new(pos.X,0,pos.Z)).Magnitude
                            if d < minD then minD=d; near=idx end
                        end
                        if near and minD < 15 then
                            local sg = m:FindFirstChild("SeedGui", true)
                            if sg then
                                for _, desc in ipairs(sg:GetDescendants()) do
                                    if desc:IsA("TextLabel") and string.find(desc.Text, "$") then
                                        avail[m.Name] = {standIdx=near, price=pMoney(desc.Text)}
                                    end
                                end
                            end
                        end
                    end
                end
                local function buyAvail(filter)
                    if next(avail) then
                        for name, info in pairs(avail) do
                            if (not filter or filter[name]) and haveMoney(info.price, "Seed", name) then
                                pcall(function() Remotes.BuySeed:FireServer(info.standIdx) end)
                                task.wait(0.5)
                            end
                        end
                    else
                        pcall(function() Remotes.RollSeeds:FireServer() end)
                        task.wait(3.5)
                    end
                end
                if _G.AutoRollAndBuyAll then buyAvail(nil)
                elseif _G.AutoRollAndBuySelected then buyAvail(_G.TargetGachaSeeds) end
            end
            task.wait(1)
        end
    end)

    -- RIGHT: Gear Shop
    local GearBox = T:AddRightGroupbox("Gear Shop")

    GearBox:AddToggle("AutoBuyAllGears", {
        Text = "Auto Buy All Available Gears", Default = false,
        Callback = function(val) _G.AutoBuyAllGears = val end,
    })

    GearBox:AddDropdown("TargetGears", {
        Values = getGears(), Default = {}, Multi = true,
        Text = "Select Gears to Buy",
        Callback = function(val) _G.TargetBuyGears = val end,
    })

    GearBox:AddToggle("AutoBuySelGears", {
        Text = "Auto Buy Selected Gears", Default = false,
        Callback = function(val) _G.AutoBuySelectedGears = val end,
    })

    task.spawn(function()
        while true do
            if _G.AutoBuyAllGears then
                for _, g in ipairs(getGears()) do
                    if getGearStk(g) > 0 then buyGear(g); task.wait(0.5) end
                end
            elseif _G.AutoBuySelectedGears then
                for g in pairs(_G.TargetBuyGears or {}) do
                    if getGearStk(g) > 0 then buyGear(g); task.wait(0.5) end
                end
            end
            task.wait(5)
        end
    end)

    -- LEFT: Egg Shop
    local EggBox = T:AddLeftGroupbox("Egg Shop")

    EggBox:AddToggle("AutoUnlockEggSlots", {
        Text = "Auto Unlock Egg Slots", Default = false,
        Callback = function(val) _G.AutoUnlockEggSlots = val end,
    })

    local eggSlots = getEggSlots()
    task.spawn(function()
        while true do
            if _G.AutoUnlockEggSlots then
                for _, si in ipairs(eggSlots) do
                    if not _G.SessionUnlockedEggSlots[si.EggSlotNumber]
                        and haveMoney(si.UnlockPrice, "Unlock Egg Slot " .. si.EggSlotNumber) then
                        pcall(function()
                            if Remotes:FindFirstChild("EggShop") and Remotes.EggShop:FindFirstChild("Transaction") then
                                Remotes.EggShop.Transaction:InvokeServer("UnlockSlot", si.EggSlotNumber)
                                _G.SessionUnlockedEggSlots[si.EggSlotNumber] = true
                            end
                        end)
                        task.wait(0.5)
                    end
                end
            end
            task.wait(3)
        end
    end)

    EggBox:AddToggle("AutoBuyAllEggs", {
        Text = "Auto Buy All Available Eggs", Default = false,
        Callback = function(val) _G.AutoBuyAllEggs = val end,
    })

    EggBox:AddDropdown("TargetEggs", {
        Values = getEggTypes(), Default = {}, Multi = true,
        Text = "Select Eggs to Buy",
        Callback = function(val) _G.TargetEggShopEggs = val end,
    })

    EggBox:AddToggle("AutoBuySelEggs", {
        Text = "Auto Buy Selected Eggs", Default = false,
        Callback = function(val) _G.AutoBuySelectedEggs = val end,
    })

    task.spawn(function()
        while true do
            local slots = getCurrEggs()
            if _G.AutoBuyAllEggs then
                for _, s in ipairs(slots) do buyEgg(s); task.wait(0.5) end
            elseif _G.AutoBuySelectedEggs then
                for _, s in ipairs(slots) do
                    if _G.TargetEggShopEggs[s.Name] then buyEgg(s); task.wait(0.5) end
                end
            end
            task.wait(5)
        end
    end)

    -- Stock Info na tab separada (env.StockTab criada no main.lua)
        if env.StockTab then
        local EggStockBox  = env.StockTab:AddLeftGroupbox("Egg Shop")
        local GearStockBox = env.StockTab:AddRightGroupbox("Gear Shop")

        local eggLbl  = EggStockBox:AddLabel("Loading...")
        local gearLbl = GearStockBox:AddLabel("Loading...")

        EggStockBox:AddButton({Text="Refresh", Func=function()
            eggLbl:SetText(env.getEggShopInfo())
            gearLbl:SetText(env.getGearShopInfo())
        end})

        task.spawn(function()
            task.wait(2)
            eggLbl:SetText(env.getEggShopInfo())
            gearLbl:SetText(env.getGearShopInfo())
        end)
    end
