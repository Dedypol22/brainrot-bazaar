-- WaveManager.luau
-- The tsunami event: every few minutes a warning banner goes out to every
-- player, then a wall of water sweeps across the plaza from one side to the
-- other. Anyone caught outside their own base when it passes is washed back
-- to the spawn point — dashing home in time is the only shelter.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local BrainrotSpawner = require(script.Parent:WaitForChild("BrainrotSpawner"))

local WaveManager = {}

local WAVE_START_X = -170
local WAVE_END_X = 170
local WAVE_SPEED = 45
local WAVE_PARK_POSITION = Vector3.new(WAVE_START_X, -60, 0)

local remotes = nil
local wavePart = nil
local spawnPosition = nil

local function sweepWaveAcrossPlaza()
	if not wavePart then
		return
	end
	local distance = WAVE_END_X - WAVE_START_X
	local duration = distance / WAVE_SPEED
	local steps = math.max(1, math.floor(duration / 0.05))
	for step = 0, steps do
		local x = WAVE_START_X + distance * (step / steps)
		wavePart.Position = Vector3.new(x, 12, 0)
		task.wait(0.05)
	end
	wavePart.Position = WAVE_PARK_POSITION
end

local function pushPlayersOutsideBasesBackToSpawn()
	if not spawnPosition then
		return
	end
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and not BaseManager.IsPositionInsideOwnBase(player, root.Position) then
			root.CFrame = CFrame.new(spawnPosition)
		end
	end
end

local function runOneTsunamiEvent()
	if remotes and remotes.ShowBanner then
		remotes.ShowBanner:FireAllClients("TSUNAMI INCOMING")
	end
	task.wait(BrainrotCatalog.WaveWarningSeconds)
	sweepWaveAcrossPlaza()
	pushPlayersOutsideBasesBackToSpawn()
end

function WaveManager.Init(remoteFolder, map)
	remotes = remoteFolder
	wavePart = map.WavePart
	spawnPosition = map.SpawnPosition

	task.spawn(function()
		while true do
			task.wait(BrainrotCatalog.WaveIntervalSeconds)
			runOneTsunamiEvent()
		end
	end)
end

return WaveManager
