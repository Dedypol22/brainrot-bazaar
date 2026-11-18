-- RebirthManager.luau
-- Rebirthing: once a player has earned the lifetime cash threshold they can
-- reset their cash, earnings and brainrot collection in exchange for a
-- permanent +25% income multiplier per rebirth. Bought base slots are kept.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local RebirthManager = {}

function RebirthManager.GetIncomeMultiplier(player)
	local data = PlayerData.Get(player)
	if not data then
		return 1
	end
	return 1 + BrainrotCatalog.RebirthIncomeBonus * data.Rebirths
end

function RebirthManager.CanRebirth(player)
	local data = PlayerData.Get(player)
	return data ~= nil and data.TotalEarned >= BrainrotCatalog.RebirthCashThreshold
end

function RebirthManager.TryRebirth(player)
	if not RebirthManager.CanRebirth(player) then
		return false
	end
	local data = PlayerData.Get(player)
	data.Rebirths += 1
	data.Cash = BrainrotCatalog.StartingCash
	data.TotalEarned = 0
	PlayerData.ClearOwnedBrainrots(player)
	BaseManager.ClearAllBaseBrainrots(player)
	PlayerData.Sync(player)
	return true
end

return RebirthManager
