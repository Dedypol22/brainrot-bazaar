-- StealManager.luau
-- Carries brainrots on players' heads. A carry starts either as a purchase
-- (bought from the belt, walk it home to claim it) or as a theft (clicked on
-- someone else's base, run home before... well, just run home). Reaching
-- your own base completes the carry; vanishing mid-carry hands a stolen
-- brainrot back to its owner.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local BrainrotSpawner = require(script.Parent:WaitForChild("BrainrotSpawner"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local StealManager = {}

local CARRY_HEIGHT = 6.5

-- [player] = { Model, Character, Mutation, Slot, Victim, VictimSlot }
local carries = {}

local function headPosition(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		return root.Position + Vector3.new(0, CARRY_HEIGHT, 0), root
	end
	return nil, nil
end

local function buildCarryModel(player, character, mutationName)
	local position = headPosition(player)
	if not position then
		local plot = BaseManager.GetPlotForPlayer(player)
		if plot then
			position = plot.Center + Vector3.new(0, CARRY_HEIGHT, 0)
		else
			position = Vector3.new(0, CARRY_HEIGHT, 0)
		end
	end
	local model = BrainrotSpawner.BuildBrainrotModel(character, mutationName, position, 0, false)
	model.Parent = Workspace
	return model
end

function StealManager.IsCarrying(player)
	return carries[player] ~= nil
end

function StealManager.GetCarriedPurchaseSlot(player)
	local carry = carries[player]
	if carry and carry.Victim == nil then
		return carry.Slot
	end
	return nil
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

function StealManager.StartPurchaseCarry(player, character, mutationName, slotIndex)
	if carries[player] then
		return false
	end
	local model = buildCarryModel(player, character, mutationName)
	carries[player] = {
		Model = model,
		Character = character,
		Mutation = mutationName or "None",
		Slot = slotIndex,
		Victim = nil,
		VictimSlot = nil,
	}
	return true
end

function StealManager.TryStealBrainrot(thief, victim, slotIndex)
	if not thief or not victim or thief == victim then
		return false
	end
	if carries[thief] then
		return false
	end
	if BaseManager.IsBaseLocked(victim) then
		return false
	end
	local entry = PlayerData.GetOwnedAtSlot(victim, slotIndex)
	if not entry then
		return false
	end
	local character = BrainrotCatalog.GetCharacterById(entry.CharacterId)
	if not character then
		return false
	end
	local freeSlot = PlayerData.FindFreeSlot(thief)
	if not freeSlot then
		return false
	end
	-- The model leaves the victim's base now; the data only changes hands
	-- once the thief actually makes it home.
	BaseManager.RemoveBrainrotFromBase(victim, slotIndex)
	local model = buildCarryModel(thief, character, entry.Mutation)
	carries[thief] = {
		Model = model,
		Character = character,
		Mutation = entry.Mutation,
		Slot = freeSlot,
		Victim = victim,
		VictimSlot = slotIndex,
	}
	return true
end

function StealManager.TryStealFromClick(clickingPlayer, ownerPlayer, slotIndex)
	return StealManager.TryStealBrainrot(clickingPlayer, ownerPlayer, slotIndex)
end

local function restoreStealToVictim(carry)
	local victim = carry.Victim
	if victim and victim.Parent and PlayerData.GetOwnedAtSlot(victim, carry.VictimSlot) then
		BaseManager.PlaceBrainrotOnBase(victim, carry.Character, carry.Mutation, carry.VictimSlot)
	end
end

function StealManager.CancelCarry(player)
	local carry = carries[player]
	if not carry then
		return
	end
	carries[player] = nil
	if carry.Victim then
		restoreStealToVictim(carry)
	end
	if carry.Model then
		carry.Model:Destroy()
	end
end

local function completeCarry(player, carry)
	carries[player] = nil
	if carry.Model then
		carry.Model:Destroy()
	end
	if carry.Victim then
		-- The victim's copy goes away as the thief's copy appears.
		PlayerData.RemoveOwnedBrainrot(carry.Victim, carry.VictimSlot)
		BaseManager.RemoveBrainrotFromBase(carry.Victim, carry.VictimSlot)
	end
	PlayerData.AddOwnedBrainrot(player, carry.Character.Id, carry.Mutation, carry.Slot)
	BaseManager.PlaceBrainrotOnBase(player, carry.Character, carry.Mutation, carry.Slot)
end

local function watchCarries()
	while true do
		local players = {}
		for player in pairs(carries) do
			table.insert(players, player)
		end
		for _, player in ipairs(players) do
			local carry = carries[player]
			if carry then
				if carry.Victim and not carry.Victim.Parent then
					-- Victim left mid-theft: their save still holds the
					-- brainrot, so the carry simply evaporates.
					carries[player] = nil
					if carry.Model then
						carry.Model:Destroy()
					end
				elseif not carry.Model or not carry.Model.Parent then
					-- The carried model was destroyed some other way.
					carries[player] = nil
					if carry.Victim then
						restoreStealToVictim(carry)
					end
				else
					local position, root = headPosition(player)
					if root then
						carry.Model:PivotTo(CFrame.new(position))
						if BaseManager.IsPositionInsideOwnBase(player, root.Position) then
							completeCarry(player, carry)
						end
					end
				end
			end
		end
		task.wait(0.1)
	end
end

function StealManager.Init(remoteFolder)
	local requestSteal = remoteFolder and remoteFolder.RequestSteal
	if requestSteal then
		requestSteal.OnServerEvent:Connect(function(player, ownerPlayer, slotIndex)
			if typeof(ownerPlayer) == "Instance" and ownerPlayer:IsA("Player")
				and typeof(slotIndex) == "number"
			then
				StealManager.TryStealBrainrot(player, ownerPlayer, math.floor(slotIndex))
			end
		end)
	end

	Players.PlayerRemoving:Connect(function(player)
		if carries[player] then
			StealManager.CancelCarry(player)
		end
	end)

	task.spawn(watchCarries)
end

return StealManager
