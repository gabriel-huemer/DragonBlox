--[[
	DataService (ModuleScript)
	Local no Studio: ServerScriptService > Services > DataService
	Carrega/salva o perfil do jogador (DataStore) e envia atualizações ao cliente.

	Para o Studio salvar dados: Game Settings > Security > "Enable Studio Access to API Services".
	Sem isso o jogo funciona, mas NÃO salva (aparece um aviso no Output).
	Em produção, considere trocar por ProfileService/ProfileStore (trava de sessão).
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

DataService.OnProfileLoaded = nil -- callback definido no Main.server.lua

local function newProfile()
	return {
		Gold = Config.StartGold,
		Apples = Config.StartApples,
		Dragons = {}, -- [id] = { Id, Element, Rarity, Shiny, Level, HabitatId, Archived }
		Eggs = {}, -- ovos na incubadora: { Id, Element, Rarity, Shiny, ReadyAt, Source }
		Team = {}, -- até 3 ids de dragões
		FarmLevel = 1,
		LastGoldCollect = os.time(),
		LastHarvest = os.time(),
		NextId = 1,
		Receipts = {},
		Stats = { Wins = 0, Heists = 0, EggsStolen = 0 },
		-- Novos campos para construção
		PlotId = nil, -- atribuído na primeira entrada
		Buildings = {
			Inventory = {}, -- [buildingId] = buildingData
			Placed = {}, -- [buildingId] = buildingData com Position e Rotation
		},
		-- Incubadora com slots
		IncubatorSlots = Config.IncubatorSlots,
		-- Flag para saber se é primeira vez
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
			noSave[player] = true -- no Studio sem API: joga sem salvar
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
	profiles[player] = data
	DataService.Push(player)
	
	-- Callback para inicialização adicional (plot, etc)
	if DataService.OnProfileLoaded then
		print("[DataService] Chamando OnProfileLoaded para " .. player.Name)
		DataService.OnProfileLoaded(player, data)
	else
		warn("[DataService] OnProfileLoaded não está definido!")
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

	-- Autosave
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
