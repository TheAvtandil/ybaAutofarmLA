-- PigletHUB Autofarm for Your Bizarre Adventure (YBA)
-- By: You 🐷

-- Services
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")
local Player = Players.LocalPlayer
local Character = function() return Player.Character or Player.CharacterAdded:Wait() end
local HRP = function() return Character():WaitForChild("HumanoidRootPart") end
local PlayerStats = Player:WaitForChild("PlayerStats")

-- GUI Setup
local function createGUI()
    if Player:FindFirstChild("PlayerGui"):FindFirstChild("PigletHUB") then
        Player.PlayerGui.PigletHUB:Destroy()
    end

    local gui = Instance.new("ScreenGui", Player.PlayerGui)
    gui.Name = "PigletHUB"
    gui.ResetOnSpawn = false

    local frame = Instance.new("Frame", gui)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.Size = UDim2.new(0, 250, 0, 100)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BorderSizePixel = 0
    frame.BackgroundTransparency = 0.2
    frame.Name = "Main"

    local title = Instance.new("TextLabel", frame)
    title.Text = "PigletHUB"
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 20
    title.TextColor3 = Color3.new(1, 1, 1)
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 20)

    local itemText = Instance.new("TextLabel", frame)
    itemText.Text = "Item: None"
    itemText.Name = "Item"
    itemText.TextSize = 16
    itemText.Font = Enum.Font.SourceSans
    itemText.TextColor3 = Color3.fromRGB(255, 255, 255)
    itemText.Position = UDim2.new(0, 0, 0, 30)
    itemText.Size = UDim2.new(1, 0, 0, 20)
    itemText.BackgroundTransparency = 1

    local moneyText = Instance.new("TextLabel", frame)
    moneyText.Text = "Money: ..."
    moneyText.Name = "Money"
    moneyText.TextSize = 16
    moneyText.Font = Enum.Font.SourceSans
    moneyText.TextColor3 = Color3.fromRGB(255, 255, 0)
    moneyText.Position = UDim2.new(0, 0, 0, 55)
    moneyText.Size = UDim2.new(1, 0, 0, 20)
    moneyText.BackgroundTransparency = 1
end

createGUI()
Player.CharacterAdded:Connect(createGUI)

-- Config
local ReturnSpot = CFrame.new(978, -42, -49)
local serverHopTime = 105
-- Added more downward offset to hide character better
local teleportOffset = Vector3.new(0, -5, 0) 
local BuyLucky = true
local AutoSell = true

-- Inventory caps
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
local has2x = false
pcall(function()
    has2x = MarketplaceService:UserOwnsGamePassAsync(Player.UserId, 14597778)
end)
if has2x then for k, v in pairs(ItemCaps) do ItemCaps[k] = v * 2 end end

