-- PlayerData.luau
-- Per-player save data: cash, owned brainrots, the Prize Book index and
-- rebirth progress, persisted through a DataStore when one is available.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))

local PlayerData = {}

local store = nil
local storeAvailable = false
local warnedUnavailable = false

do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore("BrainrotBazaar_v1")
	end)
	if ok and result then
		store = result
		storeAvailable = true
	else
		warn("[BrainrotBazaar] DataStore unavailable; running session-only.")
		warnedUnavailable = true
	end
end

local sessions = {}
local loadedFlags = {}

local function freshData()
	return {
		Cash = BrainrotCatalog.StartingCash,
		TotalEarned = 0,
		Rebirths = 0,
		SlotsBought = 0,
		Owned = {},
		Index = {},
		IndexRewardsClaimed = 0,
		LastStolenAt = 0,
	}
end

local function backfill(data)
	local defaults = freshData()
	for key, value in pairs(defaults) do
		if data[key] == nil then
			data[key] = value
		end
	end
	if type(data.Owned) ~= "table" then
		data.Owned = {}
	end
	if type(data.Index) ~= "table" then
		data.Index = {}
	end
	return data
end

local function buildLeaderstats(player, data)
	local existing = player:FindFirstChild("leaderstats")
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	local cashValue = Instance.new("IntValue")
	cashValue.Name = "Cash"
	cashValue.Value = math.floor(data.Cash)
	cashValue.Parent = folder
	local rebirthValue = Instance.new("IntValue")
	rebirthValue.Name = "Rebirths"
	rebirthValue.Value = data.Rebirths
	rebirthValue.Parent = folder
	folder.Parent = player
end

function PlayerData.Load(player)
	local data = freshData()
	if storeAvailable and store then
		local ok, saved = pcall(function()
			return store:GetAsync("player_" .. player.UserId)
		end)
		if ok and type(saved) == "table" and type(saved.Cash) == "number" then
			data = backfill(saved)
		elseif not ok and not warnedUnavailable then
			warn("[BrainrotBazaar] DataStore read failed; running session-only for this player.")
		end
	else
		data = backfill(data)
	end
	sessions[player] = data
	loadedFlags[player] = true
	buildLeaderstats(player, data)
	return data
end

function PlayerData.Get(player)
	return sessions[player]
end

function PlayerData.IsLoaded(player)
	return loadedFlags[player] == true
end

function PlayerData.Sync(player)
	local data = sessions[player]
	if not data then
		return
	end
	local folder = player:FindFirstChild("leaderstats")
	if not folder then
		buildLeaderstats(player, data)
		return
	end
	local cashValue = folder:FindFirstChild("Cash")
	if cashValue then
		cashValue.Value = math.floor(data.Cash)
	end
	local rebirthValue = folder:FindFirstChild("Rebirths")
	if rebirthValue then
		rebirthValue.Value = data.Rebirths
	end
end

function PlayerData.Save(player)
	local data = sessions[player]
	if not data or not storeAvailable or not store then
		return
	end
	pcall(function()
		store:SetAsync("player_" .. player.UserId, data)
	end)
end

function PlayerData.SaveAllPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		PlayerData.Save(player)
	end
end

function PlayerData.Unload(player)
	PlayerData.Save(player)
	sessions[player] = nil
	loadedFlags[player] = nil
end

function PlayerData.GetTotalSlots(player)
	local data = sessions[player]
	if not data then
		return BrainrotCatalog.BaseSlotCount
	end
	return BrainrotCatalog.BaseSlotCount + data.SlotsBought
end

function PlayerData.FindFreeSlot(player)
	local data = sessions[player]
	if not data then
		return nil
	end
	local used = {}
	for _, entry in ipairs(data.Owned) do
		used[entry.Slot] = true
	end
	for slotIndex = 1, PlayerData.GetTotalSlots(player) do
		if not used[slotIndex] then
			return slotIndex
		end
	end
	return nil
end

function PlayerData.GetOwnedAtSlot(player, slotIndex)
	local data = sessions[player]
	if not data then
		return nil
	end
	for _, entry in ipairs(data.Owned) do
		if entry.Slot == slotIndex then
			return entry
		end
	end
	return nil
end

function PlayerData.AddOwnedBrainrot(player, characterId, mutationName, slotIndex)
	local data = sessions[player]
	if not data then
		return
	end
	table.insert(data.Owned, {
		CharacterId = characterId,
		Mutation = mutationName or "None",
		Slot = slotIndex,
	})
	data.Index[characterId] = true
	PlayerData.Sync(player)
end

function PlayerData.RemoveOwnedBrainrot(player, slotIndex)
	local data = sessions[player]
	if not data then
		return nil
	end
	for index, entry in ipairs(data.Owned) do
		if entry.Slot == slotIndex then
			local removed = table.remove(data.Owned, index)
			PlayerData.Sync(player)
			return removed
		end
	end
	return nil
end

function PlayerData.ClearOwnedBrainrots(player)
	local data = sessions[player]
	if not data then
		return
	end
	data.Owned = {}
	PlayerData.Sync(player)
end

function PlayerData.GetIndexCount(player)
	local data = sessions[player]
	if not data then
		return 0
	end
	local count = 0
	for _ in pairs(data.Index) do
		count += 1
	end
	return count
end

function PlayerData.HasInIndex(player, characterId)
	local data = sessions[player]
	if not data then
		return false
	end
	return data.Index[characterId] == true
end

return PlayerData
