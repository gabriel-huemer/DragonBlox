--[[
HabitatManager - Funções helper para gerenciar habitats e dragões
Enhancements: reatribuição de dragões arquivados quando um habitat é colocado.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local HabitatManager = {}

-- Retorna lista de habitats do jogador (só os colocados no mundo)
function HabitatManager.GetPlacedHabitats(profile)
    local habitats = {}
    for buildingId, building in pairs(profile.Buildings.Placed) do
        if building.Type == "Habitat" then
            table.insert(habitats, {
                Id = buildingId,
                Element = building.Element,
            })
        end
    end
    return habitats
end

-- Conta quantos dragões estão em um habitat
function HabitatManager.CountDragonsInHabitat(profile, habitatId)
    local count = 0
    for _, dragon in pairs(profile.Dragons) do
        if dragon.HabitatId == habitatId and not dragon.Archived then
            count = count + 1
        end
    end
    return count
end

-- Encontra um habitat disponível para um elemento
function HabitatManager.FindAvailableHabitat(profile, element)
    local habitats = HabitatManager.GetPlacedHabitats(profile)

    for _, habitat in ipairs(habitats) do
        if habitat.Element == element then
            local count = HabitatManager.CountDragonsInHabitat(profile, habitat.Id)
            if count < Config.MaxDragonsPerHabitat then
                return habitat.Id
            end
        end
    end

    return nil
end

-- Verifica se pode chocar um ovo (tem habitat disponível)
function HabitatManager.CanHatchEgg(profile, element)
    return HabitatManager.FindAvailableHabitat(profile, element) ~= nil
end

-- Conta dragões ativos (não arquivados)
function HabitatManager.CountActiveDragons(profile)
    local count = 0
    for _, dragon in pairs(profile.Dragons) do
        if not dragon.Archived then
            count = count + 1
        end
    end
    return count
end

-- Conta dragões arquivados
function HabitatManager.CountArchivedDragons(profile)
    local count = 0
    for _, dragon in pairs(profile.Dragons) do
        if dragon.Archived then
            count = count + 1
        end
    end
    return count
end

-- Verifica se incubadora tem espaço
function HabitatManager.CanAddEgg(profile)
    return #profile.Eggs < profile.IncubatorSlots
end

-- Reassign archived dragons to a newly placed habitat when possible.
-- profile: player profile table (server-side)
-- habitatId: id of the placed habitat just created
-- player: Player object (optional). If present, Dragons will be spawned in world.
function HabitatManager.ReassignArchivedDragons(profile, habitatId, player)
    local placed = profile.Buildings.Placed[habitatId]
    if not placed or placed.Type ~= "Habitat" then return 0 end

    local capacity = Config.MaxDragonsPerHabitat
    local current = HabitatManager.CountDragonsInHabitat(profile, habitatId)
    local freeSlots = capacity - current
    if freeSlots <= 0 then return 0 end

    local assigned = 0
    for dragonId, dragon in pairs(profile.Dragons) do
        if assigned >= freeSlots then break end
        if dragon.Archived and dragon.Element == placed.Element then
            dragon.Archived = false
            dragon.HabitatId = habitatId
            -- ensure not duplicated in team
            if #profile.Team < 3 then table.insert(profile.Team, dragonId) end

            -- spawn model if player provided
            if player then
                local ok, DragonSpawner = pcall(function()
                    return require(script.Parent:FindFirstChild("DragonSpawner"))
                end)
                if ok and DragonSpawner then
                    pcall(function() DragonSpawner.SpawnDragon(player, dragon, profile) end)
                end
            end

            assigned = assigned + 1
        end
    end

    return assigned
end

return HabitatManager
