# Dragon MVP - Documento de Design

## Arquitetura Geral

### Estrutura de Pastas
```
src/
├── ReplicatedStorage/
│   ├── Shared/
│   │   ├── Config.lua (existente - expandir)
│   │   ├── DragonUtil.lua (existente - expandir)
│   │   └── Types.lua (novo - definições de tipos)
│   └── Assets/
│       ├── Models/
│       │   └── DragonModels.lua (factory de dragões)
│       ├── Sounds/
│       │   └── SoundManager.lua
│       └── UI/
│           ├── Components/ (componentes reutilizáveis)
│           └── Themes.lua (design system)
├── ServerScriptService/
│   ├── Main.server.lua (existente - refatorar)
│   ├── Services/
│   │   ├── DataService.lua (existente - migrar ProfileService)
│   │   ├── DragonService.lua (existente)
│   │   ├── EconomyService.lua (existente)
│   │   ├── IncubatorService.lua (existente)
│   │   ├── HeistService.lua (existente)
│   │   ├── BattleService.lua (existente)
│   │   ├── PlotService.lua (novo)
│   │   ├── BuildingService.lua (novo)
│   │   └── TutorialService.lua (novo)
│   └── Modules/
│       ├── TerrainGenerator.lua (novo)
│       ├── DragonAI.lua (novo)
│       └── BattleEngine.lua (novo)
├── StarterPlayer/
│   └── StarterPlayerScripts/
│       ├── Client.client.lua (reescrever)
│       ├── Controllers/
│       │   ├── PlotController.lua (novo)
│       │   ├── BuildController.lua (novo)
│       │   ├── CameraController.lua (novo)
│       │   ├── UIController.lua (novo)
│       │   └── HeistController.lua (novo)
│       └── Modules/
│           ├── InputManager.lua (novo)
│           └── EffectManager.lua (novo)
└── Workspace/
    ├── Plots/ (gerado dinamicamente)
    ├── Lobby/ (área inicial, opcional)
    └── HeistMap/ (gerado ou pré-construído)
```

## ETAPA 1: Sistema de Plot e Terreno

### 1.1 PlotService (Servidor)
**Responsabilidades:**
- Atribuir plot ao jogador ao entrar
- Gerenciar grid de plots disponíveis
- Persistir ID do plot do jogador
- Teleportar jogador para seu plot

**Dados do Plot:**
```lua
{
    PlotId = number,
    OwnerId = UserId,
    Position = Vector3,
    Size = Vector2, -- largura x profundidade
    Created = timestamp
}
```

**Algoritmo de Atribuição:**
1. Verificar se jogador já tem plot (dados persistidos)
2. Se não, procurar plot vazio mais próximo da origem
3. Se não há plots vazios, expandir grid
4. Salvar PlotId no perfil do jogador
5. Teleportar jogador para centro do plot

### 1.2 TerrainGenerator (Servidor)
**Responsabilidades:**
- Gerar terreno procedural usando Workspace.Terrain
- Criar decorações (árvores, pedras, flores)
- Definir área de construção (grid)

**Parâmetros de Geração (Config):**
```lua
Config.Plot = {
    Size = Vector2.new(100, 100),
    GridSize = 4, -- cada célula = 4x4 studs
    TerrainLayers = {
        { Material = Enum.Material.Grass, Height = 2 },
        { Material = Enum.Material.Ground, Height = 4 },
        { Material = Enum.Material.Rock, Height = 8 },
    },
    WaterLevel = -2,
    DecorationDensity = 0.3,
    ElevationNoise = {
        Frequency = 0.05,
        Amplitude = 5,
    }
}
```

**Algoritmo de Geração:**
1. Limpar área do plot
2. Gerar terreno base com ruído Perlin (elevação)
3. Aplicar materiais por altura
4. Adicionar água ao redor (oceano ou fosso)
5. Plantar decorações aleatórias (árvores, pedras)
   - Usar sementes baseadas no PlotId (determinístico)
   - Evitar área de construção central
