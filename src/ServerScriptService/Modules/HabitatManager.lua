--[[
	HabitatManager - Funções helper para gerenciar habitats e dragões
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

return HabitatManager
