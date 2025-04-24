print("[AutoFarm] Loading PintoHub...")
local success, err = pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/justinbieberreal/PintoHub/refs/heads/main/PintoHub.lua"))()
end)

if success then
    print("[AutoFarm] PintoHub loaded.")
else
    warn("[AutoFarm] Failed to load PintoHub:", err)
    return
end

-- Wait for GUI to load and auto-toggle item farm
task.spawn(function()
    print("[AutoFarm] Waiting for PintoHub GUI...")
    local gui
    repeat
        task.wait(1)
        gui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui"):FindFirstChild("PintoHub")
    until gui

    print("[AutoFarm] GUI found. Waiting for sections...")
    task.wait(4) -- extra safety delay

    local section2 = gui:FindFirstChild("Section2", true)
    if section2 then
        print("[AutoFarm] Section 2 found. Scanning buttons...")
        local buttons = section2:GetDescendants()
        local count = 0
        for _, btn in ipairs(buttons) do
            if btn:IsA("TextButton") then
                count += 1
                print("[AutoFarm] Found button #" .. count .. ": " .. btn.Text)
                if count == 4 then
                    firesignal(btn.MouseButton1Click)
                    print("[AutoFarm] ✅ Toggled Item Farm (Section 2 > Option 4).")
                    break
                end
            end
        end
    else
        warn("[AutoFarm] ❌ Couldn’t find Section 2.")
    end
end)

-- Server Hop (same as before)
task.spawn(function()
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    local Player = game:GetService("Players").LocalPlayer
    local PLACE_ID = 2809202155

    while true do
        task.wait(105)
        print("[AutoFarm] Trying serverhop...")
        local success, data = pcall(function()
            return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. PLACE_ID .. "/servers/Public?sortOrder=Asc&limit=100"))
        end)
        if success and data and data.data then
            for _, server in ipairs(data.data) do
                if server.id ~= game.JobId and server.playing < server.maxPlayers then
                    print("[AutoFarm] ➤ Hopping to new server...")
                    TeleportService:TeleportToPlaceInstance(PLACE_ID, server.id, Player)
                    return
                end
            end
        else
            warn("[AutoFarm] ❌ Server list fetch failed.")
        end
    end
end)
