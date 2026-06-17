# Aurora Luau UI Library

Aurora is a clean, dependency-free Roblox/Luau GUI library. It includes a draggable window, tabs, sections, labels, paragraphs, buttons, toggles, sliders, textboxes, dropdowns, dividers, progress bars, keybinds, color pickers, notifications, runtime themes, flags, and optional config save/load.

## Loader

```lua
local Aurora = loadstring(game:HttpGet("https://raw.githubusercontent.com/emirontop1/luau/main/src/Aurora.lua"))()
```

## Latest Example

See [`examples/latest.lua`](examples/latest.lua) for the newest full example, and [`examples/test_all_elements.lua`](examples/test_all_elements.lua) for a smoke test that creates every public element. The GitHub Actions workflow also prints the latest example and ready-to-copy loader snippets in the workflow summary.

## Quick API

```lua
local Window = Aurora:CreateWindow({ Title = "Aurora Hub", Theme = "Midnight", SaveConfig = true, ConfigFolder = "Aurora" })
local Main = Window:AddTab("Main")
local Section = Main:AddSection("Features")

Section:AddButton({ Text = "Click", Callback = function() print("Clicked") end })
Section:AddToggle({ Text = "Enabled", Default = true, Flag = "enabled", Save = true, Callback = function(value) print(value) end })
Section:AddSlider({ Text = "Speed", Min = 16, Max = 100, Default = 24, Callback = print })
Section:AddTextbox({ Placeholder = "Input", SubmitOnFocusLost = true, Callback = print })
Section:AddDropdown({ Text = "Mode", Values = { "A", "B" }, Callback = print })
Section:AddDropdown({ Text = "Theme", Values = { "Aurora", "Dark", "Midnight", "Emerald" }, Callback = function(theme) Window:SetTheme(theme) end })
Section:AddKeybind({ Text = "Menu Key", Default = Enum.KeyCode.RightShift, Flag = "menu_key", Save = true })
Section:AddColorPicker({ Text = "Accent", Callback = function(color) Window:SetAccent(color) end })
Window:SaveConfigNow()
Window:Notify({ Title = "Aurora", Text = "Ready" })
```
