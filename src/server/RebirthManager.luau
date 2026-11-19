-- RebirthManager.luau
-- Rebirth: at $1,000,000 total earned, reset cash and brainrots for a
-- permanent +25% income multiplier per rebirth. The Prize Book survives.

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
	if not data then
		return false
	end
	return data.TotalEarned >= BrainrotCatalog.RebirthCashThreshold
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
	-- SlotsBought, Index and IndexRewardsClaimed are kept on purpose.
	PlayerData.Sync(player)
	return true
end

return RebirthManager
