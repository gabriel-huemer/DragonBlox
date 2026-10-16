--[[
	HeistService (ModuleScript)
	Local no Studio: ServerScriptService > Services > HeistService
	Modo "Roube um Ovo" (PvPvE / extração).

	MAPA: se não existir Workspace.HeistMap, o script GERA um mapa de teste automaticamente.
	Para usar seu próprio mapa, crie em Workspace uma Folder "HeistMap" contendo:
	  - Part  "HeistSpawn"           (onde os jogadores aparecem)
	  - Folder "Nests"               (Parts com Attribute Tier = 1, 2 ou 3)
	  - Folder "WildSpawns"          (Parts com Attribute Kind = "Small" ou "Colossal")
	  - Folder "ExtractionZones"     (Parts; o jogador precisa ficar dentro por alguns segundos)
	O dragão companheiro e o combate são todos controlados pelo servidor.
]]

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local DragonUtil = require(ReplicatedStorage.Shared.DragonUtil)
local Data = require(script.Parent.DataService)
local Incubator = require(script.Parent.IncubatorService)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local HC = Config.Heist

local HeistService = {}
HeistService.Handlers = {}

local active = {} -- [player] = estado da expedição
local wilds = {} -- lista de dragões selvagens
local mapFolder
local extractionZones = {}
local wildFolder
local rayParams = RaycastParams.new()

----------------------------------------------------------------------
-- Utilidades
----------------------------------------------------------------------
local function notify(player, text)
	Remotes.Notify:FireClient(player, text)
end

local function getRoot(player)
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(player)
	local c = player.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function beam(a, b, color)
	local dist = (b - a).Magnitude
	if dist < 0.1 then
		return
	end
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Size = Vector3.new(0.4, 0.4, dist)
	p.CFrame = CFrame.lookAt(a, b) * CFrame.new(0, 0, -dist / 2)
	p.Parent = workspace
	Debris:AddItem(p, 0.15)
end

local function groundY(x, z, fallback)
	local hit = workspace:Raycast(Vector3.new(x, 500, z), Vector3.new(0, -1000, 0), rayParams)
	return hit and hit.Position.Y or fallback
end

-- Modelo simples de dragão feito de Parts (troque por seus modelos depois)
local function buildDragonModel(name, color, size, material)
	local model = Instance.new("Model")
	model.Name = name

	local function mk(partName, partSize, cf)
		local p = Instance.new("Part")
		p.Name = partName
		p.Size = partSize
		p.CFrame = cf
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end

	local origin = CFrame.new(0, 0, 0)
	local body = mk("Body", size, origin)
	local headSize = Vector3.new(size.X * 0.6, size.Y * 0.8, size.Z * 0.3)
	mk("Head", headSize, origin * CFrame.new(0, size.Y * 0.2, -(size.Z / 2 + headSize.Z / 2 - 0.2)))
	local wingSize = Vector3.new(size.X * 1.2, 0.3, size.Z * 0.6)
	mk("WingL", wingSize, origin * CFrame.new(-(size.X / 2 + wingSize.X / 2), size.Y * 0.3, 0) * CFrame.Angles(0, 0, math.rad(15)))
	mk("WingR", wingSize, origin * CFrame.new(size.X / 2 + wingSize.X / 2, size.Y * 0.3, 0) * CFrame.Angles(0, 0, math.rad(-15)))

	model.PrimaryPart = body

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(180, 36)
	gui.StudsOffset = Vector3.new(0, size.Y + 2, 0)
	gui.AlwaysOnTop = true
	gui.Adornee = body
	gui.Parent = body
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextStrokeTransparency = 0.3
	text.Font = Enum.Font.GothamBold
	text.TextScaled = true
	text.Text = name
	text.Parent = gui

	return model, text
end