6. Criar marcadores invisíveis do grid
7. Criar SpawnLocation

**Decorações:**
- Árvores: Models simples (tronco + copa esférica)
- Pedras: Parts com Material.Rock, variação de tamanho
- Flores: Small parts com cores vibrantes
- Caminhos: Terrain.Material.Pavement ou Sand

### 1.3 Lighting & Atmosphere (Servidor)
**Configuração Inicial:**
```lua
local Lighting = game:GetService("Lighting")
Lighting.ClockTime = 14 -- 14h (tarde)
Lighting.Ambient = Color3.fromRGB(140, 140, 160)
Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 190)
Lighting.Brightness = 2.5
Lighting.ColorShift_Top = Color3.fromRGB(255, 240, 220)

-- Atmosphere
local atmosphere = Instance.new("Atmosphere")
atmosphere.Density = 0.35
atmosphere.Offset = 0.5
atmosphere.Color = Color3.fromRGB(220, 230, 255)
atmosphere.Decay = Color3.fromRGB(140, 160, 180)
atmosphere.Glare = 0.3
atmosphere.Haze = 1.5
atmosphere.Parent = Lighting

-- Sky
local sky = Instance.new("Sky")
sky.SkyboxBk = "rbxasset://textures/sky/sky512_bk.tex"
sky.SkyboxDn = "rbxasset://textures/sky/sky512_dn.tex"
sky.SkyboxFt = "rbxasset://textures/sky/sky512_ft.tex"
sky.SkyboxLf = "rbxasset://textures/sky/sky512_lf.tex"
sky.SkyboxRt = "rbxasset://textures/sky/sky512_rt.tex"
sky.SkyboxUp = "rbxasset://textures/sky/sky512_up.tex"
sky.Parent = Lighting

-- Effects
local bloom = Instance.new("BloomEffect")
bloom.Intensity = 0.5
bloom.Size = 24
bloom.Threshold = 0.8
bloom.Parent = Lighting

local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Saturation = 0.15
colorCorrection.Contrast = 0.05
colorCorrection.TintColor = Color3.fromRGB(255, 250, 245)
colorCorrection.Parent = Lighting

local sunRays = Instance.new("SunRaysEffect")
sunRays.Intensity = 0.08
sunRays.Spread = 0.4
sunRays.Parent = Lighting
```

### 1.4 PlotController (Cliente)
**Responsabilidades:**
- Receber dados do plot
- Renderizar grid visual (opcional)
- Gerenciar câmera inicial
- Detectar limites do plot

## ETAPA 2: Sistema de Construção

### 2.1 Tipos de Construção
```lua
-- Em Config.lua
Config.Buildings = {
    Farm = {
        Name = "Fazenda",
        Cost = 100,
        Size = Vector3.new(12, 1, 12),
        MaxLevel = 10,
        Model = "FarmModel", -- nome do modelo
    },
    Incubator = {
        Name = "Incubadora",
        Cost = 200,
        Size = Vector3.new(8, 6, 8),
        Model = "IncubatorModel",
    },
    Habitat = {
        Name = "Habitat",
        BaseCost = 150,
        Size = Vector3.new(16, 1, 16),
        VariantsByElement = true, -- 10 modelos
    },
    Decoration = {
        -- Vários tipos com nomes, custos e modelos
    }
}

-- Estrutura de uma construção colocada
{
    BuildingId = "uuid",
    Type = "Farm" | "Habitat" | "Incubator" | "Decoration",
    Element = "Fogo", -- só para Habitats
    Position = Vector3,
    Rotation = CFrame,
    Level = number, -- só para Farm
    PlacedAt = timestamp
}
```

