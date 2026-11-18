-- BrainrotSpawner.luau
-- Builds the blocky brainrot character models out of Parts and runs the
-- conveyor belt: spawning fresh brainrots at one end, sliding them along the
-- belt, and removing the ones nobody buys before they fall off the far end.
-- The same model builder is used for belt brainrots, base brainrots and the
-- models players carry home over their heads.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))

local BrainrotSpawner = {}

-- Set by Main: called when a player clicks a brainrot riding the belt.
BrainrotSpawner.ClickedCallback = function(player, beltId) end

local MODEL_SCALE = 2.1
local BELT_YAW = -math.pi / 2

local beltEntries = {}
local nextBeltId = 0
local beltFolder = nil

-- Model construction --------------------------------------------------------------
-- Sizes and offsets below are written in unscaled units; every part is placed
-- relative to the model's base CFrame, whose origin is the centre of the body.

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

-- A flat cylinder standing upright (hats, bagels): the part's own axis is X,
-- so it is rolled 90 degrees to stand on end.
local function makeCylinderPart(model, baseCFrame, name, height, diameter, offset, color, s)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(height * s, diameter * s, diameter * s)
	part.CFrame = baseCFrame * CFrame.new(offset * s) * CFrame.Angles(0, 0, math.rad(90))
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = model
	return part
end

