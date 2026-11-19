-- MapBuilder.luau
-- Builds the whole Brainrot Bazaar world out of parts at runtime: plaza,
-- conveyor belt, eight base plots, decorations, the Prize Book board,
-- the bandit gate and the sambal wave wall.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))

local MapBuilder = {}

local worldFolder = nil

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
	if worldFolder then
		part.Parent = worldFolder
	end
	return part
end

local function makeBillboardLabel(parent, size, text, textSize, textColor, backgroundColor)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = size
	gui.StudsOffset = Vector3.new(0, 3, 0)
	gui.AlwaysOnTop = true
	gui.Parent = parent
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = backgroundColor or Color3.fromRGB(40, 35, 50)
	label.BackgroundTransparency = 0.25
	label.Text = text
	label.TextSize = textSize or 20
	label.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = false
	label.Parent = gui
	return label
end

local function paintLighting()
	Lighting.ClockTime = 14
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(140, 140, 160)
	Lighting.OutdoorAmbient = Color3.fromRGB(170, 180, 200)
	Lighting.GlobalShadows = true
end

local function slotPadOffset(slotIndex)
	-- Two rows of five across a 24 x 16 pad.
	local column = (slotIndex - 1) % 5
	local row = math.floor((slotIndex - 1) / 5)
	return Vector3.new(-8 + column * 4, 0.35, -4 + row * 8)
end

local function buildSlotPad(plot, slotIndex)
	local pad = Instance.new("Part")
	pad.Name = "SlotPad" .. slotIndex
	pad.Size = Vector3.new(3.6, 0.5, 3.6)
	pad.Position = plot.Center + slotPadOffset(slotIndex)
	pad.Color = Color3.fromRGB(245, 245, 245)
	pad.Material = Enum.Material.SmoothPlastic
	pad.Anchored = true
	pad.TopSurface = Enum.SurfaceType.Smooth
	pad.BottomSurface = Enum.SurfaceType.Smooth
	pad.Parent = plot.Model
	plot.Pads[slotIndex] = pad
	return pad
end

function MapBuilder.CreateSlotPad(plot, slotIndex)
	return buildSlotPad(plot, slotIndex)
end

local function buildPlot(index, center)
	local model = Instance.new("Model")
	model.Name = "Plot" .. index
	model.Parent = worldFolder

	local floorPad = Instance.new("Part")
	floorPad.Name = "Floor"
	floorPad.Size = Vector3.new(24, 1, 16)
	floorPad.Position = Vector3.new(center.X, 0, center.Z)
	floorPad.Color = BrainrotCatalog.PlotColors[index]
	floorPad.Material = Enum.Material.SmoothPlastic
	floorPad.Anchored = true
	floorPad.Parent = model

	local signPost = Instance.new("Part")
	signPost.Name = "SignPost"
	signPost.Size = Vector3.new(0.6, 6, 0.6)
	signPost.Position = Vector3.new(center.X, 3, center.Z - 9)
	signPost.Color = Color3.fromRGB(110, 75, 40)
	signPost.Material = Enum.Material.Wood
	signPost.Anchored = true
	signPost.Parent = model

	local signLabel = makeBillboardLabel(signPost, UDim2.fromOffset(220, 80), "BASE " .. index, 22, Color3.fromRGB(255, 255, 255), Color3.fromRGB(50, 45, 70))

	local plot = {
		Index = index,
		Model = model,
		Center = Vector3.new(center.X, 0.5, center.Z),
		Pads = {},
		Sign = signLabel,
		OwnerUserId = 0,
	}
	for slotIndex = 1, BrainrotCatalog.BaseSlotCount do
		buildSlotPad(plot, slotIndex)
	end
	return plot
end

