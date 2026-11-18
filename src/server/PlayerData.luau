-- PlayerData.luau
-- Owns every player's save data for Brainrot Bazaar: cash, lifetime earnings,
-- rebirths, bought slots and the brainrots they own. Data is kept in session
-- tables while a player is in the game and persisted to the
-- "BrainrotBazaar_v1" DataStore on save. When the store cannot be reached
-- (for example in Studio) the module warns once and runs session-only.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))

local PlayerData = {}

local STORE_NAME = "BrainrotBazaar_v1"

local dataStore = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		dataStore = result
	end
end

local storeAvailable = dataStore ~= nil
local storeWarned = false

local function noteStoreUnavailable()
	if not storeWarned then
		storeWarned = true
		warn("[BrainrotBazaar] DataStore unavailable; progress will not persist this session.")
	end
end

if not storeAvailable then
	noteStoreUnavailable()
end

-- Session state, keyed by the Player instance itself.
local sessions = {}
local loadedFlags = {}

local function freshData()
	return {
		Cash = BrainrotCatalog.StartingCash,
		TotalEarned = 0,
		Rebirths = 0,
		SlotsBought = 0,
		Owned = {},
	}
end

local function looksValid(saved)
	return type(saved) == "table"
		and type(saved.Cash) == "number"
		and type(saved.Owned) == "table"
end

-- Fill any missing fields of a saved table with fresh defaults so older or
-- partial saves can never produce nil-field errors downstream.
local function normalizeData(saved)
	local data = freshData()
	data.Cash = saved.Cash
	if type(saved.TotalEarned) == "number" then
		data.TotalEarned = saved.TotalEarned
	end
	if type(saved.Rebirths) == "number" then
		data.Rebirths = saved.Rebirths
	end
	if type(saved.SlotsBought) == "number" then
		data.SlotsBought = saved.SlotsBought
	end
	for _, entry in ipairs(saved.Owned) do
		if type(entry) == "table" and type(entry.CharacterId) == "string" and type(entry.Slot) == "number" then
			table.insert(data.Owned, {
				CharacterId = entry.CharacterId,
				Mutation = type(entry.Mutation) == "string" and entry.Mutation or "None",
				Slot = entry.Slot,
			})
		end
	end
	return data
end

local function buildLeaderstats(player)
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"

	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Parent = folder

	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Parent = folder

	folder.Parent = player
end

-- Loading / saving ----------------------------------------------------------

function PlayerData.Load(player)
	if loadedFlags[player] then
		return
	end
	local data = freshData()
	if storeAvailable then
		local ok, saved = pcall(function()
			return dataStore:GetAsync("player_" .. player.UserId)
		end)
		if ok then
			if looksValid(saved) then
				data = normalizeData(saved)
			end
		else
			storeAvailable = false
			noteStoreUnavailable()
		end
	end
	sessions[player] = data
	loadedFlags[player] = true
	buildLeaderstats(player)
	PlayerData.Sync(player)
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
		return
	end
	local cash = folder:FindFirstChild("Cash")
	if cash then
		cash.Value = math.floor(data.Cash)
	end
	local rebirths = folder:FindFirstChild("Rebirths")
	if rebirths then
		rebirths.Value = data.Rebirths
	end
end

function PlayerData.Save(player)
	local data = sessions[player]
	if not data or not storeAvailable then
		return
	end
	local ok = pcall(function()
		dataStore:SetAsync("player_" .. player.UserId, data)
	end)
	if not ok then
		storeAvailable = false
		noteStoreUnavailable()
	end
end

function PlayerData.SaveAllPlayers()
	for player in pairs(sessions) do
		PlayerData.Save(player)
	end
end

function PlayerData.Unload(player)
	PlayerData.Save(player)
	sessions[player] = nil
	loadedFlags[player] = nil
end

-- Slots and owned brainrots ---------------------------------------------------

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
		Mutation = mutationName,
		Slot = slotIndex,
	})
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
			break
		end
	end
	PlayerData.Sync(player)
end

function PlayerData.ClearOwnedBrainrots(player)
	local data = sessions[player]
	if not data then
		return
	end
	data.Owned = {}
	PlayerData.Sync(player)
end

return PlayerData
