-- ClientMain.client.luau
-- The whole Brainrot Bazaar HUD, built in code: top bar, belt panel,
-- base panel, the Prize Book index panel, task line, banners and toasts.
-- Rendering is driven entirely by the server's state snapshots.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))

local remotes = {}
for _, remoteName in ipairs({ "RequestBuy", "RequestSell", "RequestBuySlot", "RequestLock", "RequestRebirth", "RequestSteal", "StateUpdate", "ShowBanner", "ShowMessage" }) do
	remotes[remoteName] = remotesFolder:WaitForChild(remoteName)
end

local function formatMoney(amount)
	local value = math.floor(amount or 0)
	local text = tostring(value)
	local out = ""
	local count = 0
	for i = #text, 1, -1 do
		out = string.sub(text, i, i) .. out
		count += 1
		if count % 3 == 0 and i > 1 then
			out = "," .. out
		end
	end
	return "$" .. out
end

local function makeFrame(parent, name, size, position, backgroundColor)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.Position = position
	frame.BackgroundColor3 = backgroundColor or Color3.fromRGB(35, 32, 48)
	frame.BackgroundTransparency = 0.12
	frame.BorderSizePixel = 0
	frame.Parent = parent
	return frame
end

local function makeLabel(parent, name, size, position, text, textSize, textColor)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Text = text or ""
	label.TextSize = textSize or 16
	label.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.FredokaOne
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = parent
	return label
end

local function makeButton(parent, name, size, position, text, backgroundColor)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = backgroundColor or Color3.fromRGB(80, 140, 255)
	button.BorderSizePixel = 0
	button.Text = text or ""
	button.TextSize = 15
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.FredokaOne
	button.AutoButtonColor = true
	button.Parent = parent
	return button
end

-- Root gui ---------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotBazaarHUD"
gui.ResetOnSpawn = false
gui.Parent = playerGui

-- Top bar (starts clear of the Roblox menu buttons in the top-left).
local topBar = makeFrame(gui, "TopBar", UDim2.new(0.76, 0, 0, 46), UDim2.new(0.12, 0, 0, 8), Color3.fromRGB(30, 28, 42))
local cashLabel = makeLabel(topBar, "Cash", UDim2.new(0.3, 0, 1, 0), UDim2.new(0.02, 0, 0, 0), "$500", 20, Color3.fromRGB(140, 255, 150))
local incomeLabel = makeLabel(topBar, "Income", UDim2.new(0.3, 0, 1, 0), UDim2.new(0.34, 0, 0, 0), "$0/s", 17, Color3.fromRGB(255, 230, 140))
local rebirthLabel = makeLabel(topBar, "Rebirths", UDim2.new(0.22, 0, 1, 0), UDim2.new(0.64, 0, 0, 0), "Rebirths: 0", 16, Color3.fromRGB(200, 180, 255))
local indexButton = makeButton(topBar, "IndexButton", UDim2.new(0.13, 0, 0.78, 0), UDim2.new(0.86, 0, 0.11, 0), "INDEX 0/44", Color3.fromRGB(170, 120, 40))

-- Task line.
local taskLabel = makeLabel(gui, "Task", UDim2.new(0.6, 0, 0, 30), UDim2.new(0.2, 0, 0, 60), "", 17, Color3.fromRGB(255, 255, 255))
taskLabel.TextXAlignment = Enum.TextXAlignment.Center
taskLabel.BackgroundTransparency = 0.35
taskLabel.BackgroundColor3 = Color3.fromRGB(30, 28, 42)

-- Banner and toast.
local bannerLabel = makeLabel(gui, "Banner", UDim2.new(0.7, 0, 0, 54), UDim2.new(0.15, 0, 0, 100), "", 32, Color3.fromRGB(255, 120, 70))
bannerLabel.TextXAlignment = Enum.TextXAlignment.Center
bannerLabel.Visible = false
local toastLabel = makeLabel(gui, "Toast", UDim2.new(0.5, 0, 0, 34), UDim2.new(0.25, 0, 0, 160), "", 17, Color3.fromRGB(255, 255, 255))
toastLabel.TextXAlignment = Enum.TextXAlignment.Center
toastLabel.BackgroundTransparency = 0.3
toastLabel.BackgroundColor3 = Color3.fromRGB(30, 28, 42)
toastLabel.Visible = false

