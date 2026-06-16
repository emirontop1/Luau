-- Aurora UI Library - latest example
local Aurora = loadstring(game:HttpGet("https://raw.githubusercontent.com/emirontop1/luau/main/src/Aurora.lua"))()

local Window = Aurora:CreateWindow({
    Title = "Aurora Hub",
    Name = "AuroraHub",
})

local Main = Window:AddTab("Main")
local Player = Window:AddTab("Player")
local Settings = Window:AddTab("Settings")

local Combat = Main:AddSection("Combat")
Combat:AddParagraph("Welcome", "Clean Luau GUI components with safe callbacks and a draggable window.")
Combat:AddButton({
    Text = "Show notification",
    Callback = function()
        Window:Notify({ Title = "Aurora", Text = "Button clicked successfully!" })
    end,
})
Combat:AddToggle({
    Text = "Enable feature",
    Default = false,
    Callback = function(value)
        print("Feature enabled:", value)
    end,
})

local Movement = Player:AddSection("Movement")
Movement:AddSlider({
    Text = "WalkSpeed",
    Min = 16,
    Max = 100,
    Default = 16,
    Callback = function(value)
        local character = game.Players.LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = value
        end
    end,
})
Movement:AddTextbox({
    Placeholder = "Say something...",
    SubmitOnFocusLost = true,
    Callback = function(text)
        print("Textbox:", text)
    end,
})

local Config = Settings:AddSection("Config")
Config:AddDropdown({
    Text = "Theme",
    Values = { "Aurora", "Dark", "Purple" },
    Default = "Aurora",
    Callback = function(theme)
        print("Theme selected:", theme)
    end,
})
Config:AddLabel("Tip: replace <OWNER>/<REPO> with your GitHub repository path.")
