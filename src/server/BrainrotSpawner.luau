-- BrainrotSpawner.luau (server module)
-- Builds brainrot creature models from Parts only, spawns them on the
-- conveyor belt, rides them along it, and despawns them at the end when
-- nobody buys them. Also builds the same models for player bases.
-- A click on a belt brainrot tries to buy it (through the callback Main
-- wires up to the economy manager).

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))

local BrainrotSpawner = {}

-- Called by Main with (player, beltId) when a belt brainrot is clicked.
BrainrotSpawner.ClickedCallback = nil

local beltBrainrots = {} -- array of { Id, Character, Mutation, Cost, Rate, Model, PositionX }
local nextBeltId = 1
local map = nil

local function makeModelPart(model, baseCFrame, name, size, offset, color, material, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = baseCFrame * CFrame.new(offset)
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Shape = shape or Enum.PartType.Block
	part.Anchored = true
	part.CanCollide = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = model
	return part
end

-- Adds the one prop that makes a character recognisable.
local function addCharacterFeature(model, baseCFrame, character)
	local body = character.BodyColor
	local accent = character.AccentColor
	local feature = character.Feature

	if feature == "Phone" then
		-- A little black phone in the right hand.
		makeModelPart(model, baseCFrame, "Phone", Vector3.new(0.2, 1, 0.6), Vector3.new(0.6, 1.8, -1.4), Color3.fromRGB(30, 30, 30), Enum.Material.SmoothPlastic)
	elseif feature == "Sword" then
		-- A french-fry sword held high.
		local sword = makeModelPart(model, baseCFrame, "FrySword", Vector3.new(0.25, 2.4, 0.5), Vector3.new(0, 3, -1.4), accent, Enum.Material.Neon)
		sword.CFrame = baseCFrame * CFrame.new(0, 3, -1.4) * CFrame.Angles(0, 0, math.rad(20))
	elseif feature == "Headphones" then
		makeModelPart(model, baseCFrame, "HeadphoneLeft", Vector3.new(0.4, 1, 1), Vector3.new(0, 3.6, -1), accent, Enum.Material.SmoothPlastic)
		makeModelPart(model, baseCFrame, "HeadphoneRight", Vector3.new(0.4, 1, 1), Vector3.new(0, 3.6, 1), accent, Enum.Material.SmoothPlastic)
		makeModelPart(model, baseCFrame, "HeadphoneBand", Vector3.new(1.6, 0.3, 2.2), Vector3.new(0, 4.1, 0), accent, Enum.Material.SmoothPlastic)
	elseif feature == "CaptainHat" then
		local hat = makeModelPart(model, baseCFrame, "CaptainHat", Vector3.new(1.6, 0.4, 1.6), Vector3.new(0, 4.1, 0), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		hat.CFrame = baseCFrame * CFrame.new(0, 4.1, 0) * CFrame.Angles(0, 0, math.rad(90))
		makeModelPart(model, baseCFrame, "HatBand", Vector3.new(1.7, 0.2, 1.7), Vector3.new(0, 3.95, 0), Color3.fromRGB(255, 200, 40), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	elseif feature == "Bubblegum" then
		-- A big pink bubble at the mouth.
		makeModelPart(model, baseCFrame, "Bubble", Vector3.new(1.3, 1.3, 1.3), Vector3.new(1.3, 2.7, 0), accent, Enum.Material.Neon, Enum.PartType.Ball)
	elseif feature == "Toilet" then
		-- A white throne to sit on, with a tank behind.
		makeModelPart(model, baseCFrame, "ToiletSeat", Vector3.new(2.4, 0.9, 2.4), Vector3.new(0, 0.45, 0), accent, Enum.Material.SmoothPlastic)
		makeModelPart(model, baseCFrame, "ToiletTank", Vector3.new(0.7, 1.8, 2.2), Vector3.new(-1.1, 1.6, 0), accent, Enum.Material.SmoothPlastic)
	elseif feature == "Crown" then
		makeModelPart(model, baseCFrame, "CrownBase", Vector3.new(1.6, 0.5, 1.6), Vector3.new(0, 4.1, 0), Color3.fromRGB(255, 210, 60), Enum.Material.Neon)
		for _, spikeZ in ipairs({ -0.6, 0, 0.6 }) do
			makeModelPart(model, baseCFrame, "CrownSpike", Vector3.new(0.4, 0.8, 0.4), Vector3.new(0, 4.7, spikeZ), Color3.fromRGB(255, 210, 60), Enum.Material.Neon)
		end
	elseif feature == "Glasses" then
		makeModelPart(model, baseCFrame, "GlassesLeft", Vector3.new(0.15, 0.6, 0.7), Vector3.new(1, 3.3, -0.45), Color3.fromRGB(30, 30, 30), Enum.Material.SmoothPlastic)
		makeModelPart(model, baseCFrame, "GlassesRight", Vector3.new(0.15, 0.6, 0.7), Vector3.new(1, 3.3, 0.45), Color3.fromRGB(30, 30, 30), Enum.Material.SmoothPlastic)
		makeModelPart(model, baseCFrame, "GlassesBridge", Vector3.new(0.15, 0.15, 0.5), Vector3.new(1, 3.3, 0), Color3.fromRGB(30, 30, 30), Enum.Material.SmoothPlastic)
	elseif feature == "Moon" then
		-- A pale cheese moon floating over the head, with crater dots.
		makeModelPart(model, baseCFrame, "MoonBall", Vector3.new(1.5, 1.5, 1.5), Vector3.new(0, 5, 0), body, Enum.Material.Neon, Enum.PartType.Ball)
		makeModelPart(model, baseCFrame, "MoonCrater", Vector3.new(0.5, 0.5, 0.5), Vector3.new(0.6, 5.3, 0.3), accent, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	elseif feature == "Orb" then
		-- A glowing quantum orb above the head.
		local orb = makeModelPart(model, baseCFrame, "QuantumOrb", Vector3.new(1.1, 1.1, 1.1), Vector3.new(0, 5, 0), accent, Enum.Material.Neon, Enum.PartType.Ball)
		orb.Transparency = 0.2
	elseif feature == "Bagel" then
		-- A bagel worn like a hat: a flat ring with a dark hole.
		local bagel = makeModelPart(model, baseCFrame, "BagelRing", Vector3.new(0.6, 2.4, 2.4), Vector3.new(0, 4.2, 0), body, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		bagel.CFrame = baseCFrame * CFrame.new(0, 4.2, 0) * CFrame.Angles(0, 0, math.rad(90))
		local hole = makeModelPart(model, baseCFrame, "BagelHole", Vector3.new(0.7, 1, 1), Vector3.new(0, 4.2, 0), accent, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		hole.CFrame = baseCFrame * CFrame.new(0, 4.2, 0) * CFrame.Angles(0, 0, math.rad(90))
	elseif feature == "Waffle" then
		-- A waffle slab worn like a hat, with syrup drips.
		makeModelPart(model, baseCFrame, "WaffleSlab", Vector3.new(2.2, 0.4, 2.2), Vector3.new(0, 4.2, 0), body, Enum.Material.SmoothPlastic)
		makeModelPart(model, baseCFrame, "SyrupDrip", Vector3.new(0.5, 1, 0.5), Vector3.new(0.8, 3.8, 0.8), accent, Enum.Material.SmoothPlastic)
	end
end

-- Builds a blocky creature model for one character. The model faces +X,
-- stands on the ground at the given position, and carries a floating
-- label with its name, rarity and income. showCost adds a cost line.
function BrainrotSpawner.BuildBrainrotModel(character, mutationName, position, yaw, showCost)
	local model = Instance.new("Model")
	model.Name = character.Name
	local baseCFrame = CFrame.new(position) * CFrame.Angles(0, yaw or 0, 0)

	-- Body and head in the character's colours.
	local body = makeModelPart(model, baseCFrame, "Body", Vector3.new(2, 2, 2), Vector3.new(0, 1.4, 0), character.BodyColor, Enum.Material.SmoothPlastic)
	model.PrimaryPart = body
	makeModelPart(model, baseCFrame, "Head", Vector3.new(1.8, 1.5, 1.8), Vector3.new(0, 3.1, 0), character.BodyColor, Enum.Material.SmoothPlastic)

	-- Eyes on the +X face of the head, so the creature looks where it walks.
	for _, eyeZ in ipairs({ -0.45, 0.45 }) do
		makeModelPart(model, baseCFrame, "Eye", Vector3.new(0.2, 0.5, 0.4), Vector3.new(0.95, 3.3, eyeZ), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
		makeModelPart(model, baseCFrame, "Pupil", Vector3.new(0.15, 0.25, 0.2), Vector3.new(1.1, 3.3, eyeZ), Color3.fromRGB(20, 20, 20), Enum.Material.SmoothPlastic)
	end

	-- Legs and arms.
	for _, legZ in ipairs({ -0.55, 0.55 }) do
		makeModelPart(model, baseCFrame, "Leg", Vector3.new(0.6, 0.8, 0.6), Vector3.new(0, 0.4, legZ), character.AccentColor, Enum.Material.SmoothPlastic)
	end
	for _, armZ in ipairs({ -1.25, 1.25 }) do
		makeModelPart(model, baseCFrame, "Arm", Vector3.new(0.5, 1.2, 0.5), Vector3.new(0, 1.5, armZ), character.BodyColor, Enum.Material.SmoothPlastic)
	end

	addCharacterFeature(model, baseCFrame, character)

	-- Mutation aura: a coloured disc under the creature.
	if mutationName ~= "None" then
		local aura = makeModelPart(
			model,
			baseCFrame,
			"MutationAura",
			Vector3.new(0.3, 3.6, 3.6),
			Vector3.new(0, 0.15, 0),
			BrainrotCatalog.GetMutationColor(mutationName),
			Enum.Material.Neon,
			Enum.PartType.Cylinder
		)
		aura.CFrame = baseCFrame * CFrame.new(0, 0.15, 0) * CFrame.Angles(0, 0, math.rad(90))
		aura.Transparency = 0.3
	end

	-- Floating world label: name, rarity and money per second.
	local rate = BrainrotCatalog.GetIncomePerSecond(character, mutationName)
	local labelText = BrainrotCatalog.GetDisplayName(character, mutationName)
		.. "\n" .. character.Rarity .. "  $" .. rate .. "/s"
	if showCost then
		labelText = labelText .. "\nCost: $" .. character.Cost
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "BrainrotLabel"
	gui.Adornee = body
	gui.Size = UDim2.fromOffset(220, 90)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 150
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	label.BackgroundTransparency = 0.3
	label.BorderSizePixel = 0
	label.Text = labelText
	label.TextColor3 = BrainrotCatalog.GetRarityColor(character.Rarity)
	label.TextSize = 20
	label.Font = Enum.Font.SourceSansBold
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = gui
	gui.Parent = model

	model.Parent = Workspace
	return model
end

-- Rolls a new brainrot and puts it on the belt at the west end.
function BrainrotSpawner.SpawnBrainrotOnConveyor()
	if #beltBrainrots >= BrainrotCatalog.MaxBeltBrainrots then
		return nil
	end
	local rarity = BrainrotCatalog.RollRarity()
	local character = BrainrotCatalog.PickRandomCharacterOfRarity(rarity)
	local mutation = BrainrotCatalog.RollMutation()
	local beltId = nextBeltId
	nextBeltId = nextBeltId + 1

	local startPosition = Vector3.new(BrainrotCatalog.BeltStartX, BrainrotCatalog.BeltTopY, 0)
	local model = BrainrotSpawner.BuildBrainrotModel(character, mutation, startPosition, 0, true)
	model:SetAttribute("BeltId", beltId)

	local clicker = Instance.new("ClickDetector")
	clicker.Name = "BuyClick"
	clicker.MaxActivationDistance = 32
	clicker.MouseClick:Connect(function(player)
		if BrainrotSpawner.ClickedCallback then
			BrainrotSpawner.ClickedCallback(player, beltId)
		end
	end)
	clicker.Parent = model.PrimaryPart

	local entry = {
		Id = beltId,
		Character = character,
		Mutation = mutation,
		Cost = character.Cost,
		Rate = BrainrotCatalog.GetIncomePerSecond(character, mutation),
		Model = model,
		PositionX = BrainrotCatalog.BeltStartX,
	}
	table.insert(beltBrainrots, entry)
	return entry
end

function BrainrotSpawner.GetBeltBrainrotById(beltId)
	for _, entry in ipairs(beltBrainrots) do
		if entry.Id == beltId then
			return entry
		end
	end
	return nil
end

-- Removes one belt brainrot (bought, or washed away) and destroys its model.
function BrainrotSpawner.RemoveBeltBrainrot(beltId)
	for index, entry in ipairs(beltBrainrots) do
		if entry.Id == beltId then
			table.remove(beltBrainrots, index)
			if entry.Model then
				entry.Model:Destroy()
			end
			return entry
		end
	end
	return nil
end

-- Washes every brainrot still riding the belt away (tsunami).
function BrainrotSpawner.ClearAllBeltBrainrots()
	for _, entry in ipairs(beltBrainrots) do
		if entry.Model then
			entry.Model:Destroy()
		end
	end
	beltBrainrots = {}
end

-- Small summaries for the client's conveyor cards.
function BrainrotSpawner.GetBeltBrainrotsForClient()
	local summaries = {}
	for _, entry in ipairs(beltBrainrots) do
		table.insert(summaries, {
			Id = entry.Id,
			CharacterId = entry.Character.Id,
			Name = BrainrotCatalog.GetDisplayName(entry.Character, entry.Mutation),
			Rarity = entry.Character.Rarity,
			Cost = entry.Cost,
			Rate = entry.Rate,
			Mutation = entry.Mutation,
		})
	end
	return summaries
end

-- Slides every belt brainrot along the belt; despawns any that reach the end.
local function moveBeltBrainrotsAlongBelt(deltaTime)
	local step = BrainrotCatalog.BeltSpeedStudsPerSecond * deltaTime
	for index = #beltBrainrots, 1, -1 do
		local entry = beltBrainrots[index]
		entry.PositionX = entry.PositionX + step
		if entry.PositionX >= BrainrotCatalog.BeltEndX then
			table.remove(beltBrainrots, index)
			if entry.Model then
				entry.Model:Destroy()
			end
		elseif entry.Model then
			-- Shift the model sideways by this tick's step only, keeping
			-- the height it was built at. An absolute PivotTo down to the
			-- belt's top Y would sink the model into the belt, because
			-- the model pivot sits at its body centre, not at its feet.
			local pivot = entry.Model:GetPivot()
			entry.Model:PivotTo(pivot + Vector3.new(step, 0, 0))
		end
	end
end

function BrainrotSpawner.Init(worldMap)
	map = worldMap
	math.randomseed(os.time())
	RunService.Heartbeat:Connect(moveBeltBrainrotsAlongBelt)
	task.spawn(function()
		while true do
			task.wait(BrainrotCatalog.SpawnIntervalSeconds)
			BrainrotSpawner.SpawnBrainrotOnConveyor()
		end
	end)
end

return BrainrotSpawner
