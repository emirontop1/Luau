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

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

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

local function create(className, properties, children)
    local instance = Instance.new(className)
    for key, value in pairs(properties or {}) do
        instance[key] = value
    end
    for _, child in ipairs(children or {}) do
        child.Parent = instance
    end
    return instance
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
    elseif self.Type == "Label" or self.Type == "Paragraph" then
        self.Label.Text = tostring(value or "")
    end
    return self
end

function Element:Destroy()
    if self.Instance then
        self.Instance:Destroy()
    end
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
    return setmetatable({ Type = "Label", Instance = label, Label = label }, Element)
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
    return setmetatable({ Type = "Paragraph", Instance = frame, Label = body }, Element)
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
    return setmetatable({ Type = "Button", Instance = button }, Element)
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
    local element = setmetatable({ Type = "Toggle", Instance = frame, Value = false, Callback = options.Callback or noop, Track = track, Knob = knob }, Element)
    track.MouseButton1Click:Connect(function() element:Set(not element.Value) end)
    if options.Default ~= nil then element:Set(options.Default) end
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
    local element = setmetatable({ Type = "Slider", Instance = frame, Min = min, Max = max, Value = min, Callback = options.Callback or noop, Fill = fill, ValueLabel = valueLabel }, Element)
    local function updateFromX(x)
        local alpha = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        element:Set(min + (max - min) * alpha)
    end
    bar.MouseButton1Down:Connect(function() if Mouse then updateFromX(Mouse.X) end end)
    if options.Default ~= nil then element:Set(options.Default) end
    return element
end

function Section:AddTextbox(options)
    options = options or {}
    local box = create("TextBox", { Name = options.Name or "Textbox", BackgroundColor3 = Aurora.Theme.SurfaceLight, ClearTextOnFocus = false, PlaceholderText = options.Placeholder or "Type here...", Size = UDim2.new(1, 0, 0, 40), Font = Enum.Font.Gotham, Text = options.Default or "", TextColor3 = Aurora.Theme.Text, PlaceholderColor3 = Aurora.Theme.Muted, TextSize = 14 }, { corner(10), padding(10) })
    box.FocusLost:Connect(function(enterPressed) if enterPressed or options.SubmitOnFocusLost then safe(options.Callback or noop, box.Text) end end)
    box.Parent = self.Container
    return setmetatable({ Type = "Textbox", Instance = box, Box = box, Value = box.Text, Callback = options.Callback or noop }, Element)
end

function Section:AddDropdown(options)
    options = options or {}
    local values = options.Values or {}
    local button = create("TextButton", { Name = options.Name or "Dropdown", AutoButtonColor = false, BackgroundColor3 = Aurora.Theme.SurfaceLight, Size = UDim2.new(1, 0, 0, 40), Font = Enum.Font.GothamMedium, Text = options.Text or options.Name or "Dropdown", TextColor3 = Aurora.Theme.Text, TextSize = 14 }, { corner(10) })
    local index = 0
    local element = setmetatable({ Type = "Dropdown", Instance = button, Button = button, Title = button.Text, Value = nil, Callback = options.Callback or noop }, Element)
    button.MouseButton1Click:Connect(function()
        if #values == 0 then return end
        index = (index % #values) + 1
        element:Set(values[index])
    end)
    button.Parent = self.Container
    if options.Default ~= nil then element:Set(options.Default) end
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

    local window = setmetatable({ Gui = gui, Root = root, Nav = nav, Pages = pages, Tabs = {}, CurrentTab = nil }, Aurora)
    close.MouseButton1Click:Connect(function() window:Destroy() end)
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

function Aurora:Destroy()
    if self.Gui then
        self.Gui:Destroy()
    end
end

return Aurora