local function addCharacterFeature(model, baseCFrame, character, s)
	local accent = character.AccentColor
	local function P(name, size, offset, color, material, shape)
		return makeModelPart(model, baseCFrame, name, size * s, offset * s, color, material, shape)
	end
	local feature = character.Feature

	if feature == "Phone" then
		P("Phone", Vector3.new(0.4, 1.0, 0.7), Vector3.new(1.45, 0.15, 0), accent)
		P("PhoneScreen", Vector3.new(0.15, 0.7, 0.5), Vector3.new(1.68, 0.15, 0),
			Color3.fromRGB(180, 240, 255), Enum.Material.Neon)
	elseif feature == "Sword" then
		P("SwordBlade", Vector3.new(0.16, 1.9, 0.5), Vector3.new(1.55, 0.35, 0),
			Color3.fromRGB(210, 215, 225), Enum.Material.Metal)
		P("SwordGuard", Vector3.new(0.6, 0.2, 0.9), Vector3.new(1.55, -0.55, 0), accent)
	elseif feature == "Headphones" then
		P("HeadphoneBand", Vector3.new(2.3, 0.3, 0.5), Vector3.new(0, 1.12, 0),
			Color3.fromRGB(40, 40, 45))
		P("HeadphoneCupL", Vector3.new(0.4, 0.9, 1.05), Vector3.new(-1.32, 0.3, 0), accent)
		P("HeadphoneCupR", Vector3.new(0.4, 0.9, 1.05), Vector3.new(1.32, 0.3, 0), accent)
	elseif feature == "CaptainHat" then
		makeCylinderPart(model, baseCFrame, "HatBrim", 0.14, 2.2, Vector3.new(0, 1.06, 0), accent, s)
		makeCylinderPart(model, baseCFrame, "HatTop", 0.45, 1.55, Vector3.new(0, 1.32, 0),
			Color3.fromRGB(255, 255, 255), s)
	elseif feature == "Bubblegum" then
		local bubble = P("Bubblegum", Vector3.new(1.15, 1.15, 1.15), Vector3.new(0, 0.05, -1.05),
			accent, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		bubble.Transparency = 0.25
	elseif feature == "Toilet" then
		P("ToiletBowl", Vector3.new(1.9, 1.1, 1.0), Vector3.new(0, -0.35, 1.25), accent)
		P("ToiletTank", Vector3.new(1.9, 1.3, 0.5), Vector3.new(0, 0.75, 1.5), accent)
	elseif feature == "Crown" then
		local gold = Color3.fromRGB(255, 200, 40)
		P("CrownBand", Vector3.new(1.7, 0.5, 1.7), Vector3.new(0, 1.25, 0), gold, Enum.Material.Metal)
		for _, dx in ipairs({ -0.65, 0.65 }) do
			for _, dz in ipairs({ -0.65, 0.65 }) do
				P("CrownPoint", Vector3.new(0.35, 0.5, 0.35), Vector3.new(dx, 1.7, dz), gold, Enum.Material.Metal)
			end
		end
	elseif feature == "Glasses" then
		local frame = Color3.fromRGB(30, 30, 30)
		P("GlassesL", Vector3.new(0.75, 0.75, 0.12), Vector3.new(-0.52, 0.3, -0.9), frame)
		P("GlassesR", Vector3.new(0.75, 0.75, 0.12), Vector3.new(0.52, 0.3, -0.9), frame)
		P("GlassesBridge", Vector3.new(0.35, 0.14, 0.12), Vector3.new(0, 0.38, -0.9), frame)
	elseif feature == "Moon" then
		P("Moon", Vector3.new(1.05, 1.05, 1.05), Vector3.new(0.95, 2.0, 0),
			accent, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	elseif feature == "Orb" then
		P("Orb", Vector3.new(0.95, 0.95, 0.95), Vector3.new(0, 2.05, 0),
			accent, Enum.Material.Neon, Enum.PartType.Ball)
	elseif feature == "Bagel" then
		makeCylinderPart(model, baseCFrame, "BagelRing", 0.55, 1.7, Vector3.new(0, 1.55, 0),
			Color3.fromRGB(215, 170, 100), s)
		makeCylinderPart(model, baseCFrame, "BagelHole", 0.62, 0.8, Vector3.new(0, 1.55, 0), accent, s)
	elseif feature == "Waffle" then
		P("Waffle", Vector3.new(1.7, 1.7, 0.3), Vector3.new(0, 0.15, -1.0), accent)
		local grid = accent:Lerp(Color3.fromRGB(0, 0, 0), 0.25)
		P("WaffleGridH", Vector3.new(1.7, 0.12, 0.34), Vector3.new(0, 0.15, -1.02), grid)
		P("WaffleGridV", Vector3.new(0.12, 1.7, 0.34), Vector3.new(0, 0.15, -1.02), grid)
	end
end

local function buildNameLabel(body, character, mutationName, showCost, s)
	local gui = Instance.new("BillboardGui")
	gui.Name = "NameLabel"
	gui.Size = UDim2.fromOffset(220, 96)
	gui.StudsOffset = Vector3.new(0, 1.0 * s + 1.4, 0)
	gui.AlwaysOnTop = false

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = gui

	local function addLine(name, text, textSize, color, order)
		local label = Instance.new("TextLabel")
		label.Name = name
		label.Size = UDim2.new(1, 0, 0, textSize + 6)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.Text = text
		label.TextSize = textSize
		label.TextColor3 = color
		label.TextStrokeTransparency = 0.5
		label.LayoutOrder = order
		label.Parent = gui
		return label
	end

	addLine("Name", BrainrotCatalog.GetDisplayName(character, mutationName), 18,
		Color3.fromRGB(255, 255, 255), 1)
	addLine("Rarity", character.Rarity, 14, BrainrotCatalog.GetRarityColor(character.Rarity), 2)
	addLine("Rate", "$" .. BrainrotCatalog.GetIncomePerSecond(character, mutationName) .. "/s", 14,
		Color3.fromRGB(140, 255, 150), 3)
	if showCost then
		addLine("Cost", "$" .. character.Cost, 14, Color3.fromRGB(255, 230, 120), 4)
	end

	gui.Parent = body
end

function BrainrotSpawner.BuildBrainrotModel(character, mutationName, position, yaw, showCost, scaleOverride)
	local s = scaleOverride or MODEL_SCALE
	local mutation = mutationName or "None"
	local model = Instance.new("Model")
	model.Name = character.Id

	local baseCFrame = CFrame.new(position) * CFrame.Angles(0, yaw or 0, 0)
	local function P(name, size, offset, color, material, shape)
		return makeModelPart(model, baseCFrame, name, size * s, offset * s, color, material, shape)
	end

	local bodyColor = character.BodyColor
	if mutation ~= "None" then
		bodyColor = BrainrotCatalog.GetMutationColor(mutation)
	end

	local body = P("Body", Vector3.new(2.4, 2.0, 1.7), Vector3.new(0, 0, 0), bodyColor)
	P("FootL", Vector3.new(0.8, 0.35, 1.1), Vector3.new(-0.6, -1.12, 0), character.AccentColor)
	P("FootR", Vector3.new(0.8, 0.35, 1.1), Vector3.new(0.6, -1.12, 0), character.AccentColor)
	local eyeColor = Color3.fromRGB(20, 20, 25)
	P("EyeL", Vector3.new(0.4, 0.5, 0.12), Vector3.new(-0.5, 0.3, -0.88), eyeColor)
	P("EyeR", Vector3.new(0.4, 0.5, 0.12), Vector3.new(0.5, 0.3, -0.88), eyeColor)
	P("Mouth", Vector3.new(0.7, 0.15, 0.1), Vector3.new(0, -0.28, -0.88), eyeColor)

	addCharacterFeature(model, baseCFrame, character, s)

	model.PrimaryPart = body
	buildNameLabel(body, character, mutation, showCost, s)

	if showCost then
		local detector = Instance.new("ClickDetector")
		detector.Parent = body
		detector.MouseClick:Connect(function(clickingPlayer)
			if BrainrotSpawner.ClickedCallback then
				BrainrotSpawner.ClickedCallback(clickingPlayer, model:GetAttribute("BeltId"))
			end
		end)
	end

	if mutation == "Rainbow" then
		task.spawn(function()
			while model.Parent do
				body.Color = Color3.fromHSV((os.clock() % 3) / 3, 0.65, 1)
				task.wait(0.1)
			end
		end)
	end

	model.Parent = Workspace
	return model
end

-- The conveyor belt -----------------------------------------------------------------

local function findBeltEntry(beltId)
	for index, entry in ipairs(beltEntries) do
		if entry.Id == beltId then
			return entry, index
		end
	end
	return nil, nil
end

function BrainrotSpawner.SpawnBrainrotOnConveyor()
	if #beltEntries >= BrainrotCatalog.MaxBeltBrainrots then
		return
	end
	local rarityName = BrainrotCatalog.RollRarity()
	local character = BrainrotCatalog.PickRandomCharacterOfRarity(rarityName)
	local mutationName = BrainrotCatalog.RollMutation()

	nextBeltId += 1
	local entry = {
		Id = nextBeltId,
		CharacterId = character.Id,
		Mutation = mutationName,
		Model = nil,
		X = BrainrotCatalog.BeltStartX,
		AnchorY = BrainrotCatalog.BeltTopY + 2,
	}
	local model = BrainrotSpawner.BuildBrainrotModel(
		character,
		mutationName,
		Vector3.new(entry.X, entry.AnchorY, 0),
		BELT_YAW,
		true
	)
	model:SetAttribute("BeltId", entry.Id)
	if beltFolder then
		model.Parent = beltFolder
	end
	entry.Model = model
	table.insert(beltEntries, entry)
end

function BrainrotSpawner.GetBeltBrainrotById(beltId)
	local entry = findBeltEntry(beltId)
	return entry
end

function BrainrotSpawner.RemoveBeltBrainrot(beltId)
	local entry, index = findBeltEntry(beltId)
	if not entry then
		return
	end
	if entry.Model then
		entry.Model:Destroy()
	end
	table.remove(beltEntries, index)
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
		local character = BrainrotCatalog.GetCharacterById(entry.CharacterId)
		if character then
			table.insert(out, {
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
	return out
end

function BrainrotSpawner.Init(worldMap)
	beltFolder = Instance.new("Folder")
	beltFolder.Name = "Belt"
	beltFolder.Parent = Workspace

	-- Slide every belt brainrot toward the far end; remove the ones that
	-- reach it unpurchased.
	RunService.Heartbeat:Connect(function(deltaTime)
		for index = #beltEntries, 1, -1 do
			local entry = beltEntries[index]
			entry.X += BrainrotCatalog.BeltSpeedStudsPerSecond * deltaTime
			if entry.X > BrainrotCatalog.BeltEndX then
				if entry.Model then
					entry.Model:Destroy()
				end
				table.remove(beltEntries, index)
			elseif entry.Model then
				entry.Model:PivotTo(
					CFrame.new(entry.X, entry.AnchorY, 0) * CFrame.Angles(0, BELT_YAW, 0)
				)
			end
		end
	end)

	task.spawn(function()
		BrainrotSpawner.SpawnBrainrotOnConveyor()
		while true do
			task.wait(BrainrotCatalog.SpawnIntervalSeconds)
			BrainrotSpawner.SpawnBrainrotOnConveyor()
		end
	end)
end

return BrainrotSpawner
