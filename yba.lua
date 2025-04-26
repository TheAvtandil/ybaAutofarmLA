-- PigletHUB V2 Ultimate YBA Autofarm 🚀
-- Built by ChatGPT + DearUser7 🐷🔥

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

--// Variables
local Player = Players.LocalPlayer
local Character = function() return Player.Character or Player.CharacterAdded:Wait() end
local HRP = function() return Character():WaitForChild("HumanoidRootPart") end
local PlayerStats = Player:WaitForChild("PlayerStats")

local PLACE_ID = 2809202155
local SafeSpot = CFrame.new(978, -42, -49)
local ServerHopDelay = 105
local StayTimeUnderItem = 0.5
local FarmingEnabled = true
local IsFarming = false
local TrackedItems = {}

--// Anti-Cheat Bypass
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
--// Wall Bypass
local MapFolder = Instance.new("Folder", workspace)
for _, Part in ipairs(workspace.Map:GetChildren()) do
    Part.Parent = MapFolder
end

--// GUI
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

    local function createLabel(name, pos, size, color, text)
        local label = Instance.new("TextLabel", frame)
        label.Name = name
        label.Position = pos
        label.Size = size
        label.BackgroundTransparency = 1
        label.TextColor3 = color
        label.Font = Enum.Font.SourceSansBold
        label.TextSize = 14
        label.Text = text
        label.TextWrapped = true
        return label
    end

    createLabel("Title", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 20), Color3.new(1,1,1), "PigletHUB Autofarm V2").TextSize = 18
    createLabel("Status", UDim2.new(0, 0, 0, 20), UDim2.new(1, 0, 0, 20), Color3.fromRGB(0,255,0), "Status: Idle")
    createLabel("Debug", UDim2.new(0, 0, 0, 40), UDim2.new(1, 0, 0, 40), Color3.fromRGB(200,200,200), "Debug:\n...")
    createLabel("ItemLog", UDim2.new(0, 0, 0, 85), UDim2.new(1, 0, 0, 20), Color3.fromRGB(0,200,255), "Item: None")
    createLabel("Money", UDim2.new(0, 0, 0, 110), UDim2.new(1, 0, 0, 20), Color3.fromRGB(255,255,0), "Money: $0")

local toggle = Instance.new("TextButton", frame)
toggle.Name = "FarmToggle"
toggle.Position = UDim2.new(0, 0, 1, -22)
toggle.Size = UDim2.new(1, 0, 0, 20)
toggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggle.TextColor3 = Color3.new(1,1,1)
toggle.Font = Enum.Font.SourceSansBold
toggle.TextSize = 14
toggle.Text = "Farming: " .. (FarmingEnabled and "ON" or "OFF")

toggle.MouseButton1Click:Connect(function()
    FarmingEnabled = not FarmingEnabled
    toggle.Text = "Farming: " .. (FarmingEnabled and "ON" or "OFF")
end)

-- now Speed Toggle (still inside createGUI())
local speedToggle = Instance.new("TextButton", frame)
speedToggle.Name = "SpeedToggle"
speedToggle.Position = UDim2.new(0, 0, 1, -44)
speedToggle.Size = UDim2.new(1, 0, 0, 20)
speedToggle.BackgroundColor3 = Color3.fromRGB(80, 50, 50)
speedToggle.BorderSizePixel = 0
speedToggle.TextColor3 = Color3.new(1, 1, 1)
speedToggle.Font = Enum.Font.SourceSansBold
speedToggle.TextSize = 14
speedToggle.Text = "Speed Mode: " .. (SpeedModeEnabled and "ON" or "OFF")

speedToggle.MouseButton1Click:Connect(function()
    SpeedModeEnabled = not SpeedModeEnabled
    speedToggle.Text = "Speed Mode: " .. (SpeedModeEnabled and "ON" or "OFF")
end)

end

createGUI()

local function updateGUI(status, debug, item)
    local gui = Player:WaitForChild("PlayerGui"):WaitForChild("PigletHUB")
    if gui then
        if status then gui.Main.Status.Text = "Status: " .. status end
        if debug then gui.Main.Debug.Text = "Debug:\n" .. debug end
        if item then gui.Main.ItemLog.Text = "Item: " .. item end
        gui.Main.Money.Text = "Money: $" .. tostring(math.floor(PlayerStats.Money.Value))
    end
