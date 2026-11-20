-- EconomyManager: income ticks, buying, selling, slots, locks, rebirth and state snapshots.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local BrainrotSpawner = require(script.Parent:WaitForChild("BrainrotSpawner"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local RebirthManager = require(script.Parent:WaitForChild("RebirthManager"))
local StealManager = require(script.Parent:WaitForChild("StealManager"))
local ThiefManager = require(script.Parent:WaitForChild("ThiefManager"))

local EconomyManager = {}

local remotes = nil
local initialized = false

local function showMessage(player, message)
	if remotes and remotes.ShowMessage then
		remotes.ShowMessage:FireClient(player, message)
	end
end

local function showBanner(player, message)
	if remotes and remotes.ShowBanner then
		remotes.ShowBanner:FireClient(player, message)
	end
end

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

	local income = EconomyManager.CalculateIncomePerSecond(player)
	local slots = PlayerData.GetTotalSlots(player)

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

	local index = {}
	for characterId in pairs(data.Index) do
		table.insert(index, characterId)
	end
	table.sort(index)

	local nextSlotCost = nil
	if slots < BrainrotCatalog.MaxSlotCount then
		nextSlotCost = BrainrotCatalog.GetNextSlotCost(data.SlotsBought)
	end

	local indexCount = PlayerData.GetIndexCount(player)

	return {
		Cash = math.floor(data.Cash),
		IncomePerSecond = income,
		Rebirths = data.Rebirths,
		TotalEarned = math.floor(data.TotalEarned),
		Slots = slots,
		NextSlotCost = nextSlotCost,
		Owned = owned,
		Belt = BrainrotSpawner.GetBeltBrainrotsForClient(),
		Carrying = StealManager.GetCarrySummary(player),
		Lock = BaseManager.GetLockStatus(player),
		RebirthThreshold = BrainrotCatalog.RebirthCashThreshold,
		RebirthMultiplier = RebirthManager.GetIncomeMultiplier(player),
		Index = index,
		IndexCount = indexCount,
		IndexTotal = #BrainrotCatalog.Characters,
		NextMilestone = BrainrotCatalog.GetNextIndexMilestone(indexCount, data.IndexRewardsClaimed),
		ThiefActive = ThiefManager.IsThiefActive(),
	}
end

function EconomyManager.SendStateUpdate(player)
	local snapshot = EconomyManager.BuildStateSnapshot(player)
	if not snapshot then
		return
	end
	if remotes and remotes.StateUpdate then
		remotes.StateUpdate:FireClient(player, snapshot)
	end
end

function EconomyManager.SendInitialState(player)
	EconomyManager.SendStateUpdate(player)
end

function EconomyManager.TryBuyBeltBrainrot(player, beltId)
	local data = PlayerData.Get(player)
	if not data then
		return
	end
	if StealManager.IsCarrying(player) then
		showMessage(player, "You are already carrying a brainrot!")
		return
	end

	local entry = BrainrotSpawner.GetBeltBrainrotById(beltId)
	if not entry then
		showMessage(player, "That brainrot is already gone!")
		return
	end
	local character = BrainrotCatalog.GetCharacterById(entry.CharacterId)
	if not character then
		return
	end
	if data.Cash < character.Cost then
		showMessage(player, "Not enough cash!")
		return
	end

	local freeSlot = PlayerData.FindFreeSlot(player)
	if not freeSlot then
		showMessage(player, "Your base is full! Buy another slot.")
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
	local owned = PlayerData.GetOwnedAtSlot(player, slotIndex)
	if not owned then
		showMessage(player, "Nothing to sell there.")
		return
	end
	local character = BrainrotCatalog.GetCharacterById(owned.CharacterId)
	if not character then
		return
	end

	local refund = math.floor(character.Cost * BrainrotCatalog.SellRefundFraction)
	data.Cash += refund
	PlayerData.RemoveOwnedBrainrot(player, slotIndex)
	BaseManager.RemoveBrainrotFromBase(player, slotIndex)
	PlayerData.Sync(player)
	showMessage(player, "Sold for $" .. tostring(refund) .. ".")
	EconomyManager.SendStateUpdate(player)
end

function EconomyManager.TryBuyExtraSlot(player)
	local data = PlayerData.Get(player)
	if not data then
		return
	end
	local slots = PlayerData.GetTotalSlots(player)
	if slots >= BrainrotCatalog.MaxSlotCount then
		showMessage(player, "Every base slot is already unlocked!")
		return
	end

	local cost = BrainrotCatalog.GetNextSlotCost(data.SlotsBought)
	if not cost then
		return
	end
	if data.Cash < cost then
		showMessage(player, "Not enough cash for another slot!")
		return
	end

	data.Cash -= cost
	data.SlotsBought += 1
	local newTotal = PlayerData.GetTotalSlots(player)
	BaseManager.RevealExtraSlot(player, newTotal)
	PlayerData.Sync(player)
	showMessage(player, "New base slot unlocked!")
	EconomyManager.SendStateUpdate(player)
end

function EconomyManager.TryLockBase(player)
	if BaseManager.LockBase(player) then
		showMessage(player, "Base locked for " .. tostring(BrainrotCatalog.LockDurationSeconds) .. " seconds!")
	else
		showMessage(player, "Your lock is on cooldown!")
	end
	EconomyManager.SendStateUpdate(player)
end

local function refreshAfterRebirth(player)
	EconomyManager.SendStateUpdate(player)
end

function EconomyManager.Init(remoteFolder)
	if initialized then
		return
	end
	initialized = true
	remotes = remoteFolder

	if remotes.RequestBuy then
		remotes.RequestBuy.OnServerEvent:Connect(function(player, beltId)
			EconomyManager.TryBuyBeltBrainrot(player, beltId)
		end)
	end
	if remotes.RequestSell then
		remotes.RequestSell.OnServerEvent:Connect(function(player, slotIndex)
			EconomyManager.TrySellBrainrot(player, slotIndex)
		end)
	end
	if remotes.RequestBuySlot then
		remotes.RequestBuySlot.OnServerEvent:Connect(function(player)
			EconomyManager.TryBuyExtraSlot(player)
		end)
	end
	if remotes.RequestLock then
		remotes.RequestLock.OnServerEvent:Connect(function(player)
			EconomyManager.TryLockBase(player)
		end)
	end
	if remotes.RequestRebirth then
		remotes.RequestRebirth.OnServerEvent:Connect(function(player)
			if RebirthManager.TryRebirth(player) then
				showBanner(player, "REBIRTH!")
				showMessage(player, "You rebirthed! Income bonus is now +" .. tostring(math.floor((RebirthManager.GetIncomeMultiplier(player) - 1) * 100)) .. "%.")
				refreshAfterRebirth(player)
			else
				showMessage(player, "You need $" .. tostring(BrainrotCatalog.RebirthCashThreshold) .. " total earned to rebirth.")
			end
		end)
	end

	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(Players:GetPlayers()) do
				local data = PlayerData.Get(player)
				if data then
					local income = EconomyManager.CalculateIncomePerSecond(player)
					data.Cash += income
					data.TotalEarned += income

					local indexCount = PlayerData.GetIndexCount(player)
					local nextMilestone = BrainrotCatalog.GetNextIndexMilestone(indexCount, data.IndexRewardsClaimed)
					while nextMilestone and indexCount >= nextMilestone.Count do
						data.IndexRewardsClaimed += 1
						data.Cash += nextMilestone.Reward
						data.TotalEarned += nextMilestone.Reward
						showBanner(player, "PRIZE BOOK MILESTONE!")
						showMessage(player, "+$" .. tostring(nextMilestone.Reward) .. " — " .. tostring(nextMilestone.Count) .. " brainrots in your Prize Book!")
						indexCount = PlayerData.GetIndexCount(player)
						nextMilestone = BrainrotCatalog.GetNextIndexMilestone(indexCount, data.IndexRewardsClaimed)
					end

					PlayerData.Sync(player)
					BaseManager.UpdatePlotSign(player, income)
					EconomyManager.SendStateUpdate(player)
				end
			end
		end
	end)
end

return EconomyManager