-- Helpers
local function toggleNoclip(state)
    for _, p in pairs(Character():GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = not state end
    end
end

local function hasMax(item)
    local count = 0
    for _, tool in pairs(Player.Backpack:GetChildren()) do
        if tool.Name == item then count = count + 1 end
    end
    return (ItemCaps[item] or 9999) <= count
end

-- Update GUI
local function updateGUI(item)
    local gui = Player.PlayerGui:FindFirstChild("PigletHUB")
    if gui then
        gui.Main.Item.Text = "Item: " .. (item or "None")
        local cash = math.floor(PlayerStats.Money.Value)
        gui.Main.Money.Text = "Money: $" .. tostring(cash)
    end
end

-- Item tracker
local ItemFolder = Workspace:WaitForChild("Item_Spawns"):WaitForChild("Items")
local trackedItems = {}

local function trackItem(itemModel)
    if not itemModel:IsA("Model") then return end
    
    -- Try to find the main part (Handle or PrimaryPart)
    local mainPart = itemModel:FindFirstChild("Handle") or itemModel.PrimaryPart
    if not mainPart then return end
    
    local prompt = itemModel:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt and prompt.ObjectText then
        table.insert(trackedItems, {
            name = prompt.ObjectText,
            position = mainPart.Position,
            prompt = prompt,
            model = itemModel
        })
    end
end

-- Scan existing items
for _, child in pairs(ItemFolder:GetChildren()) do
    pcall(function() trackItem(child) end)
end

-- Track new items
ItemFolder.ChildAdded:Connect(function(child)
    task.wait(0.2)
    pcall(function() trackItem(child) end)
end)

-- Press play
repeat task.wait() until Character():FindFirstChild("RemoteEvent")
Character().RemoteEvent:FireServer("PressedPlay")
HRP().CFrame = ReturnSpot
task.wait(2)

-- Server hop function
local function serverHop()
    local servers = {}
    local req = game:HttpGet("https://games.roblox.com/v1/games/2809202155/servers/Public?sortOrder=Asc&limit=100")
    local data = game:GetService("HttpService"):JSONDecode(req)
    for _, s in pairs(data.data) do
        if s.playing < s.maxPlayers then
            table.insert(servers, s.id)
        end
    end
    if #servers > 0 then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], Player)
    else
        -- If no servers found, try again after delay
        task.wait(10)
        serverHop()
    end
end

-- Serverhop countdown
task.spawn(function()
    while true do
        task.wait(serverHopTime)
        serverHop()
    end
end)

-- Fast Auto Sell function
local function performQuickSell()
    if not AutoSell then return end
    
    -- Group items to sell by type for faster processing
    local itemsToSell = {}
    for item, sell in pairs(SellItems) do
        if sell then
            for _, tool in pairs(Player.Backpack:GetChildren()) do
                if tool.Name == item then
                    table.insert(itemsToSell, tool)
                end
            end
        end
    end
    
    -- Batch sell items more efficiently
    if #itemsToSell > 0 then
        pcall(function()
            -- Equip first item
            Character().Humanoid:EquipTool(itemsToSell[1])
            task.wait(0.1)
            
            -- Send sell request for all items of this type
            Character().RemoteEvent:FireServer("EndDialogue", {
                NPC = "Merchant",
                Dialogue = "Dialogue5",
                Option = "Option2"
            })
            
            task.wait(0.2)
        end)
    end
end

-- Improved item pickup function
local function pickupItem(item)
    toggleNoclip(true)
    
    -- Position character under the item to be stealthy
    local tpPosition = CFrame.new(item.position + teleportOffset)
    HRP().CFrame = tpPosition
    updateGUI(item.name)
    
    -- Wait for character to settle
    task.wait(0.2)
    
    -- Press E key to activate proximity prompt
    -- Use fireproximityprompt with proper parameters
    pcall(function() 
        if item.prompt and item.prompt.Parent then
            fireproximityprompt(item.prompt, 1) -- The second parameter makes it activate immediately
        end
    end)
    
    -- Wait for pickup to register
    task.wait(0.2)
    
    -- Return to safe spot
    HRP().CFrame = ReturnSpot
    toggleNoclip(false)
end

-- Farming loop
while true do
    -- Check if character is available before proceeding
    if not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") then
        task.wait(1)
        continue
    end
    
    -- Process tracked items
    local itemsProcessed = 0
    for i = #trackedItems, 1, -1 do
        local item = trackedItems[i]
        if not item.prompt or not item.prompt.Parent then
            table.remove(trackedItems, i)
            continue
        end
        
        if not hasMax(item.name) then
            if (HRP().Position - item.position).Magnitude > 75 then -- max safe pickup distance
                pickupItem(item)
                itemsProcessed = itemsProcessed + 1
                
                -- Only process a few items at a time to keep script responsive
                if itemsProcessed >= 3 then
                    break
                end
            end
        end
        table.remove(trackedItems, i)
    end

    -- Fast auto sell (perform every cycle)
    performQuickSell()

    -- Buy Lucky Arrows
    if BuyLucky and PlayerStats.Money.Value >= 50000 then
        pcall(function()
            Character().RemoteEvent:FireServer("PurchaseShopItem", {ItemName = "1x Lucky Arrow"})
        end)
    end

    updateGUI(nil)
    
    -- Use shorter wait time for more responsive farming
    task.wait(1.5)
end
