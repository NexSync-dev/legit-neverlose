-- Dash settings
local DASH_DISTANCE = 27.3  -- Backward dash distance
local DASH_DURATION = 0.15   -- Dash movement duration
local DASH_DELAY = 0.2      -- Delay before dashing
local isDashOnCooldown = false  -- Cooldown flag

local player = game.Players.LocalPlayer
local userInputService = game:GetService("UserInputService")
local tweenService = game:GetService("TweenService")

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

    userInputService.InputBegan:Connect(onKeyPress)
end

-- Setup the script for the current character
if player.Character then
    setupCharacter(player.Character)
end

-- Listen for respawn
player.CharacterAdded:Connect(setupCharacter)

-- Aimbot System
local function aimAtTarget(target)
    if not target then return end
    local humanoidRootPart = target:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        local characterRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if characterRoot then
            local newCFrame = CFrame.new(characterRoot.Position, humanoidRootPart.Position)
            local smoothness = getgenv().AimbotSettings.Smoothness or 0.5

            local aimTween = tweenService:Create(
                characterRoot,
                TweenInfo.new(smoothness, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {CFrame = newCFrame}
            )
            aimTween:Play()
        end
    end
end

local function findNearestTarget()
    local closestTarget = nil
    local shortestDistance = math.huge
    local characterRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")

    if not characterRoot then return nil end

    for _, otherPlayer in pairs(game.Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
            if otherRoot then
                local distance = (characterRoot.Position - otherRoot.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestTarget = otherPlayer.Character
                end
            end
        end
    end

    return closestTarget
end

game:GetService("RunService").RenderStepped:Connect(function()
    if getgenv().Aimbot then
        local target = findNearestTarget()
        aimAtTarget(target)
    end
end)

-- Aimbot Toggle Keybind
userInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == getgenv().AimbotKeybind then
        getgenv().Aimbot = not getgenv().Aimbot  -- Toggle Aimbot
    end
end)

-- M1 Reset
if getgenv().M1Reset then
    game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local args = {
                [1] = {
                    ["Reset"] = true,
                    ["Goal"] = "M1Reset"
                }
            }
            game:GetService("Players").LocalPlayer.Character.Communicate:FireServer(unpack(args))
        end
    end)
end