----------------------------------------------------------------------
-- Mapa de teste (gerado se você não tiver um)
----------------------------------------------------------------------
local function buildTestMap()
	local map = Instance.new("Folder")
	map.Name = "HeistMap"
	local origin = Vector3.new(3000, 0, 3000) -- longe da base
	local rng = Random.new(7)

	local function mkPart(parent, name, size, pos, color, material)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.Size = size
		p.Position = pos
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = parent
		return p
	end

	local function randomPos(minR, maxR)
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(minR, maxR)
		return origin + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
	end

	mkPart(map, "Ground", Vector3.new(700, 4, 700), origin - Vector3.new(0, 2, 0), Color3.fromRGB(70, 130, 60), Enum.Material.Grass)

	-- paredes baixas invisíveis para ninguém cair do mapa
	for _, s in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
		local w = mkPart(map, "Wall", Vector3.new(s[1] ~= 0 and 4 or 700, 80, s[2] ~= 0 and 4 or 700), origin + Vector3.new(s[1] * 350, 40, s[2] * 350), Color3.new(1, 1, 1))
		w.Transparency = 1
	end

	mkPart(map, "HeistSpawn", Vector3.new(14, 1, 14), origin + Vector3.new(-300, 0.5, -300), Color3.fromRGB(80, 160, 255), Enum.Material.Neon)

	-- colinas para dar cobertura
	for i = 1, 14 do
		local size = rng:NextInteger(40, 90)
		local hill = mkPart(map, "Hill" .. i, Vector3.one * size, randomPos(30, 280), Color3.fromRGB(110, 110, 115), Enum.Material.Rock)
		hill.Shape = Enum.PartType.Ball
	end

	local nests = Instance.new("Folder")
	nests.Name = "Nests"
	nests.Parent = map
	local function addNest(tier, minR, maxR)
		local nest = mkPart(nests, "Nest", Vector3.new(10, 1, 10), randomPos(minR, maxR) + Vector3.new(0, 0.5, 0), Color3.fromRGB(110, 80, 50), Enum.Material.Wood)
		nest:SetAttribute("Tier", tier)
	end
	for _ = 1, 6 do
		addNest(1, 150, 260)
	end
	for _ = 1, 4 do
		addNest(2, 80, 150)
	end
	for _ = 1, 2 do
		addNest(3, 0, 60)
	end

	local spawns = Instance.new("Folder")
	spawns.Name = "WildSpawns"
	spawns.Parent = map
	local function addWild(kind, minR, maxR)
		local sp = mkPart(spawns, "WildSpawn", Vector3.new(2, 1, 2), randomPos(minR, maxR) + Vector3.new(0, 0.5, 0), Color3.new(1, 0, 0))
		sp.Transparency = 1
		sp.CanCollide = false
		sp:SetAttribute("Kind", kind)
	end
	for _ = 1, 8 do
		addWild("Small", 100, 260)
	end
	for _ = 1, 3 do
		addWild("Colossal", 40, 140)
	end

	local zones = Instance.new("Folder")
	zones.Name = "ExtractionZones"
	zones.Parent = map
	for _, c in ipairs({ { 300, -300 }, { -300, 300 }, { 300, 300 } }) do
		local z = mkPart(zones, "Extraction", Vector3.new(26, 1, 26), origin + Vector3.new(c[1], 0.5, c[2]), Color3.fromRGB(60, 255, 120), Enum.Material.Neon)
		z.Transparency = 0.4
		z.CanCollide = false
	end

	map.Parent = workspace
	return map
end

----------------------------------------------------------------------
-- Ovos: pegar, carregar, largar
----------------------------------------------------------------------
local function setCarrySpeed(player, tier)
	local hum = getHumanoid(player)
	if not hum then
		return
	end
	hum.UseJumpPower = true
	if tier then
		hum.WalkSpeed = HC.Tiers[tier].WalkSpeed
		hum.JumpPower = 25
	else
		hum.WalkSpeed = HC.WalkSpeed
		hum.JumpPower = HC.JumpPower
	end
end