-- Belt panel (left).
local beltPanel = makeFrame(gui, "BeltPanel", UDim2.new(0, 228, 0, 330), UDim2.new(0, 10, 0.28, 0), Color3.fromRGB(35, 32, 48))
makeLabel(beltPanel, "Title", UDim2.new(1, -12, 0, 26), UDim2.new(0, 6, 0, 4), "ON THE BELT", 17, Color3.fromRGB(255, 210, 110))
local beltList = makeFrame(beltPanel, "List", UDim2.new(1, -12, 1, -42), UDim2.new(0, 6, 0, 36), Color3.fromRGB(25, 23, 36))
beltList.BackgroundTransparency = 1

-- Base panel (right).
local basePanel = makeFrame(gui, "BasePanel", UDim2.new(0, 228, 0, 400), UDim2.new(1, -238, 0.28, 0), Color3.fromRGB(35, 32, 48))
makeLabel(basePanel, "Title", UDim2.new(1, -12, 0, 26), UDim2.new(0, 6, 0, 4), "YOUR BASE", 17, Color3.fromRGB(140, 255, 150))
local baseList = makeFrame(basePanel, "List", UDim2.new(1, -12, 0, 210), UDim2.new(0, 6, 0, 36), Color3.fromRGB(25, 23, 36))
baseList.BackgroundTransparency = 1
local buySlotButton = makeButton(basePanel, "BuySlot", UDim2.new(1, -12, 0, 34), UDim2.new(0, 6, 0, 252), "Buy slot", Color3.fromRGB(70, 160, 90))
local lockButton = makeButton(basePanel, "Lock", UDim2.new(1, -12, 0, 34), UDim2.new(0, 6, 0, 292), "Lock base", Color3.fromRGB(90, 110, 200))
local rebirthButton = makeButton(basePanel, "Rebirth", UDim2.new(1, -12, 0, 44), UDim2.new(0, 6, 0, 332), "Rebirth", Color3.fromRGB(150, 80, 200))

buySlotButton.MouseButton1Click:Connect(function()
	remotes.RequestBuySlot:FireServer()
end)
lockButton.MouseButton1Click:Connect(function()
	remotes.RequestLock:FireServer()
end)
rebirthButton.MouseButton1Click:Connect(function()
	remotes.RequestRebirth:FireServer()
end)

-- Prize Book panel (centre, hidden until toggled).
local indexPanel = makeFrame(gui, "IndexPanel", UDim2.new(0, 560, 0, 430), UDim2.new(0.5, -280, 0.5, -215), Color3.fromRGB(42, 36, 28))
indexPanel.Visible = false
local indexTitle = makeLabel(indexPanel, "Title", UDim2.new(1, -90, 0, 34), UDim2.new(0, 14, 0, 8), "PRIZE BOOK", 24, Color3.fromRGB(255, 220, 130))
indexTitle.TextXAlignment = Enum.TextXAlignment.Left
local indexHeader = makeLabel(indexPanel, "Header", UDim2.new(1, -28, 0, 26), UDim2.new(0, 14, 0, 44), "", 15, Color3.fromRGB(255, 240, 200))
local indexClose = makeButton(indexPanel, "Close", UDim2.new(0, 64, 0, 32), UDim2.new(1, -78, 0, 8), "Close", Color3.fromRGB(180, 70, 60))
local indexScroll = Instance.new("ScrollingFrame")
indexScroll.Name = "Grid"
indexScroll.Size = UDim2.new(1, -28, 1, -86)
indexScroll.Position = UDim2.new(0, 14, 0, 76)
indexScroll.BackgroundTransparency = 0.4
indexScroll.BackgroundColor3 = Color3.fromRGB(25, 22, 18)
indexScroll.BorderSizePixel = 0
indexScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
indexScroll.Parent = indexPanel
local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 124, 0, 74)
gridLayout.CellPadding = UDim2.new(0, 6, 0, 6)
gridLayout.Parent = indexScroll

indexButton.MouseButton1Click:Connect(function()
	indexPanel.Visible = not indexPanel.Visible
end)
indexClose.MouseButton1Click:Connect(function()
	indexPanel.Visible = false
end)

-- Roster ordered by rarity order, then cost ascending.
local roster = {}
for _, entry in ipairs(BrainrotCatalog.Characters) do
	table.insert(roster, entry)
