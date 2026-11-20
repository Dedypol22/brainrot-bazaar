-- ClientMain: the whole Brainrot Bazaar HUD, driven only by server snapshots.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))

local remotes = {}
for _, remoteName in ipairs({
	"RequestBuy",
	"RequestSell",
	"RequestBuySlot",
	"RequestLock",
	"RequestRebirth",
	"RequestSteal",
	"StateUpdate",
	"ShowBanner",
	"ShowMessage",
}) do
	remotes[remoteName] = remotesFolder:WaitForChild(remoteName)
end

local function formatMoney(amount)
	local value = math.floor(amount or 0)
	local negative = value < 0
	if negative then
		value = -value
	end
	local text = tostring(value)
	while true do
		local replaced
		text, replaced = text:gsub("^(%d+)(%d%d%d)", "%1,%2")
		if replaced == 0 then
			break
		end
	end
	if negative then
		return "-$" .. text
	end
	return "$" .. text
end

local function makeFrame(parent, name, size, position, color)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.Position = position
	frame.BackgroundColor3 = color or Color3.fromRGB(28, 26, 36)
	frame.BackgroundTransparency = 0.08
	frame.BorderSizePixel = 0
	frame.Parent = parent
	return frame
end

local function makeLabel(parent, name, size, position, text, textSize, textColor, alignment)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Text = text or ""
	label.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
	label.TextSize = textSize or 18
	label.TextXAlignment = alignment or Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextWrapped = false
	label.Font = Enum.Font.FredokaOne
	label.Parent = parent
	return label
end

local function makeButton(parent, name, size, position, text, textSize)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = Color3.fromRGB(80, 60, 120)
	button.BorderSizePixel = 0
	button.Text = text or ""
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = textSize or 18
	button.Font = Enum.Font.FredokaOne
	button.AutoButtonColor = true
	button.Parent = parent
	return button
end

local function setZIndexRecursive(instance, zIndex)
	if instance:IsA("GuiObject") then
		instance.ZIndex = zIndex
	end
	for _, child in ipairs(instance:GetChildren()) do
		setZIndexRecursive(child, zIndex)
	end
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BrainrotHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
screenGui.Parent = playerGui

local state = nil
local lastBeltKey = nil
local lastBaseKey = nil
local lastIndexRendered = -1
local bannerToken = 0
local messageToken = 0

-- Top bar starts clear of the Roblox menu buttons.
local topBar = makeFrame(screenGui, "TopBar", UDim2.new(0.76, 0, 0, 56), UDim2.new(0.12, 0, 0, 8))
topBar.BackgroundTransparency = 0.1

local cashLabel = makeLabel(topBar, "Cash", UDim2.new(0.25, 0, 1, 0), UDim2.new(0, 12, 0, 0), "$500", 24, Color3.fromRGB(160, 255, 170))
local incomeLabel = makeLabel(topBar, "Income", UDim2.new(0.24, 0, 1, 0), UDim2.new(0.25, 0, 0, 0), "$0/s", 20, Color3.fromRGB(140, 220, 255))
local rebirthsLabel = makeLabel(topBar, "Rebirths", UDim2.new(0.25, 0, 1, 0), UDim2.new(0.49, 0, 0, 0), "Rebirths: 0", 20, Color3.fromRGB(255, 220, 150))
local indexButton = makeButton(topBar, "IndexButton", UDim2.new(0.24, -10, 0, 38), UDim2.new(0.76, 0, 0, 9), "INDEX 0/52", 18)
indexButton.BackgroundColor3 = Color3.fromRGB(150, 90, 190)

-- Belt panel.
local beltPanel = makeFrame(screenGui, "BeltPanel", UDim2.new(0.27, 0, 0.42, 0), UDim2.new(0.12, 0, 0, 74))
makeLabel(beltPanel, "BeltTitle", UDim2.new(1, 0, 0, 30), UDim2.new(0, 12, 0, 4), "ON THE BELT", 22, Color3.fromRGB(255, 235, 150))
local beltList = Instance.new("ScrollingFrame")
beltList.Name = "BeltList"
beltList.Size = UDim2.new(1, -8, 1, -40)
beltList.Position = UDim2.new(0, 4, 0, 36)
beltList.BackgroundTransparency = 1
beltList.BorderSizePixel = 0
beltList.ScrollBarThickness = 6
beltList.CanvasSize = UDim2.new(0, 0, 0, 0)
beltList.Parent = beltPanel