### 2.2 BuildingService (Servidor)
**Handlers:**
- `BuyBuilding(player, buildingType, element)` → ok, buildingData
- `PlaceBuilding(player, buildingId, position, rotation)` → ok
- `MoveBuilding(player, buildingId, position, rotation)` → ok
- `StoreBuilding(player, buildingId)` → ok (remove do mundo)
- `UpgradeBuilding(player, buildingId)` → ok (só Farm)

**Validações:**
- Custo suficiente
- Dentro dos limites do plot
- Sem colisão com outras construções (check de bounds)
- Player é dono do plot
- Building existe no inventário (antes de place)

**Persistência:**
```lua
-- Adicionar ao perfil
Profile.Buildings = {
    Placed = { [buildingId] = buildingData },
    Inventory = { [buildingId] = buildingData }
}
```

**Instanciação Física:**
- Clonar modelo do ReplicatedStorage.Assets.Models
- SetPrimaryPartCFrame
- Parent para pasta do plot
- Tag com BuildingId e OwnerId (CollectionService)

### 2.3 BuildController (Cliente)
**Responsabilidades:**
- Gerenciar UI de inventário de construções
- Modo construir:
  - Criar preview "fantasma" (Model clonado, transparente)
  - Seguir mouse/toque (Raycast para Y do terreno)
  - Snap para grid
  - Validar posição (bounds, colisão)
  - Mudar cor: verde OK, vermelho ERRO
  - Rotação: tecla R ou botão UI (incremento de 90°)
  - Confirmar: clique/toque → chama servidor
  - Cancelar: ESC ou botão UI
- Modo editar:
  - Clicar em construção existente
  - Opções: mover, guardar
  - Mover = entra em modo construir com preview

**Validação Visual (cliente, redundante com servidor):**
- Raycast down para terreno
- Bounds check contra limites do plot
- Spatial check contra outras construções (via Region3 ou partes)

**Input Mobile:**
- Botões UI para rotação e confirmação
- Drag para posicionar
- Pinch/botões para câmera

### 2.4 Modelos de Construção
**FarmModel:**
- Estrutura de madeira simples
- Canteiros visíveis (Parts ou Decals)
- Escala por nível (+ canteiros, + detalhes)

**IncubatorModel:**
- Base de pedra
- "Ninho" ou pedestal
- Brilho sutil (PointLight)

**HabitatModel:**
- 10 variantes (uma por elemento)
- Cerca ou delimitador
- Decoração temática (tocha para Fogo, folhas para Folha, etc.)
- Área interna para dragão passear

**DecorationModels:**
- Pedras decorativas
- Árvores extras
- Fontes
- Estátuas de dragões

## ETAPA 3: Dragões Visíveis

### 3.1 DragonModelFactory (ReplicatedStorage)
**Módulo:**
```lua
local DragonModelFactory = {}

function DragonModelFactory.Create(dragonData)
    -- dragonData: { Element, Rarity, Shiny, Level }
    local model = Instance.new("Model")
    model.Name = "Dragon_" .. dragonData.Element
    
    -- Criar partes: corpo, cabeça, pescoço, asas, cauda, chifres
    local body = CreateBody(dragonData.Element)
    local head = CreateHead(dragonData.Element)
    -- ... etc
    
    -- Animações: usar AnimationController
    local animController = Instance.new("AnimationController")
    animController.Parent = model
    local animator = Instance.new("Animator")
    animator.Parent = animController
    
    -- Carregar animações (idle, walk, attack)
    -- ...
    
    -- Efeitos elementais
    AddElementalEffects(model, dragonData.Element)
    
    -- Aura Shiny
    if dragonData.Shiny then
        AddShinyAura(model)
    end
    
    model.PrimaryPart = body
    return model
end

return DragonModelFactory
```

