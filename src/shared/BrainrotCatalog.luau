-- BrainrotCatalog: every tuning number, rarity, mutation and brainrot in one place.

local BrainrotCatalog = {}

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
BrainrotCatalog.IndexMilestones = { 13, 26, 39, 52 }
BrainrotCatalog.IndexMilestoneRewards = { 25000, 100000, 400000, 2000000 }

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

BrainrotCatalog.Mutations = {
	None = { Name = "None", Multiplier = 1, Color = Color3.fromRGB(255, 255, 255) },
	Golden = { Name = "Golden", Multiplier = 2, Color = Color3.fromRGB(255, 215, 0) },
	Candy = { Name = "Candy", Multiplier = 3, Color = Color3.fromRGB(255, 150, 200) },
	Diamond = { Name = "Diamond", Multiplier = 5, Color = Color3.fromRGB(140, 230, 255) },
	Crystal = { Name = "Crystal", Multiplier = 8, Color = Color3.fromRGB(160, 240, 235) },
	Rainbow = { Name = "Rainbow", Multiplier = 10, Color = Color3.fromRGB(255, 100, 220) },
	Galaxy = { Name = "Galaxy", Multiplier = 15, Color = Color3.fromRGB(120, 80, 255) },
	Void = { Name = "Void", Multiplier = 25, Color = Color3.fromRGB(40, 30, 60) },
}

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
		Blurb = "A banana with a phone plan older than the bazaar itself.",
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
		Id = "NoodleNewt",
		Name = "Noodle Newt",
		Rarity = "Common",
		Cost = 200,
		IncomePerSecond = 16,
		BodyColor = Color3.fromRGB(240, 200, 120),
		AccentColor = Color3.fromRGB(90, 160, 90),
		Feature = "Antenna",
		Blurb = "A newt tangled in noodles. It has accepted this.",
	},
	{
		Id = "PicklePigeon",
		Name = "Pickle Pigeon",
		Rarity = "Common",
		Cost = 260,
		IncomePerSecond = 19,
		BodyColor = Color3.fromRGB(120, 180, 90),
		AccentColor = Color3.fromRGB(60, 120, 60),
		Feature = "TopHat",
		Blurb = "Coos exclusively in brine. Owns one tiny hat.",
	},
	{
		Id = "MuffinMouse",
		Name = "Muffin Mouse",
		Rarity = "Common",
		Cost = 420,
		IncomePerSecond = 28,
		BodyColor = Color3.fromRGB(190, 140, 90),
		AccentColor = Color3.fromRGB(255, 120, 160),
		Feature = "Mushroom",
		Blurb = "Lives in a muffin. Pays no rent. Eats the walls.",
	},
	{
		Id = "GravyGoat",
		Name = "Gravy Goat",
		Rarity = "Common",
		Cost = 520,
		IncomePerSecond = 33,
		BodyColor = Color3.fromRGB(200, 180, 160),
		AccentColor = Color3.fromRGB(120, 80, 40),
		Feature = "Umbrella",
		Blurb = "Bleats gravy. Nobody questions it anymore.",
	},
	{
		Id = "PancakePig",
		Name = "Pancake Pig",
		Rarity = "Common",
		Cost = 650,
		IncomePerSecond = 40,
		BodyColor = Color3.fromRGB(255, 180, 190),
		AccentColor = Color3.fromRGB(240, 200, 110),
		Feature = "IceCream",
		Blurb = "Flat, round, and dripping with syrup and confidence.",
	},
	{
		Id = "TurnipTurtle",
		Name = "Turnip Turtle",
		Rarity = "Common",
		Cost = 800,
		IncomePerSecond = 48,
		BodyColor = Color3.fromRGB(150, 200, 120),
		AccentColor = Color3.fromRGB(240, 240, 230),
		Feature = "Mushroom",
		Blurb = "Slow because the turnip is heavy, not because it is a turtle.",
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
		Id = "SalsaSloth",
		Name = "Salsa Sloth",
		Rarity = "Rare",
		Cost = 1600,
		IncomePerSecond = 55,
		BodyColor = Color3.fromRGB(160, 110, 70),
		AccentColor = Color3.fromRGB(220, 60, 40),
		Feature = "Headphones",
		Blurb = "Dances at 0.25x speed. The salsa is full strength.",
	},
	{
		Id = "BurritoBat",
		Name = "Burrito Bat",
		Rarity = "Rare",
		Cost = 2000,
		IncomePerSecond = 65,
		BodyColor = Color3.fromRGB(120, 90, 140),
		AccentColor = Color3.fromRGB(240, 210, 140),
		Feature = "Umbrella",
		Blurb = "Sleeps wrapped. Wakes up hungry. It is the burrito.",
	},
	{
		Id = "KimchiKoi",
		Name = "Kimchi Koi",
		Rarity = "Rare",
		Cost = 3200,
		IncomePerSecond = 90,
		BodyColor = Color3.fromRGB(255, 120, 60),
		AccentColor = Color3.fromRGB(255, 255, 255),
		Feature = "Antenna",
		Blurb = "Swims upstream through pure spice.",
	},
	{
		Id = "PretzelPanda",
		Name = "Pretzel Panda",
		Rarity = "Rare",
		Cost = 4000,
		IncomePerSecond = 105,
		BodyColor = Color3.fromRGB(245, 245, 245),
		AccentColor = Color3.fromRGB(160, 100, 50),
		Feature = "Glasses",
		Blurb = "Twisted, salted, and serenely unbothered.",
	},
	{
		Id = "RavioliRaccoon",
		Name = "Ravioli Raccoon",
		Rarity = "Rare",
		Cost = 5200,
		IncomePerSecond = 125,
		BodyColor = Color3.fromRGB(150, 150, 160),
		AccentColor = Color3.fromRGB(240, 200, 120),
		Feature = "Sword",
		Blurb = "Washes its ravioli before eating. A tiny gentleman thief.",
	},
	{
		Id = "TofuTiger",
		Name = "Tofu Tiger",
		Rarity = "Rare",
		Cost = 6500,
		IncomePerSecond = 145,
		BodyColor = Color3.fromRGB(250, 245, 235),
		AccentColor = Color3.fromRGB(255, 150, 60),
		Feature = "TopHat",
		Blurb = "Soft on the outside. Still a tiger.",
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
		Id = "LasagnaLlama",
		Name = "Lasagna Llama",
		Rarity = "Epic",
		Cost = 11000,
		IncomePerSecond = 210,
		BodyColor = Color3.fromRGB(240, 170, 80),
		AccentColor = Color3.fromRGB(200, 60, 40),
		Feature = "CaptainHat",
		Blurb = "Layers upon layers. Do not reheat the llama.",
	},
	{
		Id = "ChiliCheetah",
		Name = "Chili Cheetah",
		Rarity = "Epic",
		Cost = 20000,
		IncomePerSecond = 340,
		BodyColor = Color3.fromRGB(255, 90, 50),
		AccentColor = Color3.fromRGB(255, 200, 60),
		Feature = "Rocket",
		Blurb = "The fastest land animal, now with afterburners.",
	},
	{
		Id = "FondueFox",
		Name = "Fondue Fox",
		Rarity = "Epic",
		Cost = 26000,
		IncomePerSecond = 420,
		BodyColor = Color3.fromRGB(255, 160, 70),
		AccentColor = Color3.fromRGB(255, 240, 200),
		Feature = "Umbrella",
		Blurb = "Dips everything it owns in cheese. Everything.",
	},
	{
		Id = "BobaBear",
		Name = "Boba Bear",
		Rarity = "Epic",
		Cost = 34000,
		IncomePerSecond = 520,
		BodyColor = Color3.fromRGB(180, 130, 90),
		AccentColor = Color3.fromRGB(60, 50, 50),
		Feature = "Bubblegum",
		Blurb = "Half bear, half bubble tea, entirely huggable.",
	},
	{
		Id = "CurryCobra",
		Name = "Curry Cobra",
		Rarity = "Epic",
		Cost = 45000,
		IncomePerSecond = 660,
		BodyColor = Color3.fromRGB(230, 150, 40),
		AccentColor = Color3.fromRGB(120, 200, 90),
		Feature = "Crown",
		Blurb = "Hood up. Spice level: legendary. Approach with rice.",
	},
	{
		Id = "TempuraToucan",
		Name = "Tempura Toucan",
		Rarity = "Epic",
		Cost = 58000,
		IncomePerSecond = 820,
		BodyColor = Color3.fromRGB(240, 200, 120),
		AccentColor = Color3.fromRGB(255, 110, 60),
		Feature = "IceCream",
		Blurb = "Lightly battered, deeply tropical.",
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
		Id = "SushiShogun",
		Name = "Sushi Shogun",
		Rarity = "Legendary",
		Cost = 120000,
		IncomePerSecond = 1400,
		BodyColor = Color3.fromRGB(250, 240, 235),
		AccentColor = Color3.fromRGB(230, 80, 80),
		Feature = "Sword",
		Blurb = "Rules the rice provinces with an iron chopstick.",
	},
	{
		Id = "TruffleTriceratops",
		Name = "Truffle Triceratops",
		Rarity = "Legendary",
		Cost = 160000,
		IncomePerSecond = 1800,
		BodyColor = Color3.fromRGB(140, 120, 110),
		AccentColor = Color3.fromRGB(90, 70, 60),
		Feature = "Mushroom",
		Blurb = "Sniffs out truffles. Is also, partly, a truffle.",
	},
	{
		Id = "MacaronMammoth",
		Name = "Macaron Mammoth",
		Rarity = "Legendary",
		Cost = 220000,
		IncomePerSecond = 2300,
		BodyColor = Color3.fromRGB(255, 190, 220),
		AccentColor = Color3.fromRGB(170, 230, 200),
		Feature = "TopHat",
		Blurb = "Extinct? No. Just very, very fancy now.",
	},
	{
		Id = "CaviarCentaur",
		Name = "Caviar Centaur",
		Rarity = "Legendary",
		Cost = 300000,
		IncomePerSecond = 2900,
		BodyColor = Color3.fromRGB(120, 110, 140),
		AccentColor = Color3.fromRGB(40, 40, 50),
		Feature = "Glasses",
		Blurb = "Half horse, half high society, all expensive eggs.",
	},
	{
		Id = "SaffronScorpion",
		Name = "Saffron Scorpion",
		Rarity = "Legendary",
		Cost = 380000,
		IncomePerSecond = 3600,
		BodyColor = Color3.fromRGB(255, 180, 40),
		AccentColor = Color3.fromRGB(200, 120, 20),
		Feature = "Antenna",
		Blurb = "The world's most expensive sting.",
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
		Id = "NebulaNarwhal",
		Name = "Nebula Narwhal",
		Rarity = "Mythic",
		Cost = 600000,
		IncomePerSecond = 6200,
		BodyColor = Color3.fromRGB(110, 90, 200),
		AccentColor = Color3.fromRGB(120, 230, 255),
		Feature = "Orb",
		Blurb = "Its horn is a comet that never left.",
	},
	{
		Id = "EclipseEmu",
		Name = "Eclipse Emu",
		Rarity = "Mythic",
		Cost = 800000,
		IncomePerSecond = 8000,
		BodyColor = Color3.fromRGB(70, 70, 90),
		AccentColor = Color3.fromRGB(255, 170, 60),
		Feature = "Moon",
		Blurb = "Stares at the sun until the sun blinks first.",
	},
	{
		Id = "AuroraAxolotl",
		Name = "Aurora Axolotl",
		Rarity = "Mythic",
		Cost = 1100000,
		IncomePerSecond = 10500,
		BodyColor = Color3.fromRGB(255, 170, 210),
		AccentColor = Color3.fromRGB(120, 255, 200),
		Feature = "Antenna",
		Blurb = "Glows with the northern lights and zero worries.",
	},
	{
		Id = "CometCapybara",
		Name = "Comet Capybara",
		Rarity = "Mythic",
		Cost = 1400000,
		IncomePerSecond = 13000,
		BodyColor = Color3.fromRGB(170, 130, 90),
		AccentColor = Color3.fromRGB(255, 140, 60),
		Feature = "Rocket",
		Blurb = "The chillest object in the solar system.",
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
	{
		Id = "TheLastSlice",
		Name = "The Last Slice",
		Rarity = "Secret",
		Cost = 3200000,
		IncomePerSecond = 21000,
		BodyColor = Color3.fromRGB(255, 200, 110),
		AccentColor = Color3.fromRGB(220, 70, 60),
		Feature = "Crown",
		Blurb = "Every pizza box in the world whispers about it.",
	},
	{
		Id = "MidnightMeatball",
		Name = "Midnight Meatball",
		Rarity = "Secret",
		Cost = 4000000,
		IncomePerSecond = 25000,
		BodyColor = Color3.fromRGB(110, 70, 60),
		AccentColor = Color3.fromRGB(200, 200, 255),
		Feature = "Moon",
		Blurb = "It rolls only when nobody is watching. Mostly.",
	},
	{
		Id = "OmegaNoodleDragon",
		Name = "Omega Noodle Dragon",
		Rarity = "Divine",
		Cost = 6000000,
		IncomePerSecond = 45000,
		BodyColor = Color3.fromRGB(255, 230, 150),
		AccentColor = Color3.fromRGB(255, 90, 90),
		Feature = "Crown",
		Blurb = "The final noodle. The first dragon. Both, somehow.",
	},
	{
		Id = "TheGoldenGobbler",
		Name = "The Golden Gobbler",
		Rarity = "Divine",
		Cost = 10000000,
		IncomePerSecond = 70000,
		BodyColor = Color3.fromRGB(255, 215, 0),
		AccentColor = Color3.fromRGB(255, 255, 255),
		Feature = "TopHat",
		Blurb = "A turkey cast from pure gold and pure gratitude.",
	},
	{
		Id = "ChefOfTheCosmos",
		Name = "Chef of the Cosmos",
		Rarity = "Divine",
		Cost = 18000000,
		IncomePerSecond = 120000,
		BodyColor = Color3.fromRGB(240, 240, 255),
		AccentColor = Color3.fromRGB(150, 120, 255),
		Feature = "CaptainHat",
		Blurb = "Seasons stars. Tastes galaxies. Never oversalts.",
	},
	{
		Id = "WasabiWalrus",
		Name = "Wasabi Walrus",
		Rarity = "Rare",
		Cost = 7500,
		IncomePerSecond = 155,
		BodyColor = Color3.fromRGB(170, 200, 170),
		AccentColor = Color3.fromRGB(90, 180, 90),
		Feature = "Antenna",
		Blurb = "Clears sinuses across three time zones.",
	},
	{
		Id = "GnocchiGnome",
		Name = "Gnocchi Gnome",
		Rarity = "Rare",
		Cost = 9000,
		IncomePerSecond = 175,
		BodyColor = Color3.fromRGB(240, 220, 170),
		AccentColor = Color3.fromRGB(200, 60, 60),
		Feature = "TopHat",
		Blurb = "Guards the garden. And the dumplings.",
	},
	{
		Id = "SrirachaSquid",
		Name = "Sriracha Squid",
		Rarity = "Epic",
		Cost = 70000,
		IncomePerSecond = 980,
		BodyColor = Color3.fromRGB(255, 80, 60),
		AccentColor = Color3.fromRGB(255, 240, 220),
		Feature = "Rocket",
		Blurb = "Eight arms, all of them spicy.",
	},
	{
		Id = "PavlovaPeacock",
		Name = "Pavlova Peacock",
		Rarity = "Epic",
		Cost = 85000,
		IncomePerSecond = 1150,
		BodyColor = Color3.fromRGB(120, 200, 220),
		AccentColor = Color3.fromRGB(255, 170, 220),
		Feature = "Crown",
		Blurb = "Struts in meringue. Judges everyone.",
	},
	{
		Id = "BaklavaBehemoth",
		Name = "Baklava Behemoth",
		Rarity = "Legendary",
		Cost = 450000,
		IncomePerSecond = 4200,
		BodyColor = Color3.fromRGB(220, 170, 90),
		AccentColor = Color3.fromRGB(150, 100, 40),
		Feature = "Waffle",
		Blurb = "Ninety-nine layers and counting.",
	},
	{
		Id = "TiramisuTitan",
		Name = "Tiramisu Titan",
		Rarity = "Legendary",
		Cost = 550000,
		IncomePerSecond = 5000,
		BodyColor = Color3.fromRGB(120, 85, 60),
		AccentColor = Color3.fromRGB(245, 235, 220),
		Feature = "Crown",
		Blurb = "Picks up entire cafes. Gently.",
	},
	{
		Id = "SingularitySundae",
		Name = "Singularity Sundae",
		Rarity = "Mythic",
		Cost = 1800000,
		IncomePerSecond = 16000,
		BodyColor = Color3.fromRGB(60, 50, 90),
		AccentColor = Color3.fromRGB(255, 200, 240),
		Feature = "Orb",
		Blurb = "A dessert with its own event horizon.",
	},
	{
		Id = "TheFirstBite",
		Name = "The First Bite",
		Rarity = "Secret",
		Cost = 5000000,
		IncomePerSecond = 30000,
		BodyColor = Color3.fromRGB(255, 240, 200),
		AccentColor = Color3.fromRGB(255, 120, 120),
		Feature = "Bagel",
		Blurb = "Before the bazaar, before the belt — there was a bite.",
	},
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

function GetCharacterById(characterId)
	for _, character in ipairs(BrainrotCatalog.Characters) do
		if character.Id == characterId then
			return character
		end
	end
	return nil
end

function BrainrotCatalog.GetCharacterById(characterId)
	return GetCharacterById(characterId)
end

function BrainrotCatalog.GetRarityInfo(rarityName)
	return BrainrotCatalog.Rarities[rarityName]
end

function BrainrotCatalog.GetRarityColor(rarityName)
	local rarity = BrainrotCatalog.Rarities[rarityName]
	if rarity then
		return rarity.Color
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

function BrainrotCatalog.GetIncomePerSecond(character, mutationName)
	return math.floor(character.IncomePerSecond * BrainrotCatalog.GetMutationMultiplier(mutationName))
end

function BrainrotCatalog.RollRarity()
	local totalWeight = 0
	for _, rarityName in ipairs(BrainrotCatalog.RarityOrder) do
		totalWeight += BrainrotCatalog.Rarities[rarityName].Weight
	end
	local roll = math.random() * totalWeight
	local running = 0
	for _, rarityName in ipairs(BrainrotCatalog.RarityOrder) do
		running += BrainrotCatalog.Rarities[rarityName].Weight
		if roll < running then
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

function BrainrotCatalog.RollMutation()
	local r = math.random()
	if r < 0.002 then
		return "Void"
	elseif r < 0.007 then
		return "Galaxy"
	elseif r < 0.017 then
		return "Rainbow"
	elseif r < 0.032 then
		return "Crystal"
	elseif r < 0.062 then
		return "Diamond"
	elseif r < 0.122 then
		return "Candy"
	elseif r < 0.202 then
		return "Golden"
	end
	return "None"
end

function BrainrotCatalog.GetDisplayName(character, mutationName)
	if mutationName and mutationName ~= "None" then
		return mutationName .. " " .. character.Name
	end
	return character.Name
end

function BrainrotCatalog.GetNextSlotCost(slotsBought)
	return BrainrotCatalog.SlotCosts[slotsBought + 1]
end

function BrainrotCatalog.GetNextIndexMilestone(indexCount, milestonesClaimed)
	if milestonesClaimed >= #BrainrotCatalog.IndexMilestones then
		return nil
	end
	return {
		Count = BrainrotCatalog.IndexMilestones[milestonesClaimed + 1],
		Reward = BrainrotCatalog.IndexMilestoneRewards[milestonesClaimed + 1],
	}
end

return BrainrotCatalog
