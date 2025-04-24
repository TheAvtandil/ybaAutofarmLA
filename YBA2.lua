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
-- ... [unchanged GUI setup code] ...

-- Rejoin after kick
-- ... [unchanged rejoin code] ...

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

-- Smooth teleport that avoids anti-cheat
local function safeTeleportTo(pos)
    local start = HRP().Position
    local finish = pos + teleportOffset
    local direction = (finish - start).Unit
    local distance = (finish - start).Magnitude
    local steps = math.ceil(distance / teleportStepDistance)

    for i = 1, steps do
        local stepPos = start + direction * teleportStepDistance * i
        if (stepPos - finish).Magnitude < teleportStepDistance then stepPos = finish end
        HRP().CFrame = CFrame.new(stepPos)
        task.wait(teleportStepTime)
    end
    updateGUI("Teleporting...", "")
    return true
end

local function toggleNoclip(state)
    for _, p in pairs(Character():GetDescendants()) do
        if p:IsA("BasePart") then
            p.CanCollide = not state
        end
    end
end

-- Track Items
-- ... [unchanged tracking code] ...

-- Sell Setup
-- ... [unchanged SellItems and Backpack logic] ...

-- Item Collection Loop
while true do
    for i = #trackedItems, 1, -1 do
        local item = trackedItems[i]
        table.remove(trackedItems, i)
        if item.prompt and item.prompt.Parent then
            toggleNoclip(true)
            updateGUI("Teleporting to " .. item.name, "")
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
-- ... [unchanged server hop code] ...
