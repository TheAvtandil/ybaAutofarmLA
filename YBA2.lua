-- PigletHUB Ultimate Autofarm for Your Bizarre Adventure (YBA)
-- Full script by ChatGPT + DearUser7 💥🐷

--// Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")

--// Vars
local Player = Players.LocalPlayer
local Character = function() return Player.Character or Player.CharacterAdded:Wait() end
local HRP = function() return Character():WaitForChild("HumanoidRootPart") end
local PlayerStats = Player:WaitForChild("PlayerStats")

--// Config
local PLACE_ID = 2809202155
local ReturnSpot = CFrame.new(978, -42, -49)
local TeleportOffset = Vector3.new(0, -6, 0)
local TeleportStepDistance = 22
local TeleportStepWait = 0.05
local StayUnderItemTime = 0.6
local PickupHoldTime = 0.25
local ServerhopDelay = 105
local AutoSell = true
local BuyLucky = true
local trackedItems = {}

--// Anti-Detection Flags
local IsFarming = false
local IsFirstPickup = true
local LastItemName = ""

--// Item limits and filters
local ItemCaps = {
    ["Gold Coin"] = 45, ["Rokakaka"] = 25, ["Pure Rokakaka"] = 10,
    ["Mysterious Arrow"] = 25, ["Diamond"] = 30, ["Ancient Scroll"] = 10,
    ["Caesar's Headband"] = 10, ["Stone Mask"] = 10,
    ["Rib Cage of The Saint's Corpse"] = 20, ["Quinton's Glove"] = 10,
    ["Zeppeli's Hat"] = 10, ["Lucky Arrow"] = 10,
    ["Clackers"] = 10, ["Steel Ball"] = 10, ["Dio's Diary"] = 10
}
local SellItems = {
    ["Gold Coin"] = true, ["Rokakaka"] = true, ["Pure Rokakaka"] = true,
    ["Mysterious Arrow"] = true, ["Diamond"] = true, ["Ancient Scroll"] = true,
    ["Caesar's Headband"] = true, ["Stone Mask"] = true,
    ["Rib Cage of The Saint's Corpse"] = true, ["Quinton's Glove"] = true,
    ["Zeppeli's Hat"] = true, ["Lucky Arrow"] = false, -- <== Don't sell!
    ["Clackers"] = true, ["Steel Ball"] = true, ["Dio's Diary"] = true
}

--// Double item cap if gamepass
local has2x = false
pcall(function()
    has2x = MarketplaceService:UserOwnsGamePassAsync(Player.UserId, 14597778)
end)
if has2x then
    for k, v in pairs(ItemCaps) do ItemCaps[k] = v * 2 end
end

--// GUI
local function createGUI()
    local ui = Instance.new("ScreenGui")
    ui.Name = "PigletHUB"
    ui.ResetOnSpawn = false
    ui.Parent = Player:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame", ui)
    frame.Name = "Main"
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.Size = UDim2.new(0, 250, 0, 150)
    frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
    frame.BackgroundTransparency = 0.1

    local title = Instance.new("TextLabel", frame)
    title.Text = "PigletHUB"
    title.Size = UDim2.new(1, 0, 0, 20)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.new(1,1,1)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 20

    local log = Instance.new("TextLabel", frame)
    log.Name = "ItemLog"
    log.Position = UDim2.new(0, 0, 0, 22)
    log.Size = UDim2.new(1, 0, 0, 68)
    log.BackgroundTransparency = 1
    log.TextColor3 = Color3.fromRGB(255,255,255)
    log.TextSize = 14
    log.TextWrapped = true
    log.TextYAlignment = Enum.TextYAlignment.Top
    log.Font = Enum.Font.SourceSans
    log.Text = "Item Log:\n"

    local money = Instance.new("TextLabel", frame)
    money.Name = "Money"
    money.Position = UDim2.new(0, 0, 0, 93)
    money.Size = UDim2.new(1, 0, 0, 20)
    money.BackgroundTransparency = 1
    money.TextColor3 = Color3.fromRGB(255, 255, 0)
    money.TextSize = 14
    money.Font = Enum.Font.SourceSans
    money.Text = "Money: ..."

    local status = Instance.new("TextLabel", frame)
    status.Name = "Status"
    status.Position = UDim2.new(0, 0, 0, 113)
    status.Size = UDim2.new(1, 0, 0, 20)
    status.BackgroundTransparency = 1
    status.TextColor3 = Color3.fromRGB(0, 255, 0)
    status.TextSize = 14
    status.Font = Enum.Font.SourceSans
    status.Text = "Status: Idle"

    local debug = Instance.new("TextLabel", frame)
    debug.Name = "Debug"
    debug.Position = UDim2.new(0, 0, 0, 133)
    debug.Size = UDim2.new(1, 0, 0, 15)
    debug.BackgroundTransparency = 1
    debug.TextColor3 = Color3.fromRGB(200, 200, 200)
    debug.TextSize = 13
    debug.Font = Enum.Font.SourceSans
    debug.Text = "Debug: ..."
end
createGUI()
--// GUI Updater
local function updateGUI(logText, statusText, debugText)
	local gui = Player:FindFirstChild("PlayerGui"):FindFirstChild("PigletHUB")
	if gui and gui:FindFirstChild("Main") then
		if logText and gui.Main.ItemLog then
			gui.Main.ItemLog.Text = "Item Log:\n" .. logText
		end
		if statusText and gui.Main.Status then
			gui.Main.Status.Text = "Status: " .. statusText
		end
		if debugText and gui.Main.Debug then
			gui.Main.Debug.Text = "Debug: " .. debugText
		end
		if gui.Main.Money then
			gui.Main.Money.Text = "Money: $" .. tostring(math.floor(PlayerStats.Money.Value))
		end
	end
