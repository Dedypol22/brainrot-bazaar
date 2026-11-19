-- StealManager.luau
-- Carrying: bought brainrots are carried home over the buyer's head, and
-- stolen brainrots are carried the same way. A freshly robbed base is
-- shielded for 30 seconds, and a locked base cannot be robbed at all.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local BrainrotSpawner = require(script.Parent:WaitForChild("BrainrotSpawner"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local StealManager = {}

local CARRY_HEIGHT = 6.5

local carries = {}
local remotes = nil
local carryFolder = nil

local function showMessage(player, message)
	if remotes and remotes.ShowMessage then
		remotes.ShowMessage:FireClient(player, message)
	end
end

local function headPosition(player)
	local characterModel = player.Character
	if not characterModel then
		return nil
	end
	local root = characterModel:FindFirstChild("HumanoidRootPart")
	if root then
		return root.Position
	end
	return nil
end

local function moveModelTo(model, position)
	if not model or not model.PrimaryPart then
		return
	end
	local delta = position - model.PrimaryPart.Position
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Position += delta
		end
	end
	model.PrimaryPart.Position = position
end

local function destroyCarryModel(carry)
	if carry and carry.Model then
		carry.Model:Destroy()
		carry.Model = nil
	end
end

local function completeCarry(player, carry)
	carries[player] = nil
	destroyCarryModel(carry)
	if carry.Victim then
		local victim = carry.Victim
		-- Remove from the victim first, then hand it to the thief.
		PlayerData.RemoveOwnedBrainrot(victim, carry.VictimSlot)
		BaseManager.RemoveBrainrotFromBase(victim, carry.VictimSlot)
	end
	PlayerData.AddOwnedBrainrot(player, carry.Character.Id, carry.Mutation, carry.Slot)
	BaseManager.PlaceBrainrotOnBase(player, carry.Character, carry.Mutation, carry.Slot)
end

local function restoreSteal(carry)
	local victim = carry.Victim
	if not victim then
		return
	end
	if victim.Parent and PlayerData.Get(victim) then
		local characterEntry = carry.Character
		if characterEntry and not PlayerData.GetOwnedAtSlot(victim, carry.VictimSlot) then
			-- The data entry was never removed during the carry; only the
			-- base model was. Rebuild the model if it is missing.
			if not BaseManager.GetBaseModelAtSlot(victim, carry.VictimSlot) then
				BaseManager.PlaceBrainrotOnBase(victim, characterEntry, carry.Mutation, carry.VictimSlot)
			end
		end
	end
end

function StealManager.IsCarrying(player)
	return carries[player] ~= nil
end

function StealManager.TryStealBrainrot(thief, victim, slotIndex)
	if not thief or not victim or thief == victim then
		return false
	end
	if StealManager.IsCarrying(thief) then
		return false
	end
	local victimData = PlayerData.Get(victim)
	local thiefData = PlayerData.Get(thief)
	if not victimData or not thiefData then
		return false
	end
	local owned = PlayerData.GetOwnedAtSlot(victim, slotIndex)
	if not owned then
		return false
	end
	if BaseManager.IsBaseLocked(victim) then
		showMessage(thief, "That base is locked!")
		return false
	end
	if os.time() - (victimData.LastStolenAt or 0) < BrainrotCatalog.StealShieldSeconds then
		showMessage(thief, "That base is shielded — it was just robbed!")
		return false
	end
	local freeSlot = PlayerData.FindFreeSlot(thief)
	if not freeSlot then
		showMessage(thief, "Your base is full!")
		return false
	end
	local characterEntry = BrainrotCatalog.GetCharacterById(owned.CharacterId)
	if not characterEntry then
		return false
	end
	-- Stamp the shield the moment the grab succeeds.
	victimData.LastStolenAt = os.time()
	BaseManager.RemoveBrainrotFromBase(victim, slotIndex)
	local startPosition = headPosition(thief) or Vector3.new(0, 10, 0)
	local model = BrainrotSpawner.BuildBrainrotModel(characterEntry, owned.Mutation, startPosition + Vector3.new(0, CARRY_HEIGHT, 0), 0, false)
	model.Parent = carryFolder or Workspace
	carries[thief] = {
		Model = model,
		Character = characterEntry,
		Mutation = owned.Mutation,
		Slot = freeSlot,
		Victim = victim,
		VictimSlot = slotIndex,
	}
	showMessage(victim, "Your " .. BrainrotCatalog.GetDisplayName(characterEntry, owned.Mutation) .. " is being stolen!")
	return true
end

function StealManager.TryStealFromClick(clickingPlayer, ownerPlayer, slotIndex)
	return StealManager.TryStealBrainrot(clickingPlayer, ownerPlayer, slotIndex)
end

function StealManager.StartPurchaseCarry(player, characterEntry, mutationName, slotIndex)
	local startPosition = headPosition(player) or Vector3.new(0, 10, 0)
	local model = BrainrotSpawner.BuildBrainrotModel(characterEntry, mutationName, startPosition + Vector3.new(0, CARRY_HEIGHT, 0), 0, false)
	model.Parent = carryFolder or Workspace
	carries[player] = {
		Model = model,
		Character = characterEntry,
		Mutation = mutationName,
		Slot = slotIndex,
		Victim = nil,
		VictimSlot = nil,
	}
	return true
end

function StealManager.GetCarrySummary(player)
	local carry = carries[player]
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
	local carry = carries[player]
	if carry and carry.Victim == nil then
		return carry.Slot
	end
	return nil
end

function StealManager.CancelCarry(player)
	local carry = carries[player]
	if not carry then
		return
	end
	carries[player] = nil
	if carry.Victim then
		restoreSteal(carry)
	end
	destroyCarryModel(carry)
end

function StealManager.Init(remoteFolder)
	remotes = remoteFolder
	carryFolder = Workspace:FindFirstChild("Carried")
	if not carryFolder then
		carryFolder = Instance.new("Folder")
		carryFolder.Name = "Carried"
		carryFolder.Parent = Workspace
	end
	if remotes and remotes.RequestSteal then
		remotes.RequestSteal.OnServerEvent:Connect(function(player, ownerPlayer, slotIndex)
			if typeof(ownerPlayer) == "Instance" and ownerPlayer:IsA("Player") and typeof(slotIndex) == "number" then
				StealManager.TryStealBrainrot(player, ownerPlayer, slotIndex)
			end
		end)
	end
	Players.PlayerRemoving:Connect(function(player)
		local carry = carries[player]
		if carry then
			carries[player] = nil
			if carry.Victim then
				restoreSteal(carry)
			end
			destroyCarryModel(carry)
		end
		-- Anyone carrying something stolen from this player keeps the
		-- carry, but the victim reference is now stale; the completion
		-- path tolerates a victim who has left.
	end)
	RunService.Heartbeat:Connect(function()
		for player, carry in pairs(carries) do
			if not player.Parent then
				carries[player] = nil
				if carry.Victim then
					restoreSteal(carry)
				end
				destroyCarryModel(carry)
			elseif not carry.Model or not carry.Model.Parent then
				carries[player] = nil
				if carry.Victim then
					restoreSteal(carry)
				end
			else
				local position = headPosition(player)
				if position then
					moveModelTo(carry.Model, position + Vector3.new(0, CARRY_HEIGHT, 0))
					if BaseManager.IsPositionInsideOwnBase(player, position) then
						completeCarry(player, carry)
					end
				end
			end
		end
	end)
end

return StealManager
