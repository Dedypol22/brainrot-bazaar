-- MapBuilder.luau (server module)
-- Builds the whole 3D world of Brainrot Bazaar from Parts: the circular
-- market plaza, the conveyor belt through its middle, eight player base
-- plots in a ring, the spawn area, palm trees, market stalls, clouds and
-- the tsunami wave wall. No prebuilt place parts are used besides the
-- baseplate the Rojo project file provides.

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))

local MapBuilder = {}

-- Slot offsets on a plot pad (two rows of five, local x/z studs).
local SLOT_OFFSETS = {
	Vector2.new(-7, -4),
	Vector2.new(-3.5, -4),
	Vector2.new(0, -4),
	Vector2.new(3.5, -4),
	Vector2.new(7, -4),
	Vector2.new(-7, 4),
	Vector2.new(-3.5, 4),
	Vector2.new(0, 4),
	Vector2.new(3.5, 4),
	Vector2.new(7, 4),
}

local function makePart(name, size, position, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = Workspace
	return part
end

local function makeBillboardLabel(parent, size, text, textSize, textColor, backgroundColor)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Adornee = parent
	gui.Size = UDim2.fromOffset(size.X, size.Y)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3.5, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 200
	gui.LightInfluence = 0

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = backgroundColor
	label.BackgroundTransparency = 0.25
	label.BorderSizePixel = 0
	label.Text = text
	label.TextColor3 = textColor
	label.TextSize = textSize
	label.Font = Enum.Font.SourceSansBold
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = gui

	gui.Parent = parent
	return gui
end

local function buildPlaza()
	-- Round market plaza: a flat cylinder disc, its top at y = 0.5.
	local plaza = Instance.new("Part")
	plaza.Name = "Plaza"
	plaza.Shape = Enum.PartType.Cylinder
	plaza.Size = Vector3.new(2, BrainrotCatalog.PlazaRadius * 2, BrainrotCatalog.PlazaRadius * 2)
	plaza.CFrame = CFrame.new(0, -0.5, 0) * CFrame.Angles(0, 0, math.rad(90))
	plaza.Color = Color3.fromRGB(235, 215, 170)
	plaza.Material = Enum.Material.Sand
	plaza.Anchored = true
	plaza.CanCollide = true
	plaza.TopSurface = Enum.SurfaceType.Smooth
	plaza.BottomSurface = Enum.SurfaceType.Smooth
	plaza.Parent = Workspace

	-- Golden medallion in the middle of the plaza.
	local medallion = Instance.new("Part")
	medallion.Name = "PlazaMedallion"
	medallion.Shape = Enum.PartType.Cylinder
	medallion.Size = Vector3.new(0.4, 16, 16)
	medallion.CFrame = CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, math.rad(90))
	medallion.Color = Color3.fromRGB(255, 200, 40)
	medallion.Material = Enum.Material.Neon
	medallion.Anchored = true
	medallion.CanCollide = false
	medallion.TopSurface = Enum.SurfaceType.Smooth
	medallion.BottomSurface = Enum.SurfaceType.Smooth
	medallion.Parent = Workspace
end

