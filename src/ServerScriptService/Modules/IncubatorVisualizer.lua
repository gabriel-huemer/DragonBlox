--[[
    Config (ModuleScript)
    Local no Studio: ReplicatedStorage > Shared > Config
    Todo o balanceamento do jogo fica aqui. Mexa nos números à vontade.
]]

local Config = {}

----------------------------------------------------------------------
-- ELEMENTOS
----------------------------------------------------------------------
Config.Elements = { "Fogo", "Terra", "Agua", "Raio", "Folha", "Vento", "Sombra", "Neon", "Infernal", "Cosmico" }

-- Elementos que podem sair de ovos básicos (Infernal e Cósmico só por cruzamento/expedição)
Config.BasicEggElements = { "Fogo", "Terra", "Agua", "Raio", "Folha", "Vento", "Sombra", "Neon" }

Config.ElementLabels = { Agua = "Água", Cosmico = "Cósmico" }

Config.ElementColors = {
    Fogo = Color3.fromRGB(255, 110, 40),
    Terra = Color3.fromRGB(140, 100, 60),
    Agua = Color3.fromRGB(60, 150, 255),
    Raio = Color3.fromRGB(255, 235, 70),
    Folha = Color3.fromRGB(80, 200, 90),
    Vento = Color3.fromRGB(190, 235, 240),
    Sombra = Color3.fromRGB(70, 45, 105),
    Neon = Color3.fromRGB(255, 60, 230),
    Infernal = Color3.fromRGB(170, 10, 20),
    Cosmico = Color3.fromRGB(90, 60, 220),
}

Config.ElementBias = {
    Fogo = { PoderElemental = 1.15 },
    Terra = { Resistencia = 1.25, Vitalidade = 1.1 },
    Agua = { Vitalidade = 1.15 },
    Raio = { Agilidade = 1.3 },
    Folha = { Vitalidade = 1.1, Resistencia = 1.1 },
    Vento = { Agilidade = 1.25 },
    Sombra = { PoderFisico = 1.15 },
    Neon = { PoderElemental = 1.2 },
    Infernal = { PoderFisico = 1.15, PoderElemental = 1.15 },
    Cosmico = { PoderElemental = 1.2, Agilidade = 1.1, Vitalidade = 1.1 },
}

Config.Advantage = {
    Fogo = { "Folha", "Vento" },
    Agua = { "Fogo", "Infernal" },
    Terra = { "Fogo", "Raio" },
    Raio = { "Agua", "Vento" },
    Folha = { "Agua", "Terra" },
    Vento = { "Terra", "Folha" },
    Sombra = { "Neon", "Raio" },
    Neon = { "Sombra", "Infernal" },
    Infernal = { "Folha", "Terra", "Vento" },
    Cosmico = { "Sombra", "Neon", "Infernal", "Raio" },
}

Config.Recipes = {
    { A = "Fogo", B = "Terra", Result = "Infernal", Chance = 0.35 },
    { A = "Fogo", B = "Sombra", Result = "Infernal", Chance = 0.30 },
    { A = "Raio", B = "Vento", Result = "Neon", Chance = 0.35 },
    { A = "Agua", B = "Terra", Result = "Folha", Chance = 0.40 },
    { A = "Sombra", B = "Neon", Result = "Cosmico", Chance = 0.25 },
    { A = "Neon", B = "Infernal", Result = "Cosmico", Chance = 0.20 },
}

----------------------------------------------------------------------
-- RARIDADES E STATUS
----------------------------------------------------------------------
Config.Rarities = {
    { Name = "Comum", Weight = 60, StatMult = 1.0, GoldMult = 1.0 },
    { Name = "Raro", Weight = 25, StatMult = 1.25, GoldMult = 1.5 },
    { Name = "Epico", Weight = 10, StatMult = 1.6, GoldMult = 2.2 },
    { Name = "Lendario", Weight = 4, StatMult = 2.1, GoldMult = 3.5 },
    { Name = "Mitico", Weight = 1, StatMult = 3.0, GoldMult = 6.0 },
}
Config.RarityIndex = {}
for i, r in ipairs(Config.Rarities) do
    Config.RarityIndex[r.Name] = i
end

Config.ShinyChance = 0.02
Config.ShinyMult = 1.5
Config.MaxLevel = 40

