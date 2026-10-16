--[[
	Client (LocalScript)
	Interface do Dragon MVP - Organizada e Limpa
	Abas: Base | Construir | Dragões | Incubadora | Batalha | Expedição
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local DragonUtil = require(Shared:WaitForChild("DragonUtil"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Request = Remotes:WaitForChild("Request")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Paleta de cores
local C = {
	Bg = Color3.fromRGB(24, 26, 38),
	Panel = Color3.fromRGB(34, 37, 54),
	Row = Color3.fromRGB(46, 50, 72),
	Text = Color3.fromRGB(240, 240, 250),
	Muted = Color3.fromRGB(150, 150, 170),
	Accent = Color3.fromRGB(110, 90, 255),
	Good = Color3.fromRGB(70, 190, 110),
	Bad = Color3.fromRGB(220, 80, 80),
	Gold = Color3.fromRGB(255, 205, 60),
}

-- Estado global
local profile
local currentTab = "Base"
local battleState, battleLog = nil, {}
local selectedParents = {}
local liveUpdaters = {}
local layoutCounter = 0

local function serverNow()
	return workspace:GetServerTimeNow()
end

----------------------------------------------------------------------
-- COMUNICAÇÃO COM SERVIDOR (DEVE VIR PRIMEIRO)
----------------------------------------------------------------------
local function call(action, ...)
	local ok, res = pcall(Request.InvokeServer, Request, action, ...)
	if not ok or type(res) ~= "table" then
		warn("[Client] Erro ao chamar " .. action .. ": " .. tostring(res))
		return false
	end
	if not res.ok and res.data then
		-- Toast de erro será chamado por quem usa
		return false, res.data
	end
	return res.ok, res.data
end

----------------------------------------------------------------------
-- HELPERS DE UI
----------------------------------------------------------------------
local function new(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props) do inst[k] = v end
	inst.Parent = parent
	return inst
end

local function corner(inst, radius)
	new("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, inst)
end

local function label(parent, text, props)
	local p = {
		Text = text,
		BackgroundTransparency = 1,
		TextColor3 = C.Text,
		Font = Enum.Font.GothamMedium,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
	}
	for k, v in pairs(props or {}) do p[k] = v end
	return new("TextLabel", p, parent)
end

local function button(parent, text, color, onClick, props)
	local p = {
		Text = text,
		BackgroundColor3 = color or C.Accent,
		TextColor3 = C.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		AutoButtonColor = true,
		TextWrapped = true,
	}
	for k, v in pairs(props or {}) do p[k] = v end
	local b = new("TextButton", p, parent)
	corner(b, 8)
	b.Activated:Connect(onClick)
	return b
end

local function nextOrder()
	layoutCounter += 1
	return layoutCounter
end

----------------------------------------------------------------------
-- ESTRUTURA DA TELA
----------------------------------------------------------------------
local gui = new("ScreenGui", { Name = "DragonMVP", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, playerGui)

-- Barra superior
local top = new("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = C.Bg, BackgroundTransparency = 0.15, BorderSizePixel = 0 }, gui)
local goldLabel = label(top, "Ouro: 0", { Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0, 190, 1, 0), TextColor3 = C.Gold, Font = Enum.Font.GothamBold, TextSize = 18 })
local applesLabel = label(top, "Maçãs: 0", { Position = UDim2.new(0, 210, 0, 0), Size = UDim2.new(0, 190, 1, 0), TextColor3 = Color3.fromRGB(255, 120, 120), Font = Enum.Font.GothamBold, TextSize = 18 })

-- Painel principal
local panel = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 22),
	Size = UDim2.new(0.82, 0, 0.78, 0),
	BackgroundColor3 = C.Panel,
	BorderSizePixel = 0,
	Visible = true,
}, gui)
corner(panel, 12)

local function togglePanel()
	panel.Visible = not panel.Visible
end

button(top, "Menu (M)", C.Accent, togglePanel, { Size = UDim2.new(0, 110, 0, 32), Position = UDim2.new(1, -122, 0, 6) })

-- Abas laterais
local tabsFrame = new("Frame", { Size = UDim2.new(0, 130, 1, -20), Position = UDim2.new(0, 10, 0, 10), BackgroundTransparency = 1 }, panel)
new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, tabsFrame)

-- Scroll de conteúdo
local scroll = new("ScrollingFrame", {
	Position = UDim2.new(0, 150, 0, 10),
	Size = UDim2.new(1, -160, 1, -20),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 6,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
}, panel)
new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)

-- Toasts
local toastHolder = new("Frame", { Position = UDim2.new(0.5, -230, 0, 52), Size = UDim2.new(0, 460, 0, 220), BackgroundTransparency = 1 }, gui)
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, toastHolder)

