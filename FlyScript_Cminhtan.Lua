local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local isFlying = false -- Trạng thái bay
local flySpeed = 21    -- Tốc độ bay
local flyDirection = Vector3.zero

-- Kích hoạt chế độ bay
local function startFlying()
    humanoidRootPart.Anchored = false
    isFlying = true
end

-- Dừng chế độ bay
local function stopFlying()
    isFlying = false
    humanoidRootPart.Velocity = Vector3.zero
end

-- Xử lý phím di chuyển
local function onInput(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.Insert then
        if isFlying then
            stopFlying()
        else
            startFlying()
        end
    end
end

-- Tính toán hướng bay
local function updateFlyDirection()
    local moveDirection = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        moveDirection = moveDirection + Vector3.new(0, 0, -1)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        moveDirection = moveDirection + Vector3.new(0, 0, 1)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        moveDirection = moveDirection + Vector3.new(-1, 0, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        moveDirection = moveDirection + Vector3.new(1, 0, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        moveDirection = moveDirection + Vector3.new(0, 1, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        moveDirection = moveDirection + Vector3.new(0, -1, 0)
    end

    flyDirection = moveDirection.Unit * flySpeed
end

-- Cập nhật trạng thái bay trong mỗi khung hình
RunService.RenderStepped:Connect(function(deltaTime)
    if isFlying then
        updateFlyDirection()
        humanoidRootPart.Velocity = humanoidRootPart.CFrame:VectorToWorldSpace(flyDirection)
    end
end)

-- Lắng nghe sự kiện nhấn phím
UserInputService.InputBegan:Connect(onInput)
