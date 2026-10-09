-- MK442 Roblox VisualPlus v11 - interactive in-game visual controls + FPS HUD
-- Intended for YOUR OWN Roblox Studio experience only.
-- Put this file in a LocalScript under StarterPlayer > StarterPlayerScripts.
-- This does not inject into or modify the official Roblox client or other people's games.
-- Note: Motion blur is a camera-rotation approximation. Environment reflections are Roblox
-- environment specular reflections, NOT ReShade/SSR screen-space reflections.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
if not player then return end

local CONFIG = {
    MotionBlurEnabled = true,
    MotionBlurStrength = 3,
    Brightness = 0,
    Contrast = 0.05,
    Saturation = 0.1,
    Exposure = 0,
    ReflectionScale = 0.75,
    BloomIntensity = 0.5,
    BloomSize = 35,
    SunRaysIntensity = 0.05,
    DepthOfField = false,
    DepthOfFieldStrength = 0.5,
    FPSOverlayEnabled = true,
    FPSOverlayPosition = "TopLeft",
    FPSOverlaySize = 18,
    FPSOverlayColor = Color3.fromRGB(91, 255, 164),
    Tint = Color3.fromRGB(255, 255, 255),
}

local START_CONFIG = {}
for key, value in pairs(CONFIG) do START_CONFIG[key] = value end
local originalExposure = Lighting.ExposureCompensation
local originalSpecular = Lighting.EnvironmentSpecularScale
local running = true
local currentCamera = workspace.CurrentCamera
local effectsCamera = nil
local activeSlider = nil
local hudDragging = false
local hudDragOrigin = nil
local hudStartPosition = nil
local connections = {}
local sliderWidgets = {}
local hudLabel = nil
local visualScreen = nil
local panel = nil
local panelScroll = nil
local openButton = nil
local effects = {}

