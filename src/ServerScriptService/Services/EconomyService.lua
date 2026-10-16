--[[
IncubatorService (ModuleScript) - atualizado para manipular ovos e visualização
]]

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local DragonUtil = require(ReplicatedStorage.Shared.DragonUtil)
local Data = require(script.Parent.DataService)
local Dragon = require(script.Parent.DragonService)
local HabitatManager = require(script.Parent.Parent.Modules.HabitatManager)
local okViz, IncubatorVisualizer = pcall(require, script.Parent.Parent.Modules.IncubatorVisualizer)
if not okViz then
    IncubatorVisualizer = nil
end

local IncubatorService = {}
IncubatorService.Handlers = {}

local pendingSkip = {}

function IncubatorService.AddEgg(player, egg, force)
    local profile = Data.Get(player)
    if not profile then return false, "Perfil não carregado" end

    if not force and not HabitatManager.CanAddEgg(profile) then
        return false, "Incubadora cheia"
    end

    egg.Id = "e" .. profile.NextId
    profile.NextId += 1
    table.insert(profile.Eggs, egg)

    if IncubatorVisualizer then
        pcall(function()
            IncubatorVisualizer.SpawnEgg(player, egg)
        end)
    end

    return true, egg
end

function IncubatorService.CreateHeistEgg(tier)
    local t = Config.Heist.Tiers[tier]
    if not t then return nil end

    local weights = {}
    for _, e in ipairs(Config.BasicEggElements) do
        weights[e] = 10
    end
    weights.Infernal = 2 * tier
    weights.Cosmico = 0.5 * tier * tier

    local element = DragonUtil.WeightedPick(Config.Elements, function(e)
        return weights[e] or 0
    end)

    return {
        Element = element,
        Rarity = Dragon.RollRarity(t.RarityBonus),
        Shiny = Dragon.RollShiny(t.ShinyChance),
        ReadyAt = os.time() + t.HatchSeconds,
        Source = "Expedição",
    }
end

local function resolveElement(ea, eb)
    for _, r in ipairs(Config.Recipes) do
        if (r.A == ea and r.B == eb) or (r.A == eb and r.B == ea) then
            if math.random() < r.Chance then
                return r.Result
            end
        end
    end
    return math.random() < 0.5 and ea or eb
end

local function resolveRarity(a, b)
    local ia, ib = Config.RarityIndex[a.Rarity], Config.RarityIndex[b.Rarity]
    local idx = math.random(math.min(ia, ib), math.max(ia, ib))
    if math.random() < 0.2 then
        idx = math.min(idx + 1, #Config.Rarities)
    end
    return Config.Rarities[idx].Name
end

function IncubatorService.Handlers.BuyEgg(player)
    local profile = Data.Get(player)
    if not profile then return false, "Perfil não carregado" end

    if not HabitatManager.CanAddEgg(profile) then
        return false, "Incubadora cheia"
    end

    if profile.Gold < Config.BasicEggCost then
        return false, "Ouro insuficiente"
    end

    profile.Gold = profile.Gold - Config.BasicEggCost
    local element = Config.BasicEggElements[math.random(#Config.BasicEggElements)]
    local egg = {
        Element = element,
        Rarity = nil,
        Shiny = false,
        ReadyAt = os.time() + Config.BasicEggHatchSeconds,
        Source = "Compra",
    }

    return IncubatorService.AddEgg(player, egg)
end

function IncubatorService.ProcessReceipt(player, info)
    local profile = Data.Get(player)
    if not profile then return false end

    local eggId = pendingSkip[player.UserId]
    if not eggId then return false end

    local egg = nil
    for i, candidate in ipairs(profile.Eggs) do
        if candidate.Id == eggId then
            egg = candidate
            table.remove(profile.Eggs, i)
            break
        end
    end

    if egg then
        egg.ReadyAt = os.time()
    end

    pendingSkip[player.UserId] = nil
    return true
end

return IncubatorService
