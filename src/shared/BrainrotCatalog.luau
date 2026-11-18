-- BrainrotCatalog.luau
-- The single source of truth for Brainrot Bazaar: every character, rarity,
-- mutation, price and tuning number lives here and nowhere else. Server
-- modules and the client all read from this module, so rebalancing the game
-- means editing this one file.

local BrainrotCatalog = {}

-- ---------------------------------------------------------------------------
-- Economy and timing tuning
-- ---------------------------------------------------------------------------

BrainrotCatalog.StartingCash = 500
BrainrotCatalog.BaseSlotCount = 4
BrainrotCatalog.MaxSlotCount = 10
-- Cash price of each extra slot, in order (5th slot first, 10th last).
BrainrotCatalog.SlotCosts = { 500, 2000, 8000, 25000, 75000, 200000 }
BrainrotCatalog.SellRefundFraction = 0.5

BrainrotCatalog.SpawnIntervalSeconds = 12
BrainrotCatalog.MaxBeltBrainrots = 7
BrainrotCatalog.BeltStartX = -34
BrainrotCatalog.BeltEndX = 34
BrainrotCatalog.BeltSpeedStudsPerSecond = 5
BrainrotCatalog.BeltTopY = 1.5

BrainrotCatalog.LockDurationSeconds = 45
BrainrotCatalog.LockCooldownSeconds = 120

BrainrotCatalog.WaveIntervalSeconds = 180
BrainrotCatalog.WaveWarningSeconds = 10

BrainrotCatalog.RebirthCashThreshold = 1000000
BrainrotCatalog.RebirthIncomeBonus = 0.25 -- +25% income per rebirth, stacking

BrainrotCatalog.AutosaveIntervalSeconds = 60

BrainrotCatalog.PlazaRadius = 45
-- The eight base plots stand in two rows flanking the conveyor belt,
-- four on the north side and four on the south, like the genre's hits:
-- every base is a short run from the belt and from every rival.
BrainrotCatalog.PlotRowZ = 34
BrainrotCatalog.PlotRowX = { -57, -19, 19, 57 }
BrainrotCatalog.PlotCount = 8

-- ---------------------------------------------------------------------------
-- Rarities
-- ---------------------------------------------------------------------------

BrainrotCatalog.Rarities = {
	Common = {
		Name = "Common",
		Color = Color3.fromRGB(170, 170, 170),
		Weight = 45,
		Order = 1,
	},
	Rare = {
		Name = "Rare",
		Color = Color3.fromRGB(70, 130, 255),
		Weight = 25,
		Order = 2,
	},
	Epic = {
		Name = "Epic",
		Color = Color3.fromRGB(170, 80, 255),
		Weight = 15,
		Order = 3,
	},
	Legendary = {
		Name = "Legendary",
		Color = Color3.fromRGB(255, 200, 40),
		Weight = 9,
		Order = 4,
	},
	Mythic = {
		Name = "Mythic",
		Color = Color3.fromRGB(255, 60, 60),
		Weight = 5,
		Order = 5,
	},
	Secret = {
		Name = "Secret",
		Color = Color3.fromRGB(255, 80, 200),
		Weight = 1,
		Order = 6,
	},
}

BrainrotCatalog.RarityOrder = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Secret" }

-- ---------------------------------------------------------------------------
-- Mutations
-- ---------------------------------------------------------------------------

BrainrotCatalog.Mutations = {
	None = {
		Name = "None",
		Multiplier = 1,
		Color = Color3.fromRGB(255, 255, 255),
	},
	Golden = {
		Name = "Golden",
		Multiplier = 2,
		Color = Color3.fromRGB(255, 215, 0),
	},
	Diamond = {
		Name = "Diamond",
		Multiplier = 5,
		Color = Color3.fromRGB(140, 230, 255),
	},
	Rainbow = {
		Name = "Rainbow",
		Multiplier = 10,
		Color = Color3.fromRGB(255, 100, 220),
	},
}

-- ---------------------------------------------------------------------------
-- The cast: twelve original absurd characters, two per rarity.
-- Feature names pick the extra prop the model builder adds.
-- ---------------------------------------------------------------------------

