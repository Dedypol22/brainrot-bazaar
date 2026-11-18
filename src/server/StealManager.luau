-- StealManager.luau
-- Carrying: the heart of the bazaar. Buying a brainrot from the belt and
-- stealing one from another player's base both work the same way — the
-- brainrot is lifted over the carrier's head and only becomes theirs when
-- they dash back inside their own base with it. A steal that never makes it
-- home (the thief leaves, or the carry is interrupted) is restored to its
-- victim.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local BrainrotSpawner = require(script.Parent:WaitForChild("BrainrotSpawner"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local StealManager = {}

local CARRY_HEIGHT = 6.5

-- [userId] = { Model, Character, Mutation, Slot, Victim, VictimSlot }
-- Victim is nil for a belt purchase and the robbed player for a steal.
local carries = {}

local function headPositionOf(player)
	local character = player.Character
	if not character then
		return nil
	end
	local head = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
	if head then
		return head.Position
	end
	return nil
end

local function buildCarryModel(player, character, mutationName)
	local headPosition = headPositionOf(player) or Vector3.new(0, 8, 0)
	local model = BrainrotSpawner.BuildBrainrotModel(
		character,
		mutationName,
		headPosition + Vector3.new(0, CARRY_HEIGHT, 0),
		0,
		false
	)
	model.Parent = Workspace
	return model
end

-- Ending a carry without delivering it: a stolen brainrot goes back onto its
-- victim's base (its save entry was never removed), a purchase simply ends.
local function restoreCarry(carry)
	if carry.Victim then
		local victim = carry.Victim
		if victim.Parent and PlayerData.GetOwnedAtSlot(victim, carry.VictimSlot) then
			BaseManager.PlaceBrainrotOnBase(victim, carry.Character, carry.Mutation, carry.VictimSlot)
		end
	end
	if carry.Model then
		carry.Model:Destroy()
	end
end

local function completeCarry(player, carry)
	if carry.Victim then
		PlayerData.RemoveOwnedBrainrot(carry.Victim, carry.VictimSlot)
	end
	PlayerData.AddOwnedBrainrot(player, carry.Character.Id, carry.Mutation, carry.Slot)
	BaseManager.PlaceBrainrotOnBase(player, carry.Character, carry.Mutation, carry.Slot)
	if carry.Model then
		carry.Model:Destroy()
	end
	carries[player.UserId] = nil
end

-- Queries ---------------------------------------------------------------------------

function StealManager.IsCarrying(player)
	return carries[player.UserId] ~= nil
end

function StealManager.GetCarrySummary(player)
	local carry = carries[player.UserId]
	if not carry then
		return nil
	end
	return {
		Name = BrainrotCatalog.GetDisplayName(carry.Character, carry.Mutation),
		Rate = BrainrotCatalog.GetIncomePerSecond(carry.Character, carry.Mutation),
		Steal = carry.Victim ~= nil,
	}
end

function StealManager.GetCarriedPurchaseSlot(player)
	local carry = carries[player.UserId]
	if carry and carry.Victim == nil then
		return carry.Slot
	end
	return nil
end

-- Starting carries ---------------------------------------------------------------------

function StealManager.StartPurchaseCarry(player, character, mutationName, slotIndex)
	if carries[player.UserId] then
		return
	end
	local model = buildCarryModel(player, character, mutationName)
	carries[player.UserId] = {
		Model = model,
		Character = character,
		Mutation = mutationName,
		Slot = slotIndex,
		Victim = nil,
		VictimSlot = nil,
	}
end

function StealManager.TryStealBrainrot(thief, victim, slotIndex)
	if thief == victim then
		return false
	end
	if carries[thief.UserId] then
		return false
	end
	local victimEntry = PlayerData.GetOwnedAtSlot(victim, slotIndex)
	if not victimEntry then
		return false
	end
	if BaseManager.IsBaseLocked(victim) then
		return false
	end
	local freeSlot = PlayerData.FindFreeSlot(thief)
	if not freeSlot then
		return false
	end
	local character = BrainrotCatalog.GetCharacterById(victimEntry.CharacterId)
	if not character then
		return false
	end

	BaseManager.RemoveBrainrotFromBase(victim, slotIndex)
	local model = buildCarryModel(thief, character, victimEntry.Mutation)
	carries[thief.UserId] = {
		Model = model,
		Character = character,
		Mutation = victimEntry.Mutation,
		Slot = freeSlot,
		Victim = victim,
		VictimSlot = slotIndex,
	}
	return true
end

function StealManager.TryStealFromClick(clickingPlayer, ownerPlayer, slotIndex)
	return StealManager.TryStealBrainrot(clickingPlayer, ownerPlayer, slotIndex)
end

function StealManager.CancelCarry(player)
	local carry = carries[player.UserId]
	if not carry then
		return
	end
	restoreCarry(carry)
	carries[player.UserId] = nil
end

-- The watch loop -------------------------------------------------------------------------

local function watchCarries()
	while true do
		task.wait(0.1)
		local arrived = {}
		for userId, carry in pairs(carries) do
			local player = Players:GetPlayerByUserId(userId)
			if not player then
				restoreCarry(carry)
				carries[userId] = nil
			elseif not carry.Model or not carry.Model.Parent then
				restoreCarry(carry)
				carries[userId] = nil
			else
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				local headPosition = headPositionOf(player)
				if headPosition then
					local rotation = carry.Model:GetPivot().Rotation
					carry.Model:PivotTo(
						CFrame.new(headPosition + Vector3.new(0, CARRY_HEIGHT, 0)) * rotation
					)
				end
				if root and BaseManager.IsPositionInsideOwnBase(player, root.Position) then
					table.insert(arrived, player)
				end
			end
		end
		for _, player in ipairs(arrived) do
			local carry = carries[player.UserId]
			if carry then
				completeCarry(player, carry)
			end
		end
	end
end

function StealManager.Init(remoteFolder)
	local remotes = remoteFolder
	if remotes and remotes.RequestSteal then
		remotes.RequestSteal.OnServerEvent:Connect(function(player, ownerPlayer, slotIndex)
			if typeof(ownerPlayer) == "Instance" and ownerPlayer:IsA("Player")
				and typeof(slotIndex) == "number" then
				StealManager.TryStealBrainrot(player, ownerPlayer, slotIndex)
			end
		end)
	end

	Players.PlayerRemoving:Connect(function(player)
		local carry = carries[player.UserId]
		if carry then
			restoreCarry(carry)
			carries[player.UserId] = nil
		end
	end)

	task.spawn(watchCarries)
end

return StealManager
