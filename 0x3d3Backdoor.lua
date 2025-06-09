-- 0x3d3 Backdoor GUI + Scanner + Executor
-- Colors: Red, Black, White theme
-- Draggable window, scan suspicious backdoors in Workspace & ReplicatedStorage
-- Execute scripts on detected RemoteEvents & RemoteFunctions
-- Notification when backdoor found

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Create main GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "0x3d3BackdoorGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(1, 0, 1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
mainFrame.Parent = screenGui

-- Top bar (draggable)
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 40)
topBar.BackgroundColor3 = Color3.fromRGB(180, 20, 20)
topBar.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 24
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Text = "0x3d3 Backdoor"
titleLabel.Parent = topBar

-- Draggable logic
local dragging, dragInput, dragStart, startPos

topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

topBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- Tab buttons container
local tabsFrame = Instance.new("Frame")
tabsFrame.Size = UDim2.new(1, 0, 0, 40)
tabsFrame.Position = UDim2.new(0, 0, 0, 40)
tabsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
tabsFrame.Parent = mainFrame

local function createTabButton(name, position)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 150, 1, 0)
    btn.Position = position
    btn.BackgroundColor3 = Color3.fromRGB(180, 20, 20)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 18
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = name
    btn.Parent = tabsFrame
    return btn
end

local scannerBtn = createTabButton("Scan All", UDim2.new(0, 0, 0, 0))
local executorBtn = createTabButton("Executor", UDim2.new(0, 150, 0, 0))

-- Content frames
local scannerFrame = Instance.new("Frame")
scannerFrame.Size = UDim2.new(1, 0, 1, -80)
scannerFrame.Position = UDim2.new(0, 0, 0, 80)
scannerFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
scannerFrame.Visible = true
scannerFrame.Parent = mainFrame

local executorFrame = Instance.new("Frame")
executorFrame.Size = UDim2.new(1, 0, 1, -80)
executorFrame.Position = UDim2.new(0, 0, 0, 80)
executorFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
executorFrame.Visible = false
executorFrame.Parent = mainFrame

-- Tab switching
scannerBtn.MouseButton1Click:Connect(function()
    scannerFrame.Visible = true
    executorFrame.Visible = false
end)

executorBtn.MouseButton1Click:Connect(function()
    scannerFrame.Visible = false
    executorFrame.Visible = true
end)

-- Utility: Append lines to scrolling frame
local function appendLine(frame, text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 20)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 16
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = text
    label.Parent = frame
    return label
end

-- Scanner Output (ScrollingFrame)
local scannerOutput = Instance.new("ScrollingFrame")
scannerOutput.Size = UDim2.new(1, -20, 1, -80)
scannerOutput.Position = UDim2.new(0, 10, 0, 10)
scannerOutput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
scannerOutput.BorderSizePixel = 0
scannerOutput.ScrollBarThickness = 8
scannerOutput.CanvasSize = UDim2.new(0, 0, 0, 0)
scannerOutput.Parent = scannerFrame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 2)
layout.Parent = scannerOutput

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scannerOutput.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
end)

-- Suspicious keywords and types
local suspiciousKeywords = {"backdoor", "admin", "exploit", "remote", "inject", "exec"}
local suspiciousTypes = {
    ["RemoteEvent"] = true,
    ["RemoteFunction"] = true,
    ["ModuleScript"] = true,
    ["BindableEvent"] = true,
    ["BindableFunction"] = true,
    ["Script"] = true,
    ["LocalScript"] = true,
}

-- Checks if any ancestor's or object's name contains suspicious keywords
local function nameContainsKeyword(obj)
    local nameLower = obj.Name:lower()
    for _, keyword in ipairs(suspiciousKeywords) do
        if nameLower:find(keyword) then
            return true
        end
    end
    -- Check all parents too
    local current = obj.Parent
    while current do
        local pname = current.Name:lower()
        for _, keyword in ipairs(suspiciousKeywords) do
            if pname:find(keyword) then
                return true
            end
        end
        current = current.Parent
    end
    return false
end

-- Checks source code of scripts for suspicious keywords
local function sourceContainsKeyword(scriptObj)
    if not (scriptObj:IsA("ModuleScript") or scriptObj:IsA("Script") or scriptObj:IsA("LocalScript")) then
        return false
    end
    local success, source = pcall(function()
        return scriptObj.Source
    end)
    if not success then return false end
    local srcLower = source:lower()
    for _, keyword in ipairs(suspiciousKeywords) do
        if srcLower:find(keyword) then
            return true
        end
    end
    return false