local function buildConveyor()
	-- The belt runs along the X axis through the plaza, z = 0.
	local belt = makePart(
		"ConveyorBelt",
		Vector3.new(62, 1, 10),
		Vector3.new(0, 1, 0),
		Color3.fromRGB(70, 70, 80),
		Enum.Material.Metal
	)
	belt.CanCollide = true

	-- Yellow guide stripes down the middle of the belt.
	for x = -28, 28, 4 do
		local stripe = makePart(
			"BeltStripe",
			Vector3.new(1.5, 0.1, 6),
			Vector3.new(x, 1.55, 0),
			Color3.fromRGB(255, 210, 40),
			Enum.Material.Neon
		)
		stripe.CanCollide = false
	end

	-- Side rails so the belt reads as a track.
	makePart("BeltRailNorth", Vector3.new(62, 1.2, 0.6), Vector3.new(0, 1.6, 5.2), Color3.fromRGB(200, 200, 210), Enum.Material.Metal)
	makePart("BeltRailSouth", Vector3.new(62, 1.2, 0.6), Vector3.new(0, 1.6, -5.2), Color3.fromRGB(200, 200, 210), Enum.Material.Metal)

	-- Entry and exit arches the brainrots ride through.
	for _, archX in ipairs({ -31, 31 }) do
		makePart("BeltArchLeft", Vector3.new(0.8, 7, 0.8), Vector3.new(archX, 4, 5), Color3.fromRGB(255, 120, 60), Enum.Material.SmoothPlastic)
		makePart("BeltArchRight", Vector3.new(0.8, 7, 0.8), Vector3.new(archX, 4, -5), Color3.fromRGB(255, 120, 60), Enum.Material.SmoothPlastic)
		local beam = makePart("BeltArchBeam", Vector3.new(0.8, 0.8, 11), Vector3.new(archX, 7.4, 0), Color3.fromRGB(255, 120, 60), Enum.Material.SmoothPlastic)
		beam.CanCollide = false
	end
end

local function buildSlotPad(plot, slotIndex)
	local offset = SLOT_OFFSETS[slotIndex]
	if not offset then
		return nil
	end
	local angle = plot.Angle
	local cosA = math.cos(angle)
	local sinA = math.sin(angle)
	local worldX = plot.Center.X + offset.X * cosA - offset.Y * sinA
	local worldZ = plot.Center.Z + offset.X * sinA + offset.Y * cosA
	local pad = Instance.new("Part")
	pad.Name = "SlotPad" .. slotIndex
	pad.Shape = Enum.PartType.Cylinder
	pad.Size = Vector3.new(0.3, 3.4, 3.4)
	pad.CFrame = CFrame.new(worldX, 1.15, worldZ) * CFrame.Angles(0, 0, math.rad(90))
	pad.Color = Color3.fromRGB(255, 255, 255)
	pad.Material = Enum.Material.SmoothPlastic
	pad.Anchored = true
	pad.CanCollide = false
	pad.Transparency = 0.35
	pad.TopSurface = Enum.SurfaceType.Smooth
	pad.BottomSurface = Enum.SurfaceType.Smooth
	pad.Parent = Workspace
	plot.SlotPads[slotIndex] = pad
	return pad
end

local function buildBasePlot(plotIndex, angle)
	local center = Vector3.new(
		BrainrotCatalog.PlotRingRadius * math.cos(angle),
		0,
		BrainrotCatalog.PlotRingRadius * math.sin(angle)
	)

	local plot = {
		Index = plotIndex,
		Angle = angle,
		Center = center,
		SlotPads = {},
		SlotPositions = {},
		Owner = nil,
		SignLabel = nil,
		LockUntil = 0,
		CooldownUntil = 0,
	}

	-- Plot pad: an 18x18 coloured square, top at y = 1.
	local pad = makePart(
		"BasePlot" .. plotIndex,
		Vector3.new(18, 1, 18),
		Vector3.new(center.X, 0.5, center.Z),
		BrainrotCatalog.PlotColors[plotIndex],
		Enum.Material.Grass
	)
	pad.CFrame = CFrame.new(center.X, 0.5, center.Z) * CFrame.Angles(0, -angle, 0)

	-- Slot world positions, rotated with the plot so every base faces the plaza.
	for slotIndex = 1, BrainrotCatalog.MaxSlotCount do
		local offset = SLOT_OFFSETS[slotIndex]
		local cosA = math.cos(angle)
		local sinA = math.sin(angle)
		local worldX = center.X + offset.X * cosA - offset.Y * sinA
		local worldZ = center.Z + offset.X * sinA + offset.Y * cosA
		plot.SlotPositions[slotIndex] = Vector3.new(worldX, 1, worldZ)
	end

	-- The first four slots get pads up front; the rest appear when bought.
	for slotIndex = 1, BrainrotCatalog.BaseSlotCount do
		buildSlotPad(plot, slotIndex)
	end

	-- Owner sign on the plaza-facing edge of the plot.
	local towardPlaza = -Vector3.new(math.cos(angle), 0, math.sin(angle))
	local signPosition = center + towardPlaza * 10.5
	makePart("PlotSignPole" .. plotIndex, Vector3.new(0.5, 4, 0.5), signPosition + Vector3.new(0, 2, 0), Color3.fromRGB(120, 70, 30), Enum.Material.Wood)
	local board = makePart(
		"PlotSignBoard" .. plotIndex,
		Vector3.new(7, 3, 0.4),
		signPosition + Vector3.new(0, 5.5, 0),
		Color3.fromRGB(250, 240, 210),
		Enum.Material.Wood
	)
	board.CFrame = CFrame.new(signPosition + Vector3.new(0, 5.5, 0)) * CFrame.Angles(0, -angle + math.rad(90), 0)
	local signGui = makeBillboardLabel(board, Vector2.new(240, 100), "Empty Plot\nClaim it by joining!", 22, Color3.fromRGB(60, 40, 20), Color3.fromRGB(250, 240, 210))
	plot.SignLabel = signGui

	return plot
