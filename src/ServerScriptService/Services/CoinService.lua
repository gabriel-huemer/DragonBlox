--[[
	CoinService - Detecta coleta de moedas pelos jogadores
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)

local CoinService = {}

function CoinService.Init()
	-- Detecta quando uma moeda é adicionada ao workspace
	workspace.ChildAdded:Connect(function(child)
		if child.Name == "Coin" and child:IsA("BasePart") then
			local owner = child:FindFirstChild("Owner")
			local valueTag = child:FindFirstChild("Value")
			if not owner or not owner:IsA("ObjectValue") or not owner.Value then return end
			if not valueTag or not valueTag:IsA("IntValue") then return end
			
			local player = owner.Value
			local value = valueTag.Value
			
			-- Conexão de toque: se o jogador dono tocar, coleta
			child.Touched:Connect(function(otherPart)
				local character = otherPart.Parent
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if not humanoid then return end
				
				-- Verifica se é o dono
				local touchingPlayer = Players:GetPlayerFromCharacter(character)
				if touchingPlayer ~= player then return end
				
				-- Verifica se a moeda ainda existe
				if not child.Parent then return end
				
				-- Coleta: adiciona ouro e remove moeda
				local profile = Data.Get(player)
				if profile then
					profile.Gold = profile.Gold + value
					Data.Push(player)
				end
				
				child:Destroy()
			end)
		end
	end)
	
	-- Também conecta em moedas que já existem
	for _, child in ipairs(workspace:GetChildren()) do
		if child.Name == "Coin" and child:IsA("BasePart") then
			local owner = child:FindFirstChild("Owner")
			local valueTag = child:FindFirstChild("Value")
			if owner and owner:IsA("ObjectValue") and owner.Value and valueTag and valueTag:IsA("IntValue") then
				local player = owner.Value
				local value = valueTag.Value
				
				child.Touched:Connect(function(otherPart)
					local character = otherPart.Parent
					local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if not humanoid then return end
					
					local touchingPlayer = Players:GetPlayerFromCharacter(character)
					if touchingPlayer ~= player then return end
					
					if not child.Parent then return end
					
					local profile = Data.Get(player)
					if profile then
						profile.Gold = profile.Gold + value
						Data.Push(player)
					end
					
					child:Destroy()
				end)
			end
		end
	end
	
	print("[CoinService] Inicializado")
end

return CoinService