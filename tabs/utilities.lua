return function(env)
    local T       = env.UtilitiesTab
    local Lib     = env.Library
    local LP      = env.LocalPlayer
    local tpDests = env.teleportDestinations
    local tpDest  = env.teleportToDestination
    local tpPlot  = env.teleportToMyPlot
    local rejoin  = env.rejoinServer

    -- LEFT: Purchase
    local PurchBox = T:AddLeftGroupbox('Purchase')

    PurchBox:AddToggle('SkipMoneyCheck', {
        Text = 'Skip Money Check',
        Tooltip = 'Only enable if auto-buy bugs out.',
        Default = false,
        Callback = function(val) _G.SkipMoneyCheck = val end,
    })

    -- RIGHT: Teleport
    local TpBox = T:AddRightGroupbox('Teleport')

    for _, dest in ipairs(tpDests) do
        TpBox:AddButton({
            Text = dest.Label,
            Func = function() tpDest(dest) end,
        })
    end

    -- LEFT: Floating TP Button
    local FloatBox = T:AddLeftGroupbox('Floating TP Button')

    local floatingGui, floatingBtn, floatingEnabled = nil, nil, false

    local function createFloatingTPButton()
        local gui = Instance.new('ScreenGui')
        gui.Name = 'LamduckFloatingTP'
        gui.ResetOnSpawn = false
        gui.Enabled = false
        pcall(function() gui.Parent = LP:WaitForChild('PlayerGui') end)

        local btn = Instance.new('TextButton')
        btn.Size = UDim2.new(0,48,0,32)
        btn.Position = UDim2.new(0.8,0,0.2,0)
        btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.Text = 'TP'
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.Parent = gui
        Instance.new('UICorner', btn).CornerRadius = UDim.new(0,6)

        local frame = Instance.new('Frame')
        frame.Position = UDim2.new(0,0,0,32)
        frame.Size = UDim2.new(0,140,0,0)
        frame.AutomaticSize = Enum.AutomaticSize.Y
        frame.BackgroundTransparency = 1
        frame.Visible = false
        frame.Parent = btn
        local ll = Instance.new('UIListLayout', frame)
        ll.Padding = UDim.new(0,5)
        ll.SortOrder = Enum.SortOrder.LayoutOrder

        for idx, dest in ipairs(tpDests) do
            local db = Instance.new('TextButton')
            db.Size = UDim2.new(1,0,0,32)
            db.BackgroundColor3 = Color3.fromRGB(30,30,30)
            db.TextColor3 = Color3.fromRGB
