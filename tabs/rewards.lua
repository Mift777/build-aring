return function(env)
    local T       = env.RewardsTab
    local Remotes = env.Remotes
    local Lib     = env.Library

    -- LEFT: Daily Rewards
    local RewardBox = T:AddLeftGroupbox("Daily Rewards")

    RewardBox:AddToggle("AutoClaimDaily", {
        Text = "Auto Claim Daily Reward", Default = false,
        Callback = function(val)
            _G.AutoClaimDailyReward = val
            if not val then return end
            task.spawn(function()
                while _G.AutoClaimDailyReward do
                    pcall(function()
                        if Remotes:FindFirstChild("ClaimDailyReward") then
                            Remotes.ClaimDailyReward:InvokeServer()
                        end
                    end)
                    task.wait(60)
                end
            end)
        end,
    })

    RewardBox:AddToggle("AutoClaimPlaytime", {
        Text = "Auto Claim Playtime Reward", Default = false,
        Callback = function(val)
            _G.AutoClaimPlaytimeReward = val
            if not val then return end
            task.spawn(function()
                while _G.AutoClaimPlaytimeReward do
                    pcall(function()
                        local r = Remotes:FindFirstChild("ClaimPlaytimeReward")
                        if r then
                            for i = 1, 15 do
                                if not _G.AutoClaimPlaytimeReward then break end
                                r:InvokeServer(i); task.wait(0.2)
                            end
                        end
                    end)
                    task.wait(10)
                end
            end)
        end,
    })

    -- RIGHT: Spin Wheel
    local WheelBox = T:AddRightGroupbox("Spin Wheel")

    WheelBox:AddToggle("AutoSpinWheel", {
        Text = "Auto Spin Wheel", Default = false,
        Callback = function(val)
            _G.AutoSpinWheel = val
            if not val then return end
            task.spawn(function()
                while _G.AutoSpinWheel do
                    pcall(function()
                        local r = Remotes:FindFirstChild("SpinWheel") and Remotes.SpinWheel:FindFirstChild("RequestSpin")
                        if r then r:InvokeServer(false) end
                    end)
                    task.wait(5)
                end
            end)
        end,
    })
end
