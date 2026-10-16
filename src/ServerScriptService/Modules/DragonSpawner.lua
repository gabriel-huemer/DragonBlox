--[[]]
DragonSpawner - Gerencia spawn de dragões nos habitats
Melhorias: defesa contra inconsistências e robustez.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local DragonUtil = require(Shared:WaitForChild("DragonUtil"))
local DragonModelFactory = require(script.Parent:WaitForChild("DragonModelFactory"))

local DragonSpawner = {}

-- Cache de modelos de dragões spawnados (dragonId -> model)
local spawnedDragons = {}

-- Spawna todos os dragões de um jogador nos habitats
function DragonSpawner.SpawnAllDragons(player, profile)
    print("[DragonSpawner] SpawnAllDragons chamado para " .. player.Name)

    -- Remove dragões existentes
    DragonSpawner.RemoveAllDragons(player)

    -- Spawna dragões ativos
    local count = 0
    for dragonId, dragon in pairs(profile.Dragons) do
        print("[DragonSpawner] Dragão " .. dragonId .. " - Archived: " .. tostring(dragon.Archived) .. ", HabitatId: " .. tostring(dragon.HabitatId))
        if not dragon.Archived and dragon.HabitatId then
            -- validar que habitat ainda existe
            local building = profile.Buildings.Placed[dragon.HabitatId]
            if building and building.Type == "Habitat" then
                DragonSpawner.SpawnDragon(player, dragon, profile)
                count = count + 1
            else
                warn("[DragonSpawner] Habitat inválido para dragon " .. dragonId .. ", arquivando.")
                dragon.Archived = true
                dragon.HabitatId = nil
            end
        end
    end

    print("[DragonSpawner] Total spawnado: " .. count)
end

-- Spawna um dragão em seu habitat
function DragonSpawner.SpawnDragon(player, dragon, profile)
    if not dragon or not dragon.Id then return end
    print("[DragonSpawner] SpawnDragon chamado para dragão " .. dragon.Id)

    -- Busca o building do habitat
    local building = profile.Buildings.Placed[dragon.HabitatId]
    if not building then
        warn("[DragonSpawner] Habitat não encontrado para dragão " .. dragon.Id)
        return
    end

    -- Cria modelo 3D
    local ok, model = pcall(function()
        return DragonModelFactory.Create(dragon)
    end)
    if not ok or not model then
        warn("[DragonSpawner] Falha ao criar modelo para " .. tostring(dragon.Id))
        return
    end

    -- Posiciona no habitat (dentro da área do building)
    local habitatPos = Vector3.new(unpack(building.Position))
    local offset = Vector3.new(
        math.random(-6, 6),
        2,
        math.random(-6, 6)
    )

    model:SetPrimaryPartCFrame(CFrame.new(habitatPos + offset))

    -- Tag para identificar dono
    local ownerTag = Instance.new("ObjectValue")
    ownerTag.Name = "Owner"
    ownerTag.Value = player
    ownerTag.Parent = model

    local habitatTag = Instance.new("StringValue")
    habitatTag.Name = "HabitatId"
    habitatTag.Value = dragon.HabitatId
    habitatTag.Parent = model

    -- Parent para workspace
    model.Parent = workspace

    -- Cache
    spawnedDragons[dragon.Id] = model

    -- Adiciona AI básico
    DragonSpawner.AddAI(model, habitatPos, building)

    -- Adiciona geração de moedas
    DragonSpawner.AddCoinGeneration(model, dragon, player)

    return model
end

-- Remove todos os dragões de um jogador
function DragonSpawner.RemoveAllDragons(player)
    for dragonId, model in pairs(spawnedDragons) do
        local owner = model:FindFirstChild("Owner")
        if owner and owner.Value == player then
            model:Destroy()
            spawnedDragons[dragonId] = nil
        end
    end
end

-- Remove um dragão específico
function DragonSpawner.RemoveDragon(dragonId)
    local model = spawnedDragons[dragonId]
    if model then
        model:Destroy()
        spawnedDragons[dragonId] = nil
    end
end

-- AI básico: dragão caminha aleatoriamente dentro do habitat
function DragonSpawner.AddAI(model, habitatCenter, building)
    local humanoid = model:FindFirstChild("Humanoid")
    if not humanoid then return end

    local habitatSize = building.Size or Config.Buildings.Habitat.Size
    local halfSize = habitatSize / 2

    task.spawn(function()
        while model.Parent and humanoid.Health > 0 do
            local randomOffset = Vector3.new(
                math.random(-math.max(1, halfSize.X - 3), math.max(1, halfSize.X - 3)),
                0,
                math.random(-math.max(1, halfSize.Z - 3), math.max(1, halfSize.Z - 3))
            )

            local targetPos = habitatCenter + randomOffset

            -- Move para lá
            humanoid:MoveTo(targetPos)

            -- Espera chegar ou timeout
            local timeout = 10
            local startTime = tick()
            repeat
                task.wait(0.5)
            until (model.PrimaryPart.Position - targetPos).Magnitude < 4 or tick() - startTime > timeout

            -- Pausa antes do próximo movimento
            task.wait(math.random(2, 5))
        end
    end)
end

-- Adiciona geração de moedas (spawn visual de coins que o player coleta)
function DragonSpawner.AddCoinGeneration(model, dragon, player)
    -- Calcula produção por segundo
    local rarityIdx = Config.RarityIndex[dragon.Rarity] or 1
    local rarityData = Config.Rarities[rarityIdx]
    local goldPerSecond = Config.GoldPerLevelPerSecond * dragon.Level * rarityData.GoldMult
    if dragon.Shiny then
        goldPerSecond = goldPerSecond * 1.5
    end

    -- Intervalo entre coins (mínimo 2 segundos)
    local interval = math.max(2, 10 / math.max(0.1, goldPerSecond))

    task.spawn(function()
        while model.Parent do
            task.wait(interval)

            -- Não gerar coins se dragão arquivado
            -- Encontrar dragon by id via owner profile isn't direct here; rely on the fact that model exists only for active dragons
            DragonSpawner.SpawnCoin(model.PrimaryPart.Position, player, 1)
        end
    end)
end

-- Spawna uma moeda coletável
function DragonSpawner.SpawnCoin(position, player, value)
    local coin = Instance.new("Part")
    coin.Name = "Coin"
    coin.Size = Vector3.new(1, 0.2, 1)
    coin.Shape = Enum.PartType.Cylinder
    coin.Color = Color3.fromRGB(255, 220, 60)
    coin.Material = Enum.Material.Neon
    coin.Anchored = true
    coin.CanCollide = false
    coin.CFrame = CFrame.new(position + Vector3.new(0, 2, 0)) * CFrame.Angles(0, 0, math.pi/2)

    -- Tag
    local ownerTag = Instance.new("ObjectValue")
    ownerTag.Name = "Owner"
    ownerTag.Value = player
    ownerTag.Parent = coin

    local valueTag = Instance.new("IntValue")
    valueTag.Name = "Value"
    valueTag.Value = value
    valueTag.Parent = coin

    coin.Parent = workspace

    -- Animação de rotação
    task.spawn(function()
        while coin.Parent do
            coin.CFrame = coin.CFrame * CFrame.Angles(0, math.rad(2), 0)
            task.wait(0.03)
        end
    end)

    -- Destrói após 30 segundos
    task.delay(30, function()
        if coin.Parent then
            coin:Destroy()
        end
    end)

    return coin
end

return DragonSpawner
