return function(env)
    local LP    = env.LocalPlayer
    local PGui  = env.PlayerGui
    local RS    = env.ReplicatedStorage
    local Shared= env.Shared

    local rarityW = {Common=1,Uncommon=2,Rare=3,Epic=4,Legendary=5,
                     Secret=6,Prismatic=7,Divine=8,Exotic=9,Transcended=10}

    local function getRarityFromEntry(e)
        local r = string.match(tostring(e or ""),"%[(.-)%]")
        return (r and r~="") and r or "Unknown"
    end

    local function getSeedNameFromEntry(e)
        return string.match(tostring(e or ""),"%] (.+)") or tostring(e or "")
    end

    local function buildRarityMaps(entries)
        local seedToRarity, rset = {}, {}
        for _,e in ipairs(entries or {}) do
            local r = getRarityFromEntry(e)
            local n = getSeedNameFromEntry(e)
            if r~="Unknown" and n~="" then seedToRarity[n]=r; rset[r]=true end
        end
        local sorted = {}
        for r in pairs(rset) do table.insert(sorted,r) end
        table.sort(sorted,function(a,b)
            local wa=rarityW[a] or 99; local wb=rarityW[b] or 99
            return wa~=wb and wa<wb or a<b
        end)
        if #sorted==0 then
            sorted={"Common","Uncommon","Rare","Epic","Legendary","Secret","Prismatic","Divine","Exotic","Transcended"}
        end
        return sorted, seedToRarity
    end

    local function getMutationList()
        local m={"Normal"}
        local src = RS:FindFirstChild("Shared") and RS.Shared:FindFirstChild("Registry")
                    and RS.Shared.Registry:FindFirstChild("Mutations")
        if src then
            for _,v in ipairs(src:GetChildren()) do table.insert(m,v.Name) end
        end
        table.sort(m,function(a,b)
            if a=="Normal" then return true elseif b=="Normal" then return false else return a<b end
        end)
        if #m==1 then m={"Alien","Autumn","Cosmic","Farm","Frozen","Honeycomb","Normal","Radioactive","Rainbow","Void","Wet"} end
        return m
    end

    local function getIndexSeeds()
        local seeds, seen = {}, {}
        -- Tentar pelo IndexFrame na UI
        local mainUI = PGui:FindFirstChild("MainUI")
        local pf = mainUI
            and mainUI:FindFirstChild("Menus")
            and mainUI.Menus:FindFirstChild("IndexFrame")
            and mainUI.Menus.IndexFrame:FindFirstChild("Main")
            and mainUI.Menus.IndexFrame.Main:FindFirstChild("PlantsFrame")
        if pf then
            for _,frame in ipairs(pf:GetChildren()) do
                if frame:IsA("Frame") then
                    local sn = frame:FindFirstChild("SeedName")
                    local rn = frame:FindFirstChild("RarityName")
                    if sn and rn and sn.Text~="" and sn.Text~="???" and rn.Text~="" then
                        if not seen[sn.Text] then
                            seen[sn.Text]=true
                            table.insert(seeds,"["..rn.Text.."] "..sn.Text)
                        end
                    end
                end
            end
        end
        -- Fallback: Assets/Seeds
        if #seeds==0 then
            local as = RS:FindFirstChild("Assets") and RS.Assets:FindFirstChild("Seeds")
            if as then
                for _,s in ipairs(as:GetChildren()) do
                    local n = s.Name:gsub(" Seed$","")
                    if not seen[n] then seen[n]=true; table.insert(seeds,n) end
                end
            end
        end
        if #seeds==0 then seeds={"Abra o Index primeiro"} end
        table.sort(seeds)
        return seeds
    end

    local function getAvailableGears()
        local gears,ferts,sprays,spraysNoAcid = {},{},{},{}
        local gf = RS:FindFirstChild("Assets") and RS.Assets:FindFirstChild("Gear")
        if gf then
            for _,g in ipairs(gf:GetChildren()) do
                local n=g.Name
                table.insert(gears,n)
                if string.find(n,"Fertilizer",1,true) then table.insert(ferts,n) end
                if string.find(n,"Spray",1,true) then table.insert(sprays,n) end
                if string.find(n,"Spray",1,true) and not string.find(n,"Acid",1,true) then
                    table.insert(spraysNoAcid,n)
                end
            end
        end
        table.sort(gears); table.sort(ferts); table.sort(sprays); table.sort(spraysNoAcid)
        if #ferts==0 then ferts={"Bee Fertilizer","Normal Fertilizer","Scrappy Fertilizer","Strong Fertilizer","Super Fertilizer"} end
        if #spraysNoAcid==0 then spraysNoAcid={"Autumn Spray","Cosmic Spray","Frozen Spray","Radioactive Spray","Rainbow Spray","Trucker Spray","Void Spray","Wet Spray"} end
        if #sprays==0 then sprays={"Acid Spray"}; for _,v in ipairs(spraysNoAcid) do table.insert(sprays,v) end end
        return gears, ferts, sprays, spraysNoAcid
    end

    local function getGearStock(name)
        local gs = RS:FindFirstChild("GearStocks")
        local ps = gs and gs:FindFirstChild(LP.Name)
        local so = ps and ps:FindFirstChild(name)
        return so and so.Value or 0
    end

    local _eggCfg = nil
    local function getEggConfig()
        if _eggCfg~=nil then return _eggCfg~=false and _eggCfg or nil end
        local ec = Shared and Shared:FindFirstChild("EggConfig")
        if not ec then _eggCfg=false; return nil end
        local ok,r = pcall(require,ec)
        _eggCfg = (ok and type(r)=="table") and r or false
        return _eggCfg~=false and _eggCfg or nil
    end

    local function getAvailableEggTypes()
        local eggs={}
        local cfg = getEggConfig()
        if cfg then
            for k,v in pairs(cfg) do
                if type(v)=="table" and string.match(tostring(k),"Egg$") then
                    table.insert(eggs,tostring(k))
                end
            end
        end
        table.sort(eggs)
        if #eggs==0 then eggs={"CommonEgg","RareEgg","EpicEgg"} end
        return eggs
    end

    local function getEggSlotsInfo()
        local slots={}
        local cfg = getEggConfig()
        if cfg and cfg.UnlockPrices then
            for s,p in pairs(cfg.UnlockPrices) do
                local n = tonumber(string.match(s,"%d+"))
                if n then table.insert(slots,{EggSlotNumber=n,UnlockPrice=tonumber(p) or 0}) end
            end
        end
        table.sort(slots,function(a,b) return a.EggSlotNumber<b.EggSlotNumber end)
        return slots
    end

    local function getCurrentEggSlots()
        local slots={}
        local pm = workspace:FindFirstChild("PetMerchant")
        if not pm then return slots end
        for i=1,5 do
            local pod = pm:FindFirstChild("Podium"..i.."Stock") or pm:FindFirstChild("Podium"..i)
            if pod then
                local el = pod:FindFirstChild("EggLabel",true)
                if el and el.Text~="" then
                    local n = el.Text:gsub(" ","")
                    if not n:lower():match("egg$") then n=n.."Egg" end
                    table.insert(slots,{Slot=i,Name=n})
                end
            end
        end
        return slots
    end

    env.getRarityFromEntry   = getRarityFromEntry
    env.getSeedNameFromEntry = getSeedNameFromEntry
    env.buildRarityMaps      = buildRarityMaps
    env.getMutationList      = getMutationList
    env.getIndexSeeds        = getIndexSeeds
    env.getAvailableGears    = getAvailableGears
    env.getGearStock         = getGearStock
    env.getAvailableEggTypes = getAvailableEggTypes
    env.getEggSlotsInfo      = getEggSlotsInfo
    env.getCurrentEggSlots   = getCurrentEggSlots
end