local function toast(text, color)
	local t = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = color or C.Row,
		TextColor3 = C.Text,
		Font = Enum.Font.GothamMedium,
		TextSize = 15,
		Text = text,
		TextWrapped = true,
		LayoutOrder = nextOrder(),
	}, toastHolder)
	corner(t, 8)
	task.delay(3.5, function() t:Destroy() end)
end

-- HUD Expedição
local hud = new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -40), Size = UDim2.new(0, 320, 0, 22), BackgroundColor3 = C.Bg, Visible = false }, gui)
corner(hud, 8)
local hudFill = new("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = C.Good, BorderSizePixel = 0 }, hud)
corner(hudFill, 8)
label(hud, "Extraindo... fique na zona verde!", { Size = UDim2.new(1, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 13 })

local carryLabel = label(gui, "", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 50), Size = UDim2.new(0, 360, 0, 28), TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = C.Gold, Font = Enum.Font.GothamBold, Visible = false })

----------------------------------------------------------------------
-- EFEITO DE COLETA DE MOEDA
----------------------------------------------------------------------
local function showCoinCollect(value)
	local coinLabel = label(gui, "+" .. value .. " ouro", {
		Size = UDim2.new(0, 120, 0, 30),
		Position = UDim2.new(0.5, -60, 0.7, 0),
		TextColor3 = C.Gold,
		Font = Enum.Font.GothamBold,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	
	-- Anima para cima
	local tween = TweenService:Create(coinLabel, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -60, 0.5, 0),
		TextTransparency = 1,
	})
	tween:Play()
	
	task.delay(1, function()
		coinLabel:Destroy()
	end)
end

-- Detecta coleta de moedas
workspace.ChildRemoved:Connect(function(child)
	if child.Name == "Coin" then
		local owner = child:FindFirstChild("Owner")
		local valueTag = child:FindFirstChild("Value")
		if owner and owner.Value == player and valueTag then
			showCoinCollect(valueTag.Value)
		end
	end
end)

----------------------------------------------------------------------
-- COMPONENTES DE LISTA
----------------------------------------------------------------------
local function clear()
	liveUpdaters = {}
	layoutCounter = 0
	for _, c in ipairs(scroll:GetChildren()) do
		if not c:IsA("UIListLayout") then c:Destroy() end
	end
end

local function info(text, height, color)
	return label(scroll, text, { Size = UDim2.new(1, -8, 0, height or 30), LayoutOrder = nextOrder(), TextColor3 = color or C.Text })
end

