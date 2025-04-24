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
local teleportStepTime = 0.07 -- slows down teleport in steps
local teleportStepDistance = 25 -- max studs per step

-- GUI Setup
local function createGUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "PigletHUB"
    gui.ResetOnSpawn = false
    gui.Parent = Player:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame", gui)
    frame.Name = "Main"
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.Size = UDim2.new(0, 250, 0, 150)
    frame.BackgroundTransparency = 0.2

    local title = Instance.new("TextLabel", frame)
    title.Text = "PigletHUB"
    title.Font = Enum.Font.SourceSansBold
    title.Size = UDim2.new(1, 0, 0, 20)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.new(1, 1, 1)

    local log = Instance.new("TextLabel", frame)
    log.Name = "ItemLog"
    log.Text = "Item Log:\n"
    log.Position = UDim2.new(0, 0, 0, 25)
    log.Size = UDim2.new(1, 0, 0, 80)
    log.TextWrapped = true
    log.TextYAlignment = Enum.TextYAlignment.Top
    log.Font = Enum.Font.SourceSans
    log.TextSize = 14
    log.BackgroundTransparency = 1
    log.TextColor3 = Color3.fromRGB(200, 200, 200)

    local money = Instance.new("TextLabel", frame)
    money.Name = "Money"
    money.Position = UDim2.new(0, 0, 0, 110)
    money.Size = UDim2.new(1, 0, 0, 20)
    money.Text = "Money: ..."
    money.Font = Enum.Font.SourceSans
    money.TextSize = 14
    money.BackgroundTransparency = 1
    money.TextColor3 = Color3.fromRGB(255, 255, 0)

    local status = Instance.new("TextLabel", frame)
    status.Name = "Status"
    status.Position = UDim2.new(0, 0, 0, 130)
    status.Size = UDim2.new(1, 0, 0, 20)
    status.Text = "Status: Idle"
    status.Font = Enum.Font.SourceSans
    status.TextSize = 14
    status.BackgroundTransparency = 1
    status.TextColor3 = Color3.fromRGB(0, 255, 0)
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

-- Track Items
local trackedItems = {}
local ItemFolder = Workspace:WaitForChild("Item_Spawns"):WaitForChild("Items")
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

for _, item in pairs(ItemFolder:GetDescendants()) do
    if item:IsA("Model") then pcall(function() trackItem(item) end) end
end
ItemFolder.DescendantAdded:Connect(function(item)
    if item:IsA("Model") then task.wait(0.5) pcall(function() trackItem(item) end) end
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
