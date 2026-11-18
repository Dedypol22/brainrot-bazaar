-- Main.server.luau — the server bootstrap for Brainrot Bazaar.
-- Responsibilities: build the world map, create the shared RemoteEvents,
-- initialise every server manager, connect buy/steal click callbacks, and
-- own the player lifecycle (load, plot assignment, base rebuild, autosave).
--
-- Main.server.luau
-- The single entry point of Brainrot Bazaar. It builds the world, creates
-- the RemoteEvents the client talks through, wires the server modules
-- together, and handles players joining and leaving (load, plot, rebuild,
-- save). Every other server module does one job; this script only plugs
-- them into each other.

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

-- The RemoteEvents the client uses. Created here so every module can share
-- the same folder, and the client can wait for it by name.
local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "Remotes"
remotesFolder.Parent = ReplicatedStorage

local remoteNames = {
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
local remotes = {}
for _, remoteName in ipairs(remoteNames) do
	local remote = Instance.new("RemoteEvent")
	remote.Name = remoteName
	remote.Parent = remotesFolder
	remotes[remoteName] = remote
end

-- Build the world first, so plots and the spawn exist before anyone joins.
local worldMap = MapBuilder.BuildWorld()

BaseManager.Init(worldMap)
BrainrotSpawner.Init(worldMap)
EconomyManager.Init(remotes)
StealManager.Init(remotes)
WaveManager.Init(remotes, worldMap)

-- A click on a belt brainrot tries to buy it.
BrainrotSpawner.ClickedCallback = function(player, beltId)
	EconomyManager.TryBuyBeltBrainrot(player, beltId)
end

-- A click on another player's base brainrot tries to steal it.
BaseManager.StealClickedCallback = function(clickingPlayer, ownerPlayer, slotIndex)
	StealManager.TryStealFromClick(clickingPlayer, ownerPlayer, slotIndex)
end

-- One player joining: load their save, give them a plot, rebuild their
-- base from the save, and send their first state snapshot.
local function onPlayerAdded(player)
	PlayerData.Load(player)
	BaseManager.AssignPlotToPlayer(player)
	BaseManager.RebuildBaseFromSave(player)
	EconomyManager.SendInitialState(player)
end

-- One player leaving: free their plot and save their data.
local function onPlayerRemoving(player)
	BaseManager.ReleasePlotForPlayer(player)
	PlayerData.Unload(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Players who joined before this script finished wiring up.
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

-- Autosave every minute, so a crash loses at most a minute of progress.
task.spawn(function()
	while true do
		task.wait(BrainrotCatalog.AutosaveIntervalSeconds)
		PlayerData.SaveAllPlayers()
	end
end)

-- Save everyone when the server shuts down.
game:BindToClose(function()
	PlayerData.SaveAllPlayers()
end)

print("[BrainrotBazaar] Server started: plaza, conveyor, " .. BrainrotCatalog.PlotCount .. " plots, " .. #BrainrotCatalog.Characters .. " brainrots.")
