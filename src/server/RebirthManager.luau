-- RebirthManager.luau (server module)
-- Owns rebirthing: once a player has earned one million cash since their
-- last rebirth, they may reset their cash and brainrots for a permanent
-- +25% income multiplier per rebirth, stacking forever. The count is saved
-- with the rest of the player's data.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local RebirthManager = {}

-- Permanent income multiplier from a player's rebirth count.
function RebirthManager.GetIncomeMultiplier(player)
	local data = PlayerData.Get(player)
	local rebirths = 0
	if data then
		rebirths = data.Rebirths
	end
	return 1 + BrainrotCatalog.RebirthIncomeBonus * rebirths
end

-- Can this player rebirth right now?
function RebirthManager.CanRebirth(player)
	local data = PlayerData.Get(player)
	if not data then
		return false
	end
	return data.TotalEarned >= BrainrotCatalog.RebirthCashThreshold
end

-- Resets cash and brainrots, banks one rebirth. Returns true with a
-- message, or false with the reason it cannot happen yet.
function RebirthManager.TryRebirth(player)
	local data = PlayerData.Get(player)
	if not data then
		return false, "Your data is not loaded yet."
	end
	if data.TotalEarned < BrainrotCatalog.RebirthCashThreshold then
		local missing = BrainrotCatalog.RebirthCashThreshold - data.TotalEarned
		return false, "Earn $" .. missing .. " more to rebirth!"
	end

	BaseManager.ClearAllBaseBrainrots(player)
	PlayerData.ClearOwnedBrainrots(player)
	data.Cash = BrainrotCatalog.StartingCash
	data.TotalEarned = 0
	data.Rebirths = data.Rebirths + 1
	PlayerData.Sync(player)

	return true, "REBIRTH " .. data.Rebirths .. "! Income is now +" .. (data.Rebirths * 25) .. "% forever!"
end

return RebirthManager
