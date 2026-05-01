local BindService = {}
BindService.Connections = {}

local UIS = game:GetService("UserInputService")
local RP = game:GetService("ReplicatedStorage")

local function GetSkill(Key, InputState)
	--> Loops trough the movesets
	for i, v in script.Movesets:GetChildren() do
		--> Module Check
		if v:IsA("ModuleScript") then
			local mod = require(v)
			
			if not mod.Usable then
				continue
			end
			
			--> Loops trough the keybinds of the skill to check if it matches the input
			for Skill, Info in mod.Skills do
				for i, v in Info.Keybinds["Keyboard"] do
					if Key == v then
						--> Executes the function related to that input
						mod[Skill](InputState, Key)
					end
				end
			end
		end
	end
end

local function IsKeyboard(inp)
	return inp.KeyCode ~= Enum.KeyCode.Unknown
end

local function IsMouse(inp)
	return inp.UserInputType == Enum.UserInputType.MouseButton1 or 
		inp.UserInputType == Enum.UserInputType.MouseButton2 or 
		inp.UserInputType == Enum.UserInputType.MouseButton3
end

function BindService:Init()
	BindService.Connections["Begin"] = UIS.InputBegan:Connect(function(inp, gpe)
		if gpe then return end
		
		--> Support for Keycode and InputType
		
		if IsKeyboard(inp) then
			GetSkill(inp.KeyCode, Enum.UserInputState.Begin)
		elseif IsMouse(inp) then
			GetSkill(inp.UserInputType, Enum.UserInputState.Begin)
		end
	end)

	BindService.Connections["End"] = UIS.InputEnded:Connect(function(inp, gpe)
		if gpe then return end


		if IsKeyboard(inp) then
			GetSkill(inp.KeyCode, Enum.UserInputState.End)
		elseif IsMouse(inp) then
			GetSkill(inp.UserInputType, Enum.UserInputState.End)
		end
	end)
	
	
	game.Players.LocalPlayer.CharacterAdded:Connect(function()
		print("Spawn")
		
		for i, v in script.Movesets:GetChildren() do
			local mod = require(v)
			
			for i, v in mod.Skills do
				mod.ResetSkill(i)
			end
		end
	end)
end



function BindService:ChangeBind(BindType : "Combat", BindName : string, BindPriority : number, NewBind : EnumItem, Platform : string) : () -> ()
	if not script.Movesets[BindType] then 
		warn("Bind doesn't exist.") 
		return
	end
	
	--> Check if it is secondary or primary bind
	if BindPriority == 1 or BindPriority == 2  then
		local BindModule = require(script.Movesets:WaitForChild(BindType))
		
		--> Assign new bind based on priority
		BindModule.Skills[BindName].Keybinds[Platform][BindPriority] = NewBind
	else
		warn("Priority doesn't exist.")
		return 
	end
end

function BindService:SetMovesetEnabled(Moveset : "Combat", boolean)
	local Module = require(script.Movesets:WaitForChild(Moveset))
	
	Module.Usable = boolean
end

return BindService