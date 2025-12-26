-- Robust Orion loader + Tap Simulator starter GUI (best-effort remote names)
-- NOTE: This uses likely remote names for Tap Simulator games. Because games differ,
-- this is a best-effort script. If a feature doesn't work, run the remote enumerator
-- I suggested earlier and paste the output so I can wire the exact remotes.

-- Safe HTTP fetch (tries game:HttpGet and common executor request functions)
local function fetchUrl(url)
    local ok, body = pcall(function()
        if game and game.HttpGet then
            return game:HttpGet(url, true)
        end
    end)
    if ok and body and #body > 0 then return body end

    local requestFuncs = {
        function(u) if syn and syn.request then return syn.request({Url = u, Method = "GET"}) end end,
        function(u) if http and http.request then return http.request({Url = u, Method = "GET"}) end end,
        function(u) if request then return request({Url = u, Method = "GET"}) end end,
        function(u) if http_request then return http_request({Url = u, Method = "GET"}) end end,
    }
    for _, f in ipairs(requestFuncs) do
        local ok2, res = pcall(function() return f(url) end)
        if ok2 and res then
            local body = res.Body or res.body
            if body and #body > 0 then return body end
        end
    end
    return nil, "failed to fetch"
end

-- Load Orion safely
local orionUrl = "https://raw.githubusercontent.com/shlexware/Orion/main/source"
local orionCode, err = fetchUrl(orionUrl)
if not orionCode then
    error("Could not fetch Orion library: "..tostring(err).."  URL: "..orionUrl)
end

local exec = load or loadstring
local OrionLib = exec(orionCode)
if type(OrionLib) == "function" then
    OrionLib = OrionLib()
end
if not OrionLib then
    error("Failed to execute Orion library code.")
end

-- Create main window
local Window = OrionLib:MakeWindow({
    Name = "Tap Simulator - GUI",
    HidePremium = true,
    SaveConfig = true,
    ConfigFolder = "TapSim"
})

-- Tabs
local mainTab = Window:MakeTab({ Name = "Main", Icon = "rbxassetid://4483345998", PremiumOnly = false })
local autoTab = Window:MakeTab({ Name = "Auto", Icon = "rbxassetid://4483345998", PremiumOnly = false })
local tpTab   = Window:MakeTab({ Name = "Teleports", Icon = "rbxassetid://4483345998", PremiumOnly = false })
local miscTab = Window:MakeTab({ Name = "Misc", Icon = "rbxassetid://4483345998", PremiumOnly = false })

