--[[
 CombatService.luau
 
 By : @callmecrayz on discord
 
 This will hanlde the server side of combat
]]

local CombatService = {}
CombatService._Threads = {}
CombatService.ParryBar = {}

type HitEffects = {
	AnimationName : string,
	VFX : Attachment
}

local TS = game:GetService("TweenService")

local Loader = require(script.Parent.Parent.Loader)
local Hitbox = require(script.Hitbox)

function CreateVFX(VFX : Attachment, Adornee : any)
	
	if VFX then
		local Clone = VFX:Clone()
		Clone.Parent = Adornee.HumanoidRootPart or Adornee
		
		for i, v : ParticleEmitter in Clone:GetDescendants() do
			if v:IsA("ParticleEmitter") then
				v:Emit()
			end
		end 
		
		task.delay(0.5, function()
			Clone:Destroy()
		end)
	else
		warn("VFX does not exist.")
	end
end

function CombatService:Init()
	game.ReplicatedStorage.Remotes.Combat.OnServerEvent:Connect(function(plr, Context)
		if Context == "M1" then
			self:M1(plr.Character)
		elseif Context == "Parry" then
			self:Parry(plr.Character, nil, "Start")
		end
	end)
	
	game.Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Once(function(character)
			self.ParryBar[character] = 0

			print(self.ParryBar)
		end)
	end)
end

function CombatService:Stun(Character : Model, StunnedCharacter : Model,  Duration : number, HitEffects : HitEffects)
	local StateService = Loader:GetService("StateService")
	
	if self._Threads[StunnedCharacter] then
		task.cancel(self._Threads[StunnedCharacter])
		self._Threads[StunnedCharacter] = nil
	end
	
	--> task.spawn for cancellable stuns
	self._Threads[StunnedCharacter] = task.spawn(function()
		--> Check If character is a player and if stun is an animation
		if HitEffects then
			if game.Players:GetPlayerFromCharacter(StunnedCharacter) then
				if game.ReplicatedStorage.Animations:FindFirstChild(HitEffects.AnimationName) then
					game.ReplicatedStorage.Remotes.Animation:FireClient(game.Players:GetPlayerFromCharacter(StunnedCharacter), {
						Context = "Play",
						AnimationName = HitEffects.AnimationName
					})
				end
			end

			if HitEffects.VFX then
				CreateVFX(HitEffects.VFX, StunnedCharacter)
			end
		end

		task.wait(Duration)
		
		--> State Revert after duration
		if game.Players:GetPlayerFromCharacter(StunnedCharacter) then
			StateService:ChangeState(StunnedCharacter, "Idle")
		else
			StunnedCharacter:SetAttribute("State", "Idle")
		end
	end)
end