-- Base panel.
local basePanel = makeFrame(screenGui, "BasePanel", UDim2.new(0.27, 0, 0.58, 0), UDim2.new(0.61, 0, 0, 74))
makeLabel(basePanel, "BaseTitle", UDim2.new(1, 0, 0, 30), UDim2.new(0, 12, 0, 4), "YOUR BASE", 22, Color3.fromRGB(255, 235, 150))
local baseList = Instance.new("ScrollingFrame")
baseList.Name = "BaseList"
baseList.Size = UDim2.new(1, -8, 1, -206)
baseList.Position = UDim2.new(0, 4, 0, 36)
baseList.BackgroundTransparency = 1
baseList.BorderSizePixel = 0
baseList.ScrollBarThickness = 6
baseList.CanvasSize = UDim2.new(0, 0, 0, 0)
baseList.Parent = basePanel

local buySlotButton = makeButton(basePanel, "BuySlot", UDim2.new(1, -16, 0, 34), UDim2.new(0, 8, 1, -162), "Buy slot", 16)
local lockButton = makeButton(basePanel, "Lock", UDim2.new(1, -16, 0, 34), UDim2.new(0, 8, 1, -122), "Lock base", 16)
local rebirthButton = makeButton(basePanel, "Rebirth", UDim2.new(1, -16, 0, 44), UDim2.new(0, 8, 1, -80), "Rebirth", 16)
rebirthButton.BackgroundColor3 = Color3.fromRGB(180, 110, 40)

-- Task line at the bottom.
local taskLabel = makeLabel(screenGui, "Task", UDim2.new(0.76, 0, 0, 30), UDim2.new(0.12, 0, 1, -54), "Buy a brainrot from the belt!", 20, Color3.fromRGB(255, 245, 210))
taskLabel.BackgroundColor3 = Color3.fromRGB(20, 18, 26)
taskLabel.BackgroundTransparency = 0.35
taskLabel.TextXAlignment = Enum.TextXAlignment.Center

-- Banner and toast.
local bannerLabel = makeLabel(screenGui, "Banner", UDim2.new(0.66, 0, 0, 72), UDim2.new(0.17, 0, 0.14, 0), "", 40, Color3.fromRGB(255, 240, 120), Enum.TextXAlignment.Center)
bannerLabel.TextStrokeTransparency = 0.25
bannerLabel.Visible = false
local messageLabel = makeLabel(screenGui, "Message", UDim2.new(0.5, 0, 0, 36), UDim2.new(0.25, 0, 0.85, 0), "", 18, Color3.fromRGB(255, 255, 255), Enum.TextXAlignment.Center)
messageLabel.BackgroundColor3 = Color3.fromRGB(30, 26, 40)
messageLabel.BackgroundTransparency = 0.2
messageLabel.Visible = false

-- Prize Book panel.
local indexPanel = makeFrame(screenGui, "IndexPanel", UDim2.new(0.7, 0, 0.76, 0), UDim2.new(0.5, 0, 0.5, 0))
indexPanel.AnchorPoint = Vector2.new(0.5, 0.5)
indexPanel.Visible = false
indexPanel.BackgroundColor3 = Color3.fromRGB(20, 18, 28)
indexPanel.BackgroundTransparency = 0.03
makeLabel(indexPanel, "IndexTitle", UDim2.new(1, -70, 0, 38), UDim2.new(0, 16, 0, 8), "PRIZE BOOK", 30, Color3.fromRGB(255, 230, 130))
local indexHeader = makeLabel(indexPanel, "IndexHeader", UDim2.new(1, -32, 0, 44), UDim2.new(0, 16, 0, 44), "0/52 collected", 16, Color3.fromRGB(220, 220, 235))
indexHeader.TextWrapped = true
local closeIndexButton = makeButton(indexPanel, "CloseIndex", UDim2.new(0, 56, 0, 32), UDim2.new(1, -72, 0, 10), "X", 20)
closeIndexButton.BackgroundColor3 = Color3.fromRGB(160, 60, 70)

