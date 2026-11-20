-- PlayerData: session copies, DataStore persistence, leaderstats and the Prize Book index.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))

local PlayerData = {}

local DATASTORE_NAME = "BrainrotBazaar_v1"
local STORE_KEY_PREFIX = "player_"

local store = nil
local warnedStore = false
local sessions = {}
local loaded = {}

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

local function getStore()
	if store then
		return store
	end
	if warnedStore then
		return nil
	end
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(DATASTORE_NAME)
	end)
	if ok and result then
		store = result
		return store
	end
	warnedStore = true
	warn("[BrainrotBazaar] DataStore unavailable; running session-only this session.")
	return nil
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

function PlayerData.Get(player)
	return sessions[player]
end

function PlayerData.IsLoaded(player)
	return loaded[player] == true
end

function PlayerData.Sync(player)
	local data = sessions[player]
	if not data then
		return
	end
	local folder = player:FindFirstChild("leaderstats")
	if folder then
		local cash = folder:FindFirstChild("Cash")
		if cash then
			cash.Value = math.floor(data.Cash)
		end
		local rebirths = folder:FindFirstChild("Rebirths")
		if rebirths then
			rebirths.Value = data.Rebirths
		end
	end
end

local function buildLeaderstats(player)
	local old = player:FindFirstChild("leaderstats")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"

	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = 0
	cash.Parent = folder

	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = 0
	rebirths.Parent = folder

	folder.Parent = player
end

function PlayerData.Load(player)
	local activeStore = getStore()
	local data = nil

	if activeStore then
		local ok, result = pcall(function()
			return activeStore:GetAsync(STORE_KEY_PREFIX .. tostring(player.UserId))
		end)
		if ok and type(result) == "table" then
			data = result
		end
	end

	local isFresh = data == nil
	if isFresh then
		data = freshData()
	else
		data = backfill(data)
	end

	-- Older saves may pre-date the Prize Book or the shield stamp.
	backfill(data)

	sessions[player] = data
	loaded[player] = true
	buildLeaderstats(player)
	PlayerData.Sync(player)
	return data
end

function PlayerData.Save(player)
	local data = sessions[player]
	if not data then
		return
	end
	local activeStore = getStore()
	if not activeStore then
		return
	end
	pcall(function()
		activeStore:SetAsync(STORE_KEY_PREFIX .. tostring(player.UserId), data)
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
	loaded[player] = nil
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
	local total = PlayerData.GetTotalSlots(player)
	for slot = 1, total do
		if not used[slot] then
			return slot
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
		Mutation = mutationName,
		Slot = slotIndex,
	})
	data.Index[characterId] = true
	PlayerData.Sync(player)
end

function PlayerData.RemoveOwnedBrainrot(player, slotIndex)
	local data = sessions[player]
	if not data then
		return
	end
	for index, entry in ipairs(data.Owned) do
		if entry.Slot == slotIndex then
			table.remove(data.Owned, index)
			PlayerData.Sync(player)
			return
		end
	end
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