end

local function buildSpawnArea()
	-- Spawn sits just south of the plaza, facing the conveyor: in the
	-- genre's hit games a joining player immediately sees the brainrots
	-- walking the belt, so the action is the first thing on screen.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnLocation"
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.CFrame = CFrame.lookAt(Vector3.new(0, 0.5, 54), Vector3.new(0, 0.5, 0))
	spawn.Color = Color3.fromRGB(80, 200, 100)
	spawn.Material = Enum.Material.Grass
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.AllowTeamChangeOnTouch = false
	spawn.Duration = 0
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.BottomSurface = Enum.SurfaceType.Smooth
	spawn.Parent = Workspace

	-- Welcome arch over the way into the plaza: two poles and a board.
	makePart("ArchPoleLeft", Vector3.new(1, 9, 1), Vector3.new(-8, 4.5, 46), Color3.fromRGB(255, 120, 60), Enum.Material.Wood)
	makePart("ArchPoleRight", Vector3.new(1, 9, 1), Vector3.new(8, 4.5, 46), Color3.fromRGB(255, 120, 60), Enum.Material.Wood)
	local archBoard = makePart("ArchBoard", Vector3.new(18, 3, 1), Vector3.new(0, 10, 46), Color3.fromRGB(255, 200, 40), Enum.Material.Wood)
	makeBillboardLabel(archBoard, Vector2.new(420, 90), "BRAINROT BAZAAR", 36, Color3.fromRGB(120, 30, 30), Color3.fromRGB(255, 200, 40))

	return Vector3.new(0, 3, 54)
end

