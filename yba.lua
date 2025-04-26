-- Final Safe Logger (Only track valid items, no junk)

local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local ItemFolder = Workspace:WaitForChild("Item_Spawns"):WaitForChild("Items")
local loggedItems = {}
local fileName = "YBA_RealItems.json"

local function save()
    if writefile then
        writefile(fileName, HttpService:JSONEncode(loggedItems))
    end
end

local function trackIfValid(item)
    task.spawn(function()
        task.wait(0.3) -- slight wait

        if not item:IsA("Model") then return end
        local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
        local basepart = item:FindFirstChildWhichIsA("BasePart", true)

        if prompt and basepart then
            local pos = basepart.Position
            loggedItems[item.Name .. tostring(pos)] = {
                Name = item.Name,
                X = math.floor(pos.X),
                Y = math.floor(pos.Y),
                Z = math.floor(pos.Z)
            }
            print("✅ Logged Item:", item.Name, pos)
            save()
        else
            -- ignore junk
        end
    end)
end

-- Listen for new clean spawns
ItemFolder.ChildAdded:Connect(trackIfValid)

print("✅ PigletHub Logger Started. Waiting for real items only...")
