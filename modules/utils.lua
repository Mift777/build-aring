return function(env)
    local LocalPlayer  = env.LocalPlayer
    local PlayerGui    = env.PlayerGui
    local Remotes      = env.Remotes
    local MoneySuffixes= env.MoneySuffixes
    local PlotUpgrades = env.PlotUpgrades

    local function parseMoney(value)
        if type(value) == "number" then return value end
        if type(value) ~= "string" or value == "" then return 0 end
        local clean = string.upper(value):gsub("[$%,%s]", "")
        local num, suffix = string.match(clean, "^([%d%.]+)(%a*)$")
        if not num then return 0 end
        local mult = 1
        if suffix and suffix ~= "" then
            mult = MoneySuffixes[suffix]
            if not mult then
                warn("[LamduckHub] Unknown suffix: " .. suffix)
                mult = 1
            end
        end
        return (tonumber(num) or 0) * mult
    end

    local function getCurrentMoney()
        local guiCash, leaderCash
        local mainUI = PlayerGui:FindFirstChild("MainUI")
        if mainUI then
            local mc = mainUI:FindFirstChild("MoneyCounter")
            if mc then
                local cc = mc:FindFirstChild("CashCounter")
                if cc then guiCash = parseMoney(cc.Text) end
            end
        end
        local ls = LocalPlayer:FindFirstChild("leaderstats") or LocalPlayer:FindFirstChild("Leaderstats")
        if ls then
            local c = ls:FindFirstChild("Cash")
            if c then leaderCash = parseMoney(c.Value) end
        end
        if guiCash and leaderCash and guiCash ~= leaderCash then
            print("[LamduckHub] Cash mismatch | leader: " .. tostring(leaderCash) .. " | gui: " .. tostring(guiCash))
        end
        return guiCash or leaderCash or 0
    end

    local function haveEnoughMoney(required, label, costStr)
        if _G.SkipMoneyCheck then return true end
        if getCurrentMoney() >= required then return true end
        if label then
            local msg = "[LamduckHub] Insufficient Cash - Skipped " .. label
            if costStr and costStr ~= "" then msg = msg .. ": " .. tostring(costStr) end
            print(msg)
        end
        return false
    end

    local function findMyPlot()
        local map = workspace:FindFirstChild("Map")
        if not map then return nil end
        local plotsFolder = map:FindFirstChild("Plots")
        if not plotsFolder then return nil end
        for _, plot in ipairs(plotsFolder:GetChildren()) do
            local owner = plot:FindFirstChild("Owner")
            if owner and owner.Value == LocalPlayer then return plot end
        end
        local ok, result = pcall(function()
            if Remotes and Remotes:FindFirstChild("Plot") and Remotes.Plot:FindFirstChild("GetPlot") then
                return Remotes.Plot.GetPlot:InvokeServer()
            end
        end)
        if ok then
            if typeof(result) == "Instance" then return result end
            if typeof(result) == "string" and plotsFolder then return plotsFolder:FindFirstChild(result) end
        end
        return nil
    end

    local function getUpgradeCost(upgradeType, floorNum)
        local myPlot = findMyPlot()
        if not myPlot then return nil end
        local cfg = PlotUpgrades[upgradeType]
        if not cfg or floorNum <= 1 then return nil end
        if cfg.SignName == "UpgradeSign" then return nil end
        local floorNames = {"","SecondFloor","ThirdFloor","FourthFloor","FifthFloor","SixthFloor"}
        local floorPart = myPlot:FindFirstChild(floorNames[floorNum])
        if not floorPart then return nil end
        local sign = floorPart:FindFirstChild(cfg.SignName)
        if not sign then return nil end
        local txt = sign:FindFirstChild("Screen")
            and sign.Screen:FindFirstChild("SurfaceGui")
            and sign.Screen.SurfaceGui:FindFirstChild(cfg.UIFolder)
            and sign.Screen.SurfaceGui[cfg.UIFolder]:FindFirstChild("Btn")
            and sign.Screen.SurfaceGui[cfg.UIFolder].Btn:FindFirstChild("Txt")
        if not txt then return nil end
        if txt.Text == "MAX" then return "MAX" end
        return parseMoney(txt.Text)
    end

    local function doPlotUpgrade(upgradeType, floorNum)
        if not Remotes or not Remotes:FindFirstChild("PlotUpgradeTransaction") then return end
        Remotes.PlotUpgradeTransaction:InvokeServer(PlotUpgrades[upgradeType].RemoteArg, "Floor" .. floorNum)
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

    local function teleportToCFrame(cf)
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = cf
            return true
        end
        return false
    end

    local function rejoinServer()
        if queue_on_teleport then
            queue_on_teleport("print('[LamduckHub] Rejoined!')")
        end
        env.TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end

    env.teleportDestinations = {
        {Label="Farm Floor 1",   DestinationType="MyPlotFloor",         PlotFloorYOffset=5},
        {Label="Farm Floor 2",   DestinationType="MyPlotFloor",         PlotFloorModelName="SecondFloor", PlotFloorYOffset=35},
        {Label="Farm Floor 3",   DestinationType="MyPlotFloor",         PlotFloorModelName="ThirdFloor",  PlotFloorYOffset=70},
        {Label="Seed Collector", DestinationType="WorkspacePivot",      WorkspaceModelName="SeedCollector", PositionOffset=Vector3.new(0,5,8)},
        {Label="Pet Merchant",   DestinationType="WorkspaceChildCFrame", WorkspaceModelName="PetMerchant", WorkspaceChildName="MerchantSign", PositionOffset=Vector3.new(0,5,10)},
        {Label="Friend-O-Tron",  DestinationType="WorkspacePivot",      WorkspaceModelName="FriendOTron",  PositionOffset=Vector3.new(0,5,10)},
        {Label="Rejoin",         DestinationType="Rejoin"},
    }

    local function getDestinationCFrame(dest)
        if dest.DestinationType == "MyPlotFloor" then
            local plot = findMyPlot()
            if not plot then return nil end
            return plot:GetPivot() * CFrame.new(0, dest.PlotFloorYOffset or 5, 0)
        elseif dest.DestinationType == "WorkspacePivot" then
            local model = workspace:FindFirstChild(dest.WorkspaceModelName)
            if not model then return nil end
            return model:GetPivot() * CFrame.new(dest.PositionOffset or Vector3.zero)
        elseif dest.DestinationType == "WorkspaceChildCFrame" then
            local model = workspace:FindFirstChild(dest.WorkspaceModelName)
            if not model then return nil end
            local child = model:FindFirstChild(dest.WorkspaceChildName)
            if not child then return nil end
            return child.CFrame + (dest.PositionOffset or Vector3.zero)
        end
        return nil
    end

    local function teleportToDestination(dest)
        if dest.DestinationType == "Rejoin" then
            rejoinServer()
        else
            local cf = getDestinationCFrame(dest)
            if cf then teleportToCFrame(cf) end
        end
    end

    local function teleportToMyPlot()
        local cf = getDestinationCFrame(env.teleportDestinations[1])
        if cf and teleportToCFrame(cf) then
            env.Library:Notify("Arrived at your plot!", 2)
        else
            env.Library:Notify("Plot not found or character not loaded.", 2)
        end
    end

    env.parseMoney            = parseMoney
    env.getCurrentMoney       = getCurrentMoney
    env.haveEnoughMoney       = haveEnoughMoney
    env.findMyPlot            = findMyPlot
    env.getUpgradeCost        = getUpgradeCost
    env.doPlotUpgrade         = doPlotUpgrade
    env.upgradeSeedLuck       = upgradeSeedLuck
    env.upgradeSeedRolls      = upgradeSeedRolls
    env.teleportToCFrame      = teleportToCFrame
    env.rejoinServer          = rejoinServer
    env.getDestinationCFrame  = getDestinationCFrame
    env.teleportToDestination = teleportToDestination
    env.teleportToMyPlot      = teleportToMyPlot
end
