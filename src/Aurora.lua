--!strict
-- Aurora UI Library for Roblox/Luau
-- A small, dependency-free GUI library with safe fallbacks and chainable elements.

local Aurora = {}
Aurora.__index = Aurora
Aurora.Version = "1.0.0"
Aurora.Theme = {
    Background = Color3.fromRGB(18, 18, 24),
    Surface = Color3.fromRGB(27, 29, 38),
    SurfaceLight = Color3.fromRGB(36, 39, 51),
    Accent = Color3.fromRGB(121, 91, 255),
    AccentDark = Color3.fromRGB(89, 65, 209),
    Text = Color3.fromRGB(245, 247, 255),
    Muted = Color3.fromRGB(158, 164, 184),
    Success = Color3.fromRGB(72, 199, 142),
    Danger = Color3.fromRGB(255, 91, 91),
}

Aurora.Themes = {
    Aurora = Aurora.Theme,
    Dark = {
        Background = Color3.fromRGB(14, 15, 20), Surface = Color3.fromRGB(24, 26, 34), SurfaceLight = Color3.fromRGB(34, 37, 48),
        Accent = Color3.fromRGB(121, 91, 255), AccentDark = Color3.fromRGB(89, 65, 209), Text = Color3.fromRGB(245, 247, 255),
        Muted = Color3.fromRGB(158, 164, 184), Success = Color3.fromRGB(72, 199, 142), Danger = Color3.fromRGB(255, 91, 91),
    },
    Midnight = {
        Background = Color3.fromRGB(8, 12, 24), Surface = Color3.fromRGB(13, 20, 36), SurfaceLight = Color3.fromRGB(23, 33, 55),
        Accent = Color3.fromRGB(71, 149, 255), AccentDark = Color3.fromRGB(36, 97, 194), Text = Color3.fromRGB(238, 246, 255),
        Muted = Color3.fromRGB(137, 155, 181), Success = Color3.fromRGB(68, 201, 158), Danger = Color3.fromRGB(255, 99, 132),
    },
    Emerald = {
        Background = Color3.fromRGB(9, 18, 16), Surface = Color3.fromRGB(15, 32, 28), SurfaceLight = Color3.fromRGB(23, 48, 41),
        Accent = Color3.fromRGB(52, 211, 153), AccentDark = Color3.fromRGB(16, 185, 129), Text = Color3.fromRGB(235, 255, 249),
        Muted = Color3.fromRGB(145, 181, 171), Success = Color3.fromRGB(52, 211, 153), Danger = Color3.fromRGB(251, 113, 133),
    },
}

Aurora._Windows = {}
Aurora.Flags = {}

local function cloneTheme(theme)
    local copy = {}
    for key, value in pairs(theme or Aurora.Theme) do
        copy[key] = value
    end
    return copy
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer and LocalPlayer:GetMouse()

local function noop() end

local function safe(callback, ...)
    local ok, result = pcall(callback, ...)
    if not ok then
        warn("[Aurora] callback error:", result)
    end
    return ok, result
end

local function hasExecutorFileSystem()
    return typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfile) == "function"
end

local function serializeValue(value)
    if typeof(value) == "Color3" then
        return { Type = "Color3", R = math.floor(value.R * 255), G = math.floor(value.G * 255), B = math.floor(value.B * 255) }
    end
    if typeof(value) == "EnumItem" then
        return { Type = "EnumItem", EnumType = tostring(value.EnumType), Name = value.Name }
    end
    return value
end

local function deserializeValue(value)
    if type(value) ~= "table" then
        return value
    end
    if value.Type == "Color3" then
        return Color3.fromRGB(value.R or 255, value.G or 255, value.B or 255)
    end
    if value.Type == "EnumItem" and value.EnumType == "Enum.KeyCode" then
        return Enum.KeyCode[value.Name]
    end
    return value
end

local function create(className, properties, children)
    local instance = Instance.new(className)
    for key, value in pairs(properties or {}) do
        if key == "ThemeMap" then
            for propertyName, tokenName in pairs(value) do
                instance:SetAttribute("AuroraTheme_" .. propertyName, tokenName)
            end
        else
            instance[key] = value
        end
    end
    for _, child in ipairs(children or {}) do
        child.Parent = instance
    end
    return instance
end

local function inferThemeToken(value)
    for tokenName, tokenValue in pairs(Aurora.Theme) do
        if typeof(tokenValue) == "Color3" and tokenValue == value then
            return tokenName
        end
    end
    for _, preset in pairs(Aurora.Themes) do
        for tokenName, tokenValue in pairs(preset) do
            if typeof(tokenValue) == "Color3" and tokenValue == value then
                return tokenName
            end
        end
    end
    return nil
end

local function applyThemeTo(root, theme)
    local themedProperties = { "BackgroundColor3", "TextColor3", "ImageColor3", "ScrollBarImageColor3", "PlaceholderColor3" }
    for _, instance in ipairs(root:GetDescendants()) do
        for _, propertyName in ipairs(themedProperties) do
            local tokenName = instance:GetAttribute("AuroraTheme_" .. propertyName)
            if not tokenName then
                pcall(function()
                    tokenName = inferThemeToken(instance[propertyName])
                end)
                if tokenName then
                    instance:SetAttribute("AuroraTheme_" .. propertyName, tokenName)
                end
            end
            if tokenName and theme[tokenName] then
                pcall(function() instance[propertyName] = theme[tokenName] end)
            end
        end
        if instance:IsA("UIStroke") then
            local tokenName = instance:GetAttribute("AuroraTheme_Color") or inferThemeToken(instance.Color)
            if tokenName then
                instance:SetAttribute("AuroraTheme_Color", tokenName)
            end
            if tokenName and theme[tokenName] then
                instance.Color = theme[tokenName]
            end
        end
    end
end