local function makeEggPart(tier)
	local t = HC.Tiers[tier]
	local egg = Instance.new("Part")
	egg.Shape = Enum.PartType.Ball
	egg.Size = Vector3.one * t.Size * 2
	egg.Material = Enum.Material.Neon
	egg.Color = t.Color
	egg.CanCollide = false
	return egg
end

local claimEgg -- forward declaration

local function dropEgg(position, tier)
	local egg = makeEggPart(tier)
	egg.Name = "DroppedEgg"
	egg.Anchored = true
	egg.Position = position + Vector3.new(0, HC.Tiers[tier].Size, 0)
	egg.Parent = workspace

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Pegar ovo"
	prompt.ObjectText = "Ovo caído (" .. HC.Tiers[tier].Name .. ")"
	prompt.HoldDuration = 1.5
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = egg
	prompt.Triggered:Connect(function(plr)
		if claimEgg(plr, tier) then
			egg:Destroy()
		end
	end)
	Debris:AddItem(egg, HC.DroppedEggLifetime)
end

claimEgg = function(player, tier)
	local st = active[player]
	if not st then
		notify(player, "Entre na Expedição para roubar ovos!")
		return false
	end
	if st.Carrying then
		notify(player, "Você já está carregando um ovo!")
		return false
	end
	local char, root, hum = player.Character, getRoot(player), getHumanoid(player)
	if not char or not root or not hum or hum.Health <= 0 then
		return false
	end

	st.Carrying = { Tier = tier }
	local egg = makeEggPart(tier)
	egg.Name = "CarriedEgg"
	egg.Massless = true
	egg.CFrame = root.CFrame * CFrame.new(0, 0.5, 1.8 + HC.Tiers[tier].Size)
	egg.Parent = char
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = egg
	weld.Parent = egg
	st.EggVisual = egg

	setCarrySpeed(player, tier)
	notify(player, "Ovo " .. HC.Tiers[tier].Name .. " roubado! Leve até a zona de extração (verde)!")
	Remotes.HeistEvent:FireClient(player, "Carrying", HC.Tiers[tier].Name)
	return true
end

local function alertWild(position, radius)
	for _, w in ipairs(wilds) do
		if w.Alive and (w.Body.Position - position).Magnitude < radius then
			w.AlertUntil = os.clock() + 20
		end
	end
end

local function setupNest(nest)
	local tier = nest:GetAttribute("Tier") or 1
	local t = HC.Tiers[tier]

	local egg = makeEggPart(tier)
	egg.Name = "NestEgg"
	egg.Anchored = true
	egg.Position = nest.Position + Vector3.new(0, t.Size + 0.5, 0)
	egg.Parent = nest

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Roubar ovo " .. t.Name
	prompt.ObjectText = "Ninho (Tier " .. tier .. ")"
	prompt.HoldDuration = 1.5 + tier
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = nest

	prompt.Triggered:Connect(function(plr)
		if not claimEgg(plr, tier) then
			return
		end
		egg.Transparency = 1
		prompt.Enabled = false
		alertWild(nest.Position, 150) -- os pais ficam furiosos!
		task.delay(HC.NestCooldown, function()
			egg.Transparency = 0
			prompt.Enabled = true
		end)
	end)
end

