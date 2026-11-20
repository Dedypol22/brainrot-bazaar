-- MapBuilder: builds the bazaar plaza, conveyor belt, plots and set dressing at runtime.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))

local MapBuilder = {}

local worldFolder = nil

local function getWorldFolder()
	if worldFolder and worldFolder.Parent then
		return worldFolder
	end
	local existing = Workspace:FindFirstChild("World")
	if existing then
		existing:Destroy()
	end
	worldFolder = Instance.new("Folder")
	worldFolder.Name = "World"
	worldFolder.Parent = Workspace
	return worldFolder
end

local function makePart(name, size, position, color, material, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = true
	part.Size = size
	part.Position = position
	part.Color = color or Color3.fromRGB(200, 200, 200)
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent or getWorldFolder()
	return part
end

local function makeBillboardLabel(parent, size, text, textSize, textColor, backgroundColor)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = size
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 250
	billboard.Parent = parent

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.BackgroundColor3 = backgroundColor or Color3.fromRGB(20, 20, 25)
	label.BackgroundTransparency = 0.15
	label.BorderSizePixel = 0
	label.Size = UDim2.fromScale(1, 1)
	label.Text = text
	label.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
	label.TextScaled = false
	label.TextSize = textSize or 18
	label.TextWrapped = true
	label.Font = Enum.Font.FredokaOne
	label.Parent = billboard
	return billboard, label
end

local function buildSlotPad(plot, slotIndex)
	local model = plot.Model
	local row = 0
	if slotIndex > 5 then
		row = 1
	end
	local column = ((slotIndex - 1) % 5) + 1
	local offsetX = (column - 3) * 4.4
	local offsetZ = (row == 0) and -3.6 or 3.6

	local pad = makePart(
		"Slot" .. slotIndex,
		Vector3.new(4, 0.35, 4),
		plot.Center + Vector3.new(offsetX, 0.55, offsetZ),
		Color3.fromRGB(245, 245, 245),
		Enum.Material.SmoothPlastic,
		model
	)
	pad.CanCollide = false

	local number = Instance.new("BillboardGui")
	number.Name = "SlotNumber"
	number.Size = UDim2.fromScale(2.4, 1.2)
	number.StudsOffsetWorldSpace = Vector3.new(0, 1.2, 0)
	number.AlwaysOnTop = true
	number.MaxDistance = 90
	number.Parent = pad

	local numberLabel = Instance.new("TextLabel")
	numberLabel.BackgroundTransparency = 1
	numberLabel.Size = UDim2.fromScale(1, 1)
	numberLabel.Text = tostring(slotIndex)
	numberLabel.TextColor3 = Color3.fromRGB(60, 60, 70)
	numberLabel.TextScaled = true
	numberLabel.Font = Enum.Font.FredokaOne
	numberLabel.Parent = number

	plot.Pads[slotIndex] = pad
	return pad
end

local function buildPlot(index, center, color)
	local model = Instance.new("Model")
	model.Name = "Plot" .. index
	model.Parent = getWorldFolder()

	local plot = {
		Index = index,
		Model = model,
		Center = center,
		Pads = {},
		Sign = nil,
		OwnerUserId = 0,
	}

	local floor = makePart(
		"Floor",
		Vector3.new(24, 0.6, 16),
		center + Vector3.new(0, 0.3, 0),
		color,
		Enum.Material.SmoothPlastic,
		model
	)
	floor.CanCollide = true

	local trim = makePart(
		"Trim",
		Vector3.new(24.8, 0.3, 16.8),
		center + Vector3.new(0, 0.05, 0),
		Color3.fromRGB(255, 255, 255),
		Enum.Material.SmoothPlastic,
		model
	)
	trim.CanCollide = false

	local post = makePart(
		"SignPost",
		Vector3.new(0.6, 6, 0.6),
		center + Vector3.new(0, 3, -7.2),
		Color3.fromRGB(110, 80, 50),
		Enum.Material.Wood,
		model
	)
	post.CanCollide = false

	local _, signLabel = makeBillboardLabel(
		post,
		UDim2.fromScale(12, 4),
		"BASE " .. index,
		22,
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(45, 40, 50)
	)
	signLabel.TextStrokeTransparency = 0.4
	plot.Sign = signLabel

	for slotIndex = 1, BrainrotCatalog.BaseSlotCount do
		buildSlotPad(plot, slotIndex)
	end

	return plot
end

local function addPalmTree(position)
	local trunk = makePart(
		"PalmTrunk",
		Vector3.new(1.2, 12, 1.2),
		position + Vector3.new(0, 6, 0),
		Color3.fromRGB(140, 95, 55),
		Enum.Material.Wood
	)
	trunk.CanCollide = false

	for i = 1, 5 do
		local angle = (i / 5) * math.pi * 2
		local leaf = makePart(
			"PalmLeaf",
			Vector3.new(7, 0.4, 2),
			position + Vector3.new(math.cos(angle) * 3, 11.5, math.sin(angle) * 3),
			Color3.fromRGB(60, 170, 75),
			Enum.Material.Grass
		)
		leaf.CFrame = CFrame.new(leaf.Position) * CFrame.Angles(0, angle, math.rad(-12))
		leaf.CanCollide = false
	end
end

local function addMarketStall(position, color)
	local base = makePart(
		"StallBase",
		Vector3.new(6, 1, 4),
		position + Vector3.new(0, 0.5, 0),
		Color3.fromRGB(150, 110, 70),
		Enum.Material.Wood
	)
	base.CanCollide = false

	local roof = makePart(
		"StallRoof",
		Vector3.new(6.8, 0.5, 4.8),
		position + Vector3.new(0, 4.2, 0),
		color,
		Enum.Material.Fabric
	)
	roof.CanCollide = false

	for _, xOffset in ipairs({ -2.6, 2.6 }) do
		local pole = makePart(
			"StallPole",
			Vector3.new(0.3, 4, 0.3),
			position + Vector3.new(xOffset, 2, 0),
			Color3.fromRGB(90, 70, 50),
			Enum.Material.Wood
		)
		pole.CanCollide = false
	end
end

local function addCloud(position)
	for i = 1, 3 do
		local puff = makePart(
			"CloudPuff",
			Vector3.new(14 - i * 2, 5, 10),
			position + Vector3.new((i - 2) * 9, (i % 2) * 1.5, 0),
			Color3.fromRGB(255, 255, 255),
			Enum.Material.SmoothPlastic
		)
		puff.CanCollide = false
		puff.Transparency = 0.25
	end
end

local function paintLighting()
	Lighting.ClockTime = 14
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(120, 120, 130)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 160, 180)
	Lighting.GlobalShadows = true
	Lighting.FogEnd = 600
	Lighting.FogColor = Color3.fromRGB(200, 225, 255)
