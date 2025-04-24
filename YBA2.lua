-- PigletHUB Autofarm for Your Bizarre Adventure (YBA)
-- By: You 🐷

-- Services
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
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
    frame.Size = UDim2.new(0, 250, 0, 120)
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

    -- Add status indicator
    local statusText = Instance.new("TextLabel", frame)
    statusText.Text = "Status: Idle"
    statusText.Name = "Status"
    statusText.TextSize = 16
    statusText.Font = Enum.Font.SourceSans
    statusText.TextColor3 = Color3.fromRGB(0, 255, 0)
    statusText.Position = UDim2.new(0, 0, 0, 80)
    statusText.Size = UDim2.new(1, 0, 0, 20)
    statusText.BackgroundTransparency = 1
    
    -- Add debug indicator
    local debugText = Instance.new("TextLabel", frame)
    debugText.Text = "Debug: None"
    debugText.Name = "Debug"
    debugText.TextSize = 14
    debugText.Font = Enum.Font.SourceSans
    debugText.TextColor3 = Color3.fromRGB(200, 200, 200)
    debugText.Position = UDim2.new(0, 0, 0, 105)
    debugText.Size = UDim2.new(1, 0, 0, 15)
    debugText.BackgroundTransparency = 1
end

createGUI()
Player.CharacterAdded:Connect(createGUI)

-- Config
local ReturnSpot = CFrame.new(978, -42, -49)
local serverHopTime = 105
-- Position for hiding under items
local teleportOffset = Vector3.new(0, -6, 0)
local BuyLucky = true
local AutoSell = true
-- Anti-kick delays
local delayBetweenTeleports = 1.5     -- Time between teleports
local firstPickupDelay = 3            -- Extra time for first pickup
local itemPickupTime = 2.0            -- Time to wait under item for pickup (increased for E hold)
local pickupHoldTime = 1.2            -- Time to hold E key
local betweenItemDelay = 2            -- Wait time between item pickups
local isFirstPickup = true            -- Track first pickup
local maxServerHopAttempts = 5        -- Maximum server hop attempts before restarting

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
local function updateGUI(item, status, debug)
    local gui = Player.PlayerGui:FindFirstChild("PigletHUB")
    if gui then
        if item then gui.Main.Item.Text = "Item: " .. item end
        if status then gui.Main.Status.Text = "Status: " .. status end
        if debug then gui.Main.Debug.Text = "Debug: " .. debug end
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
    local mainPart = itemModel:FindFirstChild("Handle") or (itemModel.PrimaryPart or nil)
    if not mainPart then 
        -- Try to find any BasePart if Handle/PrimaryPart not available
        for _, part in pairs(itemModel:GetChildren()) do
            if part:IsA("BasePart") then
                mainPart = part
                break
            end
        end
        if not mainPart then return end
    end
    
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

-- Hold E key function (simulates press and hold)
local function holdEKey(duration)
    -- Press E
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    -- Wait for the specified duration
    task.wait(duration)
    -- Release E
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

-- Press play
repeat task.wait() until Character():FindFirstChild("RemoteEvent")
Character().RemoteEvent:FireServer("PressedPlay")
HRP().CFrame = ReturnSpot
task.wait(2)

-- Server hop function with retry mechanism
local hopAttempts = 0
local serverHopInProgress = false

