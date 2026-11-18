-- ClientMain.client.luau
-- The whole Brainrot Bazaar HUD, built in code: a top bar with cash, income
-- and rebirths; the belt panel on the left; your base panel on the right;
-- a task line that always points at the next goal; and banner/toast labels
-- for server messages. The client only ever renders the snapshots the
-- server sends — it never changes game state itself.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local remoteFolder = ReplicatedStorage:WaitForChild("Remotes")
local remotes = {
	RequestBuy = remoteFolder:WaitForChild("RequestBuy"),
	RequestSell = remoteFolder:WaitForChild("RequestSell"),
	RequestBuySlot = remoteFolder:WaitForChild("RequestBuySlot"),
	RequestLock = remoteFolder:WaitForChild("RequestLock"),
	RequestRebirth = remoteFolder:WaitForChild("RequestRebirth"),
	StateUpdate = remoteFolder:WaitForChild("StateUpdate"),
	ShowBanner = remoteFolder:WaitForChild("ShowBanner"),
	ShowMessage = remoteFolder:WaitForChild("ShowMessage"),
}

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function formatMoney(amount)
	local value = math.floor(amount or 0)
	local text = tostring(value)
	local formatted = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	formatted = formatted:gsub("^,", "")
	return "$" .. formatted
end

local function addCorner(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = instance
	return corner
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
	return frame
end

local function makeLabel(parent, name, size, position, anchorPoint, text, textSize, textColor, align)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.AnchorPoint = anchorPoint or Vector2.new(0, 0)
	label.BackgroundTransparency = 1
	label.Text = text or ""
	label.TextSize = textSize or 16
	label.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = align or Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = parent
	return label
end

local function makeButton(parent, name, size, position, anchorPoint, text, textSize, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.AnchorPoint = anchorPoint or Vector2.new(0, 0)
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Text = text or ""
	button.TextSize = textSize or 15
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.GothamBold
	button.AutoButtonColor = true
	button.Parent = parent
	addCorner(button, 8)
	return button
end

local function makeScrollList(parent, name, size, position)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = name
	scroll.Size = size
	scroll.Position = position
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 4
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.Parent = parent
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 6)
	layout.Parent = scroll
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 4)
	padding.PaddingRight = UDim.new(0, 4)
	padding.PaddingTop = UDim.new(0, 4)
	padding.Parent = scroll
	return scroll
end

-- ---------------------------------------------------------------------------
-- HUD skeleton
-- ---------------------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHUD"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local PANEL_COLOR = Color3.fromRGB(30, 32, 48)
local CARD_COLOR = Color3.fromRGB(48, 52, 74)

-- Top bar, kept clear of the Roblox menu buttons in the top-left corner.
local topBar = makeFrame(gui, "TopBar", UDim2.new(0.76, 0, 0, 46), UDim2.new(0.12, 0, 0, 10),
	Vector2.new(0, 0), PANEL_COLOR, 0.15)
addCorner(topBar, 10)
local cashLabel = makeLabel(topBar, "Cash", UDim2.new(0.34, 0, 1, 0), UDim2.new(0, 0, 0, 0),
	Vector2.new(0, 0), "$500", 20, Color3.fromRGB(140, 255, 150))
local incomeLabel = makeLabel(topBar, "Income", UDim2.new(0.33, 0, 1, 0), UDim2.new(0.34, 0, 0, 0),
	Vector2.new(0, 0), "$0/s", 18, Color3.fromRGB(255, 255, 255))
local rebirthLabel = makeLabel(topBar, "Rebirths", UDim2.new(0.33, 0, 1, 0), UDim2.new(0.67, 0, 0, 0),
	Vector2.new(0, 0), "Rebirths: 0", 18, Color3.fromRGB(255, 170, 255))

local taskLabel = makeLabel(gui, "Task", UDim2.new(0.76, 0, 0, 26), UDim2.new(0.12, 0, 0, 62),
	Vector2.new(0, 0), "", 16, Color3.fromRGB(255, 230, 150))

local bannerLabel = makeLabel(gui, "Banner", UDim2.new(0.8, 0, 0, 64), UDim2.new(0.5, 0, 0.1, 0),
	Vector2.new(0.5, 0), "", 42, Color3.fromRGB(120, 210, 255))
bannerLabel.Visible = false
local toastLabel = makeLabel(gui, "Toast", UDim2.new(0.6, 0, 0, 34), UDim2.new(0.5, 0, 0.2, 0),
	Vector2.new(0.5, 0), "", 18, Color3.fromRGB(255, 255, 255))
toastLabel.Visible = false

-- Belt panel (left).
local beltPanel = makeFrame(gui, "BeltPanel", UDim2.new(0, 224, 0, 400), UDim2.new(0, 8, 0.16, 0),
	Vector2.new(0, 0), PANEL_COLOR, 0.15)
addCorner(beltPanel, 10)
makeLabel(beltPanel, "Title", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 2),
	Vector2.new(0, 0), "ON THE BELT", 17, Color3.fromRGB(255, 210, 90))
