-- BrainrotSpawner: blocky brainrot models, conveyor spawning and belt movement.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))

local BrainrotSpawner = {}

local MODEL_SCALE = 2.1
local BELT_Y = BrainrotCatalog.BeltTopY + 2

local beltEntries = {}
local nextBeltId = 0
local beltFolder = nil
local beltCount = 0
local initialized = false

BrainrotSpawner.ClickedCallback = function() end

local function getBeltFolder()
	if beltFolder and beltFolder.Parent then
		return beltFolder
	end
	beltFolder = Workspace:FindFirstChild("Belt")
	if not beltFolder then
		beltFolder = Instance.new("Folder")
		beltFolder.Name = "Belt"
		beltFolder.Parent = Workspace
	end
	return beltFolder
end

local function makeModelPart(model, baseCFrame, name, size, offset, color, material, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth

	local cframe = baseCFrame * CFrame.new(offset)
	if shape == "Ball" then
		part.Shape = Enum.PartType.Ball
	elseif shape == "Cylinder" then
		part.Shape = Enum.PartType.Cylinder
		cframe = cframe * CFrame.Angles(0, 0, math.rad(90))
	elseif shape == "Wedge" then
		part.Shape = Enum.PartType.Wedge
	end
	part.CFrame = cframe
	part.Parent = model
	return part
end

local function addCharacterFeature(model, baseCFrame, character, scale)
	local s = scale or MODEL_SCALE
	local bodyHeight = 2.4 * s
	local accent = character.AccentColor
	local feature = character.Feature

	if feature == "Phone" then
		makeModelPart(model, baseCFrame, "Phone", Vector3.new(0.25 * s, 0.7 * s, 0.45 * s), Vector3.new(0.78 * s, 1.45 * s, 0.2 * s), Color3.fromRGB(35, 35, 40), Enum.Material.SmoothPlastic)
		makeModelPart(model, baseCFrame, "PhoneScreen", Vector3.new(0.06 * s, 0.5 * s, 0.32 * s), Vector3.new(0.92 * s, 1.45 * s, 0.2 * s), Color3.fromRGB(120, 230, 255), Enum.Material.Neon)
	elseif feature == "Sword" then
		makeModelPart(model, baseCFrame, "SwordBlade", Vector3.new(0.18 * s, 2.4 * s, 0.18 * s), Vector3.new(0.95 * s, 1.7 * s, 0), Color3.fromRGB(210, 215, 225), Enum.Material.Metal)
		makeModelPart(model, baseCFrame, "SwordGuard", Vector3.new(0.9 * s, 0.16 * s, 0.25 * s), Vector3.new(0.95 * s, 1.05 * s, 0), accent, Enum.Material.Metal)
	elseif feature == "Headphones" then
		makeModelPart(model, baseCFrame, "Headband", Vector3.new(2.1 * s, 0.24 * s, 0.4 * s), Vector3.new(0, bodyHeight + 0.05 * s, 0), accent, Enum.Material.SmoothPlastic)
		makeModelPart(model, baseCFrame, "EarCupL", Vector3.new(0.32 * s, 0.75 * s, 0.75 * s), Vector3.new(-1.0 * s, 1.55 * s, 0), accent, Enum.Material.SmoothPlastic)
		makeModelPart(model, baseCFrame, "EarCupR", Vector3.new(0.32 * s, 0.75 * s, 0.75 * s), Vector3.new(1.0 * s, 1.55 * s, 0), accent, Enum.Material.SmoothPlastic)
	elseif feature == "CaptainHat" then
		makeModelPart(model, baseCFrame, "HatBrim", Vector3.new(0.2 * s, 1.9 * s, 1.9 * s), Vector3.new(0, bodyHeight + 0.05 * s, 0), accent, Enum.Material.SmoothPlastic, "Cylinder")
		makeModelPart(model, baseCFrame, "HatCrown", Vector3.new(0.42 * s, 1.25 * s, 1.25 * s), Vector3.new(0, bodyHeight + 0.25 * s, 0), accent, Enum.Material.SmoothPlastic, "Cylinder")
	elseif feature == "Bubblegum" then
		makeModelPart(model, baseCFrame, "Bubblegum", Vector3.new(0.9 * s, 0.9 * s, 0.9 * s), Vector3.new(0, 1.45 * s, -0.85 * s), accent, Enum.Material.SmoothPlastic, "Ball")
	elseif feature == "Toilet" then
		makeModelPart(model, baseCFrame, "ToiletBowl", Vector3.new(1.5 * s, 1.0 * s, 1.4 * s), Vector3.new(0, 1.1 * s, 0.35 * s), Color3.fromRGB(250, 250, 250), Enum.Material.SmoothPlastic)
		makeModelPart(model, baseCFrame, "ToiletTank", Vector3.new(1.2 * s, 0.9 * s, 0.5 * s), Vector3.new(0, 1.85 * s, 1.0 * s), Color3.fromRGB(240, 240, 245), Enum.Material.SmoothPlastic)
	elseif feature == "Crown" then
		makeModelPart(model, baseCFrame, "CrownBase", Vector3.new(1.25 * s, 0.35 * s, 1.25 * s), Vector3.new(0, bodyHeight + 0.15 * s, 0), Color3.fromRGB(255, 215, 0), Enum.Material.Neon, "Cylinder")
		for i = -1, 1 do
			makeModelPart(model, baseCFrame, "CrownPoint", Vector3.new(0.22 * s, 0.45 * s, 0.22 * s), Vector3.new(i * 0.4 * s, bodyHeight + 0.55 * s, 0), Color3.fromRGB(255, 225, 60), Enum.Material.Neon)
		end
	elseif feature == "Glasses" then
		makeModelPart(model, baseCFrame, "GlassL", Vector3.new(0.62 * s, 0.45 * s, 0.1 * s), Vector3.new(-0.45 * s, 1.75 * s, -0.83 * s), Color3.fromRGB(25, 25, 30), Enum.Material.SmoothPlastic)
		makeModelPart(model, baseCFrame, "GlassR", Vector3.new(0.62 * s, 0.45 * s, 0.1 * s), Vector3.new(0.45 * s, 1.75 * s, -0.83 * s), Color3.fromRGB(25, 25, 30), Enum.Material.SmoothPlastic)
		makeModelPart(model, baseCFrame, "GlassBridge", Vector3.new(0.32 * s, 0.1 * s, 0.1 * s), Vector3.new(0, 1.75 * s, -0.83 * s), Color3.fromRGB(25, 25, 30), Enum.Material.SmoothPlastic)
	elseif feature == "Moon" then
		makeModelPart(model, baseCFrame, "Moon", Vector3.new(1.25 * s, 1.25 * s, 1.25 * s), Vector3.new(0, bodyHeight + 1.0 * s, 0), accent, Enum.Material.SmoothPlastic, "Ball")
	elseif feature == "Orb" then
		makeModelPart(model, baseCFrame, "Orb", Vector3.new(0.95 * s, 0.95 * s, 0.95 * s), Vector3.new(0, bodyHeight + 1.05 * s, 0), accent, Enum.Material.Neon, "Ball")
	elseif feature == "Bagel" then
		makeModelPart(model, baseCFrame, "BagelRing", Vector3.new(0.5 * s, 1.55 * s, 1.55 * s), Vector3.new(0, bodyHeight + 0.3 * s, 0), accent, Enum.Material.SmoothPlastic, "Cylinder")
		makeModelPart(model, baseCFrame, "BagelHole", Vector3.new(0.55 * s, 0.75 * s, 0.75 * s), Vector3.new(0, bodyHeight + 0.3 * s, 0), Color3.fromRGB(120, 80, 45), Enum.Material.SmoothPlastic, "Cylinder")
	elseif feature == "Waffle" then
		makeModelPart(model, baseCFrame, "Waffle", Vector3.new(1.7 * s, 0.3 * s, 1.7 * s), Vector3.new(0, bodyHeight + 0.15 * s, 0), accent, Enum.Material.WoodPlanks)
	elseif feature == "Antenna" then
		makeModelPart(model, baseCFrame, "AntennaStalk", Vector3.new(1.7 * s, 0.12 * s, 0.12 * s), Vector3.new(0, bodyHeight + 0.85 * s, 0), accent, Enum.Material.SmoothPlastic, "Cylinder")
		makeModelPart(model, baseCFrame, "AntennaTip", Vector3.new(0.42 * s, 0.42 * s, 0.42 * s), Vector3.new(0, bodyHeight + 1.75 * s, 0), accent, Enum.Material.Neon, "Ball")
	elseif feature == "TopHat" then
		makeModelPart(model, baseCFrame, "TopHatBrim", Vector3.new(0.18 * s, 1.7 * s, 1.7 * s), Vector3.new(0, bodyHeight + 0.05 * s, 0), Color3.fromRGB(30, 30, 35), Enum.Material.SmoothPlastic, "Cylinder")
		makeModelPart(model, baseCFrame, "TopHatCrown", Vector3.new(1.1 * s, 1.0 * s, 1.0 * s), Vector3.new(0, bodyHeight + 0.62 * s, 0), Color3.fromRGB(30, 30, 35), Enum.Material.SmoothPlastic, "Cylinder")
		makeModelPart(model, baseCFrame, "TopHatBand", Vector3.new(0.22 * s, 1.04 * s, 1.04 * s), Vector3.new(0, bodyHeight + 0.25 * s, 0), accent, Enum.Material.SmoothPlastic, "Cylinder")
	elseif feature == "Umbrella" then
		makeModelPart(model, baseCFrame, "UmbrellaHandle", Vector3.new(2.0 * s, 0.12 * s, 0.12 * s), Vector3.new(1.0 * s, 1.5 * s, 0), Color3.fromRGB(70, 55, 40), Enum.Material.Wood, "Cylinder")
		makeModelPart(model, baseCFrame, "UmbrellaCanopy", Vector3.new(0.16 * s, 2.3 * s, 2.3 * s), Vector3.new(1.0 * s, 2.55 * s, 0), accent, Enum.Material.Fabric, "Cylinder")
	elseif feature == "Rocket" then
		makeModelPart(model, baseCFrame, "RocketBody", Vector3.new(1.4 * s, 0.6 * s, 0.6 * s), Vector3.new(0, 1.55 * s, 0.9 * s), Color3.fromRGB(245, 245, 245), Enum.Material.Metal, "Cylinder")
		makeModelPart(model, baseCFrame, "RocketNose", Vector3.new(0.55 * s, 0.55 * s, 0.55 * s), Vector3.new(0, 2.35 * s, 0.9 * s), accent, Enum.Material.Metal, "Ball")
		makeModelPart(model, baseCFrame, "RocketFlame", Vector3.new(0.55 * s, 0.35 * s, 0.35 * s), Vector3.new(0, 0.65 * s, 0.9 * s), Color3.fromRGB(255, 150, 40), Enum.Material.Neon, "Ball")
	elseif feature == "IceCream" then
		makeModelPart(model, baseCFrame, "IceCreamCone", Vector3.new(0.95 * s, 0.5 * s, 0.5 * s), Vector3.new(0.95 * s, 1.2 * s, -0.2 * s), Color3.fromRGB(220, 180, 120), Enum.Material.SmoothPlastic, "Cylinder")
		makeModelPart(model, baseCFrame, "IceCreamScoop", Vector3.new(0.72 * s, 0.72 * s, 0.72 * s), Vector3.new(0.95 * s, 1.9 * s, -0.2 * s), accent, Enum.Material.SmoothPlastic, "Ball")
	elseif feature == "Mushroom" then
		makeModelPart(model, baseCFrame, "MushroomStem", Vector3.new(0.8 * s, 0.36 * s, 0.36 * s), Vector3.new(0, bodyHeight + 0.3 * s, 0), Color3.fromRGB(245, 240, 225), Enum.Material.SmoothPlastic, "Cylinder")
		makeModelPart(model, baseCFrame, "MushroomCap", Vector3.new(0.42 * s, 1.55 * s, 1.55 * s), Vector3.new(0, bodyHeight + 0.78 * s, 0), accent, Enum.Material.SmoothPlastic, "Ball")
		makeModelPart(model, baseCFrame, "MushroomDotL", Vector3.new(0.18 * s, 0.18 * s, 0.18 * s), Vector3.new(-0.4 * s, bodyHeight + 0.98 * s, 0), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, "Ball")
		makeModelPart(model, baseCFrame, "MushroomDotR", Vector3.new(0.18 * s, 0.18 * s, 0.18 * s), Vector3.new(0.4 * s, bodyHeight + 0.98 * s, 0), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, "Ball")
	end
end

local function applyMutation(model, body, character, mutationName, eyes)
	if mutationName == "Golden" or mutationName == "Diamond" or mutationName == "Candy" or mutationName == "Crystal" then
		body.Color = BrainrotCatalog.GetMutationColor(mutationName)
	elseif mutationName == "Void" then
		body.Color = BrainrotCatalog.GetMutationColor(mutationName)
		for _, eye in ipairs(eyes) do
			eye.Color = character.AccentColor
			eye.Material = Enum.Material.Neon
		end
	elseif mutationName == "Rainbow" then
		task.spawn(function()
			local hue = 0
			while body.Parent do
				hue = (hue + 0.01) % 1
				body.Color = Color3.fromHSV(hue, 0.8, 1)
				task.wait(0.08)
			end
		end)
	elseif mutationName == "Galaxy" then
		task.spawn(function()
			local startColor = BrainrotCatalog.GetMutationColor("Galaxy")
			local brightColor = Color3.fromRGB(80, 230, 255)
			local alpha = 0
			local direction = 1
			while body.Parent do
				alpha += direction * 0.03
				if alpha >= 1 then
					alpha = 1
					direction = -1
				elseif alpha <= 0 then
					alpha = 0
					direction = 1
				end
				body.Color = startColor:Lerp(brightColor, alpha)
				task.wait(0.1)
			end
		end)
	end
end

function BrainrotSpawner.BuildBrainrotModel(character, mutationName, position, yaw, showCost, scaleOverride)
	local scale = scaleOverride or MODEL_SCALE
	local baseCFrame = CFrame.new(position) * CFrame.Angles(0, yaw or 0, 0)

	local model = Instance.new("Model")
	model.Name = character.Id

	local bodyWidth = 2.0 * scale
	local bodyHeight = 2.4 * scale
	local bodyDepth = 1.6 * scale

	local body = makeModelPart(
		model,
		baseCFrame,
		"Body",
		Vector3.new(bodyWidth, bodyHeight, bodyDepth),
		Vector3.new(0, bodyHeight * 0.5 + 0.1 * scale, 0),
		character.BodyColor,
		Enum.Material.SmoothPlastic
	)
	body.CanCollide = false
	model.PrimaryPart = body

	local eyes = {}
	for _, side in ipairs({ -1, 1 }) do
		local eye = makeModelPart(
			model,
			baseCFrame,
			"Eye",
			Vector3.new(0.34 * scale, 0.38 * scale, 0.22 * scale),
			Vector3.new(side * 0.44 * scale, bodyHeight * 0.72, -bodyDepth * 0.5),
			Color3.fromRGB(25, 25, 30),
			Enum.Material.SmoothPlastic
		)
		table.insert(eyes, eye)
	end

	addCharacterFeature(model, baseCFrame, character, scale)
	applyMutation(model, body, character, mutationName, eyes)

	local rate = BrainrotCatalog.GetIncomePerSecond(character, mutationName)
	local displayName = BrainrotCatalog.GetDisplayName(character, mutationName)
	local rarityColor = BrainrotCatalog.GetRarityColor(character.Rarity)

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BrainrotLabel"
	billboard.Size = UDim2.fromScale(14, 6)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, bodyHeight + 2.2 * scale, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 160
	billboard.Parent = body

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 2)
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = billboard

	local function addLine(text, color, textSize, order)
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 0.25)
		label.Text = text
		label.TextColor3 = color
		label.TextSize = textSize
		label.TextScaled = false
		label.TextStrokeTransparency = 0.35
		label.Font = Enum.Font.FredokaOne
		label.LayoutOrder = order
		label.Parent = billboard
		return label
	end

	addLine(displayName, Color3.fromRGB(255, 255, 255), 20, 1)
	addLine(character.Rarity, rarityColor, 17, 2)
	addLine("$" .. tostring(rate) .. "/s", Color3.fromRGB(150, 255, 160), 18, 3)
	if showCost then
		addLine("$" .. tostring(character.Cost), Color3.fromRGB(255, 220, 120), 18, 4)
	end

	if showCost then
		local detector = Instance.new("ClickDetector")
		detector.Name = "BuyDetector"
		detector.MaxActivationDistance = 40
		detector.MouseClick:Connect(function(player)
			local beltId = model:GetAttribute("BeltId")
			if beltId then
				BrainrotSpawner.ClickedCallback(player, beltId)
			end
		end)
		detector.Parent = body
	end

	model.WorldPivot = baseCFrame
	model.Parent = getBeltFolder()
	return model