end

function MapBuilder.CreateSlotPad(plot, slotIndex)
	return buildSlotPad(plot, slotIndex)
end

function MapBuilder.BuildWorld()
	paintLighting()

	local world = getWorldFolder()

	-- Plaza ground.
	local ground = makePart(
		"Plaza",
		Vector3.new(1, BrainrotCatalog.PlazaRadius * 2, BrainrotCatalog.PlazaRadius * 2),
		Vector3.new(0, -0.5, 0),
		Color3.fromRGB(250, 220, 160),
		Enum.Material.Grass
	)
	ground.Shape = Enum.PartType.Cylinder
	ground.CFrame = CFrame.new(Vector3.new(0, -0.5, 0)) * CFrame.Angles(0, 0, math.rad(90))

	local plazaRing = makePart(
		"PlazaRing",
		Vector3.new(4, 0.4, BrainrotCatalog.PlazaRadius * 2 + 10),
		Vector3.new(0, 0.05, 0),
		Color3.fromRGB(235, 180, 90),
		Enum.Material.Sand
	)
	plazaRing.CanCollide = false

	-- Conveyor belt at the centre.
	local beltTop = BrainrotCatalog.BeltTopY
	local belt = makePart(
		"ConveyorBelt",
		Vector3.new(76, 0.6, 14),
		Vector3.new(0, beltTop - 0.3, 0),
		Color3.fromRGB(45, 45, 55),
		Enum.Material.DiamondPlate
	)

	for _, zSide in ipairs({ -7.2, 7.2 }) do
		local rail = makePart(
			"BeltRail",
			Vector3.new(78, 1.2, 0.6),
			Vector3.new(0, beltTop + 0.4, zSide),
			Color3.fromRGB(90, 95, 110),
			Enum.Material.Metal
		)
		rail.CanCollide = false

		local glow = makePart(
			"BeltGlow",
			Vector3.new(78, 0.18, 0.3),
			Vector3.new(0, beltTop + 1.02, zSide),
			Color3.fromRGB(80, 240, 255),
			Enum.Material.Neon
		)
		glow.CanCollide = false
	end

	for _, xSide in ipairs({ -39, 39 }) do
		local post = makePart(
			"BeltSignPost",
			Vector3.new(0.8, 12, 0.8),
			Vector3.new(xSide, 6, 0),
			Color3.fromRGB(120, 85, 50),
			Enum.Material.Wood
		)
		post.CanCollide = false
	end

	local signBar = makePart(
		"BeltSignBar",
		Vector3.new(80, 5, 1),
		Vector3.new(0, 12, 0),
		Color3.fromRGB(70, 45, 35),
		Enum.Material.Wood
	)
	signBar.CanCollide = false
	makeBillboardLabel(
		signBar,
		UDim2.fromScale(30, 7),
		"BRAINROT BAZAAR",
		44,
		Color3.fromRGB(255, 235, 150),
		Color3.fromRGB(80, 30, 40)
	)

	-- Perimeter fence.
	local fenceRadius = BrainrotCatalog.PlazaRadius + 3
	for i = 1, 32 do
		local angle = (i / 32) * math.pi * 2
		local x = math.cos(angle) * fenceRadius
		local z = math.sin(angle) * fenceRadius
		local fencePost = makePart(
			"FencePost",
			Vector3.new(0.5, 4, 0.5),
			Vector3.new(x, 2, z),
			Color3.fromRGB(180, 150, 110),
			Enum.Material.Wood
		)
		fencePost.CanCollide = false
	end

	-- Palm trees and stalls.
	for i = 1, 8 do
		local angle = (i / 8) * math.pi * 2 + math.pi / 8
		addPalmTree(Vector3.new(math.cos(angle) * 39, 0, math.sin(angle) * 39))
	end
	addMarketStall(Vector3.new(-28, 0, 18), Color3.fromRGB(255, 120, 120))
	addMarketStall(Vector3.new(28, 0, 18), Color3.fromRGB(120, 200, 255))
	addMarketStall(Vector3.new(-28, 0, -18), Color3.fromRGB(255, 200, 100))
	addMarketStall(Vector3.new(28, 0, -18), Color3.fromRGB(160, 230, 150))

	-- Sky dressing.
	addCloud(Vector3.new(-30, 50, -40))
	addCloud(Vector3.new(35, 58, -55))
	addCloud(Vector3.new(10, 46, 60))

	-- Eight plots in two rows.
	local plots = {}
	for i, x in ipairs(BrainrotCatalog.PlotRowX) do
		local color = BrainrotCatalog.PlotColors[i]
		local north = buildPlot(i, Vector3.new(x, 0, -BrainrotCatalog.PlotRowZ), color)
		table.insert(plots, north)
		local southColor = BrainrotCatalog.PlotColors[i + 4]
		local south = buildPlot(i + 4, Vector3.new(x, 0, BrainrotCatalog.PlotRowZ), southColor)
		table.insert(plots, south)
	end

	-- Spawn area near the plaza centre-south.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnLocation"
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Position = Vector3.new(0, 0.5, 18)
	spawn.Color = Color3.fromRGB(255, 230, 120)
	spawn.Material = Enum.Material.Neon
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = world
	local spawnPosition = Vector3.new(0, 4, 18)

	-- Prize Book board beside spawn.
	local prizePostLeft = makePart(
		"PrizePostLeft",
		Vector3.new(0.6, 8, 0.6),
		Vector3.new(9, 4, 24),
		Color3.fromRGB(120, 85, 50),
		Enum.Material.Wood
	)
	prizePostLeft.CanCollide = false
	local prizePostRight = makePart(
		"PrizePostRight",
		Vector3.new(0.6, 8, 0.6),
		Vector3.new(15, 4, 24),
		Color3.fromRGB(120, 85, 50),
		Enum.Material.Wood
	)
	prizePostRight.CanCollide = false
	local prizeBoard = makePart(
		"PrizeBookBoard",
		Vector3.new(7, 4.5, 0.4),
		Vector3.new(12, 6, 24),
		Color3.fromRGB(110, 70, 45),
		Enum.Material.Wood
	)
	prizeBoard.CanCollide = false
	makeBillboardLabel(
		prizeBoard,
		UDim2.fromScale(10, 5),
		"PRIZE BOOK\nCollect all " .. tostring(#BrainrotCatalog.Characters) .. " brainrots!",
		20,
		Color3.fromRGB(255, 245, 210),
		Color3.fromRGB(55, 35, 30)
	)

	-- Bandit gate at the west edge.
	local gateX = -(BrainrotCatalog.PlazaRadius + 7)
	local gateLeft = makePart(
		"GatePostLeft",
		Vector3.new(1, 10, 1),
		Vector3.new(gateX, 5, -5),
		Color3.fromRGB(45, 40, 45),
		Enum.Material.Wood
	)
	gateLeft.CanCollide = false
	local gateRight = makePart(
		"GatePostRight",
		Vector3.new(1, 10, 1),
		Vector3.new(gateX, 5, 5),
		Color3.fromRGB(45, 40, 45),
		Enum.Material.Wood
	)
	gateRight.CanCollide = false
	local gateBar = makePart(
		"GateBar",
		Vector3.new(1, 1, 11),
		Vector3.new(gateX, 10, 0),
		Color3.fromRGB(60, 50, 50),
		Enum.Material.Wood
	)
	gateBar.CanCollide = false
	makeBillboardLabel(
		gateBar,
		UDim2.fromScale(8, 3),
		"BANDIT GATE",
		24,
		Color3.fromRGB(255, 120, 100),
		Color3.fromRGB(30, 20, 20)
	)

	-- Wave wall, parked far away until an event.
	local wavePart = makePart(
		"WaveWall",
		Vector3.new(10, 30, 200),
		Vector3.new(-170, -20, 0),
		Color3.fromRGB(230, 70, 30),
		Enum.Material.Neon
	)
	wavePart.CanCollide = false
	wavePart.Transparency = 0.35

	return {
		Plots = plots,
		SpawnPosition = spawnPosition,
		WavePart = wavePart,
		BanditGatePosition = Vector3.new(gateX, 0, 0),
	}
end

return MapBuilder
