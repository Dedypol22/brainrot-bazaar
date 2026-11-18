-- MapBuilder.luau
-- Builds the whole Brainrot Bazaar world out of plain Parts at runtime: the
-- plaza, the conveyor belt, decorations, the eight player base plots with
-- their slot pads, the spawn area and the parked tsunami wave wall. The
-- place file itself only holds scripts and a baseplate; everything visible
-- is created here and parented under one "World" folder in Workspace.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))

local MapBuilder = {}

local FLOOR_TOP_Y = 0.5 -- top surface of a plot's floor pad
local PAD_SIZE = Vector3.new(4, 0.2, 4)

local worldFolder = nil

-- ---------------------------------------------------------------------------
-- Small builders
-- ---------------------------------------------------------------------------

local function makePart(name, size, position, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = worldFolder
	return part
end

local function makeBillboardLabel(parent, size, text, textSize, textColor, backgroundColor)
	local gui = Instance.new("BillboardGui")
	gui.Name = "LabelGui"
	gui.Size = size
	gui.StudsOffset = Vector3.new(0, 0, 0)
	gui.AlwaysOnTop = true
	gui.Adornee = parent
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = backgroundColor
	label.BackgroundTransparency = 0.25
	label.Text = text
	label.TextColor3 = textColor
	label.TextSize = textSize
	label.Font = Enum.Font.GothamBold
	label.TextScaled = false
	label.Parent = gui
	gui.Parent = parent
	return gui
end

local function paintLighting()
	Lighting.ClockTime = 14
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(170, 180, 200)
	Lighting.OutdoorAmbient = Color3.fromRGB(190, 200, 220)
	Lighting.FogEnd = 1000
	Lighting.GlobalShadows = true
end

-- ---------------------------------------------------------------------------
-- Slot pads
-- ---------------------------------------------------------------------------

-- Two rows of five across the 24 x 16 floor pad.
local function slotPadPosition(plot, slotIndex)
	local column = (slotIndex - 1) % 5
	local row = math.floor((slotIndex - 1) / 5)
	local xOffset = (column - 2) * 4.8
	local zOffset = (row == 0) and -4 or 4
	return Vector3.new(
		plot.Center.X + xOffset,
		FLOOR_TOP_Y + 0.1,
		plot.Center.Z + zOffset
	)
end

local function buildSlotPad(plot, slotIndex)
	if plot.Pads[slotIndex] then
		return plot.Pads[slotIndex]
	end
	local pad = makePart(
		"SlotPad" .. slotIndex,
		PAD_SIZE,
		slotPadPosition(plot, slotIndex),
		Color3.fromRGB(245, 245, 245),
		Enum.Material.Neon
	)
	pad.Parent = plot.Model
	plot.Pads[slotIndex] = pad
	return pad
end

function MapBuilder.CreateSlotPad(plot, slotIndex)
	return buildSlotPad(plot, slotIndex)
end

-- ---------------------------------------------------------------------------
-- World pieces
-- ---------------------------------------------------------------------------

local function buildPlazaAndGround()
	-- Grass everywhere first, so nothing floats over the void.
	makePart("Ground", Vector3.new(220, 1, 220), Vector3.new(0, -0.55, 0),
		Color3.fromRGB(110, 200, 90), Enum.Material.Grass)
	-- The plaza itself: a fat cylinder disc in the middle.
	local plaza = makePart("Plaza", Vector3.new(1, BrainrotCatalog.PlazaRadius * 2, BrainrotCatalog.PlazaRadius * 2),
		Vector3.new(0, 0, 0), Color3.fromRGB(255, 214, 120), Enum.Material.Sand)
	plaza.Shape = Enum.PartType.Cylinder
	plaza.CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(90))
	-- A cheerful ring path around the plaza edge.
	local ring = makePart("PlazaRing", Vector3.new(1.1, 100, 100), Vector3.new(0, -0.05, 0),
		Color3.fromRGB(255, 170, 90), Enum.Material.Sand)
	ring.Shape = Enum.PartType.Cylinder
	ring.CFrame = CFrame.new(0, -0.05, 0) * CFrame.Angles(0, 0, math.rad(90))
end

