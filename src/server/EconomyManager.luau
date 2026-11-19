-- EconomyManager.luau
-- The money loop: per-second income, Prize Book milestone prizes, plot
-- sign refresh and state snapshots, plus the buy / sell / slot / lock
-- request handlers.

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
		local characterEntry = BrainrotCatalog.GetCharacterById(entry.CharacterId)
		if characterEntry then
			total += BrainrotCatalog.GetIncomePerSecond(characterEntry, entry.Mutation)
		end
	end
	return math.floor(total * RebirthManager.GetIncomeMultiplier(player))
end

function EconomyManager.BuildStateSnapshot(player)
	local data = PlayerData.Get(player)
	if not data then
		return nil
	end
	local slots = PlayerData.GetTotalSlots(player)
	local ownedList = {}
	for _, entry in ipairs(data.Owned) do
		local characterEntry = BrainrotCatalog.GetCharacterById(entry.CharacterId)
		if characterEntry then
			table.insert(ownedList, {
				Slot = entry.Slot,
				CharacterId = entry.CharacterId,
				Name = BrainrotCatalog.GetDisplayName(characterEntry, entry.Mutation),
				Rarity = characterEntry.Rarity,
				Rate = BrainrotCatalog.GetIncomePerSecond(characterEntry, entry.Mutation),
				Mutation = entry.Mutation,
				Cost = characterEntry.Cost,
			})
		end
	end
	table.sort(ownedList, function(a, b)
		return a.Slot < b.Slot
	end)
	local indexList = {}
	for characterId in pairs(data.Index) do
		table.insert(indexList, characterId)
	end
	local indexCount = PlayerData.GetIndexCount(player)
	return {
		Cash = math.floor(data.Cash),
		IncomePerSecond = EconomyManager.CalculateIncomePerSecond(player),
		Rebirths = data.Rebirths,
		TotalEarned = math.floor(data.TotalEarned),
		Slots = slots,
		NextSlotCost = (slots < BrainrotCatalog.MaxSlotCount) and BrainrotCatalog.GetNextSlotCost(data.SlotsBought) or nil,
		Owned = ownedList,
		Belt = BrainrotSpawner.GetBeltBrainrotsForClient(),
		Carrying = StealManager.GetCarrySummary(player),
		Lock = BaseManager.GetLockStatus(player),
		RebirthThreshold = BrainrotCatalog.RebirthCashThreshold,
		RebirthMultiplier = RebirthManager.GetIncomeMultiplier(player),
		Index = indexList,
		IndexCount = indexCount,
		IndexTotal = #BrainrotCatalog.Characters,
		NextMilestone = BrainrotCatalog.GetNextIndexMilestone(indexCount, data.IndexRewardsClaimed),
		ThiefActive = ThiefManager.IsThiefActive(),
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

function EconomyManager.TryBuyBeltBrainrot(player, beltId)
	local data = PlayerData.Get(player)
	if not data then
		return false
	end
	local entry = BrainrotSpawner.GetBeltBrainrotById(beltId)
	if not entry then
		showMessage(player, "That brainrot is gone!")
		return false
	end
	if StealManager.IsCarrying(player) then
		showMessage(player, "Carry what you have home first!")
		return false
	end
	local characterEntry = BrainrotCatalog.GetCharacterById(entry.CharacterId)
	if not characterEntry then
		return false
	end
	if data.Cash < characterEntry.Cost then
		showMessage(player, "Not enough cash")
		return false
	end
	local freeSlot = PlayerData.FindFreeSlot(player)
	if not freeSlot then
		showMessage(player, "Your base is full! Buy another slot.")
		return false
	end
	data.Cash -= characterEntry.Cost
	PlayerData.Sync(player)
	BrainrotSpawner.RemoveBeltBrainrot(beltId)
	StealManager.StartPurchaseCarry(player, characterEntry, entry.Mutation, freeSlot)
	showMessage(player, "Carry " .. BrainrotCatalog.GetDisplayName(characterEntry, entry.Mutation) .. " home to your base!")
	EconomyManager.SendStateUpdate(player)
	return true
end

function EconomyManager.TrySellBrainrot(player, slotIndex)
	local data = PlayerData.Get(player)
	if not data then
		return false
	end
	local owned = PlayerData.GetOwnedAtSlot(player, slotIndex)
	if not owned then
		return false
	end
	local characterEntry = BrainrotCatalog.GetCharacterById(owned.CharacterId)
	if not characterEntry then
		return false
	end
	local refund = math.floor(characterEntry.Cost * BrainrotCatalog.SellRefundFraction)
	PlayerData.RemoveOwnedBrainrot(player, slotIndex)
	BaseManager.RemoveBrainrotFromBase(player, slotIndex)
	data.Cash += refund
	PlayerData.Sync(player)
	showMessage(player, "Sold for $" .. refund)
	EconomyManager.SendStateUpdate(player)
	return true
end

function EconomyManager.TryBuyExtraSlot(player)
	local data = PlayerData.Get(player)
	if not data then
		return false
	end
	if PlayerData.GetTotalSlots(player) >= BrainrotCatalog.MaxSlotCount then
		showMessage(player, "Your base is already max size!")
		return false
	end
	local cost = BrainrotCatalog.GetNextSlotCost(data.SlotsBought)
	if not cost then
		return false
	end
	if data.Cash < cost then
		showMessage(player, "Not enough cash")
		return false
	end
	data.Cash -= cost
	data.SlotsBought += 1
	PlayerData.Sync(player)
	BaseManager.RevealExtraSlot(player, PlayerData.GetTotalSlots(player))
	showMessage(player, "New base slot unlocked!")
	EconomyManager.SendStateUpdate(player)
	return true
end

function EconomyManager.TryLockBase(player)
	if BaseManager.LockBase(player) then
		showMessage(player, "Base locked for " .. BrainrotCatalog.LockDurationSeconds .. " seconds!")
	else
		showMessage(player, "Lock is on cooldown!")
	end
	EconomyManager.SendStateUpdate(player)
	return true
end

local function payIndexMilestones(player, data)
	local nextMilestone = BrainrotCatalog.GetNextIndexMilestone(PlayerData.GetIndexCount(player), data.IndexRewardsClaimed)
	while nextMilestone and PlayerData.GetIndexCount(player) >= nextMilestone.Count do
		data.IndexRewardsClaimed += 1
		data.Cash += nextMilestone.Reward
		data.TotalEarned += nextMilestone.Reward
		showBanner(player, "PRIZE BOOK MILESTONE!")
		showMessage(player, "+$" .. nextMilestone.Reward .. " — " .. nextMilestone.Count .. " brainrots in your Prize Book!")
		nextMilestone = BrainrotCatalog.GetNextIndexMilestone(PlayerData.GetIndexCount(player), data.IndexRewardsClaimed)
	end
end

function EconomyManager.Init(remoteFolder)
	remotes = remoteFolder
	if remotes.RequestBuy then
		remotes.RequestBuy.OnServerEvent:Connect(function(player, beltId)
			if typeof(beltId) == "number" then
				EconomyManager.TryBuyBeltBrainrot(player, beltId)
			end
		end)
	end
	if remotes.RequestSell then
		remotes.RequestSell.OnServerEvent:Connect(function(player, slotIndex)
			if typeof(slotIndex) == "number" then
				EconomyManager.TrySellBrainrot(player, slotIndex)
			end
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
				showMessage(player, "Rebirth complete! Income boosted.")
			else
				showMessage(player, "Earn $" .. BrainrotCatalog.RebirthCashThreshold .. " total to rebirth.")
			end
			EconomyManager.SendStateUpdate(player)
		end)
	end
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(Players:GetPlayers()) do
				local data = PlayerData.Get(player)
				if data and PlayerData.IsLoaded(player) then
					local income = EconomyManager.CalculateIncomePerSecond(player)
					if income > 0 then
						data.Cash += income
						data.TotalEarned += income
					end
					payIndexMilestones(player, data)
					PlayerData.Sync(player)
					BaseManager.UpdatePlotSign(player, income)
					EconomyManager.SendStateUpdate(player)
				end
			end
		end
	end)
end

return EconomyManager
