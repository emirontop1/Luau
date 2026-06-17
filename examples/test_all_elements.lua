-- Aurora UI Library - all element smoke test
-- This file intentionally creates one example of every public element/API.
local Aurora = loadstring(game:HttpGet("https://raw.githubusercontent.com/emirontop1/luau/main/src/Aurora.lua"))()

Aurora:RegisterTheme("Crimson", {
    Background = Color3.fromRGB(28, 10, 16),
    Surface = Color3.fromRGB(44, 18, 28),
    SurfaceLight = Color3.fromRGB(66, 26, 42),
    Accent = Color3.fromRGB(244, 63, 94),
    AccentDark = Color3.fromRGB(190, 18, 60),
    Text = Color3.fromRGB(255, 241, 242),
    Muted = Color3.fromRGB(253, 164, 175),
    Success = Color3.fromRGB(74, 222, 128),
    Danger = Color3.fromRGB(248, 113, 113),
})

local Window = Aurora:CreateWindow({
    Title = "Aurora Full Test",
    Name = "AuroraFullElementTest",
    Theme = "Aurora",
    Size = UDim2.new(0, 680, 0, 460),
    SaveConfig = true,
    ConfigFolder = "AuroraTest",
    ConfigName = "all-elements",
})

local Elements = Window:AddTab("Elements")
local ThemeTab = Window:AddTab("Themes")
local Runtime = Window:AddTab("Runtime")

local Basic = Elements:AddSection("Basic Elements")
local Label = Basic:AddLabel("Label: ready")
local Paragraph = Basic:AddParagraph("Paragraph", "This smoke test creates every Aurora element once.")
Basic:AddDivider("Actions")
Basic:AddButton({
    Text = "Update label and notify",
    Callback = function()
        Label:Set("Label: button clicked")
        Paragraph:Set("Paragraph updated from button callback.")
        Window:Notify({ Title = "Button", Text = "Button callback ran" })
    end,
})

local Form = Elements:AddSection("Inputs")
local Toggle = Form:AddToggle({ Text = "Toggle", Default = true, Flag = "toggle", Save = true, Callback = function(value) print("toggle", value) end })
local Slider = Form:AddSlider({ Text = "Slider", Min = 0, Max = 100, Default = 25, Flag = "slider", Save = true, Callback = function(value) print("slider", value) end })
local Textbox = Form:AddTextbox({ Placeholder = "Textbox", Default = "hello", SubmitOnFocusLost = true, Flag = "textbox", Save = true, Callback = function(text) print("textbox", text) end })
local Dropdown = Form:AddDropdown({ Text = "Dropdown", Values = { "One", "Two", "Three" }, Default = "One", Flag = "dropdown", Save = true, Callback = function(value) print("dropdown", value) end })
local Progress = Form:AddProgress({ Text = "Progress", Default = 40, Flag = "progress", Save = true, Callback = function(value) print("progress", value) end })
local Keybind = Form:AddKeybind({ Text = "Keybind", Default = Enum.KeyCode.RightShift, Flag = "keybind", Save = true, Pressed = function() Window:Notify({ Title = "Keybind", Text = "RightShift pressed" }) end })
local Color = Form:AddColorPicker({ Text = "Accent Color", Flag = "accent", Save = true, Callback = function(color) Window:SetAccent(color) end })

local Themes = ThemeTab:AddSection("Theme API")
Themes:AddDropdown({
    Text = "SetTheme",
    Values = { "Aurora", "Dark", "Midnight", "Emerald", "Crimson" },
    Default = "Aurora",
    Callback = function(theme)
        Window:SetTheme(theme)
    end,
})
Themes:AddButton({ Text = "SetAccent Blue", Callback = function() Window:SetAccent(Color3.fromRGB(59, 130, 246)) end })
Themes:AddButton({ Text = "SetAccent Pink", Callback = function() Window:SetAccent(Color3.fromRGB(236, 72, 153)) end })
Themes:AddColorPicker({ Text = "ColorPicker", Callback = function(color) Window:SetAccent(color) end })

local RuntimeSection = Runtime:AddSection("Runtime Handles")
RuntimeSection:AddButton({
    Text = "Set every handle",
    Callback = function()
        Toggle:Set(false)
        Slider:Set(75)
        Textbox:Set("set from runtime")
        Dropdown:Set("Three")
        Progress:Set(90)
        Keybind:Set(Enum.KeyCode.K)
        Color:Set(Color3.fromRGB(52, 211, 153))
        Window:Notify({ Title = "Runtime", Text = "All handles updated with :Set" })
    end,
})
RuntimeSection:AddDivider()
RuntimeSection:AddButton({ Text = "Save Config Now", Callback = function() Window:SaveConfigNow() end })
RuntimeSection:AddButton({ Text = "Load Config Now", Callback = function() Window:LoadConfigNow() end })
RuntimeSection:AddLabel("Destroy test is available below.")
RuntimeSection:AddButton({ Text = "Destroy Window", Callback = function() Window:Destroy() end })
