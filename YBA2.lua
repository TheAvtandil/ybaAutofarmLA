if game.PlaceId ~= 2809202155 then return end

-- CONFIG
local SELL_BLACKLIST = {
    ["Lucky Arrow"] = true,
    ["DIO's Diary"] = false,
    ["Rokakaka"] = false, -- sell this if you want
    ["Mysterious Arrow"] = false,
}
local TELEPORT_DELAY = 1.4
local RETURN_POSITION = CFrame.new(-334, 12, 425) -- Hidden safe spot
local SERVERHOP_INTERVAL = 105

-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Backpack = LocalPlayer:WaitForChild("Backpack")

-- GUI
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "PigletHUB"

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 300, 0, 200)
Frame.Position = UDim2.new(0, 10, 0, 10)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.BackgroundTransparency = 0.2
Frame.BorderSizePixel = 0
Frame.ClipsDescendants = true

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 25)
Title.Text = "PigletHUB Item Log"
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16

local ScrollingFrame = Instance.new("ScrollingFrame", Frame)
ScrollingFrame.Position = UDim2.new(0, 0, 0, 25)
ScrollingFrame.Size = UDim2.new(1, 0, 1, -25)
ScrollingFrame.CanvasSize = UDim2.new(0, 0, 10, 0)
ScrollingFrame.ScrollBarThickness = 4
ScrollingFrame.BackgroundTransparency = 1

local function logItem(msg)
    local label = Instance.new("TextLabel", ScrollingFrame)
    label.Size = UDim2.new(1, -10, 0, 20)
    label.Position = UDim2.new(0, 5, 0, #ScrollingFrame:GetChildren() * 20)
    label.Text = msg
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.BackgroundTransparency = 1
    ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, #ScrollingFrame:GetChildren() * 20)
end

-- TELEPORT
local function safeTP(cf)
    local HumanoidRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if HumanoidRootPart then
        HumanoidRootPart.CFrame = cf
    end
end

-- ITEM DETECTION
local function getItems()
    local items = {}
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Part") and v.Name == "TouchInterest" and v.Parent and v.Parent:FindFirstChild("ClickDetector") then
            table.insert(items, v.Parent)
        end
    end
    return items
end

-- ITEM PICKUP
local function pickup(item)
    local cf = item.CFrame * CFrame.new(0, -3, 0)
    safeTP(cf)
    task.wait(TELEPORT_DELAY)
    fireclickdetector(item:FindFirstChild("ClickDetector"))
    logItem("Picked up: " .. item.Name)
    task.wait(0.4)
    safeTP(RETURN_POSITION)
end

-- AUTO SELL
Backpack.ChildAdded:Connect(function(child)
    task.wait(0.5)
    if not SELL_BLACKLIST[child.Name] then
        local sellRemote = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes", true):FindFirstChild("SellItem")
        if sellRemote then
            sellRemote:FireServer(child.Name)
            logItem("Sold: " .. child.Name)
        end
    else
        logItem("Kept: " .. child.Name)
    end
end)

-- SERVER HOP
task.spawn(function()
    while task.wait(SERVERHOP_INTERVAL) do
        local servers = {}
        local req = request({
            Url = "https://games.roblox.com/v1/games/2809202155/servers/Public?sortOrder=Asc&limit=100",
        })
        local body = HttpService:JSONDecode(req.Body)
        for _, server in pairs(body.data) do
            if server.playing < server.maxPlayers then
                table.insert(servers, server.id)
            end
        end
        if #servers > 0 then
            TeleportService:TeleportToPlaceInstance(2809202155, servers[math.random(1, #servers)], LocalPlayer)
        end
    end
end)

-- FARM LOOP
task.spawn(function()
    while task.wait(1.5) do
        local found = getItems()
        for _, item in ipairs(found) do
            if item:FindFirstChild("ClickDetector") then
                pickup(item)
                task.wait(0.5)
            end
        end
    end
end)

-- ANTI-KICK
local oldKick
oldKick = hookfunction(LocalPlayer.Kick, function(...) return end)
