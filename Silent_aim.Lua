-- Silent Aim Script
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CurrentCamera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Menu Settings
local menuOpen = false
local FOV = 170
local ESP_COLOR = Color3.fromRGB(0, 255, 0)

-- Drawing objects
local FOVring = Drawing.new("Circle")
local ESPTable = {}

-- FOV Circle Setup
FOVring.Visible = true
FOVring.Thickness = 2
FOVring.Color = Color3.fromRGB(128, 0, 128)
FOVring.Filled = false
FOVring.Radius = FOV
FOVring.Position = CurrentCamera.ViewportSize / 2

-- Toggle Menu
local function toggleMenu()
    menuOpen = not menuOpen
    if menuOpen then
        -- Show Menu Logic here
        print("Menu Opened")
    else
        -- Hide Menu Logic here
        print("Menu Closed")
    end
end

-- Tạo ESP
local function createESP(player)
    if player == LocalPlayer then return end
    local espBox = Drawing.new("Square")
    espBox.Visible = false
    espBox.Color = ESP_COLOR
    espBox.Thickness = 2
    espBox.Filled = false
    ESPTable[player] = espBox

    RunService.RenderStepped:Connect(function()
        if player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            local screenPos, onScreen = CurrentCamera:WorldToViewportPoint(head.Position)

            if onScreen then
                espBox.Visible = true
                espBox.Size = Vector2.new(50, 50)
                espBox.Position = Vector2.new(screenPos.X - 50 / 2, screenPos.Y - 50 / 2)
            else
                espBox.Visible = false
            end
        else
            espBox.Visible = false
        end
    end)
end

-- Tìm người chơi gần nhất trong FOV
local function getClosestPlayerInFOV()
    local closestPlayer = nil
    local shortestDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            local screenPos, onScreen = CurrentCamera:WorldToViewportPoint(head.Position)
            local distance = (Vector2.new(screenPos.X, screenPos.Y) - FOVring.Position).Magnitude

            if onScreen and distance < FOV and distance < shortestDistance then
                closestPlayer = player
                shortestDistance = distance
            end
        end
    end

    return closestPlayer
end

-- Áp dụng Silent Aim
local function applySilentAim()
    local target = getClosestPlayerInFOV()
    if target and target.Character and target.Character:FindFirstChild("Head") then
        -- Chỉnh sửa hướng bắn sao cho bắn vào đầu đối thủ
        local headPosition = target.Character.Head.Position
        local aimDirection = (headPosition - CurrentCamera.CFrame.Position).unit
        -- Thay đổi hướng camera hoặc điểm bắn để bắn vào đối thủ (Silent Aim)
        CurrentCamera.CFrame = CFrame.new(CurrentCamera.CFrame.Position, headPosition)
    end
end

-- Toggle Silent Aim với chuột trái
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if menuOpen then
            applySilentAim()  -- Kích hoạt Silent Aim khi chuột trái được nhấn
        end
    end
end)

-- Cập nhật vòng FOV
RunService.RenderStepped:Connect(function()
    FOVring.Position = CurrentCamera.ViewportSize / 2
end)

-- Đóng/Mở Menu khi nhấn phím
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Insert then  -- Nhấn Insert để bật/tắt menu
        toggleMenu()
    end
end)

-- Tạo ESP cho người chơi
local function onPlayerAdded(player)
    player.CharacterAdded:Connect(function(character)
        createESP(player)
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        if player.Character then
            createESP(player)
        end
        player.CharacterAdded:Connect(function(character)
            createESP(player)
        end)
    end
end

Players.PlayerAdded:Connect(onPlayerAdded)