local function corner(radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
end

local function stroke(color, transparency)
    return create("UIStroke", {
        Color = color or Aurora.Theme.SurfaceLight,
        Transparency = transparency or 0.35,
        Thickness = 1,
    })
end

local function padding(all)
    return create("UIPadding", {
        PaddingTop = UDim.new(0, all),
        PaddingBottom = UDim.new(0, all),
        PaddingLeft = UDim.new(0, all),
        PaddingRight = UDim.new(0, all),
    })
end

local function tween(instance, time, properties)
    TweenService:Create(instance, TweenInfo.new(time or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties):Play()
end

local function makeDraggable(handle, target)
    local dragging = false
    local dragStart
    local startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local Element = {}
Element.__index = Element

function Element:Set(value)
    if self.Type == "Toggle" then
        self.Value = not not value
        self.Knob.Position = self.Value and UDim2.new(1, -22, 0.5, -9) or UDim2.new(0, 4, 0.5, -9)
        self.Track.BackgroundColor3 = self.Value and Aurora.Theme.Accent or Aurora.Theme.SurfaceLight
        safe(self.Callback, self.Value)
    elseif self.Type == "Slider" then
        local clamped = math.clamp(tonumber(value) or self.Min, self.Min, self.Max)
        self.Value = clamped
        local alpha = (clamped - self.Min) / (self.Max - self.Min)
        self.Fill.Size = UDim2.new(alpha, 0, 1, 0)
        self.ValueLabel.Text = tostring(math.floor(clamped * 100) / 100)
        safe(self.Callback, clamped)
    elseif self.Type == "Textbox" then
        self.Value = tostring(value or "")
        self.Box.Text = self.Value
        safe(self.Callback, self.Value)
    elseif self.Type == "Dropdown" then
        self.Value = value
        self.Button.Text = self.Title .. ": " .. tostring(value)
        safe(self.Callback, value)
    elseif self.Type == "Progress" then
        local clamped = math.clamp(tonumber(value) or 0, 0, 100)
        self.Value = clamped
        self.Fill.Size = UDim2.new(clamped / 100, 0, 1, 0)
        self.ValueLabel.Text = tostring(math.floor(clamped)) .. "%"
        safe(self.Callback, clamped)
    elseif self.Type == "Keybind" then
        self.Value = value
        self.Button.Text = self.Title .. ": " .. tostring(value and value.Name or "None")
        safe(self.Callback, value)
    elseif self.Type == "ColorPicker" then
        self.Value = value
        self.Swatch.BackgroundColor3 = value
        safe(self.Callback, value)
    elseif self.Type == "Label" or self.Type == "Paragraph" then
        self.Label.Text = tostring(value or "")
    end
    if self.Flag then
        Aurora.Flags[self.Flag] = self
        if self.Window and self.Save and not self.Window._LoadingConfig then
            self.Window:_SaveConfig()
        end
    end
    return self
end

function Element:Destroy()
    if self.Instance then
        self.Instance:Destroy()
    end
end

function Element:Bind(flag, save)
    self.Flag = flag
    self.Save = save ~= false
    Aurora.Flags[flag] = self
    if self.Window then
        self.Window:_RegisterElement(self)
    end
    return self
end

local Section = {}
Section.__index = Section

function Section:AddLabel(text)
    local label = create("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 24),
        Font = Enum.Font.GothamMedium,
        Text = text or "Label",
        TextColor3 = Aurora.Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    label.Parent = self.Container
    return setmetatable({ Type = "Label", Instance = label, Label = label, Window = self.Window }, Element)
end

function Section:AddParagraph(title, text)
    local frame = create("Frame", {
        Name = "Paragraph",
        BackgroundColor3 = Aurora.Theme.SurfaceLight,
        Size = UDim2.new(1, 0, 0, 76),
    }, { corner(10), padding(10) })
    local body = create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.Gotham,
        Text = string.format("%s\n%s", title or "Info", text or ""),
        TextColor3 = Aurora.Theme.Text,
        TextSize = 13,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
    })
    body.Parent = frame
    frame.Parent = self.Container
    return setmetatable({ Type = "Paragraph", Instance = frame, Label = body, Window = self.Window }, Element)
end

function Section:AddButton(options)
    options = options or {}
    local button = create("TextButton", {
        Name = options.Name or "Button",
        AutoButtonColor = false,
        BackgroundColor3 = Aurora.Theme.Accent,
        Size = UDim2.new(1, 0, 0, 38),
        Font = Enum.Font.GothamSemibold,
        Text = options.Text or options.Name or "Button",
        TextColor3 = Aurora.Theme.Text,
        TextSize = 14,
    }, { corner(10) })
    button.MouseEnter:Connect(function() tween(button, 0.12, { BackgroundColor3 = Aurora.Theme.AccentDark }) end)
    button.MouseLeave:Connect(function() tween(button, 0.12, { BackgroundColor3 = Aurora.Theme.Accent }) end)
    button.MouseButton1Click:Connect(function() safe(options.Callback or noop) end)
    button.Parent = self.Container
    return setmetatable({ Type = "Button", Instance = button, Window = self.Window }, Element)
end

function Section:AddToggle(options)
    options = options or {}
    local frame = create("Frame", { Name = options.Name or "Toggle", BackgroundColor3 = Aurora.Theme.SurfaceLight, Size = UDim2.new(1, 0, 0, 42) }, { corner(10), padding(10) })
    local label = create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -58, 1, 0), Font = Enum.Font.GothamMedium, Text = options.Text or options.Name or "Toggle", TextColor3 = Aurora.Theme.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left })
    local track = create("TextButton", { AutoButtonColor = false, BackgroundColor3 = Aurora.Theme.SurfaceLight, Position = UDim2.new(1, -48, 0.5, -13), Size = UDim2.new(0, 48, 0, 26), Text = "" }, { corner(13) })
    local knob = create("Frame", { BackgroundColor3 = Color3.fromRGB(255, 255, 255), Position = UDim2.new(0, 4, 0.5, -9), Size = UDim2.new(0, 18, 0, 18) }, { corner(9) })
    knob.Parent = track
    label.Parent = frame
    track.Parent = frame
    frame.Parent = self.Container
    local element = setmetatable({ Type = "Toggle", Instance = frame, Value = false, Callback = options.Callback or noop, Track = track, Knob = knob, Window = self.Window, Flag = options.Flag, Save = options.Save }, Element)
    track.MouseButton1Click:Connect(function() element:Set(not element.Value) end)
    self.Window:_RegisterElement(element)
    if options.Default ~= nil and element.Value == false then element:Set(options.Default) end
    return element
