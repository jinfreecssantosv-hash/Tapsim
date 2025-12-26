-- Orion Library
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()

-- Services
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local VirtualUser = game:GetService("VirtualUser")

------------------------------------------------
-- WINDOW
------------------------------------------------
local Window = OrionLib:MakeWindow({
	Name = "⚡ Tap Simulator Hub",
	HidePremium = false,
	SaveConfig = true,
	ConfigFolder = "TapSimulator"
})

------------------------------------------------
-- 🔒 ANTI AFK
------------------------------------------------
LocalPlayer.Idled:Connect(function()
	VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
	task.wait(1)
	VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

------------------------------------------------
-- 📊 STATS TAB
------------------------------------------------
local StatsTab = Window:MakeTab({ Name = "Stats", Icon = "rbxassetid://4483345998" })

StatsTab:AddParagraph(
	"Player Info",
	"Username: "..LocalPlayer.Name..
	"\nUserId: "..LocalPlayer.UserId..
	"\nAccount Age: "..LocalPlayer.AccountAge.." days"
)

------------------------------------------------
-- 👆 TAP TAB
------------------------------------------------
local TapTab = Window:MakeTab({ Name = "Tap", Icon = "rbxassetid://4483345998" })

_G.AutoTap = false

TapTab:AddToggle({
	Name = "Auto Tap",
	Default = false,
	Callback = function(v)
		_G.AutoTap = v
		while _G.AutoTap do
			task.wait()
			-- Replace with the actual tap remote. Example:
			-- RS.Remotes.Tap:FireServer()
		end
	end
})

TapTab:AddButton({
	Name = "Tap Once",
	Callback = function()
		-- Replace with the correct remote event for a single tap
		-- RS.Remotes.Tap:FireServer()
	end
})

------------------------------------------------
-- 🛒 UPGRADE SHOP
------------------------------------------------
local UpgradeTab = Window:MakeTab({ Name = "Upgrades", Icon = "rbxassetid://4483345998" })

_G.AutoUpgrade = false

UpgradeTab:AddToggle({
	Name = "Auto Buy Upgrades",
	Default = false,
	Callback = function(v)
		_G.AutoUpgrade = v
		while _G.AutoUpgrade do
			task.wait(1)
			-- Replace with real upgrade remote. Example:
			-- RS.Remotes.BuyUpgrade:FireServer("TapPower")
		end
	end
})

------------------------------------------------
-- 🥚 CRAFT TAB
------------------------------------------------
local CraftTab = Window:MakeTab({ Name = "Craft", Icon = "rbxassetid://4483345998" })

_G.AutoGolden = false
_G.AutoRainbow = false

CraftTab:AddToggle({
	Name = "Auto Craft Golden",
	Default = false,
	Callback = function(v)
		_G.AutoGolden = v
		while _G.AutoGolden do
			task.wait(2)
			-- RS.Remotes.CraftGolden:FireServer()
		end
	end
})

CraftTab:AddToggle({
	Name = "Auto Craft Rainbow",
	Default = false,
	Callback = function(v)
		_G.AutoRainbow = v
		while _G.AutoRainbow do
			task.wait(3)
			-- RS.Remotes.CraftRainbow:FireServer()
		end
	end
})

------------------------------------------------
-- 🧪 POTIONS TAB
------------------------------------------------
local PotionTab = Window:MakeTab({ Name = "Potions", Icon = "rbxassetid://4483345998" })

_G.PotionAmount = 1
_G.AutoPotion = false

PotionTab:AddDropdown({
	Name = "Potion Buy Amount",
	Default = "1x",
	Options = {"1x","3x","10x"},
	Callback = function(v)
		_G.PotionAmount = tonumber(v:sub(1, v:find("x")-1)) or 1
	end
})

PotionTab:AddToggle({
	Name = "Auto Buy Potions",
	Default = false,
	Callback = function(v)
		_G.AutoPotion = v
		while _G.AutoPotion do
			task.wait(2)
			-- RS.Remotes.BuyPotion:FireServer(_G.PotionAmount)
		end
	end
})

------------------------------------------------
-- 🌍 WORLD TAB
------------------------------------------------
local WorldTab = Window:MakeTab({ Name = "Worlds", Icon = "rbxassetid://4483345998" })

_G.SelectedWorld = "Desert"

WorldTab:AddDropdown({
	Name = "Select World",
	Default = "Desert",
	Options = {"Desert","Forest","Snow","Lava","Galaxy"},
	Callback = function(v)
		_G.SelectedWorld = v
	end
})

WorldTab:AddButton({
	Name = "Unlock Selected World",
	Callback = function()
		-- RS.Remotes.UnlockWorld:FireServer(_G.SelectedWorld)
	end
})

WorldTab:AddButton({
	Name = "Unlock All Worlds",
	Callback = function()
		-- RS.Remotes.UnlockAllWorlds:FireServer()
	end
})

------------------------------------------------
-- ⚙️ MISC TAB
------------------------------------------------
local MiscTab = Window:MakeTab({ Name = "Misc", Icon = "rbxassetid://4483345998" })

MiscTab:AddButton({
	Name = "Rejoin Server",
	Callback = function()
		game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
	end
})

MiscTab:AddButton({
	Name = "Destroy UI",
	Callback = function()
		OrionLib:Destroy()
	end
})

------------------------------------------------
-- INIT
------------------------------------------------
OrionLib:Init()
