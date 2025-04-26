-- PigletHUB V2 - Ultimate YBA Autofarm (Better Service Setup)
-- Built by ChatGPT + DearUser7 🐷🔥

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local PhysicsService = game:GetService("PhysicsService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")

--// Variables
local Player = Players.LocalPlayer
local Character = function() return Player.Character or Player.CharacterAdded:Wait() end
local HRP = function() return Character():WaitForChild("HumanoidRootPart") end
local PlayerStats = Player:WaitForChild("PlayerStats")

--// Config
local PLACE_ID = 2809202155
local SafeSpot = CFrame.new(978, -42, -49)
local TeleportOffset = Vector3.new(0, -6, 0)
local StayTimeUnderItem = 0.5
local ServerHopDelay = 105
local AutoSellEnabled = true
local BuyLuckyArrowEnabled = true
local FarmingEnabled = true
local IsFarming = false

--// Item Tracking
local TrackedItems = {}

--// Item Selling Settings
local ItemSellList = {
    ["Gold Coin"] = true,
    ["Rokakaka"] = true,
    ["Pure Rokakaka"] = true,
    ["Mysterious Arrow"] = true,
    ["Diamond"] = true,
    ["Ancient Scroll"] = true,
    ["Caesar's Headband"] = true,
    ["Stone Mask"] = true,
    ["Rib Cage of The Saint's Corpse"] = true,
    ["Quinton's Glove"] = true,
    ["Zeppeli's Hat"] = true,
    ["Clackers"] = true,
    ["Steel Ball"] = true,
    ["Dio's Diary"] = true,
    ["Lucky Arrow"] = false -- Do not sell Lucky Arrow
}
local ItemCaps = ItemSellList -- reuse for item caps
--// Create Corrected GUI
local function createGUI()
    local gui = Instance.new("ScreenGui", Players.LocalPlayer:WaitForChild("PlayerGui"))
    gui.Name = "PigletHUB"

    local frame = Instance.new("Frame", gui)
    frame.Name = "Main"
    frame.Size = UDim2.new(0, 270, 0, 180)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
    frame.Active = true
    frame.Draggable = true

    -- Title
    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 20)
    title.Text = "PigletHUB Autofarm V2"
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 18

    -- Status
    local status = Instance.new("TextLabel", frame)
    status.Name = "Status"
    status.Position = UDim2.new(0, 0, 0, 25)
    status.Size = UDim2.new(1, 0, 0, 20)
    status.TextColor3 = Color3.fromRGB(0,255,0)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.SourceSans
    status.TextSize = 14
    status.Text = "Status: Idle"

    -- Debug
    local debug = Instance.new("TextLabel", frame)
    debug.Name = "Debug"
    debug.Position = UDim2.new(0, 0, 0, 45)
    debug.Size = UDim2.new(1, 0, 0, 40)
    debug.TextColor3 = Color3.fromRGB(200,200,200)
    debug.BackgroundTransparency = 1
    debug.Font = Enum.Font.SourceSans
    debug.TextSize = 14
    debug.TextWrapped = true
    debug.Text = "Debug:\n..."

    -- Item Log
    local itemLog = Instance.new("TextLabel", frame)
    itemLog.Name = "ItemLog"
    itemLog.Position = UDim2.new(0, 0, 0, 90)
    itemLog.Size = UDim2.new(1, 0, 0, 20)
    itemLog.TextColor3 = Color3.fromRGB(0,200,255)
    itemLog.BackgroundTransparency = 1
    itemLog.Font = Enum.Font.SourceSans
    itemLog.TextSize = 14
    itemLog.Text = "Item: None"

    -- Money
    local money = Instance.new("TextLabel", frame)
    money.Name = "Money"
    money.Position = UDim2.new(0, 0, 0, 115)
    money.Size = UDim2.new(1, 0, 0, 20)
    money.TextColor3 = Color3.fromRGB(255,255,0)
    money.BackgroundTransparency = 1
    money.Font = Enum.Font.SourceSans
    money.TextSize = 14
    money.Text = "Money: $0"

    -- NOW ADD Toggle button
    local toggle = Instance.new("TextButton", frame)
    toggle.Name = "FarmToggle"
    toggle.Position = UDim2.new(0, 0, 1, -20) -- Bottom of frame
    toggle.Size = UDim2.new(1, 0, 0, 18)
    toggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    toggle.BorderSizePixel = 0
    toggle.TextColor3 = Color3.new(1, 1, 1)
    toggle.Font = Enum.Font.SourceSansBold
    toggle.TextSize = 14
    toggle.Text = "Farming: " .. (FarmingEnabled and "ON" or "OFF")

    toggle.MouseButton1Click:Connect(function()
        FarmingEnabled = not FarmingEnabled
        toggle.Text = "Farming: " .. (FarmingEnabled and "ON" or "OFF")
        updateGUI(FarmingEnabled and "Farming Enabled" or "Farming Paused", "Toggled by user.")
    end)
end
createGUI()

--// GUI Update Function
local function updateGUI(statusText, debugText, itemName)
    local gui = Players.LocalPlayer:FindFirstChild("PlayerGui"):FindFirstChild("PigletHUB")
    if gui and gui:FindFirstChild("Main") then
        if statusText then
            gui.Main.Status.Text = "Status: " .. statusText
        end
        if debugText then
            gui.Main.Debug.Text = "Debug:\n" .. debugText
        end
        if itemName then
            gui.Main.ItemLog.Text = "Item: " .. itemName
        end
        if gui.Main.Money then
            gui.Main.Money.Text = "Money: $" .. tostring(math.floor(PlayerStats.Money.Value))
        end
    end
end
--// Instant Teleport
local function instantTeleport(cframe)
    HRP().CFrame = cframe
