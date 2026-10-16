--[[]]
IncubatorVisualizer - gerencia a renderização de ovos dentro dos modelos de Incubadora
Coloque este ModuleScript em ServerScriptService.Modules.IncubatorVisualizer
--]]

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local IncubatorVisualizer = {}
local incubators = {} -- [buildingId] = { model = Model, player = Player, eggs = { [eggId] = part } }

local function elementColor(element)
    return Config.ElementColors[element] or Color3.fromRGB(220, 220, 220)
end

-- Register an instantiated incubator model
function IncubatorVisualizer.RegisterIncubator(model, player, buildingId)
    if not model then return end
    incubators[buildingId] = incubators[buildingId] or { model = model, player = player, eggs = {} }
end

-- Unregister incubator and remove egg visuals
function IncubatorVisualizer.UnregisterIncubator(buildingId)
    local info = incubators[buildingId]
    if not info then return end
    for eggId, part in pairs(info.eggs) do
        if part and part.Parent then part:Destroy() end
        info.eggs[eggId] = nil
    end
    incubators[buildingId] = nil
end

-- Helper to find an incubator for a player (returns buildingId, info)
local function findIncubatorForPlayer(player)
    for bid, info in pairs(incubators) do
        if info.player == player and info.model and info.model.PrimaryPart and info.model.Parent then
            return bid, info
        end
    end
    return nil, nil
end

-- Spawn a visual egg in the player's incubator (server-side simple model)
function IncubatorVisualizer.SpawnEgg(player, egg)
    if not player or not egg or not egg.Id then return end
    local bid, info = findIncubatorForPlayer(player)
    if not bid or not info then return end

    -- don't double spawn
    if info.eggs[egg.Id] then return end

    local incubatorModel = info.model
    local primary = incubatorModel.PrimaryPart
    if not primary then return end

    local eggPart = Instance.new("Part")
    eggPart.Name = "Egg_" .. egg.Id
    eggPart.Size = Vector3.new(2, 3, 2)
    eggPart.Shape = Enum.PartType.Ball
    eggPart.Anchored = true
    eggPart.CanCollide = false
    eggPart.Material = Enum.Material.SmoothPlastic
    eggPart.Color = elementColor(egg.Element)

    local eggTag = Instance.new("StringValue")
    eggTag.Name = "EggId"
    eggTag.Value = egg.Id
    eggTag.Parent = eggPart

    -- Position egg above incubator primarypart, spread eggs if many
    local count = 0 for _ in pairs(info.eggs) do count = count + 1 end
    local angle = (count % 6) * (math.pi * 2 / 6)
    local radius = 2
    local offset = Vector3.new(math.cos(angle) * radius, 2.5, math.sin(angle) * radius)
    eggPart.CFrame = primary.CFrame * CFrame.new(offset)

    eggPart.Parent = incubatorModel
    info.eggs[egg.Id] = eggPart

    -- Simple bob animation
    local startCFrame = eggPart.CFrame
    local phase = math.random() * math.pi * 2
    local conn
    conn = RunService.Heartbeat:Connect(function(t)
        if not eggPart.Parent then
            conn:Disconnect()
            return
        end
        local y = math.sin(t + phase) * 0.25
        eggPart.CFrame = startCFrame * CFrame.new(0, y, 0)
    end)

    -- If egg is ready (choca), add small glow (PointLight)
    if egg.ReadyAt and egg.ReadyAt <= os.time() then
        local light = Instance.new("PointLight")
        light.Name = "EggGlow"
        light.Color = Color3.new(1, 0.9, 0.6)
        light.Brightness = 2
        light.Range = 8
        light.Parent = eggPart
    end

    return eggPart
end

-- Remove egg visual by eggId
function IncubatorVisualizer.RemoveEgg(eggId)
    for bid, info in pairs(incubators) do
        if info.eggs[eggId] then
            local part = info.eggs[eggId]
            if part and part.Parent then part:Destroy() end
            info.eggs[eggId] = nil
            return true
        end
    end
    return false
end

-- Update egg ready/visual state (call when egg becomes ready)
function IncubatorVisualizer.MarkEggReady(eggId)
    for bid, info in pairs(incubators) do
        local part = info.eggs[eggId]
        if part and part.Parent then
            if not part:FindFirstChild("EggGlow") then
                local light = Instance.new("PointLight")
                light.Name = "EggGlow"
                light.Color = Color3.new(1, 0.9, 0.6)
                light.Brightness = 2
                light.Range = 8
                light.Parent = part
            end
            return true
        end
    end
    return false
end

return IncubatorVisualizer
