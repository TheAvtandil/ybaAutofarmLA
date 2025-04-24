--// SERVICES
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local Character = function() return Player.Character or Player.CharacterAdded:Wait() end
local HRP = function() return Character():WaitForChild("HumanoidRootPart") end

--// SETTINGS
local ReturnSpot = CFrame.new(978, -42, -49)
local SellItems = {
    ["Gold Coin"] = true, ["Rokakaka"] = true, ["Pure Rokakaka"] = true,
    ["Mysterious Arrow"] = true, ["Diamond"] = true, ["Ancient Scroll"] = true,
    ["Caesar's Headband"] = true, ["Stone Mask"] = true,
    ["Rib Cage of The Saint's Corpse"] = true, ["Quinton's Glove"] = true,
    ["Zeppeli's Hat"] = true, ["Clackers"] = true, ["Steel Ball"] = true,
    ["Dio's Diary"] = true
}
local ItemCaps = {
    ["Gold Coin"] = 45, ["Rokakaka"] = 25, ["Pure Rokakaka"] = 10,
    ["Mysterious Arrow"] = 25, ["Diamond"] = 30, ["Ancient Scroll"] = 10,
    ["Caesar's Headband"] = 10, ["Stone Mask"] = 10,
    ["Rib Cage of The Saint's Corpse"] = 20, ["Quinton's Glove"] = 10,
    ["Zeppeli's Hat"] = 10, ["Lucky Arrow"] = 10,
    ["Clackers"] = 10, ["Steel Ball"] = 10, ["Dio's Diary"] = 10
}

--// GUI
local gui = Instance.new("ScreenGui", Player:WaitForChild("PlayerGui"))
gui.Name = "PigletHUB"
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 220, 0, 100)
frame.Position = UDim2.new(1, -230, 0, 50)
frame.BackgroundTransparency = 0.3
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local itemLabel = Instance.new("TextLabel", frame)
itemLabel.Size = UDim2.new(1, -10, 0, 40)
itemLabel.Position = UDim2.new(0, 5, 0, 5)
itemLabel.BackgroundTransparency = 1
itemLabel.TextColor3 = Color3.new(1,1,1)
itemLabel.TextScaled = true
itemLabel.Text = "Item: N/A"

local moneyLabel = Instance.new("TextLabel", frame)
moneyLabel.Size = UDim2.new(1, -10, 0, 40)
moneyLabel.Position = UDim2.new(0, 5, 0, 50)
moneyLabel.BackgroundTransparency = 1
moneyLabel.TextColor3 = Color3.new(0,1,0)
moneyLabel.TextScaled = true
moneyLabel.Text = "Money: 0"

--// UPDATE MONEY DISPLAY
spawn(function()
    local money = Player:WaitForChild("PlayerStats"):WaitForChild("Money")
    while true do
        moneyLabel.Text = "Money: " .. tostring(money.Value)
        wait(1)
    end
end)

--// ITEM TELEPORT + TRACKING
local ItemFolder = Workspace:WaitForChild("Item_Spawns"):WaitForChild("Items")
local trackedItems = {}

local function hasMax(item)
    local count = 0
    for _, tool in ipairs(Player.Backpack:GetChildren()) do
        if tool.Name == item then
            count += 1
        end
    end
    return (ItemCaps[item] or 9999) <= count
end

ItemFolder.ChildAdded:Connect(function(item)
    wait(0.2)
    local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt and prompt.ObjectText then
        table.insert(trackedItems, {
            name = prompt.ObjectText,
            prompt = prompt,
            model = item,
            position = item.PrimaryPart and item.PrimaryPart.Position
        })
    end
end)

--// SELL LOOP
spawn(function()
    while true do
        wait(5)
        for itemName, sell in pairs(SellItems) do
            local tool = Player.Backpack:FindFirstChild(itemName)
            if sell and tool then
                Character().Humanoid:EquipTool(tool)
                Character().RemoteEvent:FireServer("EndDialogue", {
                    NPC = "Merchant",
                    Dialogue = "Dialogue5",
                    Option = "Option2"
                })
                wait(0.3)
            end
        end
    end
end)

--// ITEM FARMING LOOP
spawn(function()
    while true do
        for i = #trackedItems, 1, -1 do
            local item = trackedItems[i]
            if item.prompt and item.prompt.Parent and not hasMax(item.name) then
                local pos = item.position
                if pos then
                    local safeCFrame = CFrame.new(pos.X, pos.Y - 1.4, pos.Z)
                    HRP().CFrame = safeCFrame
                    wait(0.2)
                    pcall(function() fireproximityprompt(item.prompt) end)
                    wait(0.2)
                    HRP().CFrame = ReturnSpot
                    itemLabel.Text = "Item: " .. item.name
                end
            end
            table.remove(trackedItems, i)
        end
        wait(2)
    end
end)

--// SERVER HOP FUNCTION
function serverhop()
    local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/2809202155/servers/Public?sortOrder=2&limit=100"))
    for _, server in pairs(servers.data) do
        if server.playing < server.maxPlayers then
            TeleportService:TeleportToPlaceInstance(2809202155, server.id, Player)
            break
        end
    end
end

--// SERVERHOP TIMER (105 seconds)
spawn(function()
    while true do
        wait(105)
        pcall(serverhop)
    end
end)

--// AUTO REJOIN AFTER KICK OR CRASH
game:GetService("CoreGui").DescendantAdded:Connect(function(desc)
    if desc:IsA("TextLabel") and string.find(desc.Text, "disconnected") then
        TeleportService:Teleport(game.PlaceId)
    end
end)
