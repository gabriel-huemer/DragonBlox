-- Client (LocalScript)
-- Melhorias: confirmação modal para ações destrutivas e tema visual mais forte.

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

-- Paleta de cores (tema mais dramático)
local C = {
    Bg = Color3.fromRGB(12, 12, 20),
    Panel = Color3.fromRGB(20, 22, 36),
    Row = Color3.fromRGB(34, 38, 60),
    Text = Color3.fromRGB(240, 240, 250),
    Muted = Color3.fromRGB(140, 145, 170),
    Accent = Color3.fromRGB(150, 110, 255),
    Good = Color3.fromRGB(70, 190, 110),
    Bad = Color3.fromRGB(220, 80, 80),
    Gold = Color3.fromRGB(255, 205, 60),
}

-- Estado global
local profile
local currentTab = "Base"
local liveUpdaters = {}
local layoutCounter = 0

local function serverNow()
    return workspace:GetServerTimeNow()
end

local function call(action, ...)
    local ok, res = pcall(Request.InvokeServer, Request, action, ...)
    if not ok or type(res) ~= "table" then
        warn("[Client] Erro ao chamar " .. action .. ": " .. tostring(res))
        return false
    end
    if not res.ok and res.data then
        return false, res.data
    end
    return res.ok, res.data
end

-- UI Helpers (modal confirm)
local function new(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do inst[k] = v end
    inst.Parent = parent
    return inst
end

local function corner(inst, radius)
    new("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, inst)
end

local gui = new("ScreenGui", { Name = "DragonMVP", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, playerGui)

-- Top bar (themed)
local top = new("Frame", { Size = UDim2.new(1, 0, 0, 64), BackgroundColor3 = C.Bg, BorderSizePixel = 0 }, gui)
corner(top, 0)
local title = new("TextLabel", { Text = "DragonBlox", Position = UDim2.new(0, 16, 0, 8), Size = UDim2.new(0, 300, 0, 48), BackgroundTransparency = 1, TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 28 }, top)

local goldLabel = new("TextLabel", { Text = "Ouro: 0", Position = UDim2.new(0, 320, 0, 8), Size = UDim2.new(0, 180, 0, 24), BackgroundTransparency = 1, TextColor3 = C.Gold, Font = Enum.Font.GothamBold, TextSize = 18 }, top)
local applesLabel = new("TextLabel", { Text = "Maçãs: 0", Position = UDim2.new(0, 320, 0, 32), Size = UDim2.new(0, 180, 0, 24), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 120, 120), Font = Enum.Font.GothamBold, TextSize = 16 }, top)

local panel = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0.5, 0, 40), Size = UDim2.new(0.82, 0, 0.78, 0), BackgroundColor3 = C.Panel, BorderSizePixel = 0, Visible = true }, gui)
corner(panel, 12)

local function toast(text, color)
    color = color or C.Row
    local t = new("TextLabel", { Size = UDim2.new(0, 360, 0, 36), Position = UDim2.new(0.5, -180, 0, 20), BackgroundColor3 = color, TextColor3 = C.Text, Font = Enum.Font.GothamMedium, TextSize = 16, Text = text }, gui)
    corner(t, 8)
    task.delay(3.5, function() if t then t:Destroy() end end)
end

-- Simple modal confirm
local function confirm(promptText, yesCallback)
    local overlay = new("Frame", { Size = UDim2.new(1,0,1,0), BackgroundTransparency = 0.6, BackgroundColor3 = Color3.new(0,0,0), Parent = gui })
    local box = new("Frame", { Size = UDim2.new(0, 420, 0, 180), Position = UDim2.new(0.5, -210, 0.5, -90), BackgroundColor3 = C.Panel, Parent = overlay })
    corner(box, 12)
    local lbl = new("TextLabel", { Text = promptText, Size = UDim2.new(1, -32, 1, -70), Position = UDim2.new(0, 16, 0, 16), BackgroundTransparency = 1, TextColor3 = C.Text, Font = Enum.Font.GothamMedium, TextSize = 16, TextWrapped = true }, box)
    local btnYes = new("TextButton", { Text = "Confirmar", Size = UDim2.new(0.45, -8, 0, 44), Position = UDim2.new(0.05, 0, 1, -56), BackgroundColor3 = C.Good, TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 16 }, box)
    local btnNo = new("TextButton", { Text = "Cancelar", Size = UDim2.new(0.45, -8, 0, 44), Position = UDim2.new(0.5, 4, 1, -56), BackgroundColor3 = C.Bad, TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 16 }, box)
    corner(btnYes, 8); corner(btnNo, 8)
    local function close() overlay:Destroy() end
    btnYes.Activated:Connect(function() pcall(yesCallback); close() end)
    btnNo.Activated:Connect(function() close() end)