-- Utility: find remote by name candidates (walks ReplicatedStorage and common folders)
local function findRemoteCandidates()
    local found = {}
    local checked = {}
    local function checkParent(parent)
        if not parent or checked[parent] then return end
        checked[parent] = true
        for _, child in ipairs(parent:GetChildren()) do
            local class = child.ClassName
            if class == "RemoteEvent" or class == "RemoteFunction" then
                table.insert(found, child)
            elseif child:IsA("Folder") or child:IsA("ModuleScript") then
                -- scan children (shallow)
                for _, g in ipairs(child:GetChildren()) do
                    if g.ClassName == "RemoteEvent" or g.ClassName == "RemoteFunction" then
                        table.insert(found, g)
                    end
                end
            end
        end
    end

    local servicesToScan = {
        game:GetService("ReplicatedStorage"),
        game:GetService("ReplicatedFirst"),
        game:GetService("StarterGui"),
        game:GetService("Workspace"),
        (game:GetService("Players").LocalPlayer and (game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui"))) or nil
    }
    for _, s in ipairs(servicesToScan) do
        if s then checkParent(s) end
    end
    return found
end

-- Heuristic lookups by common names (best-effort)
local function findTapRemote()
    local names = {
        "Tap", "Click", "ClickRemote", "TapEvent", "Collect", "RemoteTap", "ClickEvent", "Hit",
        "RemoteEvent", "Remote", "ClickRemoteEvent", "ClickRemoteEvent"
    }
    local rs = game:GetService("ReplicatedStorage")
    -- check direct children and common Remotes container
    local containers = { rs, rs:FindFirstChild("Remotes"), rs:FindFirstChild("RemoteEvents"), rs:FindFirstChild("Events") }
    for _, cont in ipairs(containers) do
        if cont then
            for _, name in ipairs(names) do
                local obj = cont:FindFirstChild(name)
                if obj and (obj.ClassName == "RemoteEvent" or obj.ClassName == "RemoteFunction") then
                    return obj
                end
            end
            -- check children of that container
            for _, child in ipairs(cont:GetChildren()) do
                if child:IsA("Folder") then
                    for _, name in ipairs(names) do
                        local obj = child:FindFirstChild(name)
                        if obj and (obj.ClassName == "RemoteEvent" or obj.ClassName == "RemoteFunction") then
                            return obj
                        end
                    end
                end
            end
        end
    end

    -- fallback: scan common services for any remote with a "Tap/Click" like name
    local all = findRemoteCandidates()
    for _, r in ipairs(all) do
        local rn = r.Name:lower()
        if rn:match("tap") or rn:match("click") or rn:match("hit") or rn:match("collect") then
            return r
        end
    end

    -- last resort: return first RemoteEvent found (useful for quick testing)
    if #all > 0 then return all[1] end
    return nil
end

local function findRebirthRemote()
    local names = {"Rebirth", "Prestige", "RebirthEvent", "PrestigeEvent", "RebirthRemote"}
    local rs = game:GetService("ReplicatedStorage")
    local containers = { rs, rs:FindFirstChild("Remotes"), rs:FindFirstChild("RemoteEvents") }
    for _, cont in ipairs(containers) do
        if cont then
            for _, name in ipairs(names) do
                local obj = cont:FindFirstChild(name)
                if obj and (obj.ClassName == "RemoteEvent" or obj.ClassName == "RemoteFunction") then
                    return obj
                end
            end
            for _, child in ipairs(cont:GetChildren()) do
                if child:IsA("Folder") then
                    for _, name in ipairs(names) do
                        local obj = child:FindFirstChild(name)
                        if obj and (obj.ClassName == "RemoteEvent" or obj.ClassName == "RemoteFunction") then
                            return obj
                        end
                    end
                end
            end
        end
    end
    -- fallback scan
    local all = findRemoteCandidates()
    for _, r in ipairs(all) do
        local rn = r.Name:lower()
        if rn:match("rebirth") or rn:match("prestige") then
            return r
        end
    end
    return nil
end

-- Auto Tap implementation
local autoTapRunning = false
local autoTapDelay = 0.1  -- default taps per second delay

local function doTap(remote)
    if not remote then return false, "no remote" end
    if remote.ClassName == "RemoteEvent" then
        local ok, e = pcall(function()
            -- many tap remotes require no args; some expect player or id — we try no-args first
            remote:FireServer()
        end)
        return ok, e
    elseif remote.ClassName == "RemoteFunction" then
        local ok, res = pcall(function()
            return remote:InvokeServer()
        end)
        return ok, res
    else
        return false, "unsupported class"
    end
end

local autoTapThread = nil
local function startAutoTap()
    if autoTapRunning then return end
    autoTapRunning = true
    autoTapThread = coroutine.create(function()
        local remote = findTapRemote()
        if not remote then
            OrionLib:MakeNotification({ Name = "Auto Tap", Content = "Tap remote not found. Use the Remote Enumerator in Misc.", Time = 6 })
            autoTapRunning = false
            return
        end
        while autoTapRunning do
            local ok, res = doTap(remote)
            if not ok then
                -- If tap failed, show notification once and stop loop to avoid spam
                OrionLib:MakeNotification({ Name = "Auto Tap", Content = "Tap failed: "..tostring(res), Time = 6 })
                -- stop rather than spam; user can re-enable after checking
                autoTapRunning = false
                break
            end
            wait(autoTapDelay)
        end
    end)
    coroutine.resume(autoTapThread)
end

local function stopAutoTap()
    autoTapRunning = false
end

-- Auto Rebirth implementation
local autoRebirthRunning = false
local autoRebirthMin = 1  -- default times per attempt

local rebirthThread = nil
local function startAutoRebirth()
    if autoRebirthRunning then return end
    autoRebirthRunning = true
    rebirthThread = coroutine.create(function()
        local remote = findRebirthRemote()
        if not remote then
            OrionLib:MakeNotification({ Name = "Auto Rebirth", Content = "Rebirth remote not found. Use Remote Enumerator.", Time = 6 })
            autoRebirthRunning = false
            return
        end
        while autoRebirthRunning do
            -- Try invoking rebirth. Many rebirth remotes expect an amount or nothing. We try no-args and then a 1 if fails.
            local ok, res = pcall(function()
                if remote.ClassName == "RemoteEvent" then
                    remote:FireServer()
                else
                    remote:InvokeServer()
                end
            end)
            if not ok then
                -- try variant with argument 1
                pcall(function()
                    if remote.ClassName == "RemoteEvent" then
                        remote:FireServer(1)
                    else
                        remote:InvokeServer(1)
                    end
                end)
            end
            wait(0.5)
        end
    end)
    coroutine.resume(rebirthThread)
end

local function stopAutoRebirth()
    autoRebirthRunning = false
end

-- GUI elements
autoTab:AddToggle({
    Name = "Auto Tap",
    Default = false,
    Callback = function(val)
        if val then startAutoTap() else stopAutoTap() end
    end
})

autoTab:AddSlider({
    Name = "Tap Delay (seconds)",
    Min = 0.01,
    Max = 1,
    Default = 0.1,
    Color = Color3.fromRGB(0,125,255),
    Increment = 0.01,
    ValueName = "Delay",
    Callback = function(v) autoTapDelay = v end
})

autoTab:AddToggle({
    Name = "Auto Rebirth",
    Default = false,
    Callback = function(val)
        if val then startAutoRebirth() else stopAutoRebirth() end
    end
})

autoTab:AddTextbox({
    Name = "Rebirth attempts per loop (optional)",
    Default = "1",
    TextDisappear = true,
    Callback = function(text)
        local n = tonumber(text)
        if n and n >= 1 then autoRebirthMin = n else autoRebirthMin = 1 end
    end
})

-- Teleports (example coordinates, change them as needed)
tpTab:AddButton({
    Name = "Teleport to Spawn",
    Callback = function()
        local plr = game:GetService("Players").LocalPlayer
        if plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            plr.Character.HumanoidRootPart.CFrame = CFrame.new(0, 10, 0)
        end
    end
})

tpTab:AddButton({
    Name = "Teleport to Shop (example)",
    Callback = function()
        local plr = game:GetService("Players").LocalPlayer
        if plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            plr.Character.HumanoidRootPart.CFrame = CFrame.new(100, 10, 0)
        end
    end
})

-- Misc utilities
miscTab:AddButton({
    Name = "Remote Enumerator (prints to console)",
    Callback = function()
        local found = findRemoteCandidates()
        if #found == 0 then
            print("No remote events/functions found in common services.")
            OrionLib:MakeNotification({ Name = "Enumerator", Content = "No remotes found in common services.", Time = 5 })
            return
        end
        print("---- Remote Enumerator Output ----")
        for _, r in ipairs(found) do
            print(("Name: %s | Class: %s | FullName: %s"):format(r.Name, r.ClassName, r:GetFullName()))
        end
        print("---- End Output ----")
        OrionLib:MakeNotification({ Name = "Enumerator", Content = "Printed remotes to console. Copy them here.", Time = 6 })
    end
})

miscTab:AddButton({
    Name = "Print found Tap & Rebirth (best guess)",
    Callback = function()
        local t = findTapRemote()
        local r = findRebirthRemote()
        if t then
            print("Guessed Tap remote:", t:GetFullName(), "Class:", t.ClassName)
            OrionLib:MakeNotification({ Name = "Guess", Content = "Tap remote: "..t:GetFullName(), Time = 5 })
        else
            OrionLib:MakeNotification({ Name = "Guess", Content = "Tap remote not found.", Time = 5 })
        end
        if r then
            print("Guessed Rebirth remote:", r:GetFullName(), "Class:", r.ClassName)
            OrionLib:MakeNotification({ Name = "Guess", Content = "Rebirth: "..r:GetFullName(), Time = 5 })
        else
            OrionLib:MakeNotification({ Name = "Guess", Content = "Rebirth remote not found.", Time = 5 })
        end
    end
})

miscTab:AddButton({
    Name = "Stop All",
    Callback = function()
        stopAutoTap()
        stopAutoRebirth()
        OrionLib:MakeNotification({ Name = "Stopped", Content = "Stopped Auto Tap and Auto Rebirth.", Time = 4 })
    end
})

OrionLib:MakeNotification({
    Name = "Loaded",
    Content = "Tap Simulator GUI loaded (best-effort remotes). Use Remote Enumerator if features fail.",
    Time = 6
})
