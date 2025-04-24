-- PigletHUB Autofarm for Your Bizarre Adventure (YBA)
-- Services
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local Character = function() return Player.Character or Player.CharacterAdded:Wait() end
local HRP = function() return Character():WaitForChild("HumanoidRootPart") end
local PlayerStats = Player:WaitForChild("PlayerStats")

-- Configuration
local PLACE_ID = 2809202155
local ReturnSpot = CFrame.new(978, -42, -49)
local teleportOffset = Vector3.new(0, -6, 0)
local serverHopTime = 105
local AutoSell = true
local BuyLucky = true

-- GUI Setup
local function createGUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "PigletHUB"
    gui.ResetOnSpawn = false
    gui.Parent = Player:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame", gui)
    frame.Name = "Main"
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.Size = UDim2.new(0, 250, 0, 150)

    local title = Instance.new("TextLabel", frame)
    title.Text = "PigletHUB"
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 20
    title.TextColor3 = Color3.new(1, 1, 1)
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 20)

    local itemLog = Instance.new("TextLabel", frame)
    itemLog.Name = "ItemLog"
    itemLog.Text = "Item Log:\n"
    itemLog.TextWrapped = true
    itemLog.TextYAlignment = Enum.TextYAlignment.Top
    itemLog.Font = Enum.Font.SourceSans
    itemLog.TextSize = 14
    itemLog.TextColor3 = Color3.fromRGB(200, 200, 200)
    itemLog.BackgroundTransparency = 1
    itemLog.Position = UDim2.new(0, 0, 0, 25)
    itemLog.Size = UDim2.new(1, 0, 0, 80)

    local moneyText = Instance.new("TextLabel", frame)
    moneyText.Name = "Money"
    moneyText.Text = "Money: ..."
    moneyText.Font = Enum.Font.SourceSans
    moneyText.TextSize = 14
    moneyText.TextColor3 = Color3.fromRGB(255, 255, 0)
    moneyText.BackgroundTransparency = 1
    moneyText.Position = UDim2.new(0, 0, 0, 110)
    moneyText.Size = UDim2.new(1, 0, 0, 20)

    local statusText = Instance.new("TextLabel", frame)
    statusText.Name = "Status"
    statusText.Text = "Status: Idle"
    statusText.Font = Enum.Font.SourceSans
    statusText.TextSize = 14
    statusText.TextColor3 = Color3.fromRGB(0, 255, 0)
    statusText.BackgroundTransparency = 1
    statusText.Position = UDim2.new(0, 0, 0, 130)
    statusText.Size = UDim2.new(1, 0, 0, 20)
end

createGUI()

-- Rejoin after kick
local function autoRejoin()
    game:GetService("Players").LocalPlayer.OnTeleport:Connect(function(state)
        if state == Enum.TeleportState.Failed or state == Enum.TeleportState.Started then
            TeleportService:Teleport(PLACE_ID, Player)
        end
    end)
end
autoRejoin()

-- Utils
local function updateGUI(status, itemName)
    local gui = Player:FindFirstChild("PlayerGui") and Player.PlayerGui:FindFirstChild("PigletHUB")
    if gui then
        if status then gui.Main.Status.Text = "Status: " .. status end
        if itemName then
            gui.Main.ItemLog.Text = gui.Main.ItemLog.Text .. "\nPicked: " .. itemName
            gui.Main.Money.Text = "Money: $" .. math.floor(PlayerStats.Money.Value)
        end
    end
end

local function holdEKey(duration)
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(duration)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

local function firePrompt(prompt)
    if prompt and typeof(prompt) == "Instance" and prompt:IsA("ProximityPrompt") then
        fireproximityprompt(prompt)
    end
end

local function safeTeleportTo(pos)
    local success = pcall(function()
        HRP().CFrame = CFrame.new(pos + teleportOffset)
    end)
    updateGUI("Teleporting...", "")
    task.wait(0.5)
    return success
end

local function toggleNoclip(state)
    for _, p in pairs(Character():GetDescendants()) do
        if p:IsA("BasePart") then
            p.CanCollide = not state
        end
    end
end

-- Track Items
local trackedItems = {}
local function trackItem(itemModel)
    local prompt = itemModel:FindFirstChildWhichIsA("ProximityPrompt", true)
    local part = itemModel:FindFirstChild("Handle") or itemModel.PrimaryPart or itemModel:FindFirstChildWhichIsA("BasePart")
    if prompt and prompt.ObjectText and part then
        table.insert(trackedItems, {
            name = prompt.ObjectText,
            position = part.Position,
            prompt = prompt
        })
    end
end

local itemFolder = Workspace:WaitForChild("Item_Spawns"):WaitForChild("Items")
for _, item in pairs(itemFolder:GetDescendants()) do
    if item:IsA("Model") then
        pcall(function() trackItem(item) end)
    end
end
itemFolder.DescendantAdded:Connect(function(item)
    if item:IsA("Model") then
        task.wait(0.5)
        pcall(function() trackItem(item) end)
    end
end)

-- Sell Setup
local SellItems = {
    ["Gold Coin"] = true, ["Rokakaka"] = true, ["Pure Rokakaka"] = true,
    ["Mysterious Arrow"] = true, ["Diamond"] = true, ["Ancient Scroll"] = true,
    ["Caesar's Headband"] = true, ["Stone Mask"] = true,
    ["Rib Cage of The Saint's Corpse"] = true, ["Quinton's Glove"] = true,
    ["Zeppeli's Hat"] = true, ["Clackers"] = true, ["Steel Ball"] = true,
    ["Dio's Diary"] = true
}

-- Inventory Watch
Player.Backpack.ChildAdded:Connect(function(child)
    if SellItems[child.Name] then
        task.wait(0.1)
        Character().Humanoid:EquipTool(child)
        task.wait(0.1)
        Character().RemoteEvent:FireServer("EndDialogue", {
            NPC = "Merchant",
            Dialogue = "Dialogue5",
            Option = "Option2"
        })
        task.wait(0.3)
    end
end)

-- Item Collection Loop
while true do
    for i = #trackedItems, 1, -1 do
        local item = trackedItems[i]
        table.remove(trackedItems, i)
        if item.prompt and item.prompt.Parent then
            toggleNoclip(true)
            if safeTeleportTo(item.position) then
                updateGUI("Holding E", item.name)
                holdEKey(1.2)
                firePrompt(item.prompt)
                task.wait(0.4)
                updateGUI("Returning", item.name)
                pcall(function() HRP().CFrame = ReturnSpot end)
                toggleNoclip(false)
                task.wait(1.5)
            end
        else
            updateGUI("Invalid prompt", item.name)
        end
    end
    task.wait(1)
end

-- Server Hop Logic
spawn(function()
    while true do
        task.wait(serverHopTime)
        local success, data = pcall(function()
            return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. PLACE_ID .. "/servers/Public?sortOrder=Asc&limit=100"))
        end)
        if success and data and data.data then
            for _, server in ipairs(data.data) do
                if server.id ~= game.JobId and server.playing < server.maxPlayers then
                    updateGUI("Server Hop", "Joining new server")
                    TeleportService:TeleportToPlaceInstance(PLACE_ID, server.id, Player)
                    break
                end
            end
        else
            updateGUI("Hop Failed", "Retrying next cycle")
        end
    end
end)
