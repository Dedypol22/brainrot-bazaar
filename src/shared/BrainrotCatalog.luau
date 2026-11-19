-- BrainrotCatalog.luau
-- Shared data for Brainrot Bazaar: tuning, rarities, mutations and the
-- full roster of 44 brainrots, plus small pure helpers used everywhere.

local BrainrotCatalog = {}

-- Tuning -----------------------------------------------------------------

BrainrotCatalog.StartingCash = 500
BrainrotCatalog.BaseSlotCount = 4
BrainrotCatalog.MaxSlotCount = 10
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
BrainrotCatalog.EventIntervalSeconds = 150
BrainrotCatalog.WaveWarningSeconds = 10
BrainrotCatalog.RebirthCashThreshold = 1000000
BrainrotCatalog.RebirthIncomeBonus = 0.25
BrainrotCatalog.AutosaveIntervalSeconds = 60
BrainrotCatalog.PlazaRadius = 45
BrainrotCatalog.PlotRowZ = 34
BrainrotCatalog.PlotRowX = { -57, -19, 19, 57 }
BrainrotCatalog.PlotCount = 8
BrainrotCatalog.ThiefIntervalSeconds = 75
BrainrotCatalog.ThiefSpeedStudsPerSecond = 10
BrainrotCatalog.ThiefRewardCash = 250
BrainrotCatalog.StealShieldSeconds = 30
BrainrotCatalog.ChiliRainDurationSeconds = 10
BrainrotCatalog.ChiliPickupValueMin = 100
BrainrotCatalog.ChiliPickupValueMax = 500
BrainrotCatalog.ChiliPickupLifetimeSeconds = 25
BrainrotCatalog.IndexMilestones = { 11, 22, 33, 44 }
BrainrotCatalog.IndexMilestoneRewards = { 25000, 100000, 400000, 2000000 }

-- Rarities ---------------------------------------------------------------

BrainrotCatalog.Rarities = {
	Common = { Name = "Common", Color = Color3.fromRGB(170, 170, 170), Weight = 45, Order = 1 },
	Rare = { Name = "Rare", Color = Color3.fromRGB(70, 130, 255), Weight = 25, Order = 2 },
	Epic = { Name = "Epic", Color = Color3.fromRGB(170, 80, 255), Weight = 15, Order = 3 },
	Legendary = { Name = "Legendary", Color = Color3.fromRGB(255, 200, 40), Weight = 9, Order = 4 },
	Mythic = { Name = "Mythic", Color = Color3.fromRGB(255, 60, 60), Weight = 4.4, Order = 5 },
	Secret = { Name = "Secret", Color = Color3.fromRGB(255, 80, 200), Weight = 1.2, Order = 6 },
	Divine = { Name = "Divine", Color = Color3.fromRGB(255, 235, 150), Weight = 0.4, Order = 7 },
}

BrainrotCatalog.RarityOrder = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Divine" }

-- Mutations --------------------------------------------------------------

BrainrotCatalog.Mutations = {
	None = { Name = "None", Multiplier = 1, Color = Color3.fromRGB(255, 255, 255) },
	Golden = { Name = "Golden", Multiplier = 2, Color = Color3.fromRGB(255, 215, 0) },
	Candy = { Name = "Candy", Multiplier = 3, Color = Color3.fromRGB(255, 150, 200) },
	Diamond = { Name = "Diamond", Multiplier = 5, Color = Color3.fromRGB(140, 230, 255) },
	Rainbow = { Name = "Rainbow", Multiplier = 10, Color = Color3.fromRGB(255, 100, 220) },
	Galaxy = { Name = "Galaxy", Multiplier = 15, Color = Color3.fromRGB(120, 80, 255) },
	Void = { Name = "Void", Multiplier = 25, Color = Color3.fromRGB(40, 30, 60) },
}

-- Characters -------------------------------------------------------------

local function character(id, name, rarity, cost, income, body, accent, feature, blurb)
	return {
		Id = id,
		Name = name,
		Rarity = rarity,
		Cost = cost,
		IncomePerSecond = income,
		BodyColor = body,
		AccentColor = accent,
		Feature = feature,
		Blurb = blurb,
	}
end

