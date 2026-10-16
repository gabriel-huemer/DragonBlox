--[[
	PlotService - Gerencia plots individuais dos jogadores
	Cada jogador recebe uma ilha ao entrar
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local PlotService = {}
PlotService.Handlers = {}

local PLOT_SIZE = 100 -- tamanho de cada plot (100x100 studs)
local PLOT_SPACING = 20 -- espaçamento entre plots
local plots = {} -- [userId] = { PlotId, Position, Folder }
local nextPlotId = 1

-- Calcula posição do plot baseado no ID
local function getPlotPosition(plotId)
	local row = math.floor((plotId - 1) / 10)
	local col = (plotId - 1) % 10
	return Vector3.new(
		col * (PLOT_SIZE + PLOT_SPACING),
		100, -- altura base (acima do vazio)
		row * (PLOT_SIZE + PLOT_SPACING)
	)
end

-- Atribui plot ao jogador
function PlotService.AssignPlot(player, profile)
	print("[PlotService] AssignPlot chamado para " .. player.Name)
	
	if plots[player.UserId] then
		print("[PlotService] Plot já existe, retornando existente")
		return plots[player.UserId]
	end
	
	-- Usa PlotId salvo ou cria novo
	local plotId = profile.PlotId or nextPlotId
	if not profile.PlotId then
		profile.PlotId = plotId
		nextPlotId = nextPlotId + 1
		print("[PlotService] Novo plot criado: ID " .. plotId)
	else
		nextPlotId = math.max(nextPlotId, plotId + 1)
		print("[PlotService] Plot existente carregado: ID " .. plotId)
	end
	
	local position = getPlotPosition(plotId)
	print("[PlotService] Posição do plot: " .. tostring(position))
	
	-- Criar pasta do plot
	local plotsFolder = workspace:FindFirstChild("Plots")
	if not plotsFolder then
		plotsFolder = Instance.new("Folder")
		plotsFolder.Name = "Plots"
		plotsFolder.Parent = workspace
		print("[PlotService] Pasta Plots criada")
	end
	
	local plotFolder = Instance.new("Folder")
	plotFolder.Name = "Plot_" .. player.UserId
	plotFolder.Parent = plotsFolder
	print("[PlotService] Pasta do plot criada: " .. plotFolder.Name)
	
	local plotData = {
		PlotId = plotId,
		Position = position,
		Folder = plotFolder,
		Size = PLOT_SIZE,
	}
	
	plots[player.UserId] = plotData
	print("[PlotService] PlotData armazenado")
	return plotData
end

-- Retorna plot do jogador
function PlotService.GetPlot(player)
	return plots[player.UserId]
end

-- Teleporta jogador para seu plot
function PlotService.TeleportToPlot(player)
	local plotData = plots[player.UserId]
	if not plotData or not player.Character then
		return
	end
	
	local hrp = player.Character:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.CFrame = CFrame.new(plotData.Position + Vector3.new(0, 10, 0))
	end
end

-- Verifica se posição está dentro do plot
function PlotService.IsInPlot(player, position)
	local plotData = plots[player.UserId]
	if not plotData then return false end
	
	local half = plotData.Size / 2
	local center = plotData.Position
	
	return position.X >= center.X - half and position.X <= center.X + half
		and position.Z >= center.Z - half and position.Z <= center.Z + half
end

-- Cleanup ao sair
function PlotService.OnPlayerRemoving(player)
	local plotData = plots[player.UserId]
	if plotData and plotData.Folder then
		-- Não destroi - mantém construções (serão recarregadas depois)
		plotData.Folder.Parent = game.ServerStorage
	end
	plots[player.UserId] = nil
end

return PlotService