local function serverHop()
    if serverHopInProgress then return end
    serverHopInProgress = true
    
    hopAttempts = hopAttempts + 1
    if hopAttempts > maxServerHopAttempts then
        updateGUI(nil, "Server Hop Failed", "Restarting script...")
        task.wait(2)
        -- Force script restart by causing an error
        error("Restarting script due to failed server hops")
        return
    end
    
    updateGUI(nil, "Server Hopping...", "Attempt " .. hopAttempts)
    
    local success, errorMsg = pcall(function()
        local servers = {}
        local endpoint = "https://games.roblox.com/v1/games/2809202155/servers/Public?sortOrder=Asc&limit=100"
        local data = HttpService:JSONDecode(game:HttpGet(endpoint))
        
        for _, s in pairs(data.data) do
            if s.playing < s.maxPlayers and s.playing > 1 and s.id ~= game.JobId then
                table.insert(servers, s.id)
            end
        end
        
        if #servers > 0 then
            -- Select a random server from the list
            local chosenServer = servers[math.random(1, #servers)]
            updateGUI(nil, "Server Found", "Teleporting to " .. chosenServer)
            
            -- Force GC collection before teleport
            for i = 1, 5 do
                game:GetService("Debris"):AddItem(Instance.new("Frame"), 0)
                task.wait(0.1)
            end
            
            -- Attempt teleport with timeout
            local teleportSuccess = false
            spawn(function()
                teleportSuccess = pcall(function()
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, chosenServer, Player)
                end)
            end)
            
            -- Wait for teleport or timeout
            local startTime = tick()
            while tick() - startTime < 15 and not teleportSuccess do
                task.wait(1)
                updateGUI(nil, "Teleporting...", "Wait: " .. math.floor(tick() - startTime))
            end
            
            if not teleportSuccess then
                error("Teleport timed out")
            end
        else
            error("No suitable servers found")
        end
    end)
    
    if not success then
        updateGUI(nil, "Teleport Failed", errorMsg)
        task.wait(5)
        serverHopInProgress = false
        serverHop() -- Try again
    end
end

-- Serverhop countdown
task.spawn(function()
    while true do
        for i = serverHopTime, 1, -1 do
            if not serverHopInProgress then
                updateGUI(nil, "Farm: " .. i .. "s till hop")
            end
            task.wait(1)
        end
        serverHop()
    end
end)

-- Enhanced pickup function with HOLD E implementation
local function pickupItem(item)
    -- Wait longer for the first pickup to avoid instant teleport kicks
    if isFirstPickup then
        updateGUI(item.name, "First pickup delay...", "Preventing kick")
        task.wait(firstPickupDelay)
        isFirstPickup = false
    else
        -- Normal delay between teleports
        updateGUI(item.name, "Item cooldown...", "Anti-kick delay")
        task.wait(delayBetweenTeleports)
    end
    
    -- Keep track of current inventory to verify pickup later
    local beforeCount = 0
    pcall(function()
        for _, tool in pairs(Player.Backpack:GetChildren()) do
            if tool.Name == item.name then
                beforeCount = beforeCount + 1
            end
        end
    end)
    
    updateGUI(item.name, "Collecting...", "Moving to item")
    toggleNoclip(true)
    
    -- Position character safely under the item
    local tpPosition = CFrame.new(item.position + teleportOffset)
    
    -- Use a safer teleport approach
    pcall(function()
        Character():SetPrimaryPartCFrame(tpPosition)
    end)
    
    -- Make sure we're actually there
    task.wait(0.5)
    
    -- If we're not close enough, try direct teleport
    if (HRP().Position - (item.position + teleportOffset)).Magnitude > 10 then
        HRP().CFrame = tpPosition
        task.wait(0.3)
    end
    
    -- Stay under the item and attempt pickup
    updateGUI(item.name, "Holding E...", "Holding for " .. pickupHoldTime .. "s")
    
    -- Simulate holding E key (long press)
    holdEKey(pickupHoldTime)
    
    -- Additional wait for pickup registration
    task.wait(itemPickupTime - pickupHoldTime)
    
    -- Verify pickup worked by checking inventory
    local afterCount = 0
    pcall(function()
        for _, tool in pairs(Player.Backpack:GetChildren()) do
            if tool.Name == item.name then
                afterCount = afterCount + 1
            end
        end
    end)
    
    local pickupWorked = (afterCount > beforeCount)
    updateGUI(item.name, "Pickup " .. (pickupWorked and "Success!" or "Failed!"))
    
    -- Try again if pickup failed
    if not pickupWorked and item.prompt and item.prompt.Parent then
        updateGUI(item.name, "Retrying pickup...", "Second attempt")
        holdEKey(pickupHoldTime)
        task.wait(0.3)
    end
    
    -- Return to safe spot more slowly
    updateGUI(item.name, "Returning...", "Going to safe spot")
    task.wait(0.2)
    
    pcall(function()
        Character():SetPrimaryPartCFrame(ReturnSpot)
    end)
    
    -- Backup teleport if the above fails
    if (HRP().Position - ReturnSpot.Position).Magnitude > 10 then
        HRP().CFrame = ReturnSpot
    end
    
    toggleNoclip(false)
    
    -- Wait between item pickups to avoid detection
    task.wait(betweenItemDelay)
    updateGUI(nil, "Idle", "Ready for next action")
end

-- Immediate item equip and sell function
local function equipAndSellItem(tool)
    if not tool or not Character():FindFirstChild("Humanoid") then return false end
    
    -- Equip the item
    Character().Humanoid:EquipTool(tool)
    
    -- Wait for equip to complete
    local equipStartTime = tick()
    while not Character():FindFirstChild(tool.Name) and tick() - equipStartTime < 1 do
        task.wait(0.1)
    end
    
    -- If equipped successfully, sell it
    if Character():FindFirstChild(tool.Name) then
        Character().RemoteEvent:FireServer("EndDialogue", {
            NPC = "Merchant",
            Dialogue = "Dialogue5",
            Option = "Option2"
        })
        task.wait(0.35) -- Wait for sell to complete
        return true
    end
    
    return false
end

-- Fast Auto Sell function (revised)
local function performQuickSell()
    if not AutoSell then return end
    
    updateGUI(nil, "Selling items...", "Starting sell process")
    
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
    
    local successCount = 0
    
    -- Process each item individually
    for i, tool in ipairs(itemsToSell) do
        updateGUI(nil, "Selling " .. tool.Name, i .. "/" .. #itemsToSell)
        if equipAndSellItem(tool) then
            successCount = successCount + 1
        end
    end
    
    updateGUI(nil, "Sold " .. successCount .. " items", "Complete")
    task.wait(0.5)
end

-- Farming loop
while true do
    -- Check if character is available before proceeding
    if not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") then
        task.wait(1)
        updateGUI(nil, "Waiting for character...", "No character found")
        continue
    end
    
    -- Process tracked items
    local itemsProcessed = 0
    local validItems = {}
    
    -- First, filter out invalid items and sort by priority
    for i = #trackedItems, 1, -1 do
        local item = trackedItems[i]
        if not item.prompt or not item.prompt.Parent then
            table.remove(trackedItems, i)
        elseif not hasMax(item.name) then
            table.insert(validItems, item)
            table.remove(trackedItems, i)
        end
    end
    
    -- Only process one item per cycle to avoid kicks
    if #validItems > 0 then
        pickupItem(validItems[1])
        itemsProcessed = 1
    end
    
    -- Only sell if we aren't currently picking up items
    if itemsProcessed == 0 then
        -- Sell items
        performQuickSell()
        
        -- Buy Lucky Arrows
        if BuyLucky and PlayerStats.Money.Value >= 50000 then
            updateGUI(nil, "Buying Lucky Arrow...", "Money: " .. PlayerStats.Money.Value)
            pcall(function()
                Character().RemoteEvent:FireServer("PurchaseShopItem", {ItemName = "1x Lucky Arrow"})
            end)
            task.wait(0.3)
        end
        
        -- If nothing to do, wait longer
        if #trackedItems == 0 then
            updateGUI(nil, "Searching for items...", "No items found: " .. #trackedItems)
            task.wait(3)
        end
    end
    
    -- Short wait between cycles
    task.wait(0.5)
end
