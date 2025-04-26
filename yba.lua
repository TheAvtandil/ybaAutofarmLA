-- Light Item Spawn Logger for YBA
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local scannedItems = {}
local logFileName = "YBA_ItemSpawns.json"

local function saveToFile()
    if writefile then
        writefile(logFileName, HttpService:JSONEncode(scannedItems))
    end
end

local function logItem(item)
    if item:IsA("Model") and not scannedItems[item:GetFullName()] then
        local part = item:FindFirstChildWhichIsA("BasePart", true)
        if part then
            scannedItems[item:GetFullName()] = {
                Name = item.Name,
                Position = part.Position
            }
            print("Logged Item:", item.Name, tostring(part.Position))
            saveToFile()
        end
    end
end

local itemFolder = Workspace:WaitForChild("Item_Spawns"):WaitForChild("Items")

-- Scan existing
for _, item in ipairs(itemFolder:GetChildren()) do
    logItem(item)
end

-- Scan new items
itemFolder.ChildAdded:Connect(function(item)
    task.wait(0.2)
    logItem(item)
end)

print("✅ Item logger running.")
