-- ClientMain.client.luau
-- The whole interface of Brainrot Bazaar, built from code as one ScreenGui
-- over the 3D world: cash and income at the top centre, the wave banner
-- under it, conveyor cards at the bottom centre, the player's base panel
-- on the right, and the Lock and Rebirth buttons at the bottom right.
-- All text stays clear of the top-left corner, where Roblox puts its own
-- menu buttons. The client only asks; the server decides every number.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
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

-- ---------------------------------------------------------------------------
-- Small helpers
-- ---------------------------------------------------------------------------

local function formatMoney(amount)
	local text = tostring(math.floor(amount))
	local result = ""
	while #text > 3 do
		result = "," .. string.sub(text, -3) .. result
		text = string.sub(text, 1, -4)
	end
	return text .. result
end

local function makeFrame(parent, name, size, position, anchorPoint, color, transparency)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.Position = position
	frame.AnchorPoint = anchorPoint or Vector2.new(0, 0)
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = transparency or 0
	frame.BorderSizePixel = 0
	frame.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame
	return frame
end

local function makeLabel(parent, name, size, position, text, textSize, textColor, backgroundTransparency)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = backgroundTransparency == nil and 1 or backgroundTransparency
	label.Text = text
	label.TextSize = textSize
	label.TextColor3 = textColor
	label.Font = Enum.Font.SourceSansBold
	label.TextScaled = false
	label.TextWrapped = true
	label.Parent = parent
	return label
end

local function makeButton(parent, name, size, position, text, textSize, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Text = text
	button.TextSize = textSize
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.SourceSansBold
	button.TextWrapped = true
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button
	return button
end

-- ---------------------------------------------------------------------------
-- The ScreenGui and its panels
-- ---------------------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotBazaarGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = playerGui

-- Top centre: cash and income, large enough to read at a glance.
local topBar = makeFrame(gui, "TopBar", UDim2.new(0, 430, 0, 78), UDim2.new(0.5, 0, 0, 10), Vector2.new(0.5, 0), Color3.fromRGB(25, 25, 40), 0.15)
local cashLabel = makeLabel(topBar, "CashLabel", UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 4), "$100", 32, Color3.fromRGB(255, 220, 80), 1)
local incomeLabel = makeLabel(topBar, "IncomeLabel", UDim2.new(1, 0, 0, 28), UDim2.new(0, 0, 0, 44), "+$0/s", 20, Color3.fromRGB(140, 230, 140), 1)

-- Wave warning banner, just under the top bar. Hidden until an event comes.
local waveBanner = makeFrame(gui, "WaveBanner", UDim2.new(0, 500, 0, 48), UDim2.new(0.5, 0, 0, 98), Vector2.new(0.5, 0), Color3.fromRGB(200, 40, 40), 0.1)
waveBanner.Visible = false
local waveLabel = makeLabel(waveBanner, "WaveLabel", UDim2.new(1, -16, 1, -8), UDim2.new(0, 8, 0, 4), "", 24, Color3.fromRGB(255, 255, 255), 1)

-- Feedback messages in the middle of the screen.
local messageLabel = makeLabel(gui, "MessageLabel", UDim2.new(0, 600, 0, 44), UDim2.new(0.5, 0, 0.42, 0), "", 26, Color3.fromRGB(255, 255, 255), 0.3)
messageLabel.AnchorPoint = Vector2.new(0.5, 0)
messageLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
messageLabel.Visible = false

