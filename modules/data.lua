return function(env)
    local LocalPlayer       = env.LocalPlayer
    local PlayerGui         = env.PlayerGui
    local ReplicatedStorage = env.ReplicatedStorage
    local Shared            = env.Shared
    local parseMoney        = env.parseMoney

    local function getMutationList()
        local mutations = {"Normal"}
        local src = Shared and Shared:FindFirstChild("MutationAppliers")
        if src then
            for _, obj in ipairs(src:GetChildren()) do
                if obj.Name ~= "" then table.insert(mutations, obj.Name) end
            end
        end
        table.sort(mutations, function(a, b)
            if a == "Normal" then return true
            elseif b == "Normal" then return false
            else return a < b end
        end)
        if #mutations == 1 then
            mutations = {"Normal","Alien","Autumn","Cosmic","Farm","Frozen","Honeycomb","Radioactive","Rainbow","Void","Wet"}
        end
        return mutations
    end

    local function getIndexSeeds()
        local seeds, seen = {}, {}
        local mainUI = PlayerGui:FindFirstChild("MainUI")
        if mainUI then
            local menus = mainUI:FindFirstChild("Menus")
            if menus then
                local indexFrame = menus:FindFirstChild("IndexFrame")
                if indexFrame then
                    local main = indexFrame:FindFirstChild("Main")
                    if main then
                        local pf = main:FindFirstChild("PlantsFrame")
                        if pf then
                            for _, frame in ipairs(pf:GetChildren()) do
                                if frame:IsA("Frame") then
                                    local sn = frame:FindFirstChild("SeedName")
                                    local rn = frame:FindFirstChild("RarityName")
                                    if sn and rn and sn.Text ~= "" and sn.Text ~= "???" and rn.Text ~= "" and rn.Text ~= "???" then
                                        if not seen[sn.Text] then
                                            seen[sn.Text] = true
                                            table.insert(seeds, "[" .. rn.Text .. "] " .. sn.Text)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        if #seeds == 0 then
            local as = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Seeds")
            if as then
                for _, seed in ipairs(as:GetChildren()) do
                    local name = seed.Name:gsub(" Seed$", "")
                    if not seen[name] then seen[name] = true; table.insert(seeds, name) end
                end
            end
        end
        if #seeds == 0 then
            seeds = {"No seeds found - open Index first"}
        end
        table.sort(seeds)
        return seeds
    end

    local function scanInventoryForSeeds()
        local seeds, seen = {"None"}, {}
        local function scan(parent)
            if not parent then return end
            for _, item in ipairs(parent:GetChildren()) do
                if item:IsA("Tool") and item:GetAttribute("InventoryCategory") == "Seeds" then
                    local tn = item:GetAttribute("trueName")
                    if tn and not seen[tn] then seen[tn] = true; table.insert(seeds, tn) end
                end
            end
        end
        scan(LocalPlayer.Character)
        scan(LocalPlayer:FindFirstChild("Backpack"))
        return seeds
    end

    local function getGearPriceFromGui(gearName)
        local mainUI = PlayerGui:FindFirstChild("MainUI")
        if not mainUI then return "N/A" end
        local menus = mainUI:FindFirstChild("Menus")
        if not menus then return "N/A" end
        local gsf = menus:FindFirstChild("GearShopFrame")
        if not gsf then return "N/A" end
        local sf = gsf:FindFirstChild("ScrollingFrame")
        if not sf then return "N/A" end
        local gf = sf:FindFirstChild(gearName)
        if not gf then return "N/A" end
        for _, desc in ipairs(gf:GetDescendants()) do
            if desc:IsA("TextLabel") and desc.Text and string.sub(desc.Text, 1, 1) == "$" then
                return desc.Text
            end
        end
        return "N/A"
    end

    local function getGearStock(gearName)
        local gs = ReplicatedStorage:FindFirstChild("GearStocks")
        if not gs then return 0 end
        local ps = gs:FindFirstChild(LocalPlayer.Name)
        if not ps then return 0 end
        local so = ps:FindFirstChild(gearName)
        return so and so.Value or 0
    end

    local function getAvailableGears()
        local gears = {}
        local assets = ReplicatedStorage:FindFirstChild("Assets")
        if assets then
            local gf = assets:FindFirstChild("Gear")
            if gf then
                for _, g in ipairs(gf:GetChildren()) do table.insert(gears, g.Name) end
            end
        end
        table.sort(gears)
        return gears
    end

    local function getEggSlotsInfo()
        local slots = {}
        if Shared and Shared:FindFirstChild("EggConfig") then
            local ok, cfg = pcall(function() return require(Shared.EggConfig) end)
            if ok and type(cfg) == "table" and cfg.UnlockPrices then
                for slotStr, price in pairs(cfg.UnlockPrices) do
                    local n = tonumber(string.match(slotStr, "%d+"))
                    if n then table.insert(slots, {EggSlotNumber=n, UnlockPrice=tonumber(price) or 0}) end
                end
            end
        end
        table.sort(slots, function(a, b) return a.EggSlotNumber < b.EggSlotNumber end)
        return slots
    end

    local function getAvailableEggTypes()
        local eggs = {}
        if Shared and Shared:FindFirstChild("EggConfig") then
            local ok, cfg = pcall(function() return require(Shared.EggConfig) end)
            if ok and type(cfg) == "table" then
                for k, v in pairs(cfg) do
                    if type(v) == "table" and string.match(tostring(k), "Egg$") then
                        table.insert(eggs, tostring(k))
                    end
                end
            end
        end
        table.sort(eggs)
        if #eggs == 0 then eggs = {"CommonEgg","RareEgg","EpicEgg"} end
        return eggs
    end

    local function getCurrentEggSlots()
        local slots = {}
        local pm = workspace:FindFirstChild("PetMerchant")
        if not pm then return slots end
        for i = 1, 5 do
            local pod = pm:FindFirstChild("Podium" .. i .. "Stock") or pm:FindFirstChild("Podium" .. i)
            if pod then
                local el = pod:FindFirstChild("EggLabel", true)
                if el and el.Text and el.Text ~= "" then
                    local name = string.gsub(el.Text, " ", "")
                    if not string.match(string.lower(name), "egg$") then name = name .. "Egg" end
                    table.insert(slots, {Slot=i, Name=name})
                end
            end
        end
        return slots
    end

    local function getEggShopInfo()
        local pm = workspace:FindFirstChild("PetMerchant")
        if not pm then return "--- EGG SHOP ---\nPet Merchant not found" end
        local lines = {}
        local restockText = "Restocks In: Unknown"
        local sign = pm:FindFirstChild("MerchantSign")
        if sign then
            local sg = sign:FindFirstChildWhichIsA("SurfaceGui")
            if sg then
                local tl = sg:FindFirstChild("TimeLabel")
                if tl then restockText = tl.Text end
            end
        end
        table.insert(lines, "--- EGG SHOP (" .. restockText .. ") ---")
        local hasEggs = false
        for i = 1, 5 do
            local pod = pm:FindFirstChild("Podium" .. i .. "Stock") or pm:FindFirstChild("Podium" .. i)
            if pod then
                local el = pod:FindFirstChild("EggLabel", true)
                local pl = pod:FindFirstChild("PriceLabel", true)
                if el and pl and el.Text ~= "" then
                    table.insert(lines, string.format("[Slot %d] %s | %s", i, el.Text, pl.Text))
                    hasEggs = true
                end
            end
        end
        if not hasEggs then table.insert(lines, "No eggs listed (loading or empty)") end
        return table.concat(lines, "\n")
    end

    local function getGearShopInfo()
        local lines = {"--- GEAR SHOP ---"}
        local hasStock = false
        for _, gearName in ipairs(getAvailableGears()) do
            local stock = getGearStock(gearName)
            local price = getGearPriceFromGui(gearName)
            local color = stock == 0 and "#FF5050" or "#00FF7F"
            table.insert(lines, string.format(
                "- <font color='%s'>[%d x]</font> <font color='#FFD250'>[%s]</font> %s",
                color, stock, price, gearName
            ))
            if stock > 0 then hasStock = true end
        end
        if not hasStock then table.insert(lines, "- All gears out of stock!") end
        return table.concat(lines, "\n")
    end

    env.getMutationList       = getMutationList
    env.getIndexSeeds         = getIndexSeeds
    env.scanInventoryForSeeds = scanInventoryForSeeds
    env.getGearPriceFromGui   = getGearPriceFromGui
    env.getGearStock          = getGearStock
    env.getAvailableGears     = getAvailableGears
    env.getEggSlotsInfo       = getEggSlotsInfo
    env.getAvailableEggTypes  = getAvailableEggTypes
    env.getCurrentEggSlots    = getCurrentEggSlots
    env.getEggShopInfo        = getEggShopInfo
    env.getGearShopInfo       = getGearShopInfo
    env.getFullShopInfo       = function() return getEggShopInfo() .. "\n\n" .. getGearShopInfo() end
end
