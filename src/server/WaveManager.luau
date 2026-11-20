-- WaveManager: the rotating sambal tsunami and chili-rain plaza events.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local WaveManager = {}

local WAVE_START_X = -170
local WAVE_END_X = 170
local WAVE_SPEED = 45

local remotes = nil
local map = nil
local chiliFolder = nil
local initialized = false

local function showBannerToAll(text)
	if not remotes or not remotes.ShowBanner then
		return
	end
	for _, player in ipairs(Players:GetPlayers()) do
		remotes.ShowBanner:FireClient(player, text)
	end
end

local function showMessage(player, text)
	if remotes and remotes.ShowMessage then
		remotes.ShowMessage:FireClient(player, text)
	end
end

local function sweepWaveAcrossPlaza()
	local wavePart = map.WavePart
	if not wavePart then
		return
	end
	local duration = (WAVE_END_X - WAVE_START_X) / WAVE_SPEED
	local steps = math.max(1, math.floor(duration / 0.05))
	for step = 0, steps do
		local alpha = step / steps
		local x = WAVE_START_X + (WAVE_END_X - WAVE_START_X) * alpha
		wavePart.CFrame = CFrame.new(Vector3.new(x, 15, 0))
		task.wait(0.05)
	end
	wavePart.CFrame = CFrame.new(Vector3.new(-170, -20, 0))
end

local function pushPlayersOutsideBasesBackToSpawn()
	local spawnPosition = map.SpawnPosition or Vector3.new(0, 4, 18)
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if character then
			local root = character:FindFirstChild("HumanoidRootPart")
			if root and not BaseManager.IsPositionInsideOwnBase(player, root.Position) then
				character:PivotTo(CFrame.new(spawnPosition))
			end
		end
	end
end

local function runSambalTsunami()
	showBannerToAll("SAMBAL TSUNAMI INCOMING")
	task.wait(BrainrotCatalog.WaveWarningSeconds)
	sweepWaveAcrossPlaza()
	pushPlayersOutsideBasesBackToSpawn()
end

local function ensureChiliFolder()
	if chiliFolder and chiliFolder.Parent then
		return chiliFolder
	end
	chiliFolder = Workspace:FindFirstChild("ChiliRain")
	if not chiliFolder then
		chiliFolder = Instance.new("Folder")
		chiliFolder.Name = "ChiliRain"
		chiliFolder.Parent = Workspace
	end
	return chiliFolder
end

local function spawnChiliPepper()
	local folder = ensureChiliFolder()
	local radius = BrainrotCatalog.PlazaRadius * 0.8
	local x = (math.random() * 2 - 1) * radius
	local z = (math.random() * 2 - 1) * radius
	if math.abs(z) < 8 then
		if z >= 0 then
			z = 9
		else
			z = -9
		end
		z = math.clamp(z, -radius, radius)
	end

	local model = Instance.new("Model")
	model.Name = "Chili"
	model.Parent = folder

	local pepper = Instance.new("Part")
	pepper.Name = "Pepper"
	pepper.Anchored = true
	pepper.CanCollide = false
	pepper.Size = Vector3.new(0.7, 1.4, 0.7)
	pepper.Color = Color3.fromRGB(220, 40, 30)
	pepper.Material = Enum.Material.SmoothPlastic
	pepper.TopSurface = Enum.SurfaceType.Smooth
	pepper.BottomSurface = Enum.SurfaceType.Smooth
	pepper.CFrame = CFrame.new(Vector3.new(x, 35, z))
	pepper.Parent = model
	model.PrimaryPart = pepper

	local stem = Instance.new("Part")
	stem.Name = "Stem"
	stem.Anchored = true
	stem.CanCollide = false
	stem.Size = Vector3.new(0.25, 0.4, 0.25)
	stem.Color = Color3.fromRGB(80, 180, 70)
	stem.Material = Enum.Material.Grass
	stem.CFrame = CFrame.new(Vector3.new(x, 35.85, z))
	stem.Parent = model

	model.WorldPivot = CFrame.new(Vector3.new(x, 35, z))

	task.spawn(function()
		local y = 35
		while y > 1.2 and model.Parent do
			task.wait(0.05)
			y -= 28 * 0.05
			if y < 1.2 then
				y = 1.2
			end
			model:PivotTo(CFrame.new(Vector3.new(x, y, z)))
		end
		if not model.Parent then
			return
		end

		model.Name = "ChiliPickup"
		local value = math.random(BrainrotCatalog.ChiliPickupValueMin, BrainrotCatalog.ChiliPickupValueMax)
		model:SetAttribute("Value", value)

		local claimed = false
		pepper.Touched:Connect(function(hit)
			if claimed then
				return
			end
			local character = hit.Parent
			local player = character and Players:GetPlayerFromCharacter(character)
			if not player then
				return
			end
			local data = PlayerData.Get(player)
			if not data then
				return
			end
			claimed = true
			data.Cash += value
			PlayerData.Sync(player)
			showMessage(player, "+$" .. tostring(value) .. " chili bonus!")
			if model.Parent then
				model:Destroy()
			end
		end)

		task.delay(BrainrotCatalog.ChiliPickupLifetimeSeconds, function()
			if model.Parent then
				model:Destroy()
			end
		end)
	end)
end

local function runChiliRain()
	showBannerToAll("CHILI RAIN! GRAB THE PEPPERS!")
	task.wait(BrainrotCatalog.WaveWarningSeconds)

	local elapsed = 0
	while elapsed < BrainrotCatalog.ChiliRainDurationSeconds do
		spawnChiliPepper()
		task.wait(0.7)
		elapsed += 0.7
	end
end

function WaveManager.Init(remoteFolder, worldMap)
	if initialized then
		return
	end
	initialized = true
	remotes = remoteFolder
	map = worldMap
	ensureChiliFolder()

	task.spawn(function()
		while true do
			task.wait(BrainrotCatalog.EventIntervalSeconds)
			runSambalTsunami()
			task.wait(BrainrotCatalog.EventIntervalSeconds)
			runChiliRain()
		end
	end)
end

return WaveManager