end

-- Collect all suspicious objects in given container recursively
local function scanContainer(container, results)
    for _, obj in ipairs(container:GetChildren()) do
        if suspiciousTypes[obj.ClassName] then
            local suspicious = false
            if nameContainsKeyword(obj) then
                suspicious = true
            elseif obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
                if sourceContainsKeyword(obj) then
                    suspicious = true
                end
            end
            if suspicious then
                table.insert(results, obj)
            end
        end
        if #obj:GetChildren() > 0 then
            scanContainer(obj, results)
        end
    end
end

local suspiciousObjects = {}

local function clearScanResults()
    suspiciousObjects = {}
    for _, child in pairs(scannerOutput:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end
end

-- Notification popup function
local function showNotification(text)
    local notifFrame = Instance.new("Frame")
    notifFrame.Size = UDim2.new(0, 300, 0, 50)
    notifFrame.Position = UDim2.new(0.5, -150, 0, 50)
    notifFrame.BackgroundColor3 = Color3.fromRGB(180, 20, 20)
    notifFrame.BorderSizePixel = 0
    notifFrame.Parent = screenGui

    local notifText = Instance.new("TextLabel")
    notifText.Size = UDim2.new(1, -20, 1, 0)
    notifText.Position = UDim2.new(0, 10, 0, 0)
    notifText.BackgroundTransparency = 1
    notifText.Font = Enum.Font.GothamBold
    notifText.TextSize = 18
    notifText.TextColor3 = Color3.fromRGB(255, 255, 255)
    notifText.Text = text
    notifText.Parent = notifFrame

    -- Tween to fade out
    local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(notifFrame, tweenInfo, {BackgroundTransparency = 1})
    tween:Play()
    tween.Completed:Connect(function()
        notifFrame:Destroy()
    end)
end

-- Scan function
local function scanAll()
    clearScanResults()
    local startTime = tick()
    local foundCount = 0
    local results = {}

    scanContainer(workspace, results)
    scanContainer(ReplicatedStorage, results)

    suspiciousObjects = results

    for i, obj in ipairs(results) do
        appendLine(scannerOutput, string.format("[%d] Found: %s (%s)", i, obj.Name, obj.ClassName))
        foundCount = foundCount + 1
        showNotification("Backdoor Found: "..obj.Name.." in "..string.format("%.2f", tick() - startTime).." seconds")
    end

    if foundCount == 0 then
        appendLine(scannerOutput, "No suspicious backdoors found.")
    end
end

-- Scan Button
local scanButton = Instance.new("TextButton")
scanButton.Size = UDim2.new(0, 200, 0, 40)
scanButton.Position = UDim2.new(0, 10, 1, -50)
scanButton.BackgroundColor3 = Color3.fromRGB(180, 20, 20)
scanButton.Font = Enum.Font.GothamBold
scanButton.TextSize = 20
scanButton.TextColor3 = Color3.fromRGB(255, 255, 255)
scanButton.Text = "Scan Workspace & ReplicatedStorage"
scanButton.Parent = scannerFrame

scanButton.MouseButton1Click:Connect(function()
    scanAll()
end)

-- Executor UI --

local scriptInput = Instance.new("TextBox")
scriptInput.Size = UDim2.new(1, -20, 1, -80)
scriptInput.Position = UDim2.new(0, 10, 0, 10)
scriptInput.ClearTextOnFocus = false
scriptInput.MultiLine = true
scriptInput.Font = Enum.Font.Code
scriptInput.TextSize = 16
scriptInput.TextColor3 = Color3.fromRGB(255, 255, 255)
scriptInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
scriptInput.PlaceholderText = "Write Lua script here..."
scriptInput.Parent = executorFrame

local executeBtn = Instance.new("TextButton")
executeBtn.Size = UDim2.new(0, 120, 0, 40)
executeBtn.Position = UDim2.new(1, -130, 1, -50)
executeBtn.BackgroundColor3 = Color3.fromRGB(180, 20, 20)
executeBtn.Font = Enum.Font.GothamBold
executeBtn.TextSize = 18
executeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
executeBtn.Text = "Execute Script"
executeBtn.Parent = executorFrame

executeBtn.MouseButton1Click:Connect(function()
    local success, err = pcall(function()
        loadstring(scriptInput.Text)()
    end)
    if not success then
        showNotification("Error: "..err)
    else
        showNotification("Script executed successfully.")
    end
end)
