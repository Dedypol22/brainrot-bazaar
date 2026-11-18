-- ClientMain.client.luau
-- The Brainrot Bazaar HUD, built entirely in code: a top bar with cash,
-- income and rebirths; the belt panel on the left for buying; the base panel
-- on the right for selling, slots, locking and rebirthing; plus the banner
-- and toast lines for wave warnings and feedback. The client renders only
-- what the server's state snapshots say — it never changes game state
-- itself, it just fires the request remotes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local remotes = {}
for _, remoteName in ipairs({
	"RequestBuy", "RequestSell", "RequestBuySlot", "RequestLock", "RequestRebirth",
	"RequestSteal", "StateUpdate", "ShowBanner", "ShowMessage",
}) do
	remotes[remoteName] = remotesFolder:WaitForChild(remoteName)
end

-- Small builders ---------------------------------------------------------------------

local function formatMoney(amount)
	local value = math.floor(amount or 0)
	local digits = tostring(value)
	local grouped = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if grouped:sub(1, 1) == "," then
		grouped = grouped:sub(2)
	end
	return "$" .. grouped
end

local function makeFrame(parent, name, size, position)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.Position = position
	frame.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
	frame.BackgroundTransparency = 0.12
	frame.BorderSizePixel = 0
	frame.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame
	return frame
end

local function makeLabel(parent, name, size, position, text, textSize, textColor)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextSize = textSize
	label.TextColor3 = textColor
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = parent
	return label
end

local function makeButton(parent, name, size, position, text)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = Color3.fromRGB(55, 150, 85)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.TextSize = 15
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.AutoButtonColor = true
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button
	return button
end

local function makeListContainer(parent, name, size, position)
	local container = Instance.new("Frame")
	container.Name = name
	container.Size = size
	container.Position = position
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.Parent = parent
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 6)
	layout.Parent = container
	return container
end

