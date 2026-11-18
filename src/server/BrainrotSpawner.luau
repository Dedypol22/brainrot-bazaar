-- BrainrotSpawner.luau
-- Builds the blocky brainrot character models out of Parts, runs the
-- conveyor belt (spawning, movement, cleanup) and answers belt queries for
-- the client snapshot. Models are simple on purpose: a body, eyes, feet,
-- arms and one signature prop per character.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))

local BrainrotSpawner = {}

-- Assigned by Main; called when a player clicks a brainrot on the belt.
BrainrotSpawner.ClickedCallback = function(_player, _beltId) end

local MODEL_SCALE = 2.1
local BELT_Y = BrainrotCatalog.BeltTopY + 0.05

local beltFolder = nil
local beltEntries = {} -- array of { Id, CharacterId, Mutation, Model, X }
local nextBeltId = 0
local initialised = false

local function formatMoney(amount)
	local text = tostring(math.floor(amount))
	local formatted = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	formatted = formatted:gsub("^,", "")
	return formatted
end

-- ---------------------------------------------------------------------------
-- Model building
-- ---------------------------------------------------------------------------

local function makeModelPart(model, baseCFrame, name, size, offset, color, material, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = baseCFrame * CFrame.new(offset)
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	if shape then
		part.Shape = shape
	end
	part.Anchored = true
	part.CanCollide = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = model
	return part
end

local function addCharacterFeature(model, baseCFrame, character, scale)
	local accent = character.AccentColor
	local function v(x, y, z)
		return Vector3.new(x * scale, y * scale, z * scale)
	end
	local feature = character.Feature
	if feature == "Phone" then
		makeModelPart(model, baseCFrame, "Phone", v(0.28, 0.95, 0.55), v(1.05, 1.45, 0.25), accent, Enum.Material.Neon)
	elseif feature == "Sword" then
		makeModelPart(model, baseCFrame, "SwordBlade", v(0.14, 1.5, 0.34), v(1.1, 1.25, 0), Color3.fromRGB(220, 225, 235), Enum.Material.Metal)
		makeModelPart(model, baseCFrame, "SwordGuard", v(0.16, 0.28, 0.8), v(1.1, 0.55, 0), accent, Enum.Material.Metal)
	elseif feature == "Headphones" then
		makeModelPart(model, baseCFrame, "HeadphoneBand", v(1.7, 0.24, 0.5), v(0, 2.32, 0), accent, Enum.Material.SmoothPlastic)
		makeModelPart(model, baseCFrame, "EarCupL", v(0.32, 0.75, 0.75), v(-0.98, 1.65, 0), accent, Enum.Material.SmoothPlastic)
		makeModelPart(model, baseCFrame, "EarCupR", v(0.32, 0.75, 0.75), v(0.98, 1.65, 0), accent, Enum.Material.SmoothPlastic)
	elseif feature == "CaptainHat" then
		local brim = makeModelPart(model, baseCFrame, "HatBrim", v(1.8, 0.14, 1.8), v(0, 2.22, 0), accent, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		brim.CFrame = brim.CFrame * CFrame.Angles(0, 0, math.rad(90))
		local top = makeModelPart(model, baseCFrame, "HatTop", v(1.35, 0.4, 1.35), v(0, 2.42, 0), accent, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		top.CFrame = top.CFrame * CFrame.Angles(0, 0, math.rad(90))
	elseif feature == "Bubblegum" then
		makeModelPart(model, baseCFrame, "Bubble", v(0.85, 0.85, 0.85), v(0, 1.1, 0.85), accent, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	elseif feature == "Toilet" then
		makeModelPart(model, baseCFrame, "ToiletSeat", v(1.45, 0.85, 1.25), v(0, 0.45, -1.05), accent, Enum.Material.SmoothPlastic)
		makeModelPart(model, baseCFrame, "ToiletTank", v(1.45, 1.15, 0.5), v(0, 1.35, -1.45), accent, Enum.Material.SmoothPlastic)
	elseif feature == "Crown" then
		makeModelPart(model, baseCFrame, "CrownBase", v(1.25, 0.42, 1.25), v(0, 2.32, 0), Color3.fromRGB(255, 200, 40), Enum.Material.Metal)
		for _, dx in ipairs({ -0.45, 0.45 }) do
			for _, dz in ipairs({ -0.45, 0.45 }) do
				makeModelPart(model, baseCFrame, "CrownPoint", v(0.3, 0.5, 0.3), v(dx, 2.7, dz), Color3.fromRGB(255, 200, 40), Enum.Material.Metal)
			end
		end
	elseif feature == "Glasses" then
		local glassColor = Color3.fromRGB(30, 30, 40)
		makeModelPart(model, baseCFrame, "GlassL", v(0.58, 0.58, 0.1), v(-0.44, 1.5, 0.66), glassColor, Enum.Material.Glass)
		makeModelPart(model, baseCFrame, "GlassR", v(0.58, 0.58, 0.1), v(0.44, 1.5, 0.66), glassColor, Enum.Material.Glass)
		makeModelPart(model, baseCFrame, "GlassBridge", v(0.34, 0.12, 0.1), v(0, 1.5, 0.66), glassColor, Enum.Material.Glass)
	elseif feature == "Moon" then
		makeModelPart(model, baseCFrame, "Moon", v(0.95, 0.95, 0.95), v(0.95, 3.0, 0), Color3.fromRGB(240, 230, 180), Enum.Material.Neon, Enum.PartType.Ball)
	elseif feature == "Orb" then
		makeModelPart(model, baseCFrame, "Orb", v(0.85, 0.85, 0.85), v(0, 3.05, 0), accent, Enum.Material.Neon, Enum.PartType.Ball)
	elseif feature == "Bagel" then
		local ring = makeModelPart(model, baseCFrame, "BagelRing", v(1.55, 0.48, 1.55), v(0, 2.35, 0), character.BodyColor, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		ring.CFrame = ring.CFrame * CFrame.Angles(0, 0, math.rad(90))
		local hole = makeModelPart(model, baseCFrame, "BagelHole", v(0.62, 0.54, 0.62), v(0, 2.35, 0), accent, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		hole.CFrame = hole.CFrame * CFrame.Angles(0, 0, math.rad(90))
	elseif feature == "Waffle" then
		makeModelPart(model, baseCFrame, "Waffle", v(1.35, 1.35, 0.26), v(0, 1.35, -0.82), Color3.fromRGB(230, 180, 100), Enum.Material.SmoothPlastic)
		makeModelPart(model, baseCFrame, "WaffleStripeH", v(1.35, 0.16, 0.3), v(0, 1.35, -0.84), accent, Enum.Material.SmoothPlastic)
		makeModelPart(model, baseCFrame, "WaffleStripeV", v(0.16, 1.35, 0.3), v(0, 1.35, -0.84), accent, Enum.Material.SmoothPlastic)
	end
end

local function buildInfoLabel(model, body, character, mutationName, showCost, scale)
	local gui = Instance.new("BillboardGui")
	gui.Name = "InfoLabel"
	gui.Size = UDim2.fromOffset(230, showCost and 104 or 82)
	gui.StudsOffset = Vector3.new(0, 1.35 * scale + 0.9, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 140
	gui.Adornee = body

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = gui

	local function addLine(text, size, color, order)
		local label = Instance.new("TextLabel")
		label.LayoutOrder = order
		label.Size = UDim2.new(1, 0, 0, size + 4)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextSize = size
		label.TextColor3 = color
		label.Font = Enum.Font.GothamBold
		label.TextStrokeTransparency = 0.4
		label.Parent = gui
		return label
	end

	local income = BrainrotCatalog.GetIncomePerSecond(character, mutationName)
	addLine(BrainrotCatalog.GetDisplayName(character, mutationName), 16, Color3.fromRGB(255, 255, 255), 1)
	addLine(character.Rarity, 13, BrainrotCatalog.GetRarityColor(character.Rarity), 2)
	addLine("$" .. formatMoney(income) .. "/s", 14, Color3.fromRGB(130, 255, 150), 3)
	if showCost then
		addLine("$" .. formatMoney(character.Cost), 14, Color3.fromRGB(255, 220, 90), 4)
	end
	gui.Parent = body
end

function BrainrotSpawner.BuildBrainrotModel(character, mutationName, position, yaw, showCost, scaleOverride)
	local scale = scaleOverride or MODEL_SCALE
	mutationName = mutationName or "None"
	local baseCFrame = CFrame.new(position) * CFrame.Angles(0, yaw or 0, 0)
	local function v(x, y, z)
		return Vector3.new(x * scale, y * scale, z * scale)
	end

	local model = Instance.new("Model")
	model.Name = character.Id

	local bodyColor = character.BodyColor
	if mutationName ~= "None" then
		bodyColor = BrainrotCatalog.GetMutationColor(mutationName)
	end

	local body = makeModelPart(model, baseCFrame, "Body", v(1.7, 2.1, 1.25), v(0, 1.05, 0), bodyColor, Enum.Material.SmoothPlastic)
	model.PrimaryPart = body

	-- Face: two eyes and a grin on the +Z side.
	local eyeColor = Color3.fromRGB(25, 25, 35)
	makeModelPart(model, baseCFrame, "EyeL", v(0.24, 0.3, 0.1), v(-0.42, 1.5, 0.64), eyeColor, Enum.Material.SmoothPlastic)
	makeModelPart(model, baseCFrame, "EyeR", v(0.24, 0.3, 0.1), v(0.42, 1.5, 0.64), eyeColor, Enum.Material.SmoothPlastic)
	makeModelPart(model, baseCFrame, "Mouth", v(0.6, 0.12, 0.1), v(0, 1.05, 0.64), eyeColor, Enum.Material.SmoothPlastic)
	-- Arms and feet in the accent colour.
	makeModelPart(model, baseCFrame, "ArmL", v(0.36, 1.15, 0.42), v(-1.04, 1.15, 0), character.AccentColor, Enum.Material.SmoothPlastic)
	makeModelPart(model, baseCFrame, "ArmR", v(0.36, 1.15, 0.42), v(1.04, 1.15, 0), character.AccentColor, Enum.Material.SmoothPlastic)
	makeModelPart(model, baseCFrame, "FootL", v(0.56, 0.3, 0.85), v(-0.46, 0.15, 0.12), character.AccentColor, Enum.Material.SmoothPlastic)
	makeModelPart(model, baseCFrame, "FootR", v(0.56, 0.3, 0.85), v(0.46, 0.15, 0.12), character.AccentColor, Enum.Material.SmoothPlastic)

	addCharacterFeature(model, baseCFrame, character, scale)
	buildInfoLabel(model, body, character, mutationName, showCost, scale)

	if showCost then
		local detector = Instance.new("ClickDetector")
		detector.MaxActivationDistance = 32
		detector.MouseClick:Connect(function(player)
			local beltId = model:GetAttribute("BeltId")
			if beltId then
				BrainrotSpawner.ClickedCallback(player, beltId)
			end
		end)
		detector.Parent = body
	end

	if mutationName == "Rainbow" then
		task.spawn(function()
			while model.Parent do
				body.Color = Color3.fromHSV((os.clock() % 6) / 6, 0.65, 1)
				task.wait(0.1)
			end
		end)
	end

	return model
end

-- ---------------------------------------------------------------------------
-- The belt
-- ---------------------------------------------------------------------------

function BrainrotSpawner.SpawnBrainrotOnConveyor()
	if #beltEntries >= BrainrotCatalog.MaxBeltBrainrots then
		return
	end
	local rarityName = BrainrotCatalog.RollRarity()
	local character = BrainrotCatalog.PickRandomCharacterOfRarity(rarityName)
	local mutationName = BrainrotCatalog.RollMutation()
	nextBeltId += 1
	local model = BrainrotSpawner.BuildBrainrotModel(
		character, mutationName,
		Vector3.new(BrainrotCatalog.BeltStartX, BELT_Y, 0),
		0, true
	)
	model:SetAttribute("BeltId", nextBeltId)
	model.Parent = beltFolder or Workspace
	table.insert(beltEntries, {
		Id = nextBeltId,
		CharacterId = character.Id,
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
			return
		end
	end
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
	local list = {}
	for _, entry in ipairs(beltEntries) do
		local character = BrainrotCatalog.GetCharacterById(entry.CharacterId)
		if character then
			table.insert(list, {
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
	return list
end

local function stepBelt(deltaTime)
	if #beltEntries == 0 then
		return
	end
	local expired = {}
	for _, entry in ipairs(beltEntries) do
		entry.X += BrainrotCatalog.BeltSpeedStudsPerSecond * deltaTime
		if entry.X > BrainrotCatalog.BeltEndX then
			table.insert(expired, entry.Id)
		elseif entry.Model then
			entry.Model:PivotTo(CFrame.new(entry.X, BELT_Y, 0))
		end
	end
	for _, beltId in ipairs(expired) do
		BrainrotSpawner.RemoveBeltBrainrot(beltId)
	end
end

function BrainrotSpawner.Init(_worldMap)
	if initialised then
		return
	end
	initialised = true
	beltFolder = Instance.new("Folder")
	beltFolder.Name = "Belt"
	beltFolder.Parent = Workspace

	RunService.Heartbeat:Connect(stepBelt)

	task.spawn(function()
		while true do
			BrainrotSpawner.SpawnBrainrotOnConveyor()
			task.wait(BrainrotCatalog.SpawnIntervalSeconds)
		end
	end)
end

return BrainrotSpawner