function CombatService:M1(Character : Model)
	if Character:GetAttribute("State") ~= "M1" then
		if game.Players:GetPlayerFromCharacter(Character) then
			game.ReplicatedStorage.Remotes.Animation:FireClient(game.Players:GetPlayerFromCharacter(Character), {
				Context = "Stop"
			})	
		end
		
		return
	end
	
	print(Character:GetAttribute("State"))
	
	local CharacterFound = Hitbox.Start(Character, 6, "Hitbox")
	
	local StateService = Loader:GetService("StateService")
	
	if CharacterFound then
		local Dot = Character.HumanoidRootPart.CFrame.LookVector:Dot(CharacterFound.HumanoidRootPart.CFrame.LookVector)
		
		if CharacterFound:GetAttribute("State") == "Idle" then
			
			--> Provisional
			CharacterFound.Humanoid:TakeDamage(10)
			
			if game.Players:GetPlayerFromCharacter(CharacterFound) then
				StateService:ChangeState(CharacterFound, "Stunned")
			else
				CharacterFound:SetAttribute("State", "Stunned")
			end
			
			if game.Players:GetPlayerFromCharacter(Character) then
				StateService:ChangeState(Character, "M1End")
			else
				Character:SetAttribute("State", "M1End")
			end
			
			self:Stun(Character, CharacterFound, 1, {
				AnimationName = "Stun",
				VFX = game.ReplicatedStorage.VFX.Stun
			})
			
			if game.Players:GetPlayerFromCharacter(CharacterFound) then
				game.ReplicatedStorage.Remotes.Sound:FireClient(game.Players:GetPlayerFromCharacter(CharacterFound), "M1")
			end
			
			if game.Players:GetPlayerFromCharacter(Character) then
				game.ReplicatedStorage.Remotes.Sound:FireClient(game.Players:GetPlayerFromCharacter(Character), "M1")
			end
			
		elseif CharacterFound:GetAttribute("State") == "Stunned" then
			
			CharacterFound.Humanoid:TakeDamage(10)
			
			task.cancel(self._Threads[CharacterFound])
			
			if game.Players:GetPlayerFromCharacter(CharacterFound) then
				StateService:ChangeState(CharacterFound, "Stunned")
				game.ReplicatedStorage.Remotes.Sound:FireClient(game.Players:GetPlayerFromCharacter(CharacterFound), "M1")
			else
				CharacterFound:SetAttribute("State", "Stunned")
			end

			if game.Players:GetPlayerFromCharacter(Character) then
				game.ReplicatedStorage.Remotes.Sound:FireClient(game.Players:GetPlayerFromCharacter(Character), "M1")
			end
			
			if game.Players:GetPlayerFromCharacter(Character) then
				StateService:ChangeState(Character, "M1End")
			else
				Character:SetAttribute("State", "M1End")
			end
			
			self:Stun(Character, CharacterFound, 1, {
				AnimationName = "Stun",
				VFX = game.ReplicatedStorage.VFX.Stun
			})
		elseif CharacterFound:GetAttribute("State") == "Parry" then
			if self._Threads[CharacterFound] then
				task.cancel(self._Threads[CharacterFound])
				self._Threads[CharacterFound] = nil
			end
			
			self:Parry(CharacterFound, Character, "Sucess")
		elseif CharacterFound:GetAttribute("State") == "M1" and Dot < -0.7 then
			
			if self._Threads[CharacterFound] then
				task.cancel(self._Threads[CharacterFound])
				self._Threads[CharacterFound] = nil
			end
			
			if self._Threads[Character] then
				task.cancel(self._Threads[Character])
				self._Threads[Character] = nil
			end

			self:Clash(Character, CharacterFound)
		else
			CharacterFound.Humanoid:TakeDamage(10)
			
			if self._Threads[CharacterFound] then
				task.cancel(self._Threads[CharacterFound])
				self._Threads[CharacterFound] = nil
			end

			if game.Players:GetPlayerFromCharacter(CharacterFound) then
				StateService:ChangeState(CharacterFound, "Stunned")
				game.ReplicatedStorage.Remotes.Sound:FireClient(game.Players:GetPlayerFromCharacter(CharacterFound), "M1")
			else
				CharacterFound:SetAttribute("State", "Stunned")
			end

			if game.Players:GetPlayerFromCharacter(Character) then
				game.ReplicatedStorage.Remotes.Sound:FireClient(game.Players:GetPlayerFromCharacter(Character), "M1")
			end

			self:Stun(Character, CharacterFound, 1, {
				AnimationName = "Stun",
				VFX = game.ReplicatedStorage.VFX.Stun
			})
		end
	end
end

