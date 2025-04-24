-- PigletHUB - YBA Auto-Farm Script [Full Version]
-- Features: Full-map item detection, item pickup logs, auto-sell, server hop, anti-kick, stealth teleport, GUI

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Setup GUI
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "PigletHUB"
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 300, 0, 400)
frame.Position = UDim2.new(1, -320, 0, 60)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BorderSizePixel = 0
frame.BackgroundTransparency = 0.2

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "PigletHUB"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextScaled = true

local status = Instance.new("TextLabel", frame)
status.Size = UDim2.new(1, 0, 0, 25)
status.Position = UDim2.new(0, 0, 0, 30)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.new(0.5, 1, 0.5)
status.Text = "Script running..."
status.TextScaled = true

local logFrame = Instance.new("ScrollingFrame", frame)
logFrame.Size = UDim2.new(1, -10, 1, -65)
logFrame.Position = UDim2.new(0, 5, 0, 60)
logFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
logFrame.BorderSizePixel = 0
logFrame.CanvasSize = UDim2.new(0, 0, 0, 1000)

local UIListLayout = Instance.new("UIListLayout", logFrame)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function addLog(msg)
	local log = Instance.new("TextLabel", logFrame)
	log.Size = UDim2.new(1, 0, 0, 20)
	log.BackgroundTransparency = 1
	log.TextColor3 = Color3.new(1, 1, 1)
	log.Font = Enum.Font.SourceSans
	log.TextSize = 16
	log.TextXAlignment = Enum.TextXAlignment.Left
	log.Text = "["..os.date("%H:%M:%S").."] " .. msg
end

-- Anti kick
local lastTeleport = 0
local teleportCooldown = 1.5
local safeSpot = CFrame.new(0, -50, 0)

-- Function to teleport safely under item
local function stealthTeleport(target)
	if tick() - lastTeleport < teleportCooldown then return end
	lastTeleport = tick()

	local char = LocalPlayer.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end

	local hrp = char.HumanoidRootPart
	local original = hrp.CFrame
	hrp.CFrame = target * CFrame.new(0, -3, 0)
	task.wait(1.4)
	hrp.CFrame = safeSpot
end

-- Auto-sell
LocalPlayer.PlayerGui.ChildAdded:Connect(function(child)
	if child.Name == "Dialogue" then
		local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if root then root.CFrame = safeSpot end
	end
end)

LocalPlayer.Backpack.ChildAdded:Connect(function(child)
	if child:IsA("Tool") then
		addLog("Picked: " .. child.Name)
		if string.find(child.Name:lower(), "part") or string.find(child.Name:lower(), "arrow") or string.find(child.Name:lower(), "fruit") then
			fireclickdetector(workspace:WaitForChild("Game Items"):WaitForChild("Sell"):FindFirstChildOfClass("ClickDetector"))
		end
	end
end)

-- Item scanner
local function getItems()
	local items = {}
	for _, v in pairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") and v.Name == "TouchInterest" and v.Parent and v.Parent:FindFirstChild("ProximityPrompt") then
			local name = v.Parent.Name:lower()
			if string.find(name, "part") or string.find(name, "arrow") or string.find(name, "fruit") then
				table.insert(items, v.Parent)
			end
		end
	end
	return items
end

-- Pickup loop
task.spawn(function()
	while task.wait(0.5) do
		for _, item in pairs(getItems()) do
			if item:IsDescendantOf(workspace) and item:IsA("Model") then
				addLog("Detected: ".. item.Name)
				stealthTeleport(item:GetPivot())
				local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
				if prompt then fireproximityprompt(prompt) end
				break
			end
		end
	end
end)

-- Server hop
task.spawn(function()
	while true do
		task.wait(105)
		local servers = {}
		local req = request({Url = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"})
		if req.Success then
			local data = HttpService:JSONDecode(req.Body)
			for _, v in ipairs(data.data) do
				if v.playing < v.maxPlayers and v.id ~= game.JobId then
					table.insert(servers, v.id)
				end
			end
			if #servers > 0 then
				local serverId = servers[math.random(1, #servers)]
				TeleportService:TeleportToPlaceInstance(game.PlaceId, serverId, LocalPlayer)
			end
		end
	end
end)
