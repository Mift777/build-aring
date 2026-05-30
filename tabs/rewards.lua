return function(env)
    local T       = env.RewardsTab
    local Remotes = env.Remotes

    local RewardBox = T:AddLeftGroupbox('Daily Rewards')

    RewardBox:AddToggle('AutoClaimDaily', {
        Text = 'Auto Claim Daily Reward', Default = false,
        Callback = function(val) _G.AutoClaimDailyReward = val end,
    })

    RewardBox:AddToggle('AutoClaimPlaytime', {
        Text = 'Auto Claim Playtime Reward', Default = false,
        Callback = function(val) _G.AutoClaimPlaytimeReward = val end,
    })

    task.spawn(function()
        while true do
            if _G.AutoClaimDailyReward then
                pcall(function()
                    if Remotes:FindFirstChild('ClaimDailyReward') then Remotes.ClaimDailyReward:FireServer() end
                end)
            end
            if _G.AutoClaimPlaytimeReward then
                pcall(function()
                    if Remotes:FindFirstChild('ClaimPlaytimeReward') then Remotes.ClaimPlaytimeReward:FireServer() end
                end)
            end
            task.wait(60)
        end
    end)
end
