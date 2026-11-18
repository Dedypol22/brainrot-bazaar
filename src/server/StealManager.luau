-- StealManager.luau (server module)
-- Owns carrying, for steals and for purchases alike: a player can pick
-- up a brainrot from another player's base and carry it home, but only
-- while that base is unlocked; and a brainrot bought off the belt is
-- likewise carried home by its buyer before it takes its base slot.
-- A carried brainrot rides above the carrier's head until they reach
-- their own base. A stolen one also drops and returns home when its
-- owner touches the thief; a bought one is safe, but auto-places if
-- the buyer dies on the way.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local BrainrotSpawner = require(script.Parent:WaitForChild("BrainrotSpawner"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local StealManager = {}

local remotes = nil
local carried = {} -- [carrier Player] -> { Kind, Victim, Slot, Character, Mutation, Model, TouchConnection }

-- How high above the carrier's root a carried brainrot rides. The
-- creatures are built huge, so this keeps their feet clear of the
-- carrier's head.
local CARRY_HEIGHT = 6.5

local function sendFeedback(player, message)
	if remotes then
		remotes.ShowMessage:FireClient(player, message)
	end
end

-- Is this player already carrying a stolen brainrot?
function StealManager.IsCarrying(player)
	return carried[player] ~= nil
end

-- Puts the carried brainrot back on its owner's slot and clears the carry.
local function returnStolenBrainrotToOwner(thief)
	local carry = carried[thief]
	if not carry then
		return
	end
	carried[thief] = nil
	if carry.TouchConnection then
		carry.TouchConnection:Disconnect()
	end
	if carry.Model then
		carry.Model:Destroy()
	end
	local victim = carry.Victim
	if victim and victim.Parent then
		PlayerData.AddOwnedBrainrot(victim, carry.Character.Id, carry.Mutation, carry.Slot)
		BaseManager.PlaceBrainrotOnBase(victim, carry.Character, carry.Mutation, carry.Slot)
		sendFeedback(victim, carry.Character.Name .. " is back on your base!")
	end
end

-- Drops the brainrot because the owner caught the thief.
local function dropStolenBrainrot(thief, reason)
	local carry = carried[thief]
	if not carry then
		return
	end
	returnStolenBrainrotToOwner(thief)
	sendFeedback(thief, reason)
end

-- The steal completes: the brainrot joins the thief's collection.
local function completeSteal(thief)
	local carry = carried[thief]
	if not carry then
		return
	end
	carried[thief] = nil
	if carry.TouchConnection then
		carry.TouchConnection:Disconnect()
	end
	if carry.Model then
		carry.Model:Destroy()
	end
	local slot = PlayerData.FindFreeSlot(thief)
	if not slot then
		-- No room left at home: give it back instead of losing it.
		local victim = carry.Victim
		if victim and victim.Parent then
			PlayerData.AddOwnedBrainrot(victim, carry.Character.Id, carry.Mutation, carry.Slot)
			BaseManager.PlaceBrainrotOnBase(victim, carry.Character, carry.Mutation, carry.Slot)
		end
		sendFeedback(thief, "Your base is full! The brainrot went home.")
		return
	end
	PlayerData.AddOwnedBrainrot(thief, carry.Character.Id, carry.Mutation, slot)
	BaseManager.PlaceBrainrotOnBase(thief, carry.Character, carry.Mutation, slot)
	sendFeedback(thief, "STOLEN! " .. BrainrotCatalog.GetDisplayName(carry.Character, carry.Mutation) .. " is yours now!")
	local victim = carry.Victim
	if victim and victim.Parent then
		sendFeedback(victim, thief.DisplayName .. " stole your " .. carry.Character.Name .. "!")
	end
end

-- The purchase carry completes: the brainrot takes the base slot its
-- purchase already reserved in the buyer's save.
local function completePurchaseCarry(thief)
	local carry = carried[thief]
	if not carry then
		return
	end
	carried[thief] = nil
	if carry.Model then
		carry.Model:Destroy()
	end
	BaseManager.PlaceBrainrotOnBase(thief, carry.Character, carry.Mutation, carry.Slot)
	sendFeedback(thief, BrainrotCatalog.GetDisplayName(carry.Character, carry.Mutation) .. " is on your base, earning for you!")
end

-- Ends a carry whose carrier can no longer carry: a stolen brainrot
-- goes home to its owner; a bought one simply takes its base slot.
local function endCarryInterrupted(thief)
	local carry = carried[thief]
	if not carry then
		return
	end
	if carry.Kind == "Purchase" then
		completePurchaseCarry(thief)
	else
		returnStolenBrainrotToOwner(thief)
	end
end

-- Watches the carrier: carrying the brainrot above their head,
-- completing the carry when they step onto their own base.
local function watchCarriedBrainrot(thief)
	local carry = carried[thief]
	if not carry then
		return
	end
	local character = thief.Character
	if not character then
		endCarryInterrupted(thief)
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		endCarryInterrupted(thief)
		return
	end
	if carry.Model and carry.Model.PrimaryPart then
		carry.Model:PivotTo(root.CFrame * CFrame.new(0, CARRY_HEIGHT, 0))
	end
	if BaseManager.IsPositionInsideOwnBase(thief, root.Position) then
		if carry.Kind == "Purchase" then
			completePurchaseCarry(thief)
		else
			completeSteal(thief)
		end
	end
end

-- Starts a steal: checks the lock, lifts the brainrot off the victim's
-- base and puts it above the thief's head.
function StealManager.TryStealBrainrot(thief, victim, slotIndex)
	if not PlayerData.IsLoaded(thief) then
		return false, "Your data is not loaded yet."
	end
	if thief == victim then
		return false, "That brainrot is already yours!"
	end
	if StealManager.IsCarrying(thief) then
		return false, "You are already carrying a stolen brainrot!"
	end
	if not victim or not victim.Parent then
		return false, "That player is gone."
	end
	if BaseManager.IsBaseLocked(victim) then
		return false, victim.DisplayName .. "'s base is LOCKED!"
	end
	local entry = PlayerData.GetOwnedAtSlot(victim, slotIndex)
	if not entry then
		return false, "That slot is empty."
	end
	local character = BrainrotCatalog.GetCharacterById(entry.CharacterId)
	if not character then
		return false, "That brainrot is gone."
	end
	local thiefCharacter = thief.Character
	if not thiefCharacter then
		return false, "You need to be alive to steal!"
	end
	local root = thiefCharacter:FindFirstChild("HumanoidRootPart")
	if not root then
		return false, "You need to be alive to steal!"
	end
	if PlayerData.FindFreeSlot(thief) == nil then
		return false, "Your base is full! Buy another slot first."
	end
	if not BaseManager.GetPlotForPlayer(thief) then
		return false, "You have no base yet — wait for a free plot!"
	end

	-- Lift it off the victim's base.
	PlayerData.RemoveOwnedBrainrot(victim, slotIndex)
	BaseManager.RemoveBrainrotFromBase(victim, slotIndex)

	local model = BrainrotSpawner.BuildBrainrotModel(character, entry.Mutation, root.Position + Vector3.new(0, CARRY_HEIGHT, 0), 0, false)
	model:SetAttribute("StolenFromUserId", victim.UserId)

	local carry = {
		Kind = "Steal",
		Victim = victim,
		Slot = slotIndex,
		Character = character,
		Mutation = entry.Mutation,
		Model = model,
		TouchConnection = nil,
	}
	carried[thief] = carry

	-- The owner touching the thief makes the thief drop the brainrot.
	carry.TouchConnection = root.Touched:Connect(function(hit)
		local hitCharacter = hit.Parent
		if not hitCharacter then
			return
		end
		local hitPlayer = Players:GetPlayerFromCharacter(hitCharacter)
		if hitPlayer == victim and carried[thief] then
			dropStolenBrainrot(thief, victim.DisplayName .. " caught you! You dropped " .. character.Name .. "!")
		end
	end)

	-- If the thief dies or leaves, the brainrot goes home.
	local humanoid = thiefCharacter:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Died:Connect(function()
			if carried[thief] then
				returnStolenBrainrotToOwner(thief)
				sendFeedback(thief, "You dropped " .. character.Name .. "!")
			end
		end)
	end

	sendFeedback(thief, "You grabbed " .. BrainrotCatalog.GetDisplayName(character, entry.Mutation) .. "! Run home to your base!")
	sendFeedback(victim, thief.DisplayName .. " is stealing your " .. character.Name .. "! Touch them to stop it!")
	return true, "Stolen!"
end

-- Starts a purchase carry: the brainrot the player just bought rides
-- above their head until they carry it onto their own base, where it
-- takes the slot the purchase already reserved. Returns false when
-- the player has no live character to carry it, so the caller can
-- place the brainrot directly instead.
function StealManager.StartPurchaseCarry(player, character, mutationName, slotIndex)
	if carried[player] then
		return false
	end
	local buyerCharacter = player.Character
	if not buyerCharacter then
		return false
	end
	local root = buyerCharacter:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local model = BrainrotSpawner.BuildBrainrotModel(character, mutationName, root.Position + Vector3.new(0, CARRY_HEIGHT, 0), 0, false)
	carried[player] = {
		Kind = "Purchase",
		Victim = nil,
		Slot = slotIndex,
		Character = character,
		Mutation = mutationName,
		Model = model,
		TouchConnection = nil,
	}
	-- Dying on the way home does not lose a paid-for brainrot: it
	-- takes its base slot anyway.
	local humanoid = buyerCharacter:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Died:Connect(function()
			if carried[player] and carried[player].Kind == "Purchase" then
				completePurchaseCarry(player)
			end
		end)
	end
	return true
end

-- What this player is carrying, for the client's task bar, or nil.
function StealManager.GetCarrySummary(player)
	local carry = carried[player]
	if not carry then
		return nil
	end
	return {
		Kind = carry.Kind,
		Name = BrainrotCatalog.GetDisplayName(carry.Character, carry.Mutation),
	}
end

-- The reserved base slot of a purchase carry, or nil.
function StealManager.GetCarriedPurchaseSlot(player)
	local carry = carried[player]
	if carry and carry.Kind == "Purchase" then
		return carry.Slot
	end
	return nil
end

-- Cancels a purchase carry without placing anything (used when the
-- carried purchase is sold from the base panel mid-carry, and when
-- the buyer leaves: the purchase stays in their save and its base
-- model is rebuilt when they rejoin). Steal carries are never
-- cancelled this way; a stolen brainrot must go home to its owner.
function StealManager.CancelCarry(player)
	local carry = carried[player]
	if not carry or carry.Kind ~= "Purchase" then
		return
	end
	carried[player] = nil
	if carry.Model then
		carry.Model:Destroy()
	end
end

-- Called when a base brainrot is clicked: the clicker is the thief.
function StealManager.TryStealFromClick(clickingPlayer, ownerPlayer, slotIndex)
	local ok, message = StealManager.TryStealBrainrot(clickingPlayer, ownerPlayer, slotIndex)
	if not ok then
		sendFeedback(clickingPlayer, message)
	end
	return ok
end

function StealManager.Init(remoteFolder)
	remotes = remoteFolder

	remotes.RequestSteal.OnServerEvent:Connect(function(thief, victimUserId, slotIndex)
		local victim = Players:GetPlayerByUserId(tonumber(victimUserId) or 0)
		local ok, message = StealManager.TryStealBrainrot(thief, victim, slotIndex)
		if not ok then
			sendFeedback(thief, message)
		end
	end)

	-- One watcher for every carried brainrot, every frame.
	RunService.Heartbeat:Connect(function()
		for thief, _ in pairs(carried) do
			if thief.Parent then
				watchCarriedBrainrot(thief)
			else
				returnStolenBrainrotToOwner(thief)
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		if carried[player] then
			if carried[player].Kind == "Purchase" then
				-- The purchase is already in their save; its base
				-- model is rebuilt when they rejoin.
				StealManager.CancelCarry(player)
			else
				returnStolenBrainrotToOwner(player)
			end
		end
		-- A victim leaving while their brainrot is carried keeps it safe:
		-- it returns to them the next time they join from their save.
		for thief, carry in pairs(carried) do
			if carry.Victim == player then
				returnStolenBrainrotToOwner(thief)
			end
		end
	end)
end

return StealManager
