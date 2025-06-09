-- 0x3d3 Backdoor GUI + Scanner + Executor
-- Colors: Red, Black, White theme
-- Draggable window, scan suspicious backdoors in Workspace & ReplicatedStorage
-- Execute scripts on detected RemoteEvents & RemoteFunctions

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
local UserInputService = game:GetService("UserInputService")
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

local function scanAll()
    clearScanResults()
    suspiciousObjects = {}
    appendLine(scannerOutput, "Starting scan of workspace and ReplicatedStorage...")
    scanContainer(workspace, suspiciousObjects)
    scanContainer(ReplicatedStorage, suspiciousObjects)
    if #suspiciousObjects == 0 then
        appendLine(scannerOutput, "No suspicious backdoor objects found.")
    else
        appendLine(scannerOutput, "Found suspicious backdoor objects:")
        for i, obj in ipairs(suspiciousObjects) do
            appendLine(scannerOutput, i .. ". " .. obj:GetFullName() .. " [" .. obj.ClassName .. "]")
        end
    end
end

-- Button to scan all
local scanButton = Instance.new("TextButton")
scanButton.Size = UDim2.new(0, 160, 0, 40)
scanButton.Position = UDim2.new(0, 20, 0, 10)
scanButton.BackgroundColor3 = Color3.fromRGB(180, 20, 20)
scanButton.TextColor3 = Color3.fromRGB(255, 255, 255)
scanButton.Font = Enum.Font.GothamBold
scanButton.TextSize = 18
scanButton.Text = "Scan All"
scanButton.Parent = scannerFrame
scanButton.MouseButton1Click:Connect(scanAll)

-- Executor UI
local inputBox = Instance.new("TextBox")
inputBox.Size = UDim2.new(1, -40, 0, 100)
inputBox.Position = UDim2.new(0, 20, 0, 20)
inputBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
inputBox.Font = Enum.Font.Code
inputBox.TextSize = 16
inputBox.ClearTextOnFocus = false
inputBox.MultiLine = true
inputBox.PlaceholderText = "-- Enter Lua script here"
inputBox.Parent = executorFrame

local execButton = Instance.new("TextButton")
execButton.Size = UDim2.new(0, 160, 0, 40)
execButton.Position = UDim2.new(0, 20, 0, 130)
execButton.BackgroundColor3 = Color3.fromRGB(180, 20, 20)
execButton.TextColor3 = Color3.fromRGB(255, 255, 255)
execButton.Font = Enum.Font.GothamBold
execButton.TextSize = 18
execButton.Text = "Execute Script"
execButton.Parent = executorFrame

local execOutput = Instance.new("ScrollingFrame")
execOutput.Size = UDim2.new(1, -40, 0, 200)
execOutput.Position = UDim2.new(0, 20, 0, 180)
execOutput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
execOutput.BorderSizePixel = 0
execOutput.ScrollBarThickness = 8
execOutput.CanvasSize = UDim2.new(0, 0, 0, 0)
execOutput.Parent = executorFrame

local execLayout = Instance.new("UIListLayout")
execLayout.Padding = UDim.new(0, 2)
execLayout.Parent = execOutput

execLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    execOutput.CanvasSize = UDim2.new(0, 0, 0, execLayout.AbsoluteContentSize.Y + 10)
end)

-- Append lines to executor output
local function appendExecLine(text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 20)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 16
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = text
    label.Parent = execOutput
    return label
end

-- Executor button logic
execButton.MouseButton1Click:Connect(function()
    local scriptText = inputBox.Text
    if scriptText == "" then
        appendExecLine("[Error] Please enter a script to execute.")
        return
    end
    if #suspiciousObjects == 0 then
        appendExecLine("[Warning] No suspicious backdoor objects found. Run Scan All first.")
        return
    end
    appendExecLine("Executing script on detected backdoors...")
    for _, obj in ipairs(suspiciousObjects) do
        if obj:IsA("RemoteEvent") then
            local success, err = pcall(function()
                obj:FireServer(scriptText)
            end)
            if success then
                appendExecLine("[Success] Fired script to " .. obj:GetFullName())
            else
                appendExecLine("[Failed] " .. obj:GetFullName() .. ": " .. err)
            end
        elseif obj:IsA("RemoteFunction") then
            local success, result = pcall(function()
                return obj:InvokeServer(scriptText)
            end)
            if success then
                appendExecLine("[Success] Invoked script on " .. obj:GetFullName() .. ". Result: " .. tostring(result))
            else
                appendExecLine("[Failed] " .. obj:GetFullName() .. ": " .. result)
            end
        else
            appendExecLine("[Skipped] " .. obj:GetFullName() .. " (" .. obj.ClassName .. ") - unsupported executor")
        end
    end
end)
