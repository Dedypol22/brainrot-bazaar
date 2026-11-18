-- EconomyManager.luau
-- The money brain of Brainrot Bazaar: per-second income, buying from the
-- belt, selling, extra slots, locking and rebirth requests. Everything the
-- client can ask for arrives here through the remotes Main created, and
-- everything the client sees leaves as a state snapshot.

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

local function notify(player, message)
	if remotes and remotes.ShowMessage then
		remotes.ShowMessage:FireClient(player, message)
	end
end

-- ---------------------------------------------------------------------------
-- Income and snapshots
-- ---------------------------------------------------------------------------

function EconomyManager.CalculateIncomePerSecond(player)
	local data = PlayerData.Get(player)
	if not data then
		return 0
	end
	local total = 0
	for _, entry in ipairs(data.Owned) do
		local character = BrainrotCatalog.GetCharacterById(entry.CharacterId)
		if character then
			total += BrainrotCatalog.GetIncomePerSecond(character, entry.Mutation)
		end
	end
	return math.floor(total * RebirthManager.GetIncomeMultiplier(player))
end

function EconomyManager.BuildStateSnapshot(player)
	local data = PlayerData.Get(player)
	if not data then
		return nil
	end
	local totalSlots = PlayerData.GetTotalSlots(player)
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
	return {
		Cash = math.floor(data.Cash),
		IncomePerSecond = EconomyManager.CalculateIncomePerSecond(player),
		Rebirths = data.Rebirths,
		TotalEarned = math.floor(data.TotalEarned),
		Slots = totalSlots,
		NextSlotCost = (totalSlots < BrainrotCatalog.MaxSlotCount)
			and BrainrotCatalog.GetNextSlotCost(data.SlotsBought) or nil,
		Owned = owned,
		Belt = BrainrotSpawner.GetBeltBrainrotsForClient(),
		Carrying = StealManager.GetCarrySummary(player),
		Lock = BaseManager.GetLockStatus(player),
		RebirthThreshold = BrainrotCatalog.RebirthCashThreshold,
		RebirthMultiplier = RebirthManager.GetIncomeMultiplier(player),
	}
end

function EconomyManager.SendStateUpdate(player)
	if not remotes or not remotes.StateUpdate then
		return
	end
	local snapshot = EconomyManager.BuildStateSnapshot(player)
	if snapshot then
		remotes.StateUpdate:FireClient(player, snapshot)
	end
end

function EconomyManager.SendInitialState(player)
	EconomyManager.SendStateUpdate(player)
end

-- ---------------------------------------------------------------------------
-- Actions
-- ---------------------------------------------------------------------------

function EconomyManager.TryBuyBeltBrainrot(player, beltId)
	local data = PlayerData.Get(player)
	if not data then
		return
	end
	local entry = BrainrotSpawner.GetBeltBrainrotById(beltId)
	if not entry then
		notify(player, "That brainrot already rolled away!")
		return
	end
	if StealManager.IsCarrying(player) then
		notify(player, "You are already carrying a brainrot!")
		return
	end
	local character = BrainrotCatalog.GetCharacterById(entry.CharacterId)
	if not character then
		return
	end
	if data.Cash < character.Cost then
		notify(player, "Not enough cash!")
		return
	end
	local freeSlot = PlayerData.FindFreeSlot(player)
	if not freeSlot then
		notify(player, "Your base is full! Sell something or buy a slot.")
		return
	end
	data.Cash -= character.Cost
	BrainrotSpawner.RemoveBeltBrainrot(beltId)
	StealManager.StartPurchaseCarry(player, character, entry.Mutation, freeSlot)
	PlayerData.Sync(player)
	EconomyManager.SendStateUpdate(player)
end

function EconomyManager.TrySellBrainrot(player, slotIndex)
	local data = PlayerData.Get(player)
	if not data then
		return
	end
	local entry = PlayerData.GetOwnedAtSlot(player, slotIndex)
	if not entry then
		return
	end
	local character = BrainrotCatalog.GetCharacterById(entry.CharacterId)
	if not character then
		return
	end
	local refund = math.floor(character.Cost * BrainrotCatalog.SellRefundFraction)
	data.Cash += refund
	PlayerData.RemoveOwnedBrainrot(player, slotIndex)
	BaseManager.RemoveBrainrotFromBase(player, slotIndex)
	PlayerData.Sync(player)
	EconomyManager.SendStateUpdate(player)
end

function EconomyManager.TryBuyExtraSlot(player)
	local data = PlayerData.Get(player)
	if not data then
		return
	end
	if PlayerData.GetTotalSlots(player) >= BrainrotCatalog.MaxSlotCount then
		notify(player, "Your base is already at max size!")
		return
	end
	local cost = BrainrotCatalog.GetNextSlotCost(data.SlotsBought)
	if not cost then
		return
	end
	if data.Cash < cost then
		notify(player, "Not enough cash for another slot!")
		return
	end
	data.Cash -= cost
	data.SlotsBought += 1
	BaseManager.RevealExtraSlot(player, PlayerData.GetTotalSlots(player))
	PlayerData.Sync(player)
	EconomyManager.SendStateUpdate(player)
end

function EconomyManager.TryLockBase(player)
	if BaseManager.LockBase(player) then
		notify(player, "Base locked! Nobody can steal for a while.")
	else
		notify(player, "Lock is still on cooldown!")
	end
	EconomyManager.SendStateUpdate(player)
end

-- ---------------------------------------------------------------------------
-- Wiring
-- ---------------------------------------------------------------------------

local function runIncomeLoop()
	while true do
		task.wait(1)
		for _, player in ipairs(Players:GetPlayers()) do
			local data = PlayerData.Get(player)
			if data then
				local income = EconomyManager.CalculateIncomePerSecond(player)
				if income > 0 then
					data.Cash += income
					data.TotalEarned += income
				end
				PlayerData.Sync(player)
				BaseManager.UpdatePlotSign(player, income)
				EconomyManager.SendStateUpdate(player)
			end
		end
	end
end

function EconomyManager.Init(remoteFolder)
	remotes = remoteFolder

	remotes.RequestBuy.OnServerEvent:Connect(function(player, beltId)
		if typeof(beltId) == "number" then
			EconomyManager.TryBuyBeltBrainrot(player, math.floor(beltId))
		end
	end)
	remotes.RequestSell.OnServerEvent:Connect(function(player, slotIndex)
		if typeof(slotIndex) == "number" then
			EconomyManager.TrySellBrainrot(player, math.floor(slotIndex))
		end
	end)
	remotes.RequestBuySlot.OnServerEvent:Connect(function(player)
		EconomyManager.TryBuyExtraSlot(player)
	end)
	remotes.RequestLock.OnServerEvent:Connect(function(player)
		EconomyManager.TryLockBase(player)
	end)
	remotes.RequestRebirth.OnServerEvent:Connect(function(player)
		if RebirthManager.TryRebirth(player) then
			notify(player, "Rebirth complete! Income boosted forever.")
		else
			notify(player, "Earn $1,000,000 total before you can rebirth!")
		end
		EconomyManager.SendStateUpdate(player)
	end)

	task.spawn(runIncomeLoop)
end

return EconomyManager