local function buildBelt()
	local beltTopY = BrainrotCatalog.BeltTopY
	local belt = makePart("ConveyorBelt", Vector3.new(76, 1, 14), Vector3.new(0, beltTopY - 0.5, 0),
		Color3.fromRGB(45, 45, 55), Enum.Material.Metal)
	belt.Name = "ConveyorBelt"
	-- Side rails.
	for _, zSide in ipairs({ -7.5, 7.5 }) do
		makePart("BeltRail", Vector3.new(76, 1.2, 1), Vector3.new(0, beltTopY + 0.1, zSide),
			Color3.fromRGB(120, 120, 140), Enum.Material.Metal)
	end
	-- Glowing edge strips so the belt reads as "live".
	for _, zSide in ipairs({ -6.6, 6.6 }) do
		local strip = makePart("BeltGlowStrip", Vector3.new(76, 0.15, 0.5), Vector3.new(0, beltTopY + 0.05, zSide),
			Color3.fromRGB(255, 200, 60), Enum.Material.Neon)
		strip.CanCollide = false
	end
	-- Direction arrows painted along the belt.
	for x = -30, 30, 12 do
		local arrow = makePart("BeltArrow", Vector3.new(3, 0.12, 3), Vector3.new(x, beltTopY + 0.03, 0),
			Color3.fromRGB(255, 255, 255), Enum.Material.Neon)
		arrow.CanCollide = false
	end
	-- The big sign on posts over the middle of the belt.
	for _, xPost in ipairs({ -3, 3 }) do
		makePart("SignPost", Vector3.new(1, 11, 1), Vector3.new(xPost, beltTopY + 5.5, -8.5),
			Color3.fromRGB(140, 90, 40), Enum.Material.Wood)
		makePart("SignPost", Vector3.new(1, 11, 1), Vector3.new(xPost, beltTopY + 5.5, 8.5),
			Color3.fromRGB(140, 90, 40), Enum.Material.Wood)
	end
	local board = makePart("BazaarSign", Vector3.new(1.5, 4, 20), Vector3.new(0, beltTopY + 11, 0),
		Color3.fromRGB(255, 140, 60), Enum.Material.Wood)
	makeBillboardLabel(board, UDim2.fromOffset(420, 90), "BRAINROT BAZAAR", 42,
		Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 80, 20))
end

local function buildFence()
	-- A low fence square around the whole bazaar grounds.
	local half = 80
	local fenceColor = Color3.fromRGB(160, 110, 60)
	for x = -half, half, 8 do
		for _, zEdge in ipairs({ -half, half }) do
			makePart("FencePost", Vector3.new(0.8, 3, 0.8), Vector3.new(x, 1.5, zEdge), fenceColor, Enum.Material.Wood)
		end
	end
	for z = -half, half, 8 do
		for _, xEdge in ipairs({ -half, half }) do
			makePart("FencePost", Vector3.new(0.8, 3, 0.8), Vector3.new(xEdge, 1.5, z), fenceColor, Enum.Material.Wood)
		end
	end
	for _, zEdge in ipairs({ -half, half }) do
		makePart("FenceRail", Vector3.new(half * 2, 0.5, 0.5), Vector3.new(0, 2.4, zEdge), fenceColor, Enum.Material.Wood)
		makePart("FenceRail", Vector3.new(half * 2, 0.5, 0.5), Vector3.new(0, 1.1, zEdge), fenceColor, Enum.Material.Wood)
	end
	for _, xEdge in ipairs({ -half, half }) do
		makePart("FenceRail", Vector3.new(0.5, 0.5, half * 2), Vector3.new(xEdge, 2.4, 0), fenceColor, Enum.Material.Wood)
		makePart("FenceRail", Vector3.new(0.5, 0.5, half * 2), Vector3.new(xEdge, 1.1, 0), fenceColor, Enum.Material.Wood)
	end
end

local function buildPalmTree(x, z)
	makePart("PalmTrunk", Vector3.new(1.2, 9, 1.2), Vector3.new(x, 4.5, z),
		Color3.fromRGB(150, 100, 55), Enum.Material.Wood)
	for angle = 0, 300, 60 do
		local radians = math.rad(angle)
		local frond = makePart("PalmFrond", Vector3.new(7, 0.4, 2), Vector3.new(
			x + math.cos(radians) * 3, 9.6, z + math.sin(radians) * 3),
			Color3.fromRGB(60, 180, 80), Enum.Material.Grass)
		frond.CFrame = CFrame.new(frond.Position) * CFrame.Angles(0, -radians, math.rad(-18))
	end
end

local function buildStall(x, z, canopyColor)
	makePart("StallCounter", Vector3.new(8, 2.5, 3), Vector3.new(x, 1.25, z),
		Color3.fromRGB(170, 120, 70), Enum.Material.Wood)
	for _, dx in ipairs({ -3.6, 3.6 }) do
		for _, dz in ipairs({ -1.2, 1.2 }) do
			makePart("StallPost", Vector3.new(0.5, 6, 0.5), Vector3.new(x + dx, 3, z + dz),
				Color3.fromRGB(140, 90, 40), Enum.Material.Wood)
		end
	end
	local canopy = makePart("StallCanopy", Vector3.new(9.5, 0.5, 4.5), Vector3.new(x, 6.2, z),
		canopyColor, Enum.Material.Fabric)
	canopy.CFrame = CFrame.new(canopy.Position) * CFrame.Angles(math.rad(6), 0, 0)
end

