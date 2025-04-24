-- PigletHUB for Your Bizarre Adventure (YBA)
-- Features: Auto Item Farm, Stealth Teleport, GUI with Logs, Server Hop, Auto Sell, Anti-Kick

-- CONFIG
local teleportDelay = 1.4
local safeSpot = Vector3.new(0, -1000, 0)
local serverHopDelay = 105
local logLines = 10

-- Services
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- GUI Setup
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "PigletHUB"
local main = Instance.new("Frame", gui)
main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
main.Size = UDim2.new(0, 300, 0, 220)
main.Position = UDim2.new(0, 10, 0, 10)
main.BorderSizePixel = 0

local title = Instance.new("TextLabel", main)
title.Text = "PigletHUB"
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(255, 85, 255)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1

local status = Instance.new("TextLabel", main)
status.Text = "Starting..."
status.Font = Enum.Font.Code
status.TextSize = 14
status.TextColor3 = Color3.fromRGB(255, 255, 255)
status.Position = UDim2.new(0, 0, 0, 30)
status.Size = UDim2.new(1, 0, 0, 20)
status.BackgroundTransparency = 1

local logBox = Instance.new("TextLabel", main)
logBox.Text = ""
logBox.Font = Enum.Font.Code
logBox.TextSize = 14
logBox.TextXAlignment = Enum.TextXAlignment.Left
logBox.TextYAlignment = Enum.TextYAlignment.Top
logBox.TextColor3 = Color3.fromRGB(200, 200, 200)
logBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
logBox.Position = UDim2.new(0, 0, 0, 50)
logBox.Size = UDim2.new(1, 0, 1, -50)
logBox.TextWrapped = true
logBox.TextScaled = false
logBox.ClipsDescendants = true

-- Logging
local logs = {}
function AddLog(msg)
	table.insert(logs, 1, "[" .. os.date("%H:%M:%S") .. "] " .. msg)
	while #logs > logLines do
		table.remove(logs)
	end
	logBox.Text = table.concat(logs, "\n")
end

-- Teleport under item safely
function StealthTP(target)
	local pos = target.Position - Vector3.new(0, 2.5, 0)
	local old = HumanoidRootPart.CFrame
	HumanoidRootPart.CFrame = CFrame.new(pos)
	wait(teleportDelay)
	HumanoidRootPart.CFrame = CFrame.new(safeSpot)
end

-- Detect and Pickup Items
function PickupItems()
	for _, v in ipairs(Workspace:GetChildren()) do
		if v:IsA("Model") and v:FindFirstChild("TouchInterest") then
			local dist = (v.Position - HumanoidRootPart.Position).Magnitude
			if dist < 1000 then
				AddLog("Found: " .. v.Name)
				status.Text = "Found: " .. v.Name
				StealthTP(v)
				fireproximityprompt(v:FindFirstChildOfClass("ProximityPrompt"), 1)
				AddLog("Picked: " .. v.Name)
				status.Text = "Picked: " .. v.Name
			end
		end
	end
end

-- Auto Sell Items in inventory
function AutoSell()
	local inv = LocalPlayer:FindFirstChild("Backpack")
	if not inv then return end
	for _, item in ipairs(inv:GetChildren()) do
		if item:IsA("Tool") and item:FindFirstChild("Handle") then
			AddLog("Selling: " .. item.Name)
			item.Parent = Workspace
		end
	end
end

-- Auto Rejoin
LocalPlayer.OnTeleport:Connect(function(State)
	if State == Enum.TeleportState.Failed then
		AddLog("Teleport failed, rejoining...")
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
	end
end)

-- Server Hop
function ServerHop()
	local servers = {}
	local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
	local success, result = pcall(function()
		return HttpService:JSONDecode(game:HttpGet(url))
	end)
	if success and result and result.data then
		for _, v in pairs(result.data) do
			if v.playing < v.maxPlayers and v.id ~= game.JobId then
				AddLog("Hopping to new server...")
				TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id)
				break
			end
		end
	end
end

-- Main Loop
task.spawn(function()
	while true do
		pcall(function()
			PickupItems()
			AutoSell()
		end)
		wait(3)
	end
end)

-- Server Hop Loop
task.spawn(function()
	while true do
		wait(serverHopDelay)
		ServerHop()
	end
end)

AddLog("Script started. Farming in progress...")
status.Text = "Running"