local indexGrid = Instance.new("ScrollingFrame")
indexGrid.Name = "IndexGrid"
indexGrid.Size = UDim2.new(1, -24, 1, -108)
indexGrid.Position = UDim2.new(0, 12, 0, 96)
indexGrid.BackgroundTransparency = 1
indexGrid.BorderSizePixel = 0
indexGrid.ScrollBarThickness = 8
indexGrid.CanvasSize = UDim2.new(0, 0, 0, 0)
indexGrid.AutomaticCanvasSize = Enum.AutomaticSize.Y
indexGrid.Parent = indexPanel

local indexGridLayout = Instance.new("UIGridLayout")
indexGridLayout.Name = "GridLayout"
indexGridLayout.CellSize = UDim2.new(0, 150, 0, 106)
indexGridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
indexGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
indexGridLayout.Parent = indexGrid

setZIndexRecursive(indexPanel, 20)

local function orderedRoster()
	local roster = {}
	for _, character in ipairs(BrainrotCatalog.Characters) do
		table.insert(roster, character)
	end
	table.sort(roster, function(a, b)
		local rarityA = BrainrotCatalog.GetRarityInfo(a.Rarity)
		local rarityB = BrainrotCatalog.GetRarityInfo(b.Rarity)
		local orderA = rarityA and rarityA.Order or 99
		local orderB = rarityB and rarityB.Order or 99
		if orderA ~= orderB then
			return orderA < orderB
		end
		if a.Cost ~= b.Cost then
			return a.Cost < b.Cost
		end
		return a.Id < b.Id
	end)
	return roster
end

local function rebuildIndexGrid(indexList)
	for _, child in ipairs(indexGrid:GetChildren()) do
		if not child:IsA("UIGridLayout") then
			child:Destroy()
		end
	end

	local collected = {}
	for _, characterId in ipairs(indexList or {}) do
		collected[characterId] = true
	end

	local order = 0
	for _, character in ipairs(orderedRoster()) do
		order += 1
		local isCollected = collected[character.Id] == true
		local rarityColor = BrainrotCatalog.GetRarityColor(character.Rarity)

		local cell = makeFrame(indexGrid, "Cell_" .. character.Id, UDim2.new(0, 150, 0, 106), UDim2.new(0, 0, 0, 0), Color3.fromRGB(40, 38, 50))
		cell.LayoutOrder = order
		cell.Size = UDim2.new(0, 150, 0, 106)

		local chip = Instance.new("TextLabel")
		chip.Name = "RarityChip"
		chip.Size = UDim2.new(1, -12, 0, 22)
		chip.Position = UDim2.new(0, 6, 0, 6)
		chip.BackgroundColor3 = isCollected and rarityColor or Color3.fromRGB(90, 90, 96)
		chip.BackgroundTransparency = 0
		chip.BorderSizePixel = 0
		chip.Text = character.Rarity
		chip.TextColor3 = Color3.fromRGB(25, 25, 30)
		chip.TextSize = 14
		chip.Font = Enum.Font.FredokaOne
		chip.Parent = cell

		local nameLabel = makeLabel(cell, "Name", UDim2.new(1, -12, 0, 30), UDim2.new(0, 6, 0, 32), isCollected and character.Name or "???", 16, isCollected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 190))
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd

		local bottomText = isCollected and ("$" .. tostring(character.IncomePerSecond) .. "/s") or character.Rarity
		local bottomColor = isCollected and Color3.fromRGB(150, 255, 160) or rarityColor
		makeLabel(cell, "Bottom", UDim2.new(1, -12, 0, 24), UDim2.new(0, 6, 0, 68), bottomText, 15, bottomColor)
	end
end

local function updateIndexHeader()
	if not state then
		return
	end
	local text = "Collected " .. tostring(state.IndexCount) .. " of " .. tostring(state.IndexTotal) .. " brainrots"
	if state.NextMilestone then
		text = text .. "   •   Next prize: " .. tostring(state.NextMilestone.Count) .. " collected — " .. formatMoney(state.NextMilestone.Reward)
	else
		text = text .. "   •   Every Prize Book prize claimed. Legend!"
	end
	indexHeader.Text = text
	indexButton.Text = "INDEX " .. tostring(state.IndexCount) .. "/" .. tostring(state.IndexTotal)