end

function BrainrotSpawner.SpawnBrainrotOnConveyor()
	if beltCount >= BrainrotCatalog.MaxBeltBrainrots then
		return
	end

	local rarityName = BrainrotCatalog.RollRarity()
	local character = BrainrotCatalog.PickRandomCharacterOfRarity(rarityName)
	local mutationName = BrainrotCatalog.RollMutation()

	nextBeltId += 1
	local beltId = nextBeltId
	local model = BrainrotSpawner.BuildBrainrotModel(
		character,
		mutationName,
		Vector3.new(BrainrotCatalog.BeltStartX, BELT_Y, 0),
		math.rad(90),
		true,
		nil
	)
	model:SetAttribute("BeltId", beltId)

	beltEntries[beltId] = {
		Id = beltId,
		CharacterId = character.Id,
		Mutation = mutationName,
		Model = model,
		X = BrainrotCatalog.BeltStartX,
	}
	beltCount += 1
end

function BrainrotSpawner.GetBeltBrainrotById(beltId)
	return beltEntries[beltId]
end

function BrainrotSpawner.RemoveBeltBrainrot(beltId)
	local entry = beltEntries[beltId]
	if not entry then
		return
	end
	if entry.Model then
		entry.Model:Destroy()
	end
	beltEntries[beltId] = nil
	beltCount = math.max(0, beltCount - 1)
