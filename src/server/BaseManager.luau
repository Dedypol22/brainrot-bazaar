-- BaseManager.luau
-- Owns the eight base plots: who sits where, the brainrot models standing on
-- each base, the plot signs, base locking and slot revealing. The models
-- themselves are built by BrainrotSpawner; this module just places them.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local BrainrotSpawner = require(script.Parent:WaitForChild("BrainrotSpawner"))
local MapBuilder = require(script.Parent:WaitForChild("MapBuilder"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local BaseManager = {}

-- Assigned by Main; called when someone clicks a brainrot on another base.
BaseManager.StealClickedCallback = function(_clickingPlayer, _ownerPlayer, _slotIndex) end

local plots = nil
local plotByPlayer = {} -- [player] = plot
local ownerNameByPlot = {} -- [plot] = display string for the sign
local modelsByPlayer = {} -- [player] = { [slotIndex] = Model }
local lockByPlayer = {} -- [player] = { LockedUntil = t, CooldownUntil = t }

local function formatMoney(amount)
	local text = tostring(math.floor(amount))
	local formatted = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	formatted = formatted:gsub("^,", "")
	return formatted
end

local function updateSignForPlot(plot, incomePerSecond)
	if not plot or not plot.Sign then
		return
	end
	if plot.OwnerUserId == 0 then
		plot.Sign.Text = "BASE " .. plot.Index
	else
		local name = ownerNameByPlot[plot] or "Player"
		plot.Sign.Text = name .. "\n$" .. formatMoney(incomePerSecond or 0) .. "/s"
	end
end

function BaseManager.Init(worldMap)
	plots = worldMap.Plots
	for _, plot in ipairs(plots) do
		updateSignForPlot(plot, 0)
	end
end

function BaseManager.GetPlotForPlayer(player)
	return plotByPlayer[player]
end

function BaseManager.AssignPlotToPlayer(player)
	if plotByPlayer[player] then
		return plotByPlayer[player]
	end
	if not plots then
		return nil
	end
	for _, plot in ipairs(plots) do
		if plot.OwnerUserId == 0 then
			plot.OwnerUserId = player.UserId
			ownerNameByPlot[plot] = player.Name
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
	plotByPlayer[player] = nil
	modelsByPlayer[player] = nil
	lockByPlayer[player] = nil
	if plot then
		plot.OwnerUserId = 0
		ownerNameByPlot[plot] = nil
		updateSignForPlot(plot, 0)
	end
end

function BaseManager.IsPositionInsideOwnBase(player, position)
	local plot = plotByPlayer[player]
	if not plot then
		return false
	end
	return math.abs(position.X - plot.Center.X) <= 12
		and math.abs(position.Z - plot.Center.Z) <= 8
end

function BaseManager.PlaceBrainrotOnBase(player, character, mutationName, slotIndex)
	local plot = plotByPlayer[player]
	if not plot then
		return nil
	end
	local pad = plot.Pads[slotIndex]
	if not pad then
		pad = MapBuilder.CreateSlotPad(plot, slotIndex)
	end
	BaseManager.RemoveBrainrotFromBase(player, slotIndex)
	-- North plots face south toward the belt and vice versa.
	local yaw = (plot.Center.Z < 0) and 0 or math.pi
	local position = pad.Position + Vector3.new(0, 0.15, 0)
	local model = BrainrotSpawner.BuildBrainrotModel(character, mutationName, position, yaw, false)
	model.Parent = plot.Model
	local mainPart = model.PrimaryPart
	if mainPart then
		local detector = Instance.new("ClickDetector")
		detector.MaxActivationDistance = 24
		detector.MouseClick:Connect(function(clickingPlayer)
			if clickingPlayer ~= player then
				BaseManager.StealClickedCallback(clickingPlayer, player, slotIndex)
			end
		end)
		detector.Parent = mainPart
	end
	modelsByPlayer[player] = modelsByPlayer[player] or {}
	modelsByPlayer[player][slotIndex] = model
	return model
end

function BaseManager.RemoveBrainrotFromBase(player, slotIndex)
	local models = modelsByPlayer[player]
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
	local models = modelsByPlayer[player]
	if not models then
		return
	end
	for slotIndex, model in pairs(models) do
		model:Destroy()
		models[slotIndex] = nil
	end
end

function BaseManager.GetBaseModelAtSlot(player, slotIndex)
	local models = modelsByPlayer[player]
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

-- ---------------------------------------------------------------------------
-- Locking
-- ---------------------------------------------------------------------------

function BaseManager.IsBaseLocked(player)
	local state = lockByPlayer[player]
	if not state then
		return false
	end
	return os.clock() < state.LockedUntil
end

function BaseManager.LockBase(player)
	local now = os.clock()
	local state = lockByPlayer[player]
	if state and now < state.CooldownUntil then
		return false
	end
	if state and now < state.LockedUntil then
		return false
	end
	local lockedUntil = now + BrainrotCatalog.LockDurationSeconds
	lockByPlayer[player] = {
		LockedUntil = lockedUntil,
		CooldownUntil = lockedUntil + BrainrotCatalog.LockCooldownSeconds,
	}
	return true
end

function BaseManager.GetLockStatus(player)
	local now = os.clock()
	local state = lockByPlayer[player]
	if not state then
		return { Locked = false, SecondsLeft = 0, CooldownLeft = 0 }
	end
	local locked = now < state.LockedUntil
	return {
		Locked = locked,
		SecondsLeft = locked and math.ceil(state.LockedUntil - now) or 0,
		CooldownLeft = math.max(0, math.ceil(state.CooldownUntil - now)),
	}
end

-- ---------------------------------------------------------------------------
-- Slots and signs
-- ---------------------------------------------------------------------------

function BaseManager.RevealExtraSlot(player, slotIndex)
	local plot = plotByPlayer[player]
	if not plot then
		return
	end
	if not plot.Pads[slotIndex] then
		MapBuilder.CreateSlotPad(plot, slotIndex)
	end
end

function BaseManager.UpdatePlotSign(player, incomePerSecond)
	local plot = plotByPlayer[player]
	if plot then
		updateSignForPlot(plot, incomePerSecond)
	end
end

-- Keep signs honest when a player renames (display names do not change in
-- session, but leaving players should not strand their name on a sign).
Players.PlayerRemoving:Connect(function(player)
	if plotByPlayer[player] then
		-- Main also releases the plot; this is only a sign safety net.
		local plot = plotByPlayer[player]
		ownerNameByPlot[plot] = player.Name
	end
end)

return BaseManager