end
table.sort(roster, function(a, b)
	local orderA = BrainrotCatalog.GetRarityInfo(a.Rarity).Order
	local orderB = BrainrotCatalog.GetRarityInfo(b.Rarity).Order
	if orderA ~= orderB then
		return orderA < orderB
	end
	return a.Cost < b.Cost
end)

local currentState = nil
local lastBeltKey = ""
local lastIndexCountRendered = -1

local function computeTaskText(state)
	if state.Carrying then
		return "Carry it home to your base!"
	end
	if state.ThiefActive then
		return "BOP THE RACCOON THIEF!"
	end
	if not state.Owned or #state.Owned == 0 then
		return "Buy a brainrot from the belt!"
	end
	if state.NextMilestone and state.NextMilestone.Count - state.IndexCount <= 3 then
		local more = state.NextMilestone.Count - state.IndexCount
		return "Prize Book: " .. state.IndexCount .. "/" .. state.IndexTotal .. " — " .. more .. " more for " .. formatMoney(state.NextMilestone.Reward) .. "!"
	end
	if state.NextSlotCost and state.Cash >= state.NextSlotCost then
		return "Buy another base slot!"
	end
	return "Earn $1,000,000 total to rebirth (+25% income)"
end

local function renderBelt(state)
	local keyParts = {}
	for _, entry in ipairs(state.Belt or {}) do
		table.insert(keyParts, tostring(entry.Id))
	end
	local key = table.concat(keyParts, ",")
	if key == lastBeltKey then
		return
	end
	lastBeltKey = key
	for _, child in ipairs(beltList:GetChildren()) do
		child:Destroy()
	end
	local y = 0
	for _, entry in ipairs(state.Belt or {}) do
		local card = makeButton(beltList, "Card" .. entry.Id, UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, y), "", Color3.fromRGB(55, 52, 75))
		local nameLabel = makeLabel(card, "Name", UDim2.new(1, -8, 0, 20), UDim2.new(0, 4, 0, 1), entry.Name, 14, BrainrotCatalog.GetRarityColor(entry.Rarity))
		nameLabel.BackgroundTransparency = 1
		local detail = makeLabel(card, "Detail", UDim2.new(1, -8, 0, 18), UDim2.new(0, 4, 0, 21), entry.Rarity .. "  " .. formatMoney(entry.Rate) .. "/s   " .. formatMoney(entry.Cost), 12, Color3.fromRGB(230, 230, 230))
		detail.BackgroundTransparency = 1
		local beltId = entry.Id
		card.MouseButton1Click:Connect(function()
			remotes.RequestBuy:FireServer(beltId)
		end)
		y += 44
	end
end

local function renderBase(state)
	for _, child in ipairs(baseList:GetChildren()) do
		child:Destroy()
	end
	local y = 0
	for _, entry in ipairs(state.Owned or {}) do
		local row = makeFrame(baseList, "Row" .. entry.Slot, UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, y), Color3.fromRGB(55, 52, 75))
		row.BackgroundTransparency = 0.1
		local nameLabel = makeLabel(row, "Name", UDim2.new(0.68, 0, 0, 20), UDim2.new(0, 4, 0, 1), entry.Name, 13, BrainrotCatalog.GetRarityColor(entry.Rarity))
		nameLabel.BackgroundTransparency = 1
		local detail = makeLabel(row, "Detail", UDim2.new(0.68, 0, 0, 18), UDim2.new(0, 4, 0, 21), formatMoney(entry.Rate) .. "/s", 12, Color3.fromRGB(230, 230, 230))
		detail.BackgroundTransparency = 1
		local slot = entry.Slot
		local sell = makeButton(row, "Sell", UDim2.new(0.3, 0, 0, 30), UDim2.new(0.69, 0, 0, 5), "Sell", Color3.fromRGB(190, 90, 70))
		sell.MouseButton1Click:Connect(function()
			remotes.RequestSell:FireServer(slot)
		end)
		y += 44
	end
	if y == 0 then
		makeLabel(baseList, "Empty", UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 0), "No brainrots yet.", 14, Color3.fromRGB(180, 180, 190))
	end
end