end

local function buildBeltCard(entry, index)
	local card = makeButton(beltList, "BeltCard_" .. tostring(entry.Id), UDim2.new(1, -8, 0, 64), UDim2.new(0, 4, 0, (index - 1) * 70), "", 16)
	card.BackgroundColor3 = Color3.fromRGB(45, 42, 58)
	card.Text = ""
	card:SetAttribute("BeltId", entry.Id)

	local rarityColor = BrainrotCatalog.GetRarityColor(entry.Rarity)
	local nameLabel = makeLabel(card, "Name", UDim2.new(1, -16, 0, 26), UDim2.new(0, 8, 0, 4), entry.Name, 17, Color3.fromRGB(255, 255, 255))
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	makeLabel(card, "Rarity", UDim2.new(0, 80, 0, 22), UDim2.new(1, -86, 0, 6), entry.Rarity, 14, rarityColor, Enum.TextXAlignment.Right)
	makeLabel(card, "Rate", UDim2.new(0.5, -8, 0, 24), UDim2.new(0, 8, 0, 34), "$" .. tostring(entry.Rate) .. "/s", 16, Color3.fromRGB(150, 255, 160))
	makeLabel(card, "Price", UDim2.new(0.5, -8, 0, 24), UDim2.new(0.5, 0, 0, 34), formatMoney(entry.Cost), 16, Color3.fromRGB(255, 220, 120), Enum.TextXAlignment.Right)

	card.MouseButton1Click:Connect(function()
		remotes.RequestBuy:FireServer(entry.Id)
	end)
	return card
end