-- Bottom centre: cards for the brainrots currently riding the conveyor.
local beltFrame = Instance.new("Frame")
beltFrame.Name = "BeltFrame"
beltFrame.AnchorPoint = Vector2.new(0.5, 1)
beltFrame.Position = UDim2.new(0.5, 0, 1, -10)
beltFrame.Size = UDim2.new(0, 800, 0, 116)
beltFrame.BackgroundTransparency = 1
beltFrame.BorderSizePixel = 0
beltFrame.Parent = gui
local beltLayout = Instance.new("UIListLayout")
beltLayout.FillDirection = Enum.FillDirection.Horizontal
beltLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
beltLayout.VerticalAlignment = Enum.VerticalAlignment.Center
beltLayout.Padding = UDim.new(0, 8)
beltLayout.Parent = beltFrame
local beltTitle = makeLabel(gui, "BeltTitle", UDim2.new(0, 400, 0, 26), UDim2.new(0.5, 0, 1, -152), "ON THE CONVEYOR — CLICK A CARD TO BUY", 18, Color3.fromRGB(255, 255, 255), 0.4)
beltTitle.AnchorPoint = Vector2.new(0.5, 0)
beltTitle.BackgroundColor3 = Color3.fromRGB(25, 25, 40)

-- Right side: the player's base panel, with a sell button per brainrot.
local basePanel = makeFrame(gui, "BasePanel", UDim2.new(0, 290, 0, 420), UDim2.new(1, -12, 0.5, 0), Vector2.new(1, 0.5), Color3.fromRGB(25, 25, 40), 0.15)
local baseTitle = makeLabel(basePanel, "BaseTitle", UDim2.new(1, -16, 0, 32), UDim2.new(0, 8, 0, 8), "YOUR BASE", 22, Color3.fromRGB(255, 220, 80), 1)
local baseList = Instance.new("ScrollingFrame")
baseList.Name = "BaseList"
baseList.Size = UDim2.new(1, -16, 1, -96)
baseList.Position = UDim2.new(0, 8, 0, 44)
baseList.BackgroundTransparency = 1
baseList.BorderSizePixel = 0
baseList.ScrollBarThickness = 4
baseList.AutomaticCanvasSize = Enum.AutomaticSize.Y
baseList.CanvasSize = UDim2.new(0, 0, 0, 0)
baseList.Parent = basePanel
local baseListLayout = Instance.new("UIListLayout")
baseListLayout.Padding = UDim.new(0, 6)
baseListLayout.Parent = baseList
local buySlotButton = makeButton(basePanel, "BuySlotButton", UDim2.new(1, -16, 0, 40), UDim2.new(0, 8, 1, -48), "Buy Slot", 18, Color3.fromRGB(60, 140, 220))

-- Bottom right: Lock Base and Rebirth.
local actionFrame = Instance.new("Frame")
actionFrame.Name = "ActionFrame"
actionFrame.AnchorPoint = Vector2.new(1, 1)
actionFrame.Position = UDim2.new(1, -12, 1, -136)
actionFrame.Size = UDim2.new(0, 220, 0, 112)
actionFrame.BackgroundTransparency = 1
actionFrame.BorderSizePixel = 0
actionFrame.Parent = gui
local lockButton = makeButton(actionFrame, "LockButton", UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0, 0), "Lock Base (45s)", 18, Color3.fromRGB(200, 80, 80))
local rebirthButton = makeButton(actionFrame, "RebirthButton", UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0, 62), "Rebirth", 18, Color3.fromRGB(150, 80, 220))

-- Left side, vertically centred: how to play, small and out of the way.
local hintLabel = makeLabel(
	gui,
	"HintLabel",
	UDim2.new(0, 250, 0, 110),
	UDim2.new(0, 10, 0.5, 0),
	"HOW TO PLAY\nBuy brainrots from the belt.\nClick a rival's brainrot to steal it!\nLock your base to stop thieves.\nRun home when the wave comes!",
	15,
	Color3.fromRGB(230, 230, 230),
	0.4
)
hintLabel.AnchorPoint = Vector2.new(0, 0.5)
hintLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
hintLabel.TextXAlignment = Enum.TextXAlignment.Left

-- ---------------------------------------------------------------------------
-- Rendering the state the server sends every second
-- ---------------------------------------------------------------------------

