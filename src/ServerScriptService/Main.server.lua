--[[]]
Main (Script)
Atualizado: chama Dragon.EnsureIntegrity antes de spawnar dragões e garante LoadPlacedBuildings + reassign.
--]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------------
-- 1) Remotes (precisam existir ANTES dos serviços serem carregados)
----------------------------------------------------------------------
local Remotes = Instance.new("Folder")
Remotes.Name = "Remotes"
for _, name in ipairs({ "ProfileChanged", "Notify", "BattleEvent", "HeistEvent" }) do
    local ev = Instance.new("RemoteEvent")
    ev.Name = name
    ev.Parent = Remotes
end
local Request = Instance.new("RemoteFunction")
Request.Name = "Request"
Request.Parent = Remotes
Remotes.Parent = ReplicatedStorage

----------------------------------------------------------------------
-- 2) Serviços e Módulos
----------------------------------------------------------------------
local Services = script.Parent:WaitForChild("Services")
local Modules = script.Parent:WaitForChild("Modules")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(Services.DataService)
local Dragon = require(Services.DragonService)
local Economy = require(Services.EconomyService)
local Incubator = require(Services.IncubatorService)
local Heist = require(Services.HeistService)
local Battle = require(Services.BattleService)
local PlotService = require(Services.PlotService)
local BuildingService = require(Services.BuildingService)

local LightingSetup = require(Modules.LightingSetup)
local TerrainGenerator = require(Modules.TerrainGenerator)
local DebugCommands = require(Modules.DebugCommands)
local DragonSpawner = require(Modules.DragonSpawner)
local CoinService = require(Services.CoinService)

local handlers = {}
for _, svc in ipairs({ Dragon, Economy, Incubator, Heist, Battle, BuildingService }) do
    for name, fn in pairs(svc.Handlers or {}) do
        if handlers[name] then
            warn("[Main] Handler duplicado: " .. name)
        end
        handlers[name] = fn
    end
end

----------------------------------------------------------------------
-- 3) Roteador de requisições do cliente
----------------------------------------------------------------------
local lastCall = {}

Request.OnServerInvoke = function(player, action, ...)
    if type(action) ~= "string" then
        return { ok = false, data = "Ação inválida." }
    end

    if action == "GetProfile" then
        local profile = Data.WaitForProfile(player, 20)
        return { ok = profile ~= nil, data = profile }
    end

    local fn = handlers[action]
    if not fn then
        return { ok = false, data = "Ação desconhecida." }
    end

    -- anti-spam simples
    local now = os.clock()
    if lastCall[player] and now - lastCall[player] < 0.1 then
        return { ok = false, data = "Calma, muito rápido!" }
    end
    lastCall[player] = now

    if not Data.Get(player) then
        return { ok = false, data = "Seus dados ainda estão carregando." }
    end

    local ok, result, extra = pcall(fn, player, ...)
    if not ok then
        warn("[Request:" .. action .. "] " .. tostring(result))
        return { ok = false, data = "Erro interno." }
    end
    return { ok = result == true, data = extra }
end

Players.PlayerRemoving:Connect(function(player)
    lastCall[player] = nil
    PlotService.OnPlayerRemoving(player)
end)

----------------------------------------------------------------------
-- 4) Compras com Robux (acelerar incubadora)
----------------------------------------------------------------------
MarketplaceService.ProcessReceipt = function(info)
    local player = Players:GetPlayerByUserId(info.PlayerId)
    if not player then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
    local granted = Incubator.ProcessReceipt(player, info)
    return granted and Enum.ProductPurchaseDecision.PurchaseGranted or Enum.ProductPurchaseDecision.NotProcessedYet
end

----------------------------------------------------------------------
-- 5) Iniciar
----------------------------------------------------------------------
print("[DragonMVP] Iniciando servidor...")

-- Configurar iluminação
LightingSetup.Init()
print("[DragonMVP] Iluminação configurada")

-- Definir callback ANTES de Init
Data.OnProfileLoaded = function(player, profile)
    print("[DragonMVP] OnProfileLoaded chamado para " .. player.Name)

    -- Dar ovo grátis na primeira vez (OU sempre no Studio para teste)
    local isStudio = game:GetService("RunService"):IsStudio()
    if profile.FirstTime or (isStudio and #profile.Eggs == 0 and next(profile.Dragons) == nil) then
        print("[DragonMVP] Dando ovo inicial...")
        profile.FirstTime = false

        -- Adicionar ovo inicial grátis
        local element = Config.BasicEggElements[math.random(#Config.BasicEggElements)]
        local egg = {
            Id = "Egg_" .. profile.NextId,
            Element = element,
            Rarity = nil, -- definido ao chocar
            Shiny = false,
            ReadyAt = os.time() + 10, -- 10 segundos apenas (tutorial)
            Source = "Inicial",
        }
        profile.NextId = profile.NextId + 1
        table.insert(profile.Eggs, egg)

        print("[DragonMVP] Ovo inicial adicionado: " .. element)

        -- Dar mais ouro e maçãs iniciais
        profile.Gold = 500 -- mais ouro inicial
        profile.Apples = 100 -- mais maçãs iniciais
    end

    local plotData = PlotService.AssignPlot(player, profile)
    print("[DragonMVP] Plot atribuído: ID " .. plotData.PlotId)

    -- Gerar terreno se for primeira vez
    if not plotData.Folder:FindFirstChild("TerrainGenerated") then
        print("[DragonMVP] Gerando terreno para plot " .. plotData.PlotId .. "...")
        local success, err = pcall(function()
            TerrainGenerator.GeneratePlot(plotData)
        end)

        if success then
            local marker = Instance.new("BoolValue")
            marker.Name = "TerrainGenerated"
            marker.Parent = plotData.Folder
            print("[DragonMVP] Terreno gerado com sucesso!")
        else
            warn("[DragonMVP] Erro ao gerar terreno: " .. tostring(err))
            warn("[DragonMVP] Continuando mesmo assim...")
        end
    else
        print("[DragonMVP] Terreno já existe")
    end

    -- Carregar construções colocadas
    BuildingService.LoadPlacedBuildings(player)

    -- Garantir integridade antes de spawnar dragões
    Dragon.EnsureIntegrity(player, profile)

    -- Spawnar dragões nos habitats
    DragonSpawner.SpawnAllDragons(player, profile)

    -- Teleportar após carregar character
    local function teleport()
        print("[DragonMVP] Tentando teleportar " .. player.Name .. "...")
        task.wait(1)

        if not player.Parent then
            print("[DragonMVP] Player saiu, cancelando teleporte")
            return
        end

        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            PlotService.TeleportToPlot(player)
            print("[DragonMVP] Jogador " .. player.Name .. " teleportado!")
        else
            warn("[DragonMVP] Character não tem HumanoidRootPart, tentando novamente...")
            task.wait(1)
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                PlotService.TeleportToPlot(player)
                print("[DragonMVP] Jogador " .. player.Name .. " teleportado (2ª tentativa)!)")
            end
        end
    end

    if player.Character then
        task.spawn(teleport)
    end
    player.CharacterAdded:Connect(function()
        task.spawn(teleport)
    end)
end

-- Agora iniciar serviços
Data.Init()
Heist.Init()
DebugCommands.Init()
CoinService.Init()

print("[DragonMVP] Servidor iniciado!")
