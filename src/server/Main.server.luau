-- Main.server.luau
-- Brainrot Bazaar server bootstrap. Builds the remotes, builds the world,
-- starts every manager, wires the click callbacks and handles players
-- joining, leaving and autosaving. Nothing game-specific lives here beyond
-- the wiring order.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))

local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local BrainrotSpawner = require(script.Parent:WaitForChild("BrainrotSpawner"))
local EconomyManager = require(script.Parent:WaitForChild("EconomyManager"))
local MapBuilder = require(script.Parent:WaitForChild("MapBuilder"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local RebirthManager = require(script.Parent:WaitForChild("RebirthManager"))
local StealManager = require(script.Parent:WaitForChild("StealManager"))
local WaveManager = require(script.Parent:WaitForChild("WaveManager"))

-- RebirthManager has no Init of its own; requiring it here keeps the whole
-- module graph loaded before the first player arrives.
local _ = RebirthManager

-- ---------------------------------------------------------------------------
-- Remotes
-- ---------------------------------------------------------------------------

local REMOTE_NAMES = {
	"RequestBuy",
	"RequestSell",
	"RequestBuySlot",
	"RequestLock",
	"RequestRebirth",
	"RequestSteal",
	"StateUpdate",
	"ShowBanner",
	"ShowMessage",
}

local remoteFolder = Instance.new("Folder")
remoteFolder.Name = "Remotes"
remoteFolder.Parent = ReplicatedStorage

local remotes = {}
for _, remoteName in ipairs(REMOTE_NAMES) do
	local remote = Instance.new("RemoteEvent")
	remote.Name = remoteName
	remote.Parent = remoteFolder
	remotes[remoteName] = remote
end

-- ---------------------------------------------------------------------------
-- World and managers
-- ---------------------------------------------------------------------------

local worldMap = MapBuilder.BuildWorld()

BaseManager.Init(worldMap)
BrainrotSpawner.Init(worldMap)
EconomyManager.Init(remotes)
StealManager.Init(remotes)
WaveManager.Init(remotes, worldMap)

BrainrotSpawner.ClickedCallback = function(player, beltId)
	EconomyManager.TryBuyBeltBrainrot(player, beltId)
end

BaseManager.StealClickedCallback = function(clickingPlayer, ownerPlayer, slotIndex)
	StealManager.TryStealFromClick(clickingPlayer, ownerPlayer, slotIndex)
end

-- ---------------------------------------------------------------------------
-- Players
-- ---------------------------------------------------------------------------

local function onPlayerAdded(player)
	PlayerData.Load(player)
	BaseManager.AssignPlotToPlayer(player)
	BaseManager.RebuildBaseFromSave(player)
	EconomyManager.SendInitialState(player)
end

local function onPlayerRemoving(player)
	BaseManager.ReleasePlotForPlayer(player)
	PlayerData.Unload(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

-- ---------------------------------------------------------------------------
-- Autosave
-- ---------------------------------------------------------------------------

task.spawn(function()
	while true do
		task.wait(BrainrotCatalog.AutosaveIntervalSeconds)
		PlayerData.SaveAllPlayers()
	end
end)

game:BindToClose(function()
	PlayerData.SaveAllPlayers()
end)

print(string.format(
	"[BrainrotBazaar] Server started: %d plots, %d characters, belt holds %d.",
	#worldMap.Plots,
	#BrainrotCatalog.Characters,
	BrainrotCatalog.MaxBeltBrainrots
))
