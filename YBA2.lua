if game.PlaceId ~= 2809202155 then return end

-- Prevent multiple executions
if getgenv().PigletHUBLoaded then return end
getgenv().PigletHUBLoaded = true

-- Services
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- UI
local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "PigletHUB"
gui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", gui)
mainFrame.Size = UDim2.new(0, 300, 0, 400)
mainFrame.Position = UDim2.new(0, 10, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 0

local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
title.Text = "PigletHUB"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 20

local scroll = Instance.new("ScrollingFrame", mainFrame)
scroll.Position = UDim2.new(0, 0, 0, 30)
scroll.Size = UDim2.new(1, 0, 1, -30)
scroll.CanvasSize = UDim2.new(0, 0, 10, 0)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 4

local layout = Instance.new("UIListLayout", scroll)
layout.SortOrder = Enum.SortOrder.LayoutOrder

local function log(text)
    local label = Instance.new("TextLabel", scroll)
    label.Text = "[" .. os.date("%X") .. "] " .. text
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.Code
    label.TextSize = 14
    label.Size = UDim2.new(1, -10, 0, 20)
    label.BackgroundTransparency = 1
end

-- Item detection + pickup
local function teleportUnder(position)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local root = char.HumanoidRootPart
        root.CFrame = CFrame.new(position.X, position.Y - 4, position.Z)
        task.wait(1.4)
    end
end

local function pressE()
    local virtualInput = game:GetService("VirtualInputManager")
    virtualInput:SendKeyEvent(true, "E", false, game)
    task.wait(0.1)
    virtualInput:SendKeyEvent(false, "E", false, game)
end

local function findItems()
    local items = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Part") and obj.Name == "ItemSpawn" and obj:FindFirstChild("TouchInterest") then
            table.insert(items, obj)
        end
    end
    return items
end

-- Auto sell logic
local function onInventoryChange()
    local inv = LocalPlayer:WaitForChild("Backpack"):GetChildren()
    for _, item in ipairs(inv) do
        if item:IsA("Tool") then
            log("Auto-selling: " .. item.Name)
            ReplicatedStorage.Remotes.SellItem:FireServer(item.Name)
            task.wait(0.1)
        end
    end
end

LocalPlayer.Backpack.ChildAdded:Connect(onInventoryChange)

-- Safe spot
local safeSpot = CFrame.new(0, -300, 0)

-- Anti-kick and respawn handling
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(2)
    LocalPlayer.Character:MoveTo(safeSpot.Position)
end)

-- Main farming loop
task.spawn(function()
    while task.wait(1) do
        local items = findItems()
        for _, item in ipairs(items) do
            pcall(function()
                teleportUnder(item.Position)
                pressE()
                log("Attempted to pickup: " .. item.Name)
                task.wait(0.5)
                LocalPlayer.Character.HumanoidRootPart.CFrame = safeSpot
                task.wait(0.5)
            end)
        end
    end
end)

-- Server hopping
task.spawn(function()
    while true do
        task.wait(105)
        local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
        for _, server in ipairs(servers.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id)
                break
            end
        end
    end
end)

-- Auto rejoin if kicked
game:GetService("Players").PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        TeleportService:Teleport(game.PlaceId)
    end
end)

log("PigletHUB loaded and running.")
