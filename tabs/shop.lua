return function(env)
    local T       = env.ShopTab
    local Remotes = env.Remotes
    local LP      = env.LocalPlayer
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

    local seedEntries={}; pcall(function() seedEntries=allSeeds() or {} end)
    local sortedRar, seedToRar = {}, {}
    pcall(function() sortedRar, seedToRar = buildRarity(seedEntries) end)
    local seedList = #seedEntries>0 and seedEntries or {"None"}

    -- ── GACHA ────────────────────────────────────────────────────
    T:CreateSection("Seed Gacha (Roll & Buy)")

    local function getStandPositions()
        local stands={}
        local plot=findPlot()
        if plot then
            local roller=plot:FindFirstChild("SeedRoller")
            if roller then
                for i=1,6 do
                    local s=roller:FindFirstChild("Stand"..i)
                    if s then stands[i]=s:GetPivot().Position end
                end
            end
        end
        return stands
    end

    local function getAvailableStands()
        local stands=getStandPositions()
        local avail={}
        for _,m in ipairs(workspace:GetChildren()) do
            if m:IsA("Model") and m:FindFirstChild("BuySeed",true) then
                local mp=m:GetPivot().Position
                local nearIdx,minD=nil,math.huge
                for idx,pos in pairs(stands) do
                    local d=(Vector3.new(mp.X,0,mp.Z)-Vector3.new(pos.X,0,pos.Z)).Magnitude
                    if d<minD then minD=d; nearIdx=idx end
                end
                if nearIdx and minD<15 then
                    local sg=m:FindFirstChild("SeedGui",true)
                    if sg then
                        for _,desc in ipairs(sg:GetDescendants()) do
                            if (desc:IsA("TextLabel") or desc:IsA("TextButton")) and string.find(tostring(desc.Text),"%$") then
                                avail[m.Name]={standIdx=nearIdx,price=pMoney(desc.Text)}; break
                            end
                        end
                    end
                end
            end
        end
        return avail
    end

    local function shouldBuy(name)
        if _G.AutoRollAndBuyAll then return true end
        if _G.AutoRollAndBuySelected then
            return next(_G.TargetGachaSeeds)~=nil and _G.TargetGachaSeeds[name]==true
        end
        if _G.AutoRollAndBuyByRarity then
            if next(_G.TargetGachaRarities)==nil then return false end
            local r=seedToRar[name]
            return r~=nil and _G.TargetGachaRarities[r]==true
        end
        return false
    end

    T:CreateToggle({Name="Auto Roll & Buy TODOS",CurrentValue=false,Flag="AutoRollAll",
        Callback=function(val)
            _G.AutoRollAndBuyAll=val
            if val then _G.AutoRollAndBuySelected=false; _G.AutoRollAndBuyByRarity=false end
        end})

    T:CreateDropdown({Name="Seeds Alvo (Selecionadas)",Options=seedList,CurrentOption={},MultipleOptions=true,
        Flag="GachaSeeds",
        Callback=function(opts)
            _G.TargetGachaSeeds={}
            for _,v in ipairs(opts) do
                local n=string.match(v,"%] (.+)") or v; _G.TargetGachaSeeds[n]=true
            end
        end})

    T:CreateToggle({Name="Auto Roll & Buy Selecionadas",CurrentValue=false,Flag="AutoRollSel",
        Callback=function(val)
            _G.AutoRollAndBuySelected=val
            if val then _G.AutoRollAndBuyAll=false; _G.AutoRollAndBuyByRarity=false end
        end})

    T:CreateDropdown({Name="Raridades Alvo",Options=sortedRar,CurrentOption={},MultipleOptions=true,
        Flag="GachaRarities",
        Callback=function(opts)
            _G.TargetGachaRarities={}
            for _,r in ipairs(opts) do _G.TargetGachaRarities[r]=true end
        end})

    T:CreateToggle({Name="Auto Roll & Buy por Raridade",CurrentValue=false,Flag="AutoRollRar",
        Callback=function(val)
            _G.AutoRollAndBuyByRarity=val
            if val then _G.AutoRollAndBuyAll=false; _G.AutoRollAndBuySelected=false end
        end})

    -- Gacha loop
    task.spawn(function()
        while true do
            if _G.AutoRollAndBuyAll or _G.AutoRollAndBuySelected or _G.AutoRollAndBuyByRarity then
                local avail=getAvailableStands()
                local bought=false
                for name,info in pairs(avail) do
                    if not (_G.AutoRollAndBuyAll or _G.AutoRollAndBuySelected or _G.AutoRollAndBuyByRarity) then break end
                    if shouldBuy(name) and haveMoney(info.price,"Seed",name) then
                        pcall(function() Remotes.BuySeed:FireServer(info.standIdx) end)
                        bought=true; task.wait(0.5)
                    end
                end
                if not bought then
                    pcall(function() Remotes.RollSeeds:FireServer() end)
                    task.wait(3.5)
                end
            end
            task.wait(0.5)
        end
    end)

    -- ── GEAR SHOP ────────────────────────────────────────────────
    T:CreateSection("Gear Shop")

    local allGears={}; pcall(function() allGears=getGears() or {} end)

    T:CreateToggle({Name="Auto Comprar Todos Gears",CurrentValue=false,Flag="AutoBuyAllGears",
        Callback=function(val)
            _G.AutoBuyAllGears=val
            if val then _G.AutoBuySelectedGears=false end
            if not val then return end
            task.spawn(function()
                while _G.AutoBuyAllGears do
                    for _,g in ipairs(allGears) do
                        if not _G.AutoBuyAllGears then break end
                        if getGearStk(g)>0 then pcall(function() buyGear(g) end); task.wait(0.1) end
                    end
                    task.wait(0.5)
                end
            end)
        end})

    local selGears={}
    T:CreateDropdown({Name="Gears Selecionados",Options=allGears,CurrentOption={},MultipleOptions=true,
        Flag="GearsToBuy",
        Callback=function(opts) selGears=opts end})

    T:CreateToggle({Name="Auto Comprar Gears Selecionados",CurrentValue=false,Flag="AutoBuySelGears",
        Callback=function(val)
            _G.AutoBuySelectedGears=val
            if val then _G.AutoBuyAllGears=false end
            if not val then return end
            task.spawn(function()
                while _G.AutoBuySelectedGears do
                    for _,g in ipairs(selGears) do
                        if not _G.AutoBuySelectedGears then break end
                        if getGearStk(g)>0 then pcall(function() buyGear(g) end); task.wait(0.1) end
                    end
                    task.wait(0.5)
                end
            end)
        end})

    -- ── EGG SHOP ─────────────────────────────────────────────────
    T:CreateSection("Egg Shop")

    local eggTypes={}; pcall(function() eggTypes=getEggTypes() or {} end)

    T:CreateToggle({Name="Auto Desbloquear Egg Slots",CurrentValue=false,Flag="AutoUnlockEggSlots",
        Callback=function(val)
            _G.AutoUnlockEggSlots=val
            if not val then return end
            task.spawn(function()
                while _G.AutoUnlockEggSlots do
                    pcall(function()
                        local r=Remotes:FindFirstChild("EggShop") and Remotes.EggShop:FindFirstChild("Transaction")
                        if not r then return end
                        for _,si in ipairs(getEggSlots()) do
                            if not _G.AutoUnlockEggSlots then break end
                            local n=si.EggSlotNumber
                            if not _G.SessionUnlockedEggSlots[n] and haveMoney(si.UnlockPrice,"Egg Slot","Slot "..n) then
                                local ok=pcall(function() r:InvokeServer("UnlockSlot",n) end)
                                if ok then _G.SessionUnlockedEggSlots[n]=true; task.wait(1.5) end
                            end
                        end
                    end)
                    task.wait(5)
                end
            end)
        end})

    T:CreateDropdown({Name="Eggs para Comprar",Options=eggTypes,CurrentOption={},MultipleOptions=true,
        Flag="EggsToBuy",
        Callback=function(opts)
            _G.TargetEggShopEggs={}
            for _,v in ipairs(opts) do _G.TargetEggShopEggs[v]=true end
        end})

    local function startEggLoop()
        task.spawn(function()
            while _G.AutoBuySelectedEggs or _G.AutoBuyAllEggs do
                local slots=getCurrEggs()
                for _,slot in ipairs(slots) do
                    if not (_G.AutoBuySelectedEggs or _G.AutoBuyAllEggs) then break end
                    local elig = _G.AutoBuyAllEggs or (_G.AutoBuySelectedEggs and _G.TargetEggShopEggs[slot.Name]==true)
                    if elig then pcall(function() buyEgg(slot) end); task.wait(0.2) end
                end
                task.wait(1)
            end
        end)
    end

    T:CreateToggle({Name="Auto Comprar Eggs Selecionados",CurrentValue=false,Flag="AutoBuySelEggs",
        Callback=function(val)
            _G.AutoBuySelectedEggs=val
            if val then _G.AutoBuyAllEggs=false; startEggLoop() end
        end})

    T:CreateToggle({Name="Auto Comprar Todos Eggs",CurrentValue=false,Flag="AutoBuyAllEggs",
        Callback=function(val)
            _G.AutoBuyAllEggs=val
            if val then _G.AutoBuySelectedEggs=false; startEggLoop() end
        end})
end