local function clearList(container)
	for _, child in ipairs(container:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
end

-- HUD construction ---------------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotBazaarGui"
gui.ResetOnSpawn = false
gui.Parent = playerGui

-- The top bar starts at x = 0.12 of the screen so it clears Roblox's own
-- menu buttons in the top-left corner.
local topBar = makeFrame(gui, "TopBar", UDim2.new(0, 540, 0, 46), UDim2.new(0.12, 0, 0, 8))
local cashLabel = makeLabel(topBar, "Cash", UDim2.new(0, 180, 1, 0), UDim2.new(0, 12, 0, 0),
	"$500", 20, Color3.fromRGB(140, 255, 150))
local incomeLabel = makeLabel(topBar, "Income", UDim2.new(0, 160, 1, 0), UDim2.new(0, 196, 0, 0),
	"$0/s", 18, Color3.fromRGB(255, 230, 120))
local rebirthLabel = makeLabel(topBar, "Rebirths", UDim2.new(0, 168, 1, 0), UDim2.new(0, 360, 0, 0),
	"Rebirths: 0", 16, Color3.fromRGB(200, 170, 255))

local taskLabel = makeLabel(gui, "Task", UDim2.new(0, 540, 0, 26), UDim2.new(0.12, 0, 0, 58),
	"Welcome to the bazaar!", 15, Color3.fromRGB(255, 240, 170))
taskLabel.BackgroundTransparency = 0.35
taskLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
taskLabel.TextXAlignment = Enum.TextXAlignment.Center

local beltPanel = makeFrame(gui, "BeltPanel", UDim2.new(0, 252, 0, 348), UDim2.new(0, 10, 0, 66))
makeLabel(beltPanel, "Title", UDim2.new(1, -12, 0, 26), UDim2.new(0, 8, 0, 4),
	"ON THE BELT", 17, Color3.fromRGB(255, 255, 255))
local beltList = makeListContainer(beltPanel, "BeltList",
	UDim2.new(0, 240, 1, -40), UDim2.new(0, 6, 0, 34))

local basePanel = makeFrame(gui, "BasePanel", UDim2.new(0, 252, 0, 348), UDim2.new(1, -262, 0, 66))
makeLabel(basePanel, "Title", UDim2.new(1, -12, 0, 26), UDim2.new(0, 8, 0, 4),
	"YOUR BASE", 17, Color3.fromRGB(255, 255, 255))
local baseList = makeListContainer(basePanel, "BaseList",
	UDim2.new(0, 240, 0, 176), UDim2.new(0, 6, 0, 34))
local buySlotButton = makeButton(basePanel, "BuySlot", UDim2.new(0, 240, 0, 34), UDim2.new(0, 6, 0, 218),
	"Buy slot")
local lockButton = makeButton(basePanel, "Lock", UDim2.new(0, 240, 0, 34), UDim2.new(0, 6, 0, 258),
	"Lock base (45s)")
lockButton.BackgroundColor3 = Color3.fromRGB(70, 110, 190)
local rebirthButton = makeButton(basePanel, "Rebirth", UDim2.new(0, 240, 0, 34), UDim2.new(0, 6, 0, 298),
	"Rebirth")
rebirthButton.BackgroundColor3 = Color3.fromRGB(150, 80, 200)

local bannerLabel = makeLabel(gui, "Banner", UDim2.new(0, 700, 0, 64), UDim2.new(0.5, -350, 0.14, 0),
	"", 44, Color3.fromRGB(255, 90, 90))
bannerLabel.TextXAlignment = Enum.TextXAlignment.Center
bannerLabel.Visible = false

local toastLabel = makeLabel(gui, "Toast", UDim2.new(0, 500, 0, 34), UDim2.new(0.5, -250, 0.14, 70),
	"", 18, Color3.fromRGB(255, 255, 255))
toastLabel.TextXAlignment = Enum.TextXAlignment.Center
toastLabel.BackgroundTransparency = 0.35
toastLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
toastLabel.Visible = false

-- Rendering ------------------------------------------------------------------------------

local currentState = nil
local lastBeltSignature = nil

local function renderBelt(state)
	clearList(beltList)
	-- Show the most valuable riders first so the best buys are always on top.
	local sorted = {}
	for _, entry in ipairs(state.Belt) do
		table.insert(sorted, entry)
	end
	table.sort(sorted, function(a, b)
		return a.Rate > b.Rate
	end)
	for index, entry in ipairs(sorted) do
		local card = makeButton(beltList, "BeltCard" .. entry.Id,
			UDim2.new(1, 0, 0, 54), UDim2.new(0, 0, 0, 0), "")
		card.BackgroundColor3 = Color3.fromRGB(42, 42, 58)
		card.LayoutOrder = index
		makeLabel(card, "Name", UDim2.new(1, -12, 0, 20), UDim2.new(0, 7, 0, 3),
			entry.Name, 15, Color3.fromRGB(255, 255, 255))
		makeLabel(card, "Rarity", UDim2.new(0, 90, 0, 16), UDim2.new(0, 7, 0, 24),
			entry.Rarity, 12, BrainrotCatalog.GetRarityColor(entry.Rarity))
		makeLabel(card, "Info", UDim2.new(1, -104, 0, 16), UDim2.new(0, 97, 0, 24),
			formatMoney(entry.Rate) .. "/s   " .. formatMoney(entry.Cost), 12,
			Color3.fromRGB(200, 255, 205))
		card.MouseButton1Click:Connect(function()
			remotes.RequestBuy:FireServer(entry.Id)
		end)
	end
end

local function renderBase(state)
	clearList(baseList)
	if #state.Owned == 0 then
		local empty = makeLabel(baseList, "Empty", UDim2.new(1, 0, 0, 22), UDim2.new(0, 0, 0, 0),
			"No brainrots yet — buy one!", 13, Color3.fromRGB(190, 190, 205))
		empty.LayoutOrder = 1
		return
	end
	for index, entry in ipairs(state.Owned) do
		local row = makeFrame(baseList, "OwnedRow" .. entry.Slot,
			UDim2.new(1, 0, 0, 42), UDim2.new(0, 0, 0, 0))
		row.BackgroundColor3 = Color3.fromRGB(42, 42, 58)
		row.LayoutOrder = index
		makeLabel(row, "Name", UDim2.new(1, -76, 0, 20), UDim2.new(0, 7, 0, 2),
			entry.Name, 14, Color3.fromRGB(255, 255, 255))
		makeLabel(row, "Info", UDim2.new(1, -76, 0, 16), UDim2.new(0, 7, 0, 23),
			entry.Rarity .. "  " .. formatMoney(entry.Rate) .. "/s", 12,
			BrainrotCatalog.GetRarityColor(entry.Rarity))
		local sellButton = makeButton(row, "Sell", UDim2.new(0, 58, 0, 28), UDim2.new(1, -65, 0, 7),
			"Sell")
		sellButton.BackgroundColor3 = Color3.fromRGB(190, 90, 60)
		sellButton.TextSize = 13
		sellButton.MouseButton1Click:Connect(function()
			remotes.RequestSell:FireServer(entry.Slot)
		end)
	end
end

local function computeTaskText(state)
	if state.Carrying then
		return "Carry it home to your base!"
	end
	if #state.Owned == 0 then
		return "Buy a brainrot from the belt!"
	end
	if state.TotalEarned >= state.RebirthThreshold then
		return "Rebirth now for +25% income forever!"
	end
	if state.NextSlotCost and #state.Owned >= state.Slots and state.Cash >= state.NextSlotCost then
		return "Your base is full — buy another slot!"
	end
	return "Earn " .. formatMoney(state.RebirthThreshold) .. " total to rebirth (+25% income)"
end

local function onStateUpdate(state)
	currentState = state

	cashLabel.Text = formatMoney(state.Cash)
	incomeLabel.Text = formatMoney(state.IncomePerSecond) .. "/s"
	rebirthLabel.Text = "Rebirths: " .. tostring(state.Rebirths)

	-- The belt list is only rebuilt when the set of riders actually changes;
	-- rebuilding it every second would eat the player's clicks.
	local signatureParts = {}
	for _, entry in ipairs(state.Belt) do
		table.insert(signatureParts, tostring(entry.Id))
	end
	local signature = table.concat(signatureParts, ",")
	if signature ~= lastBeltSignature then
		lastBeltSignature = signature
		renderBelt(state)
	end

	renderBase(state)

	if state.NextSlotCost then
		buySlotButton.Visible = true
		buySlotButton.Text = "Buy slot (" .. formatMoney(state.NextSlotCost) .. ")"
	else
		buySlotButton.Visible = false
	end

	if state.Lock.Locked then
		lockButton.Text = "Locked: " .. tostring(state.Lock.SecondsLeft) .. "s left"
	elseif state.Lock.CooldownLeft > 0 then
		lockButton.Text = "Lock (recharging " .. tostring(state.Lock.CooldownLeft) .. "s)"
	else
		lockButton.Text = "Lock base (45s)"
	end

	rebirthButton.Text = "Rebirth (" .. formatMoney(state.TotalEarned)
		.. " / " .. formatMoney(state.RebirthThreshold) .. ")"

	taskLabel.Text = computeTaskText(state)
end

-- Remote wiring ----------------------------------------------------------------------------

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

local bannerToken = 0
remotes.ShowBanner.OnClientEvent:Connect(function(text)
	bannerToken += 1
	local token = bannerToken
	bannerLabel.Text = text
	bannerLabel.Visible = true
	task.delay(3, function()
		if bannerToken == token then
			bannerLabel.Visible = false
		end
	end)
end)

local toastToken = 0
remotes.ShowMessage.OnClientEvent:Connect(function(text)
	toastToken += 1
	local token = toastToken
	toastLabel.Text = text
	toastLabel.Visible = true
	task.delay(2.5, function()
		if toastToken == token then
			toastLabel.Visible = false
		end
	end)
end)
