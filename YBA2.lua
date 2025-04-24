-- Services
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TeleportService = game:GetService("TeleportService")
local Player = Players.LocalPlayer
local Character = function() return Player.Character or Player.CharacterAdded:Wait() end
local HRP = function() return Character():WaitForChild("HumanoidRootPart") end

-- Settings
local BuyLucky = true
local AutoSell = true
local ReturnSpot = CFrame.new(978, -42, -49)
local ServerHopTimer = 105
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
    ["Zeppeli's Hat"] = true, ["Lucky Arrow"] = false,
    ["Clackers"] = true, ["Steel Ball"] = true, ["Dio's Diary"] = true
}

-- Double item cap check
pcall(function()
    if MarketplaceService:UserOwnsGamePassAsync(Player.UserId, 14597778) then
        for k, v in pairs(ItemCaps) do ItemCaps[k] = v * 2 end
    end
end)

-- Helpers
local function toggleNoclip(state)
    for _, p in pairs(Character():GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = not state end
    end
end

local function hasMax(item)
    local count = 0
    for _, tool in pairs(Player.Backpack:GetChildren()) do
        if tool.Name == item then count += 1 end
    end
    return (ItemCaps[item] or 9999) <= count
end

local function equipTool(item)
    local tool = Player.Backpack:FindFirstChild(item)
    if tool then
        Character().Humanoid:EquipTool(tool)
        task.wait(0.1)
    end
end

-- GUI
local ScreenGui = Instance.new("ScreenGui", Player:WaitForChild("PlayerGui"))
ScreenGui.Name = "PigletHUB"
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Position = UDim2.new(1, -210, 0, 10)
MainFrame.Size = UDim2.new(0, 200, 0, 60)
MainFrame.BorderSizePixel = 0
MainFrame.BackgroundTransparency = 0.2

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0.3, 0)
Title.BackgroundTransparency = 1
Title.Text = "PigletHUB"
Title.TextColor3 = Color3.fromRGB(255, 105, 180)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18

local Info = Instance.new("TextLabel", MainFrame)
Info.Position = UDim2.new(0, 0, 0.3, 0)
Info.Size = UDim2.new(1, 0, 0.7, 0)
Info.BackgroundTransparency = 1
Info.TextColor3 = Color3.fromRGB(255, 255, 255)
Info.Font = Enum.Font.Gotham
Info.TextSize = 14
Info.TextWrapped = true
Info.Text = "Waiting..."

-- Item tracking
local ItemFolder = Workspace:WaitForChild("Item_Spawns"):WaitForChild("Items")
local trackedItems = {}

local function trackItem(itemModel)
    if not itemModel:IsA("Model") or not itemModel.PrimaryPart then return end
    local prompt = itemModel:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt and prompt.ObjectText then
        table.insert(trackedItems, {
            name = prompt.ObjectText,
            position = itemModel.PrimaryPart.Position,
            prompt = prompt,
            model = itemModel
        })
    end
end

for _, child in pairs(ItemFolder:GetChildren()) do
    trackItem(child)
end

ItemFolder.ChildAdded:Connect(function(child)
    task.wait(0.5)
    pcall(function() trackItem(child) end)
end)

-- Startup
pcall(function() Player:WaitForChild("PlayerGui"):WaitForChild("LoadingScreen1"):Destroy() end)
pcall(function() Player.PlayerGui:WaitForChild("LoadingScreen"):Destroy() end)
pcall(function() Workspace:FindFirstChild("LoadingScreen").Song:Destroy() end)

repeat task.wait() until Character():FindFirstChild("RemoteEvent")
Character().RemoteEvent:FireServer("PressedPlay")
HRP().CFrame = ReturnSpot
task.wait(2)

-- Serverhop logic
task.spawn(function()
    while true do
        task.wait(ServerHopTimer)
        local servers = game.HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
        for _, server in pairs(servers.data) do
            if server.playing < server.maxPlayers then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, Player)
                return
            end
        end
    end
end)

-- Item farming
task.spawn(function()
    while true do
        for i = #trackedItems, 1, -1 do
            local item = trackedItems[i]
            if item.prompt and item.prompt.Parent and not hasMax(item.name) then
                toggleNoclip(true)
                local underItem = CFrame.new(item.position.X, item.position.Y - 2.2, item.position.Z)
                HRP().CFrame = underItem
                Info.Text = "Teleporting to: " .. item.name

                task.wait(0.35)
                pcall(function() fireproximityprompt(item.prompt) end)
                task.wait(0.3)
                HRP().CFrame = ReturnSpot
                Info.Text = "Picked: " .. item.name
                toggleNoclip(false)
            end
            table.remove(trackedItems, i)
        end
        Info.Text = "Waiting..."
        task.wait(2)
    end
end)

-- AutoSell
task.spawn(function()
    while true do
        for item, sell in pairs(SellItems) do
            local tool = Player.Backpack:FindFirstChild(item)
            if sell and tool then
                equipTool(item)
                Character().RemoteEvent:FireServer("EndDialogue", {
                    NPC = "Merchant",
                    Dialogue = "Dialogue5",
                    Option = "Option2"
                })
                task.wait(0.2)
            end
        end
        task.wait(5)
    end
end)

-- Lucky Arrow Buy
if BuyLucky then
    local money = Player:WaitForChild("PlayerStats"):WaitForChild("Money")
    money:GetPropertyChangedSignal("Value"):Connect(function()
        Info.Text = "Money: " .. tostring(math.floor(money.Value))
    end)
    task.spawn(function()
        while true do
            if money.Value >= 50000 then
                Character().RemoteEvent:FireServer("PurchaseShopItem", {
                    ItemName = "1x Lucky Arrow"
                })
                task.wait(0.3)
            else
                task.wait(5)
            end
        end
    end)
end
