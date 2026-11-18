-- Main.server.luau
-- Brainrot Bazaar server bootstrap. Creates the RemoteEvents the client HUD
-- talks to, builds the world, wires the managers together and hooks up the
-- player lifecycle: load data, hand out a base plot, rebuild the base from
-- the save, and keep autosaving while the server runs.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local MapBuilder = require(script.Parent:WaitForChild("MapBuilder"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local BrainrotSpawner = require(script.Parent:WaitForChild("BrainrotSpawner"))
local EconomyManager = require(script.Parent:WaitForChild("EconomyManager"))
local RebirthManager = require(script.Parent:WaitForChild("RebirthManager"))
local StealManager = require(script.Parent:WaitForChild("StealManager"))
local WaveManager = require(script.Parent:WaitForChild("WaveManager"))

-- Remotes ----------------------------------------------------------------------

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

local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "Remotes"
remotesFolder.Parent = ReplicatedStorage

local remotes = {}
for _, remoteName in ipairs(REMOTE_NAMES) do
	local remote = Instance.new("RemoteEvent")
	remote.Name = remoteName
	remote.Parent = remotesFolder
	remotes[remoteName] = remote
end

-- World and managers --------------------------------------------------------------

local worldMap = MapBuilder.BuildWorld()

BaseManager.Init(worldMap)
BrainrotSpawner.Init(worldMap)
EconomyManager.Init(remotes)
StealManager.Init(remotes)
WaveManager.Init(remotes, worldMap)

-- Click wiring: belt clicks are purchases, base clicks are steal attempts.
BrainrotSpawner.ClickedCallback = function(player, beltId)
	EconomyManager.TryBuyBeltBrainrot(player, beltId)
end
BaseManager.StealClickedCallback = function(clickingPlayer, ownerPlayer, slotIndex)
	StealManager.TryStealFromClick(clickingPlayer, ownerPlayer, slotIndex)
end

-- Player lifecycle --------------------------------------------------------------------

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

-- Autosave --------------------------------------------------------------------------------

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
	"[BrainrotBazaar] Server started: %d plots, %d characters. Rebirth module ready (x%.2f income per rebirth).",
	#worldMap.Plots,
	#BrainrotCatalog.Characters,
	1 + BrainrotCatalog.RebirthIncomeBonus
))
