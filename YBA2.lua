-- Load PintoHub script
loadstring(game:HttpGet("https://raw.githubusercontent.com/justinbieberreal/PintoHub/refs/heads/main/PintoHub.lua"))()

-- Automate: toggle 'Item Farm' on Items tab
task.spawn(function()
    local Player = game:GetService("Players").LocalPlayer
    local gui

    repeat
        task.wait(1)
        gui = Player:FindFirstChild("PlayerGui"):FindFirstChild("PintoHub")
    until gui

    task.wait(4) -- Give extra time for all GUI sections to load

    print("[AutoFarm] Scanning for 'Items' tab...")
    -- Click the 'Items' tab in left sidebar
    local sidebarClicked = false
    for _, v in pairs(gui:GetDescendants()) do
        if v:IsA("TextButton") and v.Text and v.Text:lower() == "items" then
            firesignal(v.MouseButton1Click)
            sidebarClicked = true
            print("[AutoFarm] ✅ Clicked 'Items' tab.")
            break
        end
    end

    if not sidebarClicked then
        warn("[AutoFarm] ❌ Could not find 'Items' sidebar button.")
        return
    end

    task.wait(2) -- Wait for content panel to update

    print("[AutoFarm] Scanning for 'Item Farm' toggle...")
    for _, v in pairs(gui:GetDescendants()) do
        if v:IsA("TextButton") and v.Text and v.Text:lower():find("item farm") then
            if v.TextColor3 == Color3.fromRGB(255, 255, 255) or v.TextColor3 == Color3.fromRGB(200, 200, 200) then
                firesignal(v.MouseButton1Click)
                print("[AutoFarm] ✅ Toggled 'Item Farm' ON.")
            else
                print("[AutoFarm] 'Item Farm' toggle already ON.")
            end
            break
        end
    end
end)

-- ServerHop (same)
task.spawn(function()
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    local Player = game:GetService("Players").LocalPlayer
    local PLACE_ID = 2809202155

    while true do
        task.wait(105)
        print("[AutoFarm] Attempting server hop...")
        local success, data = pcall(function()
            return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. PLACE_ID .. "/servers/Public?sortOrder=Asc&limit=100"))
        end)
        if success and data and data.data then
            for _, server in ipairs(data.data) do
                if server.id ~= game.JobId and server.playing < server.maxPlayers then
                    print("[AutoFarm] Hopping to new server...")
                    TeleportService:TeleportToPlaceInstance(PLACE_ID, server.id, Player)
                    return
                end
            end
        else
            warn("[AutoFarm] ❌ Failed to get servers.")
        end
    end
end)