Config.BaseStats = { Vitalidade = 100, PoderFisico = 10, PoderElemental = 10, Resistencia = 5, Agilidade = 10 }
Config.StatGrowth = { Vitalidade = 12, PoderFisico = 2, PoderElemental = 2, Resistencia = 1, Agilidade = 1 }

----------------------------------------------------------------------
-- PLOTS E CONSTRUÇÃO
----------------------------------------------------------------------
Config.Plot = {
    Size = 100,
    GridSize = 4,
}

Config.Buildings = {
    Farm = {
        Name = "Fazenda",
        Cost = 100,
        Size = Vector3.new(12, 1, 12),
        MaxLevel = 10,
    },
    Incubator = {
        Name = "Incubadora",
        Cost = 200,
        Size = Vector3.new(8, 6, 8),
    },
    Habitat = {
        Name = "Habitat",
        BaseCost = 150,
        Size = Vector3.new(16, 1, 16),
    },
}

----------------------------------------------------------------------
-- ECONOMIA DA BASE
----------------------------------------------------------------------
Config.StartGold = 300
Config.StartApples = 30

Config.HabitatBaseSlots = 1
Config.MaxHabitatSlots = 5
Config.MaxFarmLevel = 10
Config.MaxDragonsPerHabitat = 3

Config.OfflineCapSeconds = 4 * 3600

Config.FarmApplesPerSecond = 0.05
Config.GoldPerLevelPerSecond = 0.4

function Config.HabitatSlotCost(currentSlots)
    return 200 * 2 ^ (currentSlots - Config.HabitatBaseSlots)
end

function Config.FarmUpgradeCost(level)
    return 100 * level * level
end

Config.BasicEggCost = 150
Config.BasicEggHatchSeconds = 60

Config.IncubatorSlots = 2
Config.IncubatorExtraSlotProductId = 0
Config.BreedCost = 250
Config.BreedHatchSeconds = 300
Config.MinBreedLevel = 3

Config.DragonSellValue = {
    Comum = 50,
    Raro = 150,
    Epico = 400,
    Lendario = 1000,
    Mitico = 2500,
}

Config.SkipProductId = 0

----------------------------------------------------------------------
-- BATALHA 3v3 (por turnos)
----------------------------------------------------------------------
Config.Battle = {
    ElementalCooldown = 2,
    RewardGold = function(level)
        return 60 + level * 15
    end,
    RewardApples = function(level)
        return 10 + level
    end,
}

----------------------------------------------------------------------
-- EXPEDIÇÃO "ROUBE UM OVO" (PvPvE / extração)
----------------------------------------------------------------------
Config.Heist = {
    WalkSpeed = 16,
    JumpPower = 50,
    ExtractSeconds = 4,
    NestCooldown = 90,
    WildRespawn = 60,
    CompanionRange = 45,
    CompanionCooldown = 1.2,
    DroppedEggLifetime = 120,
    Tiers = {
        [1] = { Name = "Pequeno", WalkSpeed = 11, RarityBonus = 0, ShinyChance = 0.03, HatchSeconds = 300, Size = 1.5, Color = Color3.fromRGB(120, 220, 255) },
        [2] = { Name = "Grande", WalkSpeed = 8, RarityBonus = 1.5, ShinyChance = 0.07, HatchSeconds = 900, Size = 2.5, Color = Color3.fromRGB(255, 190, 70) },
        [3] = { Name = "Gigante", WalkSpeed = 5, RarityBonus = 4, ShinyChance = 0.15, HatchSeconds = 1800, Size = 3.5, Color = Color3.fromRGB(255, 70, 220) },
    },
    Wild = {
        Small = {
            Name = "Dragão Selvagem", HP = 150, Damage = 10, Cooldown = 1.5, Speed = 20,
            AggroRange = 55, AttackRange = 9, PreferredDistance = 6, Ranged = false,
            Size = Vector3.new(4, 3, 7), HoverHeight = 0, Reward = 25,
        },
        Colossal = {
            Name = "Dragão Colossal", HP = 500, Damage = 18, Cooldown = 3, Speed = 14,
            AggroRange = 110, AttackRange = 80, PreferredDistance = 30, Ranged = true,
            Size = Vector3.new(14, 8, 24), HoverHeight = 25, Reward = 120,
        },
    },
}

return Config
