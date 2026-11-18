-- EconomyManager.luau (server module)
-- Owns the money: the one-second income tick, buying brainrots off the
-- conveyor, selling them back for half price, buying extra base slots, and
-- the RemoteEvents that carry the client's requests and the state snapshots
-- the client renders. The client never decides money; every number here is
-- computed on the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local BrainrotSpawner = require(script.Parent:WaitForChild("BrainrotSpawner"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local RebirthManager = require(script.Parent:WaitForChild("RebirthManager"))
local StealManager = require(script.Parent:WaitForChild("StealManager"))

local EconomyManager = {}

local remotes = nil

-- Money per second from one player's owned brainrots, after mutations
-- and the permanent rebirth multiplier.
function EconomyManager.CalculateIncomePerSecond(player)
	local data = PlayerData.Get(player)
	if not data then
		return 0
	end
	local raw = 0
	for _, entry in ipairs(data.Owned) do
		local character = BrainrotCatalog.GetCharacterById(entry.CharacterId)
		if character then
			raw = raw + BrainrotCatalog.GetIncomePerSecond(character, entry.Mutation)
		end
	end
	return math.floor(raw * RebirthManager.GetIncomeMultiplier(player))
end

-- The full state snapshot the client renders every second.
function EconomyManager.BuildStateSnapshot(player)
	local data = PlayerData.Get(player)
	if not data then
		return nil
	end
	local owned = {}
	for _, entry in ipairs(data.Owned) do
		local character = BrainrotCatalog.GetCharacterById(entry.CharacterId)
		if character then
			table.insert(owned, {
				Slot = entry.Slot,
				CharacterId = entry.CharacterId,
				Name = BrainrotCatalog.GetDisplayName(character, entry.Mutation),
				Rarity = character.Rarity,
				Rate = BrainrotCatalog.GetIncomePerSecond(character, entry.Mutation),
				Mutation = entry.Mutation,
				Cost = character.Cost,
			})
		end
	end
	table.sort(owned, function(a, b)
		return a.Slot < b.Slot
	end)

	local totalSlots = PlayerData.GetTotalSlots(player)
	local nextSlotCost = nil
	if totalSlots < BrainrotCatalog.MaxSlotCount then
		nextSlotCost = BrainrotCatalog.GetNextSlotCost(data.SlotsBought)
	end

	return {
		Cash = math.floor(data.Cash),
		IncomePerSecond = EconomyManager.CalculateIncomePerSecond(player),
		Rebirths = data.Rebirths,
		TotalEarned = math.floor(data.TotalEarned),
		Slots = totalSlots,
		NextSlotCost = nextSlotCost,
		Owned = owned,
		Belt = BrainrotSpawner.GetBeltBrainrotsForClient(),
		Carrying = StealManager.GetCarrySummary(player),
		Lock = BaseManager.GetLockStatus(player),
		RebirthThreshold = BrainrotCatalog.RebirthCashThreshold,
		RebirthMultiplier = RebirthManager.GetIncomeMultiplier(player),
	}
end

function EconomyManager.SendStateUpdate(player)
	local snapshot = EconomyManager.BuildStateSnapshot(player)
	if snapshot and remotes then
		remotes.StateUpdate:FireClient(player, snapshot)
	end
end

local function sendFeedback(player, message)
	if remotes then
		remotes.ShowMessage:FireClient(player, message)
	end
end

-- Adds one second of income to every loaded player, then syncs them.
local function tickIncomeForAllPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		local data = PlayerData.Get(player)
		if data and PlayerData.IsLoaded(player) then
			local income = EconomyManager.CalculateIncomePerSecond(player)
			if income > 0 then
				data.Cash = data.Cash + income
				data.TotalEarned = data.TotalEarned + income
			end
			PlayerData.Sync(player)
			BaseManager.UpdatePlotSign(player, income)
			EconomyManager.SendStateUpdate(player)
		end
	end
end

-- Buys the brainrot riding the belt with this id. Returns true with a
-- message, or false with the reason it failed.
function EconomyManager.TryBuyBeltBrainrot(player, beltId)
	if not PlayerData.IsLoaded(player) then
		return false, "Your data is not loaded yet."
	end
	local entry = BrainrotSpawner.GetBeltBrainrotById(beltId)
	if not entry then
		return false, "That brainrot already left the belt!"
	end
	if StealManager.IsCarrying(player) then
		return false, "You are already carrying a brainrot — take it home to your base first!"
	end
	local data = PlayerData.Get(player)
	if data.Cash < entry.Cost then
		return false, "You need $" .. entry.Cost .. " for " .. BrainrotCatalog.GetDisplayName(entry.Character, entry.Mutation) .. "!"
	end
	if not BaseManager.GetPlotForPlayer(player) then
		return false, "No free base plot right now — wait for a player to leave!"
	end
	local slot = PlayerData.FindFreeSlot(player)
	if not slot then
		return false, "Your base is full! Buy another slot first."
	end

	data.Cash = data.Cash - entry.Cost
	PlayerData.AddOwnedBrainrot(player, entry.Character.Id, entry.Mutation, slot)
	BrainrotSpawner.RemoveBeltBrainrot(beltId)
	-- The purchase is the player's from this moment (it is in their
	-- save and already earns), but the creature itself rides home on
	-- the buyer's head and only takes its base slot when they carry
	-- it onto their own plot. If they cannot carry right now, it
	-- goes straight onto the base instead.
	if not StealManager.StartPurchaseCarry(player, entry.Character, entry.Mutation, slot) then
		BaseManager.PlaceBrainrotOnBase(player, entry.Character, entry.Mutation, slot)
	end
	PlayerData.Sync(player)
	EconomyManager.SendStateUpdate(player)
	return true, "You bought " .. BrainrotCatalog.GetDisplayName(entry.Character, entry.Mutation) .. " for $" .. entry.Cost .. "! Carry it home to your base!"
end

-- Sells the brainrot on one slot back for half its cost.
function EconomyManager.TrySellBrainrot(player, slotIndex)
	if not PlayerData.IsLoaded(player) then
		return false, "Your data is not loaded yet."
	end
	slotIndex = tonumber(slotIndex)
	if not slotIndex then
		return false, "Pick a brainrot to sell."
	end
	local entry = PlayerData.GetOwnedAtSlot(player, slotIndex)
	if not entry then
		return false, "That slot is empty."
	end
	local character = BrainrotCatalog.GetCharacterById(entry.CharacterId)
	if not character then
		return false, "That brainrot is gone."
	end
	local refund = math.floor(character.Cost * BrainrotCatalog.SellRefundFraction)
	local data = PlayerData.Get(player)
	data.Cash = data.Cash + refund
	-- If this brainrot is still being carried home, the carry ends
	-- here: there is nothing left to place.
	if StealManager.GetCarriedPurchaseSlot(player) == slotIndex then
		StealManager.CancelCarry(player)
	end
	PlayerData.RemoveOwnedBrainrot(player, slotIndex)
	BaseManager.RemoveBrainrotFromBase(player, slotIndex)
	PlayerData.Sync(player)
	EconomyManager.SendStateUpdate(player)
	return true, "Sold " .. BrainrotCatalog.GetDisplayName(character, entry.Mutation) .. " for $" .. refund .. "."
end

-- Buys the next extra base slot for escalating cash.
function EconomyManager.TryBuyExtraSlot(player)
	if not PlayerData.IsLoaded(player) then
		return false, "Your data is not loaded yet."
	end
	local data = PlayerData.Get(player)
	local totalSlots = PlayerData.GetTotalSlots(player)
	if not BaseManager.GetPlotForPlayer(player) then
		return false, "You have no base yet — wait for a free plot!"
	end
	if totalSlots >= BrainrotCatalog.MaxSlotCount then
		return false, "Your base already has the maximum " .. BrainrotCatalog.MaxSlotCount .. " slots."
	end
	local cost = BrainrotCatalog.GetNextSlotCost(data.SlotsBought)
	if not cost then
		return false, "Your base already has the maximum slots."
	end
	if data.Cash < cost then
		return false, "You need $" .. cost .. " for the next slot."
	end
	data.Cash = data.Cash - cost
	data.SlotsBought = data.SlotsBought + 1
	local newSlotIndex = PlayerData.GetTotalSlots(player)
	BaseManager.RevealExtraSlot(player, newSlotIndex)
	PlayerData.Sync(player)
	EconomyManager.SendStateUpdate(player)
	return true, "New base slot unlocked! You now have " .. newSlotIndex .. " slots."
end

-- Locks the player's base against stealing for 45 seconds.
function EconomyManager.TryLockBase(player)
	local ok, message = BaseManager.LockBase(player)
	if ok then
		EconomyManager.SendStateUpdate(player)
	end
	return ok, message
end

-- Sends one player their fresh snapshot (used right after they join).
function EconomyManager.SendInitialState(player)
	EconomyManager.SendStateUpdate(player)
end

function EconomyManager.Init(remoteFolder)
	remotes = remoteFolder

	remotes.RequestBuy.OnServerEvent:Connect(function(player, beltId)
		local ok, message = EconomyManager.TryBuyBeltBrainrot(player, beltId)
		sendFeedback(player, message)
	end)

	remotes.RequestSell.OnServerEvent:Connect(function(player, slotIndex)
		local ok, message = EconomyManager.TrySellBrainrot(player, slotIndex)
		sendFeedback(player, message)
	end)

	remotes.RequestBuySlot.OnServerEvent:Connect(function(player)
		local ok, message = EconomyManager.TryBuyExtraSlot(player)
		sendFeedback(player, message)
	end)

	remotes.RequestLock.OnServerEvent:Connect(function(player)
		local ok, message = EconomyManager.TryLockBase(player)
		sendFeedback(player, message)
	end)

	remotes.RequestRebirth.OnServerEvent:Connect(function(player)
		if StealManager.IsCarrying(player) then
			sendFeedback(player, "Take the brainrot you are carrying home before you rebirth!")
			return
		end
		local ok, message = RebirthManager.TryRebirth(player)
		sendFeedback(player, message)
		if ok then
			EconomyManager.SendStateUpdate(player)
		end
	end)

	-- One second of income for everyone, forever.
	task.spawn(function()
		while true do
			task.wait(1)
			tickIncomeForAllPlayers()
		end
	end)
end

return EconomyManager
