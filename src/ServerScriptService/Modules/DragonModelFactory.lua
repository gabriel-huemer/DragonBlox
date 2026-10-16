--[[
	DragonModelFactory - Cria modelos 3D simples para dragões
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local DragonModelFactory = {}

-- Cores por elemento
local elementColors = {
	Fire = Color3.fromRGB(220, 60, 40),
	Water = Color3.fromRGB(40, 120, 220),
	Earth = Color3.fromRGB(120, 80, 40),
	Wind = Color3.fromRGB(180, 220, 200),
	Electric = Color3.fromRGB(255, 230, 60),
	Ice = Color3.fromRGB(150, 220, 255),
	Nature = Color3.fromRGB(60, 180, 60),
	Dark = Color3.fromRGB(60, 40, 80),
	Light = Color3.fromRGB(255, 240, 180),
	Infernal = Color3.fromRGB(200, 40, 20),
	Cosmico = Color3.fromRGB(120, 60, 200),
}

function DragonModelFactory.Create(dragon)
	local model = Instance.new("Model")
	model.Name = "Dragon_" .. (dragon.Id or "Unknown")

	local color = elementColors[dragon.Element] or Color3.fromRGB(150, 150, 150)
	if dragon.Shiny then
		-- Shiny = dourado brilhante
		color = Color3.fromRGB(255, 215, 0)
	end

	-- Corpo principal
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(4, 3, 6)
	body.Color = color
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = false
	body.CanCollide = true
	body.Parent = model

	-- Cabeça
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2.5, 2.5, 2.5)
	head.Color = color
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = false
	head.CanCollide = true
	head.CFrame = body.CFrame * CFrame.new(0, 2, -3.5)
	head.Parent = model

	-- Weld cabeça no corpo
	local headWeld = Instance.new("WeldConstraint")
	headWeld.Part0 = body
	headWeld.Part1 = head
	headWeld.Parent = head

	-- Olhos
	for _, offset in ipairs({ CFrame.new(-0.6, 0.3, -1.2), CFrame.new(0.6, 0.3, -1.2) }) do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Size = Vector3.new(0.3, 0.3, 0.3)
		eye.Color = dragon.Shiny and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(255, 200, 50)
		eye.Material = Enum.Material.Neon
		eye.Anchored = false
		eye.CanCollide = false
		eye.CFrame = head.CFrame * offset
		eye.Parent = model

		local eyeWeld = Instance.new("WeldConstraint")
		eyeWeld.Part0 = head
		eyeWeld.Part1 = eye
		eyeWeld.Parent = eye
	end

	-- Asas (simples)
	for _, side in ipairs({ -1, 1 }) do
		local wing = Instance.new("Part")
		wing.Name = side == -1 and "WingL" or "WingR"
		wing.Size = Vector3.new(0.3, 1, 4)
		wing.Color = color:lerp(Color3.new(0, 0, 0), 0.2)
		wing.Material = Enum.Material.SmoothPlastic
		wing.Anchored = false
		wing.CanCollide = false
		wing.CFrame = body.CFrame * CFrame.new(side * 2.5, 0.5, 0) * CFrame.Angles(0, 0, side * 0.3)
		wing.Parent = model

		local wingWeld = Instance.new("WeldConstraint")
		wingWeld.Part0 = body
		wingWeld.Part1 = wing
		wingWeld.Parent = wing
	end

	-- Cauda
	local tail = Instance.new("Part")
	tail.Name = "Tail"
	tail.Size = Vector3.new(0.8, 0.8, 3)
	tail.Color = color
	tail.Material = Enum.Material.SmoothPlastic
	tail.Anchored = false
	tail.CanCollide = false
	tail.CFrame = body.CFrame * CFrame.new(0, 0, 3.5)
	tail.Parent = model

	local tailWeld = Instance.new("WeldConstraint")
	tailWeld.Part0 = body
	tailWeld.Part1 = tail
	tailWeld.Parent = tail

	-- Humanoid para movimento
	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.Parent = model

	-- HumanoidRootPart
	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Size = Vector3.new(2, 2, 1)
	hrp.Transparency = 1
	hrp.CanCollide = false
	hrp.Anchored = false
	hrp.CFrame = body.CFrame
	hrp.Parent = model

	local hrpWeld = Instance.new("WeldConstraint")
	hrWeld.Part0 = body
	hrWeld.Part1 = hrp
	hrWeld.Parent = hrp

	model.PrimaryPart = hrp

	return model
end

return DragonModelFactory