local NotificationLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/IceMinisterq/Notification-Library/Main/Library.lua"))()
NotificationLibrary:SendNotification("Info", "This script isnt the best as I work alone and some features may not be up to what you expect", 8)

if getgenv().AimbotRan then return else getgenv().AimbotRan = true end

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()
local Player = nil

local function GetClosestPlayer()
    local ClosestDistance, ClosestPlayer = math.huge, nil
    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character and Player.Character:FindFirstChild(Aimbot.Hitpart) then
            local Root, Visible = Camera:WorldToScreenPoint(Player.Character[Aimbot.Hitpart].Position)
            if Visible then
                local Distance = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(Root.X, Root.Y)).Magnitude
                if Distance < ClosestDistance then
                    ClosestPlayer = Player
                    ClosestDistance = Distance
                end
            end
        end
    end
    return ClosestPlayer
end

Mouse.KeyDown:Connect(function(key)
    if key == getgenv().Aimbot_Keybind:lower() then
        Player = (not Player and GetClosestPlayer()) or nil
    end
end)

RunService.RenderStepped:Connect(function()
    if not Player or not Aimbot.Status then return end
    local Hitpart = Player.Character:FindFirstChild(Aimbot.Hitpart)
    if not Hitpart then return end

    -- Proper smoothness scaling: Higher values = slower aim
    local SmoothFactor = math.clamp(1 - (getgenv().Aimbot_Smoothness / 10), 0.1, 1)
    Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, Hitpart.Position), SmoothFactor)

    -- M1 Reset (Only if enabled in M1Reset setting)
    if getgenv().M1Reset then
        if Mouse.Target then
            Mouse1Click() -- Trigger the M1 reset when target is present
        end
    end
end)

-- Dash Configuration
local player = game.Players.LocalPlayer
local userInputService = game:GetService("UserInputService")
local tweenService = game:GetService("TweenService")

local DASH_DISTANCE = 27.3  -- Backward dash distance
local DASH_DURATION = 0.15    -- Dash movement duration
local DASH_DELAY = 0.2       -- Delay before dashing
local isDashOnCooldown = false  -- Cooldown flag

local function setupCharacter(character)
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")
    local playerGui = player:WaitForChild("PlayerGui")

    -- Function to create the cooldown UI
    humanoid.AnimationPlayed:Connect(function(track)
        if track.Animation and track.Animation.AnimationId == "rbxassetid://10479335397" then
            isDashOnCooldown = true  -- Set cooldown

            -- Create GUI
            local cooldownGui = Instance.new("ScreenGui")
            cooldownGui.Parent = playerGui
            
            local cooldownText = Instance.new("TextLabel")
            cooldownText.Size = UDim2.new(0, 200, 0, 50)
            cooldownText.Position = UDim2.new(0.5, -100, 0.8, 0)
            cooldownText.BackgroundTransparency = 1
            cooldownText.TextScaled = true
            cooldownText.TextColor3 = Color3.fromRGB(255, 0, 0)
            cooldownText.Font = Enum.Font.SourceSansBold
            cooldownText.Parent = cooldownGui
            
            -- Countdown loop
            for i = 5, 1, -1 do
                cooldownText.Text = "Dash cooldown - " .. i .. "s"
                task.wait(1)
            end
            
            cooldownGui:Destroy()
            isDashOnCooldown = false  -- Remove cooldown
        end
    end)

    local function onKeyPress(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.C and not isDashOnCooldown then  -- Prevent dashing while on cooldown
            -- Load and play animation
            local animation = Instance.new("Animation")
            animation.AnimationId = "rbxassetid://10480793962"
            local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator")
            local animationTrack = animator:LoadAnimation(animation)
            animationTrack:Play()

            -- **Wait before movement starts**
            task.wait(DASH_DELAY)

            -- Corrected movement: move backward using LookVector
            local targetPosition = humanoidRootPart.Position - humanoidRootPart.CFrame.LookVector * DASH_DISTANCE
            local targetCFrame = CFrame.new(targetPosition, targetPosition + humanoidRootPart.CFrame.LookVector)

            -- Tween to new position
            local dashTween = tweenService:Create(
                humanoidRootPart,
                TweenInfo.new(DASH_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {CFrame = targetCFrame}
            )
            dashTween:Play()

            -- Wait for dash to finish
            dashTween.Completed:Wait()

            -- Fire the server with Dash and KeyPress
            local args = {
                [1] = {
                    ["Dash"] = Enum.KeyCode.W,
                    ["Key"] = Enum.KeyCode.Q,
                    ["Goal"] = "KeyPress"
                }
            }

            game:GetService("Players").LocalPlayer.Character.Communicate:FireServer(unpack(args))
        end
    end

    -- Only trigger M1 Reset if enabled in M1Reset setting
    if getgenv().M1Reset then
        userInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                -- M1 Reset logic when enabled
                if Mouse.Target then
                    Mouse1Click() -- Trigger the click reset
                end
            end
        end)
    end

    userInputService.InputBegan:Connect(onKeyPress)
end

-- Setup the script for the current character
if player.Character then
    setupCharacter(player.Character)
end

-- Listen for respawn
player.CharacterAdded:Connect(setupCharacter)
