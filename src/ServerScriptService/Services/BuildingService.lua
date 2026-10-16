--[[
    DataService (ModuleScript)
    Local no Studio: ServerScriptService > Services > DataService
    Carrega/salva o perfil do jogador (DataStore) e envia atualizações ao cliente.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local store = DataStoreService:GetDataStore("DragonMVP_v1")

local DataService = {}
local profiles = {}
local noSave = {}

DataService.OnProfileLoaded = nil

local function newProfile()
    return {
        Gold = Config.StartGold,
        Apples = Config.StartApples,
        Dragons = {},
        Eggs = {},
        Team = {},
        FarmLevel = 1,
        HabitatSlots = Config.HabitatBaseSlots,
        LastGoldCollect = os.time(),
        LastHarvest = os.time(),
        NextId = 1,
        Receipts = {},
        Stats = { Wins = 0, Heists = 0, EggsStolen = 0 },
        PlotId = nil,
        Buildings = {
            Inventory = {},
            Placed = {},
        },
        IncubatorSlots = Config.IncubatorSlots,
        FirstTime = true,
    }
end

local function reconcile(data, template)
    for k, v in pairs(template) do
        if data[k] == nil then
            data[k] = type(v) == "table" and table.clone(v) or v
        end
    end
end

local function loadProfile(player)
    local key = "P_" .. player.UserId
    local data, ok, err
    for attempt = 1, 3 do
        ok, err = pcall(function()
            data = store:GetAsync(key)
        end)
        if ok then
            break
        end
        task.wait(attempt)
    end
    if not player.Parent then
        return
    end

    if not ok then
        warn("[DataService] Falha ao carregar " .. player.Name .. ": " .. tostring(err))
        if RunService:IsStudio() then
            noSave[player] = true
        else
            player:Kick("Não foi possível carregar seus dados. Tente entrar de novo.")
            return
        end
    end

    local template = newProfile()
    if type(data) ~= "table" then
        data = template
    else
        reconcile(data, template)
    end

    if data.HabitatSlots == nil then
        data.HabitatSlots = Config.HabitatBaseSlots
    end

    profiles[player] = data
    DataService.Push(player)

    if DataService.OnProfileLoaded then
        DataService.OnProfileLoaded(player, data)
    end
end

function DataService.Get(player)
    return profiles[player]
end

function DataService.WaitForProfile(player, timeout)
    local t = 0
    while not profiles[player] and player.Parent and t < (timeout or 20) do
        t += task.wait(0.2)
    end
    return profiles[player]
end

function DataService.Push(player)
    local p = profiles[player]
    if p and player.Parent then
        Remotes.ProfileChanged:FireClient(player, p)
    end
end

function DataService.Save(player)
    local p = profiles[player]
    if not p or noSave[player] then
        return false
    end
    local ok, err = pcall(function()
        store:SetAsync("P_" .. player.UserId, p)
    end)
    if not ok then
        warn("[DataService] Falha ao salvar " .. player.Name .. ": " .. tostring(err))
    end
    return ok
end

function DataService.Init()
    Players.PlayerAdded:Connect(function(player)
        task.spawn(loadProfile, player)
    end)
    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(loadProfile, player)
    end

    Players.PlayerRemoving:Connect(function(player)
        DataService.Save(player)
        profiles[player] = nil
        noSave[player] = nil
    end)

    task.spawn(function()
        while true do
            task.wait(120)
            for _, player in ipairs(Players:GetPlayers()) do
                task.spawn(DataService.Save, player)
            end
        end
    end)

    game:BindToClose(function()
        local pending = 0
        for _, player in ipairs(Players:GetPlayers()) do
            pending += 1
            task.spawn(function()
                DataService.Save(player)
                pending -= 1
            end)
        end
        while pending > 0 do
            task.wait()
        end
    end)
end

return DataService
