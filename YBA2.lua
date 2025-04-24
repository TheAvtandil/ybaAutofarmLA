-- Load PintoHub
loadstring(game:HttpGet("https://raw.githubusercontent.com/justinbieberreal/PintoHub/refs/heads/main/PintoHub.lua"))()

-- Wait for GUI and force-toggle Item Farm
task.spawn(function()
    local Player = game:GetService("Players").LocalPlayer
    local gui

    repeat
        task.wait(1)
        gui = Player:FindFirstChild("PlayerGui"):FindFirstChild("PintoHub")
    until gui

    task.wait(4)

    print("[AutoFarm] Opening Items tab...")
    for _, v in pairs(gui:GetDescendants()) do
        if v:IsA("TextButton") and v.Text and v.Text:lower() == "items" then
            firesignal(v.MouseButton1Click)
            print("[AutoFarm] ✅ Clicked 'Items' tab.")
            break
        end
    end

    task.wait(2)

    print("[AutoFarm] Searching for 'Item Farm' toggle...")
    local toggled = false
    for _, v in pairs(gui:GetDescendants()) do
        if (v:IsA("TextButton") or v:IsA("ImageButton")) and v.Text and v.Text:lower():find("item farm") then
            print("[AutoFarm] Found Item Farm toggle: firing signal...")
            firesignal(v.MouseButton1Click)
            toggled = true
            break
        end
    end

    if not toggled then
        -- fallback: try to find any TextLabel or toggle near text
        for _, v in pairs(gui:GetDescendants()) do
            if v:IsA("TextLabel") and v.Text:lower():find("item farm") then
                local parent = v.Parent
                for _, sibling in pairs(parent:GetChildren()) do
                    if sibling:IsA("TextButton") or sibling:IsA("ImageButton") then
                        print("[AutoFarm] Firing fallback sibling toggle...")
                        firesignal(sibling.MouseButton1Click)
                        break
                    end
                end
            end
        end
    end
end)

-- Server Hop
task.spawn(function()
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    local Player = game:GetService("Players").LocalPlayer
    local PLACE_ID = 2809202155

    while true do
        task.wait(105)
        print("[AutoFarm] Hopping servers...")
        local success, data = pcall(function()
            return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. PLACE_ID .. "/servers/Public?sortOrder=Asc&limit=100"))
        end)
        if success and data and data.data then
            for _, server in ipairs(data.data) do
                if server.id ~= game.JobId and server.playing < server.maxPlayers then
                    TeleportService:TeleportToPlaceInstance(PLACE_ID, server.id, Player)
                    break
                end
            end
        end
    end
end)