function CombatService:Parry(Character, CharacterParried, Context)
	local StateService = Loader:GetService("StateService")
	
	if Context == "Start" then
		StateService:ChangeState(Character, "Parry")
		
		local Highlight = Instance.new("Highlight")
		Highlight.FillTransparency = 0.5
		Highlight.OutlineTransparency = 0.5
		Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
		Highlight.FillColor = Color3.fromRGB(255,255,255)
		Highlight.Parent = Character
		Highlight.Name = "ParryHighlight"
		
		task.delay(0.5, function()
			local Tween = TS:Create(Highlight, TweenInfo.new(1), {OutlineTransparency = 1, FillTransparency = 1})
			Tween:Play()
			
			Tween.Completed:Once(function()
				if Highlight then
					Highlight:Destroy()
				end
				
				Tween:Destroy()
			end)
		end)
		
		self._Threads[Character] = task.delay(1, function()
			StateService:ChangeState(Character, "Idle")
		end)
	else
		if self._Threads[Character] then
			task.cancel(self._Threads[Character])
			self._Threads[Character] = nil
		end
		
		if game.Players:GetPlayerFromCharacter(Character) then
			StateService:ChangeState(Character, "Sucess")
			game.ReplicatedStorage.Remotes.Sound:FireClient(game.Players:GetPlayerFromCharacter(Character), "ParrySucess")
			game.ReplicatedStorage.Remotes.Animation:FireClient(game.Players:GetPlayerFromCharacter(Character), {Context = "Stop"})
		else
			Character:SetAttribute("State", "Sucess")
		end
		
		CharacterParried.Humanoid:TakeDamage(3)
		
		if Character:FindFirstChild("ParryHighlight") then
			Character.ParryHighlight:Destroy()
		end
		
		local Highlight = Instance.new("Highlight")
		Highlight.FillTransparency = 0.5
		Highlight.OutlineTransparency = 0.5
		Highlight.OutlineColor = Color3.fromRGB(255, 170, 0)
		Highlight.FillColor = Color3.fromRGB(255,170,0)
		Highlight.Parent = Character
		Highlight.Name = "ParryHighlight"

		task.delay(0.5, function()
			local Tween = TS:Create(Highlight, TweenInfo.new(1), {OutlineTransparency = 1, FillTransparency = 1})
			Tween:Play()

			Tween.Completed:Once(function()
				Highlight:Destroy()
				Tween:Destroy()
			end)
		end)
		
		if game.Players:GetPlayerFromCharacter(CharacterParried) then
			game.ReplicatedStorage.Remotes.Sound:FireClient(game.Players:GetPlayerFromCharacter(CharacterParried), "ParrySucess")
			self.ParryBar[CharacterParried] += 20
			
			if self.ParryBar[CharacterParried] >= 100 then
				self.ParryBar[CharacterParried] = 0
				print("Dazed")
			end
		end
		
		CreateVFX(game.ReplicatedStorage.VFX.Parry, Character)
	end
end

function CombatService:Clash(Character1 : Model, Character2 : Model, ClashAnimName)
	local StateService = Loader:GetService("StateService")
	
	
	--> Store Original Character Speeds
	local OriginalSpeed = Character1.Humanoid.WalkSpeed
	local OriginalSpeed2 = Character2.Humanoid.WalkSpeed
	
	--> Start Clash States
	if game.Players:GetPlayerFromCharacter(Character1) then
		game.ReplicatedStorage.Remotes.Animation:FireClient(game.Players:GetPlayerFromCharacter(Character1), {Context = "Stop"})
		StateService:ChangeState(Character1, "Clash")
	else
		Character1:SetAttribute("State", "Clash")
	end
	
	if game.Players:GetPlayerFromCharacter(Character2) then
		game.ReplicatedStorage.Remotes.Animation:FireClient(game.Players:GetPlayerFromCharacter(Character1), {Context = "Stop"})
		StateService:ChangeState(Character2, "Clash")
	else
		Character2:SetAttribute("State", "Clash")
	end
	
	
	--> Reset to Idle State
	task.delay(1, function()
		if game.Players:GetPlayerFromCharacter(Character1) then
			StateService:ChangeState(Character1, "Idle")
			game.ReplicatedStorage.Remotes.Animation:FireClient(game.Players:GetPlayerFromCharacter(Character1), {Context = "Play", AnimationName = "Recover"})
		else
			Character1:SetAttribute("State", "Idle")
		end
		
		if game.Players:GetPlayerFromCharacter(Character2) then
			StateService:ChangeState(Character2, "Idle")
			game.ReplicatedStorage.Remotes.Animation:FireClient(game.Players:GetPlayerFromCharacter(Character2), {Context = "Play", AnimationName = "Recover"})
		else
			Character2:SetAttribute("State", "Idle")
		end
		
		Character1.Humanoid.WalkSpeed = OriginalSpeed
		Character2.Humanoid.WalkSpeed = OriginalSpeed2
		
		Character1.HumanoidRootPart.AssemblyLinearVelocity = -Character1.HumanoidRootPart.CFrame.LookVector * 200
		Character2.HumanoidRootPart.AssemblyLinearVelocity = -Character2.HumanoidRootPart.CFrame.LookVector * 200
	end)
end

return CombatService