local function renderBeltCards(belt)
	for _, child in ipairs(beltFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	for _, entry in ipairs(belt) do
		local card = makeButton(
			beltFrame,
			"BeltCard" .. entry.Id,
			UDim2.new(0, 124, 0, 106),
			UDim2.new(0, 0, 0, 0),
			entry.Name .. "\n" .. entry.Rarity .. "\n$" .. formatMoney(entry.Cost) .. "\n$" .. formatMoney(entry.Rate) .. "/s",
			15,
			BrainrotCatalog.GetRarityColor(entry.Rarity)
		)
		card.TextColor3 = Color3.fromRGB(255, 255, 255)
		local beltId = entry.Id
		card.MouseButton1Click:Connect(function()
			remotes.RequestBuy:FireServer(beltId)
		end)
	end
end

local function renderBaseList(owned)
	for _, child in ipairs(baseList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for _, entry in ipairs(owned) do
		local row = Instance.new("Frame")
		row.Name = "BaseRow" .. entry.Slot
		row.Size = UDim2.new(1, 0, 0, 46)
		row.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
		row.BorderSizePixel = 0
		row.Parent = baseList
		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 8)
		rowCorner.Parent = row

		local nameLabel = makeLabel(row, "NameLabel", UDim2.new(1, -96, 1, 0), UDim2.new(0, 8, 0, 0), entry.Name .. "\n$" .. formatMoney(entry.Rate) .. "/s", 15, BrainrotCatalog.GetRarityColor(entry.Rarity), 1)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left

		local refund = math.floor(entry.Cost * BrainrotCatalog.SellRefundFraction)
		local sellButton = makeButton(row, "SellButton", UDim2.new(0, 84, 0, 32), UDim2.new(1, -92, 0, 7), "Sell $" .. formatMoney(refund), 14, Color3.fromRGB(200, 120, 40))
		local slotIndex = entry.Slot
		sellButton.MouseButton1Click:Connect(function()
			remotes.RequestSell:FireServer(slotIndex)
		end)
	end
end

local function onStateUpdate(state)
	cashLabel.Text = "$" .. formatMoney(state.Cash)
	local bonusPercent = math.floor((state.RebirthMultiplier - 1) * 100 + 0.5)
	incomeLabel.Text = "+$" .. formatMoney(state.IncomePerSecond) .. "/s    Rebirths: " .. state.Rebirths .. " (+" .. bonusPercent .. "%)"

	renderBeltCards(state.Belt)
	renderBaseList(state.Owned)

	if state.NextSlotCost then
		buySlotButton.Text = "Buy Slot — $" .. formatMoney(state.NextSlotCost) .. "  (" .. state.Slots .. "/10)"
	else
		buySlotButton.Text = "Base Full  (" .. state.Slots .. "/10)"
	end

	if state.Lock.Locked then
		lockButton.Text = "LOCKED  " .. state.Lock.LockRemaining .. "s"
		lockButton.BackgroundColor3 = Color3.fromRGB(90, 180, 90)
	elseif state.Lock.CooldownRemaining > 0 then
		lockButton.Text = "Lock Base (" .. state.Lock.CooldownRemaining .. "s)"
		lockButton.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
	else
		lockButton.Text = "Lock Base (45s)"
		lockButton.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
	end

	rebirthButton.Text = "Rebirth: $" .. formatMoney(state.TotalEarned) .. " / $" .. formatMoney(state.RebirthThreshold) .. "  (" .. state.Rebirths .. "x)"
end

remotes.StateUpdate.OnClientEvent:Connect(onStateUpdate)

-- ---------------------------------------------------------------------------
-- Banners, messages and buttons
-- ---------------------------------------------------------------------------

local bannerToken = 0
remotes.ShowBanner.OnClientEvent:Connect(function(text, durationSeconds)
	bannerToken = bannerToken + 1
	local myToken = bannerToken
	waveLabel.Text = text
	waveBanner.Visible = true
	task.delay(durationSeconds or 3, function()
		if myToken == bannerToken then
			waveBanner.Visible = false
		end
	end)
end)

local messageToken = 0
remotes.ShowMessage.OnClientEvent:Connect(function(text)
	messageToken = messageToken + 1
	local myToken = messageToken
	messageLabel.Text = text
	messageLabel.Visible = true
	task.delay(3, function()
		if myToken == messageToken then
			messageLabel.Visible = false
		end
	end)
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