local function buildClouds()
	local cloudColor = Color3.fromRGB(255, 255, 255)
	local spots = {
		{ -60, 68, -40 }, { 30, 74, -70 }, { 70, 66, 30 }, { -35, 72, 55 }, { 0, 78, 0 },
	}
	for _, spot in ipairs(spots) do
		local x, y, z = spot[1], spot[2], spot[3]
		local main = makePart("Cloud", Vector3.new(18, 3, 10), Vector3.new(x, y, z), cloudColor, Enum.Material.SmoothPlastic)
		main.CanCollide = false
		local puff = makePart("Cloud", Vector3.new(11, 4, 8), Vector3.new(x + 6, y + 1, z + 1), cloudColor, Enum.Material.SmoothPlastic)
		puff.CanCollide = false
		local puff2 = makePart("Cloud", Vector3.new(9, 2.5, 7), Vector3.new(x - 7, y + 0.5, z - 1), cloudColor, Enum.Material.SmoothPlastic)
		puff2.CanCollide = false
	end
end

local function buildPlot(index, x, z)
	local model = Instance.new("Model")
	model.Name = "Plot" .. index
	model.Parent = worldFolder

	local plot = {
		Index = index,
		Model = model,
		Center = Vector3.new(x, FLOOR_TOP_Y, z),
		Pads = {},
		Sign = nil,
		OwnerUserId = 0,
	}

	local floor = makePart("FloorPad", Vector3.new(24, 0.5, 16), Vector3.new(x, 0.25, z),
		BrainrotCatalog.PlotColors[index], Enum.Material.SmoothPlastic)
	floor.Parent = model
	-- A rim so the pad reads as a base.
	local rim = makePart("FloorRim", Vector3.new(25.5, 0.35, 17.5), Vector3.new(x, 0.17, z),
		Color3.fromRGB(90, 90, 100), Enum.Material.Metal)
	rim.Parent = model

	-- Owner sign at the back edge of the pad, facing the belt.
	local facing = (z < 0) and 1 or -1
	local signPost = makePart("SignPost", Vector3.new(0.7, 6, 0.7),
		Vector3.new(x, FLOOR_TOP_Y + 3, z - facing * 7), Color3.fromRGB(140, 90, 40), Enum.Material.Wood)
	signPost.Parent = model
	local signBoard = makePart("SignBoard", Vector3.new(9, 3, 0.6),
		Vector3.new(x, FLOOR_TOP_Y + 6.2, z - facing * 7), Color3.fromRGB(255, 240, 200), Enum.Material.Wood)
	signBoard.Parent = model
	local gui = makeBillboardLabel(signBoard, UDim2.fromOffset(300, 100), "BASE " .. index, 30,
		Color3.fromRGB(40, 40, 60), Color3.fromRGB(255, 240, 200))
	plot.Sign = gui:FindFirstChild("Label")

	-- The first BaseSlotCount pads exist from the start; the rest are built
	-- on demand by CreateSlotPad when the owner buys more room.
	for slotIndex = 1, BrainrotCatalog.BaseSlotCount do
		buildSlotPad(plot, slotIndex)
	end

	return plot
end

-- ---------------------------------------------------------------------------
-- BuildWorld
-- ---------------------------------------------------------------------------

function MapBuilder.BuildWorld()
	local existing = Workspace:FindFirstChild("World")
	if existing then
		existing:Destroy()
	end
	worldFolder = Instance.new("Folder")
	worldFolder.Name = "World"
	worldFolder.Parent = Workspace

	paintLighting()
	buildPlazaAndGround()
	buildBelt()
	buildFence()
	buildClouds()

	buildPalmTree(-46, -14)
	buildPalmTree(46, 14)
	buildPalmTree(-46, 16)
	buildPalmTree(48, -16)
	buildStall(-24, 20, Color3.fromRGB(255, 90, 90))
	buildStall(24, -20, Color3.fromRGB(90, 160, 255))
	buildStall(0, -22, Color3.fromRGB(255, 210, 80))

	local plots = {}
	for rowIndex, x in ipairs(BrainrotCatalog.PlotRowX) do
		table.insert(plots, buildPlot(rowIndex, x, -BrainrotCatalog.PlotRowZ))
	end
	for rowIndex, x in ipairs(BrainrotCatalog.PlotRowX) do
		table.insert(plots, buildPlot(rowIndex + 4, x, BrainrotCatalog.PlotRowZ))
	end

	-- Spawn: just south of the belt, in the middle of the plaza.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "BazaarSpawn"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Vector3.new(0, 1, 18)
	spawn.Color = Color3.fromRGB(90, 220, 140)
	spawn.Material = Enum.Material.Neon
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Parent = worldFolder
	local spawnPosition = Vector3.new(0, 3.5, 18)

	-- The tsunami wall, parked far away and sunk out of sight until the
	-- WaveManager sends it across the plaza.
	local wavePart = makePart("WaveWall", Vector3.new(10, 30, 200), Vector3.new(-170, -60, 0),
		Color3.fromRGB(60, 140, 255), Enum.Material.Glass)
	wavePart.Transparency = 0.35
	wavePart.CanCollide = false

	return {
		Plots = plots,
		SpawnPosition = spawnPosition,
		WavePart = wavePart,
	}
end

return MapBuilder
