-- BrainrotSpawner.luau
-- Builds blocky brainrot models from parts and runs the conveyor belt:
-- spawning, movement along the belt and despawning at the far end.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))

local BrainrotSpawner = {}
BrainrotSpawner.ClickedCallback = function(_player, _beltId) end

local MODEL_SCALE = 2.1

local beltEntries = {}
local nextBeltId = 1
local beltFolder = nil
local worldMap = nil

local function makeModelPart(model, baseCFrame, name, size, offset, color, material, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	if shape then
		part.Shape = shape
	end
	part.Anchored = true
	part.CanCollide = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CFrame = baseCFrame * CFrame.new(offset)
	part.Parent = model
	return part
end

local function addCharacterFeature(model, baseCFrame, characterEntry)
	local accent = characterEntry.AccentColor
	local feature = characterEntry.Feature
	if feature == "Phone" then
		makeModelPart(model, baseCFrame, "Phone", Vector3.new(0.35, 0.9, 0.15), Vector3.new(1.15, 0.3, 0), accent, Enum.Material.SmoothPlastic)
	elseif feature == "Sword" then
		makeModelPart(model, baseCFrame, "SwordBlade", Vector3.new(0.18, 1.6, 0.18), Vector3.new(1.25, 0.4, 0), Color3.fromRGB(220, 220, 230), Enum.Material.Metal)
		makeModelPart(model, baseCFrame, "SwordGuard", Vector3.new(0.7, 0.18, 0.3), Vector3.new(1.25, -0.35, 0), accent, Enum.Material.SmoothPlastic)
	elseif feature == "Headphones" then
		makeModelPart(model, baseCFrame, "HeadphoneBand", Vector3.new(1.9, 0.25, 0.5), Vector3.new(0, 1.15, 0), accent, Enum.Material.SmoothPlastic)
		makeModelPart(model, baseCFrame, "EarCupL", Vector3.new(0.35, 0.8, 0.8), Vector3.new(-1.0, 0.65, 0), accent, Enum.Material.SmoothPlastic)
		makeModelPart(model, baseCFrame, "EarCupR", Vector3.new(0.35, 0.8, 0.8), Vector3.new(1.0, 0.65, 0), accent, Enum.Material.SmoothPlastic)
	elseif feature == "CaptainHat" then
		makeModelPart(model, baseCFrame, "HatTop", Vector3.new(1.5, 0.45, 1.5), Vector3.new(0, 1.25, 0), Color3.fromRGB(250, 250, 250), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		makeModelPart(model, baseCFrame, "HatBrim", Vector3.new(0.9, 0.15, 0.7), Vector3.new(0, 1.05, 0.75), accent, Enum.Material.SmoothPlastic)
	elseif feature == "Bubblegum" then
		makeModelPart(model, baseCFrame, "Bubble", Vector3.new(0.9, 0.9, 0.9), Vector3.new(0, 0.35, 0.95), Color3.fromRGB(255, 150, 200), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	elseif feature == "Toilet" then
		makeModelPart(model, baseCFrame, "ToiletBowl", Vector3.new(1.3, 0.8, 1.3), Vector3.new(0, -0.9, 0.3), Color3.fromRGB(250, 250, 250), Enum.Material.SmoothPlastic)
		makeModelPart(model, baseCFrame, "ToiletTank", Vector3.new(1.3, 1.1, 0.45), Vector3.new(0, -0.4, -0.75), Color3.fromRGB(250, 250, 250), Enum.Material.SmoothPlastic)
	elseif feature == "Crown" then
		makeModelPart(model, baseCFrame, "CrownBase", Vector3.new(1.5, 0.5, 1.5), Vector3.new(0, 1.3, 0), Color3.fromRGB(255, 200, 40), Enum.Material.Metal)
		makeModelPart(model, baseCFrame, "CrownPointL", Vector3.new(0.35, 0.6, 0.35), Vector3.new(-0.5, 1.75, 0), Color3.fromRGB(255, 200, 40), Enum.Material.Metal)
		makeModelPart(model, baseCFrame, "CrownPointR", Vector3.new(0.35, 0.6, 0.35), Vector3.new(0.5, 1.75, 0), Color3.fromRGB(255, 200, 40), Enum.Material.Metal)
		makeModelPart(model, baseCFrame, "CrownGem", Vector3.new(0.35, 0.35, 0.35), Vector3.new(0, 1.3, 0.8), accent, Enum.Material.Neon, Enum.PartType.Ball)
	elseif feature == "Glasses" then
		makeModelPart(model, baseCFrame, "GlassL", Vector3.new(0.65, 0.65, 0.12), Vector3.new(-0.45, 0.45, 0.92), Color3.fromRGB(30, 30, 35), Enum.Material.SmoothPlastic)
		makeModelPart(model, baseCFrame, "GlassR", Vector3.new(0.65, 0.65, 0.12), Vector3.new(0.45, 0.45, 0.92), Color3.fromRGB(30, 30, 35), Enum.Material.SmoothPlastic)
		makeModelPart(model, baseCFrame, "GlassBridge", Vector3.new(0.3, 0.12, 0.12), Vector3.new(0, 0.5, 0.92), Color3.fromRGB(30, 30, 35), Enum.Material.SmoothPlastic)
	elseif feature == "Moon" then
		makeModelPart(model, baseCFrame, "MoonProp", Vector3.new(0.8, 0.8, 0.8), Vector3.new(0.7, 1.9, 0), Color3.fromRGB(245, 240, 200), Enum.Material.Neon, Enum.PartType.Ball)
	elseif feature == "Orb" then
		makeModelPart(model, baseCFrame, "OrbProp", Vector3.new(0.85, 0.85, 0.85), Vector3.new(0, 2.0, 0), accent, Enum.Material.Neon, Enum.PartType.Ball)
	elseif feature == "Bagel" then
		makeModelPart(model, baseCFrame, "BagelRing", Vector3.new(1.4, 0.45, 1.4), Vector3.new(0, 1.45, 0), characterEntry.BodyColor, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		makeModelPart(model, baseCFrame, "BagelHole", Vector3.new(0.5, 0.5, 0.5), Vector3.new(0, 1.45, 0), Color3.fromRGB(60, 45, 30), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	elseif feature == "Waffle" then
		makeModelPart(model, baseCFrame, "WaffleProp", Vector3.new(1.5, 0.3, 1.5), Vector3.new(0, 1.4, 0), Color3.fromRGB(220, 165, 80), Enum.Material.SmoothPlastic)
		makeModelPart(model, baseCFrame, "WaffleSyrup", Vector3.new(1.1, 0.34, 1.1), Vector3.new(0, 1.42, 0), accent, Enum.Material.SmoothPlastic)
	elseif feature == "Antenna" then
		makeModelPart(model, baseCFrame, "AntennaStem", Vector3.new(0.14, 1.1, 0.14), Vector3.new(0, 1.6, 0), Color3.fromRGB(90, 90, 100), Enum.Material.Metal, Enum.PartType.Cylinder)
		makeModelPart(model, baseCFrame, "AntennaTip", Vector3.new(0.45, 0.45, 0.45), Vector3.new(0, 2.25, 0), accent, Enum.Material.Neon, Enum.PartType.Ball)
	elseif feature == "TopHat" then
		makeModelPart(model, baseCFrame, "TopHatBrim", Vector3.new(1.7, 0.18, 1.7), Vector3.new(0, 1.15, 0), Color3.fromRGB(25, 25, 30), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		makeModelPart(model, baseCFrame, "TopHatTop", Vector3.new(1.1, 0.95, 1.1), Vector3.new(0, 1.7, 0), Color3.fromRGB(25, 25, 30), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		makeModelPart(model, baseCFrame, "TopHatBand", Vector3.new(1.16, 0.3, 1.16), Vector3.new(0, 1.35, 0), accent, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	elseif feature == "Umbrella" then
		local handle = makeModelPart(model, baseCFrame, "UmbrellaHandle", Vector3.new(0.14, 1.6, 0.14), Vector3.new(1.2, 0.6, 0), Color3.fromRGB(100, 70, 40), Enum.Material.Wood, Enum.PartType.Cylinder)
		handle.CFrame = baseCFrame * CFrame.new(1.2, 0.6, 0) * CFrame.Angles(0, 0, math.rad(20))
		makeModelPart(model, baseCFrame, "UmbrellaCanopy", Vector3.new(2.4, 0.35, 2.4), Vector3.new(1.45, 1.5, 0), accent, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	elseif feature == "Rocket" then
		makeModelPart(model, baseCFrame, "RocketBody", Vector3.new(0.8, 1.7, 0.8), Vector3.new(0, 0.5, -0.95), Color3.fromRGB(250, 250, 250), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		makeModelPart(model, baseCFrame, "RocketCap", Vector3.new(0.7, 0.7, 0.7), Vector3.new(0, 1.55, -0.95), accent, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		makeModelPart(model, baseCFrame, "RocketFlame", Vector3.new(0.45, 0.7, 0.45), Vector3.new(0, -0.6, -0.95), Color3.fromRGB(255, 130, 30), Enum.Material.Neon, Enum.PartType.Cylinder)
	elseif feature == "IceCream" then
		makeModelPart(model, baseCFrame, "ConeProp", Vector3.new(0.55, 0.9, 0.55), Vector3.new(1.2, 0.1, 0.3), Color3.fromRGB(215, 175, 110), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		makeModelPart(model, baseCFrame, "ScoopProp", Vector3.new(0.85, 0.85, 0.85), Vector3.new(1.2, 0.85, 0.3), accent, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	elseif feature == "Mushroom" then
		makeModelPart(model, baseCFrame, "MushroomStem", Vector3.new(0.5, 0.6, 0.5), Vector3.new(0, 1.3, 0), Color3.fromRGB(245, 240, 225), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		makeModelPart(model, baseCFrame, "MushroomCap", Vector3.new(1.6, 0.7, 1.6), Vector3.new(0, 1.75, 0), accent, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		makeModelPart(model, baseCFrame, "MushroomDotL", Vector3.new(0.28, 0.28, 0.28), Vector3.new(-0.4, 1.95, 0.25), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		makeModelPart(model, baseCFrame, "MushroomDotR", Vector3.new(0.28, 0.28, 0.28), Vector3.new(0.45, 1.9, -0.2), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	end
end

function BrainrotSpawner.BuildBrainrotModel(characterEntry, mutationName, position, yaw, showCost, scaleOverride)
	local scale = scaleOverride or MODEL_SCALE
	local model = Instance.new("Model")
	model.Name = characterEntry.Id

	local baseCFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(yaw or 0), 0)

	local bodyColor = characterEntry.BodyColor
	local tintBody = mutationName == "Golden" or mutationName == "Diamond" or mutationName == "Candy" or mutationName == "Void"
	if tintBody then
		bodyColor = BrainrotCatalog.GetMutationColor(mutationName)
	end

	local scaleFactor = scale / MODEL_SCALE
	local body = makeModelPart(model, baseCFrame, "Body", Vector3.new(1.7 * scaleFactor, 1.9 * scaleFactor, 1.2 * scaleFactor), Vector3.new(0, 0, 0), bodyColor, Enum.Material.SmoothPlastic)
	model.PrimaryPart = body

	local eyeColor = Color3.fromRGB(25, 25, 30)
	local eyeMaterial = Enum.Material.SmoothPlastic
	if mutationName == "Void" then
		eyeColor = characterEntry.AccentColor
		eyeMaterial = Enum.Material.Neon
	end
	makeModelPart(model, baseCFrame, "EyeL", Vector3.new(0.28, 0.4, 0.12), Vector3.new(-0.4, 0.4, 0.62), eyeColor, eyeMaterial, Enum.PartType.Ball)
	makeModelPart(model, baseCFrame, "EyeR", Vector3.new(0.28, 0.4, 0.12), Vector3.new(0.4, 0.4, 0.62), eyeColor, eyeMaterial, Enum.PartType.Ball)
	makeModelPart(model, baseCFrame, "FootL", Vector3.new(0.6, 0.35, 0.9), Vector3.new(-0.45, -1.1, 0.1), characterEntry.AccentColor, Enum.Material.SmoothPlastic)
	makeModelPart(model, baseCFrame, "FootR", Vector3.new(0.6, 0.35, 0.9), Vector3.new(0.45, -1.1, 0.1), characterEntry.AccentColor, Enum.Material.SmoothPlastic)

	addCharacterFeature(model, baseCFrame, characterEntry)

	-- Billboard label.
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromOffset(240, showCost and 90 or 70)
	gui.StudsOffset = Vector3.new(0, 3.2, 0)
	gui.AlwaysOnTop = true
	gui.Parent = body
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.35
	label.BackgroundColor3 = Color3.fromRGB(30, 28, 40)
	label.Font = Enum.Font.FredokaOne
	label.TextSize = 16
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	local income = BrainrotCatalog.GetIncomePerSecond(characterEntry, mutationName)
	local displayName = BrainrotCatalog.GetDisplayName(characterEntry, mutationName)
	if showCost then
		label.Text = displayName .. "\n" .. characterEntry.Rarity .. "  $" .. income .. "/s\n$" .. characterEntry.Cost
	else
		label.Text = displayName .. "\n" .. characterEntry.Rarity .. "  $" .. income .. "/s"
	end
	label.Parent = gui
	-- Colour the label's rarity feel via the text colour of the name line is
	-- not separable in one label, so tint the background edge instead.
	gui.Adornee = body

	if mutationName == "Rainbow" then
		task.spawn(function()
			local hue = 0
			while model.Parent do
				hue = (hue + 0.01) % 1
				body.Color = Color3.fromHSV(hue, 0.75, 1)
				task.wait(0.1)
			end
		end)
	elseif mutationName == "Galaxy" then
		task.spawn(function()
			local violet = BrainrotCatalog.GetMutationColor("Galaxy")
			local cyan = Color3.fromRGB(90, 230, 255)
			local t = 0
			while model.Parent do
				t += 0.02
				local blend = (math.sin(t) + 1) / 2
				body.Color = violet:Lerp(cyan, blend)
				task.wait(0.1)
			end
		end)
	end

	return model
end

function BrainrotSpawner.SpawnBrainrotOnConveyor()
	if #beltEntries >= BrainrotCatalog.MaxBeltBrainrots then
		return
	end
	local rarityName = BrainrotCatalog.RollRarity()
	local characterEntry = BrainrotCatalog.PickRandomCharacterOfRarity(rarityName)
	local mutationName = BrainrotCatalog.RollMutation()
	local beltId = nextBeltId
	nextBeltId += 1
	local model = BrainrotSpawner.BuildBrainrotModel(characterEntry, mutationName, Vector3.new(BrainrotCatalog.BeltStartX, BrainrotCatalog.BeltTopY + 2, 0), 90, true)
	model:SetAttribute("BeltId", beltId)
	local detector = Instance.new("ClickDetector")
	detector.MaxActivationDistance = 32
	detector.Parent = model.PrimaryPart
	detector.MouseClick:Connect(function(player)
		BrainrotSpawner.ClickedCallback(player, beltId)
	end)
	if beltFolder then
		model.Parent = beltFolder
	else
		model.Parent = Workspace
	end
	table.insert(beltEntries, {
		Id = beltId,
		CharacterId = characterEntry.Id,
		Mutation = mutationName,
		Model = model,
		X = BrainrotCatalog.BeltStartX,
	})
end

function BrainrotSpawner.GetBeltBrainrotById(beltId)
	for _, entry in ipairs(beltEntries) do
		if entry.Id == beltId then
			return entry
		end
	end
	return nil
end

function BrainrotSpawner.RemoveBeltBrainrot(beltId)
	for index, entry in ipairs(beltEntries) do
		if entry.Id == beltId then
			if entry.Model then
				entry.Model:Destroy()
			end
			table.remove(beltEntries, index)
			return true
		end
	end
	return false
end

function BrainrotSpawner.ClearAllBeltBrainrots()
	for _, entry in ipairs(beltEntries) do
		if entry.Model then
			entry.Model:Destroy()
		end
	end
	beltEntries = {}
end

function BrainrotSpawner.GetBeltBrainrotsForClient()
	local out = {}
	for _, entry in ipairs(beltEntries) do
		local characterEntry = BrainrotCatalog.GetCharacterById(entry.CharacterId)
		if characterEntry then
			table.insert(out, {
				Id = entry.Id,
				CharacterId = entry.CharacterId,
				Name = BrainrotCatalog.GetDisplayName(characterEntry, entry.Mutation),
				Rarity = characterEntry.Rarity,
				Rate = BrainrotCatalog.GetIncomePerSecond(characterEntry, entry.Mutation),
				Cost = characterEntry.Cost,
				Mutation = entry.Mutation,
			})
		end
	end
	return out
end

function BrainrotSpawner.Init(map)
	worldMap = map
	beltFolder = Workspace:FindFirstChild("Belt")
	if not beltFolder then
		beltFolder = Instance.new("Folder")
		beltFolder.Name = "Belt"
		beltFolder.Parent = Workspace
	end
	task.spawn(function()
		while true do
			task.wait(BrainrotCatalog.SpawnIntervalSeconds)
			BrainrotSpawner.SpawnBrainrotOnConveyor()
		end
	end)
	RunService.Heartbeat:Connect(function(deltaTime)
		local step = BrainrotCatalog.BeltSpeedStudsPerSecond * deltaTime
		for index = #beltEntries, 1, -1 do
			local entry = beltEntries[index]
			entry.X += step
			if entry.X > BrainrotCatalog.BeltEndX then
				if entry.Model then
					entry.Model:Destroy()
				end
				table.remove(beltEntries, index)
			elseif entry.Model and entry.Model.PrimaryPart then
				local current = entry.Model.PrimaryPart.Position
				local target = Vector3.new(entry.X, current.Y, current.Z)
				local delta = target - current
				for _, part in ipairs(entry.Model:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Position += delta
					end
				end
			end
		end
	end)
end

return BrainrotSpawner
