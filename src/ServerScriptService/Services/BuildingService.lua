--[[]]
BuildingService - Gerencia compra e colocação de construções
Melhorias:
- Ao colocar um Habitat, tenta reatribuir dragões arquivados automaticamente.
- Ao guardar (store) uma construção Habitat, arquiva dragões que estavam naquele habitat.
- Usa FloatingBase para registrar modelos flutuantes.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local HabitatManager = require(script.Parent.Parent.Modules.HabitatManager)
local FloatingBase = require(script.Parent.Parent.Modules.FloatingBase)

local BuildingService = {}
BuildingService.Handlers = {}

-- Gera ID único para building
local function generateId(profile)
    local id = "B_" .. profile.NextId
    profile.NextId = profile.NextId + 1
    return id
end

-- Compra construção e adiciona ao inventário
BuildingService.Handlers.BuyBuilding = function(player, buildingType, element)
    local profile = Data.Get(player)
    if not profile then return false, "Perfil não carregado" end

    local buildingConfig = Config.Buildings[buildingType]
    if not buildingConfig then return false, "Tipo de construção inválido" end

    local cost = buildingConfig.Cost or buildingConfig.BaseCost
    if profile.Gold < cost then
        return false, "Ouro insuficiente"
    end

    -- Para Habitats, precisa especificar elemento
    if buildingType == "Habitat" and not element then
        return false, "Elemento não especificado"
    end
    if buildingType == "Habitat" and not table.find(Config.Elements, element) then
        return false, "Elemento inválido"
    end

    -- Deduz ouro
    profile.Gold = profile.Gold - cost

    -- Cria building data
    local buildingId = generateId(profile)
    local buildingData = {
        Id = buildingId,
        Type = buildingType,
        Element = element, -- nil para Farm/Incubator
        Level = 1,
        PurchasedAt = os.time(),
    }

    -- Adiciona ao inventário
    profile.Buildings.Inventory[buildingId] = buildingData

    Data.Push(player)
    return true, buildingData
end

-- Coloca construção no plot
BuildingService.Handlers.PlaceBuilding = function(player, buildingId, position, rotation)
    local profile = Data.Get(player)
    if not profile then return false, "Perfil não carregado" end

    -- Valida que building existe no inventário
    local buildingData = profile.Buildings.Inventory[buildingId]
    if not buildingData then
        return false, "Construção não encontrada no inventário"
    end

    print("[BuildingService] PlaceBuilding: " .. buildingId .. " em " .. tostring(position))

    -- Valida posição dentro do plot
    if not PlotService.IsInPlot(player, position) then
        return false, "Fora dos limites do plot"
    end

    -- TODO: validar colisão (por enquanto aceita tudo)

    -- Move de Inventory para Placed
    profile.Buildings.Inventory[buildingId] = nil
    buildingData.Position = {position.X, position.Y, position.Z}
    buildingData.Rotation = rotation or 0
    profile.Buildings.Placed[buildingId] = buildingData

    print("[BuildingService] Building salvo em Placed")

    -- Instanciar físicamente
    BuildingService.InstantiateBuilding(player, buildingData)

    -- Se for Habitat, tentar reatribuir dragões arquivados
    if buildingData.Type == "Habitat" then
        local assigned = HabitatManager.ReassignArchivedDragons(profile, buildingId, player)
        if assigned and assigned > 0 then
            print("[BuildingService] Reatribuiu " .. assigned .. " dragões arquivados para habitat " .. buildingId)
        end
    end

    Data.Push(player)
    return true
end

-- Move construção para nova posição
BuildingService.Handlers.MoveBuilding = function(player, buildingId, position, rotation)
    local profile = Data.Get(player)
    if not profile then return false, "Perfil não carregado" end

    local buildingData = profile.Buildings.Placed[buildingId]
    if not buildingData then
        return false, "Construção não encontrada"
    end

    if not PlotService.IsInPlot(player, position) then
        return false, "Fora dos limites do plot"
    end

    -- Atualiza posição
    buildingData.Position = {position.X, position.Y, position.Z}
    buildingData.Rotation = rotation or buildingData.Rotation

    -- Atualiza físico
    local plotData = PlotService.GetPlot(player)
    if plotData then
        local existing = plotData.Folder:FindFirstChild("Building_" .. buildingId)
        if existing then
            local pos = Vector3.new(unpack(buildingData.Position))
            existing:SetPrimaryPartCFrame(CFrame.new(pos) * CFrame.Angles(0, math.rad(buildingData.Rotation), 0))
        end
    end

    Data.Push(player)
    return true
