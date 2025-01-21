local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CurrentCamera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Teams = game:GetService("Teams")

-- Menu Settings
local menuOpen = false
local FOV = 100
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
        print("Menu Opened")
    else
        print("Menu Closed")
    end
end

-- Wall Check (Bắn xuyên tường - Kiểm tra vật cản)
local function isTargetVisible(targetHead)
    -- Sử dụng Raycast để kiểm tra vật cản, nhưng không kiểm tra tường (cho phép bắn xuyên tường)
    local origin = CurrentCamera.CFrame.Position
    local direction = (targetHead.Position - origin).Unit * 500
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character} -- Ignore LocalPlayer và các vật thể không cần thiết
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    local result = Workspace:Raycast(origin, direction, raycastParams)
    return result == nil or result.Instance:IsDescendantOf(targetHead.Parent)
end

-- Kiểm tra Team (Chỉ nhắm vào kẻ thù)
local function isEnemy(player)
    return player.Team ~= LocalPlayer.Team -- Kiểm tra nếu người chơi là địch
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

    RunService.Heartbeat:Connect(function()
        if player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            local screenPos, onScreen = CurrentCamera:WorldToViewportPoint(head.Position)

            if onScreen then
                espBox.Visible = true
                espBox.Size = Vector2.new(50, 50)
                espBox.Position = Vector2.new(screenPos.X - 25, screenPos.Y - 25)
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
            if isEnemy(player) then  -- Kiểm tra xem có phải địch không
                local head = player.Character.Head
                local screenPos, onScreen = CurrentCamera:WorldToViewportPoint(head.Position)
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - FOVring.Position).Magnitude

                -- Kiểm tra xem đối thủ có trong FOV và không có vật cản (bắn xuyên tường)
                if onScreen and distance < FOV and distance < shortestDistance and isTargetVisible(head) then
                    closestPlayer = player
                    shortestDistance = distance
                end
            end
        end
    end

    return closestPlayer
end

-- Áp dụng Silent Aim
local function applySilentAim()
    local target = getClosestPlayerInFOV()
    if target and target.Character and target.Character:FindFirstChild("Head") then
        local headPosition = target.Character.Head.Position
        -- Điều chỉnh hướng camera về đầu đối thủ (100% Headshot)
        CurrentCamera.CFrame = CFrame.new(CurrentCamera.CFrame.Position, headPosition)
    end
end

-- Biến để theo dõi trạng thái chuột trái
local isMouseDown = false

-- Kích hoạt Silent Aim liên tục khi chuột trái được giữ
RunService.RenderStepped:Connect(function()
    if isMouseDown and menuOpen then
        applySilentAim()
    end
end)

-- Xử lý khi chuột trái được nhấn
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isMouseDown = true
    end
end)

-- Xử lý khi chuột trái được nhả ra
UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isMouseDown = false
    end
end)

-- Cập nhật vòng FOV
RunService.RenderStepped:Connect(function()
    FOVring.Position = CurrentCamera.ViewportSize / 2
end)

-- Đóng/Mở Menu khi nhấn phím
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Insert then
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
