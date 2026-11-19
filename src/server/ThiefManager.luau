-- ThiefManager.luau
-- The NPC raccoon thief: every so often one slips in through the bandit
-- gate, walks to a random base and grabs its cheapest brainrot. Players
-- bop it (click it) for $250 and, if it is already carrying, the stolen
-- brainrot is restored to its owner.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local ThiefManager = {}

local remotes = nil
local banditGatePosition = Vector3.new(-52, 0, 0)
local thiefFolder = nil
local activeThief = nil

local BODY_Y = 2.2

local function showMessage(player, message)
	if remotes and remotes.ShowMessage then
		remotes.ShowMessage:FireClient(player, message)
	end
end

local function showBannerToAll(message)
	if remotes and remotes.ShowBanner then
		remotes.ShowBanner:FireAllClients(message)
	end
end

local function raccoonPart(model, name, size, offset, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CFrame = CFrame.new(offset)
	part.Parent = model
	return part
end

local function buildRaccoonModel(position)
	local model = Instance.new("Model")
	model.Name = "RaccoonThief"
	local grey = Color3.fromRGB(150, 150, 158)
	local dark = Color3.fromRGB(55, 52, 60)
	local origin = Vector3.new(position.X, BODY_Y, position.Z)

	local body = raccoonPart(model, "Body", Vector3.new(2.2, 2, 3), origin, grey)
	model.PrimaryPart = body
	raccoonPart(model, "Head", Vector3.new(1.7, 1.5, 1.6), origin + Vector3.new(0, 1.55, 1.6), grey)
	raccoonPart(model, "EarL", Vector3.new(0.45, 0.55, 0.25), origin + Vector3.new(-0.6, 2.45, 1.6), dark)
	raccoonPart(model, "EarR", Vector3.new(0.45, 0.55, 0.25), origin + Vector3.new(0.6, 2.45, 1.6), dark)
	raccoonPart(model, "Mask", Vector3.new(1.75, 0.45, 0.2), origin + Vector3.new(0, 1.7, 2.42), Color3.fromRGB(20, 18, 22))
	raccoonPart(model, "EyeL", Vector3.new(0.22, 0.22, 0.1), origin + Vector3.new(-0.4, 1.72, 2.55), Color3.fromRGB(255, 255, 255), Enum.Material.Neon)
	raccoonPart(model, "EyeR", Vector3.new(0.22, 0.22, 0.1), origin + Vector3.new(0.4, 1.72, 2.55), Color3.fromRGB(255, 255, 255), Enum.Material.Neon)
	raccoonPart(model, "TailA", Vector3.new(0.7, 0.7, 1.1), origin + Vector3.new(0, 0.5, -2), grey)
	raccoonPart(model, "TailB", Vector3.new(0.6, 0.6, 1), origin + Vector3.new(0, 1, -2.7), dark)
	raccoonPart(model, "TailC", Vector3.new(0.5, 0.5, 0.9), origin + Vector3.new(0, 1.5, -3.3), grey)
	raccoonPart(model, "LegFL", Vector3.new(0.55, 1.1, 0.55), origin + Vector3.new(-0.7, -1.4, 0.9), dark)
	raccoonPart(model, "LegFR", Vector3.new(0.55, 1.1, 0.55), origin + Vector3.new(0.7, -1.4, 0.9), dark)
	raccoonPart(model, "LegBL", Vector3.new(0.55, 1.1, 0.55), origin + Vector3.new(-0.7, -1.4, -0.9), dark)
	raccoonPart(model, "LegBR", Vector3.new(0.55, 1.1, 0.55), origin + Vector3.new(0.7, -1.4, -0.9), dark)

	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromOffset(260, 60)
	gui.StudsOffset = Vector3.new(0, 3.6, 0)
	gui.AlwaysOnTop = true
	gui.Parent = body
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.3
	label.BackgroundColor3 = Color3.fromRGB(30, 25, 35)
	label.Text = "RACCOON THIEF — BOP ME!"
	label.TextColor3 = Color3.fromRGB(255, 210, 120)
	label.TextSize = 18
	label.Font = Enum.Font.FredokaOne
	label.Parent = gui

	local detector = Instance.new("ClickDetector")
	detector.MaxActivationDistance = 40
	detector.Parent = body
	detector.MouseClick:Connect(function(player)
		ThiefManager.BopThief(player)
	end)

	return model
end

local function moveModelTowards(model, targetPosition, step)
	local primary = model.PrimaryPart
	if not primary then
		return 999
	end
	local current = primary.Position
	local flatTarget = Vector3.new(targetPosition.X, current.Y, targetPosition.Z)
	local delta = flatTarget - current
	local distance = delta.Magnitude
	if distance <= step then
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Position += delta
			end
		end
		return 0
	end
	local move = delta.Unit * step
	local look = CFrame.lookAt(current, flatTarget)
	local yawOnly = CFrame.new(current, current + Vector3.new(look.LookVector.X, 0, look.LookVector.Z))
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Position += move
		end
	end
	primary.CFrame = yawOnly + move
	return distance - step
end

local function destroyThief()
	if not activeThief then
		return
	end
	if activeThief.CarryModel then
		activeThief.CarryModel:Destroy()
		activeThief.CarryModel = nil
	end
	if activeThief.Model then
		activeThief.Model:Destroy()
		activeThief.Model = nil
	end
	activeThief = nil
end

local function buildCarryModel(characterEntry, mutationName)
	local model = Instance.new("Model")
	model.Name = "StolenBrainrot"
	local box = Instance.new("Part")
	box.Name = "Body"
	box.Size = Vector3.new(1.6, 1.6, 1.6)
	box.Color = characterEntry.BodyColor
	box.Material = Enum.Material.SmoothPlastic
	box.Anchored = true
	box.CanCollide = false
	box.Parent = model
	model.PrimaryPart = box
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromOffset(200, 50)
	gui.StudsOffset = Vector3.new(0, 1.6, 0)
	gui.AlwaysOnTop = true
	gui.Parent = box
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.3
	label.BackgroundColor3 = Color3.fromRGB(30, 25, 35)
	label.Text = BrainrotCatalog.GetDisplayName(characterEntry, mutationName)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 16
	label.Font = Enum.Font.FredokaOne
	label.Parent = gui
	return model
end

local function targetForThief(thief)
	if thief.State == "seek" then
		local victim = thief.Victim
		local plot = victim and BaseManager.GetPlotForPlayer(victim)
		if plot then
			local pad = plot.Pads[thief.Slot]
			if pad then
				return pad.Position
			end
			return plot.Center
		end
		return banditGatePosition
	end
	return banditGatePosition
end

local function onSeekArrival(thief)
	local victim = thief.Victim
	if not victim or not victim.Parent then
		destroyThief()
		return
	end
	if BaseManager.IsBaseLocked(victim) then
		thief.State = "flee"
		showMessage(victim, "The raccoon thief fled from your locked base!")
		return
	end
	local owned = PlayerData.GetOwnedAtSlot(victim, thief.Slot)
	if not owned then
		thief.State = "flee"
		return
	end
	local characterEntry = BrainrotCatalog.GetCharacterById(owned.CharacterId)
	if not characterEntry then
		thief.State = "flee"
		return
	end
	thief.CharacterId = owned.CharacterId
	thief.Mutation = owned.Mutation
	PlayerData.RemoveOwnedBrainrot(victim, thief.Slot)
	BaseManager.RemoveBrainrotFromBase(victim, thief.Slot)
	local carryModel = buildCarryModel(characterEntry, owned.Mutation)
	carryModel.Parent = thiefFolder or Workspace
	thief.CarryModel = carryModel
	thief.State = "escape"
	showMessage(victim, "A raccoon stole your " .. BrainrotCatalog.GetDisplayName(characterEntry, owned.Mutation) .. "! Bop it before it escapes!")
end

local function onGateArrival(thief)
	local victim = thief.Victim
	if thief.State == "escape" and victim and victim.Parent then
		local characterEntry = BrainrotCatalog.GetCharacterById(thief.CharacterId)
		local displayName = characterEntry and BrainrotCatalog.GetDisplayName(characterEntry, thief.Mutation) or "brainrot"
		showMessage(victim, "The raccoon got away with your " .. displayName .. "!")
	end
	destroyThief()
end

local function maybeSpawnThief()
	if activeThief then
		return
	end
	local candidates = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local data = PlayerData.Get(player)
		if data and PlayerData.IsLoaded(player) and BaseManager.GetPlotForPlayer(player) and #data.Owned > 0 then
			table.insert(candidates, player)
		end
	end
	if #candidates == 0 then
		return
	end
	local victim = candidates[math.random(1, #candidates)]
	local data = PlayerData.Get(victim)
	local cheapest = nil
	local cheapestCost = math.huge
	for _, entry in ipairs(data.Owned) do
		local characterEntry = BrainrotCatalog.GetCharacterById(entry.CharacterId)
		local cost = characterEntry and characterEntry.Cost or math.huge
		if cost < cheapestCost then
			cheapestCost = cost
			cheapest = entry
		end
	end
	if not cheapest then
		return
	end
	local model = buildRaccoonModel(banditGatePosition)
	model.Parent = thiefFolder or Workspace
	activeThief = {
		Model = model,
		CarryModel = nil,
		State = "seek",
		Victim = victim,
		CharacterId = cheapest.CharacterId,
		Mutation = cheapest.Mutation,
		Slot = cheapest.Slot,
	}
	showBannerToAll("A RACCOON THIEF IS LOOSE!")
end

function ThiefManager.IsThiefActive()
	return activeThief ~= nil
end

function ThiefManager.BopThief(player)
	if not activeThief then
		return
	end
	local bopperData = PlayerData.Get(player)
	if not bopperData then
		return
	end
	local thief = activeThief
	if thief.State == "escape" and thief.CarryModel then
		local victim = thief.Victim
		if victim and victim.Parent and PlayerData.Get(victim) then
			local characterEntry = BrainrotCatalog.GetCharacterById(thief.CharacterId)
			if characterEntry then
				local slotUsed = nil
				if not PlayerData.GetOwnedAtSlot(victim, thief.Slot) and PlayerData.GetTotalSlots(victim) >= thief.Slot then
					-- Only reuse the original slot when it is inside the
					-- victim's unlocked slot range and still free.
					local used = PlayerData.GetOwnedAtSlot(victim, thief.Slot)
					if not used then
						slotUsed = thief.Slot
					end
				end
				if not slotUsed then
					slotUsed = PlayerData.FindFreeSlot(victim)
				end
				if slotUsed then
					PlayerData.AddOwnedBrainrot(victim, thief.CharacterId, thief.Mutation, slotUsed)
					BaseManager.PlaceBrainrotOnBase(victim, characterEntry, thief.Mutation, slotUsed)
				else
					local victimData = PlayerData.Get(victim)
					victimData.Cash += characterEntry.Cost
					PlayerData.Sync(victim)
				end
			end
		end
	end
	bopperData.Cash += BrainrotCatalog.ThiefRewardCash
	PlayerData.Sync(player)
	showMessage(player, "Thief bopped! +$" .. BrainrotCatalog.ThiefRewardCash)
	destroyThief()
end

function ThiefManager.Init(remoteFolder, worldMap)
	remotes = remoteFolder
	if worldMap and worldMap.BanditGatePosition then
		banditGatePosition = worldMap.BanditGatePosition
	end
	thiefFolder = Workspace:FindFirstChild("Thieves")
	if not thiefFolder then
		thiefFolder = Instance.new("Folder")
		thiefFolder.Name = "Thieves"
		thiefFolder.Parent = Workspace
	end
	RunService.Heartbeat:Connect(function(deltaTime)
		local thief = activeThief
		if not thief or not thief.Model or not thief.Model.Parent then
			return
		end
		local victim = thief.Victim
		if not victim or not victim.Parent then
			destroyThief()
			return
		end
		local target = targetForThief(thief)
		local remaining = moveModelTowards(thief.Model, target, BrainrotCatalog.ThiefSpeedStudsPerSecond * deltaTime)
		if thief.CarryModel and thief.Model.PrimaryPart then
			local above = thief.Model.PrimaryPart.Position + Vector3.new(0, 3.4, 0)
			local carryPrimary = thief.CarryModel.PrimaryPart
			if carryPrimary then
				local delta = above - carryPrimary.Position
				for _, part in ipairs(thief.CarryModel:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Position += delta
					end
				end
			end
			if not thief.CarryModel.Parent then
				thief.CarryModel.Parent = thiefFolder or Workspace
			end
		end
		if remaining <= 4 then
			if thief.State == "seek" then
				-- Arrival is judged on flat distance to the pad, not the
				-- step remainder alone, so re-check the distance.
				local primary = thief.Model.PrimaryPart
				local flatDistance = primary and (Vector3.new(target.X, primary.Position.Y, target.Z) - primary.Position).Magnitude or 999
				if flatDistance <= 4 then
					onSeekArrival(thief)
				end
			else
				local primary = thief.Model.PrimaryPart
				local flatDistance = primary and (Vector3.new(target.X, primary.Position.Y, target.Z) - primary.Position).Magnitude or 999
				if flatDistance <= 4 then
					onGateArrival(thief)
				end
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(BrainrotCatalog.ThiefIntervalSeconds)
			maybeSpawnThief()
		end
	end)
end

return ThiefManager
