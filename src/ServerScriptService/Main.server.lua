local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Remotes precisam existir antes dos serviços carregarem.
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not Remotes then
    Remotes = Instance.new("Folder")
    Remotes.Name = "Remotes"
    Remotes.Parent = ReplicatedStorage
end

for _, name in ipairs({ "ProfileChanged", "Notify", "BattleEvent", "HeistEvent" }) do
    if not Remotes:FindFirstChild(name) then
        local ev = Instance.new("RemoteEvent")
        ev.Name = name
        ev.Parent = Remotes
    end
end

local Request = Remotes:FindFirstChild("Request")
if not Request then
    Request = Instance.new("RemoteFunction")
    Request.Name = "Request"
    Request.Parent = Remotes
end

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
        else
            handlers[name] = fn
        end
    end
end

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
    if PlotService and PlotService.OnPlayerRemoving then
        PlotService.OnPlayerRemoving(player)
    end
end)

MarketplaceService.ProcessReceipt = function(info)
    local player = Players:GetPlayerByUserId(info.PlayerId)
    if not player then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local granted = Incubator.ProcessReceipt(player, info)
    return granted and Enum.ProductPurchaseDecision.PurchaseGranted or Enum.ProductPurchaseDecision.NotProcessedYet
end

print("[DragonMVP] Iniciando servidor...")

LightingSetup.Init()
print("[DragonMVP] Iluminação configurada")

Data.OnProfileLoaded = function(player, profile)
    print("[DragonMVP] OnProfileLoaded chamado para " .. player.Name)

    local isStudio = game:GetService("RunService"):IsStudio()
    if profile.FirstTime or (isStudio and #profile.Eggs == 0 and next(profile.Dragons) == nil) then
        profile.FirstTime = false

        local element = Config.BasicEggElements[math.random(#Config.BasicEggElements)]
        local egg = {
            Id = "Egg_" .. profile.NextId,
            Element = element,
            Rarity = nil,
            Shiny = false,
            ReadyAt = os.time() + 10,
            Source = "Inicial",
        }
        profile.NextId = profile.NextId + 1
        table.insert(profile.Eggs, egg)

        profile.Gold = 500
        profile.Apples = 100
    end

    local plotData = PlotService.AssignPlot(player, profile)
    print("[DragonMVP] Plot atribuído: ID " .. plotData.PlotId)

    if not plotData.Folder:FindFirstChild("TerrainGenerated") then
        local success, err = pcall(function()
            TerrainGenerator.GeneratePlot(plotData)
        end)

        if success then
            local marker = Instance.new("BoolValue")
            marker.Name = "TerrainGenerated"
            marker.Parent = plotData.Folder
        else
            warn("[DragonMVP] Erro ao gerar terreno: " .. tostring(err))
        end
    end

    BuildingService.LoadPlacedBuildings(player)
    Dragon.EnsureIntegrity(player, profile)
    DragonSpawner.SpawnAllDragons(player, profile)

    local function teleport()
        task.wait(1)
        if not player.Parent then
            return
        end

        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            PlotService.TeleportToPlot(player)
        else
            task.wait(1)
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                PlotService.TeleportToPlot(player)
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

Data.Init()
Heist.Init()
DebugCommands.Init()
CoinService.Init()

print("[DragonMVP] Servidor iniciado!")
