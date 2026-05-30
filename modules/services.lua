return function(env)
    local Players           = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local HttpService       = game:GetService("HttpService")
    local VirtualUser       = game:GetService("VirtualUser")
    local TeleportService   = game:GetService("TeleportService")

    env.Players           = Players
    env.ReplicatedStorage = ReplicatedStorage
    env.HttpService       = HttpService
    env.VirtualUser       = VirtualUser
    env.TeleportService   = TeleportService
    env.LocalPlayer       = Players.LocalPlayer
    env.PlayerGui         = Players.LocalPlayer:WaitForChild("PlayerGui")
    env.Remotes           = ReplicatedStorage:WaitForChild("Remotes", 10)
    env.Shared            = ReplicatedStorage:WaitForChild("Shared", 10)

    Players.LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
        print("[ArkhamHub] Anti-AFK triggered.")
    end)
end
