local HitboxModule = {}

function HitboxModule.Start(Character : Model, Range : number, Type : string) : Part?
	if Type == "Hitbox" then
		local Hitbox = Instance.new("Part")
		Hitbox.Size = Vector3.new(4, Range, 4)
		Hitbox.Transparency = 0.5
		Hitbox.Anchored = true
		Hitbox.CanCollide = false
		Hitbox.Parent = workspace
		Hitbox.Position = Character.HumanoidRootPart.Position + Character.HumanoidRootPart.CFrame.LookVector * 4
		Hitbox.CFrame = Hitbox.CFrame * CFrame.Angles(math.rad(90), 0, 0)
		Hitbox.Material = Enum.Material.SmoothPlastic
		Hitbox.Color = Color3.fromRGB(255, 0, 0)
		
		local OverlapParam = OverlapParams.new()
		OverlapParam.FilterType = Enum.RaycastFilterType.Exclude
		OverlapParam.FilterDescendantsInstances = {Character}
		
		local Parts = workspace:GetPartsInPart(Hitbox, OverlapParam)
		
		if Parts[1] then
			if Parts[1].Parent:FindFirstChild("Humanoid") and Parts[1].Parent.Humanoid.Health > 0 then
				Hitbox:Destroy()
				
				return Parts[1].Parent
			end
		else
			print("Nothing found")
		end
		
		Hitbox:Destroy()
	elseif Type == "Raycast" then
		local RayParams = RaycastParams.new()
		RayParams.FilterType = Enum.RaycastFilterType.Exclude
		RayParams.FilterDescendantsInstances = {Character}

		local RayResult = workspace:Shapecast(Character.HumanoidRootPart, Character.HumanoidRootPart.CFrame.LookVector * Range, RayParams)

		if RayResult then
			if RayResult.Instance.Parent:FindFirstChild("Humanoid") and RayResult.Instance.Parent.Humanoid.Health > 0 and RayResult.Instance.Parent:GetAttribute("State") ~= 2 then
				return RayResult.Instance.Parent
			end
		end

		if RayResult and RayResult.Instance.Parent:FindFirstChild("Humanoid") and RayResult.Instance.Parent.Humanoid.Health > 0  then
			return RayResult.Instance.Parent
		end
	else
		warn("Did Not input the right type or nil")
	end
end

return HitboxModule