local function buildPalmTree(position)
	local trunk = Instance.new("Part")
	trunk.Name = "PalmTrunk"
	trunk.Shape = Enum.PartType.Cylinder
	trunk.Size = Vector3.new(10, 1.4, 1.4)
	trunk.CFrame = CFrame.new(position + Vector3.new(0, 5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	trunk.Color = Color3.fromRGB(150, 100, 50)
	trunk.Material = Enum.Material.Wood
	trunk.Anchored = true
	trunk.CanCollide = true
	trunk.TopSurface = Enum.SurfaceType.Smooth
	trunk.BottomSurface = Enum.SurfaceType.Smooth
	trunk.Parent = Workspace

	local top = position + Vector3.new(0, 10, 0)
	for leafIndex = 0, 5 do
		local leafAngle = (leafIndex / 6) * math.pi * 2
		local leaf = Instance.new("Part")
		leaf.Name = "PalmLeaf"
		leaf.Size = Vector3.new(6, 0.3, 1.8)
		leaf.CFrame = CFrame.new(top + Vector3.new(math.cos(leafAngle) * 2.6, 0.4, math.sin(leafAngle) * 2.6))
			* CFrame.Angles(0, -leafAngle, math.rad(25))
		leaf.Color = Color3.fromRGB(60, 180, 80)
		leaf.Material = Enum.Material.Grass
		leaf.Anchored = true
		leaf.CanCollide = false
		leaf.TopSurface = Enum.SurfaceType.Smooth
		leaf.BottomSurface = Enum.SurfaceType.Smooth
		leaf.Parent = Workspace
	end

	-- Two coconuts under the leaves.
	for _, offset in ipairs({ Vector3.new(0.8, 9.4, 0.5), Vector3.new(-0.7, 9.4, -0.4) }) do
		local nut = Instance.new("Part")
		nut.Name = "Coconut"
		nut.Shape = Enum.PartType.Ball
		nut.Size = Vector3.new(1, 1, 1)
		nut.Position = position + offset
		nut.Color = Color3.fromRGB(110, 70, 30)
		nut.Material = Enum.Material.SmoothPlastic
		nut.Anchored = true
		nut.CanCollide = false
		nut.TopSurface = Enum.SurfaceType.Smooth
		nut.BottomSurface = Enum.SurfaceType.Smooth
		nut.Parent = Workspace
	end
end

local function buildMarketStall(angle)
	local radius = 40
	local center = Vector3.new(radius * math.cos(angle), 0, radius * math.sin(angle))
	local yaw = -angle + math.rad(90)

	local counter = makePart("StallCounter", Vector3.new(7, 2.5, 3), center + Vector3.new(0, 1.75, 0), Color3.fromRGB(200, 140, 80), Enum.Material.Wood)
	counter.CFrame = CFrame.new(center + Vector3.new(0, 1.75, 0)) * CFrame.Angles(0, yaw, 0)

	for _, postOffset in ipairs({ Vector3.new(-3.2, 0, -1.2), Vector3.new(3.2, 0, -1.2), Vector3.new(-3.2, 0, 1.2), Vector3.new(3.2, 0, 1.2) }) do
		local rotated = Vector3.new(
			postOffset.X * math.cos(yaw) - postOffset.Z * math.sin(yaw),
			postOffset.Y,
			postOffset.X * math.sin(yaw) + postOffset.Z * math.cos(yaw)
		)
		makePart("StallPost", Vector3.new(0.5, 5, 0.5), center + rotated + Vector3.new(0, 2.5, 0), Color3.fromRGB(120, 70, 30), Enum.Material.Wood)
	end

	-- Striped awning roof, tilted so it reads as a market stall.
	local roof = makePart("StallRoof", Vector3.new(8.5, 0.4, 4.5), center + Vector3.new(0, 6, 0), Color3.fromRGB(255, 90, 90), Enum.Material.SmoothPlastic)
	roof.CFrame = CFrame.new(center + Vector3.new(0, 6, 0)) * CFrame.Angles(math.rad(12), yaw, 0)
	roof.CanCollide = false

	-- Goods on the counter: a few bright boxes and balls, like market stock.
	local goods = {
		{ Vector3.new(-2, 0, 0), Color3.fromRGB(255, 220, 60), "Box" },
		{ Vector3.new(0, 0, 0.4), Color3.fromRGB(255, 120, 180), "Ball" },
		{ Vector3.new(2, 0, -0.3), Color3.fromRGB(90, 200, 255), "Box" },
	}
	for _, good in ipairs(goods) do
		local offset = good[1]
		local rotated = Vector3.new(
			offset.X * math.cos(yaw) - offset.Z * math.sin(yaw),
			offset.Y,
			offset.X * math.sin(yaw) + offset.Z * math.cos(yaw)
		)
		local item = Instance.new("Part")
		item.Name = "StallGoods"
		if good[3] == "Ball" then
			item.Shape = Enum.PartType.Ball
		end
		item.Size = Vector3.new(1.2, 1.2, 1.2)
		item.Position = center + rotated + Vector3.new(0, 3.6, 0)
		item.Color = good[2]
		item.Material = Enum.Material.SmoothPlastic
		item.Anchored = true
		item.CanCollide = false
		item.TopSurface = Enum.SurfaceType.Smooth
		item.BottomSurface = Enum.SurfaceType.Smooth
		item.Parent = Workspace
	end
end

local function buildClouds()
	local cloudSpots = {
		{ Vector3.new(-70, 48, -60), 14 },
		{ Vector3.new(60, 55, -70), 18 },
		{ Vector3.new(80, 45, 40), 12 },
		{ Vector3.new(-80, 52, 50), 16 },
		{ Vector3.new(0, 60, -90), 20 },
		{ Vector3.new(20, 47, 85), 13 },
		{ Vector3.new(-40, 58, 80), 15 },
		{ Vector3.new(90, 50, -20), 12 },
	}
	for _, spot in ipairs(cloudSpots) do
		local size = spot[2]
		local cloud = Instance.new("Part")
		cloud.Name = "Cloud"
		cloud.Shape = Enum.PartType.Ball
		cloud.Size = Vector3.new(size, size * 0.4, size * 0.7)
		cloud.Position = spot[1]
		cloud.Color = Color3.fromRGB(255, 255, 255)
		cloud.Material = Enum.Material.SmoothPlastic
		cloud.Transparency = 0.15
		cloud.Anchored = true
		cloud.CanCollide = false
		cloud.TopSurface = Enum.SurfaceType.Smooth
		cloud.BottomSurface = Enum.SurfaceType.Smooth
		cloud.Parent = Workspace
	end
end

local function buildWaveWall()
	local wave = Instance.new("Part")
	wave.Name = "TsunamiWave"
	wave.Size = Vector3.new(4, 26, 160)
	wave.Position = Vector3.new(-170, 13, 0)
	wave.Color = Color3.fromRGB(40, 140, 255)
	wave.Material = Enum.Material.Water
	wave.Transparency = 0.35
	wave.Anchored = true
	wave.CanCollide = false
	wave.Transparency = 1
	wave.TopSurface = Enum.SurfaceType.Smooth
	wave.BottomSurface = Enum.SurfaceType.Smooth
	wave.Parent = Workspace
	return wave
end

local function paintLighting()
	Lighting.ClockTime = 10
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(120, 120, 120)
	Lighting.OutdoorAmbient = Color3.fromRGB(140, 150, 170)
	Lighting.GlobalShadows = true
	Lighting.FogEnd = 1200
end

-- Builds the whole world once and hands back the references the other
-- server modules need (plots, spawn, belt, wave wall).
function MapBuilder.BuildWorld()
	paintLighting()
	buildPlaza()
	buildConveyor()
	local spawnPosition = buildSpawnArea()

	local plots = {}
	for plotIndex = 1, BrainrotCatalog.PlotCount do
		local angle = (plotIndex - 1) * (math.pi * 2 / BrainrotCatalog.PlotCount)
		plots[plotIndex] = buildBasePlot(plotIndex, angle)
	end

	-- Palm trees between the plots, just outside the plaza.
	for treeIndex = 0, 5 do
		local angle = math.rad(30 + treeIndex * 60)
		local position = Vector3.new(52 * math.cos(angle), 0, 52 * math.sin(angle))
		buildPalmTree(position)
	end

	-- Four market stalls on the plaza edge, between the plots.
	for _, stallAngle in ipairs({ math.rad(45), math.rad(135), math.rad(225), math.rad(315) }) do
		buildMarketStall(stallAngle)
	end

	buildClouds()
	local wave = buildWaveWall()

	return {
		Plots = plots,
		SpawnPosition = spawnPosition,
		WavePart = wave,
	}
end

-- Adds the visible pad for a slot that a player just bought.
function MapBuilder.CreateSlotPad(plot, slotIndex)
	return buildSlotPad(plot, slotIndex)
end

return MapBuilder