BrainrotCatalog.Characters = {
	{
		Id = "BananaphoneBarry",
		Name = "Bananaphone Barry",
		Rarity = "Common",
		Cost = 150,
		IncomePerSecond = 12,
		BodyColor = Color3.fromRGB(255, 220, 60),
		AccentColor = Color3.fromRGB(120, 70, 20),
		Feature = "Phone",
		Blurb = "A banana holding a phone, always on a call.",
	},
	{
		Id = "SirFriesALot",
		Name = "Sir Fries-A-Lot",
		Rarity = "Common",
		Cost = 350,
		IncomePerSecond = 24,
		BodyColor = Color3.fromRGB(220, 60, 50),
		AccentColor = Color3.fromRGB(255, 210, 60),
		Feature = "Sword",
		Blurb = "A french-fries knight sworn to protect the ketchup.",
	},
	{
		Id = "DJToastShark",
		Name = "DJ Toast Shark",
		Rarity = "Rare",
		Cost = 1200,
		IncomePerSecond = 45,
		BodyColor = Color3.fromRGB(90, 130, 200),
		AccentColor = Color3.fromRGB(255, 140, 40),
		Feature = "Headphones",
		Blurb = "A shark that drops beats instead of dropping crumbs.",
	},
	{
		Id = "CaptainCroissant",
		Name = "Captain Croissant",
		Rarity = "Rare",
		Cost = 2500,
		IncomePerSecond = 75,
		BodyColor = Color3.fromRGB(230, 180, 90),
		AccentColor = Color3.fromRGB(255, 255, 255),
		Feature = "CaptainHat",
		Blurb = "Sails the butter seas in search of flaky treasure.",
	},
	{
		Id = "BubblegumYeti",
		Name = "Bubblegum Yeti",
		Rarity = "Epic",
		Cost = 8000,
		IncomePerSecond = 160,
		BodyColor = Color3.fromRGB(240, 240, 245),
		AccentColor = Color3.fromRGB(255, 120, 180),
		Feature = "Bubblegum",
		Blurb = "A yeti that blows bubbles big enough to live in.",
	},
	{
		Id = "TurboToiletTRex",
		Name = "Turbo Toilet T-Rex",
		Rarity = "Epic",
		Cost = 15000,
		IncomePerSecond = 280,
		BodyColor = Color3.fromRGB(80, 180, 90),
		AccentColor = Color3.fromRGB(250, 250, 250),
		Feature = "Toilet",
		Blurb = "A tiny-armed T-Rex with a turbocharged throne.",
	},
	{
		Id = "GoldenSpaghettiSphinx",
		Name = "Golden Spaghetti Sphinx",
		Rarity = "Legendary",
		Cost = 50000,
		IncomePerSecond = 650,
		BodyColor = Color3.fromRGB(255, 210, 60),
		AccentColor = Color3.fromRGB(200, 40, 40),
		Feature = "Crown",
		Blurb = "Asks riddles in noodle form. Nobody has answered one.",
	},
	{
		Id = "ProfessorPicklephant",
		Name = "Professor Picklephant",
		Rarity = "Legendary",
		Cost = 90000,
		IncomePerSecond = 1100,
		BodyColor = Color3.fromRGB(90, 160, 70),
		AccentColor = Color3.fromRGB(140, 90, 200),
		Feature = "Glasses",
		Blurb = "An elephant pickled in knowledge. Tenured in brine.",
	},
	{
		Id = "MoonCheeseMoose",
		Name = "Moon Cheese Moose",
		Rarity = "Mythic",
		Cost = 250000,
		IncomePerSecond = 2600,
		BodyColor = Color3.fromRGB(240, 230, 160),
		AccentColor = Color3.fromRGB(120, 120, 130),
		Feature = "Moon",
		Blurb = "A moose made of moon cheese. The moon denies everything.",
	},
	{
		Id = "QuantumQuokka",
		Name = "Quantum Quokka",
		Rarity = "Mythic",
		Cost = 450000,
		IncomePerSecond = 4800,
		BodyColor = Color3.fromRGB(150, 100, 60),
		AccentColor = Color3.fromRGB(80, 220, 255),
		Feature = "Orb",
		Blurb = "Happy in two places at once. Mostly.",
	},
	{
		Id = "TheInfiniteBagel",
		Name = "The Infinite Bagel",
		Rarity = "Secret",
		Cost = 1500000,
		IncomePerSecond = 15000,
		BodyColor = Color3.fromRGB(210, 160, 90),
		AccentColor = Color3.fromRGB(120, 70, 30),
		Feature = "Bagel",
		Blurb = "A bagel with no beginning and no end. Still warm.",
	},
	{
		Id = "BaronVonWafflefish",
		Name = "Baron Von Wafflefish",
		Rarity = "Secret",
		Cost = 2500000,
		IncomePerSecond = 17000,
		BodyColor = Color3.fromRGB(200, 140, 50),
		AccentColor = Color3.fromRGB(90, 50, 20),
		Feature = "Waffle",
		Blurb = "A fish of noble syrup, swimming in maple.",
	},
}