**Elementos Visuais por Elemento:**
- **Fogo**: Vermelho/laranja, ParticleEmitter de chamas nas asas
- **Terra**: Marrom/verde, textura rochosa
- **Água**: Azul, ParticleEmitter de gotas
- **Raio**: Amarelo, SparkleEffect + ParticleEmitter de raios
- **Folha**: Verde, folhas como ParticleEmitter
- **Vento**: Branco/azul claro, trilha de fumaça
- **Sombra**: Roxo escuro, aura sombria
- **Neon**: Rosa/magenta, brilho neon (SurfaceLight)
- **Infernal**: Vermelho escuro + chamas negras
- **Cósmico**: Roxo/azul + estrelas/galáxia

**Tamanhos por Raridade:**
- Comum: 1.0x
- Raro: 1.15x
- Épico: 1.3x
- Lendário: 1.5x
- Mítico: 1.8x

**Shiny:**
- Aura brilhante (SurfaceLight + ParticleEmitter)
- Cor mais saturada
- Estrelas/sparkles ao redor

### 3.2 Dragões nos Habitats (Servidor)
**Sistema:**
- Ao inicializar plot, instanciar dragões dos habitats
- DragonService mantém tabela: `DragonInstances[dragonId] = modelInstance`
- NPCs andam aleatoriamente dentro do habitat (PathfindingService ou SimplePath)
- A cada X segundos (baseado em GoldPerSecond), spawnar moeda física

**Moeda Física:**
- Part esférica dourada
- Brilho (PointLight)
- ParticleEmitter de sparkles
- ClickDetector (servidor) ou ProximityPrompt
- Ao coletar: fly tween para HUD + som + increment gold
- Despawnar após 60s se não coletada

**IA Simples de Passeio:**
```lua
-- Loop por dragão
while true do
    local randomPoint = GetRandomPointInHabitat(habitat)
    MoveDragonTo(dragon, randomPoint)
    wait(math.random(3, 8))
end
```

### 3.3 Painel de Dragão (Cliente)
**UI:**
- Abrir ao clicar no dragão (client → server → valida propriedade → envia dados)
- Informações:
  - Nome, elemento, raridade, shiny
  - Nível e barra de XP
  - Status (HP, Poder, Res, Agi)
  - Ouro/seg
- Botão "Alimentar" (custo em maçãs)
- Animação ao alimentar:
  - Maçã voa da UI para dragão
  - Partículas douradas
  - Dragão brilha
  - Level up visual

### 3.4 Fazenda Visual
**Estados:**
- Vazia: apenas canteiros de terra
- Crescendo: pequenas plantas (scale up ao longo do tempo)
- Pronta: maçãs grandes visíveis (Parts ou Decals)

**Colheita:**
- Clicar em maçã (ClickDetector ou ProximityPrompt)
- Animação: maçã desaparece + partículas + som
- Incrementa apples no perfil

**Upgrade Visual:**
- Mais canteiros
- Plantas maiores
- Mais decoração (espantalho, ferramentas)

### 3.5 Incubadora Visual
**Estados:**
- Vazia: pedestal vazio
- Com ovo: ovo 3D no pedestal
  - Cor por elemento
  - Rotação lenta
  - Brilho (PointLight)
  - Timer 3D (SurfaceGui com texto)
- Rachando: textura de rachadura + shake
- Nascimento:
  - Explosão de partículas
  - Ovo desaparece (tween scale 0)
  - Dragão aparece (tween scale 0→1)
  - Som dramático

## ETAPA 4: Interface Profissional