----------------------------------------------------------------------
-- Dragões selvagens (PvE)
----------------------------------------------------------------------
local function spawnWild(spawnPart)
	local kind = spawnPart:GetAttribute("Kind") or "Small"
	local cfg = HC.Wild[kind]
	if not cfg then
		return
	end
	local element = Config.Elements[math.random(#Config.Elements)]
	local color = Config.ElementColors[element]

	local model, label = buildDragonModel(cfg.Name .. " (" .. DragonUtil.ElementLabel(element) .. ")", color, cfg.Size)
	local home = spawnPart.Position
	model:PivotTo(CFrame.new(home + Vector3.new(0, cfg.Size.Y / 2 + cfg.HoverHeight, 0)))
	model.Parent = wildFolder

	table.insert(wilds, {
		Model = model,
		Body = model.PrimaryPart,
		Label = label,
		Home = home,
		Cfg = cfg,
		Color = color,
		HP = cfg.HP,
		MaxHP = cfg.HP,
		Alive = true,
		AttackCd = 0,
		AlertUntil = 0,
		BaseName = cfg.Name .. " (" .. DragonUtil.ElementLabel(element) .. ")",
	})
end

local function damageWild(w, dmg, killer)
	w.HP -= dmg
	w.Label.Text = string.format("%s  %d/%d", w.BaseName, math.max(0, math.floor(w.HP)), w.MaxHP)
	if w.HP > 0 then
		return
	end

	w.Alive = false
	w.Model.Parent = nil
	local st = active[killer]
	if st then
		st.LootGold += w.Cfg.Reward
		notify(killer, "Seu dragão derrotou um " .. w.Cfg.Name .. "! +" .. w.Cfg.Reward .. " ouro (pago na extração)")
	end
	task.delay(HC.WildRespawn, function()
		w.HP = w.MaxHP
		w.Alive = true
		w.AlertUntil = 0
		w.Label.Text = w.BaseName
		w.Model:PivotTo(CFrame.new(w.Home + Vector3.new(0, w.Cfg.Size.Y / 2 + w.Cfg.HoverHeight, 0)))
		w.Model.Parent = wildFolder
	end)
end

local function stepWilds(dt)
	local now = os.clock()
	for _, w in ipairs(wilds) do
		if w.Alive then
			local cfg = w.Cfg
			local pos = w.Body.Position
			local range = (w.AlertUntil > now) and cfg.AggroRange * 2 or cfg.AggroRange

			local tRoot, tHum, bestD
			bestD = range
			for player in pairs(active) do
				local r, h = getRoot(player), getHumanoid(player)
				if r and h and h.Health > 0 then
					local d = (r.Position - pos).Magnitude
					if d < bestD then
						bestD, tRoot, tHum = d, r, h
					end
				end
			end

			local goal = tRoot and tRoot.Position or w.Home
			local flat = Vector3.new(goal.X - pos.X, 0, goal.Z - pos.Z)
			local dist = flat.Magnitude
			local stopAt = tRoot and cfg.PreferredDistance or 3
			local nx, nz = pos.X, pos.Z
			if dist > stopAt then
				local step = math.min(cfg.Speed * dt, dist - stopAt)
				local dir = flat.Unit
				nx += dir.X * step
				nz += dir.Z * step
			end

			local y = groundY(nx, nz, w.Home.Y) + cfg.HoverHeight + cfg.Size.Y / 2
			local newPos = Vector3.new(nx, y, nz)
			local look = Vector3.new(goal.X, y, goal.Z)
			if (look - newPos).Magnitude > 0.5 then
				w.Model:PivotTo(CFrame.lookAt(newPos, look))
			else
				w.Model:PivotTo(CFrame.new(newPos))
			end

			w.AttackCd -= dt
			if tRoot and w.AttackCd <= 0 and (tRoot.Position - newPos).Magnitude <= cfg.AttackRange then
				w.AttackCd = cfg.Cooldown
				if cfg.Ranged then
					beam(newPos, tRoot.Position, w.Color)
				end
				tHum:TakeDamage(cfg.Damage)
			end
		end
	end
end

----------------------------------------------------------------------
-- Dragão companheiro (segue o jogador e ataca sozinho)
----------------------------------------------------------------------
local function tryCompanionAttack(player, st)
	local origin = st.Companion.PrimaryPart.Position
	local bestWild, bestPlayer
	local bestD = HC.CompanionRange

	for _, w in ipairs(wilds) do
		if w.Alive then
			local d = (w.Body.Position - origin).Magnitude
			if d < bestD then
				bestD, bestWild, bestPlayer = d, w, nil
			end
		end
	end
	for other in pairs(active) do -- PvP: ataca outros jogadores da expedição
		if other ~= player then
			local r = getRoot(other)
			if r then
				local d = (r.Position - origin).Magnitude
				if d < bestD then
					bestD, bestWild, bestPlayer = d, nil, other
				end
			end
		end
	end

	local damage = (st.Stats.PoderFisico + st.Stats.PoderElemental) * 1.2
	local color = Config.ElementColors[st.Dragon.Element]
	if bestWild then
		beam(origin, bestWild.Body.Position, color)
		damageWild(bestWild, damage, player)
		return true
	elseif bestPlayer then
		local hum = getHumanoid(bestPlayer)
		local r = getRoot(bestPlayer)
		if hum and r and hum.Health > 0 then
			beam(origin, r.Position, color)
			hum:TakeDamage(damage * 0.6)
			return true
		end
	end
	return false
end

local function stepCompanions(dt)
	for player, st in pairs(active) do
		local root = getRoot(player)
		local comp = st.Companion
		if root and comp and comp.PrimaryPart then
			st.LastPos = root.Position
			local bob = math.sin(os.clock() * 3) * 0.6
			local target = root.CFrame * CFrame.new(4, 4 + bob, 5)
			comp:PivotTo(comp:GetPivot():Lerp(target, math.min(1, dt * 6)))

			st.AttackCd -= dt
			if st.AttackCd <= 0 then
				st.AttackCd = tryCompanionAttack(player, st) and HC.CompanionCooldown or 0.2
			end
		end
	end
end

----------------------------------------------------------------------
-- Entrar / sair / extrair
----------------------------------------------------------------------
local function cleanup(player)
	local st = active[player]
	if not st then
		return
	end
	active[player] = nil
	for _, c in ipairs(st.Conns) do
		c:Disconnect()
	end
	if st.Companion then
		st.Companion:Destroy()
	end
	if st.EggVisual then
		st.EggVisual:Destroy()
	end
	if st.Carrying then
		dropEgg(st.LastPos, st.Carrying.Tier) -- quem matar pode pegar o ovo!
		st.Carrying = nil
	end
	if player.Parent then
		Remotes.HeistEvent:FireClient(player, "Left")
	end
end

local function extract(player)
	local st = active[player]
	if not st then
		return
	end
	local profile = Data.Get(player)
	local lines = {}

	if st.Carrying then
		local egg = Incubator.CreateHeistEgg(st.Carrying.Tier)
		Incubator.AddEgg(player, egg, true) -- ovo roubado ignora o limite da incubadora
		profile.Stats.EggsStolen += 1
		table.insert(lines, "Ovo " .. HC.Tiers[st.Carrying.Tier].Name .. " na incubadora!")
		st.Carrying = nil -- consumido (não cai no cleanup)
	else
		table.insert(lines, "Você saiu sem ovo.")
	end
	if st.LootGold > 0 then
		profile.Gold += st.LootGold
		table.insert(lines, "+" .. st.LootGold .. " ouro.")
	end
	profile.Stats.Heists += 1

	cleanup(player)
	Data.Push(player)
	Remotes.HeistEvent:FireClient(player, "Result", table.concat(lines, " "))
	task.spawn(function()
		player:LoadCharacter() -- volta para a base
	end)
end

local function onDied(player)
	local st = active[player]
	if not st then
		return
	end
	local hadEgg = st.Carrying ~= nil
	cleanup(player)
	notify(player, hadEgg and "Você morreu e perdeu o ovo!" or "Você morreu na expedição.")
end

function HeistService.Handlers.EnterHeist(player)
	if active[player] then
		return false, "Você já está na expedição."
	end
	if not mapFolder then
		return false, "Mapa da expedição indisponível."
	end
	local profile = Data.Get(player)
	local dragon = profile.Dragons[profile.Team[1]]
	if not dragon then
		return false, "Monte um time primeiro (aba Dragões)."
	end
	local char, root, hum = player.Character, getRoot(player), getHumanoid(player)
	local spawnPart = mapFolder:FindFirstChild("HeistSpawn")
	if not (char and root and hum and hum.Health > 0 and spawnPart) then
		return false, "Não foi possível entrar agora."
	end

	char:PivotTo(spawnPart.CFrame * CFrame.new(math.random(-4, 4), 4, math.random(-4, 4)))
	setCarrySpeed(player, nil)

	local stats = DragonUtil.GetStats(dragon)
	local model = buildDragonModel(
		DragonUtil.DisplayName(dragon) .. " Lv." .. dragon.Level,
		Config.ElementColors[dragon.Element],
		Vector3.new(3, 2.5, 5),
		dragon.Shiny and Enum.Material.Neon or Enum.Material.SmoothPlastic
	)
	model:PivotTo(root.CFrame * CFrame.new(4, 4, 5))
	model.Parent = workspace

	local st = {
		Dragon = dragon,
		Stats = stats,
		Companion = model,
		Carrying = nil,
		EggVisual = nil,
		ExtractT = 0,
		AttackCd = 0,
		LootGold = 0,
		LastPos = root.Position,
		Conns = {},
	}
	active[player] = st

	table.insert(st.Conns, hum.Died:Connect(function()
		onDied(player)
	end))
	table.insert(st.Conns, player.CharacterRemoving:Connect(function()
		cleanup(player)
	end))

	Remotes.HeistEvent:FireClient(player, "Entered")
	notify(player, "Você está na expedição! Roube um ovo e fuja para a zona verde.")
	return true
end

----------------------------------------------------------------------
-- Inicialização
----------------------------------------------------------------------
function HeistService.Init()
	mapFolder = workspace:FindFirstChild("HeistMap") or buildTestMap()

	wildFolder = Instance.new("Folder")
	wildFolder.Name = "HeistWildlife"
	wildFolder.Parent = workspace

	rayParams.FilterType = Enum.RaycastFilterType.Include
	rayParams.FilterDescendantsInstances = { mapFolder }

	local nests = mapFolder:FindFirstChild("Nests")
	if nests then
		for _, nest in ipairs(nests:GetChildren()) do
			if nest:IsA("BasePart") then
				setupNest(nest)
			end
		end
	else
		warn("[Heist] HeistMap.Nests não encontrado")
	end

	local spawns = mapFolder:FindFirstChild("WildSpawns")
	if spawns then
		for _, sp in ipairs(spawns:GetChildren()) do
			if sp:IsA("BasePart") then
				spawnWild(sp)
			end
		end
	end

	local zones = mapFolder:FindFirstChild("ExtractionZones")
	if zones then
		for _, z in ipairs(zones:GetChildren()) do
			if z:IsA("BasePart") then
				table.insert(extractionZones, z)
			end
		end
	else
		warn("[Heist] HeistMap.ExtractionZones não encontrado")
	end

	RunService.Heartbeat:Connect(function(dt)
		stepWilds(dt)
		stepCompanions(dt)
	end)

	-- Extração: ficar parado na zona por ExtractSeconds
	task.spawn(function()
		local TICK = 0.25
		while true do
			task.wait(TICK)
			for player, st in pairs(active) do
				local root = getRoot(player)
				if root then
					local inZone = false
					for _, z in ipairs(extractionZones) do
						local dx = root.Position.X - z.Position.X
						local dz = root.Position.Z - z.Position.Z
						if math.sqrt(dx * dx + dz * dz) <= z.Size.X / 2 then
							inZone = true
							break
						end
					end
					if inZone then
						st.ExtractT += TICK
						Remotes.HeistEvent:FireClient(player, "Extracting", math.min(st.ExtractT / HC.ExtractSeconds, 1))
						if st.ExtractT >= HC.ExtractSeconds then
							extract(player)
						end
					elseif st.ExtractT > 0 then
						st.ExtractT = 0
						Remotes.HeistEvent:FireClient(player, "Extracting", 0)
					end
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(cleanup)
end

return HeistService
