-- PigletHUB V2 - Ultimate YBA Autofarm (Final Clean Full Fix)
-- Built by ChatGPT + DearUser7 🐷🔥

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

--// Variables
local Player = Players.LocalPlayer
local Character = function() return Player.Character or Player.CharacterAdded:Wait() end
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
local TrackedItems = {}

--// Anti-Cheat Bypasses
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local args = {...}
    if not checkcaller() and getnamecallmethod() == "InvokeServer" and args[1] == "idklolbrah2de" then
        return "  ___XP DE KEY"
    end
    return oldNamecall(self, ...)
end))

local oldIndex
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
    if not checkcaller() and typeof(self) == "Vector3" and key == "Magnitude" then
        local callingScript = getcallingscript()
        if callingScript and callingScript.Name == "ItemSpawn" then
            return 0
        end
    end
    return oldIndex(self, key)
end))
--// GUI Creation
local function createGUI()
    local gui = Instance.new("ScreenGui", Player:WaitForChild("PlayerGui"))
    gui.Name = "PigletHUB"

    local frame = Instance.new("Frame", gui)
    frame.Name = "Main"
    frame.Size = UDim2.new(0, 270, 0, 200)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
    frame.Active = true
    frame.Draggable = true

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 20)
    title.Text = "PigletHUB Autofarm V2"
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 18

    local status = Instance.new("TextLabel", frame)
    status.Name = "Status"
    status.Position = UDim2.new(0, 0, 0, 25)
    status.Size = UDim2.new(1, 0, 0, 20)
    status.TextColor3 = Color3.fromRGB(0,255,0)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.SourceSans
    status.TextSize = 14
    status.Text = "Status: Idle"

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

    local itemLog = Instance.new("TextLabel", frame)
    itemLog.Name = "ItemLog"
    itemLog.Position = UDim2.new(0, 0, 0, 90)
    itemLog.Size = UDim2.new(1, 0, 0, 20)
    itemLog.TextColor3 = Color3.fromRGB(0,200,255)
    itemLog.BackgroundTransparency = 1
    itemLog.Font = Enum.Font.SourceSans
    itemLog.TextSize = 14
    itemLog.Text = "Item: None"

    local money = Instance.new("TextLabel", frame)
    money.Name = "Money"
    money.Position = UDim2.new(0, 0, 0, 115)
    money.Size = UDim2.new(1, 0, 0, 20)
    money.TextColor3 = Color3.fromRGB(255,255,0)
    money.BackgroundTransparency = 1
    money.Font = Enum.Font.SourceSans
    money.TextSize = 14
    money.Text = "Money: $0"

    local toggle = Instance.new("TextButton", frame)
    toggle.Name = "FarmToggle"
    toggle.Position = UDim2.new(0, 0, 1, -22)
    toggle.Size = UDim2.new(1, 0, 0, 20)
    toggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    toggle.BorderSizePixel = 0
    toggle.TextColor3 = Color3.new(1, 1, 1)
    toggle.Font = Enum.Font.SourceSansBold
    toggle.TextSize = 14
    toggle.Text = "Farming: " .. (FarmingEnabled and "ON" or "OFF")

    toggle.MouseButton1Click:Connect(function()
        FarmingEnabled = not FarmingEnabled
        toggle.Text = "Farming: " .. (FarmingEnabled and "ON" or "OFF")
        updateGUI(FarmingEnabled and "Farming Enabled" or "Paused", "Toggled by user")
    end)
end
createGUI()
--// Update GUI
local function updateGUI(statusText, debugText, itemName)
    local gui = Players.LocalPlayer:FindFirstChild("PlayerGui"):FindFirstChild("PigletHUB")
    if gui and gui:FindFirstChild("Main") then
        if statusText then gui.Main.Status.Text = "Status: " .. statusText end
        if debugText then gui.Main.Debug.Text = "Debug:\n" .. debugText end
        if itemName then gui.Main.ItemLog.Text = "Item: " .. itemName end
        if gui.Main.Money then gui.Main.Money.Text = "Money: $" .. tostring(math.floor(PlayerStats.Money.Value)) end
    end
