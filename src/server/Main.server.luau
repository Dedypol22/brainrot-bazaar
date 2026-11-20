-- Main: wire the bazaar together on the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local MapBuilder = require(script.Parent:WaitForChild("MapBuilder"))
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local BrainrotSpawner = require(script.Parent:WaitForChild("BrainrotSpawner"))
local EconomyManager = require(script.Parent:WaitForChild("EconomyManager"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local RebirthManager = require(script.Parent:WaitForChild("RebirthManager"))
local StealManager = require(script.Parent:WaitForChild("StealManager"))
local ThiefManager = require(script.Parent:WaitForChild("ThiefManager"))
local WaveManager = require(script.Parent:WaitForChild("WaveManager"))

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

local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if remotesFolder then
	remotesFolder:Destroy()
end
remotesFolder = Instance.new("Folder")
remotesFolder.Name = "Remotes"
remotesFolder.Parent = ReplicatedStorage

local remotes = {}
for _, remoteName in ipairs(remoteNames) do
	local remote = Instance.new("RemoteEvent")
	remote.Name = remoteName
	remote.Parent = remotesFolder
	remotes[remoteName] = remote
end

local worldMap = MapBuilder.BuildWorld()

BaseManager.Init(worldMap)
BrainrotSpawner.Init(worldMap)
EconomyManager.Init(remotes)
StealManager.Init(remotes)
ThiefManager.Init(remotes, worldMap)
WaveManager.Init(remotes, worldMap)

BrainrotSpawner.ClickedCallback = function(player, beltId)
	EconomyManager.TryBuyBeltBrainrot(player, beltId)
end

BaseManager.StealClickedCallback = function(clickingPlayer, ownerPlayer, slotIndex)
	StealManager.TryStealFromClick(clickingPlayer, ownerPlayer, slotIndex)
end

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

Players.PlayerAdded:Connect(function(player)
	task.spawn(onPlayerAdded, player)
end)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

task.spawn(function()
	while true do
		task.wait(BrainrotCatalog.AutosaveIntervalSeconds)
		PlayerData.SaveAllPlayers()
	end
end)

game:BindToClose(function()
	PlayerData.SaveAllPlayers()
end)

print("[Brainrot Bazaar] Server started with " .. tostring(#worldMap.Plots) .. " plots and " .. tostring(#BrainrotCatalog.Characters) .. " brainrots.")
