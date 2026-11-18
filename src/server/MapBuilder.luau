-- MapBuilder.luau
-- Builds the whole Brainrot Bazaar world out of Parts at runtime: the plaza,
-- the conveyor belt, decorations, the eight player base plots with their slot
-- pads, the spawn point and the parked tsunami wave wall. The place file
-- itself only holds the scripts and a baseplate; everything a player sees is
-- created here when the server starts.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))

local MapBuilder = {}

local worldFolder = nil

-- Small construction helpers --------------------------------------------------

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

local function makeShapedPart(name, shape, size, cframe, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape
	part.Size = size
	part.CFrame = cframe
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
	gui.Name = "BillboardLabel"
	gui.Size = size
	gui.AlwaysOnTop = false

	local label = Instance.new("TextLabel")
	label.Name = "TextLabel"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundColor3 = backgroundColor
	label.BackgroundTransparency = 0.3
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextSize = textSize
	label.TextColor3 = textColor
	label.Parent = gui

	gui.Parent = parent
	return gui
end

-- Lighting --------------------------------------------------------------------

local function paintLighting()
	Lighting.ClockTime = 14
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(135, 135, 155)
	Lighting.OutdoorAmbient = Color3.fromRGB(170, 185, 210)
	Lighting.GlobalShadows = true
end

-- Plaza and ground --------------------------------------------------------------

local function buildGroundAndPlaza()
	-- A wide grass apron over the baseplate so the world reads as one fairground.
	makePart("Ground", Vector3.new(300, 0.2, 240), Vector3.new(0, 0.02, 0),
		Color3.fromRGB(105, 195, 105), Enum.Material.SmoothPlastic)
	-- The round plaza in the middle, radius PlazaRadius.
	makeShapedPart("Plaza", Enum.PartType.Cylinder, Vector3.new(1, BrainrotCatalog.PlazaRadius * 2, BrainrotCatalog.PlazaRadius * 2),
		CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(245, 215, 150), Enum.Material.SmoothPlastic)
end

-- The conveyor belt ---------------------------------------------------------------

local function buildBelt()
	local beltTopY = BrainrotCatalog.BeltTopY
	-- The belt itself: 76 long, 14 wide, its top exactly at BeltTopY.
	makePart("ConveyorBelt", Vector3.new(76, 1, 14), Vector3.new(0, beltTopY - 0.5, 0),
		Color3.fromRGB(38, 38, 46), Enum.Material.SmoothPlastic)
	-- Tread stripes across the belt so its motion reads at a glance.
	for x = -35, 35, 7 do
		makePart("BeltStripe", Vector3.new(0.7, 0.08, 13.4), Vector3.new(x, beltTopY + 0.04, 0),
			Color3.fromRGB(72, 72, 88), Enum.Material.SmoothPlastic)
	end
	-- Side rails and glowing edge strips.
	for _, side in ipairs({ -1, 1 }) do
		makePart("BeltRail", Vector3.new(76, 0.6, 0.4), Vector3.new(0, beltTopY + 0.2, side * 7.1),
			Color3.fromRGB(120, 125, 140), Enum.Material.Metal)
		makePart("BeltGlow", Vector3.new(76, 0.18, 0.35), Vector3.new(0, beltTopY + 0.12, side * 6.7),
			Color3.fromRGB(255, 200, 60), Enum.Material.Neon)
	end
	-- End rollers.
	for _, endSide in ipairs({ -1, 1 }) do
		makeShapedPart("BeltRoller", Enum.PartType.Cylinder, Vector3.new(14.6, 1.4, 1.4),
			CFrame.new(endSide * 38.5, beltTopY - 0.5, 0) * CFrame.Angles(0, math.rad(90), 0),
			Color3.fromRGB(90, 95, 110), Enum.Material.Metal)
	end
	-- The big sign on posts over the middle of the belt.
	for _, side in ipairs({ -1, 1 }) do
		makePart("SignPost", Vector3.new(0.5, 9, 0.5), Vector3.new(0, 4.5, side * 8.5),
			Color3.fromRGB(110, 80, 50), Enum.Material.Wood)
	end
	local board = makePart("BazaarSign", Vector3.new(0.4, 3, 19), Vector3.new(0, 9.6, 0),
		Color3.fromRGB(50, 40, 90), Enum.Material.SmoothPlastic)
	makeBillboardLabel(board, UDim2.fromOffset(520, 120), "BRAINROT BAZAAR", 64,
		Color3.fromRGB(255, 220, 80), Color3.fromRGB(30, 25, 60))
end

-- Decorations ---------------------------------------------------------------------

local function buildFence()
	local postColor = Color3.fromRGB(240, 240, 240)
	local railColor = Color3.fromRGB(255, 120, 120)
	local halfX, halfZ = 72, 50
	for z = -48, 48, 12 do
		for _, side in ipairs({ -1, 1 }) do
			makePart("FencePost", Vector3.new(0.35, 3, 0.35), Vector3.new(side * halfX, 1.5, z),
				postColor, Enum.Material.Wood)
		end
	end
	for x = -72, 72, 12 do
		for _, side in ipairs({ -1, 1 }) do
			makePart("FencePost", Vector3.new(0.35, 3, 0.35), Vector3.new(x, 1.5, side * halfZ),
				postColor, Enum.Material.Wood)
		end
	end
	for _, side in ipairs({ -1, 1 }) do
		makePart("FenceRail", Vector3.new(0.2, 0.3, halfZ * 2), Vector3.new(side * halfX, 2.4, 0),
			railColor, Enum.Material.Wood)
		makePart("FenceRail", Vector3.new(halfX * 2, 0.3, 0.2), Vector3.new(0, 2.4, side * halfZ),
			railColor, Enum.Material.Wood)
	end
end

local function buildPalm(x, z)
	makePart("PalmTrunk", Vector3.new(0.9, 7, 0.9), Vector3.new(x, 3.5, z),
		Color3.fromRGB(140, 100, 60), Enum.Material.Wood)
	local canopy = makeShapedPart("PalmCanopy", Enum.PartType.Ball, Vector3.new(6.5, 2.2, 6.5),
		CFrame.new(x, 7.6, z), Color3.fromRGB(60, 170, 70), Enum.Material.SmoothPlastic)
	canopy.CanCollide = false
end

local function buildStall(x, z, roofColor)
	makePart("StallCounter", Vector3.new(6, 2.6, 4), Vector3.new(x, 1.3, z),
		Color3.fromRGB(160, 110, 70), Enum.Material.Wood)
	for _, dx in ipairs({ -2.7, 2.7 }) do
		makePart("StallPost", Vector3.new(0.3, 5.2, 0.3), Vector3.new(x + dx, 2.6, z - 1.7),
			Color3.fromRGB(120, 85, 50), Enum.Material.Wood)
	end
	makePart("StallRoof", Vector3.new(7, 0.35, 5.5), Vector3.new(x, 5.3, z),
		roofColor, Enum.Material.SmoothPlastic)
	makePart("StallStripe", Vector3.new(7.05, 0.37, 1.8), Vector3.new(x, 5.31, z),
		Color3.fromRGB(250, 250, 250), Enum.Material.SmoothPlastic)
end

local function buildCloud(x, y, z)
	local puffs = {
		{ size = Vector3.new(11, 3, 7.5), offset = Vector3.new(0, 0, 0) },
		{ size = Vector3.new(7.5, 2.5, 5.5), offset = Vector3.new(5, 0.4, 1) },
		{ size = Vector3.new(6.5, 2.2, 5), offset = Vector3.new(-5, 0.3, -1) },
	}
	for _, puff in ipairs(puffs) do
		local cloud = makeShapedPart("Cloud", Enum.PartType.Ball, puff.size,
			CFrame.new(x + puff.offset.X, y + puff.offset.Y, z + puff.offset.Z),
			Color3.fromRGB(252, 252, 255), Enum.Material.SmoothPlastic)
		cloud.CanCollide = false
		cloud.Transparency = 0.1
	end
end

local function buildDecorations()
	buildFence()
	for _, spot in ipairs({ { 40, -14 }, { -40, -14 }, { 40, 14 }, { -40, 14 }, { 14, -44 }, { -14, 44 } }) do
		buildPalm(spot[1], spot[2])
	end
	buildStall(28, -16, Color3.fromRGB(220, 70, 70))
	buildStall(-28, -16, Color3.fromRGB(70, 130, 220))
	buildStall(28, 16, Color3.fromRGB(70, 190, 120))
	buildStall(-28, 16, Color3.fromRGB(240, 180, 60))
	buildCloud(-30, 58, -20)
	buildCloud(25, 64, 15)
	buildCloud(0, 70, -45)
	buildCloud(45, 60, 40)
	buildCloud(-50, 66, 30)
end

-- Base plots ----------------------------------------------------------------------

-- Slot pads sit on the 24x16 plot floor in two rows of five.
local function slotPadOffset(slotIndex)
	local row = slotIndex > 5 and 1 or 0
	local col = (slotIndex - 1) % 5
	local z = row == 0 and -4 or 4
	return Vector3.new(-9.6 + col * 4.8, 0, z)
end

local function buildSlotPad(plot, slotIndex)
	local existing = plot.Pads[slotIndex]
	if existing then
		existing.Transparency = 0
		existing.CanCollide = true
		return existing
	end
	local offset = slotPadOffset(slotIndex)
	local pad = makePart("SlotPad" .. slotIndex, Vector3.new(4, 0.3, 4),
		plot.Center + Vector3.new(offset.X, 1.15, offset.Z),
		plot.Color:Lerp(Color3.fromRGB(255, 255, 255), 0.35), Enum.Material.SmoothPlastic)
	pad.Parent = plot.Model
	plot.Pads[slotIndex] = pad
	return pad
end

local function buildPlot(index, x, z)
	local model = Instance.new("Model")
	model.Name = "Plot" .. index
	model.Parent = worldFolder

	local plot = {
		Index = index,
		Model = model,
		Center = Vector3.new(x, 0, z),
		Color = BrainrotCatalog.PlotColors[index],
		Pads = {},
		Sign = nil,
		OwnerUserId = 0,
	}

	local foundation = makePart("Foundation", Vector3.new(26, 0.4, 18), Vector3.new(x, 0.2, z),
		Color3.fromRGB(90, 90, 100), Enum.Material.SmoothPlastic)
	foundation.Parent = model
	local floor = makePart("Floor", Vector3.new(24, 1, 16), Vector3.new(x, 0.5, z),
		plot.Color, Enum.Material.SmoothPlastic)
	floor.Parent = model

	for slotIndex = 1, BrainrotCatalog.MaxSlotCount do
		local pad = buildSlotPad(plot, slotIndex)
		if slotIndex > BrainrotCatalog.BaseSlotCount then
			-- Locked slots start hidden until the owner buys and reveals them.
			pad.Transparency = 1
			pad.CanCollide = false
		end
	end

	-- Owner sign on the edge of the plot that faces the belt.
	local edgeZ = z < 0 and z + 6.8 or z - 6.8
	local post = makePart("SignPost", Vector3.new(0.4, 4.4, 0.4), Vector3.new(x, 2.2, edgeZ),
		Color3.fromRGB(110, 80, 50), Enum.Material.Wood)
	post.Parent = model
	local board = makePart("SignBoard", Vector3.new(7, 2.2, 0.3), Vector3.new(x, 4.6, edgeZ),
		Color3.fromRGB(45, 45, 60), Enum.Material.SmoothPlastic)
	board.Parent = model
	local signGui = makeBillboardLabel(board, UDim2.fromOffset(260, 70), "BASE " .. index, 30,
		Color3.fromRGB(255, 255, 255), Color3.fromRGB(25, 25, 35))
	plot.Sign = signGui:FindFirstChild("TextLabel")

	return plot
end

-- The world -----------------------------------------------------------------------

function MapBuilder.BuildWorld()
	worldFolder = Instance.new("Folder")
	worldFolder.Name = "World"
	worldFolder.Parent = Workspace

	paintLighting()
	buildGroundAndPlaza()
	buildBelt()
	buildDecorations()

	local plots = {}
	for i, x in ipairs(BrainrotCatalog.PlotRowX) do
		plots[i] = buildPlot(i, x, -BrainrotCatalog.PlotRowZ)
		plots[i + 4] = buildPlot(i + 4, x, BrainrotCatalog.PlotRowZ)
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Vector3.new(0, 0.6, 24)
	spawn.Color = Color3.fromRGB(255, 240, 170)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = worldFolder

	-- The tsunami wall, parked far away and deep below the ground until the
	-- wave manager sweeps it across the plaza.
	local wavePart = makePart("WaveWall", Vector3.new(10, 30, 200), Vector3.new(-170, -60, 0),
		Color3.fromRGB(60, 140, 255), Enum.Material.SmoothPlastic)
	wavePart.Transparency = 0.45
	wavePart.CanCollide = false

	return {
		Plots = plots,
		SpawnPosition = spawn.Position + Vector3.new(0, 3, 0),
		WavePart = wavePart,
	}
end

-- Public wrapper so BaseManager can reveal (or create) a slot pad later.
function MapBuilder.CreateSlotPad(plot, slotIndex)
	return buildSlotPad(plot, slotIndex)
end

return MapBuilder