end

function Section:AddSlider(options)
    options = options or {}
    local min, max = options.Min or 0, options.Max or 100
    local frame = create("Frame", { Name = options.Name or "Slider", BackgroundColor3 = Aurora.Theme.SurfaceLight, Size = UDim2.new(1, 0, 0, 58) }, { corner(10), padding(10) })
    local label = create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -64, 0, 20), Font = Enum.Font.GothamMedium, Text = options.Text or options.Name or "Slider", TextColor3 = Aurora.Theme.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left })
    local valueLabel = create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(1, -60, 0, 0), Size = UDim2.new(0, 60, 0, 20), Font = Enum.Font.Gotham, Text = tostring(options.Default or min), TextColor3 = Aurora.Theme.Muted, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right })
    local bar = create("TextButton", { AutoButtonColor = false, BackgroundColor3 = Aurora.Theme.Background, Position = UDim2.new(0, 0, 1, -18), Size = UDim2.new(1, 0, 0, 8), Text = "" }, { corner(4) })
    local fill = create("Frame", { BackgroundColor3 = Aurora.Theme.Accent, Size = UDim2.new(0, 0, 1, 0) }, { corner(4) })
    fill.Parent = bar
    label.Parent = frame; valueLabel.Parent = frame; bar.Parent = frame; frame.Parent = self.Container
    local element = setmetatable({ Type = "Slider", Instance = frame, Min = min, Max = max, Value = min, Callback = options.Callback or noop, Fill = fill, ValueLabel = valueLabel, Window = self.Window, Flag = options.Flag, Save = options.Save }, Element)
    local function updateFromX(x)
        local alpha = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        element:Set(min + (max - min) * alpha)
    end
    bar.MouseButton1Down:Connect(function() if Mouse then updateFromX(Mouse.X) end end)
    self.Window:_RegisterElement(element)
    if options.Default ~= nil and element.Value == min then element:Set(options.Default) end
    return element
end

function Section:AddTextbox(options)
    options = options or {}
    local box = create("TextBox", { Name = options.Name or "Textbox", BackgroundColor3 = Aurora.Theme.SurfaceLight, ClearTextOnFocus = false, PlaceholderText = options.Placeholder or "Type here...", Size = UDim2.new(1, 0, 0, 40), Font = Enum.Font.Gotham, Text = options.Default or "", TextColor3 = Aurora.Theme.Text, PlaceholderColor3 = Aurora.Theme.Muted, TextSize = 14 }, { corner(10), padding(10) })
    box.FocusLost:Connect(function(enterPressed) if enterPressed or options.SubmitOnFocusLost then safe(options.Callback or noop, box.Text) end end)
    box.Parent = self.Container
    local element = setmetatable({ Type = "Textbox", Instance = box, Box = box, Value = box.Text, Callback = options.Callback or noop, Window = self.Window, Flag = options.Flag, Save = options.Save }, Element)
    self.Window:_RegisterElement(element)
    return element
end

function Section:AddDropdown(options)
    options = options or {}
    local values = options.Values or {}
    local button = create("TextButton", { Name = options.Name or "Dropdown", AutoButtonColor = false, BackgroundColor3 = Aurora.Theme.SurfaceLight, Size = UDim2.new(1, 0, 0, 40), Font = Enum.Font.GothamMedium, Text = options.Text or options.Name or "Dropdown", TextColor3 = Aurora.Theme.Text, TextSize = 14 }, { corner(10) })
    local index = 0
    local element = setmetatable({ Type = "Dropdown", Instance = button, Button = button, Title = button.Text, Value = nil, Callback = options.Callback or noop, Window = self.Window, Flag = options.Flag, Save = options.Save }, Element)
    button.MouseButton1Click:Connect(function()
        if #values == 0 then return end
        index = (index % #values) + 1
        element:Set(values[index])
    end)
    button.Parent = self.Container
    self.Window:_RegisterElement(element)
    if options.Default ~= nil and element.Value == nil then element:Set(options.Default) end
    return element
end

function Section:AddDivider(text)
    local frame = create("Frame", { Name = "Divider", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, text and 28 or 14) })
    local line = create("Frame", { BackgroundColor3 = Aurora.Theme.SurfaceLight, Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(1, 0, 0, 1) })
    line.Parent = frame
    if text then
        local label = create("TextLabel", { BackgroundColor3 = Aurora.Theme.Background, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0, 160, 1, 0), Font = Enum.Font.GothamBold, Text = "  " .. text .. "  ", TextColor3 = Aurora.Theme.Muted, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left })
        label.Parent = frame
    end
    frame.Parent = self.Container
    return setmetatable({ Type = "Divider", Instance = frame, Window = self.Window }, Element)
end

function Section:AddProgress(options)
    options = options or {}
    local frame = create("Frame", { Name = options.Name or "Progress", BackgroundColor3 = Aurora.Theme.SurfaceLight, Size = UDim2.new(1, 0, 0, 54) }, { corner(10), padding(10) })
    local label = create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -64, 0, 20), Font = Enum.Font.GothamMedium, Text = options.Text or options.Name or "Progress", TextColor3 = Aurora.Theme.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left })
    local valueLabel = create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(1, -60, 0, 0), Size = UDim2.new(0, 60, 0, 20), Font = Enum.Font.Gotham, Text = "0%", TextColor3 = Aurora.Theme.Muted, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right })
    local bar = create("Frame", { BackgroundColor3 = Aurora.Theme.Background, Position = UDim2.new(0, 0, 1, -16), Size = UDim2.new(1, 0, 0, 8) }, { corner(4) })
    local fill = create("Frame", { BackgroundColor3 = Aurora.Theme.Accent, Size = UDim2.new(0, 0, 1, 0) }, { corner(4) })
    fill.Parent = bar
    label.Parent = frame; valueLabel.Parent = frame; bar.Parent = frame; frame.Parent = self.Container
    local element = setmetatable({ Type = "Progress", Instance = frame, Fill = fill, ValueLabel = valueLabel, Value = 0, Callback = options.Callback or noop, Window = self.Window, Flag = options.Flag, Save = options.Save }, Element)
    self.Window:_RegisterElement(element)
    if element.Value == 0 then element:Set(options.Default or 0) end
    return element
