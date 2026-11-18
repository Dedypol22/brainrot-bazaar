-- PlayerData.luau (server module)
-- Owns one player's save data: cash, lifetime earnings, rebirths, extra
-- slots and the list of brainrots standing on their base. Persistence uses
-- DataStoreService wrapped in pcall calls, so when Studio runs without API
-- access (or the place is unpublished) the game quietly falls back to
-- session-only data and nothing ever errors.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))

local PlayerData = {}

local STORE_NAME = "BrainrotBazaar_v1"

local store = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	else
		warn("[BrainrotBazaar] DataStore unavailable, using session-only data: " .. tostring(result))
	end
end

local function freshData()
	return {
		Cash = BrainrotCatalog.StartingCash,
		TotalEarned = 0,
		Rebirths = 0,
		SlotsBought = 0,
		Owned = {}, -- array of { CharacterId = string, Mutation = string, Slot = number }
	}
end

local sessions = {} -- [Player] -> data table
local loaded = {} -- [Player] -> true once the data is ready

local function buildLeaderstats(player, data)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = math.floor(data.Cash)
	cash.Parent = leaderstats

	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = math.floor(data.Rebirths)
	rebirths.Parent = leaderstats

	leaderstats.Parent = player
end

-- Copies the session data into the leaderstats the player list shows.
function PlayerData.Sync(player)
	local data = sessions[player]
	if not data then
		return
	end
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local cash = leaderstats:FindFirstChild("Cash")
		if cash then
			cash.Value = math.floor(data.Cash)
		end
		local rebirths = leaderstats:FindFirstChild("Rebirths")
		if rebirths then
			rebirths.Value = math.floor(data.Rebirths)
		end
	end
end

-- Loads one player's save, or hands them a fresh start when there is none.
-- Brainrot entries whose character no longer exists in the catalogue are
-- dropped instead of breaking the load.
function PlayerData.Load(player)
	local data = freshData()

	if store then
		local ok, saved = pcall(function()
			return store:GetAsync("Player_" .. player.UserId)
		end)
		if ok and type(saved) == "table" then
			if type(saved.Cash) == "number" then
				data.Cash = saved.Cash
			end
			if type(saved.TotalEarned) == "number" then
				data.TotalEarned = saved.TotalEarned
			end
			if type(saved.Rebirths) == "number" then
				data.Rebirths = saved.Rebirths
			end
			if type(saved.SlotsBought) == "number" then
				data.SlotsBought = saved.SlotsBought
			end
			if type(saved.Owned) == "table" then
				for _, entry in ipairs(saved.Owned) do
					if type(entry) == "table"
						and type(entry.CharacterId) == "string"
						and type(entry.Slot) == "number"
						and BrainrotCatalog.GetCharacterById(entry.CharacterId) then
						table.insert(data.Owned, {
							CharacterId = entry.CharacterId,
							Mutation = type(entry.Mutation) == "string" and entry.Mutation or "None",
							Slot = entry.Slot,
						})
					end
				end
			end
		elseif not ok then
			warn("[BrainrotBazaar] Failed to load data for " .. player.Name .. ": " .. tostring(saved))
		end
	end

	sessions[player] = data
	buildLeaderstats(player, data)
	PlayerData.Sync(player)
	loaded[player] = true
end

function PlayerData.Get(player)
	return sessions[player]
end

function PlayerData.IsLoaded(player)
	return loaded[player] == true
end

function PlayerData.Save(player)
	local data = sessions[player]
	if not data or not store then
		return
	end
	local ok, err = pcall(function()
		store:SetAsync("Player_" .. player.UserId, data)
	end)
	if not ok then
		warn("[BrainrotBazaar] Failed to save data for " .. player.Name .. ": " .. tostring(err))
	end
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

-- Total number of base slots this player owns (starting slots + bought).
function PlayerData.GetTotalSlots(player)
	local data = sessions[player]
	if not data then
		return BrainrotCatalog.BaseSlotCount
	end
	return BrainrotCatalog.BaseSlotCount + data.SlotsBought
end

-- First free slot index for this player, or nil when the base is full.
function PlayerData.FindFreeSlot(player)
	local data = sessions[player]
	if not data then
		return nil
	end
	local totalSlots = PlayerData.GetTotalSlots(player)
	local taken = {}
	for _, entry in ipairs(data.Owned) do
		taken[entry.Slot] = true
	end
	for slot = 1, totalSlots do
		if not taken[slot] then
			return slot
		end
	end
	return nil
end

-- The owned entry standing on one slot, or nil when the slot is empty.
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
		return false
	end
	table.insert(data.Owned, {
		CharacterId = characterId,
		Mutation = mutationName,
		Slot = slotIndex,
	})
	return true
end

function PlayerData.RemoveOwnedBrainrot(player, slotIndex)
	local data = sessions[player]
	if not data then
		return nil
	end
	for index, entry in ipairs(data.Owned) do
		if entry.Slot == slotIndex then
			table.remove(data.Owned, index)
			return entry
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
end

return PlayerData