-- Distinct pastel floor colour for each of the eight base plots.
BrainrotCatalog.PlotColors = {
	Color3.fromRGB(255, 170, 170),
	Color3.fromRGB(255, 220, 150),
	Color3.fromRGB(180, 230, 150),
	Color3.fromRGB(150, 220, 230),
	Color3.fromRGB(170, 170, 255),
	Color3.fromRGB(230, 170, 255),
	Color3.fromRGB(255, 190, 210),
	Color3.fromRGB(200, 200, 200),
}

-- ---------------------------------------------------------------------------
-- Lookups and rolls
-- ---------------------------------------------------------------------------

function BrainrotCatalog.GetCharacterById(characterId)
	for _, character in ipairs(BrainrotCatalog.Characters) do
		if character.Id == characterId then
			return character
		end
	end
	return nil
end

function BrainrotCatalog.GetRarityInfo(rarityName)
	return BrainrotCatalog.Rarities[rarityName]
end

function BrainrotCatalog.GetRarityColor(rarityName)
	local info = BrainrotCatalog.Rarities[rarityName]
	if info then
		return info.Color
	end
	return Color3.fromRGB(255, 255, 255)
end

function BrainrotCatalog.GetMutationMultiplier(mutationName)
	local mutation = BrainrotCatalog.Mutations[mutationName]
	if mutation then
		return mutation.Multiplier
	end
	return 1
end

function BrainrotCatalog.GetMutationColor(mutationName)
	local mutation = BrainrotCatalog.Mutations[mutationName]
	if mutation then
		return mutation.Color
	end
	return Color3.fromRGB(255, 255, 255)
end

-- Money per second for one brainrot before the rebirth multiplier.
function BrainrotCatalog.GetIncomePerSecond(character, mutationName)
	return math.floor(character.IncomePerSecond * BrainrotCatalog.GetMutationMultiplier(mutationName))
end

-- Weighted rarity roll: Common 45, Rare 25, Epic 15, Legendary 9, Mythic 5, Secret 1.
function BrainrotCatalog.RollRarity()
	local totalWeight = 0
	for _, rarityName in ipairs(BrainrotCatalog.RarityOrder) do
		totalWeight = totalWeight + BrainrotCatalog.Rarities[rarityName].Weight
	end
	local roll = math.random(1, totalWeight)
	local running = 0
	for _, rarityName in ipairs(BrainrotCatalog.RarityOrder) do
		running = running + BrainrotCatalog.Rarities[rarityName].Weight
		if roll <= running then
			return rarityName
		end
	end
	return "Common"
end

function BrainrotCatalog.PickRandomCharacterOfRarity(rarityName)
	local pool = {}
	for _, character in ipairs(BrainrotCatalog.Characters) do
		if character.Rarity == rarityName then
			table.insert(pool, character)
		end
	end
	if #pool == 0 then
		return BrainrotCatalog.Characters[1]
	end
	return pool[math.random(1, #pool)]
end

-- Mutation roll: Rainbow 1%, Diamond 3%, Golden 8%, otherwise none.
function BrainrotCatalog.RollMutation()
	local roll = math.random()
	if roll < 0.01 then
		return "Rainbow"
	elseif roll < 0.04 then
		return "Diamond"
	elseif roll < 0.12 then
		return "Golden"
	end
	return "None"
end

-- Display name with the mutation in front, for labels and cards.
function BrainrotCatalog.GetDisplayName(character, mutationName)
	if mutationName and mutationName ~= "None" then
		return mutationName .. " " .. character.Name
	end
	return character.Name
end

-- Cash price of the next extra slot, or nil when the base is already full.
function BrainrotCatalog.GetNextSlotCost(slotsBought)
	return BrainrotCatalog.SlotCosts[slotsBought + 1]
end

return BrainrotCatalog
