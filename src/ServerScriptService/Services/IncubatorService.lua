--[[
	IncubatorService (ModuleScript)
	Local no Studio: ServerScriptService > Services > IncubatorService
	Ovos básicos, cruzamento de elementos, chocar, acelerar com Robux e ovos roubados na expedição.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local DragonUtil = require(ReplicatedStorage.Shared.DragonUtil)
local Data = require(script.Parent.DataService)
local Dragon = require(script.Parent.DragonService)
local HabitatManager = require(script.Parent.Parent.Modules.HabitatManager)

local IncubatorService = {}
IncubatorService.Handlers = {}

local pendingSkip = {} -- [userId] = eggId aguardando compra

----------------------------------------------------------------------
-- API usada por outros serviços
----------------------------------------------------------------------
function IncubatorService.AddEgg(player, egg, force)
	local profile = Data.Get(player)
	if not force and not HabitatManager.CanAddEgg(profile) then
		return false, "Incubadora cheia"
	end
	egg.Id = "e" .. profile.NextId
	profile.NextId += 1
	table.insert(profile.Eggs, egg)
	return true, egg
end

-- Ovo roubado na expedição. Tier 1..3 (pequeno, grande, gigante)
function IncubatorService.CreateHeistEgg(tier)
	local t = Config.Heist.Tiers[tier]
	local weights = {}
	for _, e in ipairs(Config.BasicEggElements) do
		weights[e] = 10
	end
	weights.Infernal = 2 * tier
	weights.Cosmico = 0.5 * tier * tier -- 0.5 / 2 / 4.5

	local element = DragonUtil.WeightedPick(Config.Elements, function(e)
		return weights[e] or 0
	end)
	return {
		Element = element,
		Rarity = Dragon.RollRarity(t.RarityBonus),
		Shiny = Dragon.RollShiny(t.ShinyChance),
		ReadyAt = os.time() + t.HatchSeconds,
		Source = "Expedição",
	}
end

----------------------------------------------------------------------
-- Cruzamento
----------------------------------------------------------------------
local function resolveElement(ea, eb)
	for _, r in ipairs(Config.Recipes) do
		if (r.A == ea and r.B == eb) or (r.A == eb and r.B == ea) then
			if math.random() < r.Chance then
				return r.Result
			end
		end
	end
	return math.random() < 0.5 and ea or eb
end

local function resolveRarity(a, b)
	local ia, ib = Config.RarityIndex[a.Rarity], Config.RarityIndex[b.Rarity]
	local idx = math.random(math.min(ia, ib), math.max(ia, ib))
	if math.random() < 0.2 then
		idx = math.min(idx + 1, #Config.Rarities)
	end
	return Config.Rarities[idx].Name
end

----------------------------------------------------------------------
-- Handlers
----------------------------------------------------------------------
function IncubatorService.Handlers.BuyEgg(player)
	local profile = Data.Get(player)
	if #profile.Eggs >= Config.IncubatorSlots then
		return false, "Incubadora cheia."
	end
	if profile.Gold < Config.BasicEggCost then
		return false, "Ouro insuficiente (" .. Config.BasicEggCost .. ")."
	end
	profile.Gold -= Config.BasicEggCost
	IncubatorService.AddEgg(player, {
		Element = Config.BasicEggElements[math.random(#Config.BasicEggElements)],
		Rarity = Dragon.RollRarity(0, 3), -- ovo básico não dá Lendário/Mítico
		Shiny = Dragon.RollShiny(),
		ReadyAt = os.time() + Config.BasicEggHatchSeconds,
		Source = "Loja",
	})
	Data.Push(player)
	return true
end

function IncubatorService.Handlers.Breed(player, idA, idB)
	local profile = Data.Get(player)
	if type(idA) ~= "string" or type(idB) ~= "string" or idA == idB then
		return false, "Escolha dois dragões diferentes."
	end
	local a, b = profile.Dragons[idA], profile.Dragons[idB]
	if not a or not b then
		return false, "Dragão inválido."
	end
	if a.Level < Config.MinBreedLevel or b.Level < Config.MinBreedLevel then
		return false, "Os pais precisam ser nível " .. Config.MinBreedLevel .. "+."
	end
	if #profile.Eggs >= Config.IncubatorSlots then
		return false, "Incubadora cheia."
	end
	if profile.Gold < Config.BreedCost then
		return false, "Ouro insuficiente (" .. Config.BreedCost .. ")."
	end

	profile.Gold -= Config.BreedCost
	local shinyChance = (a.Shiny or b.Shiny) and 0.10 or 0.03
	IncubatorService.AddEgg(player, {
		Element = resolveElement(a.Element, b.Element),
		Rarity = resolveRarity(a, b),
		Shiny = Dragon.RollShiny(shinyChance),
		ReadyAt = os.time() + Config.BreedHatchSeconds,
		Source = "Cruzamento",
	})
	Data.Push(player)
	return true
end

function IncubatorService.Handlers.Hatch(player, eggId, action)
	local profile = Data.Get(player)
	for i, egg in ipairs(profile.Eggs) do
		if egg.Id == eggId then
			if os.time() < egg.ReadyAt then
				return false, "O ovo ainda está chocando."
			end
			
			-- Verifica se tem habitat disponível
			local hasHabitat = HabitatManager.CanHatchEgg(profile, egg.Element)
			
			if not hasHabitat then
				-- Sem habitat: precisa escolher arquivar ou vender
				if not action then
					-- Retorna sinal especial: precisa escolher
					return false, "NO_HABITAT", {
						element = egg.Element,
						rarity = egg.Rarity,
						shiny = egg.Shiny,
					}
				end
				
				if action == "Archive" then
					-- Choca e arquiva
					table.remove(profile.Eggs, i)
					local d = Dragon.Add(player, Dragon.New(egg.Element, egg.Rarity, egg.Shiny))
					d.Archived = true
					d.HabitatId = nil
					Data.Push(player)
					return true, d
					
				elseif action == "Sell" then
					-- Choca e vende imediatamente
					table.remove(profile.Eggs, i)
					local baseValue = Config.DragonSellValue[egg.Rarity] or 50
					local value = baseValue * (egg.Shiny and 2 or 1)
					profile.Gold += value
					Data.Push(player)
					return true, { sold = true, value = value }
					
				else
					return false, "Ação inválida. Use 'Archive' ou 'Sell'."
				end
			end
			
			-- Tem habitat: choca normalmente
			table.remove(profile.Eggs, i)
			local d = Dragon.Add(player, Dragon.New(egg.Element, egg.Rarity, egg.Shiny))
			
			-- Spawna dragão no mundo
			local ok, DragonSpawner = pcall(require, script.Parent.Parent.Modules.DragonSpawner)
			if ok and DragonSpawner then
				DragonSpawner.SpawnDragon(player, d, profile)
			end
			
			Data.Push(player)
			return true, d
		end
	end
	return false, "Ovo não encontrado."
end

function IncubatorService.Handlers.SkipEgg(player, eggId)
	local profile = Data.Get(player)
	local found
	for _, egg in ipairs(profile.Eggs) do
		if egg.Id == eggId then
			found = egg
		end
	end
	if not found then
		return false, "Ovo não encontrado."
	end

	if Config.SkipProductId == 0 then
		if RunService:IsStudio() then
			found.ReadyAt = os.time() -- só para testes
			Data.Push(player)
			return true
		end
		return false, "Produto de Robux não configurado."
	end

	pendingSkip[player.UserId] = eggId
	MarketplaceService:PromptProductPurchase(player, Config.SkipProductId)
	return true
end

-- Chamado pelo MarketplaceService.ProcessReceipt (ver Main). Retorna true se concedeu.
function IncubatorService.ProcessReceipt(player, receiptInfo)
	local profile = Data.Get(player)
	if not profile then
		return false
	end
	local receiptId = tostring(receiptInfo.PurchaseId)
	if profile.Receipts[receiptId] then
		return true -- já concedido
	end
	if receiptInfo.ProductId ~= Config.SkipProductId then
		return false
	end

	local eggId = pendingSkip[player.UserId]
	pendingSkip[player.UserId] = nil
	for _, egg in ipairs(profile.Eggs) do
		if egg.Id == eggId then
			egg.ReadyAt = os.time()
		end
	end
	profile.Receipts[receiptId] = true
	Data.Push(player)
	return Data.Save(player) -- só confirma a compra se salvou
end

return IncubatorService
