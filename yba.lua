-- Safer Item Spawn Logger (No Crash Version)

local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local ItemFolder = Workspace:WaitForChild("Item_Spawns"):WaitForChild("Items")
local loggedItems = {}
local fileName = "YBA_ItemSpawns.json"

local function save()
    if writefile then
        writefile(fileName, HttpService:JSONEncode(loggedItems))
    end
end

local function logNewItem(item)
    task.spawn(function()
        task.wait(0.5) -- wait half second for item to fully load

        if not item:IsA("Model") then return end
        local part = item:FindFirstChildWhichIsA("BasePart", true)
        if not part then return end
        if loggedItems[item.Name] then return end -- already logged?

        loggedItems[item.Name] = {
            X = math.floor(part.Position.X),
            Y = math.floor(part.Position.Y),
            Z = math.floor(part.Position.Z),
        }

        print("[LOGGED]", item.Name, part.Position)
        save()
    end)
end

-- Only future spawns
ItemFolder.ChildAdded:Connect(logNewItem)

print("✅ YBA Light Logger running. Waiting for item spawns...")
