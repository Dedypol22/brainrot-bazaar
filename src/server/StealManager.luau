-- StealManager: purchase and steal carries, base arrival and the post-robbery shield.

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
local initialized = false

local function showMessage(player, message)
	if remotes and remotes.ShowMessage then
		remotes.ShowMessage:FireClient(player, message)
	end
end

local function getRootPosition(player)
	local character = player.Character
	if character then
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			return root.Position
		end
	end
	return nil
end

local function carryPosition(player)
	local root = getRootPosition(player)
	if root then
		return root + Vector3.new(0, CARRY_HEIGHT, 0)
	end
	return Vector3.new(0, CARRY_HEIGHT, 0)
end

local function buildCarryModel(player, character, mutationName)
	local model = BrainrotSpawner.BuildBrainrotModel(
		character,
		mutationName,
		carryPosition(player),
		0,
		false,
		nil
	)
	model.Parent = Workspace
	return model
end

local function clearCarry(player)
	local carry = carries[player]
	if not carry then
		return
	end
	if carry.Model then
		carry.Model:Destroy()
	end
	carries[player] = nil
end

local function restoreStolen(player)
	local carry = carries[player]
	if not carry then
		return
	end
	local victim = carry.Victim
	if victim and victim.Parent and carry.Character then
		BaseManager.PlaceBrainrotOnBase(victim, carry.Character, carry.Mutation, carry.VictimSlot)
	end
	clearCarry(player)
end

local function finishCarry(player)
	local carry = carries[player]
	if not carry then
		return
	end

	local character = carry.Character
	if not character then
		clearCarry(player)
		return
	end

	if carry.Victim then
		local victim = carry.Victim
		if victim.Parent then
			PlayerData.RemoveOwnedBrainrot(victim, carry.VictimSlot)
			BaseManager.RemoveBrainrotFromBase(victim, carry.VictimSlot)
		end
	end

	PlayerData.AddOwnedBrainrot(player, character.Id, carry.Mutation, carry.Slot)
	BaseManager.PlaceBrainrotOnBase(player, character, carry.Mutation, carry.Slot)
	clearCarry(player)
end

function StealManager.IsCarrying(player)
	return carries[player] ~= nil
end

function StealManager.TryStealBrainrot(thief, victim, slotIndex)
	if not thief or not victim or thief == victim then
		return false
	end
	if StealManager.IsCarrying(thief) then
		showMessage(thief, "You are already carrying a brainrot!")
		return false
	end

	local victimData = PlayerData.Get(victim)
	if not victimData then
		return false
	end

	local owned = PlayerData.GetOwnedAtSlot(victim, slotIndex)
	if not owned then
		showMessage(thief, "That slot is empty.")
		return false
	end

	if BaseManager.IsBaseLocked(victim) then
		showMessage(thief, "That base is locked!")
		return false
	end

	local lastStolenAt = victimData.LastStolenAt or 0
	if os.time() - lastStolenAt < BrainrotCatalog.StealShieldSeconds then
		showMessage(thief, "That base is shielded — it was just robbed!")
		return false
	end

	local freeSlot = PlayerData.FindFreeSlot(thief)
	if not freeSlot then
		showMessage(thief, "Your base has no free slots!")
		return false
	end

	local character = BrainrotCatalog.GetCharacterById(owned.CharacterId)
	if not character then
		return false
	end

	BaseManager.RemoveBrainrotFromBase(victim, slotIndex)
	local model = buildCarryModel(thief, character, owned.Mutation)

	carries[thief] = {
		Model = model,
		Character = character,
		Mutation = owned.Mutation,
		Slot = freeSlot,
		Victim = victim,
		VictimSlot = slotIndex,
	}

	victimData.LastStolenAt = os.time()
	return true
end

function StealManager.TryStealFromClick(clickingPlayer, ownerPlayer, slotIndex)
	return StealManager.TryStealBrainrot(clickingPlayer, ownerPlayer, slotIndex)
end

function StealManager.StartPurchaseCarry(player, character, mutationName, slotIndex)
	if carries[player] then
		return
	end
	local model = buildCarryModel(player, character, mutationName)
	carries[player] = {
		Model = model,
		Character = character,
		Mutation = mutationName,
		Slot = slotIndex,
		Victim = nil,
		VictimSlot = nil,
	}
end

function StealManager.GetCarrySummary(player)
	local carry = carries[player]
	if not carry or not carry.Character then
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
	if carry and not carry.Victim then
		return carry.Slot
	end
	return nil
end

function StealManager.CancelCarry(player)
	local carry = carries[player]
	if not carry then
		return
	end
	if carry.Victim then
		restoreStolen(player)
	else
		clearCarry(player)
	end
end

function StealManager.Init(remoteFolder)
	if initialized then
		return
	end
	initialized = true
	remotes = remoteFolder

	if remotes.RequestSteal then
		remotes.RequestSteal.OnServerEvent:Connect(function(player, ownerPlayer, slotIndex)
			StealManager.TryStealBrainrot(player, ownerPlayer, slotIndex)
		end)
	end

	Players.PlayerRemoving:Connect(function(player)
		if carries[player] then
			restoreStolen(player)
		end
	end)

	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		for player, carry in pairs(carries) do
			if player.Parent == nil then
				if carry.Victim then
					restoreStolen(player)
				else
					clearCarry(player)
				end
			elseif carry.Model == nil or carry.Model.Parent == nil then
				if carry.Victim then
					restoreStolen(player)
				else
					clearCarry(player)
				end
			else
				local root = getRootPosition(player)
				if root then
					carry.Model:PivotTo(CFrame.new(root + Vector3.new(0, CARRY_HEIGHT, 0)))
					if BaseManager.IsPositionInsideOwnBase(player, root) then
						finishCarry(player)
					end
				end
			end
		end
	end)
end

return StealManager
