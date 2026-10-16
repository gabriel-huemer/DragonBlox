--[[
 FloatingBase - centraliza animação de flutuação para buildings do tipo Habitat
 Coloque este ModuleScript em ServerScriptService.Modules.FloatingBase
]]

local RunService = game:GetService("RunService")

local FloatingBase = {}

local tracked = {} -- model -> {origin = CFrame, amplitude, speed, phase}

-- Registra um model para flutuar (model.PrimaryPart deve existir)
function FloatingBase.Register(model, amplitude, speed)
    if not model or not model.PrimaryPart then return end
    amplitude = amplitude or 3
    speed = speed or 0.8
    tracked[model] = { origin = model.PrimaryPart.CFrame, amplitude = amplitude, speed = speed, phase = math.random() * math.pi * 2 }
end

function FloatingBase.Unregister(model)
    tracked[model] = nil
end

-- Limpa rastreamento quando model destruído
local function cleanup()
    for m, _ in pairs(tracked) do
        if not m.Parent then tracked[m] = nil end
    end
end

RunService.Heartbeat:Connect(function(dt)
    cleanup()
    local t = tick()
    for model, info in pairs(tracked) do
        if model and model.PrimaryPart and model.Parent then
            local origin = info.origin
            local y = math.sin(t * info.speed + info.phase) * info.amplitude
            local target = origin + Vector3.new(0, y, 0)
            -- Ler rotação e posição base a partir do origin CFrame
            local rot = origin - origin.p
            model:SetPrimaryPartCFrame(CFrame.new(target.p) * rot)
        end
    end
end)

return FloatingBase
