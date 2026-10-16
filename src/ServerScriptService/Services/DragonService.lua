--[[]]
DragonService (ModuleScript)
Responsabilidades expandidas:
- Garantir invariantes: não existir dragão ativo sem habitat.
- Fornecer função EnsureIntegrity(player, profile) para corrigir estados inválidos.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)
local DragonUtil = require(ReplicatedStorage.Shared.DragonUtil)
local Data = require(script.Parent.DataService)
local HabitatManager = require(script.Parent.Parent.Modules.HabitatManager)

local DragonService = {}
DragonService.Handlers = {}

-- bonus: aumenta o peso das raridades altas. maxIndex: limita a raridade máxima (ex.: ovo básico)
function DragonService.RollRarity(bonus, maxIndex)
    bonus = bonus or 0
    maxIndex = maxIndex or #Config.Rarities
    local pool = {}
    for i = 1, maxIndex do
        pool[i] = i
    end
    local idx = DragonUtil.WeightedPick(pool, function(i)
        return Config.Rarities[i].Weight * (1 + bonus * (i - 1))
    end)
    return Config.Rarities[idx].Name
end

function DragonService.RollShiny(chance)
    return math.random() < (chance or Config.ShinyChance)
end

function DragonService.New(element, rarity, shiny)
    return { Element = element, Rarity = rarity, Shiny = shiny or false, Level = 1, Archived = false, HabitatId = nil }
end

function DragonService.Add(player, dragon)
    local profile = Data.Get(player)
    local id = "d" .. profile.NextId
    profile.NextId += 1
    dragon.Id = id

    -- Atribui habitat automaticamente se disponível
    local habitatId = HabitatManager.FindAvailableHabitat(profile, dragon.Element)
    dragon.HabitatId = habitatId
    dragon.Archived = habitatId == nil -- arquiva se não tiver habitat

    -- Só adiciona ao time se não estiver arquivado
    if not dragon.Archived and #profile.Team < 3 then
        table.insert(profile.Team, id)
    end

    profile.Dragons[id] = dragon

    return dragon
end

-- Ensure invariants: no active dragon without a valid habitat. If found, archive it and remove model.
function DragonService.EnsureIntegrity(player, profile)
    local ok, DragonSpawner = pcall(require, script.Parent.Parent.Modules.DragonSpawner)
    for dragonId, dragon in pairs(profile.Dragons) do
        if not dragon.Archived then
            local hid = dragon.HabitatId
            local valid = hid and profile.Buildings.Placed[hid] and profile.Buildings.Placed[hid].Type == "Habitat"
            if not valid then
                -- archive the dragon safely
                dragon.Archived = true
                dragon.HabitatId = nil
                -- remove from team
                local tIdx = table.find(profile.Team, dragonId)
                if tIdx then table.remove(profile.Team, tIdx) end
                -- remove 3D model if present
                if ok and DragonSpawner then
                    pcall(function() DragonSpawner.RemoveDragon(dragonId) end)
                end
            end
        end
    end
    -- push changes
    Data.Push(player)
end

---------------------------------------------------------------------
-- HANDLERS (chamados pelo cliente via Remotes.Request)
---------------------------------------------------------------------
function DragonService.Handlers.Feed(player, id)
    local profile = Data.Get(player)
    local d = type(id) == "string" and profile.Dragons[id]
    if not d then
        return false, "Dragão inválido."
    end
    if d.Level >= Config.MaxLevel then
        return false, "Esse dragão já está no nível máximo."
    end
    local cost = DragonUtil.FeedCost(d.Level)
    if profile.Apples < cost then
        return false, "Maçãs insuficientes (" .. cost .. ")."
    end
    profile.Apples -= cost
    d.Level += 1
    Data.Push(player)
    return true, d.Level
end

function DragonService.Handlers.ToggleTeam(player, id)
    local profile = Data.Get(player)
    if type(id) ~= "string" or not profile.Dragons[id] then
        return false, "Dragão inválido."
    end
    local idx = table.find(profile.Team, id)
    if idx then
        table.remove(profile.Team, idx)
    else
        if #profile.Team >= 3 then
            return false, "Seu time já tem 3 dragões."
        end
        table.insert(profile.Team, id)
    end
    Data.Push(player)
    return true
end

-- Arquiva dragão (remove do habitat, para de produzir ouro)
function DragonService.Handlers.ArchiveDragon(player, dragonId)
    local profile = Data.Get(player)
    local dragon = profile.Dragons[dragonId]
    if not dragon then
        return false, "Dragão não encontrado"
    end

    if dragon.Archived then
        return false, "Dragão já está arquivado"
    end

    dragon.Archived = true
    dragon.HabitatId = nil

    -- Remove do time se estiver
    local teamIdx = table.find(profile.Team, dragonId)
    if teamIdx then
        table.remove(profile.Team, teamIdx)
    end

    -- Remove modelo 3D do mundo
    local ok, DragonSpawner = pcall(require, script.Parent.Parent.Modules.DragonSpawner)
    if ok and DragonSpawner then
        DragonSpawner.RemoveDragon(dragonId)
    end

    Data.Push(player)
    return true
end

-- Desarquiva dragão (tenta colocar em habitat disponível)
function DragonService.Handlers.UnarchiveDragon(player, dragonId)
    local profile = Data.Get(player)
    local dragon = profile.Dragons[dragonId]
    if not dragon then
        return false, "Dragão não encontrado"
    end

    if not dragon.Archived then
        return false, "Dragão não está arquivado"
    end

    -- Precisa de habitat disponível
    local habitatId = HabitatManager.FindAvailableHabitat(profile, dragon.Element)
    if not habitatId then
        return false, "Nenhum habitat disponível para " .. DragonUtil.ElementLabel(dragon.Element)
    end

    dragon.Archived = false
    dragon.HabitatId = habitatId

    -- Spawna modelo 3D no mundo
    local ok, DragonSpawner = pcall(require, script.Parent.Parent.Modules.DragonSpawner)
    if ok and DragonSpawner then
        DragonSpawner.SpawnDragon(player, dragon, profile)
    end

    Data.Push(player)
    return true
end

-- Vende dragão (recebe ouro)
function DragonService.Handlers.SellDragon(player, dragonId)
    local profile = Data.Get(player)
    local dragon = profile.Dragons[dragonId]
    if not dragon then
        return false, "Dragão não encontrado"
    end

    -- Calcula valor
    local baseValue = Config.DragonSellValue[dragon.Rarity] or 50
    local value = baseValue * (dragon.Shiny and 2 or 1)

    -- Remove do time se estiver
    local teamIdx = table.find(profile.Team, dragonId)
    if teamIdx then
        table.remove(profile.Team, teamIdx)
    end

    -- Remove modelo 3D do mundo
    local ok, DragonSpawner = pcall(require, script.Parent.Parent.Modules.DragonSpawner)
    if ok and DragonSpawner then
        DragonSpawner.RemoveDragon(dragonId)
    end

    -- Remove dragão
    profile.Dragons[dragonId] = nil

    -- Adiciona ouro
    profile.Gold += value

    Data.Push(player)
    return true, value
end

return DragonService