end
--// Safe Step Teleport
local function stepTeleport(targetCFrame)
    local hrp = Character():WaitForChild("HumanoidRootPart", 5)
    if not hrp then return end

    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    local steps = math.max(5, math.floor(distance / 5))
    local direction = (targetCFrame.Position - hrp.Position).Unit
    local stepSize = distance / steps

    for _ = 1, steps do
        hrp.CFrame = hrp.CFrame + direction * stepSize
        task.wait(0.02) -- Very fast but safe!
    end

    hrp.CFrame = targetCFrame
end
--// Hold E
local function holdE(duration)
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(duration)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end
--// Track Items
local ItemFolder = Workspace:WaitForChild("Item_Spawns"):WaitForChild("Items")

local function trackItem(itemModel)
    if not itemModel:IsA("Model") then return end

    local prompt = itemModel:FindFirstChildWhichIsA("ProximityPrompt", true)
    local part = nil
    for _, desc in ipairs(itemModel:GetDescendants()) do
        if desc:IsA("MeshPart") or desc:IsA("BasePart") then
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
        updateGUI("Tracking", "New Item", prompt.ObjectText)
    end
end

-- Track existing and new
for _, item in ipairs(ItemFolder:GetChildren()) do task.spawn(function() trackItem(item) end) end
ItemFolder.ChildAdded:Connect(function(item)
    task.wait(0.1)
    trackItem(item)
end)
--// Pickup Item
local function pickupItem(item)
    IsFarming = true
    updateGUI("Farming", "Teleporting to item...", item.name)

    local targetPos = item.position + TeleportOffset
    stepTeleport(CFrame.new(targetPos))
    task.wait(0.1)

    updateGUI("Picking", "Holding E", item.name)
    holdE(0.25)

    pcall(function()
        fireproximityprompt(item.prompt)
    end)

    task.wait(StayTimeUnderItem)

    updateGUI("Returning", "Safe Spot")
    stepTeleport(SafeSpot)
    task.wait(0.2)

    IsFarming = false
end
--// Quick Sell (Sell everything in Backpack)
local function quickSell()
    for _, tool in ipairs(Player.Backpack:GetChildren()) do
        local char = Character()
        local hum = char:FindFirstChild("Humanoid")
        if tool:IsA("Tool") and hum then
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
                updateGUI("Sold", "Sold " .. tool.Name)
            end
        end
    end
end
--// Lucky Arrow Auto Buyer
local function buyLucky()
    if PlayerStats.Money.Value >= 50000 then
        Character().RemoteEvent:FireServer("PurchaseShopItem", { ItemName = "1x Lucky Arrow" })
        updateGUI("Buying", "Bought Lucky Arrow!")
        task.wait(0.5)
    end
end
--// Panic Key (P)
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.P then
        updateGUI("Panic!", "Teleporting Safe!")
        stepTeleport(SafeSpot)
    end
end)
--// ServerHop Logic
local function serverHop()
    pcall(function()
        local servers = {}
        local res = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..PLACE_ID.."/servers/Public?sortOrder=Asc&limit=100"))
        for _, v in ipairs(res.data) do
            if v.playing < v.maxPlayers and v.id ~= game.JobId then
                table.insert(servers, v.id)
            end
        end
        if #servers > 0 then
            TeleportService:TeleportToPlaceInstance(PLACE_ID, servers[math.random(1, #servers)], Player)
        end
    end)
end

--// Auto ServerHop Every 105 Seconds
task.spawn(function()
    while true do
        task.wait(ServerHopDelay)
        if not IsFarming and FarmingEnabled then
            updateGUI("ServerHop", "Switching Servers...")
            serverHop()
        end
    end
end)
--// Auto-Rejoin if Disconnected
Player.OnTeleport:Connect(function(state)
    if state == Enum.TeleportState.Failed then
        TeleportService:Teleport(PLACE_ID)
    end
end)
--// Final Main Farming Loop
task.spawn(function()
    while true do
        task.wait(0.5)

        if not FarmingEnabled then
            updateGUI("Paused", "Farming OFF")
            continue
        end

        local validItem
        for i = #TrackedItems, 1, -1 do
            local item = TrackedItems[i]
            if item and item.model and item.prompt and item.prompt.Parent and item.part then
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
