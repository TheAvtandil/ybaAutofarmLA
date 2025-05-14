-- Made by rinq :100: @rinq on discord
-- Fixed version for YBA

game.Loaded:Wait()

local BuyLucky = true
local AutoSell = true
local SellItems = {
    ["Gold Coin"] = true,
    ["Rokakaka"] = true,
    ["Pure Rokakaka"] = true,
    ["Mysterious Arrow"] = true,
    ["Diamond"] = true,
    ["Ancient Scroll"] = true,
    ["Caesar's Headband"] = true,
    ["Stone Mask"] = true,
    ["Rib Cage of The Saint's Corpse"] = true,
    ["Quinton's Glove"] = true,
    ["Zeppeli's Hat"] = true,
    ["Lucky Arrow"] = false,
    ["Clackers"] = true,
    ["Steel Ball"] = true,
    ["Dio's Diary"] = true
}

-- Script --

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Has2x = MarketplaceService:UserOwnsGamePassAsync(Player.UserId, 14597778)

-- Vector3 Index Hook (Proximity Bypass) --
local oldMagnitude
oldMagnitude = hookmetamethod(Vector3.new(), "__index", newcclosure(function(self, index)
    local CallingScript = getcallingscript() and tostring(getcallingscript()) or ""

    if not checkcaller() and index == "magnitude" and CallingScript == "ItemSpawn" then
        return 0
    end

    return oldMagnitude(self, index)
end))

local ItemSpawnFolder = Workspace:WaitForChild("Item_Spawns"):WaitForChild("Items")

local function GetCharacter(Part)
    if Player.Character then
        if not Part then
            return Player.Character
        elseif typeof(Part) == "string" then
            return Player.Character:FindFirstChild(Part) or nil
        end
    end

    return nil
end

local function TeleportTo(Position)
    local HumanoidRootPart = GetCharacter("HumanoidRootPart")

    if HumanoidRootPart then
        local PositionType = typeof(Position)

        if PositionType == "CFrame" then
            HumanoidRootPart.CFrame = Position
        elseif PositionType == "Vector3" then
            HumanoidRootPart.CFrame = CFrame.new(Position)
        end
    end
end

local function ToggleNoclip(Value)
    local Character = GetCharacter()

    if Character then
        for _, Child in pairs(Character:GetDescendants()) do
            if Child:IsA("BasePart") and Child.CanCollide == not Value then
                Child.CanCollide = not Value
            end
        end
    end
end

local MaxItemAmounts = {
    ["Gold Coin"] = 45,
    ["Rokakaka"] = 25,
    ["Pure Rokakaka"] = 10,
    ["Mysterious Arrow"] = 25,
    ["Diamond"] = 30,
    ["Ancient Scroll"] = 10,
    ["Caesar's Headband"] = 10,
    ["Stone Mask"] = 10,
    ["Rib Cage of The Saint's Corpse"] = 20,
    ["Quinton's Glove"] = 10,
    ["Zeppeli's Hat"] = 10,
    ["Lucky Arrow"] = 10,
    ["Clackers"] = 10,
    ["Steel Ball"] = 10,
    ["Dio's Diary"] = 10
}

if Has2x then
    for Index, Max in pairs(MaxItemAmounts) do
        MaxItemAmounts[Index] = Max * 2
    end
end

local function HasMaxItem(Item)
    local Count = 0

    for _, Tool in pairs(Player.Backpack:GetChildren()) do
        if Tool.Name == Item then
            Count = Count + 1
        end
    end
    
    -- Also check for items equipped in character
    local Character = GetCharacter()
    if Character then
        for _, Tool in pairs(Character:GetChildren()) do
            if Tool:IsA("Tool") and Tool.Name == Item then
                Count = Count + 1
            end
        end
    end

    if MaxItemAmounts[Item] then
        return Count >= MaxItemAmounts[Item]
    else
        warn("Item not found in the table: " .. Item)
        return false
    end
end

-- ServerHop function if needed
local function ServerHop()
    local servers = {}
    local req = game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")
    local data = game:GetService("HttpService"):JSONDecode(req)
    
    if data and data.data then
        for _, v in pairs(data.data) do
            if v.playing and v.playing < v.maxPlayers and v.id ~= game.JobId then
                table.insert(servers, v.id)
            end
        end
        
        if #servers > 0 then
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)])
        else
            warn("No available servers found")
        end
    end
end

local function GetItemInfo(Model)
    if Model and Model:IsA("Model") and Model.Parent and Model.Parent.Name == "Items" then
        local PrimaryPart = Model.PrimaryPart
        if not PrimaryPart then
            for _, part in pairs(Model:GetChildren()) do
                if part:IsA("BasePart") then
                    PrimaryPart = part
                    break
                end
            end
        end
        
        if not PrimaryPart then return nil end
        
        local Position = PrimaryPart.Position
        local ProximityPrompt

        for _, ItemInstance in pairs(Model:GetDescendants()) do
            if ItemInstance:IsA("ProximityPrompt") then
                ProximityPrompt = ItemInstance
                break
            end
        end

        if ProximityPrompt then
            return {["Name"] = ProximityPrompt.ObjectText, ["ProximityPrompt"] = ProximityPrompt, ["Position"] = Position}
        end
    end

    return nil
end

-- Store spawned items
getgenv().SpawnedItems = {}

