--// File save helpers
local SettingsFile = "PigletHub_Settings.json"
local FarmEnabled = true
if isfile and readfile and writefile then
	if isfile(SettingsFile) then
		local success, data = pcall(function() return game:GetService("HttpService"):JSONDecode(readfile(SettingsFile)) end)
		if success and type(data) == "table" then
			FarmEnabled = data.Enabled or true
		end
	end
end

local function saveFarmToggle(state)
	if writefile then
		local json = game:GetService("HttpService"):JSONEncode({ Enabled = state })
		writefile(SettingsFile, json)
	end
end

--// GUI Function with Toggle + Drag
local function createGUI()
	local ui = Instance.new("ScreenGui")
	ui.Name = "PigletHUB"
	ui.ResetOnSpawn = false
	ui.Parent = Player:WaitForChild("PlayerGui")

	local frame = Instance.new("Frame", ui)
	frame.Name = "Main"
	frame.Position = UDim2.new(0, 10, 0, 10)
	frame.Size = UDim2.new(0, 260, 0, 170)
	frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
	frame.BackgroundTransparency = 0.1
	frame.Active = true
	frame.Draggable = true -- 🖱️ Make GUI movable

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

	-- ✅ Toggle Button
	local toggle = Instance.new("TextButton", frame)
	toggle.Name = "ToggleFarm"
	toggle.Text = "Farming: " .. (FarmEnabled and "ON" or "OFF")
	toggle.Position = UDim2.new(0, 0, 1, -20)
	toggle.Size = UDim2.new(1, 0, 0, 18)
	toggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	toggle.TextColor3 = Color3.new(1,1,1)
	toggle.Font = Enum.Font.SourceSans
	toggle.TextSize = 14

	toggle.MouseButton1Click:Connect(function()
		FarmEnabled = not FarmEnabled
		toggle.Text = "Farming: " .. (FarmEnabled and "ON" or "OFF")
		saveFarmToggle(FarmEnabled)
	end)
end
createGUI()
--// Item Tracker (with MeshPart+Part+BasePart detection)
local ItemFolder = Workspace:WaitForChild("Item_Spawns"):WaitForChild("Items")
local function trackItem(itemModel)
	if not itemModel:IsA("Model") then return end
	local prompt = itemModel:FindFirstChildWhichIsA("ProximityPrompt", true)
	local part = nil

	for _, obj in pairs(itemModel:GetDescendants()) do
		if obj:IsA("Part") or obj:IsA("MeshPart") or obj:IsA("BasePart") then
			part = obj
			break
		end
	end

	if prompt and part and prompt.ObjectText and prompt.ObjectText ~= "" then
		table.insert(trackedItems, {
			model = itemModel,
			prompt = prompt,
			part = part,
			name = prompt.ObjectText,
			position = part.Position
		})
		updateGUI("Tracking: " .. prompt.ObjectText, "Item Tracked", "Added to trackedItems")
	else
		updateGUI(nil, nil, "Skipped: " .. itemModel.Name)
	end
end

-- Track all existing items
for _, item in ipairs(ItemFolder:GetChildren()) do
	trackItem(item)
end

-- Track new spawns
ItemFolder.ChildAdded:Connect(function(child)
	task.wait(0.2)
	trackItem(child)
end)

--// Hold E key simulation
local function holdE(duration)
	VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
	task.wait(duration)
	VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

--// Step teleport with anti-kick
local function stepTeleport(targetCFrame)
	local origin = HRP().CFrame.Position
	local goal = targetCFrame.Position
	local direction = (goal - origin).Unit
	local distance = (goal - origin).Magnitude
	local steps = math.floor(distance / TeleportStepDistance)

	for i = 1, steps do
		local step = origin + (direction * TeleportStepDistance * i)
		HRP().CFrame = CFrame.new(step)
		task.wait(TeleportStepWait)
	end

	HRP().CFrame = targetCFrame
end

--// Pickup Logic
local function pickupItem(item)
	IsFarming = true
	updateGUI("Last Item: " .. item.name, "Teleporting...", "To item")

	-- Teleport under item
	local goal = CFrame.new(item.position + TeleportOffset)
	stepTeleport(goal)
	task.wait(0.1)

	updateGUI("Last Item: " .. item.name, "Picking Up...", "Holding E")
	holdE(PickupHoldTime)

	pcall(function()
		fireproximityprompt(item.prompt)
	end)

	task.wait(StayUnderItemTime)

	-- Return to safe spot
	updateGUI(nil, "Returning...", "To safe spot")
	stepTeleport(ReturnSpot)
	task.wait(0.2)

	IsFarming = false
end

--// Sell logic
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

--// Lucky Arrow auto-buy
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

--// Serverhop (respects farming toggle)
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

-- Serverhop every 105 seconds
task.spawn(function()
	while true do
		task.wait(ServerhopDelay)
		if not IsFarming and FarmEnabled then
			updateGUI(nil, "Serverhop...", "Timer done")
			serverHop()
		end
	end
end)

-- Panic key
game:GetService("UserInputService").InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.P then
		updateGUI(nil, "Panic Key!", "Teleporting back")
		stepTeleport(ReturnSpot)
	end
end)

--// Main farming loop
while true do
	task.wait(0.5)

	if not FarmEnabled then
		updateGUI(nil, "Paused", "Toggle Farming to resume")
		continue
	end

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
		updateGUI(nil, "Idle", "Waiting for item...")
	end
end