end

-- Abas laterais e conteúdo (mantive renderers e lógica principal --- apenas adicionei confirmações em ações destrutivas)
local tabsFrame = new("Frame", { Size = UDim2.new(0, 150, 1, -20), Position = UDim2.new(0, 10, 0, 10), BackgroundTransparency = 1 }, panel)
new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, tabsFrame)

local scroll = new("ScrollingFrame", { Position = UDim2.new(0, 170, 0, 10), Size = UDim2.new(1, -180, 1, -20), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 6, AutomaticCanvasSize = Enum.AutomaticSize.Y }, panel)
new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)

local function nextOrder()
    layoutCounter += 1
    return layoutCounter
end

local function label(parent, text, props)
    local p = { Text = text, BackgroundTransparency = 1, TextColor3 = C.Text, Font = Enum.Font.GothamMedium, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true }
    for k,v in pairs(props or {}) do p[k] = v end
    return new("TextLabel", p, parent)
end

local function addRow(titleText, actions, accent, height)
    local r = new("Frame", { Size = UDim2.new(1, -8, 0, height or 64), BackgroundColor3 = C.Row, BorderSizePixel = 0, LayoutOrder = nextOrder() }, scroll)
    corner(r, 8)
    new("Frame", { Size = UDim2.new(0, 6, 1, 0), BackgroundColor3 = accent or C.Accent, BorderSizePixel = 0 }, r)
    local t = label(r, titleText, { Position = UDim2.new(0, 14, 0, 8), Size = UDim2.new(1, -(#actions * 110 + 24), 1, -16), TextSize = 15 })
    for i, a in ipairs(actions) do
        local btn = new("TextButton", { Text = a.text, BackgroundColor3 = a.color or C.Accent, TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 14, Size = UDim2.new(0, 100, 0, 36), Position = UDim2.new(1, -((#actions - i + 1) * 110), 0.5, -18) }, r)
        corner(btn, 8)
        btn.Activated:Connect(a.fn)
    end
    return r, t
end

-- Renderers (simplified copy of existing logic) --- focus on replacing sell/archive calls with confirmations
local renderers = {}

renderers["Base"] = function()
    local p = profile
    local _, goldTitle = addRow("", {{ text = "Coletar", color = C.Good, fn = function() local ok, gained = call("CollectGold") if ok then toast("+" .. gained .. " ouro", C.Gold) end end }}, C.Gold)
    table.insert(liveUpdaters, function() goldTitle.Text = "Ouro acumulado nos habitats: " .. (profile and math.floor(profile.Gold) or 0) end)

    addRow("Fazenda (100 ouro)", {{ text = "Comprar", color = C.Accent, fn = function() local ok, err = call("BuyBuilding", "Farm") if ok then toast("Fazenda comprada!", C.Good) else toast(tostring(err), C.Bad) end end }}, C.Accent)
end

renderers["Dragões"] = function()
    local p = profile
    local ids = {}
    for id in pairs(p.Dragons) do table.insert(ids, id) end
    table.sort(ids, function(a,b) return a < b end)

    for _, id in ipairs(ids) do
        local d = p.Dragons[id]
        local isArchived = d.Archived or false
        local text = string.format("%s Lv.%d [%s]", DragonUtil.DisplayName(d), d.Level, d.Rarity)
        local actions = {}
        if not isArchived then
            table.insert(actions, { text = "Alimentar", color = C.Good, fn = function() local ok, err = call("Feed", id) if ok then toast("Subiu de nível!", C.Good) else toast(tostring(err), C.Bad) end end })
            table.insert(actions, { text = "Arquivar", color = C.Row, fn = function() confirm("Arquivar este dragão? Ele ficará guardado (não produzirá ouro).", function() local ok, err = call("ArchiveDragon", id) if ok then toast("Dragão arquivado", C.Muted) else toast(tostring(err), C.Bad) end end) end })
        else
            table.insert(actions, { text = "Desarquivar", color = C.Accent, fn = function() local ok, err = call("UnarchiveDragon", id) if ok then toast("Dragão ativado!", C.Good) else toast(tostring(err), C.Bad) end end })
        end
        table.insert(actions, { text = "Vender", color = C.Bad, fn = function() confirm("Vender este dragão por ouro? Esta ação é irreversível.", function() local ok, value = call("SellDragon", id) if ok then toast("Vendido por " .. value .. " ouro!", C.Gold) else toast(tostring(value), C.Bad) end end) end })
        addRow(text, actions, Config.ElementColors[d.Element], 64)
    end
end

renderers["Incubadora"] = function()
    local p = profile
    if #p.Eggs == 0 then addRow("Incubadora vazia.", {}, C.Muted) return end
    for _, egg in ipairs(p.Eggs) do
        local ready = egg.ReadyAt <= serverNow()
        local actions = {}
        if ready then
            table.insert(actions, { text = "Chocar", color = C.Good, fn = function()
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
                    local msg = string.format("Dragão %s [%s] vai nascer! Você NÃO tem Habitat de %s disponível. Escolha:", DragonUtil.ElementLabel(extra.element), extra.rarity, DragonUtil.ElementLabel(extra.element))
                    -- mostra opções: arquivar / vender
                    addRow(msg, {}, C.Bad, 120)
                    addRow("Arquivar", { { text = "Arquivar", color = C.Accent, fn = function() local ok2, d = call("Hatch", egg.Id, "Archive") if ok2 then toast("Dragão arquivado!", C.Muted); render() end end } }, C.Accent, 60)
                    addRow("Vender", { { text = "Vender", color = C.Gold, fn = function() local ok2, result2 = call("Hatch", egg.Id, "Sell") if ok2 and result2.sold then toast("Dragão vendido por " .. result2.value .. " ouro!", C.Gold); render() end end } }, C.Gold, 60)
                else
                    toast(tostring(result), C.Bad)
                end
            end })
        else
            table.insert(actions, { text = "Acelerar", color = C.Gold, fn = function() call("SkipEgg", egg.Id) end })
        end
        addRow("Ovo: " .. egg.Element .. " - " .. (ready and "Pronto" or ("Choca em " .. DragonUtil.FormatTime(egg.ReadyAt - serverNow()))), actions, Config.ElementColors[egg.Element], 56)
    end
end

-- Aba system
local TAB_NAMES = { "Base", "Construir", "Dragões", "Incubadora", "Batalha", "Expedição" }
local tabButtons = {}
local function render()
    if not profile then return end
    for name, b in pairs(tabButtons) do b.BackgroundColor3 = (name == currentTab) and C.Accent or C.Row end
    for _, c in ipairs(scroll:GetChildren()) do if not c:IsA("UIListLayout") then c:Destroy() end end
    liveUpdaters = {}
    if renderers[currentTab] then renderers[currentTab]() end
end

for i, name in ipairs(TAB_NAMES) do
    tabButtons[name] = new("TextButton", { Text = name, BackgroundColor3 = C.Row, Size = UDim2.new(1, 0, 0, 44), LayoutOrder = i, Font = Enum.Font.GothamBold, TextSize = 16 }, tabsFrame)
    corner(tabButtons[name], 8)
    tabButtons[name].Activated:Connect(function() currentTab = name; render() end)
end

local function updateTop()
    if profile then
        goldLabel.Text = "Ouro: " .. math.floor(profile.Gold)
        applesLabel.Text = "Maçãs: " .. math.floor(profile.Apples)
    end
end

Remotes.ProfileChanged.OnClientEvent:Connect(function(p)
    profile = p
    updateTop()
    render()
end)

Remotes.Notify.OnClientEvent:Connect(function(text)
    toast(text)
end)

-- Initial load
local ok, data = call("GetProfile")
if ok then profile = data; updateTop(); render() end

-- Input
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.M then
        panel.Visible = not panel.Visible
    end
end)
