# Aurora Luau UI Library

Aurora is a clean, dependency-free Roblox/Luau GUI library. It includes a draggable window, tabs, sections, labels, paragraphs, buttons, toggles, sliders, textboxes, dropdowns, and notifications.

## Loader

```lua
local Aurora = loadstring(game:HttpGet("https://raw.githubusercontent.com/emirontop1/luau/main/src/Aurora.lua"))()
```

## Latest Example

See [`examples/latest.lua`](examples/latest.lua) for the newest full example. The GitHub Actions workflow also prints the latest example and ready-to-copy loader snippets in the workflow summary.

## Quick API

```lua
local Window = Aurora:CreateWindow({ Title = "Aurora Hub", Theme = "Midnight" })
local Main = Window:AddTab("Main")
local Section = Main:AddSection("Features")

Section:AddButton({ Text = "Click", Callback = function() print("Clicked") end })
Section:AddToggle({ Text = "Enabled", Default = true, Callback = function(value) print(value) end })
Section:AddSlider({ Text = "Speed", Min = 16, Max = 100, Default = 24, Callback = print })
Section:AddTextbox({ Placeholder = "Input", SubmitOnFocusLost = true, Callback = print })
Section:AddDropdown({ Text = "Mode", Values = { "A", "B" }, Callback = print })
Section:AddDropdown({ Text = "Theme", Values = { "Aurora", "Dark", "Midnight", "Emerald" }, Callback = function(theme) Window:SetTheme(theme) end })
Window:Notify({ Title = "Aurora", Text = "Ready" })
```
