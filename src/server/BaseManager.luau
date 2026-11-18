-- BaseManager.luau
-- Looks after the eight base plots: who owns which plot, the brainrot models
-- standing on a base, the plot signs, and the timed base lock that protects a
-- base from stealing. Plot geometry itself comes from MapBuilder; the models
-- come from BrainrotSpawner; ownership data lives in PlayerData.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local BrainrotSpawner = require(script.Parent:WaitForChild("BrainrotSpawner"))
local MapBuilder = require(script.Parent:WaitForChild("MapBuilder"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local BaseManager = {}

-- Set by Main: called when a player clicks a brainrot standing on a base.
BaseManager.StealClickedCallback = function(clickingPlayer, ownerPlayer, slotIndex) end

local plots = {}
local playerPlots = {} -- [userId] = plot
local plotModels = {} -- [userId] = { [slotIndex] = Model }
local lockStates = {} -- [userId] = { LockedUntil = n, CooldownUntil = n }

function BaseManager.Init(worldMap)
	plots = worldMap.Plots
end

-- Plot signs ----------------------------------------------------------------------

local function updateSignForPlot(plot, incomePerSecond)
	if not plot.Sign then
		return
	end
	if plot.OwnerUserId == 0 then
		plot.Sign.Text = "BASE " .. plot.Index
	else
		local owner = Players:GetPlayerByUserId(plot.OwnerUserId)
		local ownerName = owner and owner.Name or "Player"
		plot.Sign.Text = ownerName .. "\n$" .. tostring(incomePerSecond) .. "/s"
	end
end

function BaseManager.UpdatePlotSign(player, incomePerSecond)
	local plot = playerPlots[player.UserId]
	if plot then
		updateSignForPlot(plot, incomePerSecond)
	end
end

-- Plot ownership --------------------------------------------------------------------

function BaseManager.GetPlotForPlayer(player)
	return playerPlots[player.UserId]
end

function BaseManager.AssignPlotToPlayer(player)
	local existing = playerPlots[player.UserId]
	if existing then
		return existing
	end
	for _, plot in ipairs(plots) do
		if plot.OwnerUserId == 0 then
			plot.OwnerUserId = player.UserId
			playerPlots[player.UserId] = plot
			plotModels[player.UserId] = {}
			updateSignForPlot(plot, 0)
			return plot
		end
	end
	return nil
end

function BaseManager.ReleasePlotForPlayer(player)
	local plot = playerPlots[player.UserId]
	if not plot then
		return
	end
	BaseManager.ClearAllBaseBrainrots(player)
	plot.OwnerUserId = 0
	updateSignForPlot(plot, 0)
	playerPlots[player.UserId] = nil
	plotModels[player.UserId] = nil
	lockStates[player.UserId] = nil
end

function BaseManager.IsPositionInsideOwnBase(player, position)
	local plot = playerPlots[player.UserId]
	if not plot then
		return false
	end
	return math.abs(position.X - plot.Center.X) <= 13
		and math.abs(position.Z - plot.Center.Z) <= 9
end

-- Brainrot models on bases ------------------------------------------------------------

function BaseManager.PlaceBrainrotOnBase(player, character, mutationName, slotIndex)
	local plot = playerPlots[player.UserId]
	if not plot then
		return nil
	end
	local pad = plot.Pads[slotIndex]
	if not pad then
		pad = MapBuilder.CreateSlotPad(plot, slotIndex)
	end
	-- North plots face south toward the belt and vice versa.
	local yaw = plot.Center.Z < 0 and math.pi or 0
	local anchor = Vector3.new(
		pad.Position.X,
		pad.Position.Y + pad.Size.Y / 2 + 2,
		pad.Position.Z
	)
	local model = BrainrotSpawner.BuildBrainrotModel(character, mutationName, anchor, yaw, false)
	model.Parent = plot.Model

	local mainPart = model.PrimaryPart
	if mainPart then
		local detector = Instance.new("ClickDetector")
		detector.Parent = mainPart
		detector.MouseClick:Connect(function(clickingPlayer)
			if BaseManager.StealClickedCallback then
				BaseManager.StealClickedCallback(clickingPlayer, player, slotIndex)
			end
		end)
	end

	plotModels[player.UserId] = plotModels[player.UserId] or {}
	plotModels[player.UserId][slotIndex] = model
	return model
end

function BaseManager.RemoveBrainrotFromBase(player, slotIndex)
	local models = plotModels[player.UserId]
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
	local models = plotModels[player.UserId]
	if not models then
		return
	end
	for _, model in pairs(models) do
		model:Destroy()
	end
	plotModels[player.UserId] = {}
end

function BaseManager.GetBaseModelAtSlot(player, slotIndex)
	local models = plotModels[player.UserId]
	if not models then
		return nil
	end
	return models[slotIndex]
end

function BaseManager.RebuildBaseFromSave(player)
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

-- Base locking ---------------------------------------------------------------------------

local function lockStateFor(player)
	local state = lockStates[player.UserId]
	if not state then
		state = { LockedUntil = 0, CooldownUntil = 0 }
		lockStates[player.UserId] = state
	end
	return state
end

function BaseManager.IsBaseLocked(player)
	local state = lockStates[player.UserId]
	return state ~= nil and os.clock() < state.LockedUntil
end

function BaseManager.LockBase(player)
	local now = os.clock()
	local state = lockStateFor(player)
	if now < state.LockedUntil or now < state.CooldownUntil then
		return false
	end
	state.LockedUntil = now + BrainrotCatalog.LockDurationSeconds
	state.CooldownUntil = state.LockedUntil + BrainrotCatalog.LockCooldownSeconds
	return true
end

function BaseManager.GetLockStatus(player)
	local now = os.clock()
	local state = lockStates[player.UserId]
	local lockedUntil = state and state.LockedUntil or 0
	local cooldownUntil = state and state.CooldownUntil or 0
	return {
		Locked = now < lockedUntil,
		SecondsLeft = math.ceil(math.max(0, lockedUntil - now)),
		CooldownLeft = math.ceil(math.max(0, cooldownUntil - now)),
	}
end

-- Slots -------------------------------------------------------------------------------------

function BaseManager.RevealExtraSlot(player, slotIndex)
	local plot = playerPlots[player.UserId]
	if plot then
		MapBuilder.CreateSlotPad(plot, slotIndex)
	end
end

return BaseManager
