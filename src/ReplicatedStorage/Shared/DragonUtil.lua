--[[
	DragonUtil (ModuleScript)
	Local no Studio: ReplicatedStorage > Shared > DragonUtil
	Funções puras usadas pelo servidor E pelo cliente (status, custos, formatação).
]]

local Config = require(script.Parent.Config)

local DragonUtil = {}

function DragonUtil.GetStats(d)
	local rarityData = Config.Rarities[Config.RarityIndex[d.Rarity]]
	if not rarityData then
		warn("[DragonUtil] Raridade inválida: " .. tostring(d.Rarity))
		rarityData = Config.Rarities[1] -- fallback para Comum
	end
	
	local mult = rarityData.StatMult * (d.Shiny and Config.ShinyMult or 1)
	local bias = Config.ElementBias[d.Element] or {}
	local stats = {}
	for stat, base in pairs(Config.BaseStats) do
		local value = (base + Config.StatGrowth[stat] * (d.Level - 1)) * mult * (bias[stat] or 1)
		stats[stat] = math.floor(value)
	end
	return stats
end

function DragonUtil.FeedCost(level)
	return 4 + level * 2
end

function DragonUtil.GoldPerSecond(d)
	-- Ovos não têm raridade ainda
	if not d.Rarity then
		return 0
	end
	
	local rarityData = Config.Rarities[Config.RarityIndex[d.Rarity]]
	if not rarityData then
		warn("[DragonUtil] Raridade inválida em GoldPerSecond: " .. tostring(d.Rarity))
		rarityData = Config.Rarities[1]
	end
	return Config.GoldPerLevelPerSecond * d.Level * rarityData.GoldMult * (d.Shiny and 2 or 1)
end

-- Só os N melhores dragões (N = slots de habitat) produzem ouro
function DragonUtil.TotalGoldPerSecond(profile)
	local rates = {}
	for _, d in pairs(profile.Dragons) do
		table.insert(rates, DragonUtil.GoldPerSecond(d))
	end
	table.sort(rates, function(a, b)
		return a > b
	end)
	local total = 0
	for i = 1, math.min(profile.HabitatSlots, #rates) do
		total += rates[i]
	end
	return total
end

function DragonUtil.ElementLabel(element)
	return Config.ElementLabels[element] or element
end

function DragonUtil.DisplayName(d)
	return (d.Shiny and "★ " or "") .. "Dragão " .. DragonUtil.ElementLabel(d.Element)
end

function DragonUtil.FormatTime(seconds)
	seconds = math.max(0, math.floor(seconds))
	if seconds >= 3600 then
		return string.format("%d:%02d:%02d", seconds // 3600, (seconds % 3600) // 60, seconds % 60)
	end
	return string.format("%02d:%02d", seconds // 60, seconds % 60)
end

function DragonUtil.WeightedPick(list, weightFn)
	local total = 0
	for _, item in ipairs(list) do
		total += weightFn(item)
	end
	local roll = math.random() * total
	for _, item in ipairs(list) do
		roll -= weightFn(item)
		if roll <= 0 then
			return item
		end
	end
	return list[1]
end

return DragonUtil
