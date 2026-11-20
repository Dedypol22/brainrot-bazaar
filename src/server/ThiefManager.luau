-- ThiefManager: the raccoon bandit that raids a base and can be bopped for cash.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))

local ThiefManager = {}

local activeThief = nil
local remotes = nil
local worldMap = nil
local thievesFolder = nil
local initialized = false

local BODY_HEIGHT = 2.2
local ARRIVE_DISTANCE = 4

local function showMessage(player, message)
	if remotes and remotes.ShowMessage and player then
		remotes.ShowMessage:FireClient(player, message)
	end
end

local function showBannerToAll(text)
	if not remotes or not remotes.ShowBanner then
		return
	end
	for _, player in ipairs(Players:GetPlayers()) do
		remotes.ShowBanner:FireClient(player, text)
	end
end

local function makeRaccoonPart(model, baseCFrame, name, size, offset, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CFrame = baseCFrame * CFrame.new(offset)
	part.Parent = model
	return part
end

local function buildRaccoonModel(position)
	local model = Instance.new("Model")
	model.Name = "RaccoonThief"

	local baseCFrame = CFrame.new(position + Vector3.new(0, BODY_HEIGHT, 0))
	local body = makeRaccoonPart(model, baseCFrame, "Body", Vector3.new(2.2, 2, 3), Vector3.new(0, 0, 0), Color3.fromRGB(120, 120, 130), Enum.Material.SmoothPlastic)
	model.PrimaryPart = body

	makeRaccoonPart(model, baseCFrame, "Head", Vector3.new(1.6, 1.4, 1.2), Vector3.new(0, 0.6, -1.75), Color3.fromRGB(140, 140, 150), Enum.Material.SmoothPlastic)
	makeRaccoonPart(model, baseCFrame, "EarL", Vector3.new(0.45, 0.55, 0.3), Vector3.new(-0.55, 1.5, -1.75), Color3.fromRGB(60, 60, 70), Enum.Material.SmoothPlastic)
	makeRaccoonPart(model, baseCFrame, "EarR", Vector3.new(0.45, 0.55, 0.3), Vector3.new(0.55, 1.5, -1.75), Color3.fromRGB(60, 60, 70), Enum.Material.SmoothPlastic)
	makeRaccoonPart(model, baseCFrame, "Mask", Vector3.new(1.35, 0.36, 0.12), Vector3.new(0, 0.7, -2.36), Color3.fromRGB(30, 30, 35), Enum.Material.SmoothPlastic)
	makeRaccoonPart(model, baseCFrame, "EyeL", Vector3.new(0.2, 0.2, 0.12), Vector3.new(-0.38, 0.76, -2.42), Color3.fromRGB(255, 255, 255), Enum.Material.Neon)
	makeRaccoonPart(model, baseCFrame, "EyeR", Vector3.new(0.2, 0.2, 0.12), Vector3.new(0.38, 0.76, -2.42), Color3.fromRGB(255, 255, 255), Enum.Material.Neon)

	for i = 1, 3 do
		local tailColor = (i % 2 == 1) and Color3.fromRGB(120, 120, 130) or Color3.fromRGB(50, 50, 60)
		local tail = makeRaccoonPart(model, baseCFrame, "Tail" .. i, Vector3.new(0.8, 0.5, 0.9), Vector3.new(0, -0.2 + i * 0.45, 1.9 + i * 0.55), tailColor, Enum.Material.SmoothPlastic)
		tail.CFrame = tail.CFrame * CFrame.Angles(math.rad(-18), 0, 0)
	end

	for _, xSide in ipairs({ -0.7, 0.7 }) do
		for _, zSide in ipairs({ -0.9, 0.9 }) do
			makeRaccoonPart(model, baseCFrame, "Leg", Vector3.new(0.4, 1.2, 0.4), Vector3.new(xSide, -1.3, zSide), Color3.fromRGB(80, 80, 90), Enum.Material.SmoothPlastic)
		end
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ThiefLabel"
	billboard.Size = UDim2.fromScale(12, 3)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 180
	billboard.Parent = body

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Text = "RACCOON THIEF — BOP ME!"
	label.TextColor3 = Color3.fromRGB(255, 110, 90)
	label.TextSize = 22
	label.TextStrokeTransparency = 0.3
	label.Font = Enum.Font.FredokaOne
	label.Parent = billboard

	local detector = Instance.new("ClickDetector")
	detector.Name = "BopDetector"
	detector.MaxActivationDistance = 40
	detector.MouseClick:Connect(function(player)
		ThiefManager.BopThief(player)
	end)
	detector.Parent = body

	model.WorldPivot = baseCFrame
	model.Parent = thievesFolder
	return model
end

local function buildThiefCarry(character, mutationName, bodyPosition)
	local displayName = BrainrotCatalog.GetDisplayName(character, mutationName)

	local model = Instance.new("Model")
	model.Name = "ThiefCarry"

	local part = Instance.new("Part")
	part.Name = "Loot"
	part.Anchored = true
	part.CanCollide = false
	part.Size = Vector3.new(1.5, 1.5, 1.5)
	part.Color = character.BodyColor
	part.Material = Enum.Material.SmoothPlastic
	part.CFrame = CFrame.new(bodyPosition + Vector3.new(0, 3, 0))
	part.Parent = model
	model.PrimaryPart = part
	model.WorldPivot = CFrame.new(bodyPosition + Vector3.new(0, 3, 0))

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "LootLabel"
	billboard.Size = UDim2.fromScale(9, 2.5)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 1.6, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 150
	billboard.Parent = part

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Text = displayName
	label.TextColor3 = Color3.fromRGB(255, 245, 220)
	label.TextSize = 20
	label.TextStrokeTransparency = 0.3
	label.Font = Enum.Font.FredokaOne
	label.Parent = billboard

	model.Parent = thievesFolder
	return model
end

local function destroyThief()
	if not activeThief then
		return
	end
	if activeThief.CarryModel then
		activeThief.CarryModel:Destroy()
	end
	if activeThief.Model then
		activeThief.Model:Destroy()
	end
	activeThief = nil
end

local function getTargetPosition(thief)
	if thief.State == "seek" then
		local plot = BaseManager.GetPlotForPlayer(thief.Victim)
		if plot then
			local pad = plot.Pads[thief.Slot]
			if pad then
				return pad.Position
			end
			return plot.Center
		end
		return worldMap.BanditGatePosition
	end
	return worldMap.BanditGatePosition
end

local function handleArrival()
	local thief = activeThief
	if not thief then
		return
	end

	if thief.State == "seek" then
		local victim = thief.Victim
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

		local character = BrainrotCatalog.GetCharacterById(owned.CharacterId)
		if not character then
			thief.State = "flee"
			return
		end

		PlayerData.RemoveOwnedBrainrot(victim, thief.Slot)
		BaseManager.RemoveBrainrotFromBase(victim, thief.Slot)

		thief.CharacterId = owned.CharacterId
		thief.Mutation = owned.Mutation
		thief.Character = character
		thief.CarryModel = buildThiefCarry(character, owned.Mutation, thief.Position)
		thief.State = "escape"

		showMessage(victim, "A raccoon stole your " .. BrainrotCatalog.GetDisplayName(character, owned.Mutation) .. "! Bop it before it escapes!")
	elseif thief.State == "escape" then
		local victim = thief.Victim
		if thief.Character then
			showMessage(victim, "The raccoon got away with your " .. BrainrotCatalog.GetDisplayName(thief.Character, thief.Mutation) .. "!")
		end
		destroyThief()
	elseif thief.State == "flee" then
		destroyThief()
	end
end

local function maybeSpawnThief()
	if activeThief then
		return
	end

	local candidates = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if PlayerData.IsLoaded(player) and BaseManager.GetPlotForPlayer(player) then
			local data = PlayerData.Get(player)
			if data and #data.Owned > 0 then
				table.insert(candidates, player)
			end
		end
	end

	if #candidates == 0 then
		return
	end

	local victim = candidates[math.random(1, #candidates)]
	local data = PlayerData.Get(victim)
	local targetEntry = nil
	local lowestCost = math.huge
	for _, entry in ipairs(data.Owned) do
		local character = BrainrotCatalog.GetCharacterById(entry.CharacterId)
		if character and character.Cost < lowestCost then
			lowestCost = character.Cost
			targetEntry = entry
		end
	end
	if not targetEntry then
		return
	end

	local model = buildRaccoonModel(worldMap.BanditGatePosition)
	activeThief = {
		Model = model,
		CarryModel = nil,
		State = "seek",
		Victim = victim,
		Slot = targetEntry.Slot,
		CharacterId = nil,
		Mutation = nil,
		Character = nil,
		Position = Vector3.new(worldMap.BanditGatePosition.X, BODY_HEIGHT, worldMap.BanditGatePosition.Z),
	}

	showBannerToAll("A RACCOON THIEF IS LOOSE!")
end

function ThiefManager.Init(remoteFolder, map)
	if initialized then
		return
	end
	initialized = true
	remotes = remoteFolder
	worldMap = map

	thievesFolder = Workspace:FindFirstChild("Thieves")
	if not thievesFolder then
		thievesFolder = Instance.new("Folder")
		thievesFolder.Name = "Thieves"
		thievesFolder.Parent = Workspace
	end

	task.spawn(function()
		while true do
			task.wait(BrainrotCatalog.ThiefIntervalSeconds)
			maybeSpawnThief()
		end
	end)

	RunService.Heartbeat:Connect(function(deltaTime)
		local thief = activeThief
		if not thief then
			return
		end

		if thief.Victim and thief.Victim.Parent == nil then
			destroyThief()
			return
		end

		local target = getTargetPosition(thief)
		local current = thief.Position
		local flatTarget = Vector3.new(target.X, BODY_HEIGHT, target.Z)
		local flatCurrent = Vector3.new(current.X, BODY_HEIGHT, current.Z)
		local difference = flatTarget - flatCurrent
		local distance = difference.Magnitude

		if distance <= ARRIVE_DISTANCE then
			handleArrival()
			return
		end

		local step = BrainrotCatalog.ThiefSpeedStudsPerSecond * deltaTime
		local move = math.min(step, distance)
		local direction = difference.Unit
		local newPosition = flatCurrent + direction * move
		thief.Position = newPosition

		if thief.Model and thief.Model.Parent then
			thief.Model:PivotTo(CFrame.lookAt(newPosition, newPosition + direction))
		end
		if thief.CarryModel and thief.CarryModel.Parent then
			thief.CarryModel:PivotTo(CFrame.new(newPosition + Vector3.new(0, 3, 0)))
		end
	end)
end

function ThiefManager.IsThiefActive()
	return activeThief ~= nil
end

function ThiefManager.BopThief(player)
	local thief = activeThief
	if not thief then
		return
	end
	local data = PlayerData.Get(player)
	if not data then
		return
	end

	if thief.State == "escape" and thief.CharacterId then
		local victim = thief.Victim
		local character = BrainrotCatalog.GetCharacterById(thief.CharacterId)
		if victim and victim.Parent and character then
			local slotUsed = nil
			if not PlayerData.GetOwnedAtSlot(victim, thief.Slot) then
				slotUsed = thief.Slot
			else
				slotUsed = PlayerData.FindFreeSlot(victim)
			end
			if slotUsed then
				PlayerData.AddOwnedBrainrot(victim, thief.CharacterId, thief.Mutation, slotUsed)
				BaseManager.PlaceBrainrotOnBase(victim, character, thief.Mutation, slotUsed)
			else
				local victimData = PlayerData.Get(victim)
				if victimData then
					victimData.Cash += character.Cost
					PlayerData.Sync(victim)
				end
			end
		end
		if thief.CarryModel then
			thief.CarryModel:Destroy()
			thief.CarryModel = nil
		end
	end

	data.Cash += BrainrotCatalog.ThiefRewardCash
	PlayerData.Sync(player)
	showMessage(player, "Thief bopped! +$" .. tostring(BrainrotCatalog.ThiefRewardCash))

	destroyThief()
end

return ThiefManager
