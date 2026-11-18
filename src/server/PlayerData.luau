-- PlayerData.luau
-- Owns per-player save data for Brainrot Bazaar: cash, lifetime earnings,
-- rebirths, bought slots and the brainrots standing on the player's base.
-- Persists through the "BrainrotBazaar_v1" DataStore when one is available;
-- in Studio (or whenever the store refuses) it quietly runs session-only.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))

local PlayerData = {}

local STORE_NAME = "BrainrotBazaar_v1"

local store = nil
local storeUnavailable = false
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok and result then
		store = result
	else
		storeUnavailable = true
		warn("[BrainrotBazaar] DataStore unavailable; progress will be session-only.")
	end
end

-- Session copies, keyed by player.
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
	if type(saved) ~= "table" then
		return false
	end
	if type(saved.Cash) ~= "number" or type(saved.TotalEarned) ~= "number" then
		return false
	end
	if type(saved.Rebirths) ~= "number" or type(saved.SlotsBought) ~= "number" then
		return false
	end
	if type(saved.Owned) ~= "table" then
		return false
	end
	return true
end

local function sanitise(saved)
	-- Rebuild the table from scratch so a hand-edited or stale save can never
	-- smuggle in fields the game does not understand.
	local data = freshData()
	data.Cash = saved.Cash
	data.TotalEarned = saved.TotalEarned
	data.Rebirths = saved.Rebirths
	data.SlotsBought = math.clamp(saved.SlotsBought, 0, BrainrotCatalog.MaxSlotCount - BrainrotCatalog.BaseSlotCount)
	for _, entry in ipairs(saved.Owned) do
		if type(entry) == "table"
			and type(entry.CharacterId) == "string"
			and BrainrotCatalog.GetCharacterById(entry.CharacterId)
			and type(entry.Slot) == "number"
		then
			table.insert(data.Owned, {
				CharacterId = entry.CharacterId,
				Mutation = type(entry.Mutation) == "string" and entry.Mutation or "None",
				Slot = entry.Slot,
			})
		end
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
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = math.floor(data.Cash)
	cash.Parent = folder
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = data.Rebirths
	rebirths.Parent = folder
	folder.Parent = player
end

function PlayerData.Load(player)
	local data = freshData()
	if store and not storeUnavailable then
		local ok, saved = pcall(function()
			return store:GetAsync("player_" .. player.UserId)
		end)
		if ok and looksValid(saved) then
			data = sanitise(saved)
		elseif not ok then
			warn("[BrainrotBazaar] Load failed for " .. player.Name .. "; starting fresh.")
		end
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
	if not data or not store or storeUnavailable then
		return
	end
	local ok, err = pcall(function()
		store:SetAsync("player_" .. player.UserId, data)
	end)
	if not ok then
		warn("[BrainrotBazaar] Save failed for " .. player.Name .. ": " .. tostring(err))
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

function PlayerData.GetTotalSlots(player)
	local data = sessions[player]
	if not data then
		return BrainrotCatalog.BaseSlotCount
	end
	return BrainrotCatalog.BaseSlotCount + data.SlotsBought
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

function PlayerData.FindFreeSlot(player)
	local data = sessions[player]
	if not data then
		return nil
	end
	local totalSlots = PlayerData.GetTotalSlots(player)
	for slotIndex = 1, totalSlots do
		if not PlayerData.GetOwnedAtSlot(player, slotIndex) then
			return slotIndex
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