end

--// Noclip Always On
RunService.Stepped:Connect(function()
    local char = Character()
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end)

--// Item Tracking
local ItemFolder = Workspace:WaitForChild("Item_Spawns"):WaitForChild("Items")
local function trackItem(itemModel)
    if not itemModel:IsA("Model") then return end
    local prompt = itemModel:FindFirstChildWhichIsA("ProximityPrompt", true)
    local part = itemModel:FindFirstChildWhichIsA("BasePart", true)
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
for _, item in ipairs(ItemFolder:GetChildren()) do task.spawn(function() trackItem(item) end) end
ItemFolder.ChildAdded:Connect(function(item) task.wait(0.1) trackItem(item) end)

--// Instant Teleport
local function instantTeleport(cframe)
    local hrp = HRP()
    if hrp then hrp.CFrame = cframe end
end

--// Hold E
local function holdE(duration)
    local pickupTime = SpeedModeEnabled and FastPickupDelay or NormalPickupDelay
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(pickupTime)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

--// Pickup Item
local function pickupItem(item)
    IsFarming = true
    updateGUI("Farming", "Going to item...", item.name)
    instantTeleport(CFrame.new(item.position + Vector3.new(0, -6, 0)))
    task.wait(0.1)

    updateGUI("Picking", "Holding E", item.name)
    holdE(0.25)
    pcall(function() fireproximityprompt(item.prompt) end)
    task.wait(StayTimeUnderItem)

    IsFarming = false
end

--// Quick Sell All
local function quickSell()
    local backpack = Player.Backpack:GetChildren()
    for _, tool in ipairs(backpack) do
        local hum = Character():FindFirstChildOfClass("Humanoid")
        if hum and tool:IsA("Tool") then
            hum:EquipTool(tool)
            local timeout = tick() + 1
            repeat task.wait(0.1) until Character():FindFirstChild(tool.Name) or tick() > timeout
            if Character():FindFirstChild(tool.Name) then
                Character().RemoteEvent:FireServer("EndDialogue", { NPC = "Merchant", Dialogue = "Dialogue5", Option = "Option2" })
                updateGUI("Sold", "Sold " .. tool.Name)
                task.wait(0.3)
            end
        end
    end
end

--// Lucky Arrow Auto Buyer
local function buyLucky()
    if PlayerStats.Money.Value >= 50000 then
        Character().RemoteEvent:FireServer("PurchaseShopItem", { ItemName = "1x Lucky Arrow" })
        updateGUI("Buying", "Lucky Arrow Bought!")
        task.wait(0.5)
    end
end

--// Find Closest Item
local function getClosestItem()
    local closest, minDist
    local pos = HRP().Position
    for i, item in ipairs(TrackedItems) do
        if item and item.model and item.prompt and item.part then
            local dist = (item.position - pos).Magnitude
            if not minDist or dist < minDist then
                closest = i
                minDist = dist
            end
        end
    end
    return closest
end

--// Main Farm Loop
task.spawn(function()
    while true do
        task.wait(0.5)
        if not FarmingEnabled then continue end

        local closest = getClosestItem()
        if closest then
            local item = TrackedItems[closest]
            table.remove(TrackedItems, closest)
            pickupItem(item)
        else
            quickSell()
            buyLucky()
            updateGUI("Idle", "Waiting for items...")
        end
    end
end)

--// Panic (P Key)
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.P then
        updateGUI("Panic!", "Back to SafeSpot!")
        instantTeleport(SafeSpot)
    end
end)

--// ServerHop Every 105s
task.spawn(function()
    while true do
        task.wait(ServerHopDelay)
        if not IsFarming and FarmingEnabled then
            updateGUI("ServerHop", "Switching Servers...")
            pcall(function()
                local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..PLACE_ID.."/servers/Public?sortOrder=Asc&limit=100")).data
                local choices = {}
                for _, s in ipairs(servers) do
                    if s.playing < s.maxPlayers and s.id ~= game.JobId then
                        table.insert(choices, s.id)
                    end
                end
                if #choices > 0 then
                    TeleportService:TeleportToPlaceInstance(PLACE_ID, choices[math.random(1, #choices)], Player)
                end
            end)
        end
    end
end)

--// Lag Boost
task.spawn(function()
    task.wait(2)
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
        Lighting.Brightness = 2
    end)
end)

