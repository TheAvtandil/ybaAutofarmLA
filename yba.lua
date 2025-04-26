-- Auto-Log Unique Item Spawn Positions in YBA
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local ItemFolder = Workspace:WaitForChild("Item_Spawns"):WaitForChild("Items")
local savedPositions = {}
local lastLog = tick()
local saveFile = "YBA_SpawnPoints.json"

-- Load existing positions
if isfile and readfile and isfile(saveFile) then
    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(saveFile))
    end)
    if success and type(data) == "table" then
        for _, pos in pairs(data) do
            table.insert(savedPositions, Vector3.new(pos.X, pos.Y, pos.Z))
        end
    end
end

-- Check if position is already known (small tolerance)
local function isNew(pos)
    for _, p in ipairs(savedPositions) do
        if (p - pos).Magnitude < 2 then
            return false
        end
    end
    return true
end

-- Save function
local function save()
    if writefile then
        local export = {}
        for _, vec in ipairs(savedPositions) do
            table.insert(export, { X = vec.X, Y = vec.Y, Z = vec.Z })
        end
        writefile(saveFile, HttpService:JSONEncode(export))
        print("✅ Saved spawn positions! Count:", #export)
    end
end

-- Log new items
ItemFolder.ChildAdded:Connect(function(child)
    task.wait(0.1)
    local part = child:FindFirstChildWhichIsA("BasePart", true)
    if part and isNew(part.Position) then
        table.insert(savedPositions, part.Position)
        print("🗺️ Logged new item spawn at:", part.Position)
        if tick() - lastLog > 5 then
            lastLog = tick()
            save()
        end
    end
end)

-- Initial scan
for _, item in ipairs(ItemFolder:GetChildren()) do
    local part = item:FindFirstChildWhichIsA("BasePart", true)
    if part and isNew(part.Position) then
        table.insert(savedPositions, part.Position)
        print("📍 Initial item at:", part.Position)
    end
end

save()