local function renderIndexGrid(state)
	if state.IndexCount == lastIndexCountRendered then
		return
	end
	lastIndexCountRendered = state.IndexCount
	for _, child in ipairs(indexScroll:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextButton") then
			child:Destroy()
		end
	end
	local collected = {}
	for _, characterId in ipairs(state.Index or {}) do
		collected[characterId] = true
	end
	for _, entry in ipairs(roster) do
		local cell = makeFrame(indexScroll, "Cell_" .. entry.Id, UDim2.new(0, 124, 0, 74), UDim2.new(0, 0, 0, 0), Color3.fromRGB(60, 55, 70))
		if collected[entry.Id] then
			cell.BackgroundColor3 = BrainrotCatalog.GetRarityColor(entry.Rarity)
			local nameLabel = makeLabel(cell, "Name", UDim2.new(1, -8, 0, 38), UDim2.new(0, 4, 0, 4), entry.Name, 12, Color3.fromRGB(25, 22, 30))
			nameLabel.TextWrapped = true
			nameLabel.BackgroundTransparency = 1
			local income = makeLabel(cell, "Income", UDim2.new(1, -8, 0, 18), UDim2.new(0, 4, 0, 50), formatMoney(entry.IncomePerSecond) .. "/s", 12, Color3.fromRGB(25, 22, 30))
			income.BackgroundTransparency = 1
		else
			cell.BackgroundColor3 = Color3.fromRGB(85, 85, 92)
			local nameLabel = makeLabel(cell, "Name", UDim2.new(1, -8, 0, 38), UDim2.new(0, 4, 0, 4), "???", 14, Color3.fromRGB(220, 220, 225))
			nameLabel.BackgroundTransparency = 1
			local rarity = makeLabel(cell, "Rarity", UDim2.new(1, -8, 0, 18), UDim2.new(0, 4, 0, 50), entry.Rarity, 12, Color3.fromRGB(200, 200, 205))
			rarity.BackgroundTransparency = 1
		end
	end
	indexScroll.CanvasSize = UDim2.new(0, 0, 0, math.ceil(#roster / 4) * 80 + 10)
end

local function renderIndexHeader(state)
	local text = "You have collected " .. state.IndexCount .. " of " .. state.IndexTotal .. " brainrots"
	if state.NextMilestone then
		text ..= "  •  Next Prize Book prize at " .. state.NextMilestone.Count .. " collected: " .. formatMoney(state.NextMilestone.Reward)
	else
		text ..= "  •  Every Prize Book prize has been claimed — collection complete!"
	end
	indexHeader.Text = text
	indexButton.Text = "INDEX " .. state.IndexCount .. "/" .. state.IndexTotal
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
	renderBelt(state)
	renderBase(state)
	if state.NextSlotCost then
		buySlotButton.Visible = true
		buySlotButton.Text = "Buy slot (" .. formatMoney(state.NextSlotCost) .. ")"
	else
		buySlotButton.Visible = false
	end
	if state.Lock and state.Lock.Locked then
		lockButton.Text = "LOCKED (" .. tostring(state.Lock.SecondsLeft) .. "s)"
	elseif state.Lock and state.Lock.CooldownLeft and state.Lock.CooldownLeft > 0 then
		lockButton.Text = "Lock (cooldown " .. tostring(state.Lock.CooldownLeft) .. "s)"
	else
		lockButton.Text = "Lock base (45s)"
	end
	local progress = math.min(state.TotalEarned or 0, state.RebirthThreshold or 1000000)
	rebirthButton.Text = "Rebirth: " .. formatMoney(progress) .. " / " .. formatMoney(state.RebirthThreshold or 1000000) .. "\nMultiplier x" .. string.format("%.2f", state.RebirthMultiplier or 1)
	renderIndexHeader(state)
	renderIndexGrid(state)
end

remotes.StateUpdate.OnClientEvent:Connect(onStateUpdate)

local bannerToken = 0
remotes.ShowBanner.OnClientEvent:Connect(function(message)
	bannerToken += 1
	local token = bannerToken
	bannerLabel.Text = tostring(message)
	bannerLabel.Visible = true
	task.delay(3, function()
		if bannerToken == token then
			bannerLabel.Visible = false
		end
	end)
end)

local toastToken = 0
remotes.ShowMessage.OnClientEvent:Connect(function(message)
	toastToken += 1
	local token = toastToken
	toastLabel.Text = tostring(message)
	toastLabel.Visible = true
	task.delay(2.5, function()
		if toastToken == token then
			toastLabel.Visible = false
		end
	end)
end)