BrainrotCatalog.Characters = {
	character("BananaphoneBarry", "Bananaphone Barry", "Common", 150, 12, Color3.fromRGB(255, 220, 60), Color3.fromRGB(120, 70, 20), "Phone", "A banana holding a phone, always on a call. It is never Barry anyone is calling for, and Barry never hangs up first."),
	character("SirFriesALot", "Sir Fries-A-Lot", "Common", 350, 24, Color3.fromRGB(220, 60, 50), Color3.fromRGB(255, 210, 60), "Sword", "A french-fries knight sworn to protect the ketchup. He has dueled three salt shakers and won every time."),
	character("NoodleNewt", "Noodle Newt", "Common", 200, 16, Color3.fromRGB(240, 200, 120), Color3.fromRGB(90, 160, 90), "Antenna", "A newt tangled in noodles. It has accepted this. The noodles, frankly, have accepted the newt too."),
	character("PicklePigeon", "Pickle Pigeon", "Common", 260, 19, Color3.fromRGB(120, 180, 90), Color3.fromRGB(60, 120, 60), "TopHat", "Coos exclusively in brine. Owns one tiny hat."),
	character("MuffinMouse", "Muffin Mouse", "Common", 420, 28, Color3.fromRGB(190, 140, 90), Color3.fromRGB(255, 120, 160), "Mushroom", "Lives in a muffin. Pays no rent. Eats the walls."),
	character("GravyGoat", "Gravy Goat", "Common", 520, 33, Color3.fromRGB(200, 180, 160), Color3.fromRGB(120, 80, 40), "Umbrella", "Bleats gravy. Nobody questions it anymore."),
	character("PancakePig", "Pancake Pig", "Common", 650, 40, Color3.fromRGB(255, 180, 190), Color3.fromRGB(240, 200, 110), "IceCream", "Flat, round, and dripping with syrup and confidence."),
	character("TurnipTurtle", "Turnip Turtle", "Common", 800, 48, Color3.fromRGB(150, 200, 120), Color3.fromRGB(240, 240, 230), "Mushroom", "Slow because the turnip is heavy, not because it is a turtle."),
	character("DJToastShark", "DJ Toast Shark", "Rare", 1200, 45, Color3.fromRGB(90, 130, 200), Color3.fromRGB(255, 140, 40), "Headphones", "A shark that drops beats instead of dropping crumbs."),
	character("CaptainCroissant", "Captain Croissant", "Rare", 2500, 75, Color3.fromRGB(230, 180, 90), Color3.fromRGB(255, 255, 255), "CaptainHat", "Sails the butter seas in search of flaky treasure."),
	character("SalsaSloth", "Salsa Sloth", "Rare", 1600, 55, Color3.fromRGB(160, 110, 70), Color3.fromRGB(220, 60, 40), "Headphones", "Dances at 0.25x speed. The salsa is full strength."),
	character("BurritoBat", "Burrito Bat", "Rare", 2000, 65, Color3.fromRGB(120, 90, 140), Color3.fromRGB(240, 210, 140), "Umbrella", "Sleeps wrapped. Wakes up hungry. It is the burrito."),
	character("KimchiKoi", "Kimchi Koi", "Rare", 3200, 90, Color3.fromRGB(255, 120, 60), Color3.fromRGB(255, 255, 255), "Antenna", "Swims upstream through pure spice."),
	character("PretzelPanda", "Pretzel Panda", "Rare", 4000, 105, Color3.fromRGB(245, 245, 245), Color3.fromRGB(160, 100, 50), "Glasses", "Twisted, salted, and serenely unbothered."),
	character("RavioliRaccoon", "Ravioli Raccoon", "Rare", 5200, 125, Color3.fromRGB(150, 150, 160), Color3.fromRGB(240, 200, 120), "Sword", "Washes its ravioli before eating. A tiny gentleman thief."),
	character("TofuTiger", "Tofu Tiger", "Rare", 6500, 145, Color3.fromRGB(250, 245, 235), Color3.fromRGB(255, 150, 60), "TopHat", "Soft on the outside. Still a tiger."),
	character("BubblegumYeti", "Bubblegum Yeti", "Epic", 8000, 160, Color3.fromRGB(240, 240, 245), Color3.fromRGB(255, 120, 180), "Bubblegum", "A yeti that blows bubbles big enough to live in."),
	character("TurboToiletTRex", "Turbo Toilet T-Rex", "Epic", 15000, 280, Color3.fromRGB(80, 180, 90), Color3.fromRGB(250, 250, 250), "Toilet", "A tiny-armed T-Rex with a turbocharged throne."),
	character("LasagnaLlama", "Lasagna Llama", "Epic", 11000, 210, Color3.fromRGB(240, 170, 80), Color3.fromRGB(200, 60, 40), "CaptainHat", "Layers upon layers. Do not reheat the llama."),
	character("ChiliCheetah", "Chili Cheetah", "Epic", 20000, 340, Color3.fromRGB(255, 90, 50), Color3.fromRGB(255, 200, 60), "Rocket", "The fastest land animal, now with afterburners."),
	character("FondueFox", "Fondue Fox", "Epic", 26000, 420, Color3.fromRGB(255, 160, 70), Color3.fromRGB(255, 240, 200), "Umbrella", "Dips everything it owns in cheese. Everything."),
	character("BobaBear", "Boba Bear", "Epic", 34000, 520, Color3.fromRGB(180, 130, 90), Color3.fromRGB(60, 50, 50), "Bubblegum", "Half bear, half bubble tea, entirely huggable."),
	character("CurryCobra", "Curry Cobra", "Epic", 45000, 660, Color3.fromRGB(230, 150, 40), Color3.fromRGB(120, 200, 90), "Crown", "Hood up. Spice level: legendary. Approach with rice."),
	character("TempuraToucan", "Tempura Toucan", "Epic", 58000, 820, Color3.fromRGB(240, 200, 120), Color3.fromRGB(255, 110, 60), "IceCream", "Lightly battered, deeply tropical."),
	character("GoldenSpaghettiSphinx", "Golden Spaghetti Sphinx", "Legendary", 50000, 650, Color3.fromRGB(255, 210, 60), Color3.fromRGB(200, 40, 40), "Crown", "Asks riddles in noodle form. Nobody has answered one."),
	character("ProfessorPicklephant", "Professor Picklephant", "Legendary", 90000, 1100, Color3.fromRGB(90, 160, 70), Color3.fromRGB(140, 90, 200), "Glasses", "An elephant pickled in knowledge. Tenured in brine."),
	character("SushiShogun", "Sushi Shogun", "Legendary", 120000, 1400, Color3.fromRGB(250, 240, 235), Color3.fromRGB(230, 80, 80), "Sword", "Rules the rice provinces with an iron chopstick."),
	character("TruffleTriceratops", "Truffle Triceratops", "Legendary", 160000, 1800, Color3.fromRGB(140, 120, 110), Color3.fromRGB(90, 70, 60), "Mushroom", "Sniffs out truffles. Is also, partly, a truffle."),
	character("MacaronMammoth", "Macaron Mammoth", "Legendary", 220000, 2300, Color3.fromRGB(255, 190, 220), Color3.fromRGB(170, 230, 200), "TopHat", "Extinct? No. Just very, very fancy now."),
	character("CaviarCentaur", "Caviar Centaur", "Legendary", 300000, 2900, Color3.fromRGB(120, 110, 140), Color3.fromRGB(40, 40, 50), "Glasses", "Half horse, half high society, all expensive eggs."),
	character("SaffronScorpion", "Saffron Scorpion", "Legendary", 380000, 3600, Color3.fromRGB(255, 180, 40), Color3.fromRGB(200, 120, 20), "Antenna", "The world's most expensive sting."),
	character("MoonCheeseMoose", "Moon Cheese Moose", "Mythic", 250000, 2600, Color3.fromRGB(240, 230, 160), Color3.fromRGB(120, 120, 130), "Moon", "A moose made of moon cheese. The moon denies everything."),
	character("QuantumQuokka", "Quantum Quokka", "Mythic", 450000, 4800, Color3.fromRGB(150, 100, 60), Color3.fromRGB(80, 220, 255), "Orb", "Happy in two places at once. Mostly."),
	character("NebulaNarwhal", "Nebula Narwhal", "Mythic", 600000, 6200, Color3.fromRGB(110, 90, 200), Color3.fromRGB(120, 230, 255), "Orb", "Its horn is a comet that never left."),
	character("EclipseEmu", "Eclipse Emu", "Mythic", 800000, 8000, Color3.fromRGB(70, 70, 90), Color3.fromRGB(255, 170, 60), "Moon", "Stares at the sun until the sun blinks first."),
	character("AuroraAxolotl", "Aurora Axolotl", "Mythic", 1100000, 10500, Color3.fromRGB(255, 170, 210), Color3.fromRGB(120, 255, 200), "Antenna", "Glows with the northern lights and zero worries."),
	character("CometCapybara", "Comet Capybara", "Mythic", 1400000, 13000, Color3.fromRGB(170, 130, 90), Color3.fromRGB(255, 140, 60), "Rocket", "The chillest object in the solar system."),
	character("TheInfiniteBagel", "The Infinite Bagel", "Secret", 1500000, 15000, Color3.fromRGB(210, 160, 90), Color3.fromRGB(120, 70, 30), "Bagel", "A bagel with no beginning and no end. Still warm."),
	character("BaronVonWafflefish", "Baron Von Wafflefish", "Secret", 2500000, 17000, Color3.fromRGB(200, 140, 50), Color3.fromRGB(90, 50, 20), "Waffle", "A fish of noble syrup, swimming in maple."),
	character("TheLastSlice", "The Last Slice", "Secret", 3200000, 21000, Color3.fromRGB(255, 200, 110), Color3.fromRGB(220, 70, 60), "Crown", "Every pizza box in the world whispers about it."),
	character("MidnightMeatball", "Midnight Meatball", "Secret", 4000000, 25000, Color3.fromRGB(110, 70, 60), Color3.fromRGB(200, 200, 255), "Moon", "It rolls only when nobody is watching. Mostly."),
	character("OmegaNoodleDragon", "Omega Noodle Dragon", "Divine", 6000000, 45000, Color3.fromRGB(255, 230, 150), Color3.fromRGB(255, 90, 90), "Crown", "The final noodle. The first dragon. Both, somehow."),
	character("TheGoldenGobbler", "The Golden Gobbler", "Divine", 10000000, 70000, Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 255, 255), "TopHat", "A turkey cast from pure gold and pure gratitude."),
	character("ChefOfTheCosmos", "Chef of the Cosmos", "Divine", 18000000, 120000, Color3.fromRGB(240, 240, 255), Color3.fromRGB(150, 120, 255), "CaptainHat", "Seasons stars. Tastes galaxies. Never oversalts."),
}

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