### 4.1 Design System (Themes.lua)
```lua
local Themes = {
    Colors = {
        Background = Color3.fromRGB(25, 28, 40),
        Panel = Color3.fromRGB(35, 38, 55),
        Card = Color3.fromRGB(45, 50, 70),
        Accent = Color3.fromRGB(110, 90, 255),
        Success = Color3.fromRGB(70, 200, 120),
        Warning = Color3.fromRGB(255, 200, 60),
        Error = Color3.fromRGB(230, 80, 80),
        Text = Color3.fromRGB(245, 245, 255),
        TextMuted = Color3.fromRGB(150, 155, 170),
        Gold = Color3.fromRGB(255, 205, 60),
        Apple = Color3.fromRGB(255, 100, 100),
    },
    
    Fonts = {
        Title = Enum.Font.GothamBold,
        Body = Enum.Font.GothamMedium,
        Button = Enum.Font.GothamBold,
    },
    
    Sizes = {
        CornerRadius = 12,
        Padding = 8,
        ButtonHeight = 48,
        IconSize = 32,
    },
    
    Animations = {
        Duration = 0.3,
        EasingStyle = Enum.EasingStyle.Quad,
        EasingDirection = Enum.EasingDirection.Out,
    }
}

function Themes.ApplyCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or Themes.Sizes.CornerRadius)
    corner.Parent = instance
end

function Themes.ApplyPadding(instance, all)
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, all or Themes.Sizes.Padding)
    padding.PaddingBottom = UDim.new(0, all or Themes.Sizes.Padding)
    padding.PaddingLeft = UDim.new(0, all or Themes.Sizes.Padding)
    padding.PaddingRight = UDim.new(0, all or Themes.Sizes.Padding)
    padding.Parent = instance
end

return Themes
```

### 4.2 Componentes Reutilizáveis
**Button Component:**
```lua
function Components.Button(props)
    -- props: text, onClick, color, icon, size, disabled
    local button = Instance.new("TextButton")
    button.Text = props.text
    button.BackgroundColor3 = props.color or Themes.Colors.Accent
    -- ...
    
    -- Hover animation
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {
            Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset, 
                             button.Size.Y.Scale, button.Size.Y.Offset + 4)
        }):Play()
    end)
    
    -- Click animation
    button.MouseButton1Down:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1), {
            Size = UDim2.new(...) -- ligeiramente menor
        }):Play()
    end)
    
    return button
end
```

**Card Component:**
- Background = Themes.Colors.Card
- Corner arredondado
- Padding interno
- Sombra (Frame com Transparency gradient)

**ProgressBar Component:**
- Barra de fundo
- Barra de preenchimento (animada)
- Texto opcional

**Toast Component:**
- Auto-destroy após 3s
- Animação de entrada (slide + fade)
- Animação de saída (fade)
- Fila gerenciada

### 4.3 SoundManager
```lua
local SoundManager = {}

local sounds = {
    Click = "rbxassetid://...",
    Purchase = "rbxassetid://...",
    Coin = "rbxassetid://...",
    Hatch = "rbxassetid://...",
    LevelUp = "rbxassetid://...",
    Error = "rbxassetid://...",
    Victory = "rbxassetid://...",
    Defeat = "rbxassetid://...",
}

function SoundManager.Play(soundName, volume)
    local soundId = sounds[soundName]
    if not soundId then return end
    
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume or 0.5
    sound.Parent = game.Workspace
    sound:Play()
    
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

return SoundManager
```

### 4.4 Tutorial System
**TutorialService (Servidor):**
- Detectar primeiro login (Profile.TutorialCompleted = false)
- Dar ovo inicial grátis
- Enviar eventos ao cliente passo a passo

**TutorialController (Cliente):**
- Receber eventos do servidor
- Mostrar highlight/arrow em elementos específicos
- Bloquear interação com outros elementos
- Avançar ao completar cada passo:
  1. "Bem-vindo! Você ganhou um ovo. Abra o menu (M)"
  2. "Vá para Incubadora e choque seu ovo"
  3. "Enquanto espera, vá para Base e compre um Habitat"
  4. "Coloque o Habitat no seu terreno"
  5. "Volte e choque o ovo (ou acelere grátis no Studio)"
  6. "Coloque seu dragão no Habitat"
  7. "Compre uma Fazenda e coloque-a"
  8. "Colete ouro e maçãs. Tutorial completo!"

## ETAPA 5: Expedição "Roube um Ovo"

