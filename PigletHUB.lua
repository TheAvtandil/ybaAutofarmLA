--// Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")
local Player = Players.LocalPlayer

local Character = function() return Player.Character or Player.CharacterAdded:Wait() end
local HRP = function() return Character():WaitForChild("HumanoidRootPart") end

--// Settings
local BuyLucky = true
local AutoSell = true
local ReturnSpot = CFrame.new(978, -42, -49)
local GamePlaceId = 2809202155
local ServerHopDelay = 105
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

--// 2x Gamepass Boost
local has2x = false
pcall(function()
    has2x = MarketplaceService:UserOwnsGamePassAsync(Player.UserId, 14597778)
end)
if has2x then for k, v in pairs(ItemCaps) do ItemCaps[k] = v * 2 end end

--// Anti-Detection
local KeyBypass = "  ___XP DE KEY"
hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local args = {...}
    if not checkcaller() and self.Name == "Returner" and args[1] == "idklolbrah2de" then
        return KeyBypass
    end
    return getrawmetatable(game).__namecall(self, ...)
end))

--// Auto Rejoin
game.CoreGui:FindFirstChild("RobloxPromptGui").PromptOverlay.ChildAdded:Connect(function(child)
    if child.Name:find("Kick") then
        task.wait(2)
        TeleportService:Teleport(GamePlaceId)
    end
end)

--// GUI Setup
local gui = Instance.new("ScreenGui", Player:WaitForChild("PlayerGui"))
gui.Name = "PigletHUB"
local frame = Instance.new("Frame", gui)
frame.BackgroundTransparency = 0.3
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Position = UDim2.new(1, -220, 0, 10)
frame.Size = UDim2.new(0, 200, 0, 70)
frame.BorderSizePixel = 0
frame.Visible = true
frame.AnchorPoint = Vector2.new(1, 0)
frame.Active = true
frame.Draggable = true

local itemLabel = Instance.new("TextLabel", frame)
itemLabel.Size = UDim2.new(1, 0, 0.5, 0)
itemLabel.Position = UDim2.new(0, 0, 0, 0)
itemLabel.BackgroundTransparency = 1
itemLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
itemLabel.TextScaled = true
itemLabel.Font = Enum.Font.Gotham
itemLabel.Text = "Item: None"

local moneyLabel = Instance.new("TextLabel", frame)
moneyLabel.Size = UDim2.new(1, 0, 0.5, 0)
moneyLabel.Position = UDim2.new(0, 0, 0.5, 0)
moneyLabel.BackgroundTransparency = 1
moneyLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
moneyLabel.TextScaled = true
moneyLabel.Font = Enum.Font.Gotham
moneyLabel.Text = "Money: ..."

--// Functions
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

local function getSafeCFrame(itemPos)
    local rayOrigin = itemPos
    local rayDirection = Vector3.new(0, -10, 0)
    local result = Workspace:Raycast(rayOrigin, rayDirection)

    local offsetY
    if result then
        local distanceFromGround = itemPos.Y - result.Position.Y
        offsetY = math.clamp(distanceFromGround - 0.5, 3.5, 5.5)
    else
        offsetY = 3.5
    end

    return CFrame.new(itemPos.X, itemPos.Y - offsetY, itemPos.Z)
end

--// Item Detection
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

ItemFolder.ChildAdded:Connect(function(child)
    task.wait(0.5)
    pcall(function() trackItem(child) end)
end)

--// Clean UI Clutter
pcall(function() Player:WaitForChild("PlayerGui"):WaitForChild("LoadingScreen1"):Destroy() end)
pcall(function() Player.PlayerGui:WaitForChild("LoadingScreen"):Destroy() end)
pcall(function() Workspace:FindFirstChild("LoadingScreen").Song:Destroy() end)

--// Play
repeat task.wait() until Character():FindFirstChild("RemoteEvent")
Character().RemoteEvent:FireServer("PressedPlay")
HRP().CFrame = ReturnSpot
task.wait(2)

--// Serverhop Timer
task.spawn(function()
    while task.wait(ServerHopDelay) do
        TeleportService:Teleport(GamePlaceId)
    end
end)

--// Item Farming Loop
task.spawn(function()
    while true do
        moneyLabel.Text = "Money: " .. tostring(Player:WaitForChild("PlayerStats").Money.Value)
        for i = #trackedItems, 1, -1 do
            local item = trackedItems[i]
            if item.prompt and item.prompt.Parent and not hasMax(item.name) then
                toggleNoclip(true)
                HRP().CFrame = getSafeCFrame(item.position)
                task.wait(0.25)
                pcall(function() fireproximityprompt(item.prompt) end)
                task.wait(0.15)
                HRP().CFrame = ReturnSpot
                toggleNoclip(false)
                itemLabel.Text = "Item: " .. item.name
            end
            table.remove(trackedItems, i)
        end
        task.wait(2)
    end
end)

--// Auto Sell
task.spawn(function()
    if AutoSell then
        while task.wait(5) do
            for item, sell in pairs(SellItems) do
                local tool = Player.Backpack:FindFirstChild(item)
                if sell and tool then
                    Character().Humanoid:EquipTool(tool)
                    Character().RemoteEvent:FireServer("EndDialogue", {
                        NPC = "Merchant",
                        Dialogue = "Dialogue5",
                        Option = "Option2"
                    })
                    task.wait(0.3)
                end
            end
        end
    end
end)

--// Buy Lucky Arrow
task.spawn(function()
    if BuyLucky then
        local money = Player:WaitForChild("PlayerStats"):WaitForChild("Money")
        while task.wait(5) do
            if money.Value >= 50000 then
                Character().RemoteEvent:FireServer("PurchaseShopItem", {
                    ItemName = "1x Lucky Arrow"
                })
                task.wait(0.3)
            end
        end
    end
end)