-- Helpers ----------------------------------------------------------------

function BrainrotCatalog.GetCharacterById(characterId)
	for _, entry in ipairs(BrainrotCatalog.Characters) do
		if entry.Id == characterId then
			return entry
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
	local info = BrainrotCatalog.Mutations[mutationName]
	if info then
		return info.Multiplier
	end
	return 1
end

function BrainrotCatalog.GetMutationColor(mutationName)
	local info = BrainrotCatalog.Mutations[mutationName]
	if info then
		return info.Color
	end
	return Color3.fromRGB(255, 255, 255)
end

function BrainrotCatalog.GetIncomePerSecond(characterEntry, mutationName)
	return math.floor(characterEntry.IncomePerSecond * BrainrotCatalog.GetMutationMultiplier(mutationName))
end

function BrainrotCatalog.RollRarity()
	local totalWeight = 0
	for _, rarityName in ipairs(BrainrotCatalog.RarityOrder) do
		totalWeight += BrainrotCatalog.Rarities[rarityName].Weight
	end
	local roll = math.random() * totalWeight
	local walking = 0
	for _, rarityName in ipairs(BrainrotCatalog.RarityOrder) do
		walking += BrainrotCatalog.Rarities[rarityName].Weight
		if roll <= walking then
			return rarityName
		end
	end
	return "Common"