### 5.1 Mapa da Expedição
**Opções de Implementação:**
1. **Pré-construído:** Construir manualmente no Studio, adicionar ninhos/spawns
2. **Procedural:** Gerar com TerrainGenerator expandido

**Elementos do Mapa:**
- Tamanho: 1000x1000 studs
- Biomas variados (floresta, montanha, caverna, ruínas)
- Ninhos: 10-15, distribuídos, cada um com tier aleatório
- Zona de extração: área verde brilhante, fácil de ver
- Spawns de jogadores: aleatórios, longe da zona

**Ninhos:**
```lua
-- Part grande, esférica ou oval
local nest = Instance.new("Part")
nest.Size = Vector3.new(8, 4, 8)
nest.BrickColor = BrickColor.new("Brown")
nest.Material = Enum.Material.Wood
nest.Anchored = true

-- ProximityPrompt
local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Roubar Ovo"
prompt.HoldDuration = 2
prompt.Parent = nest

-- Brilho
local light = Instance.new("PointLight")
light.Brightness = 2
light.Range = 30
light.Color = Color3.fromRGB(255, 220, 100)
light.Parent = nest

-- Partículas
-- ...
```

### 5.2 HeistService (Servidor)
**Estados:**
```lua
HeistStates = {
    [player] = {
        State = "Exploring" | "Carrying" | "Extracting" | "Dead",
        CarriedEgg = eggData | nil,
        CompanionDragon = modelInstance,
        ExtractProgress = 0,
        LastNestUse = {},
    }
}
```

**Handlers:**
- `EnterHeist(player)` → teleporta, spawna companion
- `StealEgg(player, nestId)` → valida cooldown, gera ovo, aplica lentidão
- `DropEgg(player)` → cria DroppedEgg no chão
- `PickupDroppedEgg(player, droppedEggId)` → outro jogador pega
- `ExtractEgg(player)` → valida zona, inicia contador
- `LeaveHeist(player)` → remove da expedição

**Mecânica de Roubo:**
1. Player usa ProximityPrompt no ninho
2. Servidor valida cooldown (Config.Heist.NestCooldown)
3. Gera ovo (tier aleatório, weighted)
4. Atribui ao player (`CarriedEgg`)
5. Aplica lentidão (Character.Humanoid.WalkSpeed = tier.WalkSpeed)
6. Envia evento ao cliente (mostrar HUD, modelo do ovo)

**Mecânica de Extração:**
1. Player entra na zona verde (Region3 ou Part.Touched)
2. Servidor inicia contador
3. A cada 0.5s, valida se ainda está na zona
4. Se sair, reseta contador
5. Ao completar, extrai ovo:
   - Remove `CarriedEgg`
   - Adiciona ovo à incubadora do player
   - Restaura velocidade
   - Incrementa Stats.Heists
   - Envia notificação

**Mecânica de Morte:**
1. Player morre (Humanoid.Died)
2. Se carregava ovo, droppa no chão (Part física)
3. Outro player pode pegar (ProximityPrompt)
4. DroppedEgg despawna após 2 minutos

### 5.3 DragonAI (Servidor)
**IA de Dragão Selvagem:**
```lua
-- Estados: Idle, Patrol, Chase, Attack, Flee
local AI = {
    State = "Patrol",
    Target = nil,
    PatrolPoints = {},
    Health = maxHP,
    LastAttack = 0,
}

-- Loop principal
while true do
    if AI.State == "Patrol" then
        -- Caminhar para próximo patrol point
        -- Detectar jogadores em AggroRange
        local nearbyPlayers = GetPlayersInRange(AI.Position, Config.Heist.Wild.Small.AggroRange)
        if #nearbyPlayers > 0 then
            AI.Target = nearbyPlayers[1]
            AI.State = "Chase"
        end
    elseif AI.State == "Chase" then
        -- Seguir target
        if DistanceTo(AI.Target) <= Config.Heist.Wild.Small.AttackRange then
            AI.State = "Attack"
        elseif DistanceTo(AI.Target) > AggroRange * 1.5 then
            AI.Target = nil
            AI.State = "Patrol"
        end
    elseif AI.State == "Attack" then
        -- Atacar target a cada Cooldown
        if os.clock() - AI.LastAttack >= Cooldown then
            DealDamage(AI.Target, Damage)
            PlayAttackAnimation()
            AI.LastAttack = os.clock()
        end
        -- Se target fugiu
        if DistanceTo(AI.Target) > AttackRange * 1.2 then
            AI.State = "Chase"
        end
    elseif AI.State == "Flee" then
        -- HP baixo, fugir
        -- Retornar a Patrol após distância segura
    end
    
    task.wait(0.5)
end
```

