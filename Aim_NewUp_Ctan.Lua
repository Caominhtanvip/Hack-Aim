local fov = 150
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Cam = game.Workspace.CurrentCamera

-- Create the FOV ring
local FOVring = Drawing.new("Circle")
FOVring.Visible = true
FOVring.Thickness = 2
FOVring.Color = Color3.fromRGB(128, 0, 128) -- Purple color
FOVring.Filled = false
FOVring.Radius = fov
FOVring.Position = Cam.ViewportSize / 2

-- ESP table to store drawings
local ESP = {}

-- Variable to track if silent aim is enabled
local isSilentAim = false

-- Function to update the FOV ring position
local function updateDrawings()
    FOVring.Position = Cam.ViewportSize / 2
end

-- Function to create ESP for players
local function createESP(player)
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Color3.fromRGB(255, 0, 0) -- Red
    box.Thickness = 2
    box.Transparency = 1
    ESP[player] = box
end

local function removeESP(player)
    if ESP[player] then
        ESP[player]:Remove()
        ESP[player] = nil
    end
end

-- Function to update ESP boxes
local function updateESP()
    for player, box in pairs(ESP) do
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local hrp = character.HumanoidRootPart
            local pos, isVisible = Cam:WorldToViewportPoint(hrp.Position)

            if isVisible then
                box.Size = Vector2.new(50, 50) -- Example size
                box.Position = Vector2.new(pos.X - box.Size.X / 2, pos.Y - box.Size.Y / 2)
                box.Visible = true
            else
                box.Visible = false
            end
        else
            box.Visible = false
        end
    end
end

-- Add ESP for all players
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(removeESP)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= Players.LocalPlayer then
        createESP(player)
    end
end

-- Function to handle key press events
local function onKeyDown(input)
    if input.KeyCode == Enum.KeyCode.Delete then
        RunService:UnbindFromRenderStep("FOVUpdate")
        FOVring:Remove()
        for _, box in pairs(ESP) do
            box:Remove()
        end
    end
end

-- Function to handle mouse input events
local function onMouseButtonPress(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isSilentAim = not isSilentAim -- Toggle silent aim on left click
    end
end

UserInputService.InputBegan:Connect(onMouseButtonPress)
UserInputService.InputBegan:Connect(onKeyDown)

-- Function to find the closest player within the FOV
local function getClosestPlayerInFOV(trg_part)
    local nearest = nil
    local last = math.huge
    local playerMousePos = Cam.ViewportSize / 2

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer then
            local part = player.Character and player.Character:FindFirstChild(trg_part)
            if part then
                local ePos, isVisible = Cam:WorldToViewportPoint(part.Position)
                local distance = (Vector2.new(ePos.x, ePos.y) - playerMousePos).Magnitude

                if distance < last and isVisible and distance < fov then
                    last = distance
                    nearest = part
                end
            end
        end
    end

    return nearest
end

-- Silent aim function
local function applySilentAim()
    local target = getClosestPlayerInFOV("Head") -- Target player's head
    if target then
        local mouse = Players.LocalPlayer:GetMouse()
        mouse.TargetFilter = target.Parent -- Ignore target for further raycasts
        mouse.Hit = target.CFrame -- Direct shots toward the target
    end
end

-- Update the FOV ring and handle silent aim every frame
RunService.RenderStepped:Connect(function()
    updateDrawings()
    updateESP()
    if isSilentAim then
        applySilentAim()
    end
end)
