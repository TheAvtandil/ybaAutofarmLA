-- Made by rinq :100: @rinq on discord
-- Don't comment about how shit it is YBA isn't worth my time

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
    local CallingScript = tostring(getcallingscript())

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
        end
    end
end

local function ToggleNoclip(Value)
    local Character = GetCharacter()

    if Character then
        for _, Child in pairs(Character:GetDescendants()) do
            if Child:IsA("BasePart") and Child.CanCollide == not Value then
                Child.CanCollide = Value
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
            Count += 1
        end
    end

    if MaxItemAmounts[Item] then
        return Count >= MaxItemAmounts[Item]
    else
        warn("Item not found in the table: " .. Item)
        return false
    end
end

local Teleport = loadstring(game:HttpGet("https://raw.githubusercontent.com/rinqedd/pub_rblx/main/ServerHop", true))

local function GetItemInfo(Model)
    if Model and Model:IsA("Model") and Model.Parent and Model.Parent.Name == "Items" then
        local PrimaryPart = Model.PrimaryPart
        local Position = PrimaryPart.Position
        local ProximityPrompt

        for _, ItemInstance in pairs(Model:GetChildren()) do
            if ItemInstance:IsA("ProximityPrompt") and ItemInstance.MaxActivationDistance == 8 then
                ProximityPrompt = ItemInstance
            end
        end

        if ProximityPrompt then
            return {["Name"] = ProximityPrompt.ObjectText, ["ProximityPrompt"] = ProximityPrompt, ["Position"] = Position}
        end
    end

    return nil
end

getgenv().SpawnedItems = {}

ItemSpawnFolder.ChildAdded:Connect(function(Model)
    task.wait(1)
    if Model:IsA("Model") then
        local ItemInfo = GetItemInfo(Model)

        if ItemInfo then
            getgenv().SpawnedItems[Model] = ItemInfo
        end
    end
end)

local UzuKeeIsRetardedAndDoesntKnowHowToMakeAnAntiCheatOnTheServerSideAlsoVexStfuIKnowTheCodeIsBadYouDontNeedToTellMe = "  ___XP DE KEY"

-- Namecall Hook (TP Bypass) --
local oldNc
oldNc = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local Method = getnamecallmethod()
    local Args = {...}

    if not checkcaller() and rawequal(self.Name, "Returner") and rawequal(Args[1], "idklolbrah2de") then
        return UzuKeeIsRetardedAndDoesntKnowHowToMakeAnAntiCheatOnTheServerSideAlsoVexStfuIKnowTheCodeIsBadYouDontNeedToTellMe
    end

    return oldNc(self, ...)
end))

task.wait(1)

if not PlayerGui:FindFirstChild("HUD") then
    local HUD = ReplicatedStorage.Objects.HUD:Clone()
    HUD.Parent = PlayerGui
end

task.spawn(function()
    PlayerGui:WaitForChild("LoadingScreen1"):Destroy()

    task.wait(.5)

    pcall(function()
        PlayerGui:WaitForChild("LoadingScreen"):Destroy()
    end)

    pcall(function()
        workspace.LoadingScreen.Song:Destroy()
    end)
end)

repeat task.wait() until GetCharacter() and GetCharacter("RemoteEvent")

GetCharacter("RemoteEvent"):FireServer("PressedPlay")

TeleportTo(CFrame.new(978, -42, -49))

task.wait(5)

repeat
    for Index, ItemInfo in pairs(getgenv().SpawnedItems) do
        local HumanoidRootPart = GetCharacter("HumanoidRootPart")

        if HumanoidRootPart then
            local Name = ItemInfo.Name

            local HasMax = HasMaxItem(Name)

            if not HasMax then
                local ProximityPrompt = ItemInfo.ProximityPrompt
                local Position = ItemInfo.Position

                table.remove(getgenv().SpawnedItems, table.find(getgenv().SpawnedItems, ItemInfo))

                if not ProximityPrompt.Parent then
                    print("Why does this " .. ItemInfo.Name .. " prompt not have a parent bro")
                    continue
                end

                local BodyVelocity = Instance.new("BodyVelocity")
                BodyVelocity.Parent = HumanoidRootPart
                BodyVelocity.Velocity = Vector3.new(0, 0, 0)

                ToggleNoclip(true)
                TeleportTo(CFrame.new(Position.X, Position.Y + 25, Position.Z))

                task.wait(.2)
                fireproximityprompt(ProximityPrompt)
                ProximityPrompt.Destroying:Wait()

                BodyVelocity:Destroy()

                TeleportTo(CFrame.new(978, -42, -49))

                print("Collected an item: " .. Name)
            else
                table.remove(getgenv().SpawnedItems, table.find(getgenv().SpawnedItems, ItemInfo))
            end
        end
    end

    task.wait(3)
until #getgenv().SpawnedItems == 0