-- Track existing items
for _, Model in pairs(ItemSpawnFolder:GetChildren()) do
    task.spawn(function()
        local ItemInfo = GetItemInfo(Model)
        if ItemInfo then
            getgenv().SpawnedItems[Model] = ItemInfo
        end
    end)
end

-- Track new items
ItemSpawnFolder.ChildAdded:Connect(function(Model)
    task.wait(1)
    if Model:IsA("Model") then
        local ItemInfo = GetItemInfo(Model)
        if ItemInfo then
            getgenv().SpawnedItems[Model] = ItemInfo
        end
    end
end)

ItemSpawnFolder.ChildRemoved:Connect(function(Model)
    if getgenv().SpawnedItems[Model] then
        getgenv().SpawnedItems[Model] = nil
    end
end)

local UzuKeeIsRetardedAndDoesntKnowHowToMakeAnAntiCheatOnTheServerSideAlsoVexStfuIKnowTheCodeIsBadYouDontNeedToTellMe = "  ___XP DE KEY"

-- Namecall Hook (TP Bypass) --
local oldNc
oldNc = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local Method = getnamecallmethod()
    local Args = {...}

    if not checkcaller() and Method == "FireServer" and self.Name == "Returner" and Args[1] == "idklolbrah2de" then
        return UzuKeeIsRetardedAndDoesntKnowHowToMakeAnAntiCheatOnTheServerSideAlsoVexStfuIKnowTheCodeIsBadYouDontNeedToTellMe
    end

    return oldNc(self, ...)
end))

task.wait(1)

-- Auto-sell function
if AutoSell then
    for Item, Sell in pairs(SellItems) do
        if Sell and Player.Backpack and Player.Backpack:FindFirstChild(Item) then
            GetCharacter("Humanoid"):EquipTool(Player.Backpack:FindFirstChild(Item))

            GetCharacter("RemoteEvent"):FireServer("EndDialogue", {
                ["NPC"] = "Merchant",
                ["Dialogue"] = "Dialogue5",
                ["Option"] = "Option2"
            })

            task.wait(.1)
        end
    end
end


-- Handle loading screens
if PlayerGui:FindFirstChild("LoadingScreen1") then
    PlayerGui:WaitForChild("LoadingScreen1"):Destroy()
end

task.wait(0.5)

pcall(function()
    if PlayerGui:FindFirstChild("LoadingScreen") then
        PlayerGui:WaitForChild("LoadingScreen"):Destroy()
    end
end)

pcall(function()
    if workspace:FindFirstChild("LoadingScreen") and workspace.LoadingScreen:FindFirstChild("Song") then
        workspace.LoadingScreen.Song:Destroy()
    end
end)

-- Make sure we're in the game
repeat task.wait() until GetCharacter() and GetCharacter("RemoteEvent")

-- Press play
GetCharacter("RemoteEvent"):FireServer("PressedPlay")

-- Move to item farming position
TeleportTo(CFrame.new(978, -42, -49))

task.wait(5)

-- Buy Lucky Arrow if enabled
local Money = Player.PlayerStats.Money

if BuyLucky then
    while Money.Value >= 50000 do
        Player.Character.RemoteEvent:FireServer("PurchaseShopItem", {["ItemName"] = "1x Lucky Arrow"})
        task.wait(.1)
    end
end
-- Main item collection loop
while true do
    local itemsCollected = false
    
    for Model, ItemInfo in pairs(getgenv().SpawnedItems) do
        local HumanoidRootPart = GetCharacter("HumanoidRootPart")

        if HumanoidRootPart then
            local Name = ItemInfo.Name

            local HasMax = HasMaxItem(Name)

            if not HasMax then
                local ProximityPrompt = ItemInfo.ProximityPrompt
                local Position = ItemInfo.Position

                if not ProximityPrompt or not ProximityPrompt.Parent then
                    getgenv().SpawnedItems[Model] = nil
                    print("Removed invalid item: " .. (Name or "Unknown"))
                    continue
                end

                local BodyVelocity = Instance.new("BodyVelocity")
                BodyVelocity.Parent = HumanoidRootPart
                BodyVelocity.Velocity = Vector3.new(0, 0, 0)
                BodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)

                ToggleNoclip(true)
                TeleportTo(CFrame.new(Position.X, Position.Y + 5, Position.Z))

                task.wait(0.2)
                fireproximityprompt(ProximityPrompt)
                task.wait(0.2)
                
                if SellItems[Name] and AutoSell then
                    SellItem(Name)
                end

                BodyVelocity:Destroy()
                ToggleNoclip(false)

                TeleportTo(CFrame.new(978, -42, -49))

                print("Collected an item: " .. Name)
                getgenv().SpawnedItems[Model] = nil
                itemsCollected = true
            else
                getgenv().SpawnedItems[Model] = nil
                print("Already have max " .. Name)
            end
        end
    end

    -- If no items were collected for a while, consider server hopping
    if not itemsCollected then
        local itemCount = 0
        for _ in pairs(getgenv().SpawnedItems) do
            itemCount = itemCount + 1
        end
        
        if itemCount == 0 then
            task.wait(10)  -- Wait for potential new items
            local newItemCount = 0
            for _ in pairs(getgenv().SpawnedItems) do
                newItemCount = newItemCount + 1
            end
            
            if newItemCount == 0 then
                print("No items found, waiting for more to spawn...")
                -- Uncomment the next line if you want to server hop when no items are found
                -- ServerHop()
            end
        end
    end

    task.wait(1)
end