end

-- Guarda construção de volta no inventário
BuildingService.Handlers.StoreBuilding = function(player, buildingId)
    local profile = Data.Get(player)
    if not profile then return false, "Perfil não carregado" end

    local buildingData = profile.Buildings.Placed[buildingId]
    if not buildingData then
        return false, "Construção não encontrada"
    end

    -- Se for Habitat, arquiva dragões que estavam naquele habitat
    if buildingData.Type == "Habitat" then
        for dragonId, dragon in pairs(profile.Dragons) do
            if dragon.HabitatId == buildingId then
                dragon.Archived = true
                dragon.HabitatId = nil
                -- Remove do time se estiver
                local tIdx = table.find(profile.Team, dragonId)
                if tIdx then table.remove(profile.Team, tIdx) end
                -- Remove modelo 3D do mundo
                local ok, DragonSpawner = pcall(require, script.Parent.Parent.Modules.DragonSpawner)
                if ok and DragonSpawner then
                    pcall(function() DragonSpawner.RemoveDragon(dragonId) end)
                end
            end
        end
    end

    -- Move para inventário
    profile.Buildings.Placed[buildingId] = nil
    buildingData.Position = nil
    buildingData.Rotation = nil
    profile.Buildings.Inventory[buildingId] = buildingData

    -- Remove físico
    local plotData = PlotService.GetPlot(player)
    if plotData then
        local existing = plotData.Folder:FindFirstChild("Building_" .. buildingId)
        if existing then
            -- Unregister from floating base if needed
            pcall(function()
                FloatingBase.Unregister(existing)
            end)
            existing:Destroy()
        end
    end

    Data.Push(player)
    return true
end

-- Instancia construção no mundo (modelo simples por enquanto)
function BuildingService.InstantiateBuilding(player, buildingData)
    local plotData = PlotService.GetPlot(player)
    if not plotData then
        warn("[BuildingService] Plot não encontrado para " .. player.Name)
        return
    end

    local buildingConfig = Config.Buildings[buildingData.Type]
    if not buildingConfig then
        warn("[BuildingService] Config não encontrada para " .. buildingData.Type)
        return
    end

    local position = Vector3.new(unpack(buildingData.Position))
    local size = buildingConfig.Size

    print("[BuildingService] Instanciando " .. buildingData.Type .. " em " .. tostring(position))

    -- Cria modelo simples (um Part por enquanto)
    local model = Instance.new("Model")
    model.Name = "Building_" .. buildingData.Id

    local part = Instance.new("Part")
    part.Name = "Base"
    part.Size = size
    -- Posição: recebemos a base (Y do chão), então adicionamos metade da altura
    part.Position = position + Vector3.new(0, size.Y/2, 0)
    part.Anchored = true
    part.Material = Enum.Material.Wood
    part.CanCollide = true

    -- Cor por tipo
    if buildingData.Type == "Farm" then
        part.BrickColor = BrickColor.new("Bright yellow")
    elseif buildingData.Type == "Incubator" then
        part.BrickColor = BrickColor.new("Light stone grey")
    elseif buildingData.Type == "Habitat" then
        local elementColor = Config.ElementColors[buildingData.Element]
        part.Color = elementColor or Color3.new(1, 1, 1)
    end

    part.Parent = model
    model.PrimaryPart = part

    -- Rotação
    local rotation = buildingData.Rotation or 0
    model:SetPrimaryPartCFrame(CFrame.new(part.Position) * CFrame.Angles(0, math.rad(rotation), 0))

    -- Tag para identificar
    local tag = Instance.new("StringValue")
    tag.Name = "BuildingId"
    tag.Value = buildingData.Id
    tag.Parent = model

    model.Parent = plotData.Folder

    -- Se Habitat: registrar flutuação e tornar maior visualmente
    if buildingData.Type == "Habitat" then
        -- aumentar visual sem alterar colisão (escala do Mesh eventualmente)
        pcall(function()
            -- tentativa simples: aumentar PrimaryPart Y offset to appear larger
            local f = model.PrimaryPart
            -- registrar para flutuar
            FloatingBase.Register(model, 3, 0.9)
        end)
    end

    print("[BuildingService] Building instanciado: " .. model.Name)
end

-- Carregar construções colocadas ao entrar
function BuildingService.LoadPlacedBuildings(player)
    local profile = Data.Get(player)
    if not profile then return end

    for buildingId, buildingData in pairs(profile.Buildings.Placed) do
        BuildingService.InstantiateBuilding(player, buildingData)
    end
end

return BuildingService