end

function Section:AddKeybind(options)
    options = options or {}
    local button = create("TextButton", { Name = options.Name or "Keybind", AutoButtonColor = false, BackgroundColor3 = Aurora.Theme.SurfaceLight, Size = UDim2.new(1, 0, 0, 40), Font = Enum.Font.GothamMedium, Text = (options.Text or options.Name or "Keybind") .. ": " .. tostring((options.Default and options.Default.Name) or "None"), TextColor3 = Aurora.Theme.Text, TextSize = 14 }, { corner(10) })
    button.Parent = self.Container
    local element = setmetatable({ Type = "Keybind", Instance = button, Button = button, Title = options.Text or options.Name or "Keybind", Value = options.Default, Callback = options.Callback or noop, Pressed = options.Pressed or noop, Window = self.Window, Flag = options.Flag, Save = options.Save }, Element)
    local waiting = false
    button.MouseButton1Click:Connect(function()
        waiting = true
        button.Text = element.Title .. ": press a key..."
    end)
    self.Window:_RegisterElement(element)
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if waiting then
            waiting = false
            element:Set(input.KeyCode)
        elseif element.Value and input.KeyCode == element.Value then
            safe(element.Pressed, input.KeyCode)
        end
    end)
    return element
end

function Section:AddColorPicker(options)
    options = options or {}
    local colors = options.Colors or { Color3.fromRGB(121, 91, 255), Color3.fromRGB(236, 72, 153), Color3.fromRGB(52, 211, 153), Color3.fromRGB(71, 149, 255), Color3.fromRGB(251, 113, 133) }
    local frame = create("Frame", { Name = options.Name or "ColorPicker", BackgroundColor3 = Aurora.Theme.SurfaceLight, Size = UDim2.new(1, 0, 0, 42) }, { corner(10), padding(10) })
    local label = create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -52, 1, 0), Font = Enum.Font.GothamMedium, Text = options.Text or options.Name or "Color", TextColor3 = Aurora.Theme.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left })
    local swatch = create("TextButton", { AutoButtonColor = false, BackgroundColor3 = options.Default or colors[1], Position = UDim2.new(1, -36, 0.5, -14), Size = UDim2.new(0, 28, 0, 28), Text = "" }, { corner(14), stroke(Color3.fromRGB(255, 255, 255), 0.4) })
    label.Parent = frame; swatch.Parent = frame; frame.Parent = self.Container
    local index = 1
    local element = setmetatable({ Type = "ColorPicker", Instance = frame, Swatch = swatch, Value = options.Default or colors[1], Callback = options.Callback or noop, Window = self.Window, Flag = options.Flag, Save = options.Save }, Element)
    self.Window:_RegisterElement(element)
    swatch.MouseButton1Click:Connect(function()
        index = (index % #colors) + 1
        element:Set(colors[index])
    end)
    return element
end

local Tab = {}
Tab.__index = Tab

function Tab:AddSection(name)
    local title = create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), Font = Enum.Font.GothamBold, Text = name or "Section", TextColor3 = Aurora.Theme.Muted, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
    local container = create("Frame", { Name = name or "Section", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y }, {
        create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
    })
    title.Parent = self.Page
    container.Parent = self.Page
    return setmetatable({ Window = self.Window, Container = container }, Section)
end

