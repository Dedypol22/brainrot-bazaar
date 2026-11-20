-- BaseManager: plot ownership, placed brainrots, signs and base locking.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local BrainrotSpawner = require(script.Parent:WaitForChild("BrainrotSpawner"))
local MapBuilder = require(script.Parent:WaitForChild("MapBuilder"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local BaseManager = {}

local plots = {}
local baseModels = {}
local lockStates = {}

BaseManager.StealClickedCallback = function() end

local function getPlotForPlayerInternal(player)
	for _, plot in ipairs(plots) do
		if plot.OwnerUserId == player.UserId then
			return plot
		end
	end
	return nil
end

local function getOwnerPlayer(plot)
	if plot.OwnerUserId == 0 then
		return nil
	end
	return Players:GetPlayerByUserId(plot.OwnerUserId)
end

local function setPlotSign(plot, incomePerSecond)
	if not plot.Sign then
		return
	end
	if plot.OwnerUserId == 0 then
		plot.Sign.Text = "BASE " .. tostring(plot.Index)
		plot.Sign.TextColor3 = Color3.fromRGB(255, 255, 255)
		return
	end

	local owner = getOwnerPlayer(plot)
	local name = owner and owner.Name or "Player"
	local income = math.floor(incomePerSecond or 0)
	local text = name .. "\n$" .. tostring(income) .. "/s"
	local lockState = lockStates[owner]
	if lockState and os.time() < lockState.LockedUntil then
		text = text .. "\nLOCKED"
	end
	plot.Sign.Text = text
end

local function clearModelsForPlayer(player)
	local models = baseModels[player]
	if not models then
		return
	end
	for _, model in pairs(models) do
		if model and model.Parent then
			model:Destroy()
		end
	end
	baseModels[player] = {}
end

function BaseManager.Init(worldMap)
	plots = worldMap.Plots or {}
end

function BaseManager.GetPlotForPlayer(player)
	return getPlotForPlayerInternal(player)
end

function BaseManager.AssignPlotToPlayer(player)
	for _, plot in ipairs(plots) do
		if plot.OwnerUserId == 0 then
			plot.OwnerUserId = player.UserId
			baseModels[player] = {}
			setPlotSign(plot, 0)
			return plot
		end
	end
	return nil
end

function BaseManager.ReleasePlotForPlayer(player)
	local plot = getPlotForPlayerInternal(player)
	clearModelsForPlayer(player)
	baseModels[player] = nil
	lockStates[player] = nil
	if plot then
		plot.OwnerUserId = 0
		setPlotSign(plot, 0)
	end
end

function BaseManager.IsPositionInsideOwnBase(player, position)
	local plot = getPlotForPlayerInternal(player)
	if not plot then
		return false
	end
	local dx = math.abs(position.X - plot.Center.X)
	local dz = math.abs(position.Z - plot.Center.Z)
	return dx <= 12 and dz <= 8
end

function BaseManager.PlaceBrainrotOnBase(player, character, mutationName, slotIndex)
	local plot = getPlotForPlayerInternal(player)
	if not plot then
		return nil
	end
	if not plot.Pads[slotIndex] then
		MapBuilder.CreateSlotPad(plot, slotIndex)
	end
	local pad = plot.Pads[slotIndex]

	local position = pad.Position + Vector3.new(0, pad.Size.Y * 0.5, 0)
	local yaw = plot.Center.Z > 0 and 0 or math.pi
	local model = BrainrotSpawner.BuildBrainrotModel(character, mutationName, position, yaw, false, nil)
	model.Parent = plot.Model

	if not baseModels[player] then
		baseModels[player] = {}
	end
	baseModels[player][slotIndex] = model

	if model.PrimaryPart then
		local detector = Instance.new("ClickDetector")
		detector.Name = "StealDetector"
		detector.MaxActivationDistance = 40
		detector.MouseClick:Connect(function(clickingPlayer)
			BaseManager.StealClickedCallback(clickingPlayer, player, slotIndex)
		end)
		detector.Parent = model.PrimaryPart
	end

	return model
end

function BaseManager.RemoveBrainrotFromBase(player, slotIndex)
	local models = baseModels[player]
	if not models then
		return
	end
	local model = models[slotIndex]
	if model then
		model:Destroy()
		models[slotIndex] = nil
	end
end

function BaseManager.ClearAllBaseBrainrots(player)
	clearModelsForPlayer(player)
end

function BaseManager.RebuildBaseFromSave(player)
	clearModelsForPlayer(player)
	local data = PlayerData.Get(player)
	if not data then
		return
	end
	for _, entry in ipairs(data.Owned) do
		local character = BrainrotCatalog.GetCharacterById(entry.CharacterId)
		if character then
			BaseManager.PlaceBrainrotOnBase(player, character, entry.Mutation, entry.Slot)
		end
	end
end

function BaseManager.GetBaseModelAtSlot(player, slotIndex)
	local models = baseModels[player]
	if not models then
		return nil
	end
	return models[slotIndex]
end

function BaseManager.IsBaseLocked(player)
	local state = lockStates[player]
	return state ~= nil and os.time() < state.LockedUntil
end

function BaseManager.LockBase(player)
	local now = os.time()
	local state = lockStates[player]
	if state then
		if now < state.LockedUntil or now < state.CooldownUntil then
			return false
		end
	end
	local lockedUntil = now + BrainrotCatalog.LockDurationSeconds
	lockStates[player] = {
		LockedUntil = lockedUntil,
		CooldownUntil = lockedUntil + BrainrotCatalog.LockCooldownSeconds,
	}
	return true
end

function BaseManager.GetLockStatus(player)
	local now = os.time()
	local state = lockStates[player]
	if not state then
		return { Locked = false, SecondsLeft = 0, CooldownLeft = 0 }
	end
	return {
		Locked = now < state.LockedUntil,
		SecondsLeft = math.max(0, state.LockedUntil - now),
		CooldownLeft = math.max(0, state.CooldownUntil - now),
	}
end

function BaseManager.RevealExtraSlot(player, slotIndex)
	local plot = getPlotForPlayerInternal(player)
	if not plot then
		return
	end
	if not plot.Pads[slotIndex] then
		MapBuilder.CreateSlotPad(plot, slotIndex)
	else
		plot.Pads[slotIndex].Transparency = 0
	end
end

function BaseManager.UpdatePlotSign(player, incomePerSecond)
	local plot = getPlotForPlayerInternal(player)
	if not plot then
		return
	end
	setPlotSign(plot, incomePerSecond)
end

return BaseManager
