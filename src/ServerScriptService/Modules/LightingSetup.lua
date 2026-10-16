--[[
	LightingSetup - Configura iluminação cinematográfica
]]

local LightingSetup = {}

function LightingSetup.Init()
	local Lighting = game:GetService("Lighting")
	
	local success, err = pcall(function()
		-- Configurações básicas
		Lighting.ClockTime = 14 -- 14h (tarde agradável)
		Lighting.Ambient = Color3.fromRGB(140, 140, 160)
		Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 190)
		Lighting.Brightness = 2.5
		Lighting.ColorShift_Top = Color3.fromRGB(255, 240, 220)
		Lighting.GlobalShadows = true
		-- Lighting.Technology removido (causa erro no Studio)
		
		-- Atmosphere
		local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
		atmosphere.Density = 0.35
		atmosphere.Offset = 0.5
		atmosphere.Color = Color3.fromRGB(220, 230, 255)
		atmosphere.Decay = Color3.fromRGB(140, 160, 180)
		atmosphere.Glare = 0.3
		atmosphere.Haze = 1.5
		atmosphere.Parent = Lighting
		
		-- Sky
		local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky")
		sky.SkyboxBk = "rbxasset://textures/sky/sky512_bk.tex"
		sky.SkyboxDn = "rbxasset://textures/sky/sky512_dn.tex"
		sky.SkyboxFt = "rbxasset://textures/sky/sky512_ft.tex"
		sky.SkyboxLf = "rbxasset://textures/sky/sky512_lf.tex"
		sky.SkyboxRt = "rbxasset://textures/sky/sky512_rt.tex"
		sky.SkyboxUp = "rbxasset://textures/sky/sky512_up.tex"
		sky.Parent = Lighting
		
		-- Bloom
		local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
		bloom.Intensity = 0.4
		bloom.Size = 24
		bloom.Threshold = 0.8
		bloom.Parent = Lighting
		
		-- ColorCorrection
		local colorCorrection = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
		colorCorrection.Saturation = 0.15
		colorCorrection.Contrast = 0.05
		colorCorrection.TintColor = Color3.fromRGB(255, 250, 245)
		colorCorrection.Parent = Lighting
		
		-- SunRays
		local sunRays = Lighting:FindFirstChildOfClass("SunRaysEffect") or Instance.new("SunRaysEffect")
		sunRays.Intensity = 0.08
		sunRays.Spread = 0.4
		sunRays.Parent = Lighting
	end)
	
	if not success then
		warn("[LightingSetup] Erro ao configurar iluminação: " .. tostring(err))
		warn("[LightingSetup] Continuando mesmo assim...")
	end
end

return LightingSetup