local function keepConnection(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end

local function clamp(number, minimum, maximum)
    return math.max(minimum, math.min(maximum, number))
end

local function addEffect(parent, className, objectName)
    local object = parent:FindFirstChild(objectName)
    if object and not object:IsA(className) then
        object:Destroy()
        object = nil
    end
    if not object then
        object = Instance.new(className)
        object.Name = objectName
    end
    object.Parent = parent
    return object
end

local function setHudPosition(positionName)
    if not hudLabel then return end
    local positions = {
        TopLeft = {anchor = Vector2.new(0, 0), position = UDim2.new(0, 12, 0, 12), align = Enum.TextXAlignment.Left},
        TopRight = {anchor = Vector2.new(1, 0), position = UDim2.new(1, -12, 0, 12), align = Enum.TextXAlignment.Right},
        BottomLeft = {anchor = Vector2.new(0, 1), position = UDim2.new(0, 12, 1, -12), align = Enum.TextXAlignment.Left},
        BottomRight = {anchor = Vector2.new(1, 1), position = UDim2.new(1, -12, 1, -12), align = Enum.TextXAlignment.Right},
    }
    local chosen = positions[positionName] or positions.TopLeft
    hudLabel.AnchorPoint = chosen.anchor
    hudLabel.Position = chosen.position
    hudLabel.TextXAlignment = chosen.align
    CONFIG.FPSOverlayPosition = positionName
end

local function setHudColor(color)
    if hudLabel then hudLabel.TextColor3 = color end
    CONFIG.FPSOverlayColor = color
end

local function applyHudStyle()
    if not hudLabel then return end
    CONFIG.FPSOverlaySize = clamp(math.floor(CONFIG.FPSOverlaySize + 0.5), 10, 32)
    hudLabel.TextSize = CONFIG.FPSOverlaySize
    hudLabel.Size = UDim2.fromOffset(math.max(106, CONFIG.FPSOverlaySize * 6), CONFIG.FPSOverlaySize + 14)
    hudLabel.Visible = CONFIG.FPSOverlayEnabled
    hudLabel.TextColor3 = CONFIG.FPSOverlayColor
end

local function removeOwnedEffects(camera)
    if not camera then return end
    for _, name in ipairs({
        "MK442_VisualPlus_MotionBlur", "MK442_VisualPlus_Color", "MK442_VisualPlus_Bloom",
        "MK442_VisualPlus_SunRays", "MK442_VisualPlus_DepthOfField"
    }) do
        local object = camera:FindFirstChild(name)
        if object then object:Destroy() end
    end
end

local function applyVisuals()
    if not running then return end
    currentCamera = workspace.CurrentCamera
    if not currentCamera then return end
    if effectsCamera and effectsCamera ~= currentCamera then
        removeOwnedEffects(effectsCamera)
    end
    effectsCamera = currentCamera

    effects.Blur = addEffect(currentCamera, "BlurEffect", "MK442_VisualPlus_MotionBlur")
    effects.Color = addEffect(currentCamera, "ColorCorrectionEffect", "MK442_VisualPlus_Color")
    effects.Bloom = addEffect(currentCamera, "BloomEffect", "MK442_VisualPlus_Bloom")
    effects.SunRays = addEffect(currentCamera, "SunRaysEffect", "MK442_VisualPlus_SunRays")
    effects.DOF = addEffect(currentCamera, "DepthOfFieldEffect", "MK442_VisualPlus_DepthOfField")

    effects.Blur.Enabled = CONFIG.MotionBlurEnabled and CONFIG.MotionBlurStrength > 0
    if not effects.Blur.Enabled then effects.Blur.Size = 0 end

    effects.Color.Brightness = clamp(CONFIG.Brightness, -1, 1)
    effects.Color.Contrast = clamp(CONFIG.Contrast, -1, 1)
    effects.Color.Saturation = clamp(CONFIG.Saturation, -1, 1)
    effects.Color.TintColor = CONFIG.Tint
    effects.Color.Enabled = true

    effects.Bloom.Intensity = clamp(CONFIG.BloomIntensity, 0, 2)
    effects.Bloom.Size = clamp(CONFIG.BloomSize, 0, 56)
    effects.Bloom.Threshold = 0.9
    effects.Bloom.Enabled = CONFIG.BloomIntensity > 0 and CONFIG.BloomSize > 0

    effects.SunRays.Intensity = clamp(CONFIG.SunRaysIntensity, 0, 0.25)
    effects.SunRays.Spread = 0.8
    effects.SunRays.Enabled = CONFIG.SunRaysIntensity > 0

    local dofStrength = clamp(CONFIG.DepthOfFieldStrength, 0, 1)
    effects.DOF.FocusDistance = 30
    effects.DOF.InFocusRadius = 40 - (dofStrength * 25)
    effects.DOF.NearIntensity = dofStrength * 0.18
    effects.DOF.FarIntensity = dofStrength * 0.35
    effects.DOF.Enabled = CONFIG.DepthOfField and dofStrength > 0

    -- Roblox environment specular response is not a screen-space reflection shader.
    pcall(function() Lighting.EnvironmentSpecularScale = clamp(CONFIG.ReflectionScale, 0, 1) end)
    pcall(function() Lighting.ExposureCompensation = clamp(CONFIG.Exposure, -1, 1) end)
end

local function setSliderValue(widget, rawValue)
    local step = widget.step or 0.01
    local value = widget.minimum + clamp((rawValue - widget.minimum) / (widget.maximum - widget.minimum), 0, 1) * (widget.maximum - widget.minimum)
    value = math.floor(value / step + 0.5) * step
    value = clamp(value, widget.minimum, widget.maximum)
    CONFIG[widget.key] = value
    local alpha = (value - widget.minimum) / (widget.maximum - widget.minimum)
    widget.fill.Size = UDim2.new(alpha, 0, 1, 0)
    widget.knob.Position = UDim2.new(alpha, -6, 0.5, -6)
    widget.value.Text = widget.format(value)
    applyVisuals()
end

local function updateSliderFromX(widget, x)
    if not widget or not widget.track or not widget.track.Parent then return end
    local width = math.max(1, widget.track.AbsoluteSize.X)
    local alpha = clamp((x - widget.track.AbsolutePosition.X) / width, 0, 1)
    setSliderValue(widget, widget.minimum + alpha * (widget.maximum - widget.minimum))
end

local function styleButton(button)
    button.AutoButtonColor = true
    button.BackgroundColor3 = Color3.fromRGB(38, 47, 65)
    button.BorderSizePixel = 0
    button.TextColor3 = Color3.fromRGB(236, 244, 255)
    button.Font = Enum.Font.GothamSemibold
    button.TextSize = 12
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = button
end

local function makeButton(parent, text, position, size, callback)
    local button = Instance.new("TextButton")
    button.Text = text
    button.Position = position
    button.Size = size
    button.Parent = parent
    styleButton(button)
    keepConnection(button.Activated, callback)
    return button
end

local function refreshToggleLabels()
    if not panelScroll then return end
    local definitions = {
        MotionToggle = "Motion Blur: " .. (CONFIG.MotionBlurEnabled and "ON" or "OFF"),
        DOFToggle = "Depth of Field: " .. (CONFIG.DepthOfField and "ON" or "OFF"),
        FPSToggle = "FPS HUD: " .. (CONFIG.FPSOverlayEnabled and "ON" or "OFF"),
    }
    for name, text in pairs(definitions) do
        local button = panelScroll:FindFirstChild(name)
        if button then button.Text = text end
    end
    applyHudStyle()
end

local function restoreAndStop()
    if not running then return end
    running = false
    pcall(function() RunService:UnbindFromRenderStep("MK442_VisualPlus_Motion") end)
    pcall(function() Lighting.ExposureCompensation = originalExposure end)
    pcall(function() Lighting.EnvironmentSpecularScale = originalSpecular end)
    removeOwnedEffects(effectsCamera or currentCamera)
    for _, connection in ipairs(connections) do
        pcall(function() connection:Disconnect() end)
    end
    connections = {}
    if visualScreen then visualScreen:Destroy() end
end

-- Screen UI: a compact in-game controller and a movable FPS display.
visualScreen = Instance.new("ScreenGui")
visualScreen.Name = "MK442_VisualPlus_Interactive"
visualScreen.ResetOnSpawn = false
visualScreen.IgnoreGuiInset = false
visualScreen.DisplayOrder = 9999
visualScreen.Parent = player:WaitForChild("PlayerGui")

openButton = Instance.new("TextButton")
openButton.Name = "OpenVisualControls"
openButton.Text = "MK442  •  VISUALS"
openButton.Position = UDim2.new(0, 12, 0, 48)
openButton.Size = UDim2.fromOffset(150, 30)
openButton.Parent = visualScreen
styleButton(openButton)
openButton.BackgroundColor3 = Color3.fromRGB(18, 124, 167)

panel = Instance.new("Frame")
panel.Name = "VisualControlsPanel"
panel.Position = UDim2.new(0, 12, 0, 84)
panel.Size = UDim2.fromOffset(430, 580)
panel.BackgroundColor3 = Color3.fromRGB(17, 22, 33)
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = visualScreen
local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = panel
local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(36, 188, 220)
panelStroke.Thickness = 1
panelStroke.Parent = panel

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(12, 7)
title.Size = UDim2.new(1, -58, 0, 31)
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(102, 231, 255)
title.Text = "VisualPlus • Live controls"
title.Parent = panel
local closeButton = makeButton(panel, "X", UDim2.new(1, -42, 0, 8), UDim2.fromOffset(30, 28), function()
    panel.Visible = false
end)
closeButton.BackgroundColor3 = Color3.fromRGB(98, 46, 58)

panelScroll = Instance.new("ScrollingFrame")
panelScroll.Name = "ControlsScroll"
panelScroll.Position = UDim2.fromOffset(8, 44)
panelScroll.Size = UDim2.new(1, -16, 1, -100)
panelScroll.BackgroundTransparency = 1
panelScroll.BorderSizePixel = 0
panelScroll.ScrollBarThickness = 5
panelScroll.ScrollBarImageColor3 = Color3.fromRGB(50, 184, 218)
panelScroll.CanvasSize = UDim2.fromOffset(0, 780)
panelScroll.Parent = panel

local function makeToggle(name, text, x, callback)
    local button = makeButton(panelScroll, text, UDim2.fromOffset(x, 6), UDim2.fromOffset(132, 29), callback)
    button.Name = name
    return button
end

makeToggle("MotionToggle", "Motion Blur: ON", 4, function()
    CONFIG.MotionBlurEnabled = not CONFIG.MotionBlurEnabled
    applyVisuals()
    refreshToggleLabels()
end)
makeToggle("DOFToggle", "Depth of Field: OFF", 142, function()
    CONFIG.DepthOfField = not CONFIG.DepthOfField
    applyVisuals()
    refreshToggleLabels()
end)
makeToggle("FPSToggle", "FPS HUD: ON", 280, function()
    CONFIG.FPSOverlayEnabled = not CONFIG.FPSOverlayEnabled
    refreshToggleLabels()
end)

makeButton(panelScroll, "HUD corner", UDim2.fromOffset(4, 40), UDim2.fromOffset(98, 27), function()
    local positions = {"TopLeft", "TopRight", "BottomLeft", "BottomRight"}
    local index = table.find(positions, CONFIG.FPSOverlayPosition) or 1
    CONFIG.FPSOverlayPosition = positions[(index % #positions) + 1]
    setHudPosition(CONFIG.FPSOverlayPosition)
end)
makeButton(panelScroll, "Size -", UDim2.fromOffset(106, 40), UDim2.fromOffset(67, 27), function()
    CONFIG.FPSOverlaySize = clamp(CONFIG.FPSOverlaySize - 2, 10, 32)
    applyHudStyle()
end)
makeButton(panelScroll, "Size +", UDim2.fromOffset(177, 40), UDim2.fromOffset(67, 27), function()
    CONFIG.FPSOverlaySize = clamp(CONFIG.FPSOverlaySize + 2, 10, 32)
    applyHudStyle()
end)
local colorChoices = {
    Color3.fromRGB(91, 255, 164), Color3.fromRGB(255, 255, 255), Color3.fromRGB(78, 230, 255),
    Color3.fromRGB(255, 220, 85), Color3.fromRGB(255, 90, 90), Color3.fromRGB(201, 139, 255)
}
local colorIndex = 1
for i, color in ipairs(colorChoices) do
    if color == CONFIG.FPSOverlayColor then colorIndex = i end
end
makeButton(panelScroll, "FPS color", UDim2.fromOffset(248, 40), UDim2.fromOffset(96, 27), function()
    colorIndex = (colorIndex % #colorChoices) + 1
    setHudColor(colorChoices[colorIndex])
end)

local resetButton = makeButton(panel, "Reset exported preset", UDim2.new(0, 8, 1, -47), UDim2.new(0.5, -12, 0, 38), function()
    for key, value in pairs(START_CONFIG) do CONFIG[key] = value end
    colorIndex = 1
    for i, color in ipairs(colorChoices) do if color == CONFIG.FPSOverlayColor then colorIndex = i end end
    setHudPosition(CONFIG.FPSOverlayPosition)
    applyHudStyle()
    applyVisuals()
    for _, widget in pairs(sliderWidgets) do setSliderValue(widget, CONFIG[widget.key]) end
    refreshToggleLabels()
end)
resetButton.BackgroundColor3 = Color3.fromRGB(49, 83, 108)
local restoreButton = makeButton(panel, "Restore original look", UDim2.new(0.5, 4, 1, -47), UDim2.new(0.5, -12, 0, 38), restoreAndStop)
restoreButton.BackgroundColor3 = Color3.fromRGB(126, 54, 62)

local function addSlider(key, labelText, minimum, maximum, step, y, formatter)
    local row = Instance.new("Frame")
    row.Name = "SliderRow_" .. key
    row.Position = UDim2.fromOffset(4, y)
    row.Size = UDim2.new(1, -18, 0, 54)
    row.BackgroundColor3 = Color3.fromRGB(24, 31, 45)
    row.BorderSizePixel = 0
    row.Parent = panelScroll
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = row

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.fromOffset(9, 3)
    label.Size = UDim2.new(1, -84, 0, 19)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = Color3.fromRGB(226, 237, 250)
    label.Text = labelText
    label.Parent = row

    local value = Instance.new("TextLabel")
    value.BackgroundTransparency = 1
    value.Position = UDim2.new(1, -76, 0, 3)
    value.Size = UDim2.fromOffset(67, 19)
    value.Font = Enum.Font.GothamBold
    value.TextSize = 12
    value.TextXAlignment = Enum.TextXAlignment.Right
    value.TextColor3 = Color3.fromRGB(102, 231, 255)
    value.Parent = row

    local track = Instance.new("TextButton")
    track.Name = "Track"
    track.Text = ""
    track.AutoButtonColor = false
    track.Position = UDim2.fromOffset(9, 29)
    track.Size = UDim2.new(1, -18, 0, 12)
    track.BackgroundColor3 = Color3.fromRGB(47, 56, 72)
    track.BorderSizePixel = 0
    track.Parent = row
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track
    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = Color3.fromRGB(27, 190, 218)
    fill.BorderSizePixel = 0
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.Parent = track
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill
    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(12, 12)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(0, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(245, 252, 255)
    knob.BorderSizePixel = 0
    knob.Parent = track
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local widget = {key = key, minimum = minimum, maximum = maximum, step = step, track = track, fill = fill, knob = knob, value = value, format = formatter or function(v) return string.format("%.2f", v) end}
    sliderWidgets[key] = widget
    keepConnection(track.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            activeSlider = widget
            updateSliderFromX(widget, input.Position.X)
        end
    end)
    setSliderValue(widget, CONFIG[key])
end

local section = Instance.new("TextLabel")
section.BackgroundTransparency = 1
section.Position = UDim2.fromOffset(7, 76)
section.Size = UDim2.new(1, -16, 0, 24)
section.Font = Enum.Font.GothamBold
section.TextSize = 13
section.TextXAlignment = Enum.TextXAlignment.Left
section.TextColor3 = Color3.fromRGB(102, 231, 255)
section.Text = "LIVE EFFECTS  •  changes apply immediately"
section.Parent = panelScroll

local y = 105
addSlider("MotionBlurStrength", "Motion blur strength (camera-turn approximation)", 0, 10, 0.1, y, function(v) return string.format("%.1f / 10", v) end); y = y + 58
addSlider("Brightness", "Brightness", -0.2, 0.2, 0.01, y, function(v) return string.format("%+.2f", v) end); y = y + 58
addSlider("Contrast", "Contrast", -0.5, 0.5, 0.01, y, function(v) return string.format("%+.2f", v) end); y = y + 58
addSlider("Saturation", "Saturation", -1, 1, 0.02, y, function(v) return string.format("%+.2f", v) end); y = y + 58
addSlider("Exposure", "Exposure compensation", -1, 1, 0.05, y, function(v) return string.format("%+.2f", v) end); y = y + 58
addSlider("ReflectionScale", "Environment specular (not screen-space reflections)", 0, 1, 0.05, y, function(v) return string.format("%.2f", v) end); y = y + 58
addSlider("BloomIntensity", "Bloom intensity", 0, 2, 0.05, y, function(v) return string.format("%.2f", v) end); y = y + 58
addSlider("BloomSize", "Bloom size", 0, 56, 1, y, function(v) return string.format("%.0f", v) end); y = y + 58
addSlider("SunRaysIntensity", "Sun rays intensity", 0, 0.25, 0.005, y, function(v) return string.format("%.3f", v) end); y = y + 58
addSlider("DepthOfFieldStrength", "Depth of field strength", 0, 1, 0.05, y, function(v) return string.format("%.2f", v) end); y = y + 58
panelScroll.CanvasSize = UDim2.fromOffset(0, y + 8)

keepConnection(openButton.Activated, function()
    if running and panel then panel.Visible = not panel.Visible end
end)

keepConnection(UserInputService.InputChanged, function(input)
    if not running then return end
    if activeSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateSliderFromX(activeSlider, input.Position.X)
    end
    if hudDragging and hudLabel and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - hudDragOrigin
        local viewport = currentCamera and currentCamera.ViewportSize or Vector2.new(1920, 1080)
        local newX = clamp(hudStartPosition.X + delta.X, 0, math.max(0, viewport.X - hudLabel.AbsoluteSize.X))
        local newY = clamp(hudStartPosition.Y + delta.Y, 0, math.max(0, viewport.Y - hudLabel.AbsoluteSize.Y))
        hudLabel.AnchorPoint = Vector2.new(0, 0)
        hudLabel.Position = UDim2.fromOffset(newX, newY)
    end
end)
keepConnection(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        activeSlider = nil
        hudDragging = false
    end
end)

hudLabel = Instance.new("TextLabel")
hudLabel.Name = "FPSLabel"
hudLabel.BackgroundColor3 = Color3.fromRGB(8, 13, 22)
hudLabel.BackgroundTransparency = 0.22
hudLabel.BorderSizePixel = 0
hudLabel.Font = Enum.Font.GothamBold
hudLabel.TextSize = clamp(CONFIG.FPSOverlaySize, 10, 32)
hudLabel.TextColor3 = CONFIG.FPSOverlayColor
hudLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
hudLabel.TextStrokeTransparency = 0.25
hudLabel.Text = "FPS --"
hudLabel.Active = true
hudLabel.ZIndex = 100
hudLabel.Parent = visualScreen
local hudCorner = Instance.new("UICorner")
hudCorner.CornerRadius = UDim.new(0, 6)
hudCorner.Parent = hudLabel
setHudPosition(CONFIG.FPSOverlayPosition)
applyHudStyle()
keepConnection(hudLabel.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        hudDragging = true
        hudDragOrigin = input.Position
        hudStartPosition = hudLabel.AbsolutePosition
    end
end)

local fpsElapsed = 0
local fpsFrames = 0
keepConnection(RunService.RenderStepped, function(dt)
    if not running then return end
    fpsFrames = fpsFrames + 1
    fpsElapsed = fpsElapsed + dt
    if fpsElapsed >= 0.5 then
        if hudLabel and hudLabel.Parent then
            hudLabel.Text = string.format("%d FPS", math.floor(fpsFrames / math.max(fpsElapsed, 0.001) + 0.5))
            applyHudStyle()
        end
        fpsFrames = 0
        fpsElapsed = 0
    end
end)

local previousLook = currentCamera and currentCamera.CFrame.LookVector or Vector3.new(0, 0, -1)
RunService:UnbindFromRenderStep("MK442_VisualPlus_Motion")
RunService:BindToRenderStep("MK442_VisualPlus_Motion", Enum.RenderPriority.Camera.Value + 1, function(dt)
    if not running then return end
    local cam = workspace.CurrentCamera
    if not cam then return end
    if cam ~= currentCamera then
        currentCamera = cam
        previousLook = cam.CFrame.LookVector
        applyVisuals()
    end
    local blur = cam:FindFirstChild("MK442_VisualPlus_MotionBlur")
    if not blur then return end
    if not CONFIG.MotionBlurEnabled or CONFIG.MotionBlurStrength <= 0 then
        blur.Size = 0
        previousLook = cam.CFrame.LookVector
        return
    end
    local look = cam.CFrame.LookVector
    local dot = clamp(previousLook:Dot(look), -1, 1)
    local angle = math.deg(math.acos(dot))
    local target = clamp(angle * CONFIG.MotionBlurStrength * 0.7, 0, math.min(24, CONFIG.MotionBlurStrength * 2))
    blur.Size = blur.Size + (target - blur.Size) * clamp(dt * 14, 0, 1)
    previousLook = look
end)

keepConnection(workspace:GetPropertyChangedSignal("CurrentCamera"), function()
    if not running then return end
    currentCamera = workspace.CurrentCamera
    previousLook = currentCamera and currentCamera.CFrame.LookVector or Vector3.new(0, 0, -1)
    applyVisuals()
end)

applyVisuals()
refreshToggleLabels()
