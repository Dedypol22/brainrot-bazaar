-- WaveManager.luau
-- The tsunami event. Every few minutes a glowing wall of water sweeps the
-- plaza from west to east. Anyone caught outside their own base when it has
-- passed gets washed back to spawn — so when the banner drops, run home.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local BrainrotSpawner = require(script.Parent:WaitForChild("BrainrotSpawner"))

local WaveManager = {}

local WAVE_START_X = -170
local WAVE_END_X = 170
local WAVE_SPEED = 45
local WAVE_Y = 10 -- centre height while sweeping, so the wall towers over the plaza
local PARKED_POSITION = Vector3.new(-170, -60, 0)

local remotes = nil
local worldMap = nil

local function sweepWaveAcrossPlaza()
	local wavePart = worldMap and worldMap.WavePart
	if not wavePart then
		return
	end
	local distance = WAVE_END_X - WAVE_START_X
	local duration = distance / WAVE_SPEED
	local steps = math.max(1, math.floor(duration / 0.05))
	for step = 0, steps do
		local fraction = step / steps
		local x = WAVE_START_X + distance * fraction
		wavePart.Position = Vector3.new(x, WAVE_Y, 0)
		task.wait(0.05)
	end
	wavePart.Position = PARKED_POSITION
end

local function pushPlayersOutsideBasesBackToSpawn()
	if not worldMap then
		return
	end
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and not BaseManager.IsPositionInsideOwnBase(player, root.Position) then
			character:PivotTo(CFrame.new(worldMap.SpawnPosition))
		end
	end
end

local function runOneTsunamiEvent()
	if remotes and remotes.ShowBanner then
		remotes.ShowBanner:FireAllClient("TSUNAMI INCOMING")
	end
	local halfway = BrainrotCatalog.WaveWarningSeconds / 2
	task.wait(halfway)
	if remotes and remotes.ShowBanner then
		remotes.ShowBanner:FireAllClient("GET TO YOUR BASE!")
	end
	task.wait(BrainrotCatalog.WaveWarningSeconds - halfway)

	sweepWaveAcrossPlaza()
	pushPlayersOutsideBasesBackToSpawn()
end

function WaveManager.Init(remoteFolder, map)
	remotes = remoteFolder
	worldMap = map
	-- BrainrotSpawner is required so the module graph matches the other
	-- managers; the wave itself does not spawn anything.
	local _ = BrainrotSpawner
	task.spawn(function()
		while true do
			task.wait(BrainrotCatalog.WaveIntervalSeconds)
			runOneTsunamiEvent()
		end
	end)
end

return WaveManager
