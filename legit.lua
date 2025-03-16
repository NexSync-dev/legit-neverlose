if getgenv().AimbotRan then return; else getgenv().AimbotRan = true; end

local RunService = game:GetService("RunService");
local Workspace = game:GetService("Workspace");
local Players = game:GetService("Players");
local LocalPlayer = Players.LocalPlayer;
local Camera = Workspace.CurrentCamera;
local Mouse = LocalPlayer:GetMouse();
local Player = nil;

local function GetClosestPlayer()
	local ClosestDistance, ClosestPlayer = math.huge, nil;
	for _, Player in pairs(Players:GetPlayers()) do
		if Player ~= LocalPlayer and Player.Character and Player.Character:FindFirstChild(Aimbot.Hitpart) then
			local Root, Visible = Camera:WorldToScreenPoint(Player.Character[Aimbot.Hitpart].Position);
			if Visible then
				local Distance = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(Root.X, Root.Y)).Magnitude;
				if Distance < ClosestDistance then
					ClosestPlayer = Player;
					ClosestDistance = Distance;
				end
			end
		end
	end
	return ClosestPlayer;
end

Mouse.KeyDown:Connect(function(key)
	if key == getgenv().Aimbot_Keybind:lower() then
		Player = (not Player and GetClosestPlayer()) or nil;
	end
end)

RunService.RenderStepped:Connect(function()
	if not Player or not Aimbot.Status then return; end
	local Hitpart = Player.Character:FindFirstChild(Aimbot.Hitpart);
	if not Hitpart then return; end
	
	-- Proper smoothness scaling: Higher values = slower aim
	local SmoothFactor = math.clamp(1 - (getgenv().Aimbot_Smoothness / 10), 0.1, 1);
	Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, Hitpart.Position), SmoothFactor);
end)