function Aurora:CreateWindow(options)
    options = options or {}
    local gui = create("ScreenGui", { Name = options.Name or "AuroraUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
    gui.Parent = options.Parent or CoreGui

    local root = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Aurora.Theme.Background, Position = UDim2.new(0.5, 0, 0.5, 0), Size = options.Size or UDim2.new(0, 620, 0, 420) }, { corner(16), stroke(Aurora.Theme.Accent, 0.45) })
    local topbar = create("Frame", { BackgroundColor3 = Aurora.Theme.Surface, Size = UDim2.new(1, 0, 0, 54) }, { corner(16) })
    local title = create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 18, 0, 0), Size = UDim2.new(1, -90, 1, 0), Font = Enum.Font.GothamBold, Text = options.Title or "Aurora UI", TextColor3 = Aurora.Theme.Text, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left })
    local close = create("TextButton", { AutoButtonColor = false, BackgroundColor3 = Aurora.Theme.Danger, Position = UDim2.new(1, -42, 0.5, -14), Size = UDim2.new(0, 28, 0, 28), Font = Enum.Font.GothamBold, Text = "×", TextColor3 = Aurora.Theme.Text, TextSize = 18 }, { corner(14) })
    local nav = create("Frame", { BackgroundColor3 = Aurora.Theme.Surface, Position = UDim2.new(0, 14, 0, 68), Size = UDim2.new(0, 150, 1, -82) }, { corner(12), padding(8), create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })
    local pages = create("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 178, 0, 68), Size = UDim2.new(1, -192, 1, -82) })

    title.Parent = topbar; close.Parent = topbar; topbar.Parent = root; nav.Parent = root; pages.Parent = root; root.Parent = gui
    makeDraggable(topbar, root)

    local window = setmetatable({ Gui = gui, Root = root, Nav = nav, Pages = pages, Tabs = {}, CurrentTab = nil, Theme = cloneTheme(Aurora.Themes[options.Theme or "Aurora"] or Aurora.Theme), Flags = {}, SaveConfig = options.SaveConfig == true, ConfigFolder = options.ConfigFolder or "Aurora", ConfigName = options.ConfigName or options.Name or "default", _Config = {}, _LoadingConfig = false }, Aurora)
    table.insert(Aurora._Windows, window)
    window:_LoadConfig()
    close.MouseButton1Click:Connect(function() window:Destroy() end)
    window:SetTheme(window.Theme)
    return window
end

function Aurora:AddTab(name)
    local page = create("ScrollingFrame", { Name = name or "Tab", Active = true, BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarImageColor3 = Aurora.Theme.Accent, ScrollBarThickness = 4, Size = UDim2.new(1, 0, 1, 0), Visible = false }, {
        create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
    })
    local button = create("TextButton", { AutoButtonColor = false, BackgroundColor3 = Aurora.Theme.SurfaceLight, Size = UDim2.new(1, 0, 0, 36), Font = Enum.Font.GothamSemibold, Text = name or "Tab", TextColor3 = Aurora.Theme.Text, TextSize = 14 }, { corner(10) })
    page.Parent = self.Pages
    button.Parent = self.Nav
    local tab = setmetatable({ Window = self, Page = page, Button = button }, Tab)
    table.insert(self.Tabs, tab)
    button.MouseButton1Click:Connect(function() self:SelectTab(tab) end)
    if not self.CurrentTab then self:SelectTab(tab) end
    return tab
end

function Aurora:SelectTab(tab)
    for _, item in ipairs(self.Tabs) do
        item.Page.Visible = item == tab
        tween(item.Button, 0.12, { BackgroundColor3 = item == tab and Aurora.Theme.Accent or Aurora.Theme.SurfaceLight })
    end
    self.CurrentTab = tab
end

function Aurora:Notify(options)
    options = options or {}
    local notice = create("TextLabel", { AnchorPoint = Vector2.new(1, 1), BackgroundColor3 = Aurora.Theme.Surface, Position = UDim2.new(1, -18, 1, -18), Size = UDim2.new(0, 260, 0, 62), Font = Enum.Font.GothamMedium, Text = (options.Title or "Aurora") .. "\n" .. (options.Text or "Notification"), TextColor3 = Aurora.Theme.Text, TextSize = 14, TextWrapped = true }, { corner(12), stroke(Aurora.Theme.Accent, 0.35), padding(10) })
    notice.Parent = self.Gui
    task.delay(options.Duration or 3, function()
        if notice.Parent then
            tween(notice, 0.2, { TextTransparency = 1, BackgroundTransparency = 1 })
            task.wait(0.22)
            notice:Destroy()
        end
    end)
end


function Aurora:_ConfigPath()
    return string.format("%s/%s.json", self.ConfigFolder or "Aurora", self.ConfigName or "default")
end

function Aurora:_LoadConfig()
    if not self.SaveConfig or not hasExecutorFileSystem() then
        return self
    end
    local path = self:_ConfigPath()
    if isfile(path) then
        local ok, decoded = pcall(function()
            return HttpService:JSONDecode(readfile(path))
        end)
        if ok and type(decoded) == "table" then
            self._Config = decoded
        end
    end
    return self
end

function Aurora:_SaveConfig()
    if not self.SaveConfig or not hasExecutorFileSystem() then
        return self
    end
    local payload = {}
    for flag, element in pairs(self.Flags or {}) do
        if element.Save ~= false then
            payload[flag] = serializeValue(element.Value)
        end
    end
    pcall(function()
        if typeof(makefolder) == "function" and typeof(isfolder) == "function" and not isfolder(self.ConfigFolder) then
            makefolder(self.ConfigFolder)
        end
        writefile(self:_ConfigPath(), HttpService:JSONEncode(payload))
    end)
    return self
end

function Aurora:_RegisterElement(element)
    if not element or not element.Flag then
        return element
    end
    self.Flags[element.Flag] = element
    Aurora.Flags[element.Flag] = element
    if self._Config and self._Config[element.Flag] ~= nil then
        self._LoadingConfig = true
        element:Set(deserializeValue(self._Config[element.Flag]))
        self._LoadingConfig = false
    end
    return element
end

function Aurora:SaveConfigNow()
    return self:_SaveConfig()
end

function Aurora:LoadConfigNow()
    self:_LoadConfig()
    for flag, element in pairs(self.Flags or {}) do
        if self._Config[flag] ~= nil then
            self._LoadingConfig = true
            element:Set(deserializeValue(self._Config[flag]))
            self._LoadingConfig = false
        end
    end
    return self
end

function Aurora:RegisterTheme(name, theme)
    Aurora.Themes[name] = cloneTheme(theme)
    return self
end

function Aurora:SetTheme(theme)
    local nextTheme = type(theme) == "string" and Aurora.Themes[theme] or theme
    if not nextTheme then
        warn("[Aurora] unknown theme:", theme)
        return self
    end
    self.Theme = cloneTheme(nextTheme)
    if self.Gui then
        applyThemeTo(self.Gui, self.Theme)
    end
    return self
end

function Aurora:SetAccent(color)
    self.Theme.Accent = color
    self.Theme.AccentDark = color
    if self.Gui then
        applyThemeTo(self.Gui, self.Theme)
    end
    return self
end

function Aurora:Destroy()
    if self.Gui then
        self.Gui:Destroy()
    end
end


Aurora.MakeWindow = Aurora.CreateWindow
Aurora.Window = Aurora.CreateWindow
Tab.MakeSection = Tab.AddSection
Section.Label = Section.AddLabel
Section.Paragraph = Section.AddParagraph
Section.Button = Section.AddButton
Section.Toggle = Section.AddToggle
Section.Slider = Section.AddSlider
Section.Input = Section.AddTextbox
Section.Textbox = Section.AddTextbox
Section.Dropdown = Section.AddDropdown
Section.Divider = Section.AddDivider
Section.Progress = Section.AddProgress
Section.Bind = Section.AddKeybind
Section.Keybind = Section.AddKeybind
Section.Colorpicker = Section.AddColorPicker
Section.ColorPicker = Section.AddColorPicker

return Aurora

--[[
Aurora extended source notes:
Feature note 001: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 002: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 003: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 004: Tabs keep pages isolated and easy to find from returned references.
Feature note 005: Sections group elements so scripts stay readable.
Feature note 006: Every interactive element returns a handle with Set and Destroy methods.
Feature note 007: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 008: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 009: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 010: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 011: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 012: Tabs keep pages isolated and easy to find from returned references.
Feature note 013: Sections group elements so scripts stay readable.
Feature note 014: Every interactive element returns a handle with Set and Destroy methods.
Feature note 015: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 016: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 017: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 018: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 019: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 020: Tabs keep pages isolated and easy to find from returned references.
Feature note 021: Sections group elements so scripts stay readable.
Feature note 022: Every interactive element returns a handle with Set and Destroy methods.
Feature note 023: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 024: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 025: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 026: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 027: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 028: Tabs keep pages isolated and easy to find from returned references.
Feature note 029: Sections group elements so scripts stay readable.
Feature note 030: Every interactive element returns a handle with Set and Destroy methods.
Feature note 031: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 032: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 033: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 034: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 035: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 036: Tabs keep pages isolated and easy to find from returned references.
Feature note 037: Sections group elements so scripts stay readable.
Feature note 038: Every interactive element returns a handle with Set and Destroy methods.
Feature note 039: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 040: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 041: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 042: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 043: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 044: Tabs keep pages isolated and easy to find from returned references.
Feature note 045: Sections group elements so scripts stay readable.
Feature note 046: Every interactive element returns a handle with Set and Destroy methods.
Feature note 047: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 048: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 049: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 050: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 051: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 052: Tabs keep pages isolated and easy to find from returned references.
Feature note 053: Sections group elements so scripts stay readable.
Feature note 054: Every interactive element returns a handle with Set and Destroy methods.
Feature note 055: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 056: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 057: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 058: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 059: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 060: Tabs keep pages isolated and easy to find from returned references.
Feature note 061: Sections group elements so scripts stay readable.
Feature note 062: Every interactive element returns a handle with Set and Destroy methods.
Feature note 063: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 064: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 065: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 066: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 067: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 068: Tabs keep pages isolated and easy to find from returned references.
Feature note 069: Sections group elements so scripts stay readable.
Feature note 070: Every interactive element returns a handle with Set and Destroy methods.
Feature note 071: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 072: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 073: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 074: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 075: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 076: Tabs keep pages isolated and easy to find from returned references.
Feature note 077: Sections group elements so scripts stay readable.
Feature note 078: Every interactive element returns a handle with Set and Destroy methods.
Feature note 079: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 080: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 081: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 082: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 083: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 084: Tabs keep pages isolated and easy to find from returned references.
Feature note 085: Sections group elements so scripts stay readable.
Feature note 086: Every interactive element returns a handle with Set and Destroy methods.
Feature note 087: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 088: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 089: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 090: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 091: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 092: Tabs keep pages isolated and easy to find from returned references.
Feature note 093: Sections group elements so scripts stay readable.
Feature note 094: Every interactive element returns a handle with Set and Destroy methods.
Feature note 095: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 096: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 097: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 098: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 099: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 100: Tabs keep pages isolated and easy to find from returned references.
Feature note 101: Sections group elements so scripts stay readable.
Feature note 102: Every interactive element returns a handle with Set and Destroy methods.
Feature note 103: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 104: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 105: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 106: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 107: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 108: Tabs keep pages isolated and easy to find from returned references.
Feature note 109: Sections group elements so scripts stay readable.
Feature note 110: Every interactive element returns a handle with Set and Destroy methods.
Feature note 111: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 112: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 113: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 114: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 115: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 116: Tabs keep pages isolated and easy to find from returned references.
Feature note 117: Sections group elements so scripts stay readable.
Feature note 118: Every interactive element returns a handle with Set and Destroy methods.
Feature note 119: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 120: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 121: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 122: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 123: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 124: Tabs keep pages isolated and easy to find from returned references.
Feature note 125: Sections group elements so scripts stay readable.
Feature note 126: Every interactive element returns a handle with Set and Destroy methods.
Feature note 127: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 128: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 129: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 130: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 131: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 132: Tabs keep pages isolated and easy to find from returned references.
Feature note 133: Sections group elements so scripts stay readable.
Feature note 134: Every interactive element returns a handle with Set and Destroy methods.
Feature note 135: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 136: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 137: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 138: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 139: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 140: Tabs keep pages isolated and easy to find from returned references.
Feature note 141: Sections group elements so scripts stay readable.
Feature note 142: Every interactive element returns a handle with Set and Destroy methods.
Feature note 143: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 144: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 145: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 146: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 147: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 148: Tabs keep pages isolated and easy to find from returned references.
Feature note 149: Sections group elements so scripts stay readable.
Feature note 150: Every interactive element returns a handle with Set and Destroy methods.
Feature note 151: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 152: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 153: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 154: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 155: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 156: Tabs keep pages isolated and easy to find from returned references.
Feature note 157: Sections group elements so scripts stay readable.
Feature note 158: Every interactive element returns a handle with Set and Destroy methods.
Feature note 159: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 160: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 161: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 162: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 163: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 164: Tabs keep pages isolated and easy to find from returned references.
Feature note 165: Sections group elements so scripts stay readable.
Feature note 166: Every interactive element returns a handle with Set and Destroy methods.
Feature note 167: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 168: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 169: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 170: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 171: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 172: Tabs keep pages isolated and easy to find from returned references.
Feature note 173: Sections group elements so scripts stay readable.
Feature note 174: Every interactive element returns a handle with Set and Destroy methods.
Feature note 175: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 176: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 177: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 178: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 179: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 180: Tabs keep pages isolated and easy to find from returned references.
Feature note 181: Sections group elements so scripts stay readable.
Feature note 182: Every interactive element returns a handle with Set and Destroy methods.
Feature note 183: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 184: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 185: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 186: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 187: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 188: Tabs keep pages isolated and easy to find from returned references.
Feature note 189: Sections group elements so scripts stay readable.
Feature note 190: Every interactive element returns a handle with Set and Destroy methods.
Feature note 191: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 192: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 193: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 194: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 195: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 196: Tabs keep pages isolated and easy to find from returned references.
Feature note 197: Sections group elements so scripts stay readable.
Feature note 198: Every interactive element returns a handle with Set and Destroy methods.
Feature note 199: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 200: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 201: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 202: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 203: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 204: Tabs keep pages isolated and easy to find from returned references.
Feature note 205: Sections group elements so scripts stay readable.
Feature note 206: Every interactive element returns a handle with Set and Destroy methods.
Feature note 207: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 208: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 209: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 210: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 211: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 212: Tabs keep pages isolated and easy to find from returned references.
Feature note 213: Sections group elements so scripts stay readable.
Feature note 214: Every interactive element returns a handle with Set and Destroy methods.
Feature note 215: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 216: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 217: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 218: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 219: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 220: Tabs keep pages isolated and easy to find from returned references.
Feature note 221: Sections group elements so scripts stay readable.
Feature note 222: Every interactive element returns a handle with Set and Destroy methods.
Feature note 223: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 224: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 225: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 226: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 227: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 228: Tabs keep pages isolated and easy to find from returned references.
Feature note 229: Sections group elements so scripts stay readable.
Feature note 230: Every interactive element returns a handle with Set and Destroy methods.
Feature note 231: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 232: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 233: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 234: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 235: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 236: Tabs keep pages isolated and easy to find from returned references.
Feature note 237: Sections group elements so scripts stay readable.
Feature note 238: Every interactive element returns a handle with Set and Destroy methods.
Feature note 239: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 240: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 241: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 242: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 243: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 244: Tabs keep pages isolated and easy to find from returned references.
Feature note 245: Sections group elements so scripts stay readable.
Feature note 246: Every interactive element returns a handle with Set and Destroy methods.
Feature note 247: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 248: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 249: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 250: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 251: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 252: Tabs keep pages isolated and easy to find from returned references.
Feature note 253: Sections group elements so scripts stay readable.
Feature note 254: Every interactive element returns a handle with Set and Destroy methods.
Feature note 255: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 256: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 257: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 258: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 259: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 260: Tabs keep pages isolated and easy to find from returned references.
Feature note 261: Sections group elements so scripts stay readable.
Feature note 262: Every interactive element returns a handle with Set and Destroy methods.
Feature note 263: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 264: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 265: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 266: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 267: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 268: Tabs keep pages isolated and easy to find from returned references.
Feature note 269: Sections group elements so scripts stay readable.
Feature note 270: Every interactive element returns a handle with Set and Destroy methods.
Feature note 271: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 272: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 273: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 274: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 275: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 276: Tabs keep pages isolated and easy to find from returned references.
Feature note 277: Sections group elements so scripts stay readable.
Feature note 278: Every interactive element returns a handle with Set and Destroy methods.
Feature note 279: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 280: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 281: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 282: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 283: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 284: Tabs keep pages isolated and easy to find from returned references.
Feature note 285: Sections group elements so scripts stay readable.
Feature note 286: Every interactive element returns a handle with Set and Destroy methods.
Feature note 287: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 288: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 289: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 290: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 291: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 292: Tabs keep pages isolated and easy to find from returned references.
Feature note 293: Sections group elements so scripts stay readable.
Feature note 294: Every interactive element returns a handle with Set and Destroy methods.
Feature note 295: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 296: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 297: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 298: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 299: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 300: Tabs keep pages isolated and easy to find from returned references.
Feature note 301: Sections group elements so scripts stay readable.
Feature note 302: Every interactive element returns a handle with Set and Destroy methods.
Feature note 303: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 304: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 305: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 306: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 307: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 308: Tabs keep pages isolated and easy to find from returned references.
Feature note 309: Sections group elements so scripts stay readable.
Feature note 310: Every interactive element returns a handle with Set and Destroy methods.
Feature note 311: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 312: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 313: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 314: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 315: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 316: Tabs keep pages isolated and easy to find from returned references.
Feature note 317: Sections group elements so scripts stay readable.
Feature note 318: Every interactive element returns a handle with Set and Destroy methods.
Feature note 319: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 320: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 321: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 322: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 323: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 324: Tabs keep pages isolated and easy to find from returned references.
Feature note 325: Sections group elements so scripts stay readable.
Feature note 326: Every interactive element returns a handle with Set and Destroy methods.
Feature note 327: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 328: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 329: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 330: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 331: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 332: Tabs keep pages isolated and easy to find from returned references.
Feature note 333: Sections group elements so scripts stay readable.
Feature note 334: Every interactive element returns a handle with Set and Destroy methods.
Feature note 335: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 336: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 337: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 338: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 339: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 340: Tabs keep pages isolated and easy to find from returned references.
Feature note 341: Sections group elements so scripts stay readable.
Feature note 342: Every interactive element returns a handle with Set and Destroy methods.
Feature note 343: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 344: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 345: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 346: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 347: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 348: Tabs keep pages isolated and easy to find from returned references.
Feature note 349: Sections group elements so scripts stay readable.
Feature note 350: Every interactive element returns a handle with Set and Destroy methods.
Feature note 351: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 352: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 353: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 354: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 355: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 356: Tabs keep pages isolated and easy to find from returned references.
Feature note 357: Sections group elements so scripts stay readable.
Feature note 358: Every interactive element returns a handle with Set and Destroy methods.
Feature note 359: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 360: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 361: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 362: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 363: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 364: Tabs keep pages isolated and easy to find from returned references.
Feature note 365: Sections group elements so scripts stay readable.
Feature note 366: Every interactive element returns a handle with Set and Destroy methods.
Feature note 367: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 368: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 369: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 370: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 371: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 372: Tabs keep pages isolated and easy to find from returned references.
Feature note 373: Sections group elements so scripts stay readable.
Feature note 374: Every interactive element returns a handle with Set and Destroy methods.
Feature note 375: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 376: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 377: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 378: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 379: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 380: Tabs keep pages isolated and easy to find from returned references.
Feature note 381: Sections group elements so scripts stay readable.
Feature note 382: Every interactive element returns a handle with Set and Destroy methods.
Feature note 383: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 384: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 385: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 386: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 387: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 388: Tabs keep pages isolated and easy to find from returned references.
Feature note 389: Sections group elements so scripts stay readable.
Feature note 390: Every interactive element returns a handle with Set and Destroy methods.
Feature note 391: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 392: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 393: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 394: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 395: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 396: Tabs keep pages isolated and easy to find from returned references.
Feature note 397: Sections group elements so scripts stay readable.
Feature note 398: Every interactive element returns a handle with Set and Destroy methods.
Feature note 399: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 400: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 401: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 402: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 403: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 404: Tabs keep pages isolated and easy to find from returned references.
Feature note 405: Sections group elements so scripts stay readable.
Feature note 406: Every interactive element returns a handle with Set and Destroy methods.
Feature note 407: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 408: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 409: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 410: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 411: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 412: Tabs keep pages isolated and easy to find from returned references.
Feature note 413: Sections group elements so scripts stay readable.
Feature note 414: Every interactive element returns a handle with Set and Destroy methods.
Feature note 415: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 416: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 417: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 418: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 419: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 420: Tabs keep pages isolated and easy to find from returned references.
Feature note 421: Sections group elements so scripts stay readable.
Feature note 422: Every interactive element returns a handle with Set and Destroy methods.
Feature note 423: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 424: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 425: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 426: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 427: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 428: Tabs keep pages isolated and easy to find from returned references.
Feature note 429: Sections group elements so scripts stay readable.
Feature note 430: Every interactive element returns a handle with Set and Destroy methods.
Feature note 431: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 432: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 433: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 434: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 435: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 436: Tabs keep pages isolated and easy to find from returned references.
Feature note 437: Sections group elements so scripts stay readable.
Feature note 438: Every interactive element returns a handle with Set and Destroy methods.
Feature note 439: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 440: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 441: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 442: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 443: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 444: Tabs keep pages isolated and easy to find from returned references.
Feature note 445: Sections group elements so scripts stay readable.
Feature note 446: Every interactive element returns a handle with Set and Destroy methods.
Feature note 447: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 448: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 449: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 450: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 451: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 452: Tabs keep pages isolated and easy to find from returned references.
Feature note 453: Sections group elements so scripts stay readable.
Feature note 454: Every interactive element returns a handle with Set and Destroy methods.
Feature note 455: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 456: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 457: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 458: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 459: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 460: Tabs keep pages isolated and easy to find from returned references.
Feature note 461: Sections group elements so scripts stay readable.
Feature note 462: Every interactive element returns a handle with Set and Destroy methods.
Feature note 463: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 464: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 465: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 466: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 467: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 468: Tabs keep pages isolated and easy to find from returned references.
Feature note 469: Sections group elements so scripts stay readable.
Feature note 470: Every interactive element returns a handle with Set and Destroy methods.
Feature note 471: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 472: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 473: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 474: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 475: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 476: Tabs keep pages isolated and easy to find from returned references.
Feature note 477: Sections group elements so scripts stay readable.
Feature note 478: Every interactive element returns a handle with Set and Destroy methods.
Feature note 479: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 480: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 481: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 482: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 483: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 484: Tabs keep pages isolated and easy to find from returned references.
Feature note 485: Sections group elements so scripts stay readable.
Feature note 486: Every interactive element returns a handle with Set and Destroy methods.
Feature note 487: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 488: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 489: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 490: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 491: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 492: Tabs keep pages isolated and easy to find from returned references.
Feature note 493: Sections group elements so scripts stay readable.
Feature note 494: Every interactive element returns a handle with Set and Destroy methods.
Feature note 495: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 496: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 497: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 498: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 499: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 500: Tabs keep pages isolated and easy to find from returned references.
Feature note 501: Sections group elements so scripts stay readable.
Feature note 502: Every interactive element returns a handle with Set and Destroy methods.
Feature note 503: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 504: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 505: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 506: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 507: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 508: Tabs keep pages isolated and easy to find from returned references.
Feature note 509: Sections group elements so scripts stay readable.
Feature note 510: Every interactive element returns a handle with Set and Destroy methods.
Feature note 511: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 512: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 513: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 514: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 515: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 516: Tabs keep pages isolated and easy to find from returned references.
Feature note 517: Sections group elements so scripts stay readable.
Feature note 518: Every interactive element returns a handle with Set and Destroy methods.
Feature note 519: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 520: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 521: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 522: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 523: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 524: Tabs keep pages isolated and easy to find from returned references.
Feature note 525: Sections group elements so scripts stay readable.
Feature note 526: Every interactive element returns a handle with Set and Destroy methods.
Feature note 527: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 528: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 529: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 530: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 531: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 532: Tabs keep pages isolated and easy to find from returned references.
Feature note 533: Sections group elements so scripts stay readable.
Feature note 534: Every interactive element returns a handle with Set and Destroy methods.
Feature note 535: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 536: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 537: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 538: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 539: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 540: Tabs keep pages isolated and easy to find from returned references.
Feature note 541: Sections group elements so scripts stay readable.
Feature note 542: Every interactive element returns a handle with Set and Destroy methods.
Feature note 543: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 544: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 545: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 546: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 547: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 548: Tabs keep pages isolated and easy to find from returned references.
Feature note 549: Sections group elements so scripts stay readable.
Feature note 550: Every interactive element returns a handle with Set and Destroy methods.
Feature note 551: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 552: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 553: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 554: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 555: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 556: Tabs keep pages isolated and easy to find from returned references.
Feature note 557: Sections group elements so scripts stay readable.
Feature note 558: Every interactive element returns a handle with Set and Destroy methods.
Feature note 559: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 560: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 561: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 562: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 563: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 564: Tabs keep pages isolated and easy to find from returned references.
Feature note 565: Sections group elements so scripts stay readable.
Feature note 566: Every interactive element returns a handle with Set and Destroy methods.
Feature note 567: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 568: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 569: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 570: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 571: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 572: Tabs keep pages isolated and easy to find from returned references.
Feature note 573: Sections group elements so scripts stay readable.
Feature note 574: Every interactive element returns a handle with Set and Destroy methods.
Feature note 575: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 576: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
Feature note 577: Window creation supports Title, Name, Parent, Size, and Theme parameters.
Feature note 578: Themes can be changed at runtime with Window:SetTheme("Aurora"), Window:SetTheme("Midnight"), or Window:SetTheme(customTable).
Feature note 579: Use Window:SetAccent(Color3.fromRGB(r, g, b)) for quick accent changes.
Feature note 580: Tabs keep pages isolated and easy to find from returned references.
Feature note 581: Sections group elements so scripts stay readable.
Feature note 582: Every interactive element returns a handle with Set and Destroy methods.
Feature note 583: Callbacks are protected with pcall so user callback errors do not break the UI library.
Feature note 584: The library is dependency-free and can be loaded with loadstring(game:HttpGet(...))().
]]
