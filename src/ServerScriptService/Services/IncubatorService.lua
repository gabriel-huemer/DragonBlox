--[[
BuildingService - Gerencia compra, colocação e gestão de construções.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local HabitatManager = require(script.Parent.Parent.Modules.HabitatManager)
local FloatingBase = require(script.Parent.Parent.Modules.FloatingBase)

local okIncViz, IncubatorVisualizer = pcall(require, script.Parent.Parent.Modules.IncubatorVisualizer)
if not okIncViz then
    IncubatorVisualizer = nil
end

local BuildingService = {}
BuildingService.Handlers = {}

local function generateId(profile)
    local id = "B_" .. profile.NextId
    profile.NextId = profile.NextId + 1
    return id
end

local function ensureHabitatSlots(profile)
    if profile.HabitatSlots == nil then
        profile.HabitatSlots = Config.HabitatBaseSlots
    end
end

BuildingService.Handlers.BuyBuilding = function(player, buildingType, element)
    local profile = Data.Get(player)
    if not profile then return false, "Perfil não carregado" end

    ensureHabitatSlots(profile)

    local buildingConfig = Config.Buildings[buildingType]
    if not buildingConfig then return false, "Tipo de construção inválido" end

    local cost = buildingConfig.Cost or buildingConfig.BaseCost
    if profile.Gold < cost then
        return false, "Ouro insuficiente"
    end

    if buildingType == "Habitat" and not element then
        return false, "Elemento não especificado"
    end
    if buildingType == "Habitat" and not table.find(Config.Elements, element) then
        return false, "Elemento inválido"
    end

    profile.Gold = profile.Gold - cost

    local buildingId = generateId(profile)
    local buildingData = {
        Id = buildingId,
        Type = buildingType,
        Element = element,
        Level = 1,
        PurchasedAt = os.time(),
    }

    profile.Buildings.Inventory[buildingId] = buildingData
    Data.Push(player)
    return true, buildingData
end

BuildingService.Handlers.PlaceBuilding = function(player, buildingId, position, rotation)
    local profile = Data.Get(player)
    if not profile then return false, "Perfil não carregado" end

    local buildingData = profile.Buildings.Inventory[buildingId]
    if not buildingData then return false, "Construção não encontrada no inventário" end

    if not PlotService.IsInPlot(player, position) then
        return false, "Fora dos limites do plot"
    end

    buildingData.Position = position
    buildingData.Rotation = rotation or 0
    profile.Buildings.Placed[buildingId] = buildingData
    profile.Buildings.Inventory[buildingId] = nil

    if buildingData.Type == "Habitat" then
        local dragonList = {}
        for _, dragon in pairs(profile.Dragons) do
            if dragon.Archived and dragon.HabitatId == nil then
                table.insert(dragonList, dragon)
            end
        end

        local count = 0
        for _, dragon in pairs(dragonList) do
            if count >= Config.MaxDragonsPerHabitat then break end
            if dragon and dragon.Element == buildingData.Element then
                dragon.HabitatId = buildingId
                dragon.Archived = false
                count += 1
            end
        end
    end

    Data.Push(player)
    return true
end

function BuildingService.LoadPlacedBuildings(player)
    local profile = Data.Get(player)
    if not profile then return end
    for _, building in pairs(profile.Buildings.Placed) do
        if building.Type == "Incubator" and IncubatorVisualizer then
            pcall(function()
                IncubatorVisualizer.RegisterIncubator(building.Model, player, building.Id)
            end)
        end
    end
end

function BuildingService.StoreBuilding(player, buildingId)
    local profile = Data.Get(player)
    if not profile then return false end

    local building = profile.Buildings.Placed[buildingId]
    if not building then return false end

    if building.Type == "Habitat" then
        for _, dragon in pairs(profile.Dragons) do
            if dragon.HabitatId == buildingId and not dragon.Archived then
                dragon.Archived = true
                dragon.HabitatId = nil
            end
        end
    elseif building.Type == "Incubator" and IncubatorVisualizer then
        IncubatorVisualizer.UnregisterIncubator(buildingId)
    end

    profile.Buildings.Inventory[buildingId] = {
        Id = building.Id,
        Type = building.Type,
        Element = building.Element,
        Level = building.Level,
        PurchasedAt = building.PurchasedAt,
    }
    profile.Buildings.Placed[buildingId] = nil

    Data.Push(player)
    return true
end

return BuildingService
