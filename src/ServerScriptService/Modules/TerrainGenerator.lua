--[[
	TerrainGenerator - Gera terreno procedural simples para cada plot
]]

local TerrainGenerator = {}

local GRID_SIZE = 4 -- tamanho das células de terreno

-- Gera terreno básico para um plot
function TerrainGenerator.GeneratePlot(plotData)
	print("[TerrainGenerator] Iniciando geração para plot ID " .. plotData.PlotId)
	
	local position = plotData.Position
	local size = plotData.Size
	
	print("[TerrainGenerator] Posição: " .. tostring(position) .. ", Tamanho: " .. size)
	
	local region = Region3.new(
		position - Vector3.new(size/2, 10, size/2),
		position + Vector3.new(size/2, 20, size/2)
	):ExpandToGrid(4)
	
	-- Limpa terreno existente
	print("[TerrainGenerator] Limpando terreno...")
	workspace.Terrain:FillRegion(region, 4, Enum.Material.Air)
	
	-- Cria base de grama (simples, sem ruído por enquanto)
	print("[TerrainGenerator] Criando grama...")
	local grassRegion = Region3.new(
		position - Vector3.new(size/2, 4, size/2),
		position + Vector3.new(size/2, 0, size/2)
	):ExpandToGrid(4)
	workspace.Terrain:FillRegion(grassRegion, 4, Enum.Material.Grass)
	
	-- Cria camada de terra abaixo
	print("[TerrainGenerator] Criando terra...")
	local groundRegion = Region3.new(
		position - Vector3.new(size/2, 12, size/2),
		position - Vector3.new(-size/2, 4, -size/2)
	):ExpandToGrid(4)
	workspace.Terrain:FillRegion(groundRegion, 4, Enum.Material.Ground)
	
	-- Água ao redor (oceano simples)
	print("[TerrainGenerator] Criando água...")
	local waterHeight = position.Y - 8
	local waterSize = size + 40
	local waterRegion = Region3.new(
		Vector3.new(position.X - waterSize/2, waterHeight - 8, position.Z - waterSize/2),
		Vector3.new(position.X + waterSize/2, waterHeight, position.Z + waterSize/2)
	):ExpandToGrid(4)
	workspace.Terrain:FillRegion(waterRegion, 4, Enum.Material.Water)
	
	-- Adiciona algumas decorações simples
	print("[TerrainGenerator] Adicionando decorações...")
	TerrainGenerator.AddDecorations(plotData)
	
	-- Cria spawn
	print("[TerrainGenerator] Criando spawn...")
	local spawn = Instance.new("SpawnLocation")
	spawn.Position = position + Vector3.new(0, 2, 0)
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Transparency = 1 -- invisível
	spawn.Duration = 0
	spawn.Parent = plotData.Folder
	
	print("[TerrainGenerator] Geração concluída!")
end

-- Adiciona decorações simples (árvores e pedras)
function TerrainGenerator.AddDecorations(plotData)
	local position = plotData.Position
	local size = plotData.Size
	local random = Random.new(plotData.PlotId) -- determinístico
	
	-- Árvores simples
	for i = 1, 8 do
		local x = position.X + random:NextNumber(-size/2 + 10, size/2 - 10)
		local z = position.Z + random:NextNumber(-size/2 + 10, size/2 - 10)
		local y = position.Y
		
		-- Tronco
		local trunk = Instance.new("Part")
		trunk.Name = "TreeTrunk"
		trunk.Size = Vector3.new(2, 8, 2)
		trunk.Position = Vector3.new(x, y + 4, z)
		trunk.Anchored = true
		trunk.Material = Enum.Material.Wood
		trunk.BrickColor = BrickColor.new("Brown")
		trunk.Parent = plotData.Folder
		
		-- Copa (usando Part normal, não Ball)
		local leaves = Instance.new("Part")
		leaves.Name = "TreeLeaves"
		leaves.Size = Vector3.new(8, 8, 8)
		leaves.Position = Vector3.new(x, y + 10, z)
		leaves.Anchored = true
		leaves.Material = Enum.Material.Grass
		leaves.BrickColor = BrickColor.new("Bright green")
		leaves.Parent = plotData.Folder
		
		-- Mesh esférico para a copa
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = leaves
	end
	
	-- Pedras
	for i = 1, 12 do
		local x = position.X + random:NextNumber(-size/2 + 5, size/2 - 5)
		local z = position.Z + random:NextNumber(-size/2 + 5, size/2 - 5)
		local y = position.Y
		
		local rock = Instance.new("Part")
		rock.Name = "Rock"
		rock.Size = Vector3.new(
			random:NextNumber(2, 4),
			random:NextNumber(1.5, 3),
			random:NextNumber(2, 4)
		)
		rock.Position = Vector3.new(x, y + rock.Size.Y/2, z)
		rock.Anchored = true
		rock.Material = Enum.Material.Rock
		rock.BrickColor = BrickColor.new("Medium stone grey")
		rock.Parent = plotData.Folder
	end
	
	print("[TerrainGenerator] Decorações adicionadas!")
end

return TerrainGenerator