local function buildDecorations()
	-- Palm trees: a tilted trunk and a few leaf slabs.
	for _, spot in ipairs({ Vector3.new(-40, 0, -20), Vector3.new(42, 0, 18), Vector3.new(-42, 0, 22), Vector3.new(38, 0, -24) }) do
		local trunk = makePart("PalmTrunk", Vector3.new(1, 7, 1), spot + Vector3.new(0, 3.5, 0), Color3.fromRGB(140, 100, 60), Enum.Material.Wood)
		trunk.CFrame = CFrame.new(trunk.Position) * CFrame.Angles(0, 0, math.rad(8))
		for leafIndex = 1, 4 do
			local leaf = makePart("PalmLeaf", Vector3.new(6, 0.4, 1.6), spot + Vector3.new(0, 7.2, 0), Color3.fromRGB(70, 170, 80), Enum.Material.SmoothPlastic)
			leaf.CFrame = CFrame.new(leaf.Position) * CFrame.Angles(0, math.rad(leafIndex * 90), math.rad(-18))
		end
	end
	-- Market stalls.
	for _, spot in ipairs({ Vector3.new(-24, 0, -14), Vector3.new(24, 0, 14), Vector3.new(0, 0, -26) }) do
		makePart("StallCounter", Vector3.new(6, 2.5, 3), spot + Vector3.new(0, 1.25, 0), Color3.fromRGB(170, 120, 70), Enum.Material.Wood)
		makePart("StallRoof", Vector3.new(7, 0.4, 4.5), spot + Vector3.new(0, 4.4, 0), Color3.fromRGB(220, 70, 70), Enum.Material.SmoothPlastic)
		makePart("StallPostL", Vector3.new(0.4, 4.4, 0.4), spot + Vector3.new(-3, 2.2, 0), Color3.fromRGB(120, 85, 45), Enum.Material.Wood)
		makePart("StallPostR", Vector3.new(0.4, 4.4, 0.4), spot + Vector3.new(3, 2.2, 0), Color3.fromRGB(120, 85, 45), Enum.Material.Wood)
	end
	-- Blocky clouds.
	for _, spot in ipairs({ Vector3.new(-30, 42, -30), Vector3.new(25, 48, 10), Vector3.new(0, 44, 35), Vector3.new(45, 40, -35) }) do
		makePart("Cloud", Vector3.new(14, 2.5, 7), spot, Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
		makePart("CloudPuff", Vector3.new(8, 2.5, 6), spot + Vector3.new(3, 1.4, 0), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
	end
end

function MapBuilder.BuildWorld()
	paintLighting()

	worldFolder = Instance.new("Folder")
	worldFolder.Name = "World"
	worldFolder.Parent = Workspace

	-- Plaza ground.
	local plaza = makePart("Plaza", Vector3.new(BrainrotCatalog.PlazaRadius * 2 + 30, 1, BrainrotCatalog.PlazaRadius * 2 + 30), Vector3.new(0, -0.5, 0), Color3.fromRGB(120, 210, 130), Enum.Material.SmoothPlastic)
	plaza.Shape = Enum.PartType.Block
	local plazaDisc = Instance.new("Part")
	plazaDisc.Name = "PlazaDisc"
	plazaDisc.Shape = Enum.PartType.Cylinder
	plazaDisc.Size = Vector3.new(1, BrainrotCatalog.PlazaRadius * 2, BrainrotCatalog.PlazaRadius * 2)
	plazaDisc.CFrame = CFrame.new(0, 0.05, 0) * CFrame.Angles(0, 0, math.rad(90))
	plazaDisc.Color = Color3.fromRGB(255, 225, 160)
	plazaDisc.Material = Enum.Material.SmoothPlastic
	plazaDisc.Anchored = true
	plazaDisc.Parent = worldFolder

	-- Conveyor belt.
	local belt = makePart("Belt", Vector3.new(76, 1, 14), Vector3.new(0, BrainrotCatalog.BeltTopY - 0.5, 0), Color3.fromRGB(45, 45, 55), Enum.Material.SmoothPlastic)
	belt.Name = "ConveyorBelt"
	makePart("BeltRailNorth", Vector3.new(76, 1, 0.8), Vector3.new(0, BrainrotCatalog.BeltTopY + 0.4, -7.2), Color3.fromRGB(90, 90, 110), Enum.Material.Metal)
	makePart("BeltRailSouth", Vector3.new(76, 1, 0.8), Vector3.new(0, BrainrotCatalog.BeltTopY + 0.4, 7.2), Color3.fromRGB(90, 90, 110), Enum.Material.Metal)
	local glowNorth = makePart("BeltGlowNorth", Vector3.new(76, 0.25, 0.35), Vector3.new(0, BrainrotCatalog.BeltTopY + 0.1, -6.6), Color3.fromRGB(255, 210, 80), Enum.Material.Neon)
	glowNorth.CanCollide = false
	local glowSouth = makePart("BeltGlowSouth", Vector3.new(76, 0.25, 0.35), Vector3.new(0, BrainrotCatalog.BeltTopY + 0.1, 6.6), Color3.fromRGB(255, 210, 80), Enum.Material.Neon)
	glowSouth.CanCollide = false

	-- Belt sign on posts.
	makePart("BeltSignPostL", Vector3.new(0.7, 10, 0.7), Vector3.new(-8, 5, -8), Color3.fromRGB(110, 75, 40), Enum.Material.Wood)
	makePart("BeltSignPostR", Vector3.new(0.7, 10, 0.7), Vector3.new(8, 5, -8), Color3.fromRGB(110, 75, 40), Enum.Material.Wood)
	local beltSign = makePart("BeltSign", Vector3.new(18, 3.5, 0.5), Vector3.new(0, 9.5, -8), Color3.fromRGB(255, 170, 50), Enum.Material.SmoothPlastic)
	makeBillboardLabel(beltSign, UDim2.fromOffset(420, 90), "BRAINROT BAZAAR", 30, Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 90, 30))

	-- Perimeter fence.
	local fenceColor = Color3.fromRGB(150, 110, 70)
	local radius = BrainrotCatalog.PlazaRadius + 12
	for _, edge in ipairs({
		{ Vector3.new(0, 1, -radius), Vector3.new(radius * 2, 2, 0.6) },
		{ Vector3.new(0, 1, radius), Vector3.new(radius * 2, 2, 0.6) },
		{ Vector3.new(-radius, 1, 0), Vector3.new(0.6, 2, radius * 2) },
		{ Vector3.new(radius, 1, 0), Vector3.new(0.6, 2, radius * 2) },
	}) do
		makePart("Fence", edge[2], edge[1], fenceColor, Enum.Material.Wood)
	end

	buildDecorations()

	-- Base plots: row of four south, row of four north.
	local plots = {}
	for i, x in ipairs(BrainrotCatalog.PlotRowX) do
		plots[i] = buildPlot(i, Vector3.new(x, 0, -BrainrotCatalog.PlotRowZ))
	end
	for i, x in ipairs(BrainrotCatalog.PlotRowX) do
		plots[i + 4] = buildPlot(i + 4, Vector3.new(x, 0, BrainrotCatalog.PlotRowZ))
	end

	-- Spawn.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnLocation"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Vector3.new(0, 0.6, 22)
	spawn.Color = Color3.fromRGB(90, 200, 255)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Parent = worldFolder
	local spawnPosition = Vector3.new(0, 3, 22)

	-- Prize Book board near spawn.
	makePart("PrizeBookPostL", Vector3.new(0.6, 6, 0.6), Vector3.new(10, 3, 24), Color3.fromRGB(110, 75, 40), Enum.Material.Wood)
	makePart("PrizeBookPostR", Vector3.new(0.6, 6, 0.6), Vector3.new(18, 3, 24), Color3.fromRGB(110, 75, 40), Enum.Material.Wood)
	local prizeBoard = makePart("PrizeBookBoard", Vector3.new(10, 5, 0.5), Vector3.new(14, 5, 24), Color3.fromRGB(150, 105, 55), Enum.Material.Wood)
	makeBillboardLabel(prizeBoard, UDim2.fromOffset(360, 110), "PRIZE BOOK\nCollect all " .. #BrainrotCatalog.Characters .. " brainrots!", 22, Color3.fromRGB(255, 240, 180), Color3.fromRGB(90, 60, 30))

	-- Bandit gate at the west edge.
	local gateX = -(BrainrotCatalog.PlazaRadius + 7)
	makePart("BanditGatePostL", Vector3.new(1, 9, 1), Vector3.new(gateX, 4.5, -4), Color3.fromRGB(50, 45, 55), Enum.Material.Wood)
	makePart("BanditGatePostR", Vector3.new(1, 9, 1), Vector3.new(gateX, 4.5, 4), Color3.fromRGB(50, 45, 55), Enum.Material.Wood)
	local gateBar = makePart("BanditGateBar", Vector3.new(1, 1.2, 9), Vector3.new(gateX, 8.5, 0), Color3.fromRGB(50, 45, 55), Enum.Material.Wood)
	makeBillboardLabel(gateBar, UDim2.fromOffset(260, 70), "BANDIT GATE", 22, Color3.fromRGB(255, 120, 120), Color3.fromRGB(30, 25, 35))
	local banditGatePosition = Vector3.new(gateX, 0, 0)

	-- Sambal wave wall, parked far away.
	local wavePart = Instance.new("Part")
	wavePart.Name = "WaveWall"
	wavePart.Size = Vector3.new(10, 30, 200)
	wavePart.Position = Vector3.new(-170, -40, 0)
	wavePart.Color = Color3.fromRGB(230, 70, 30)
	wavePart.Material = Enum.Material.SmoothPlastic
	wavePart.Transparency = 0.35
	wavePart.Anchored = true
	wavePart.CanCollide = false
	wavePart.Parent = worldFolder

	return {
		Plots = plots,
		SpawnPosition = spawnPosition,
		WavePart = wavePart,
		BanditGatePosition = banditGatePosition,
	}
end

return MapBuilder
