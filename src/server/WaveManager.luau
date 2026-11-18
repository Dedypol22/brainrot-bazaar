-- WaveManager.luau (server module)
-- Owns the tsunami event: about every three minutes a warning banner
-- counts down ten seconds, then a huge wall of water sweeps across the
-- plaza. Brainrots still riding the conveyor are washed away, and players
-- caught outside their own base are pushed back to the spawn area.
-- Brainrots safe on a base are never touched.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local BrainrotSpawner = require(script.Parent:WaitForChild("BrainrotSpawner"))

local WaveManager = {}

local remotes = nil
local worldMap = nil

local WAVE_START_X = -170
local WAVE_END_X = 170
local WAVE_SPEED = 45 -- studs per second across the plaza

-- Pushes every player standing outside their own base back to spawn.
local function pushPlayersOutsideBasesBackToSpawn()
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if character then
			local root = character:FindFirstChild("HumanoidRootPart")
			if root and not BaseManager.IsPositionInsideOwnBase(player, root.Position) then
				root.CFrame = CFrame.new(worldMap.SpawnPosition)
				if remotes then
					remotes.ShowMessage:FireClient(player, "The wave swept you back to spawn!")
				end
			end
		end
	end
end

-- Slides the wall across the plaza, washing the belt clean as it passes.
local function sweepWaveAcrossPlaza()
	local wave = worldMap.WavePart
	wave.Position = Vector3.new(WAVE_START_X, 13, 0)
	wave.Visible = true

	local beltWashed = false
	local playersPushed = false
	local x = WAVE_START_X
	while x < WAVE_END_X do
		task.wait(0.05)
		x = x + WAVE_SPEED * 0.05
		wave.Position = Vector3.new(x, 13, 0)
		if not beltWashed and x >= 0 then
			beltWashed = true
			BrainrotSpawner.ClearAllBeltBrainrots()
			if remotes then
				remotes.ShowMessage:FireAllClients("The wave washed the conveyor clean!")
			end
		end
		if not playersPushed and x >= -40 then
			playersPushed = true
			pushPlayersOutsideBasesBackToSpawn()
		end
	end

	wave.Visible = false
	wave.Position = Vector3.new(WAVE_START_X, 13, 0)
end

-- One full event: warn, count down, then sweep.
local function runOneTsunamiEvent()
	if remotes then
		for secondsLeft = BrainrotCatalog.WaveWarningSeconds, 1, -1 do
			remotes.ShowBanner:FireAllClients("TSUNAMI INCOMING! Get to your base! " .. secondsLeft .. "s", 1)
			task.wait(1)
		end
		remotes.ShowBanner:FireAllClients("TSUNAMI! HOLD ON!", 3)
	end
	sweepWaveAcrossPlaza()
end

function WaveManager.Init(remoteFolder, map)
	remotes = remoteFolder
	worldMap = map

	task.spawn(function()
		while true do
			task.wait(BrainrotCatalog.WaveIntervalSeconds)
			local ok, err = pcall(runOneTsunamiEvent)
			if not ok then
				warn("[BrainrotBazaar] Tsunami event failed: " .. tostring(err))
			end
		end
	end)
end

return WaveManager