local beltList = makeScrollList(beltPanel, "BeltList", UDim2.new(1, -4, 1, -38), UDim2.new(0, 2, 0, 34))

-- Base panel (right).
local basePanel = makeFrame(gui, "BasePanel", UDim2.new(0, 224, 0, 400), UDim2.new(1, -8, 0.16, 0),
	Vector2.new(1, 0), PANEL_COLOR, 0.15)
addCorner(basePanel, 10)
makeLabel(basePanel, "Title", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 2),
	Vector2.new(0, 0), "YOUR BASE", 17, Color3.fromRGB(140, 255, 150))
local baseList = makeScrollList(basePanel, "BaseList", UDim2.new(1, -4, 0, 218), UDim2.new(0, 2, 0, 34))
local buySlotButton = makeButton(basePanel, "BuySlot", UDim2.new(1, -12, 0, 34), UDim2.new(0, 6, 0, 258),
	Vector2.new(0, 0), "Buy Slot", 15, Color3.fromRGB(70, 140, 90))
local lockButton = makeButton(basePanel, "Lock", UDim2.new(1, -12, 0, 34), UDim2.new(0, 6, 0, 298),
	Vector2.new(0, 0), "Lock Base", 15, Color3.fromRGB(90, 110, 180))
local rebirthButton = makeButton(basePanel, "Rebirth", UDim2.new(1, -12, 0, 34), UDim2.new(0, 6, 0, 338),
	Vector2.new(0, 0), "Rebirth", 14, Color3.fromRGB(170, 80, 200))

buySlotButton.MouseButton1Click:Connect(function()
	remotes.RequestBuySlot:FireServer()
end)
lockButton.MouseButton1Click:Connect(function()
	remotes.RequestLock:FireServer()
end)
rebirthButton.MouseButton1Click:Connect(function()
	remotes.RequestRebirth:FireServer()
end)

-- ---------------------------------------------------------------------------
-- Rendering
-- ---------------------------------------------------------------------------

local currentState = nil
local lastBeltKey = nil
local lastOwnedKey = nil

local function beltKeyOf(belt)
	local ids = {}
	for _, entry in ipairs(belt) do
		table.insert(ids, tostring(entry.Id))
	end
	return table.concat(ids, ",")
end

local function ownedKeyOf(owned)
	local parts = {}
	for _, entry in ipairs(owned) do
		table.insert(parts, entry.Slot .. ":" .. entry.CharacterId .. ":" .. entry.Mutation)
	end
	return table.concat(parts, ",")
end

local function renderBelt(belt)
	for _, child in ipairs(beltList:GetChildren()) do
		if child:IsA("GuiButton") or child:IsA("Frame") then
			child:Destroy()
		end
	end
	if #belt == 0 then
		makeLabel(beltList, "Empty", UDim2.new(1, -8, 0, 40), UDim2.new(0, 0, 0, 0),
			Vector2.new(0, 0), "The belt is empty...", 14, Color3.fromRGB(200, 200, 210))
		return
	end
	-- Show the most valuable brainrots first: sort a copy by income rate,
	-- highest earner at the top of the panel.
	local sorted = {}
	for _, entry in ipairs(belt) do
		table.insert(sorted, entry)
	end
	table.sort(sorted, function(a, b)
		return (a.Rate or 0) > (b.Rate or 0)
	end)
	for _, entry in ipairs(sorted) do
		local card = makeButton(beltList, "BeltCard" .. entry.Id, UDim2.new(1, -8, 0, 58),
			UDim2.new(0, 0, 0, 0), Vector2.new(0, 0), "", 14, CARD_COLOR)
		makeLabel(card, "Name", UDim2.new(1, -10, 0, 20), UDim2.new(0, 5, 0, 3),
			Vector2.new(0, 0), entry.Name, 14, Color3.fromRGB(255, 255, 255), Enum.TextXAlignment.Left)
		local rarityColor = BrainrotCatalog.GetRarityColor(entry.Rarity)
		makeLabel(card, "Rarity", UDim2.new(0.5, 0, 0, 16), UDim2.new(0, 5, 0, 24),
			Vector2.new(0, 0), entry.Rarity, 12, rarityColor, Enum.TextXAlignment.Left)
		makeLabel(card, "Rate", UDim2.new(0.5, -5, 0, 16), UDim2.new(0.5, 0, 0, 24),
			Vector2.new(0, 0), formatMoney(entry.Rate) .. "/s", 12, Color3.fromRGB(140, 255, 150), Enum.TextXAlignment.Right)
		makeLabel(card, "Price", UDim2.new(1, -10, 0, 16), UDim2.new(0, 5, 0, 40),
			Vector2.new(0, 0), formatMoney(entry.Cost), 13, Color3.fromRGB(255, 220, 90), Enum.TextXAlignment.Left)
		local beltId = entry.Id
		card.MouseButton1Click:Connect(function()
			remotes.RequestBuy:FireServer(beltId)
		end)
	end
end

