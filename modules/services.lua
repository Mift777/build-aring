return function(env)
    env.Players           = game:GetService("Players")
    env.ReplicatedStorage = game:GetService("ReplicatedStorage")
    env.RunService        = game:GetService("RunService")
    env.TweenService      = game:GetService("TweenService")
    env.TeleportService   = game:GetService("TeleportService")
    env.LocalPlayer       = env.Players.LocalPlayer
    env.PlayerGui         = env.LocalPlayer:WaitForChild("PlayerGui")
    env.Shared            = env.ReplicatedStorage:FindFirstChild("Shared")

    local ok, r = pcall(function()
        return env.ReplicatedStorage:WaitForChild("Remotes", 10)
    end)
    env.Remotes = ok and r or env.ReplicatedStorage:FindFirstChild("Remotes")
end
