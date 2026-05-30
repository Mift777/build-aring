return function(env)
    local LP      = env.LocalPlayer
    local PGui    = env.PlayerGui
    local Remotes = env.Remotes
    local Suf     = env.MoneySuffixes
    local PUpgs   = env.PlotUpgrades

    local function parseMoney(v)
        if type(v)=="number" then return v end
        if type(v)~="string" or v=="" then return 0 end
        local c = string.upper(v):gsub("[$,%s]","")
        local n,s = string.match(c,"^([%d%.]+)(%a*)$")
        if not n then return 0 end
        return (tonumber(n) or 0) * (Suf[s] or 1)
    end

    local function getCurrentMoney()
        local gui = PGui:FindFirstChild("MainUI")
        local cc  = gui and gui:FindFirstChild("MoneyCounter")
                    and gui.MoneyCounter:FindFirstChild("CashCounter")
        local gv  = cc and parseMoney(cc.Text)
        local ls  = LP:FindFirstChild("leaderstats") or LP:FindFirstChild("Leaderstats")
        local lv  = ls and ls:FindFirstChild("Cash") and parseMoney(ls.Cash.Value)
        return gv or lv or 0
    end

    local function haveEnoughMoney(req, label, info)
        if _G.SkipMoneyCheck then return true end
        if getCurrentMoney() >= req then return true end
        if label then warn("[BAR] Sem dinheiro: "..label..(info and " ("..tostring(info)..")" or "")) end
        return false
    end

    -- findMyPlot com cache + 4 fallbacks
    local _cachedPlot = nil
    local _cachedName = nil

    local function findMyPlot()
        if _cachedPlot and _cachedPlot.Parent then return _cachedPlot end
        _cachedPlot = nil
        local map = workspace:FindFirstChild("Map")
        local pf  = map and map:FindFirstChild("Plots")
        if not pf then return nil end
        -- 1: Owner
        for _,p in ipairs(pf:GetChildren()) do
            local o = p:FindFirstChild("Owner")
            if o and o.Value == LP then _cachedPlot=p; return p end
        end
        -- 2: GetPlot remote
        pcall(function()
            if Remotes and Remotes:FindFirstChild("GetPlot") then
                local r = Remotes.GetPlot:Invoke()
                if typeof(r)=="Instance" then _cachedPlot=r
                elseif typeof(r)=="string" then _cachedPlot=pf:FindFirstChild(r) end
            end
        end)
        if _cachedPlot then return _cachedPlot end
        -- 3: Text label
        for _,p in ipairs(pf:GetChildren()) do
            for _,e in ipairs(p:GetDescendants()) do
                if (e:IsA("TextLabel") or e:IsA("TextButton")) then
                    if string.find(string.lower(tostring(e.Text)), string.lower(LP.Name), 1, true) then
                        _cachedPlot=p; return p
                    end
                end
            end
        end
        -- 4: Proximity
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local best, bd = nil, math.huge
            for _,p in ipairs(pf:GetChildren()) do
                local ok,pv = pcall(function() return p:GetPivot() end)
                if ok then
                    local d = (hrp.Position-pv.Position).Magnitude
                    if d<bd then bd=d; best=p end
                end
            end
            if best then _cachedPlot=best; return best end
        end
        return nil
    end

    local floorNames = {"","SecondFloor","ThirdFloor"}

    local function getFloorFarmPlot(floor)
        local plot = findMyPlot()
        if not plot then return nil end
        if floor==1 then return plot:FindFirstChild("FarmPlot") end
        local fn = floorNames[floor]
        if not fn or fn=="" then return nil end
        local fm = plot:FindFirstChild(fn)
        return fm and fm:FindFirstChild("FarmPlot")
    end

    local function getAllDirt(farmPlot)
        local r={}
        if not farmPlot then return r end
        for _,d in ipairs(farmPlot:GetDescendants()) do
            if d.Name=="Dirt" then table.insert(r,d) end
        end
        return r
    end

    local function getUpgradeCost(upgType, floorNum)
        local plot = findMyPlot()
        if not plot then return nil end
        local cfg = PUpgs[upgType]
        if not cfg or floorNum<=1 then return nil end
        if cfg.SignName=="UpgradeSign" then return nil end
        local fp   = plot:FindFirstChild(floorNames[floorNum])
        if not fp then return nil end
        local sign = fp:FindFirstChild(cfg.SignName)
        if not sign then return nil end
        local txt = sign:FindFirstChild("Screen")
            and sign.Screen:FindFirstChild("SurfaceGui")
            and sign.Screen.SurfaceGui:FindFirstChild(cfg.UIFolder)
            and sign.Screen.SurfaceGui[cfg.UIFolder]:FindFirstChild("Btn")
            and sign.Screen.SurfaceGui[cfg.UIFolder].Btn:FindFirstChild("Txt")
        if not txt then return nil end
        if txt.Text=="MAX" then return "MAX" end
        return parseMoney(txt.Text)
    end

    local function doPlotUpgrade(upgType, floorNum)
        if Remotes and Remotes:FindFirstChild("PlotUpgradeTransaction") then
            Remotes.PlotUpgradeTransaction:InvokeServer(PUpgs[upgType].RemoteArg,"Floor"..floorNum)
        end
    end

    local function upgradeSeedLuck()
        if Remotes and Remotes:FindFirstChild("UpgradeSeedLuck") then
            pcall(function() Remotes.UpgradeSeedLuck:InvokeServer() end)
        end
    end

    local function upgradeSeedRolls()
        if Remotes and Remotes:FindFirstChild("UpgradeSeedRolls") then
            pcall(function() Remotes.UpgradeSeedRolls:InvokeServer() end)
        end
    end

    local function teleportToMyPlot()
        local plot = findMyPlot()
        local hrp  = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if plot and hrp then
            hrp.CFrame = plot:GetPivot() * CFrame.new(0,5,0)
            env.Window:Notify({Title="Teleporte",Content="Chegou no plot!",Duration=2})
        end
    end

    env.parseMoney       = parseMoney
    env.getCurrentMoney  = getCurrentMoney
    env.haveEnoughMoney  = haveEnoughMoney
    env.findMyPlot       = findMyPlot
    env.getFloorFarmPlot = getFloorFarmPlot
    env.getAllDirt        = getAllDirt
    env.getUpgradeCost   = getUpgradeCost
    env.doPlotUpgrade    = doPlotUpgrade
    env.upgradeSeedLuck  = upgradeSeedLuck
    env.upgradeSeedRolls = upgradeSeedRolls
    env.teleportToMyPlot = teleportToMyPlot
end
