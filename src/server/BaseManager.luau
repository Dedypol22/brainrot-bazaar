-- BaseManager.luau
-- Owns the eight base plots: assignment, brainrot models on pads, signs
-- and the base lock (45 seconds locked, 2 minutes of cooldown).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local BrainrotSpawner = require(script.Parent:WaitForChild("BrainrotSpawner"))
local MapBuilder = require(script.Parent:WaitForChild("MapBuilder"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local BaseManager = {}
BaseManager.StealClickedCallback = function(_clickingPlayer, _ownerPlayer, _slotIndex) end

local plots = {}
local plotByPlayer = {}
local modelsByPlayer = {}
local lockStateByPlayer = {}

local function updateSignForPlot(plot, incomePerSecond)
	if not plot or not plot.Sign then
		return
	end
	if plot.OwnerUserId == 0 then
		plot.Sign.Text = "BASE " .. plot.Index
		return
	end
	local owner = Players:GetPlayerByUserId(plot.OwnerUserId)
	local ownerName = owner and owner.Name or "Player"
	local text = ownerName .. "\n$" .. tostring(incomePerSecond or 0) .. "/s"
	if owner and BaseManager.IsBaseLocked(owner) then
		text ..= "\nLOCKED"
	end
	plot.Sign.Text = text
end

function BaseManager.Init(worldMap)
	plots = worldMap.Plots or {}
end

function BaseManager.GetPlotForPlayer(player)
	return plotByPlayer[player]
end

function BaseManager.AssignPlotToPlayer(player)
	for _, plot in ipairs(plots) do
		if plot.OwnerUserId == 0 then
			plot.OwnerUserId = player.UserId
			plotByPlayer[player] = plot
			modelsByPlayer[player] = modelsByPlayer[player] or {}
			updateSignForPlot(plot, 0)
			return plot
		end
	end
	return nil
end

function BaseManager.ReleasePlotForPlayer(player)
	local plot = plotByPlayer[player]
	BaseManager.ClearAllBaseBrainrots(player)
	if plot then
		plot.OwnerUserId = 0
		updateSignForPlot(plot, 0)
	end
	plotByPlayer[player] = nil
	lockStateByPlayer[player] = nil
end

function BaseManager.IsPositionInsideOwnBase(player, position)
	local plot = plotByPlayer[player]
	if not plot or not position then
		return false
	end
	local dx = math.abs(position.X - plot.Center.X)
	local dz = math.abs(position.Z - plot.Center.Z)
	return dx <= 13 and dz <= 9.5
end

function BaseManager.PlaceBrainrotOnBase(player, characterEntry, mutationName, slotIndex)
	local plot = plotByPlayer[player]
	if not plot then
		return nil
	end
	local pad = plot.Pads[slotIndex]
	if not pad then
		pad = MapBuilder.CreateSlotPad(plot, slotIndex)
	end
	local yaw = 0
	if plot.Center.Z < 0 then
		yaw = 0
	else
		yaw = 180
	end
	local position = pad.Position + Vector3.new(0, 1.6, 0)
	local model = BrainrotSpawner.BuildBrainrotModel(characterEntry, mutationName, position, yaw, false)
	model.Parent = plot.Model
	local primary = model.PrimaryPart
	if primary then
		local detector = Instance.new("ClickDetector")
		detector.MaxActivationDistance = 32
		detector.Parent = primary
		detector.MouseClick:Connect(function(clickingPlayer)
			BaseManager.StealClickedCallback(clickingPlayer, player, slotIndex)
		end)
	end
	modelsByPlayer[player] = modelsByPlayer[player] or {}
	modelsByPlayer[player][slotIndex] = model
	return model
end

function BaseManager.RemoveBrainrotFromBase(player, slotIndex)
	local models = modelsByPlayer[player]
	if models and models[slotIndex] then
		models[slotIndex]:Destroy()
		models[slotIndex] = nil
	end
end

function BaseManager.ClearAllBaseBrainrots(player)
	local models = modelsByPlayer[player]
	if not models then
		return
	end
	for _, model in pairs(models) do
		if model then
			model:Destroy()
		end
	end
	modelsByPlayer[player] = {}
end

function BaseManager.RebuildBaseFromSave(player)
	local data = PlayerData.Get(player)
	if not data then
		return
	end
	for _, entry in ipairs(data.Owned) do
		local characterEntry = BrainrotCatalog.GetCharacterById(entry.CharacterId)
		if characterEntry then
			BaseManager.PlaceBrainrotOnBase(player, characterEntry, entry.Mutation, entry.Slot)
		end
	end
end

function BaseManager.GetBaseModelAtSlot(player, slotIndex)
	local models = modelsByPlayer[player]
	if not models then
		return nil
	end
	return models[slotIndex]
end

function BaseManager.IsBaseLocked(player)
	local state = lockStateByPlayer[player]
	if not state then
		return false
	end
	return os.clock() < state.LockedUntil
end

function BaseManager.LockBase(player)
	local now = os.clock()
	local state = lockStateByPlayer[player]
	if state and now < state.CooldownUntil then
		return false
	end
	if state and now < state.LockedUntil then
		return false
	end
	lockStateByPlayer[player] = {
		LockedUntil = now + BrainrotCatalog.LockDurationSeconds,
		CooldownUntil = now + BrainrotCatalog.LockDurationSeconds + BrainrotCatalog.LockCooldownSeconds,
	}
	return true
end

function BaseManager.GetLockStatus(player)
	local now = os.clock()
	local state = lockStateByPlayer[player]
	if not state then
		return { Locked = false, SecondsLeft = 0, CooldownLeft = 0 }
	end
	local secondsLeft = math.max(0, math.ceil(state.LockedUntil - now))
	local cooldownLeft = math.max(0, math.ceil(state.CooldownUntil - now))
	return {
		Locked = now < state.LockedUntil,
		SecondsLeft = secondsLeft,
		CooldownLeft = cooldownLeft,
	}
end

function BaseManager.RevealExtraSlot(player, slotIndex)
	local plot = plotByPlayer[player]
	if not plot then
		return
	end
	if not plot.Pads[slotIndex] then
		MapBuilder.CreateSlotPad(plot, slotIndex)
	end
	local pad = plot.Pads[slotIndex]
	if pad then
		pad.Transparency = 0
		pad.CanCollide = true
	end
end

function BaseManager.UpdatePlotSign(player, incomePerSecond)
	local plot = plotByPlayer[player]
	if plot then
		updateSignForPlot(plot, incomePerSecond)
	end
end

return BaseManager
