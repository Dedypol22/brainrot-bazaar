-- WaveManager.luau
-- Rotating plaza events, alternating forever: the sambal tsunami sweeps
-- everyone caught outside a base back to spawn, then chili rain drops
-- cash peppers all over the plaza.

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
local worldMap = nil
local chiliFolder = nil

local function showBannerToAll(message)
	if remotes and remotes.ShowBanner then
		remotes.ShowBanner:FireAllClients(message)
	end
end

local function showMessage(player, message)
	if remotes and remotes.ShowMessage then
		remotes.ShowMessage:FireClient(player, message)
	end
end

local function sweepWaveAcrossPlaza()
	local wavePart = worldMap and worldMap.WavePart
	if not wavePart then
		return
	end
	local distance = WAVE_END_X - WAVE_START_X
	local duration = distance / WAVE_SPEED
	local steps = math.max(1, math.floor(duration / 0.05))
	for step = 0, steps do
		local x = WAVE_START_X + distance * (step / steps)
		wavePart.Position = Vector3.new(x, 8, 0)
		task.wait(0.05)
	end
	wavePart.Position = Vector3.new(-170, -40, 0)
end

local function pushPlayersOutsideBasesBackToSpawn()
	if not worldMap or not worldMap.SpawnPosition then
		return
	end
	for _, player in ipairs(Players:GetPlayers()) do
		local characterModel = player.Character
		local root = characterModel and characterModel:FindFirstChild("HumanoidRootPart")
		if root then
			if not BaseManager.IsPositionInsideOwnBase(player, root.Position) then
				root.CFrame = CFrame.new(worldMap.SpawnPosition)
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

local function findPlayerFromPart(part)
	local model = part
	while model and model ~= Workspace do
		if model:IsA("Model") then
			local player = Players:GetPlayerFromCharacter(model)
			if player then
				return player
			end
		end
		model = model.Parent
	end
	return nil
end

local function spawnChiliPepper()
	if not chiliFolder then
		chiliFolder = Instance.new("Folder")
		chiliFolder.Name = "ChiliRain"
		chiliFolder.Parent = Workspace
	end
	local range = BrainrotCatalog.PlazaRadius * 0.8
	local x = math.random(-range * 10, range * 10) / 10
	local z = math.random(-range * 10, range * 10) / 10
	if math.abs(z) < 8 then
		if z >= 0 then
			z = 8 + math.random(0, 40) / 10
		else
			z = -8 - math.random(0, 40) / 10
		end
	end
	local pepper = Instance.new("Part")
	pepper.Name = "ChiliFalling"
	pepper.Size = Vector3.new(0.7, 1.4, 0.7)
	pepper.Position = Vector3.new(x, 35, z)
	pepper.Color = Color3.fromRGB(220, 40, 30)
	pepper.Material = Enum.Material.SmoothPlastic
	pepper.Anchored = true
	pepper.CanCollide = false
	pepper.Parent = chiliFolder
	local stem = Instance.new("Part")
	stem.Name = "Stem"
	stem.Size = Vector3.new(0.3, 0.5, 0.3)
	stem.Position = pepper.Position + Vector3.new(0, 0.9, 0)
	stem.Color = Color3.fromRGB(60, 160, 60)
	stem.Material = Enum.Material.SmoothPlastic
	stem.Anchored = true
	stem.CanCollide = false
	stem.Parent = pepper

	task.spawn(function()
		local claimed = false
		while pepper.Parent and pepper.Position.Y > 1.2 do
			local drop = math.min(28 * 0.05, pepper.Position.Y - 1.2)
			pepper.Position -= Vector3.new(0, drop, 0)
			stem.Position -= Vector3.new(0, drop, 0)
			task.wait(0.05)
		end
		if not pepper.Parent then
			return
		end
		pepper.Name = "ChiliPickup"
		local value = math.random(BrainrotCatalog.ChiliPickupValueMin, BrainrotCatalog.ChiliPickupValueMax)
		pepper:SetAttribute("Value", value)
		pepper.Touched:Connect(function(hit)
			if claimed then
				return
			end
			local player = findPlayerFromPart(hit)
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
			showMessage(player, "+$" .. value .. " chili bonus!")
			pepper:Destroy()
		end)
		task.delay(BrainrotCatalog.ChiliPickupLifetimeSeconds, function()
			if pepper.Parent then
				pepper:Destroy()
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

function WaveManager.Init(remoteFolder, map)
	remotes = remoteFolder
	worldMap = map
	chiliFolder = Workspace:FindFirstChild("ChiliRain")
	if not chiliFolder then
		chiliFolder = Instance.new("Folder")
		chiliFolder.Name = "ChiliRain"
		chiliFolder.Parent = Workspace
	end
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
