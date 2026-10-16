--[[
	BattleService (ModuleScript)
	Local no Studio: ServerScriptService > Services > BattleService
	Torneio 3v3 POR TURNOS contra um time de IA. 100% autoritativo no servidor.

	Ações por rodada: Physical, Elemental (cooldown), Defend, Switch.
	Agilidade define quem age primeiro e a chance de esquiva.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DragonUtil = require(ReplicatedStorage.Shared.DragonUtil)
local Data = require(script.Parent.DataService)
local Dragon = require(script.Parent.DragonService)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local BattleService = {}
BattleService.Handlers = {}

local battles = {} -- [player] = state

----------------------------------------------------------------------
-- Montagem dos times
----------------------------------------------------------------------
local function makeFighter(d)
	local stats = DragonUtil.GetStats(d)
	return {
		Name = DragonUtil.DisplayName(d),
		Element = d.Element,
		Level = d.Level,
		Shiny = d.Shiny,
		Stats = stats,
		HP = stats.Vitalidade,
		MaxHP = stats.Vitalidade,
		ElemCd = 0,
		Defending = false,
	}
end

local function makeEnemyTeam(avgLevel)
	local fighters = {}
	for _ = 1, 3 do
		local lvl = math.max(1, avgLevel + math.random(-1, 2))
		local d = Dragon.New(Config.Elements[math.random(#Config.Elements)], Dragon.RollRarity(0, 3), false)
		d.Level = lvl
		table.insert(fighters, makeFighter(d))
	end
	return { Fighters = fighters, Active = 1 }
end

----------------------------------------------------------------------
-- Regras de combate
----------------------------------------------------------------------
local function typeMult(atkEl, defEl)
	local strong = Config.Advantage[atkEl]
	if strong and table.find(strong, defEl) then
		return 1.5
	end
	local defStrong = Config.Advantage[defEl]
	if defStrong and table.find(defStrong, atkEl) then
		return 0.7
	end
	return 1
end

local function dodgeChance(attacker, defender)
	return math.clamp(0.05 + (defender.Stats.Agilidade - attacker.Stats.Agilidade) * 0.005, 0, 0.35)
end

local function doAttack(attacker, defender, kind, log)
	if math.random() < dodgeChance(attacker, defender) then
		table.insert(log, defender.Name .. " desviou do ataque de " .. attacker.Name .. "!")
		if kind == "Elemental" then
			attacker.ElemCd = Config.Battle.ElementalCooldown
		end
		return
	end

	local base, mult = 0, 1
	if kind == "Physical" then
		base = attacker.Stats.PoderFisico * 1.6
	else
		base = attacker.Stats.PoderElemental * 2.4
		mult = typeMult(attacker.Element, defender.Element)
		attacker.ElemCd = Config.Battle.ElementalCooldown
	end

	local dmg = base * mult * (100 / (100 + defender.Stats.Resistencia * 2))
	if defender.Defending then
		dmg *= 0.5
	end
	dmg = math.max(1, math.floor(dmg * (0.9 + math.random() * 0.2)))
	defender.HP = math.max(0, defender.HP - dmg)

	local what = kind == "Physical" and "ataque físico" or "ataque elemental"
	local line = string.format("%s usou %s em %s: -%d HP", attacker.Name, what, defender.Name, dmg)
	if mult > 1 then
		line ..= " (super efetivo!)"
	elseif mult < 1 then
		line ..= " (pouco efetivo...)"
	end
	table.insert(log, line)
end

local function aliveCount(side)
	local n = 0
	for _, f in ipairs(side.Fighters) do
		if f.HP > 0 then
			n += 1
		end
	end
	return n
end

local function nextAlive(side)
	for i, f in ipairs(side.Fighters) do
		if f.HP > 0 then
			return i
		end
	end
	return nil
end

local function checkFaint(side, log)
	local active = side.Fighters[side.Active]
	if active.HP <= 0 then
		table.insert(log, active.Name .. " foi derrotado!")
		local idx = nextAlive(side)
		if idx then
			side.Active = idx
			table.insert(log, side.Fighters[idx].Name .. " entra na batalha!")
		end
	end
end

local function chooseEnemyAction(f)
	local r = math.random()
	if f.ElemCd == 0 then
		if r < 0.55 then
			return "Elemental"
		elseif r < 0.65 then
			return "Defend"
		end
		return "Physical"
	end
	return r < 0.15 and "Defend" or "Physical"
end

local function snapshot(state, log, isStart)
	local function side(s)
		local out = { Active = s.Active, Fighters = {} }
		for i, f in ipairs(s.Fighters) do
			out.Fighters[i] = { Name = f.Name, Element = f.Element, Level = f.Level, HP = f.HP, MaxHP = f.MaxHP, ElemCd = f.ElemCd }
		end
		return out
	end
	return {
		Player = side(state.Player),
		Enemy = side(state.Enemy),
		Log = log,
		Start = isStart or false,
		Over = state.Over,
		Won = state.Won,
		Rewards = state.Rewards,
		Round = state.Round,
	}
end

local function resolveRound(player, state, pAct)
	local log = {}
	local P, E = state.Player, state.Enemy
	local pf, ef = P.Fighters[P.Active], E.Fighters[E.Active]
	pf.Defending, ef.Defending = false, false

	local eAct = chooseEnemyAction(ef)

	if pAct.Type == "Switch" then
		P.Active = pAct.Index
		pf = P.Fighters[P.Active]
		table.insert(log, "Você trocou para " .. pf.Name .. "!")
	elseif pAct.Type == "Defend" then
		pf.Defending = true
		table.insert(log, pf.Name .. " está se defendendo.")
	end
	if eAct == "Defend" then
		ef.Defending = true
		table.insert(log, ef.Name .. " (inimigo) está se defendendo.")
	end

	local actors = {}
	if pAct.Type == "Physical" or pAct.Type == "Elemental" then
		table.insert(actors, { Side = "P", F = pf, Kind = pAct.Type, Roll = math.random() })
	end
	if eAct == "Physical" or eAct == "Elemental" then
		table.insert(actors, { Side = "E", F = ef, Kind = eAct, Roll = math.random() })
	end
	table.sort(actors, function(a, b)
		if a.F.Stats.Agilidade ~= b.F.Stats.Agilidade then
			return a.F.Stats.Agilidade > b.F.Stats.Agilidade
		end
		return a.Roll > b.Roll
	end)

	for _, a in ipairs(actors) do
		local mine = (a.Side == "P") and P or E
		local theirs = (a.Side == "P") and E or P
		local attacker = mine.Fighters[mine.Active]
		local defender = theirs.Fighters[theirs.Active]
		if attacker == a.F and attacker.HP > 0 and defender.HP > 0 then
			doAttack(attacker, defender, a.Kind, log)
			checkFaint(theirs, log)
			if aliveCount(theirs) == 0 then
				break
			end
		end
	end

	for _, side in ipairs({ P, E }) do
		for _, f in ipairs(side.Fighters) do
			if f.ElemCd > 0 then
				f.ElemCd -= 1
			end
		end
	end
	state.Round += 1

	if aliveCount(E) == 0 or aliveCount(P) == 0 then
		state.Over = true
		state.Won = aliveCount(E) == 0
		local profile = Data.Get(player)
		if state.Won then
			local gold = Config.Battle.RewardGold(state.AvgLevel)
			local apples = Config.Battle.RewardApples(state.AvgLevel)
			profile.Gold += gold
			profile.Apples += apples
			profile.Stats.Wins += 1
			state.Rewards = { Gold = gold, Apples = apples }
			table.insert(log, string.format("VITÓRIA! +%d ouro, +%d maçãs.", gold, apples))
		else
			profile.Gold += 10
			state.Rewards = { Gold = 10, Apples = 0 }
			table.insert(log, "Derrota... (+10 ouro de consolação)")
		end
		Data.Push(player)
		battles[player] = nil
	end

	return log
end

----------------------------------------------------------------------
-- Handlers
----------------------------------------------------------------------
function BattleService.Handlers.BattleStart(player)
	if battles[player] then
		Remotes.BattleEvent:FireClient(player, snapshot(battles[player], { "Batalha retomada." }, true))
		return true
	end
	local profile = Data.Get(player)
	local fighters, levelSum = {}, 0
	for _, id in ipairs(profile.Team) do
		local d = profile.Dragons[id]
		if d then
			table.insert(fighters, makeFighter(d))
			levelSum += d.Level
		end
	end
	if #fighters == 0 then
		return false, "Monte um time primeiro (aba Dragões)."
	end

	local avg = math.max(1, math.floor(levelSum / #fighters))
	local state = {
		Player = { Fighters = fighters, Active = 1 },
		Enemy = makeEnemyTeam(avg),
		Round = 1,
		AvgLevel = avg,
		Over = false,
		Won = false,
	}
	battles[player] = state
	Remotes.BattleEvent:FireClient(player, snapshot(state, { "O torneio começou! Escolha sua ação." }, true))
	return true
end

function BattleService.Handlers.BattleAction(player, actionType, index)
	local state = battles[player]
	if not state then
		return false, "Nenhuma batalha em andamento."
	end
	local valid = { Physical = true, Elemental = true, Defend = true, Switch = true }
	if type(actionType) ~= "string" or not valid[actionType] then
		return false, "Ação inválida."
	end

	local P = state.Player
	local me = P.Fighters[P.Active]
	if actionType == "Elemental" and me.ElemCd > 0 then
		return false, "Ataque elemental em recarga (" .. me.ElemCd .. ")."
	end
	if actionType == "Switch" then
		if type(index) ~= "number" or not P.Fighters[index] or P.Fighters[index].HP <= 0 or index == P.Active then
			return false, "Troca inválida."
		end
	end

	local log = resolveRound(player, state, { Type = actionType, Index = index })
	Remotes.BattleEvent:FireClient(player, snapshot(state, log, false))
	return true
end

game:GetService("Players").PlayerRemoving:Connect(function(player)
	battles[player] = nil
end)

return BattleService