**IA de Companheiro:**
- Segue o jogador (PathfindingService)
- Detecta inimigos próximos
- Ataca automaticamente (similar a selvagem, mas aliado)
- Não morre, mas pode ficar "atordoado" temporariamente

### 5.4 HeistController (Cliente)
**Responsabilidades:**
- Receber eventos do servidor
- Mostrar HUD de extração (barra de progresso)
- Mostrar modelo do ovo carregado (attach ao personagem)
- Indicador de direção para zona de extração (arrow UI)
- Som ambiente da expedição

## ETAPA 6: Batalha Visual

### 6.1 BattleArena (Workspace)
**Estrutura:**
- Área 50x50 com terreno temático (pedras, lava, etc.)
- Iluminação dramática (spot lights, fog)
- Posições fixas para dragões (3 de cada lado)
- Câmera com CFrame fixa ou scripted

### 6.2 BattleEngine (Servidor)
**Expandir lógica existente:**
- Ao iniciar batalha, clonar arena para o player (ou usar arena compartilhada)
- Instanciar modelos 3D dos dragões de ambos os lados
- Sincronizar ações com animações:
  - Ataque físico: animação de bite/claw
  - Ataque elemental: animação + partículas
  - Defesa: pose defensiva
  - Switch: dragão sai (fade), novo entra (fade in)

**Eventos para Cliente:**
```lua
BattleEvent:FireClient(player, {
    Type = "Action",
    Attacker = dragonIndex,
    Defender = dragonIndex,
    ActionType = "Physical" | "Elemental" | "Defend",
    Damage = number,
    IsCrit = bool,
    Missed = bool,
})
```

### 6.3 BattleVisualizer (Cliente)
**Responsabilidades:**
- Receber eventos de ação
- Tocar animações nos modelos correspondentes
- Criar efeitos visuais:
  - Números de dano flutuando (BillboardGui)
  - Partículas de impacto
  - Screen shake em golpes críticos
  - Flash branco em hits
- Animar barras de HP (tween smooth)
- Câmera:
  - Zoom no atacante
  - Segue ação
  - Retorna para visão geral

## Migrações e Refatorações

### Migrar DataService para ProfileService
**Instalar ProfileService:**
- Download do modelo da biblioteca Roblox
- Colocar em ServerScriptService ou ReplicatedStorage.Packages

**Refatorar DataService:**
```lua
local ProfileService = require(...)
local ProfileStore = ProfileService.GetProfileStore("DragonMVP_v1", newProfile())

function DataService.LoadProfile(player)
    local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
    if profile then
        profile:AddUserId(player.UserId)
        profile:Reconcile()
        
        profile:ListenToRelease(function()
            profiles[player] = nil
            player:Kick("Sessão perdida.")
        end)
        
        if player:IsDescendantOf(Players) then
            profiles[player] = profile
            DataService.Push(player)
        else
            profile:Release()
        end
    else
        player:Kick("Falha ao carregar dados.")
    end
end
```

