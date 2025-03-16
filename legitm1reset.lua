local player = game.Players.LocalPlayer
local userInputService = game:GetService("UserInputService")
local tweenService = game:GetService("TweenService")

local DASH_DISTANCE = -27.3  -- Backward dash distance
local DASH_DURATION = 0.2    -- Dash duration (adjust for speed)
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

            -- Calculate target position
            local targetPosition = humanoidRootPart.Position + (humanoidRootPart.CFrame.LookVector * DASH_DISTANCE)

            -- Tween to new position
            local dashTween = tweenService:Create(
                humanoidRootPart,
                TweenInfo.new(DASH_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Position = targetPosition}
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