end

function BrainrotCatalog.PickRandomCharacterOfRarity(rarityName)
	local pool = {}
	for _, entry in ipairs(BrainrotCatalog.Characters) do
		if entry.Rarity == rarityName then
			table.insert(pool, entry)
		end
	end
	if #pool == 0 then
		return BrainrotCatalog.Characters[1]
	end
	return pool[math.random(1, #pool)]
end

function BrainrotCatalog.RollMutation()
	local r = math.random()
	if r < 0.002 then
		return "Void"
	elseif r < 0.007 then
		return "Galaxy"
	elseif r < 0.017 then
		return "Rainbow"
	elseif r < 0.047 then
		return "Diamond"
	elseif r < 0.107 then
		return "Candy"
	elseif r < 0.187 then
		return "Golden"
	end
	return "None"
end

function BrainrotCatalog.GetDisplayName(characterEntry, mutationName)
	if mutationName and mutationName ~= "None" and mutationName ~= "" then
		return mutationName .. " " .. characterEntry.Name
	end
	return characterEntry.Name
end

function BrainrotCatalog.GetNextSlotCost(slotsBought)
	return BrainrotCatalog.SlotCosts[slotsBought + 1]
end

function BrainrotCatalog.GetNextIndexMilestone(indexCount, milestonesClaimed)
	if milestonesClaimed >= #BrainrotCatalog.IndexMilestones then
		return nil
	end
	local nextIndex = milestonesClaimed + 1
	return {
		Count = BrainrotCatalog.IndexMilestones[nextIndex],
		Reward = BrainrotCatalog.IndexMilestoneRewards[nextIndex],
	}
end

return BrainrotCatalog
