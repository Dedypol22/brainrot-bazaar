-- EconomyManager.luau
-- The money side of Brainrot Bazaar: the per-second income tick, buying from
-- the belt, selling, buying extra base slots, locking the base, and the
-- state snapshots that keep every client's HUD in sync. All client requests
-- arrive through the RemoteEvents Main created; every answer goes back as a
-- fresh snapshot on StateUpdate.

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

local function showMessage(player, message)
	if remotes and remotes.ShowMessage then
		remotes.ShowMessage:FireClient(player, message)
	end
end

-- Income and snapshots -----------------------------------------------------------------

function EconomyManager.CalculateIncomePerSecond(player)
	local data = PlayerData.Get(player)
	if not data then
		return 0
	end
	local base = 0
	for _, entry in ipairs(data.Owned) do
		local character = BrainrotCatalog.GetCharacterById(entry.CharacterId)
		if character then
			base += BrainrotCatalog.GetIncomePerSecond(character, entry.Mutation)
		end
	end
	return math.floor(base * RebirthManager.GetIncomeMultiplier(player))
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
		BaseManager.UpdatePlotSign(player, snapshot.IncomePerSecond)
		remotes.StateUpdate:FireClient(player, snapshot)
	end
end

function EconomyManager.SendInitialState(player)
	EconomyManager.SendStateUpdate(player)
end

-- Trades -----------------------------------------------------------------------------------

function EconomyManager.TryBuyBeltBrainrot(player, beltId)
	local data = PlayerData.Get(player)
	if not data then
		return
	end
	local beltEntry = BrainrotSpawner.GetBeltBrainrotById(beltId)
	if not beltEntry then
		showMessage(player, "That brainrot already rolled away!")
		return
	end
	if StealManager.IsCarrying(player) then
		showMessage(player, "Your hands are full — carry that one home first!")
		return
	end
	local character = BrainrotCatalog.GetCharacterById(beltEntry.CharacterId)
	if not character then
		return
	end
	if data.Cash < character.Cost then
		showMessage(player, "Not enough cash!")
		return
	end
	local freeSlot = PlayerData.FindFreeSlot(player)
	if not freeSlot then
		showMessage(player, "Your base is full!")
		return
	end

	data.Cash -= character.Cost
	PlayerData.Sync(player)
	BrainrotSpawner.RemoveBeltBrainrot(beltId)
	StealManager.StartPurchaseCarry(player, character, beltEntry.Mutation, freeSlot)
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
	showMessage(player, "Sold " .. character.Name .. " for $" .. refund)
	EconomyManager.SendStateUpdate(player)
end

function EconomyManager.TryBuyExtraSlot(player)
	local data = PlayerData.Get(player)
	if not data then
		return
	end
	if PlayerData.GetTotalSlots(player) >= BrainrotCatalog.MaxSlotCount then
		showMessage(player, "You already own every slot!")
		return
	end
	local cost = BrainrotCatalog.GetNextSlotCost(data.SlotsBought)
	if not cost then
		return
	end
	if data.Cash < cost then
		showMessage(player, "Not enough cash!")
		return
	end
	data.Cash -= cost
	data.SlotsBought += 1
	PlayerData.Sync(player)
	BaseManager.RevealExtraSlot(player, PlayerData.GetTotalSlots(player))
	showMessage(player, "New base slot unlocked!")
	EconomyManager.SendStateUpdate(player)
end

function EconomyManager.TryLockBase(player)
	if BaseManager.LockBase(player) then
		showMessage(player, "Base locked! Nobody can steal from you for a while.")
	else
		showMessage(player, "Your lock is still recharging!")
	end
	EconomyManager.SendStateUpdate(player)
end

-- Wiring --------------------------------------------------------------------------------------

local function runIncomeLoop()
	while true do
		task.wait(1)
		for _, player in ipairs(Players:GetPlayers()) do
			if PlayerData.IsLoaded(player) then
				local data = PlayerData.Get(player)
				local income = EconomyManager.CalculateIncomePerSecond(player)
				if data and income > 0 then
					data.Cash += income
					data.TotalEarned += income
					PlayerData.Sync(player)
				end
				EconomyManager.SendStateUpdate(player)
			end
		end
	end
end

function EconomyManager.Init(remoteFolder)
	remotes = remoteFolder

	remotes.RequestBuy.OnServerEvent:Connect(function(player, beltId)
		if typeof(beltId) == "number" then
			EconomyManager.TryBuyBeltBrainrot(player, beltId)
		end
	end)
	remotes.RequestSell.OnServerEvent:Connect(function(player, slotIndex)
		if typeof(slotIndex) == "number" then
			EconomyManager.TrySellBrainrot(player, slotIndex)
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
			showMessage(player, "Reborn! Your income is permanently higher.")
		else
			showMessage(player, "Earn $" .. BrainrotCatalog.RebirthCashThreshold .. " total to rebirth!")
		end
		EconomyManager.SendStateUpdate(player)
	end)

	task.spawn(runIncomeLoop)
end

return EconomyManager