end

--// Track All Items (improved)
local ItemFolder = Workspace:WaitForChild("Item_Spawns"):WaitForChild("Items")

local function trackItem(itemModel)
    if not itemModel:IsA("Model") then return end
    local prompt = itemModel:FindFirstChildWhichIsA("ProximityPrompt", true)
    local part = nil

    -- Find usable part (MeshPart, Part, or any BasePart)
    for _, desc in ipairs(itemModel:GetDescendants()) do
        if desc:IsA("MeshPart") or desc:IsA("Part") or desc:IsA("BasePart") then
            part = desc
            break
        end
    end

    if prompt and part and prompt.ObjectText and prompt.ObjectText ~= "" then
        table.insert(TrackedItems, {
            model = itemModel,
            prompt = prompt,
            part = part,
            name = prompt.ObjectText,
            position = part.Position
        })
        updateGUI("Tracking", "Tracking item...", prompt.ObjectText)
    else
        updateGUI(nil, "Bad item skipped", itemModel.Name)
    end
end

--// Initial Tracking
for _, item in ipairs(ItemFolder:GetChildren()) do
    task.spawn(function()
        trackItem(item)
    end)
end

--// Track newly spawned items
ItemFolder.ChildAdded:Connect(function(child)
    task.wait(0.1)
    trackItem(child)
end)
--// Hold E Key
local function holdE(duration)
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(duration)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

--// Pickup Item Logic
local function pickupItem(item)
    IsFarming = true
    updateGUI("Farming", "Teleporting to: " .. item.name)

    -- Teleport under item
    local targetPos = item.position + TeleportOffset
    instantTeleport(CFrame.new(targetPos))
    task.wait(0.1)

    -- Hold E to pick up
    updateGUI("Farming", "Holding E: " .. item.name)
    holdE(0.25)

    -- Backup ProximityPrompt
    pcall(function()
        fireproximityprompt(item.prompt)
    end)

    -- Stay under item
    task.wait(StayTimeUnderItem)

    -- Return to SafeSpot
    updateGUI("Returning", "Safe Spot")
    instantTeleport(SafeSpot)
    task.wait(0.2)

    IsFarming = false
end

--// Main Farming Loop
task.spawn(function()
    while true do
        task.wait(0.5)

        if not FarmingEnabled then
            updateGUI("Paused", "Waiting for toggle...")
            continue
        end

        local validItem
        for i = #TrackedItems, 1, -1 do
            local item = TrackedItems[i]
            if item.model and item.prompt and item.prompt.Parent and item.part and not item.model:IsDescendantOf(nil) then
                validItem = item
                table.remove(TrackedItems, i)
                break
            else
                table.remove(TrackedItems, i)
            end
        end

        if validItem then
            pickupItem(validItem)
        else
            quickSell()
            buyLucky()
            updateGUI("Idle", "Waiting for items...")
        end
    end
end)
--// Quick Sell Logic
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
    if not AutoSellEnabled then return end
    local sold = 0
    for itemName, shouldSell in pairs(ItemSellList) do
        if shouldSell then
            for _, tool in ipairs(Player.Backpack:GetChildren()) do
                if tool.Name == itemName then
                    if equipAndSell(tool) then
                        sold += 1
                        updateGUI("Sold", "Sold: " .. tool.Name .. " | Total: " .. sold)
                    end
                end
            end
        end
    end
end

--// Lucky Arrow Auto Buyer
local function buyLucky()
    if not BuyLuckyArrowEnabled then return end
    local money = PlayerStats.Money.Value
    if money >= 50000 then
        Character().RemoteEvent:FireServer("PurchaseShopItem", { ItemName = "1x Lucky Arrow" })
        updateGUI("Buying Lucky Arrow", "Money: $" .. money)
        task.wait(0.3)
    end
end

--// ServerHop Logic
local function serverHop()
    local success, result = pcall(function()
        local servers = {}
        local response = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. PLACE_ID .. "/servers/Public?sortOrder=Asc&limit=100"))
        for _, s in ipairs(response.data) do
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
        updateGUI("Hop Failed", "Retrying in 5s")
        task.wait(5)
        serverHop()
    end
end

--// Auto ServerHop every 105s
task.spawn(function()
    while true do
        task.wait(ServerHopDelay)
        if not IsFarming and FarmingEnabled then
            updateGUI("Serverhopping", "Time to hop")
            serverHop()
        end
    end
end)

--// Panic Key (P) Instant Teleport to Safe Spot
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.P then
        updateGUI("Panic Key!", "Teleporting to Safe Spot...")
        instantTeleport(SafeSpot)
    end
end)
--// Add Toggle Button to GUI
local function createToggleButton()
    local gui = Players.LocalPlayer:FindFirstChild("PlayerGui"):FindFirstChild("PigletHUB")
    if not gui then return end

    local frame = gui:FindFirstChild("Main")
    if not frame then return end

    local toggle = Instance.new("TextButton")
    toggle.Name = "FarmToggle"
    toggle.Parent = frame
    toggle.Position = UDim2.new(0, 0, 1, -25)
    toggle.Size = UDim2.new(1, 0, 0, 20)
    toggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    toggle.TextColor3 = Color3.new(1, 1, 1)
    toggle.Font = Enum.Font.SourceSans
    toggle.TextSize = 14
    toggle.Text = "Farming: " .. (FarmingEnabled and "ON" or "OFF")

    toggle.MouseButton1Click:Connect(function()
        FarmingEnabled = not FarmingEnabled
        toggle.Text = "Farming: " .. (FarmingEnabled and "ON" or "OFF")
        updateGUI(FarmingEnabled and "Farming Enabled" or "Farming Paused", "Toggle switched!")
    end)
end
createToggleButton()
