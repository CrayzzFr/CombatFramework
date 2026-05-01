local Combat = {}
Combat.Usable = true
Combat.Character = "Base"

local plr = game.Players.LocalPlayer

local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local RNS = game:GetService("RunService")

local Loader = require(game.ReplicatedStorage.Modules.Client.Loader)
local Velocity = require(script.Parent.Parent.Parent.Parent.Parent.Packages.Velocity)

local AnimationService = Loader:GetService("AnimationService")

Combat.Skills = {
	["M1"] = {
		Keybinds = {
			["Keyboard"] = {Enum.UserInputType.MouseButton1};
			["Controller"] = {Enum.KeyCode.ButtonX};
		};
		
		Info = {
			Current = 0;
			Max = 4;
			LastM1 = 0;
			ResetTime = 1;
			Usable = true;
			Speed = 6;
		};
	},
	
	["Parry"] = {
		Keybinds = {
			["Keyboard"] = {Enum.KeyCode.F};
			["Controller"] = {Enum.KeyCode.ButtonY};
		};
		
		Info = {
			Usable = true;
			Speed = 5;
			Cooldown = 4;
		};
	};
	
	["Dash"] = {
		Keybinds = {
			["Keyboard"] = {Enum.KeyCode.Q};
			["Controller"] = {Enum.KeyCode.ButtonL2};
		};
		
		Info = {
			Usable = true;
			Speed = 5;
		};
	},
}

function GetInfo(SkillName)
	return Combat.Skills[SkillName].Info
end

function Combat.ResetSkill(SkillName)
	local Info = GetInfo(SkillName)
	
	if SkillName == "M1" then
		Info.Current = 0
		Info.Usable = true
		Info.LastM1 = 0
	elseif SkillName == "Parry" then
		Info.Usable = true
	end
end

function Combat.M1(InputState, Key)
	if InputState == Enum.UserInputState.End or game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:GetAttribute("State") ~= "Idle" then
		return
	end
	
	local M1 = GetInfo("M1")
	
	if not M1.Usable or not Combat.Usable then 
		return 
	end
	
	print(AnimationService.Animations)
	
	local OriginalSpeed = game.Players.LocalPlayer.Character:WaitForChild("Humanoid").WalkSpeed
	game.Players.LocalPlayer.Character:WaitForChild("Humanoid").WalkSpeed = M1.Speed
	
	if tick() - M1.LastM1 >= M1.ResetTime then
		M1.Current = 1
	else
		M1.Current += 1
	end
	
	M1.LastM1 = tick()
	
	M1.Usable = false
	Combat.Usable = false
	
	game.ReplicatedStorage.Remotes.State:FireServer("M1")
	
	AnimationService:PlayAnimation(`M{M1.Current}_{Combat.Character}`)
	
	task.delay(0.2 , function()
		game.ReplicatedStorage.Remotes.Combat:FireServer("M1")
	end)
	
	task.wait(0.4)
	
	if game.Players.LocalPlayer.Character:GetAttribute("State") == "M1End" or game.Players.LocalPlayer.Character:GetAttribute("State") == "M1" then
		game.ReplicatedStorage.Remotes.State:FireServer("Idle")
		
		game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = OriginalSpeed

		OriginalSpeed = nil
	end
	
	Combat.Usable = true
	
	if M1.Current >= M1.Max then
		task.wait(1)
		M1.Current = 0
		M1.Usable = true
	else
		M1.Usable = true
	end
end

function Combat.Parry(InputState, Key)
	if InputState == Enum.UserInputState.End or game.Players.LocalPlayer.Character:GetAttribute("State") ~= "Idle" or not Combat.Usable then
		return
	end
	
	local Info = GetInfo("Parry")
	
	if not Info.Usable then
		return
	end
	
	Combat.Usable = false
	Info.Usable = false
	
	game.ReplicatedStorage.Remotes.Combat:FireServer("Parry")
	game.ReplicatedStorage.SFX.Parry:Play()
	
	AnimationService:PlayAnimation(`Parry_{Combat.Character}`)
	
	local OriginalSpeed = game.Players.LocalPlayer.Character.Humanoid.WalkSpeed
	
	game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Info.Speed
	
	task.wait(0.7)
	game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = OriginalSpeed
	Combat.Usable = true
	
	if game.Players.LocalPlayer.Character:GetAttribute("State") == "Sucess" then
		Info.Usable = true
	else
		task.wait(Info.Cooldown)
		Info.Usable = true
	end
	
	if game.Players.LocalPlayer.Character:GetAttribute("State") ~= "Idle" then
		game.ReplicatedStorage.Remotes.State:FireServer("Idle")
	end
end

function Combat.Dash(InputState)
	if InputState == Enum.UserInputState.End or game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:GetAttribute("State") ~= "Idle" or not Combat.Usable then
		return
	end
	
	local Info = GetInfo("Dash")
	
	if not Info.Usable then
		return
	end
	
	Info.Usable = false
	
	local AnimationService = Loader:GetService("AnimationService")
	
	Combat.Usable = false
	
	local Connection = nil
	
	AnimationService:PlayAnimation("Dash")
	game.ReplicatedStorage.Remotes.State:FireServer("Dash")
	
	Connection = RNS.RenderStepped:Connect(function(dt)
		game.Players.LocalPlayer.Character.HumanoidRootPart.AssemblyLinearVelocity = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame.LookVector * 50
	end)
	
	task.delay(0.3, function()
		Connection:Disconnect()
		Combat.Usable = true
		game.ReplicatedStorage.Remotes.State:FireServer("Idle")
	end)
	
	task.wait(2)
	Info.Usable = true
end

return Combat