### Refatorar Client.client.lua
**Separar em Controllers:**
- **UIController:** gerenciar painéis, HUD, toasts
- **PlotController:** lógica de plot/câmera
- **BuildController:** modo construir
- **HeistController:** lógica de expedição
- **BattleController:** lógica de batalha

**Client.client.lua se torna apenas inicializador:**
```lua
local Controllers = script.Controllers
local UIController = require(Controllers.UIController)
local PlotController = require(Controllers.PlotController)
-- ...

UIController.Init()
PlotController.Init()
-- ...
```

## Performance e Otimizações

### Streaming Enabled
- Ativar StreamingEnabled para mapas grandes (expedição)
- RequestStreamAroundAsync para jogadores na expedição
- Persistent models para construções do plot

### LOD (Level of Detail)
- Dragões distantes: modelos simplificados
- Decorações distantes: menor detail
- Partículas desativadas quando longe

### Pooling
- Moedas físicas: pool de parts reutilizadas
- Efeitos visuais: pool de ParticleEmitters
- Projéteis (batalha): pool

### Rate Limiting
- Já existe em Main.server.lua (0.1s por chamada)
- Adicionar rate limit específico para ações caras (breed, batalha)

## Testes e Debug

### Modo DEBUG (Config.lua)
```lua
Config.Debug = {
    Enabled = RunService:IsStudio(),
    Commands = {
        GiveGold = 1000,
        GiveApples = 1000,
        InstantHatch = true,
        GodMode = true,
    }
}
```

**Implementar comandos:**
- `/givegold [amount]` → adiciona ouro
- `/giveapples [amount]` → adiciona maçãs
- `/giveegg [element] [rarity] [shiny]` → cria ovo específico
- `/levelup [dragonId]` → sobe nível
- `/clearplot` → remove todas construções
- `/resetplot` → regenera terreno

**Debug UI:**
- Painel toggle-able (F3)
- Mostra FPS, ping, memory
- Logs de eventos (batalha, expedição)

## Cronograma Sugerido

### Etapa 1 (Base 3D): ~2-3 dias
- PlotService + TerrainGenerator
- Lighting setup
- PlotController
- Testes: spawn correto, terreno bonito

### Etapa 2 (Construção): ~3-4 dias
- BuildingService
- BuildController
- Modelos de construções (simples)
- Testes: buy, place, move, persist

### Etapa 3 (Dragões Visíveis): ~4-5 dias
- DragonModelFactory (maior parte do tempo)
- Dragões nos habitats
- Fazenda e Incubadora visuais
- Testes: dragão aparece, moedas, level up, nascimento

### Etapa 4 (Interface): ~3-4 dias
- Themes e componentes
- Refatorar UI existente
- SoundManager
- Tutorial
- Testes: responsividade, animações, tutorial completo

### Etapa 5 (Expedição): ~4-5 dias
- Mapa da expedição
- DragonAI
- HeistController visual
- Testes: roubar, carregar, extrair, PvP

### Etapa 6 (Batalha Visual): ~2-3 dias
- BattleArena
- BattleVisualizer
- Animações e câmera
- Testes: batalha completa com visuais

**Total estimado: 18-24 dias**

## Riscos e Mitigações

**Risco:** Modelos de dragão complexos demais → performance ruim
**Mitigação:** Usar modelos simples, LOD agressivo, limitar partículas

**Risco:** Geração procedural de terreno lenta
**Mitigação:** Gerar assincronamente (yield), cachear, ou pré-gerar plots

**Risco:** Colisão de construções complexa
**Mitigação:** Usar bounds simples (box check), grid discreto

**Risco:** IA de dragões selvagens causa lag
**Mitigação:** Limitar quantidade, dormir AI quando sem jogadores por perto

**Risco:** Sincronização de batalha visual com lógica
**Mitigação:** Enviar eventos detalhados, cliente confia no servidor

## Próximos Passos
Após aprovação deste design, gerar `tasks.md` com tarefas granulares para cada etapa.