end

function BrainrotSpawner.ClearAllBeltBrainrots()
	for beltId, entry in pairs(beltEntries) do
		if entry.Model then
			entry.Model:Destroy()
		end
		beltEntries[beltId] = nil
	end
	beltCount = 0
end

function BrainrotSpawner.GetBeltBrainrotsForClient()
	local result = {}
	for _, entry in pairs(beltEntries) do
		local character = BrainrotCatalog.GetCharacterById(entry.CharacterId)
		if character then
			table.insert(result, {
				Id = entry.Id,
				CharacterId = entry.CharacterId,
				Name = BrainrotCatalog.GetDisplayName(character, entry.Mutation),
				Rarity = character.Rarity,
				Rate = BrainrotCatalog.GetIncomePerSecond(character, entry.Mutation),
				Cost = character.Cost,
				Mutation = entry.Mutation,
			})
		end
	end
	table.sort(result, function(a, b)
		return a.Id < b.Id
	end)
	return result
end

function BrainrotSpawner.Init(worldMap)
	if initialized then
		return
	end
	initialized = true
	getBeltFolder()

	task.spawn(function()
		while true do
			task.wait(BrainrotCatalog.SpawnIntervalSeconds)
			BrainrotSpawner.SpawnBrainrotOnConveyor()
		end
	end)

	RunService.Heartbeat:Connect(function(deltaTime)
		local step = BrainrotCatalog.BeltSpeedStudsPerSecond * deltaTime
		for beltId, entry in pairs(beltEntries) do
			entry.X += step
			if entry.X > BrainrotCatalog.BeltEndX then
				BrainrotSpawner.RemoveBeltBrainrot(beltId)
			elseif entry.Model and entry.Model.Parent then
				entry.Model:PivotTo(entry.Model:GetPivot() + Vector3.new(step, 0, 0))
			end
		end
	end)
end

return BrainrotSpawner
