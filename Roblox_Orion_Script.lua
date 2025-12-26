-- Self-contained Tap Simulator GUI (no external libraries)
-- Provides Auto Tap, Auto Rebirth, Remote Enumerator, and simple teleports

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return warn("LocalPlayer not found. Run this client-side in a player session.") end

-- remove old GUI if present
local existing = LocalPlayer:FindFirstChildOfClass("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("TapSimGUI_by_Copilot")
if existing then existing:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TapSimGUI_by_Copilot"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- basic styling helper
local function make(cls, props)
    local obj = Instance.new(cls)
    for k,v in pairs(props or {}) do obj[k] = v end
    return obj
end

local mainFrame = make("Frame", {
    Size = UDim2.new(0, 360, 0, 420),
    Position = UDim2.new(0.5, -180, 0.15, 0),
    BackgroundColor3 = Color3.fromRGB(24,24,24),
    BorderSizePixel = 0,
    Parent = screenGui
})
mainFrame.Active = true
mainFrame.Draggable = true

local title = make("TextLabel", {
    Size = UDim2.new(1,0,0,36),
    Position = UDim2.new(0,0,0,0),
    BackgroundTransparency = 1,
    Text = "Tap Simulator - Copilot GUI",
    TextColor3 = Color3.fromRGB(255,255,255),
    Font = Enum.Font.SourceSansBold,
    TextSize = 20,
    Parent = mainFrame
})

local function makeButton(y, txt)
    local btn = make("TextButton", {
        Size = UDim2.new(0,160,0,36),
        Position = UDim2.new(0, 16 + ((#mainFrame:GetChildren()-3)%2)*176, 0, 56 + y),
        BackgroundColor3 = Color3.fromRGB(40,40,40),
        BorderSizePixel = 0,
        Text = txt,
        TextColor3 = Color3.fromRGB(255,255,255),
        Font = Enum.Font.SourceSans,
        TextSize = 16,
        Parent = mainFrame
    })
    return btn
end

-- Notification label (small)
local notif = make("TextLabel", {
    Size = UDim2.new(1, -16, 0, 28),
    Position = UDim2.new(0,8,1,-36),
    BackgroundTransparency = 0.2,
    BackgroundColor3 = Color3.fromRGB(10,10,10),
    TextColor3 = Color3.fromRGB(200,200,200),
    Text = "",
    Font = Enum.Font.SourceSans,
    TextSize = 16,
    Parent = mainFrame
})

local function notify(msg, t)
    t = t or 4
    notif.Text = msg
    spawn(function()
        wait(t)
        if notif then notif.Text = "" end
    end)
end

-- Controls area
local ctrlY = 0

-- Auto Tap toggle
local autoTapToggle = make("TextButton", {
    Size = UDim2.new(0,160,0,36),
    Position = UDim2.new(0,16,0,56),
    BackgroundColor3 = Color3.fromRGB(60,60,60),
    Text = "Auto Tap: OFF",
    TextColor3 = Color3.fromRGB(255,255,255),
    Font = Enum.Font.SourceSans,
    TextSize = 16,
    Parent = mainFrame
})

local autoRebirthToggle = make("TextButton", {
    Size = UDim2.new(0,160,0,36),
    Position = UDim2.new(0,192,0,56),
    BackgroundColor3 = Color3.fromRGB(60,60,60),
    Text = "Auto Rebirth: OFF",
    TextColor3 = Color3.fromRGB(255,255,255),
    Font = Enum.Font.SourceSans,
    TextSize = 16,
    Parent = mainFrame
})

-- Delay input
local delayLabel = make("TextLabel", {
    Size = UDim2.new(0,160,0,20),
    Position = UDim2.new(0,16,0,104),
    BackgroundTransparency = 1,
    Text = "Tap Delay (s):",
    TextColor3 = Color3.fromRGB(200,200,200),
    Font = Enum.Font.SourceSans,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = mainFrame
})
local delayBox = make("TextBox", {
    Size = UDim2.new(0,160,0,28),
    Position = UDim2.new(0,16,0,124),
    BackgroundColor3 = Color3.fromRGB(40,40,40),
    Text = "0.1",
    TextColor3 = Color3.fromRGB(255,255,255),
    Font = Enum.Font.SourceSans,
    TextSize = 16,
    Parent = mainFrame
})

-- Rebirth attempts input
local rebLabel = make("TextLabel", {
    Size = UDim2.new(0,160,0,20),
    Position = UDim2.new(0,192,0,104),
    BackgroundTransparency = 1,
    Text = "Rebirth per loop:",
    TextColor3 = Color3.fromRGB(200,200,200),
    Font = Enum.Font.SourceSans,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = mainFrame
})
local rebBox = make("TextBox", {
    Size = UDim2.new(0,160,0,28),
    Position = UDim2.new(0,192,0,124),
    BackgroundColor3 = Color3.fromRGB(40,40,40),
    Text = "1",
    TextColor3 = Color3.fromRGB(255,255,255),
    Font = Enum.Font.SourceSans,
    TextSize = 16,
    Parent = mainFrame
})

-- Remote enumerator and test buttons
local enumBtn = make("TextButton", {
    Size = UDim2.new(0,336,0,36),
    Position = UDim2.new(0,16,0,168),
    BackgroundColor3 = Color3.fromRGB(50,50,50),
    Text = "Remote Enumerator (prints to console)",
    TextColor3 = Color3.fromRGB(255,255,255),
    Font = Enum.Font.SourceSans,
    TextSize = 16,
    Parent = mainFrame
})

local printGuessBtn = make("TextButton", {
    Size = UDim2.new(0,336,0,36),
    Position = UDim2.new(0,16,0,212),
    BackgroundColor3 = Color3.fromRGB(50,50,50),
    Text = "Print guessed Tap & Rebirth",
    TextColor3 = Color3.fromRGB(255,255,255),
    Font = Enum.Font.SourceSans,
    TextSize = 16,
    Parent = mainFrame
})

-- Teleports
local tp1 = make("TextButton", {
    Size = UDim2.new(0,160,0,36),
    Position = UDim2.new(0,16,0,260),
    BackgroundColor3 = Color3.fromRGB(50,50,50),
    Text = "Teleport Spawn",
    TextColor3 = Color3.fromRGB(255,255,255),
    Font = Enum.Font.SourceSans,
    TextSize = 16,
    Parent = mainFrame
})
local tp2 = make("TextButton", {
    Size = UDim2.new(0,160,0,36),
    Position = UDim2.new(0,192,0,260),
    BackgroundColor3 = Color3.fromRGB(50,50,50),
    Text = "Teleport Shop",
    TextColor3 = Color3.fromRGB(255,255,255),
    Font = Enum.Font.SourceSans,
    TextSize = 16,
    Parent = mainFrame
})

-- Close button
local closeBtn = make("TextButton", {
    Size = UDim2.new(0,34,0,28),
    Position = UDim2.new(1,-40,0,6),
    BackgroundColor3 = Color3.fromRGB(140,30,30),
    Text = "X",
    TextColor3 = Color3.fromRGB(255,255,255),
    Font = Enum.Font.SourceSansBold,
    TextSize = 18,
    Parent = mainFrame
})

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Remote helpers (same approach as before)
local function findRemoteCandidates()
    local found = {}
    local function checkParent(parent)
        if not parent then return end
        for _, child in ipairs(parent:GetChildren()) do
            if child.ClassName == "RemoteEvent" or child.ClassName == "RemoteFunction" then
                table.insert(found, child)
            elseif child:IsA("Folder") then
                for _, g in ipairs(child:GetChildren()) do
                    if g.ClassName == "RemoteEvent" or g.ClassName == "RemoteFunction" then
                        table.insert(found, g)
                    end
                end
            end
        end
    end
    local services = {game:GetService("ReplicatedStorage"), game:GetService("ReplicatedFirst"), game:GetService("Workspace"), LocalPlayer:FindFirstChild("PlayerGui")}
    for _, s in ipairs(services) do if s then checkParent(s) end end
    return found
end

local function findTapRemote()
    local names = {"Tap","Click","Collect","Hit","ClickRemote","TapEvent","ClickEvent"}
    local rs = game:GetService("ReplicatedStorage")
    local containers = {rs, rs:FindFirstChild("Remotes"), rs:FindFirstChild("RemoteEvents"), rs:FindFirstChild("Events")}
    for _, cont in ipairs(containers) do
        if cont then
            for _, n in ipairs(names) do
                local obj = cont:FindFirstChild(n)
                if obj and (obj.ClassName=="RemoteEvent" or obj.ClassName=="RemoteFunction") then return obj end
            end
            for _, child in ipairs(cont:GetChildren()) do
                if child:IsA("Folder") then
                    for _, n in ipairs(names) do
                        local obj = child:FindFirstChild(n)
                        if obj and (obj.ClassName=="RemoteEvent" or obj.ClassName=="RemoteFunction") then return obj end
                    end
                end
            end
        end
    end
    local all = findRemoteCandidates()
    for _, r in ipairs(all) do local rn = r.Name:lower() if rn:match("tap") or rn:match("click") or rn:match("collect") then return r end end
    if #all>0 then return all[1] end
    return nil
end

local function findRebirthRemote()
    local names = {"Rebirth","Prestige","RebirthEvent","PrestigeEvent"}
    local rs = game:GetService("ReplicatedStorage")
    local containers = {rs, rs:FindFirstChild("Remotes"), rs:FindFirstChild("RemoteEvents")}
    for _, cont in ipairs(containers) do
        if cont then
            for _, n in ipairs(names) do
                local obj = cont:FindFirstChild(n)
                if obj and (obj.ClassName=="RemoteEvent" or obj.ClassName=="RemoteFunction") then return obj end
            end
            for _, child in ipairs(cont:GetChildren()) do
                if child:IsA("Folder") then
                    for _, n in ipairs(names) do
                        local obj = child:FindFirstChild(n)
                        if obj and (obj.ClassName=="RemoteEvent" or obj.ClassName=="RemoteFunction") then return obj end
                    end
                end
            end
        end
    end
    local all = findRemoteCandidates()
    for _, r in ipairs(all) do local rn = r.Name:lower() if rn:match("rebirth") or rn:match("prestige") then return r end end
    return nil
end

-- Auto mechanics
local autoTapRunning = false
local autoTapDelay = 0.1
local autoTapThread

local function doTap(remote)
    if not remote then return false, "no remote" end
    if remote.ClassName=="RemoteEvent" then
        local ok, e = pcall(function() remote:FireServer() end)
        return ok, e
    elseif remote.ClassName=="RemoteFunction" then
        local ok, res = pcall(function() return remote:InvokeServer() end)
        return ok, res
    end
    return false, "unsupported"
end

local function startAutoTap()
    if autoTapRunning then return end
    autoTapRunning = true
    autoTapThread = coroutine.create(function()
        local remote = findTapRemote()
        if not remote then notify("Tap remote not found.") autoTapRunning=false return end
        while autoTapRunning do
            local ok, res = doTap(remote)
            if not ok then notify("Tap failed: "..tostring(res)) autoTapRunning=false break end
            wait(autoTapDelay)
        end
    end)
    coroutine.resume(autoTapThread)
    notify("Auto Tap started")
end
local function stopAutoTap() autoTapRunning=false notify("Auto Tap stopped") end

local autoRebirthRunning=false
local rebirthThread
local function startAutoRebirth()
    if autoRebirthRunning then return end
    autoRebirthRunning=true
    rebirthThread=coroutine.create(function()
        local remote = findRebirthRemote()
        if not remote then notify("Rebirth remote not found.") autoRebirthRunning=false return end
        while autoRebirthRunning do
            local ok, res = pcall(function()
                if remote.ClassName=="RemoteEvent" then remote:FireServer() else remote:InvokeServer() end
            end)
            if not ok then pcall(function() if remote.ClassName=="RemoteEvent" then remote:FireServer(1) else remote:InvokeServer(1) end end)
            wait(0.5)
        end
    end)
    coroutine.resume(rebirthThread)
    notify("Auto Rebirth started")
end
local function stopAutoRebirth() autoRebirthRunning=false notify("Auto Rebirth stopped") end

-- UI behaviour
local function toNum(s, def) local n=tonumber(s) return n and n>0 and n or def end

autoTapToggle.MouseButton1Click:Connect(function()
    if not autoTapRunning then
        autoTapDelay = toNum(delayBox.Text, 0.1)
        startAutoTap()
        autoTapToggle.BackgroundColor3 = Color3.fromRGB(0,150,0)
        autoTapToggle.Text = "Auto Tap: ON"
    else
        stopAutoTap()
        autoTapToggle.BackgroundColor3 = Color3.fromRGB(60,60,60)
        autoTapToggle.Text = "Auto Tap: OFF"
    end
end)

autoRebirthToggle.MouseButton1Click:Connect(function()
    if not autoRebirthRunning then
        startAutoRebirth()
        autoRebirthToggle.BackgroundColor3 = Color3.fromRGB(0,150,0)
        autoRebirthToggle.Text = "Auto Rebirth: ON"
    else
        stopAutoRebirth()
        autoRebirthToggle.BackgroundColor3 = Color3.fromRGB(60,60,60)
        autoRebirthToggle.Text = "Auto Rebirth: OFF"
    end
end)

enumBtn.MouseButton1Click:Connect(function()
    local found = findRemoteCandidates()
    if #found==0 then print("No remotes found in common services.") notify("No remotes found.") return end
    print("---- Remote Enumerator Output ----")
    for _, r in ipairs(found) do
        print(("Name: %s | Class: %s | FullName: %s"):format(r.Name, r.ClassName, r:GetFullName()))
    end
    print("---- End Output ----")
    notify("Printed remotes to console", 6)
end)

printGuessBtn.MouseButton1Click:Connect(function()
    local t = findTapRemote()
    local r = findRebirthRemote()
    if t then print("Guessed Tap:", t:GetFullName(), t.ClassName) notify("Tap: "..t:GetFullName()) else notify("Tap not found") end
    if r then print("Guessed Rebirth:", r:GetFullName(), r.ClassName) notify("Rebirth: "..r:GetFullName()) else notify("Rebirth not found") end
end)

-- Teleports (example coords)
tp1.MouseButton1Click:Connect(function()
    local plr = LocalPlayer
    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
        plr.Character.HumanoidRootPart.CFrame = CFrame.new(0,10,0)
        notify("Teleported to spawn")
    end
end)

tp2.MouseButton1Click:Connect(function()
    local plr = LocalPlayer
    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
        plr.Character.HumanoidRootPart.CFrame = CFrame.new(100,10,0)
        notify("Teleported to shop")
    end
end)

-- finished
notify("TapSim GUI loaded (self-contained)", 5)
