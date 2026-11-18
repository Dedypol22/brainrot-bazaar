-- StealManager.luau (server module)
-- Owns stealing: a player can pick up a brainrot from another player's
-- base and carry it home, but only while that base is unlocked. The brainrot
-- rides above the thief's head until they reach their own base (the steal
-- completes) or the owner touches them (the brainrot drops and returns).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local BrainrotSpawner = require(script.Parent:WaitForChild("BrainrotSpawner"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local StealManager = {}

local remotes = nil
local carried = {} -- [thief Player] -> { Victim, Slot, Character, Mutation, Model, TouchConnection }

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

-- Watches the thief: carrying the brainrot above their head, completing
-- the steal when they step onto their own base.
local function watchCarriedBrainrot(thief)
	local carry = carried[thief]
	if not carry then
		return
	end
	local character = thief.Character
	if not character then
		returnStolenBrainrotToOwner(thief)
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		returnStolenBrainrotToOwner(thief)
		return
	end
	if carry.Model and carry.Model.PrimaryPart then
		carry.Model:PivotTo(root.CFrame * CFrame.new(0, 4.5, 0))
	end
	if BaseManager.IsPositionInsideOwnBase(thief, root.Position) then
		completeSteal(thief)
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

	local model = BrainrotSpawner.BuildBrainrotModel(character, entry.Mutation, root.Position + Vector3.new(0, 4.5, 0), 0, false)
	model:SetAttribute("StolenFromUserId", victim.UserId)

	local carry = {
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
			returnStolenBrainrotToOwner(player)
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
