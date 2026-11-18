-- BaseManager.luau (server module)
-- Owns the eight base plots: who owns which plot, which brainrot model
-- stands on each slot, the lock that stops stealing, and the signs that
-- show each owner's name and income. The owned-brainrot records themselves
-- live in PlayerData; this module owns the visible models and the lock.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local BrainrotSpawner = require(script.Parent:WaitForChild("BrainrotSpawner"))
local MapBuilder = require(script.Parent:WaitForChild("MapBuilder"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local BaseManager = {}

-- Called by Main with (player, ownerPlayer, slotIndex) when a base
-- brainrot is clicked, so a click can become a steal attempt.
BaseManager.StealClickedCallback = nil

local plots = {} -- array of plot records from MapBuilder
local plotByPlayer = {} -- [Player] -> plot record
local baseModels = {} -- [Player] -> { [slotIndex] = Model }

-- Writes the owner's name and income per second on a plot's sign.
local function updateSignForPlot(plot, incomePerSecond)
	if not plot or not plot.SignLabel then
		return
	end
	local label = plot.SignLabel:FindFirstChild("Text")
	if not label then
		return
	end
	if plot.Owner then
		label.Text = plot.Owner.DisplayName .. "'s Bazaar\n$" .. math.floor(incomePerSecond) .. "/s"
		plot.SignLabel.Enabled = true
	else
		-- An unclaimed plot shows no floating text at all: a row of
		-- "Empty Plot" billboards was the ugliest thing on the map.
		plot.SignLabel.Enabled = false
	end
end

-- Finds the plot a player owns, or nil when they have none yet.
function BaseManager.GetPlotForPlayer(player)
	return plotByPlayer[player]
end

-- Gives the player the first unclaimed plot and writes their name on it.
function BaseManager.AssignPlotToPlayer(player)
	if plotByPlayer[player] then
		return plotByPlayer[player]
	end
	for _, plot in ipairs(plots) do
		if plot.Owner == nil then
			plot.Owner = player
			plotByPlayer[player] = plot
			baseModels[player] = {}
			updateSignForPlot(plot, 0)
			return plot
		end
	end
	return nil
end

-- Frees a plot when its owner leaves, so the next player can claim it.
function BaseManager.ReleasePlotForPlayer(player)
	local plot = plotByPlayer[player]
	if plot then
		plot.Owner = nil
		plot.LockUntil = 0
		plot.CooldownUntil = 0
		plotByPlayer[player] = nil
		updateSignForPlot(plot, 0)
	end
	if baseModels[player] then
		for _, model in pairs(baseModels[player]) do
			if model then
				model:Destroy()
			end
		end
		baseModels[player] = nil
	end
end

-- Is a world position inside this player's own plot rectangle? The
-- plot pad is rotated by the plot angle, so rotate the offset back
-- into the plot's local frame first; an axis-aligned check in world
-- space would wrongly judge the corners and wrongly accept ground
-- just outside them. The pad is 24 deep (local X) by 16 wide.
function BaseManager.IsPositionInsideOwnBase(player, position)
	local plot = plotByPlayer[player]
	if not plot then
		return false
	end
	local offset = position - plot.Center
	local angle = plot.Angle
	local cosA = math.cos(angle)
	local sinA = math.sin(angle)
	local localX = offset.X * cosA + offset.Z * sinA
	local localZ = -offset.X * sinA + offset.Z * cosA
	return math.abs(localX) <= 12 and math.abs(localZ) <= 8
end

-- Puts a brainrot model on one slot of a player's base, facing the plaza.
function BaseManager.PlaceBrainrotOnBase(player, character, mutationName, slotIndex)
	local plot = plotByPlayer[player]
	if not plot then
		return nil
	end
	local slotPosition = plot.SlotPositions[slotIndex]
	if not slotPosition then
		return nil
	end
	BaseManager.RemoveBrainrotFromBase(player, slotIndex)

	-- Face the plaza: the model's front (+X) points at the plaza centre.
	-- Base creatures stand a touch smaller than belt creatures so a
	-- full base of ten does not crowd itself off the pad.
	local yaw = -plot.Angle + math.pi
	local model = BrainrotSpawner.BuildBrainrotModel(character, mutationName, slotPosition, yaw, false, 1.9)
	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("SlotIndex", slotIndex)

	local clicker = Instance.new("ClickDetector")
	clicker.Name = "StealClick"
	clicker.MaxActivationDistance = 32
	clicker.MouseClick:Connect(function(clickingPlayer)
		if BaseManager.StealClickedCallback then
			BaseManager.StealClickedCallback(clickingPlayer, player, slotIndex)
		end
	end)
	clicker.Parent = model.PrimaryPart

	if not baseModels[player] then
		baseModels[player] = {}
	end
	baseModels[player][slotIndex] = model
	return model
end

-- Takes the model off one slot, if one is standing there.
function BaseManager.RemoveBrainrotFromBase(player, slotIndex)
	local models = baseModels[player]
	if not models then
		return
	end
	local model = models[slotIndex]
	if model then
		model:Destroy()
	end
	models[slotIndex] = nil
end

-- Takes every brainrot model off a player's base (rebirth).
function BaseManager.ClearAllBaseBrainrots(player)
	local models = baseModels[player]
	if not models then
		return
	end
	for slotIndex, model in pairs(models) do
		if model then
			model:Destroy()
		end
		models[slotIndex] = nil
	end
end

-- Rebuilds a player's base models from their saved brainrots (on join).
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

-- The model standing on one slot, or nil.
function BaseManager.GetBaseModelAtSlot(player, slotIndex)
	local models = baseModels[player]
	if not models then
		return nil
	end
	return models[slotIndex]
end

-- ---------------------------------------------------------------------------
-- Base lock (the defence against stealing)
-- ---------------------------------------------------------------------------

function BaseManager.IsBaseLocked(player)
	local plot = plotByPlayer[player]
	if not plot then
		return false
	end
	return os.time() < plot.LockUntil
end

-- Locks the base for 45 seconds; starts the 2-minute cooldown either way.
-- Returns true when the lock went on, false with a reason when it cannot.
function BaseManager.LockBase(player)
	local plot = plotByPlayer[player]
	if not plot then
		return false, "You have no base yet."
	end
	local now = os.time()
	if now < plot.LockUntil then
		return false, "Your base is already locked."
	end
	if now < plot.CooldownUntil then
		return false, "Lock is cooling down for " .. (plot.CooldownUntil - now) .. "s."
	end
	plot.LockUntil = now + BrainrotCatalog.LockDurationSeconds
	plot.CooldownUntil = now + BrainrotCatalog.LockCooldownSeconds
	return true, "Base locked for " .. BrainrotCatalog.LockDurationSeconds .. " seconds!"
end

function BaseManager.GetLockStatus(player)
	local plot = plotByPlayer[player]
	local now = os.time()
	if not plot then
		return { Locked = false, LockRemaining = 0, CooldownRemaining = 0 }
	end
	return {
		Locked = now < plot.LockUntil,
		LockRemaining = math.max(0, plot.LockUntil - now),
		CooldownRemaining = math.max(0, plot.CooldownUntil - now),
	}
end

-- ---------------------------------------------------------------------------
-- Extra slots and the plot sign
-- ---------------------------------------------------------------------------

-- Shows the pad for a slot the player just bought.
function BaseManager.RevealExtraSlot(player, slotIndex)
	local plot = plotByPlayer[player]
	if not plot then
		return
	end
	if not plot.SlotPads[slotIndex] then
		MapBuilder.CreateSlotPad(plot, slotIndex)
	end
end

-- Writes the owner's name and income per second on their plot sign.
function BaseManager.UpdatePlotSign(player, incomePerSecond)
	updateSignForPlot(plotByPlayer[player], incomePerSecond)
end

function BaseManager.Init(worldMap)
	plots = worldMap.Plots
end

return BaseManager