local function renderBase(owned)
	for _, child in ipairs(baseList:GetChildren()) do
		if child:IsA("GuiButton") or child:IsA("Frame") then
			child:Destroy()
		end
	end
	if #owned == 0 then
		makeLabel(baseList, "Empty", UDim2.new(1, -8, 0, 40), UDim2.new(0, 0, 0, 0),
			Vector2.new(0, 0), "Nothing here yet.\nBuy from the belt!", 14, Color3.fromRGB(200, 200, 210))
		return
	end
	for _, entry in ipairs(owned) do
		local card = makeFrame(baseList, "BaseCard" .. entry.Slot, UDim2.new(1, -8, 0, 46),
			UDim2.new(0, 0, 0, 0), Vector2.new(0, 0), CARD_COLOR, 0)
		addCorner(card, 8)
		makeLabel(card, "Name", UDim2.new(1, -70, 0, 20), UDim2.new(0, 5, 0, 3),
			Vector2.new(0, 0), entry.Name, 13, Color3.fromRGB(255, 255, 255), Enum.TextXAlignment.Left)
		makeLabel(card, "Rate", UDim2.new(1, -70, 0, 16), UDim2.new(0, 5, 0, 24),
			Vector2.new(0, 0), formatMoney(entry.Rate) .. "/s", 12, Color3.fromRGB(140, 255, 150), Enum.TextXAlignment.Left)
		local sellButton = makeButton(card, "Sell", UDim2.new(0, 56, 0, 28), UDim2.new(1, -5, 0.5, 0),
			Vector2.new(1, 0.5), "Sell", 13, Color3.fromRGB(180, 80, 70))
		local slot = entry.Slot
		sellButton.MouseButton1Click:Connect(function()
			remotes.RequestSell:FireServer(slot)
		end)
	end
end

local function computeTaskText(state)
	if state.Carrying then
		if state.Carrying.Steal then
			return "Run! Carry the stolen brainrot home!"
		end
		return "Carry it home to your base!"
	end
	if #state.Owned == 0 then
		return "Buy a brainrot from the belt!"
	end
	if state.TotalEarned >= state.RebirthThreshold then
		return "You can rebirth! +25% income forever"
	end
	if state.NextSlotCost and #state.Owned >= state.Slots and state.Cash >= state.NextSlotCost then
		return "Your base is full — buy another slot!"
	end
	return "Earn $1,000,000 total to rebirth (+25% income)"
end

local function refreshButtons(state)
	if state.NextSlotCost then
		buySlotButton.Visible = true
		buySlotButton.Text = "Buy Slot (" .. formatMoney(state.NextSlotCost) .. ")"
	else
		buySlotButton.Visible = false
	end
	if state.Lock and state.Lock.Locked then
		lockButton.Text = "Locked (" .. tostring(state.Lock.SecondsLeft) .. "s)"
	elseif state.Lock and state.Lock.CooldownLeft and state.Lock.CooldownLeft > 0 then
		lockButton.Text = "Lock (cooldown " .. tostring(state.Lock.CooldownLeft) .. "s)"
	else
		lockButton.Text = "Lock Base (45s)"
	end
	local multiplierText = string.format("x%.2f", state.RebirthMultiplier or 1)
	rebirthButton.Text = "Rebirth " .. formatMoney(state.TotalEarned) .. " / "
		.. formatMoney(state.RebirthThreshold) .. " (" .. multiplierText .. ")"
end

local function onStateUpdate(state)
	if type(state) ~= "table" then
		return
	end
	currentState = state
	cashLabel.Text = formatMoney(state.Cash)
	incomeLabel.Text = formatMoney(state.IncomePerSecond) .. "/s"
	rebirthLabel.Text = "Rebirths: " .. tostring(state.Rebirths)
	taskLabel.Text = computeTaskText(state)

	local beltKey = beltKeyOf(state.Belt or {})
	if beltKey ~= lastBeltKey then
		lastBeltKey = beltKey
		renderBelt(state.Belt or {})
	end
	local ownedKey = ownedKeyOf(state.Owned or {})
	if ownedKey ~= lastOwnedKey then
		lastOwnedKey = ownedKey
		renderBase(state.Owned or {})
	end
	refreshButtons(state)
end

-- ---------------------------------------------------------------------------
-- Banners and toasts
-- ---------------------------------------------------------------------------

local bannerToken = 0
remotes.ShowBanner.OnClientEvent:Connect(function(text)
	bannerToken += 1
	local myToken = bannerToken
	bannerLabel.Text = tostring(text)
	bannerLabel.Visible = true
	task.delay(3, function()
		if bannerToken == myToken then
			bannerLabel.Visible = false
		end
	end)
end)

local toastToken = 0
remotes.ShowMessage.OnClientEvent:Connect(function(text)
	toastToken += 1
	local myToken = toastToken
	toastLabel.Text = tostring(text)
	toastLabel.Visible = true
	task.delay(2.5, function()
		if toastToken == myToken then
			toastLabel.Visible = false
		end
	end)
end)

remotes.StateUpdate.OnClientEvent:Connect(onStateUpdate)
