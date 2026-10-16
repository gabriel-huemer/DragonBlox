--[[
	EconomyService (ModuleScript)
	Local no Studio: ServerScriptService > Services > EconomyService
	Ouro (dragões nos habitats), Maçãs (fazenda), upgrades.
	Produção é calculada por TEMPO DECORRIDO (funciona offline, sem loops por jogador).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DragonUtil = require(ReplicatedStorage.Shared.DragonUtil)
local Data = require(script.Parent.DataService)

local EconomyService = {}
EconomyService.Handlers = {}

local function collectGold(profile)
	local now = os.time()
	local elapsed = math.clamp(now - profile.LastGoldCollect, 0, Config.OfflineCapSeconds)
	local gained = math.floor(DragonUtil.TotalGoldPerSecond(profile) * elapsed)
	if gained > 0 then
		profile.LastGoldCollect = now
		profile.Gold += gained
	end
	return gained
end

local function harvest(profile)
	local now = os.time()
	local elapsed = math.clamp(now - profile.LastHarvest, 0, Config.OfflineCapSeconds)
	local gained = math.floor(elapsed * Config.FarmApplesPerSecond * profile.FarmLevel)
	if gained > 0 then
		profile.LastHarvest = now
		profile.Apples += gained
	end
	return gained
end

function EconomyService.Handlers.CollectGold(player)
	local profile = Data.Get(player)
	local gained = collectGold(profile)
	Data.Push(player)
	return true, gained
end

function EconomyService.Handlers.HarvestApples(player)
	local profile = Data.Get(player)
	local gained = harvest(profile)
	Data.Push(player)
	return true, gained
end

function EconomyService.Handlers.UpgradeFarm(player)
	local profile = Data.Get(player)
	
	-- Verificar se tem fazenda colocada ou no inventário
	local hasFarm = false
	for _, building in pairs(profile.Buildings.Placed) do
		if building.Type == "Farm" then
			hasFarm = true
			break
		end
	end
	if not hasFarm then
		for _, building in pairs(profile.Buildings.Inventory) do
			if building.Type == "Farm" then
				hasFarm = true
				break
			end
		end
	end
	
	if not hasFarm then
		return false, "Você precisa comprar uma Fazenda primeiro!"
	end
	
	if profile.FarmLevel >= Config.MaxFarmLevel then
		return false, "Fazenda no nível máximo."
	end
	local cost = Config.FarmUpgradeCost(profile.FarmLevel)
	if profile.Gold < cost then
		return false, "Ouro insuficiente (" .. cost .. ")."
	end
	harvest(profile) -- liquida a produção antiga antes de mudar a taxa
	profile.Gold -= cost
	profile.FarmLevel += 1
	Data.Push(player)
	return true
end

function EconomyService.Handlers.BuyHabitat(player)
	local profile = Data.Get(player)
	if profile.HabitatSlots >= Config.MaxHabitatSlots then
		return false, "Você já tem o máximo de habitats."
	end
	local cost = Config.HabitatSlotCost(profile.HabitatSlots)
	if profile.Gold < cost then
		return false, "Ouro insuficiente (" .. cost .. ")."
	end
	collectGold(profile)
	profile.Gold -= cost
	profile.HabitatSlots += 1
	Data.Push(player)
	return true
end

return EconomyService
