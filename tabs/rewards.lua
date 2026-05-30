return function(env)
    local T       = env.RewardsTab
    local Remotes = env.Remotes

    T:CreateSection("Recompensas Diárias")

    T:CreateToggle({
        Name = "Auto Coletar Daily Reward",
        CurrentValue = false,
        Flag = "AutoDailyReward",
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

    T:CreateToggle({
        Name = "Auto Coletar Playtime Reward",
        CurrentValue = false,
        Flag = "AutoPlaytimeReward",
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

    T:CreateSection("Spin Wheel")

    T:CreateToggle({
        Name = "Auto Girar Roleta",
        CurrentValue = false,
        Flag = "AutoSpinWheel",
        Callback = function(val)
            _G.AutoSpinWheel = val
            if not val then return end
            task.spawn(function()
                while _G.AutoSpinWheel do
                    pcall(function()
                        local r = Remotes:FindFirstChild("SpinWheel")
                                  and Remotes.SpinWheel:FindFirstChild("RequestSpin")
                        if r then r:InvokeServer(false) end
                    end)
                    task.wait(5)
                end
            end)
        end,
    })
end