local function rebuildBelt(belt)
	for _, child in ipairs(beltList:GetChildren()) do
		child:Destroy()
	end
	for index, entry in ipairs(belt) do
		buildBeltCard(entry, index)
	end
	beltList.CanvasSize = UDim2.new(0, 0, 0, #belt * 70)
end

local function buildOwnedCard(entry, index)
	local card = makeFrame(baseList, "OwnedCard_" .. tostring(entry.Slot), UDim2.new(1, -8, 0, 56), UDim2.new(0, 4, 0, (index - 1) * 62), Color3.fromRGB(45, 42, 58))
	local nameLabel = makeLabel(card, "Name", UDim2.new(0.65, -12, 0, 26), UDim2.new(0, 8, 0, 4), entry.Name, 16, Color3.fromRGB(255, 255, 255))
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	makeLabel(card, "Rate", UDim2.new(0.65, -12, 0, 22), UDim2.new(0, 8, 0, 30), "$" .. tostring(entry.Rate) .. "/s", 15, Color3.fromRGB(150, 255, 160))
	makeLabel(card, "Rarity", UDim2.new(0, 80, 0, 22), UDim2.new(0.65, 0, 0, 8), entry.Rarity, 13, BrainrotCatalog.GetRarityColor(entry.Rarity), Enum.TextXAlignment.Right)

	local sellButton = makeButton(card, "Sell", UDim2.new(0, 56, 0, 34), UDim2.new(1, -62, 0.5, -17), "Sell", 15)
	sellButton.BackgroundColor3 = Color3.fromRGB(150, 70, 70)
	sellButton.MouseButton1Click:Connect(function()
		remotes.RequestSell:FireServer(entry.Slot)
	end)
	return card
end

local function rebuildBase(owned)
	for _, child in ipairs(baseList:GetChildren()) do
		child:Destroy()
	end
	for index, entry in ipairs(owned) do
		buildOwnedCard(entry, index)
	end
	baseList.CanvasSize = UDim2.new(0, 0, 0, #owned * 62)
end

local function computeTaskText(currentState)
	if currentState.Carrying then
		return "Carry it home to your base!"
	end
	if currentState.ThiefActive then
		return "BOP THE RACCOON THIEF!"
	end
	if #currentState.Owned == 0 then
		return "Buy a brainrot from the belt!"
	end
	if currentState.NextMilestone and (currentState.NextMilestone.Count - currentState.IndexCount) <= 3 then
		local remaining = currentState.NextMilestone.Count - currentState.IndexCount
		return "Prize Book: " .. tostring(currentState.IndexCount) .. "/" .. tostring(currentState.IndexTotal) .. " — " .. tostring(remaining) .. " more for " .. formatMoney(currentState.NextMilestone.Reward) .. "!"
	end
	if currentState.NextSlotCost and currentState.Cash >= currentState.NextSlotCost then
		return "Buy another base slot!"
	end
	return "Earn " .. formatMoney(currentState.RebirthThreshold) .. " total to rebirth (+25% income)"
end

local function refreshButtons()
	if not state then
		return
	end
	if state.NextSlotCost then
		buySlotButton.Visible = true
		buySlotButton.Text = "Buy slot (" .. formatMoney(state.NextSlotCost) .. ")"
	else
		buySlotButton.Visible = false
	end

	local lockState = state.Lock or { Locked = false, SecondsLeft = 0, CooldownLeft = 0 }
	if lockState.Locked then
		lockButton.Text = "LOCKED (" .. tostring(lockState.SecondsLeft) .. "s)"
	elseif lockState.CooldownLeft and lockState.CooldownLeft > 0 then
		lockButton.Text = "Lock cooldown (" .. tostring(lockState.CooldownLeft) .. "s)"
	else
		lockButton.Text = "Lock base (" .. tostring(BrainrotCatalog.LockDurationSeconds) .. "s)"
	end

	if state.TotalEarned >= state.RebirthThreshold then
		rebirthButton.Text = "REBIRTH NOW (+" .. tostring(math.floor((state.RebirthMultiplier - 1) * 100)) .. "%)"
	else
		rebirthButton.Text = "Rebirth: " .. formatMoney(state.TotalEarned) .. " / " .. formatMoney(state.RebirthThreshold) .. " (x" .. string.format("%.2f", state.RebirthMultiplier) .. ")"
	end
end

local function onStateUpdate(newState)
	state = newState

	cashLabel.Text = formatMoney(state.Cash)
	incomeLabel.Text = formatMoney(state.IncomePerSecond) .. "/s"
	rebirthsLabel.Text = "Rebirths: " .. tostring(state.Rebirths)
	updateIndexHeader()

	local beltKey = ""
	for _, entry in ipairs(state.Belt) do
		beltKey = beltKey .. tostring(entry.Id) .. ","
	end
	if beltKey ~= lastBeltKey then
		lastBeltKey = beltKey
		rebuildBelt(state.Belt)
	end

	local baseKey = ""
	for _, entry in ipairs(state.Owned) do
		baseKey = baseKey .. tostring(entry.Slot) .. ":" .. entry.CharacterId .. ":" .. tostring(entry.Mutation) .. ","
	end
	if baseKey ~= lastBaseKey then
		lastBaseKey = baseKey
		rebuildBase(state.Owned)
	end

	refreshButtons()
	taskLabel.Text = computeTaskText(state)

	if state.IndexCount ~= lastIndexRendered then
		lastIndexRendered = state.IndexCount
		rebuildIndexGrid(state.Index)
	end
end

indexButton.MouseButton1Click:Connect(function()
	indexPanel.Visible = not indexPanel.Visible
end)
closeIndexButton.MouseButton1Click:Connect(function()
	indexPanel.Visible = false
end)

buySlotButton.MouseButton1Click:Connect(function()
	remotes.RequestBuySlot:FireServer()
end)
lockButton.MouseButton1Click:Connect(function()
	remotes.RequestLock:FireServer()
end)
rebirthButton.MouseButton1Click:Connect(function()
	remotes.RequestRebirth:FireServer()
end)

remotes.StateUpdate.OnClientEvent:Connect(onStateUpdate)

remotes.ShowBanner.OnClientEvent:Connect(function(text)
	bannerToken += 1
	local token = bannerToken
	bannerLabel.Text = text
	bannerLabel.Visible = true
	task.delay(3, function()
		if token == bannerToken then
			bannerLabel.Visible = false
		end
	end)
end)

remotes.ShowMessage.OnClientEvent:Connect(function(text)
	messageToken += 1
	local token = messageToken
	messageLabel.Text = text
	messageLabel.Visible = true
	task.delay(2.5, function()
		if token == messageToken then
			messageLabel.Visible = false
		end
	end)
end)