local function addRow(titleText, actions, accent, height)
	local r = new("Frame", { Size = UDim2.new(1, -8, 0, height or 60), BackgroundColor3 = C.Row, BorderSizePixel = 0, LayoutOrder = nextOrder() }, scroll)
	corner(r, 8)
	new("Frame", { Size = UDim2.new(0, 5, 1, 0), BackgroundColor3 = accent or C.Accent, BorderSizePixel = 0 }, r)
	local t = label(r, titleText, { Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(1, -(#actions * 108 + 24), 1, 0), TextSize = 14 })
	for i, a in ipairs(actions) do
		button(r, a.text, a.color, a.fn, {
			Size = UDim2.new(0, 100, 0, 36),
			Position = UDim2.new(1, -((#actions - i + 1) * 108), 0.5, -18),
			TextSize = 13,
		})
	end
	return r, t
end

----------------------------------------------------------------------
-- MODO CONSTRUIR
----------------------------------------------------------------------
local buildMode = { active = false, preview = nil, building = nil, isMoving = false, rotation = 0 }

local function exitBuildMode()
	if buildMode.preview then buildMode.preview:Destroy() buildMode.preview = nil end
	buildMode.active = false
	buildMode.building = nil
	buildMode.isMoving = false
	buildMode.rotation = 0
end

local function enterBuildMode(building, isMoving)
	exitBuildMode()
	
	buildMode.active = true
	buildMode.building = building
	buildMode.isMoving = isMoving or false
	buildMode.rotation = building.Rotation or 0
	
	local buildingConfig = Config.Buildings[building.Type]
	if not buildingConfig then return end
	
	local preview = Instance.new("Part")
	preview.Size = buildingConfig.Size
	preview.Anchored = true
	preview.CanCollide = false
	preview.Transparency = 0.5
	preview.Color = Color3.fromRGB(0, 255, 0)
	preview.Parent = workspace
	
	buildMode.preview = preview
	panel.Visible = false
end

-- Loop do preview
task.spawn(function()
	while true do
		task.wait(0.05)
		if buildMode.active and buildMode.preview and player.Character then
			local hrp = player.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local forward = hrp.CFrame.LookVector
				local distance = 12
				local targetPos = hrp.Position + forward * distance
				
				local gridSize = Config.Plot.GridSize
				local snappedX = math.floor(targetPos.X / gridSize + 0.5) * gridSize
				local snappedZ = math.floor(targetPos.Z / gridSize + 0.5) * gridSize
				
				local rayOrigin = Vector3.new(snappedX, hrp.Position.Y + 20, snappedZ)
				local rayDirection = Vector3.new(0, -100, 0)
				
				local rayParams = RaycastParams.new()
				rayParams.FilterDescendantsInstances = {buildMode.preview, player.Character}
				rayParams.FilterType = Enum.RaycastFilterType.Exclude
				
				local raycastResult = workspace:Raycast(rayOrigin, rayDirection, rayParams)
				
				local snappedY = raycastResult and raycastResult.Position.Y or hrp.Position.Y
				local finalPos = Vector3.new(snappedX, snappedY + buildMode.preview.Size.Y/2, snappedZ)
				
				buildMode.preview.Color = Color3.fromRGB(0, 255, 0)
				buildMode.preview.CFrame = CFrame.new(finalPos) * CFrame.Angles(0, math.rad(buildMode.rotation), 0)
			end
		end
	end
end)

-- Input construir
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	
	if buildMode.active then
		if input.KeyCode == Enum.KeyCode.E then
			if buildMode.preview then
				local previewCFrame = buildMode.preview.CFrame
				local pos = previewCFrame.Position
				local groundPos = Vector3.new(pos.X, pos.Y - buildMode.preview.Size.Y/2, pos.Z)
				
				local action = buildMode.isMoving and "MoveBuilding" or "PlaceBuilding"
				local ok, err = call(action, buildMode.building.Id, groundPos, buildMode.rotation)
				
				if ok then
					toast(buildMode.isMoving and "Construção movida!" or "Construção colocada!", C.Good)
					exitBuildMode()
					currentTab = "Construir"
					panel.Visible = true
					render()
				else
					toast(tostring(err), C.Bad)
				end
			end
		elseif input.KeyCode == Enum.KeyCode.R then
			buildMode.rotation = (buildMode.rotation + 90) % 360
		elseif input.KeyCode == Enum.KeyCode.Q then
			exitBuildMode()
			toast("Construção cancelada", C.Muted)
			panel.Visible = true
		end
	end
	
	if input.KeyCode == Enum.KeyCode.M and not buildMode.active then
		togglePanel()
	end
end)

----------------------------------------------------------------------
-- RENDERIZADORES DE ABAS
----------------------------------------------------------------------
local renderers = {}
local render

local function pendingGold()
	local elapsed = math.clamp(serverNow() - profile.LastGoldCollect, 0, Config.OfflineCapSeconds)
	return math.floor(DragonUtil.TotalGoldPerSecond(profile) * elapsed)
end

local function pendingApples()
	local elapsed = math.clamp(serverNow() - profile.LastHarvest, 0, Config.OfflineCapSeconds)
	return math.floor(elapsed * Config.FarmApplesPerSecond * profile.FarmLevel)
end

-- ABA BASE
renderers["Base"] = function()
	local p = profile
	
	local _, goldTitle = addRow("", {
		{ text = "Coletar", color = C.Good, fn = function()
			local ok, gained = call("CollectGold")
			if ok then toast("+" .. gained .. " ouro", C.Gold) end
		end },
	}, C.Gold)
	
	local _, appleTitle = addRow("", {
		{ text = "Colher", color = C.Good, fn = function()
			local ok, gained = call("HarvestApples")
			if ok then toast("+" .. gained .. " maçãs", C.Bad) end
		end },
	}, C.Bad)
	
	table.insert(liveUpdaters, function()
		goldTitle.Text = "Ouro acumulado nos habitats: " .. pendingGold()
		appleTitle.Text = "Maçãs acumuladas na fazenda: " .. pendingApples()
	end)
	
	addRow(string.format("Melhorar fazenda (nível %d → %d)\nCusto: %d ouro", p.FarmLevel, p.FarmLevel + 1, Config.FarmUpgradeCost(p.FarmLevel)), {
		{ text = "Melhorar", color = C.Accent, fn = function()
			local ok, err = call("UpgradeFarm")
			if not ok then toast(tostring(err), C.Bad) end
		end }
	}, C.Accent)
	
	addRow(string.format("Ovo básico (%d ouro) — chocar leva %s", Config.BasicEggCost, DragonUtil.FormatTime(Config.BasicEggHatchSeconds)), {
		{ text = "Comprar", color = C.Accent, fn = function()
			local ok, err = call("BuyEgg")
			if ok then
				toast("Ovo colocado na incubadora!", C.Good)
			else
				toast(tostring(err), C.Bad)
			end
		end }
	}, C.Good)
	
	info("=== LOJA DE CONSTRUÇÕES ===", 26, C.Accent)
	
	addRow("Fazenda (100 ouro) - Produz maçãs", {
		{ text = "Comprar", color = C.Accent, fn = function()
			local ok, err = call("BuyBuilding", "Farm")
			if ok then toast("Fazenda comprada! Vá para aba Construir", C.Good)
			else toast(tostring(err), C.Bad) end
		end }
	}, C.Accent)
	
	addRow("Incubadora (200 ouro) - Chocar ovos", {
		{ text = "Comprar", color = C.Accent, fn = function()
			local ok, err = call("BuyBuilding", "Incubator")
			if ok then toast("Incubadora comprada! Vá para aba Construir", C.Good)
			else toast(tostring(err), C.Bad) end
		end }
	}, C.Accent)
	
	for i, element in ipairs(Config.Elements) do
		addRow(string.format("Habitat %s (150 ouro) - Casa para dragões", DragonUtil.ElementLabel(element)), {
			{ text = "Comprar", color = C.Accent, fn = function()
				local ok, err = call("BuyBuilding", "Habitat", element)
				if ok then toast("Habitat comprado! Vá para aba Construir", C.Good)
				else toast(tostring(err), C.Bad) end
			end }
		}, Config.ElementColors[element])
	end
end

-- ABA CONSTRUIR
renderers["Construir"] = function()
	local p = profile
	local invCount = 0
	for _ in pairs(p.Buildings.Inventory) do invCount = invCount + 1 end
	local placedCount = 0
	for _ in pairs(p.Buildings.Placed) do placedCount = placedCount + 1 end
	
	info(string.format("Inventário: %d construções | Colocadas: %d construções", invCount, placedCount), 26, C.Muted)
	
	if invCount == 0 and placedCount == 0 then
		info("Você ainda não tem construções. Compre na aba Base!", 40)
		return
	end
	
	if invCount > 0 then
		info("=== NO INVENTÁRIO (clique para colocar) ===", 26, C.Accent)
		for buildingId, building in pairs(p.Buildings.Inventory) do
			local name = building.Type == "Habitat" and (building.Type .. " " .. DragonUtil.ElementLabel(building.Element)) or building.Type
			addRow(name, {
				{ text = "Colocar", color = C.Good, fn = function()
					toast("MODO CONSTRUIR: Ande e pressione E para confirmar (R=girar, Q=cancelar)", C.Accent)
					enterBuildMode(building)
				end }
			}, building.Element and Config.ElementColors[building.Element] or C.Accent)
		end
	end
	
	if placedCount > 0 then
		info("=== COLOCADAS NO PLOT ===", 26, C.Good)
		for buildingId, building in pairs(p.Buildings.Placed) do
			local name = building.Type == "Habitat" and (building.Type .. " " .. DragonUtil.ElementLabel(building.Element)) or building.Type
			local pos = building.Position
			addRow(string.format("%s (X:%.0f Z:%.0f)", name, pos[1], pos[3]), {
				{ text = "Mover", color = C.Accent, fn = function()
					toast("MODO MOVER: Ande e pressione E para reposicionar", C.Accent)
					enterBuildMode(building, true)
				end },
				{ text = "Guardar", color = C.Row, fn = function()
					local ok, err = call("StoreBuilding", buildingId)
					if ok then toast("Construção guardada no inventário", C.Good)
					else toast(tostring(err), C.Bad) end
				end }
			}, building.Element and Config.ElementColors[building.Element] or C.Accent)
		end
	end
end

-- ABA DRAGÕES
renderers["Dragões"] = function()
	local p = profile
	local ids = {}
	for id in pairs(p.Dragons) do table.insert(ids, id) end
	table.sort(ids, function(a, b)
		local da, db = p.Dragons[a], p.Dragons[b]
		local ra, rb = Config.RarityIndex[da.Rarity] or 1, Config.RarityIndex[db.Rarity] or 1
		if ra ~= rb then return ra > rb end
		if da.Level ~= db.Level then return da.Level > db.Level end
		return a < b
	end)

	info("Time de batalha/expedição: " .. #p.Team .. "/3  (o 1º do time é o companheiro da expedição)", 26, C.Muted)

	if #selectedParents > 0 then
		local names = {}
		for _, id in ipairs(selectedParents) do
			local d = p.Dragons[id]
			if d then table.insert(names, DragonUtil.DisplayName(d)) end
		end
		local actions = { { text = "Limpar", color = C.Row, fn = function() selectedParents = {}; render() end } }
		if #selectedParents == 2 then
			table.insert(actions, 1, { text = "Cruzar", color = C.Good, fn = function()
				local ok, err = call("Breed", selectedParents[1], selectedParents[2])
				if ok then
					toast("Ovo de cruzamento na incubadora!", C.Good)
					selectedParents = {}
					render()
				else
					toast(tostring(err), C.Bad)
				end
			end })
		end
		addRow("Cruzamento: " .. table.concat(names, " + ") .. "\nCusto: " .. Config.BreedCost .. " ouro (pais nível " .. Config.MinBreedLevel .. "+)", actions, C.Good)
	end

	if #ids == 0 then
		info("Você ainda não tem dragões. Compre um ovo na aba Base e choque na Incubadora.", 40)
	end

	for _, id in ipairs(ids) do
		local d = p.Dragons[id]
		local s = DragonUtil.GetStats(d)
		local teamIdx = table.find(p.Team, id)
		local isArchived = d.Archived or false
		
		local statusText = isArchived and "[ARQUIVADO] " or (teamIdx and ("[TIME " .. teamIdx .. "] ") or "")
		local text = string.format("%s%s  Lv.%d  [%s]\nHP %d   FIS %d   ELE %d   RES %d   AGI %d",
			statusText, DragonUtil.DisplayName(d), d.Level, d.Rarity,
			s.Vitalidade, s.PoderFisico, s.PoderElemental, s.Resistencia, s.Agilidade)
		
		local isSelected = table.find(selectedParents, id) ~= nil
		local actions = {}
		
		if not isArchived then
			table.insert(actions, { text = "Alimentar\n(" .. DragonUtil.FeedCost(d.Level) .. " maçãs)", color = C.Good, fn = function()
				local ok, err = call("Feed", id)
				if ok then toast("Subiu de nível!", C.Good)
				else toast(tostring(err), C.Bad) end
			end })
			
			table.insert(actions, { text = teamIdx and "Tirar do time" or "Pôr no time", color = C.Accent, fn = function()
				call("ToggleTeam", id)
			end })
			
			table.insert(actions, { text = "Arquivar", color = C.Row, fn = function()
				local ok, err = call("ArchiveDragon", id)
				if ok then toast("Dragão arquivado", C.Muted)
				else toast(tostring(err), C.Bad) end
			end })
		else
			table.insert(actions, { text = "Desarquivar", color = C.Accent, fn = function()
				local ok, err = call("UnarchiveDragon", id)
				if ok then toast("Dragão ativado!", C.Good)
				else toast(tostring(err), C.Bad) end
			end })
		end
		
		table.insert(actions, { text = "Vender", color = C.Bad, fn = function()
			local ok, value = call("SellDragon", id)
			if ok then toast("Vendido por " .. value .. " ouro!", C.Gold)
			else toast(tostring(value), C.Bad) end
		end })
		
		if not isArchived then
			table.insert(actions, { text = isSelected and "Desmarcar" or "Cruzar", color = isSelected and C.Bad or C.Row, fn = function()
				local idx = table.find(selectedParents, id)
				if idx then
					table.remove(selectedParents, idx)
				elseif #selectedParents < 2 then
					table.insert(selectedParents, id)
				else
					toast("Escolha só 2 pais.", C.Bad)
				end
				render()
			end })
		end
		
		addRow(text, actions, Config.ElementColors[d.Element], 68)
	end
end

-- ABA INCUBADORA
renderers["Incubadora"] = function()
	local p = profile
	info("Slots: " .. #p.Eggs .. "/" .. (p.IncubatorSlots or 2), 26, C.Muted)
	
	if #p.Eggs == 0 then
		info("Incubadora vazia. Compre um ovo, cruze dois dragões ou roube um na Expedição!", 40)
	end
	
	for _, egg in ipairs(p.Eggs) do
		local ready = egg.ReadyAt <= serverNow()
		local actions = {}
		
		if ready then
			table.insert(actions, {
				text = "Chocar",
				color = C.Good,
				fn = function()
					local ok, result, extra = call("Hatch", egg.Id)
					if ok then
						if result and result.sold then
							toast("Dragão vendido por " .. result.value .. " ouro (sem habitat)", C.Gold)
						elseif result and result.Rarity then
							toast("Nasceu: " .. DragonUtil.DisplayName(result) .. " [" .. result.Rarity .. "]", C.Gold)
						else
							toast("Dragão nasceu!", C.Gold)
						end
						render()
					elseif result == "NO_HABITAT" and extra then
						-- Sem habitat: mostrar escolha
						local elementLabel = DragonUtil.ElementLabel(extra.element)
						local rarityLabel = extra.rarity
						local msg = string.format("Dragão %s [%s]%s vai nascer!\n\nVocê NÃO tem Habitat de %s disponível.\n\nEscolha uma opção:",
							elementLabel, rarityLabel, extra.shiny and " ★" or "", elementLabel)
						
						clear()
						info(msg, 120, C.Bad)
						
						addRow("ARQUIVAR - Dragão fica guardado, não produz ouro", {
							{ text = "Arquivar", color = C.Accent, fn = function()
								local ok2, d = call("Hatch", egg.Id, "Archive")
								if ok2 then
									toast("Dragão arquivado! Compre habitat para ativá-lo", C.Muted)
									render()
								end
							end }
						}, C.Accent, 60)
						
						addRow("VENDER - Recebe ouro imediatamente", {
							{ text = "Vender", color = C.Gold, fn = function()
								local ok2, result2 = call("Hatch", egg.Id, "Sell")
								if ok2 and result2.sold then
									toast("Dragão vendido por " .. result2.value .. " ouro!", C.Gold)
									render()
								end
							end }
						}, C.Gold, 60)
						
						addRow("", {
							{ text = "Cancelar", color = C.Row, fn = function() render() end }
						}, C.Row, 50)
					else
						toast(tostring(result), C.Bad)
					end
				end
			})
		else
			table.insert(actions, {
				text = "Acelerar\n(Robux)",
				color = C.Gold,
				fn = function() call("SkipEgg", egg.Id) end
			})
		end
		
		local _, titleLabel = addRow("", actions, Config.ElementColors[egg.Element], 56)

		local wasReady = ready
		local function update()
			local remaining = egg.ReadyAt - serverNow()
			titleLabel.Text = "Ovo misterioso (" .. (egg.Source or "?") .. ")\n" .. (remaining > 0 and ("Choca em " .. DragonUtil.FormatTime(remaining)) or "Pronto para chocar!")
			if not wasReady and remaining <= 0 then
				wasReady = true
				render()
			end
		end
		update()
		table.insert(liveUpdaters, update)
	end
end

-- Outras abas (placeholder)
renderers["Batalha"] = function()
	info("Sistema de batalha (em desenvolvimento)", 40)
end

renderers["Expedição"] = function()
	info("Sistema de expedição (em desenvolvimento)", 40)
end

----------------------------------------------------------------------
-- SISTEMA DE ABAS
----------------------------------------------------------------------
local TAB_NAMES = { "Base", "Construir", "Dragões", "Incubadora", "Batalha", "Expedição" }
local tabButtons = {}

render = function()
	if not profile then return end
	for name, b in pairs(tabButtons) do
		b.BackgroundColor3 = (name == currentTab) and C.Accent or C.Row
	end
	clear()
	renderers[currentTab]()
end

for i, name in ipairs(TAB_NAMES) do
	tabButtons[name] = button(tabsFrame, name, C.Row, function()
		currentTab = name
		render()
	end, { Size = UDim2.new(1, 0, 0, 44), LayoutOrder = i, TextSize = 15 })
end

local function updateTop()
	if profile then
		goldLabel.Text = "Ouro: " .. math.floor(profile.Gold)
		applesLabel.Text = "Maçãs: " .. math.floor(profile.Apples)
	end
end

----------------------------------------------------------------------
-- EVENTOS DO SERVIDOR
----------------------------------------------------------------------
Remotes.ProfileChanged.OnClientEvent:Connect(function(p)
	profile = p
	updateTop()
	render()
end)

Remotes.Notify.OnClientEvent:Connect(function(text)
	toast(text)
end)

-- Loop de atualização
task.spawn(function()
	while true do
		task.wait(0.5)
		if profile and panel.Visible then
			for _, fn in ipairs(liveUpdaters) do
				fn()
			end
		end
	end
end)

-- Carga inicial
local ok, data = call("GetProfile")
if ok then
	profile = data
	updateTop()
	render()
end
