--[[
	DebugCommands - Comandos de debug só no Studio
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataService = require(script.Parent.Parent.Services.DataService)

local DebugCommands = {}

function DebugCommands.Init()
	-- Só funciona no Studio
	if not RunService:IsStudio() then
		return
	end
	
	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			local args = string.split(message, " ")
			local cmd = string.lower(args[1])
			
			if cmd == "/reset" or cmd == "/resetdata" then
				-- Reseta dados do jogador
				local profile = DataService.Get(player)
				if profile then
					-- Limpa tudo
					profile.Gold = 500
					profile.Apples = 100
					profile.Dragons = {}
					profile.Eggs = {}
					profile.Team = {}
					profile.Buildings = { Inventory = {}, Placed = {} }
					profile.FirstTime = true
					profile.FarmLevel = 1
					profile.HabitatSlots = 3
					profile.Stats = { Wins = 0, Heists = 0, EggsStolen = 0 }
					
					DataService.Push(player)
					DataService.Save(player)
					
					print("[DEBUG] Dados resetados para " .. player.Name)
					
					-- Notifica player
					local Remotes = game.ReplicatedStorage:WaitForChild("Remotes")
					Remotes.Notify:FireClient(player, "✅ Dados resetados! Saia e entre novamente.")
				end
			elseif cmd == "/gold" then
				local amount = tonumber(args[2]) or 1000
				local profile = DataService.Get(player)
				if profile then
					profile.Gold += amount
					DataService.Push(player)
					print("[DEBUG] +" .. amount .. " ouro para " .. player.Name)
				end
			elseif cmd == "/apples" then
				local amount = tonumber(args[2]) or 100
				local profile = DataService.Get(player)
				if profile then
					profile.Apples += amount
					DataService.Push(player)
					print("[DEBUG] +" .. amount .. " maçãs para " .. player.Name)
				end
			end
		end)
	end)
	
	print("[DebugCommands] Comandos ativados! Digite /reset no chat")
end

return DebugCommands