end

--// E key holder
local function holdE(duration)
	VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
	task.wait(duration)
	VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

--// Step teleport to position
local function stepTeleport(targetCFrame)
	local origin = HRP().CFrame.Position
	local goal = targetCFrame.Position
	local distance = (goal - origin).Magnitude
	local direction = (goal - origin).Unit
	local steps = math.floor(distance / TeleportStepDistance)
	for i = 1, steps do
		local stepPosition = origin + (direction * TeleportStepDistance * i)
		HRP().CFrame = CFrame.new(stepPosition)
		task.wait(TeleportStepWait)
	end
	HRP().CFrame = targetCFrame
end

--// Item Tracker
local ItemFolder = Workspace:WaitForChild("Item_Spawns"):WaitForChild("Items")
local function trackItem(itemModel)
	if not itemModel:IsA("Model") then return end
	local prompt = itemModel:FindFirstChildWhichIsA("ProximityPrompt", true)
	local part = itemModel:FindFirstChildWhichIsA("BasePart")
	if prompt and part and prompt.ObjectText then
		table.insert(trackedItems, {
			model = itemModel,
			prompt = prompt,
			part = part,
			name = prompt.ObjectText,
			position = part.Position
		})
	end
end

-- Track existing + new items
for _, item in ipairs(ItemFolder:GetChildren()) do
	trackItem(item)
end
ItemFolder.ChildAdded:Connect(function(child)
	task.wait(0.2)
	trackItem(child)
end)

--// Pickup Function
local function pickupItem(item)
	IsFarming = true
	LastItemName = item.name
	updateGUI("Last Item: " .. item.name, "Teleporting...", "Going to item")

	-- Teleport under the item
	local target = CFrame.new(item.position + TeleportOffset)
	stepTeleport(target)

	task.wait(0.1)
	updateGUI("Last Item: " .. item.name, "Holding E...", "Holding for pickup")

	-- Hold E key
	holdE(PickupHoldTime)

	-- Also fire prompt (backup)
	pcall(function()
		fireproximityprompt(item.prompt)
	end)

	-- Wait under item
	task.wait(StayUnderItemTime)

	-- Return
	updateGUI("Last Item: " .. item.name, "Returning...", "To safe spot")
	stepTeleport(ReturnSpot)
	task.wait(0.2)

	IsFarming = false
end
--// Sell Logic
local function equipAndSell(tool)
	if not tool then return false end
	local char = Character()
	local hum = char:FindFirstChild("Humanoid")
	if not hum then return false end

	hum:EquipTool(tool)
	local timeout = tick() + 1
	repeat task.wait(0.1) until char:FindFirstChild(tool.Name) or tick() > timeout

	if char:FindFirstChild(tool.Name) then
		char.RemoteEvent:FireServer("EndDialogue", {
			NPC = "Merchant",
			Dialogue = "Dialogue5",
			Option = "Option2"
		})
		task.wait(0.3)
		return true
	end
	return false
end

local function quickSell()
	if not AutoSell then return end
	local sold = 0
	for itemName, shouldSell in pairs(SellItems) do
		if shouldSell then
			for _, tool in ipairs(Player.Backpack:GetChildren()) do
				if tool.Name == itemName then
					if equipAndSell(tool) then
						sold += 1
						updateGUI("Sold: " .. tool.Name, "Selling...", "Count: " .. sold)
					end
				end
			end
		end
	end
end

--// Lucky Arrow Buyer
local function buyLucky()
	if not BuyLucky then return end
	local money = PlayerStats.Money.Value
	if money >= 50000 then
		Character().RemoteEvent:FireServer("PurchaseShopItem", {
			ItemName = "1x Lucky Arrow"
		})
		updateGUI(nil, "Buying Lucky", "Money: " .. money)
		task.wait(0.3)
	end
end

--// ServerHop + Rejoin
local function serverHop()
	local success, result = pcall(function()
		local servers = {}
		local response = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. PLACE_ID .. "/servers/Public?sortOrder=Asc&limit=100"))
		for _, s in pairs(response.data) do
			if s.playing < s.maxPlayers and s.id ~= game.JobId then
				table.insert(servers, s.id)
			end
		end
		if #servers > 0 then
			local chosen = servers[math.random(1, #servers)]
			TeleportService:TeleportToPlaceInstance(PLACE_ID, chosen, Player)
		end
	end)
	if not success then
		updateGUI(nil, "Hop Failed", "Retrying in 5s")
		task.wait(5)
		serverHop()
	end
end

task.spawn(function()
	while true do
		task.wait(ServerhopDelay)
		if not IsFarming then
			updateGUI(nil, "Serverhop...", "Timer done")
			serverHop()
		end
	end
end)

--// Panic Key (Press P to return to safe spot instantly)
game:GetService("UserInputService").InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.P then
		updateGUI(nil, "Panic Key!", "Returning to Safe Spot")
		stepTeleport(ReturnSpot)
	end
end)

--// Main Farm Loop
while true do
	task.wait(0.5)

	local validItem
	for i = #trackedItems, 1, -1 do
		local item = trackedItems[i]
		if item.model and item.prompt and item.prompt.Parent and item.part and not item.model:IsDescendantOf(nil) then
			local inBackpack = 0
			for _, tool in ipairs(Player.Backpack:GetChildren()) do
				if tool.Name == item.name then
					inBackpack += 1
				end
			end
			if (ItemCaps[item.name] or 999) > inBackpack then
				validItem = item
				table.remove(trackedItems, i)
				break
			end
		else
			table.remove(trackedItems, i)
		end
	end

	if validItem then
		pickupItem(validItem)
	else
		quickSell()
		buyLucky()
		updateGUI(nil, "Idle", "Waiting for item")
	end
end
