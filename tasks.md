# Dragon MVP - Tasks

## ETAPA 1: Base 3D Bonita e Jogável

### Task 1.1: Criar estrutura base de pastas e tipos
- [ ] Criar pasta `src/ReplicatedStorage/Shared/Types.lua`
- [ ] Definir tipos TypeScript/Luau para Plot, Building, Dragon
- [ ] Criar pasta `src/ServerScriptService/Modules/`
- [ ] Criar pasta `src/StarterPlayer/StarterPlayerScripts/Controllers/`

### Task 1.2: Implementar PlotService
- [ ] Criar `src/ServerScriptService/Services/PlotService.lua`
- [ ] Implementar grid de plots (matriz 2D de posições)
- [ ] Função `AssignPlot(player)` - atribui plot ao jogador
- [ ] Função `GetPlayerPlot(player)` - retorna dados do plot
- [ ] Função `TeleportToPlot(player)` - teleporta para spawn do plot
- [ ] Persistir PlotId no perfil do jogador (DataService)
- [ ] Criar pasta `Workspace.Plots` para organizar plots

### Task 1.3: Implementar TerrainGenerator
- [ ] Criar `src/ServerScriptService/Modules/TerrainGenerator.lua`
- [ ] Adicionar Config.Plot em `Config.lua` com parâmetros de geração
- [ ] Função `GeneratePlotTerrain(plotData)` usando Workspace.Terrain
- [ ] Implementar ruído Perlin para elevação
- [ ] Aplicar materiais por camada (Grass, Ground, Rock)
- [ ] Adicionar água ao redor do plot
- [ ] Função `AddDecorations(plotData)` - árvores, pedras, flores
- [ ] Criar SpawnLocation no centro do plot
- [ ] Garantir geração determinística (seed baseada em PlotId)

### Task 1.4: Configurar Lighting e Atmosphere
- [ ] Criar `src/ServerScriptService/Modules/LightingSetup.lua`
- [ ] Configurar Lighting (ClockTime, Ambient, Brightness, etc.)
- [ ] Adicionar Atmosphere com densidade e cores
- [ ] Adicionar Sky (textura padrão do Roblox ou custom)
- [ ] Adicionar BloomEffect
- [ ] Adicionar ColorCorrectionEffect
- [ ] Adicionar SunRaysEffect
- [ ] Chamar LightingSetup no Main.server.lua

### Task 1.5: Implementar PlotController (Cliente)
- [ ] Criar `src/StarterPlayer/StarterPlayerScripts/Controllers/PlotController.lua`
- [ ] Requisitar plot do servidor ao entrar
- [ ] Armazenar dados do plot localmente
- [ ] Função para verificar se posição está dentro do plot
- [ ] (Opcional) Renderizar grid visual com Parts semi-transparentes

### Task 1.6: Integrar PlotService com Main.server.lua
- [ ] Adicionar PlotService aos requires em Main.server.lua
- [ ] Chamar PlotService.Init() na inicialização
- [ ] Atribuir plot ao jogador em PlayerAdded
- [ ] Gerar terreno do plot se for primeira vez
- [ ] Teleportar jogador para plot após load de perfil

### Task 1.7: Testar Etapa 1
- [ ] Entrar no jogo e verificar spawn em ilha bonita
- [ ] Verificar terreno variado com decorações
- [ ] Verificar iluminação e atmosfera
- [ ] Verificar ausência de erros no Output
- [ ] Verificar múltiplos jogadores recebem plots diferentes
- [ ] Verificar persistência do PlotId ao sair/entrar

---

## ETAPA 2: Sistema de Construção e Inventário

### Task 2.1: Adicionar Config de Buildings
- [ ] Adicionar `Config.Buildings` em `Config.lua`
- [ ] Definir Farm (custo, tamanho, modelo)
- [ ] Definir Incubator (custo, tamanho, modelo)
- [ ] Definir Habitat com 10 variantes elementais
- [ ] Definir Decorations básicas
- [ ] Adicionar estrutura de Buildings no perfil do jogador (Inventory, Placed)

### Task 2.2: Criar modelos de construção básicos
- [ ] Criar pasta `Workspace.BuildingModels` (temporária, movida para RS depois)
- [ ] Criar FarmModel básico (estrutura + canteiros)
- [ ] Criar IncubatorModel básico (pedestal + brilho)
- [ ] Criar 10 HabitatModels (variação por elemento: cores, decoração)
- [ ] Mover modelos para ReplicatedStorage.Assets.Models
- [ ] Garantir cada modelo tem PrimaryPart definida

### Task 2.3: Implementar BuildingService
- [ ] Criar `src/ServerScriptService/Services/BuildingService.lua`
- [ ] Handler `BuyBuilding(player, buildingType, element)` → ok, buildingData
  - Validar custo
  - Deduzir ouro
  - Adicionar ao inventory
- [ ] Handler `PlaceBuilding(player, buildingId, position, rotation)` → ok
  - Validar building existe no inventory
  - Validar posição dentro do plot
  - Validar sem colisão (bounds check)
  - Instanciar modelo físico
  - Mover de Inventory para Placed
- [ ] Handler `MoveBuilding(player, buildingId, position, rotation)` → ok
  - Validar propriedade
  - Validar nova posição
  - Atualizar CFrame do modelo
- [ ] Handler `StoreBuilding(player, buildingId)` → ok
  - Remover modelo físico
  - Mover de Placed para Inventory
- [ ] Handler `UpgradeBuilding(player, buildingId)` → ok (Farm apenas)
  - Validar custo
  - Incrementar nível
  - Atualizar modelo visual
- [ ] Função helper `InstantiateBuilding(buildingData, plotFolder)` - cria modelo físico
- [ ] Função helper `CheckCollision(bounds, plotData, excludeBuildingId)` - valida colisão
- [ ] Função `LoadPlacedBuildings(player)` - instanciar ao entrar

### Task 2.4: Adicionar handlers no Main.server.lua
- [ ] Adicionar BuildingService aos requires
- [ ] Registrar handlers de BuildingService

### Task 2.5: Implementar BuildController (Cliente)
- [ ] Criar `src/StarterPlayer/StarterPlayerScripts/Controllers/BuildController.lua`
- [ ] Estado: `buildMode` (idle, placing, moving)
- [ ] Função `EnterBuildMode(buildingData, isMoving)` - ativa modo construir
  - Clonar modelo como preview (transparente)
  - Conectar a RunService.RenderStepped para seguir mouse
- [ ] Raycast do mouse/toque para terreno (obter posição Y)
- [ ] Snap posição para grid (Config.Plot.GridSize)
- [ ] Validar posição (dentro do plot, sem colisão)
- [ ] Mudar cor do preview: verde OK, vermelho erro
- [ ] Input de rotação (tecla R, +90°)
- [ ] Input de confirmação (clique esquerdo) - chama servidor
- [ ] Input de cancelamento (ESC) - destroi preview
- [ ] Função `ExitBuildMode()` - limpa preview
- [ ] Suporte mobile: botões UI para rotação e confirmação

### Task 2.6: UI de Inventário e Loja
- [ ] Adicionar aba "Loja" no menu principal (Client.client.lua ou UIController)
- [ ] Listar Buildings compráveis com preço
- [ ] Botão "Comprar" chama `BuyBuilding`
- [ ] Adicionar aba "Construir" no menu
- [ ] Listar Buildings no inventory
- [ ] Botão "Colocar" chama `EnterBuildMode`
- [ ] Clicar em building já colocada abre menu: Mover | Guardar
- [ ] "Mover" chama `EnterBuildMode` com isMoving=true
- [ ] "Guardar" chama `StoreBuilding`

### Task 2.7: Refatorar EconomyService para Building
- [ ] Atualizar EconomyService.BuyHabitat para usar BuildingService
- [ ] Atualizar Client para usar nova flow de compra

### Task 2.8: Testar Etapa 2
- [ ] Comprar Farm na loja
- [ ] Farm aparece no inventário
- [ ] Modo construir: preview segue mouse e snapa no grid
- [ ] Preview fica vermelho fora do plot ou com colisão
- [ ] Rotação funciona (R ou botão mobile)
- [ ] Confirmar colocação
- [ ] Building aparece no mundo
- [ ] Mover building para nova posição
- [ ] Guardar building de volta no inventário
- [ ] Sair e entrar: building persiste
- [ ] Testar em emulador mobile: botões funcionam

---

## ETAPA 3: Dragões Visíveis no Mundo

### Task 3.1: Criar DragonModelFactory
- [ ] Criar `src/ReplicatedStorage/Assets/Models/DragonModelFactory.lua`
- [ ] Função `Create(dragonData)` retorna Model
- [ ] Implementar geração procedural básica:
  - Corpo (Part ou MeshPart)
  - Cabeça (Part anexada)
  - Pescoço (Cylinder)
  - Asas (2x Parts)
  - Cauda (Cylinder + Parts)
  - Chifres (2x Small parts)
- [ ] Adicionar AnimationController e Animator
- [ ] Criar animações básicas (idle, walk) ou usar procedural (bobbing)
- [ ] Função `ApplyElementalTheme(model, element)` - cores e materiais
- [ ] Função `AddElementalEffects(model, element)` - partículas por elemento:
  - Fogo: Fire + ParticleEmitter (chamas)
  - Água: ParticleEmitter (gotas)
  - Raio: Sparkles + ParticleEmitter (raios)
  - Folha: ParticleEmitter (folhas)
  - Vento: Smoke/ParticleEmitter (trail)
  - Sombra: SurfaceLight escuro + fumaça
  - Neon: SurfaceLight + cores vibrantes
  - Infernal: Fire escuro + ParticleEmitter
  - Cósmico: ParticleEmitter (estrelas) + galáxia
- [ ] Função `AddShinyAura(model)` - brilho extra, partículas douradas
- [ ] Escalar modelo por raridade (Config.RarityScales)

### Task 3.2: Sistema de Dragões nos Habitats (Servidor)
- [ ] Criar `src/ServerScriptService/Modules/DragonSpawner.lua`
- [ ] Função `SpawnDragonInHabitat(dragon, habitat)` - instancia modelo 3D
  - Usar DragonModelFactory.Create
  - Posicionar dentro do habitat
  - Parent para pasta do plot
  - Tag com dragonId (CollectionService)
- [ ] Manter tabela global `DragonInstances[dragonId] = modelInstance`
- [ ] Função `DespawnDragon(dragonId)` - remove modelo
- [ ] Carregar dragões ao inicializar plot (PlotService)

### Task 3.3: IA de Passeio de Dragões
- [ ] Criar `src/ServerScriptService/Modules/DragonAI.lua`
- [ ] Função `StartPatrol(dragonModel, habitatBounds)` - loop assíncrono
  - Escolher ponto aleatório dentro do habitat
  - Mover dragão (Humanoid ou TweenService)
  - Esperar 3-8 segundos
  - Repetir
- [ ] Iniciar patrol ao spawnar dragão

### Task 3.4: Sistema de Moedas Físicas
- [ ] Criar `src/ServerScriptService/Modules/CoinSpawner.lua`
- [ ] Função `SpawnCoin(position, amount, targetPlayer)` - cria Part dourada
  - PointLight dourada
  - ParticleEmitter sparkles
  - ProximityPrompt ou ClickDetector
  - Tag com targetPlayer (só ele pode coletar)
- [ ] Função `CollectCoin(player, coinPart)` - incrementa ouro, despawna moeda
  - Validar propriedade
  - Tween moeda voando para HUD (cliente)
  - Som de coleta
  - Destruir moeda
- [ ] Loop em DragonService: a cada X segundos (baseado em GoldPerSecond), spawna moeda perto de cada dragão ativo
- [ ] Moedas despawnam após 60s se não coletadas

### Task 3.5: Painel de Dragão (Cliente)
- [ ] Adicionar UI de painel de dragão (modal)
- [ ] Detectar clique em dragão (ClickDetector no modelo)
- [ ] Requisitar dados do dragão ao servidor
- [ ] Mostrar:
  - Nome, elemento (cor), raridade, shiny (ícone)
  - Nível e barra de XP
  - Status (HP, Poder Físico, Elemental, Res, Agi)
  - Ouro/seg
- [ ] Botão "Alimentar" (custo em maçãs)
  - Chama servidor `Feed(dragonId)`
  - Ao sucesso, mostra animação:
    - Maçã voa da UI para dragão (tween)
    - Partículas douradas ao redor do dragão
    - Dragão "brilha" (flash branco)
    - Som de level up
    - Números "+1 Level" flutuando

### Task 3.6: Fazenda Visual
- [ ] Atualizar FarmModel para ter states:
  - Canteiros vazios (Parts marrons)
  - Plantações (small green parts, crescem com TweenService)
  - Maçãs prontas (red spheres)
- [ ] Criar `src/ServerScriptService/Modules/FarmVisualizer.lua`
- [ ] Função `UpdateFarmVisual(farmInstance, farmLevel, applesReady)` - atualiza modelo
  - Mostrar número de canteiros por nível
  - Mostrar maçãs se applesReady > 0
- [ ] Adicionar ClickDetectors ou ProximityPrompts nas maçãs
- [ ] Handler `HarvestApple(player, farmId)` - coleta uma maçã
  - Validar propriedade
  - Incrementar apples
  - Remover visual da maçã
  - Som + partículas
- [ ] Chamar UpdateFarmVisual ao colocar fazenda, fazer upgrade, ou colher

### Task 3.7: Incubadora Visual
- [ ] Atualizar IncubatorModel para ter states:
  - Pedestal vazio
  - Com ovo (Model de ovo)
  - Rachando (textura diferente ou decals)
- [ ] Criar `src/ServerScriptService/Modules/IncubatorVisualizer.lua`
- [ ] Função `UpdateIncubatorVisual(incubatorInstance, eggsData)` - atualiza modelo
  - Se tem ovo: spawnar modelo de ovo no pedestal
  - Cor do ovo por elemento
  - PointLight por elemento
  - Rotação lenta (TweenService loop)
  - SurfaceGui com timer countdown
- [ ] Função `PlayHatchAnimation(incubatorInstance, eggData, dragonData)` - animação de nascimento
  - Shake do ovo
  - Partículas de rachadura
  - Ovo explode (scale → 0, partículas)
  - Dragão aparece (scale 0 → 1)
  - Som dramático
  - Confete ou fogos
- [ ] Chamar UpdateIncubatorVisual a cada 1s (ou via evento de atualização)
- [ ] Chamar PlayHatchAnimation ao clicar em "Chocar"

### Task 3.8: Refatorar DragonService para visual
- [ ] Ao criar dragão (hatch ou breed), spawnar modelo 3D no habitat
- [ ] Ao alimentar dragão, atualizar modelo (escala se mudar raridade? ou apenas efeito)
- [ ] Ao remover dragão do habitat (morte, venda), despawnar modelo

### Task 3.9: Testar Etapa 3
- [ ] Ovo inicial aparece visualmente na incubadora
- [ ] Timer countdown funciona
- [ ] Clicar "Chocar" toca animação de nascimento
- [ ] Dragão aparece no habitat em 3D
- [ ] Dragão passeia dentro do habitat
- [ ] Moedas aparecem perto do dragão
- [ ] Coletar moeda funciona (clique, som, incrementa ouro)
- [ ] Clicar no dragão abre painel com stats
- [ ] Alimentar dragão:
  - Gasta maçãs
  - Mostra animação de level up
  - Stats aumentam
- [ ] Comprar e colocar fazenda
- [ ] Maçãs crescem visualmente
- [ ] Colher maçãs funciona
- [ ] Cruzar dois dragões gera ovo visual na incubadora
- [ ] Tudo persiste ao sair/entrar

---

## ETAPA 4: Interface Profissional

### Task 4.1: Criar Design System (Themes.lua)
- [ ] Criar `src/ReplicatedStorage/Assets/UI/Themes.lua`
- [ ] Definir paleta de cores (Background, Panel, Card, Accent, Success, Error, etc.)
- [ ] Definir fontes (Title, Body, Button)
- [ ] Definir tamanhos (CornerRadius, Padding, ButtonHeight, IconSize)
- [ ] Definir parâmetros de animação (Duration, EasingStyle)
- [ ] Funções helper:
  - `ApplyCorner(instance, radius)`
  - `ApplyPadding(instance, all)`
  - `ApplyShadow(instance)` (frame com gradient de transparência)

### Task 4.2: Criar Componentes Reutilizáveis
- [ ] Criar `src/ReplicatedStorage/Assets/UI/Components.lua`
- [ ] Componente `Button(props)` - botão com hover, clique animado
- [ ] Componente `Card(props)` - painel com corner, padding, sombra
- [ ] Componente `ProgressBar(props)` - barra com preenchimento animado
- [ ] Componente `Toast(text, color, duration)` - notificação auto-destrutiva
- [ ] Componente `Modal(title, content)` - janela modal centralizada
- [ ] Componente `IconButton(icon, onClick)` - botão com ícone (ImageLabel)

### Task 4.3: Adicionar ícones
- [ ] Pesquisar/criar ícones (ou usar text emojis como placeholder):
  - Ouro: 🪙
  - Maçã: 🍎
  - Loja: 🏪
  - Inventário: 🎒
  - Dragões: 🐉
  - Incubadora: 🥚
  - Batalha: ⚔️
  - Expedição: 🗺️
- [ ] Adicionar ImageLabels ou TextLabels com emojis
- [ ] Ou usar Roblox asset IDs de ícones (pesquisar no Toolbox)

### Task 4.4: Refatorar Client.client.lua usando Themes e Components
- [ ] Importar Themes e Components
- [ ] Substituir todas as cores hard-coded por Themes.Colors
- [ ] Substituir criações de botões por Components.Button
- [ ] Adicionar animações de abertura/fechamento de painéis (TweenService)
- [ ] Adicionar hover effects nos botões
- [ ] Substituir toast por Components.Toast
- [ ] Melhorar HUD: adicionar ícones ao lado de Ouro e Maçãs

### Task 4.5: Criar SoundManager
- [ ] Criar `src/ReplicatedStorage/Assets/Sounds/SoundManager.lua`
- [ ] Adicionar IDs de sons (rbxassetid ou placeholders):
  - Click: som de clique
  - Purchase: caixa registradora
  - Coin: moeda tilintando
  - Hatch: casca quebrando + dragão rugindo
  - LevelUp: fanfarra
  - Error: buzzer
  - Victory: música de vitória
  - Defeat: música triste
- [ ] Função `Play(soundName, volume, parent)` - toca som
- [ ] Função `PlayAt(soundName, position, volume)` - toca som em posição 3D
- [ ] Integrar no Client: tocar sons em ações (clique, compra, coleta, etc.)

### Task 4.6: Sistema de Notificações (Toasts)
- [ ] Refatorar toast atual para usar Components.Toast
- [ ] Implementar fila de toasts (max 3 visíveis)
- [ ] Animação de entrada: slide from top + fade in
- [ ] Animação de saída: fade out
- [ ] Cores por tipo: Success (verde), Error (vermelho), Info (azul), Warning (amarelo)

### Task 4.7: Implementar Tutorial System (Servidor)
- [ ] Criar `src/ServerScriptService/Services/TutorialService.lua`
- [ ] Detectar primeiro login (`Profile.TutorialCompleted == nil or false`)
- [ ] Handler `StartTutorial(player)` - inicia sequência
  - Dar ovo grátis
  - Enviar evento ao cliente com step 1
- [ ] Handler `AdvanceTutorial(player, stepId)` - avança para próximo step
  - Validar step atual
  - Verificar conclusão (ex: ovo chocado)
  - Enviar próximo step ao cliente
- [ ] Steps:
  1. "Bem-vindo! Você ganhou um ovo. Abra o menu (M)"
  2. "Vá para Incubadora e veja seu ovo"
  3. "Enquanto espera, compre um Habitat na Loja"
  4. "Coloque o Habitat no seu terreno (aba Construir)"
  5. "Volte e choque seu ovo (acelere grátis no Studio)"
  6. "Seu dragão nasceu! Ele está no Habitat"
  7. "Compre uma Fazenda na Loja"
  8. "Coloque a Fazenda no terreno"
  9. "Colete ouro e maçãs. Tutorial completo!"
- [ ] Ao completar: `Profile.TutorialCompleted = true`

### Task 4.8: Implementar Tutorial System (Cliente)
- [ ] Criar `src/StarterPlayer/StarterPlayerScripts/Controllers/TutorialController.lua`
- [ ] Receber eventos do servidor com tutorial steps
- [ ] Para cada step:
  - Mostrar modal com texto explicativo
  - Highlight elemento específico (Frame amarela pulsante ao redor)
  - Bloquear interação com outros elementos (optional: darkening overlay)
  - Detectar conclusão do step (ex: menu aberto, ovo chocado)
  - Enviar confirmação ao servidor
- [ ] Botão "Pular Tutorial" (opcional)
- [ ] Animação de conclusão (confete, som)

### Task 4.9: Responsividade Mobile
- [ ] Adicionar UIScale ao ScreenGui (scale por screen size)
- [ ] Adicionar UISizeConstraint em botões (MinSize = 48x48)
- [ ] Testar em emulador mobile (várias resoluções)
- [ ] Ajustar tamanhos de texto (mínimo 14)
- [ ] Garantir painéis não ultrapassam tela
- [ ] Adicionar botões touch-friendly para construir (sem precisar de teclado)

### Task 4.10: Testar Etapa 4
- [ ] Interface com identidade visual consistente
- [ ] Ícones visíveis em todos os botões principais
- [ ] Animações suaves ao abrir/fechar painéis
- [ ] Hover effects nos botões (desktop)
- [ ] Sons tocam em ações (clique, compra, coleta, level up)
- [ ] Notificações aparecem e somem corretamente
- [ ] Fila de notificações funciona (max 3)
- [ ] Tutorial inicia automaticamente em primeiro login
- [ ] Tutorial guia pelos passos corretamente
- [ ] Tutorial pode ser pulado
- [ ] Interface funciona bem em mobile (emulador)
- [ ] Botões são tocáveis (tamanho mínimo)
- [ ] Textos legíveis em mobile

---

## ETAPA 5: Mapa da Expedição "Roube um Ovo"

### Task 5.1: Criar Mapa da Expedição
- [ ] Decidir: pré-construir ou procedural?
  - **Recomendação:** Pré-construir no Studio por simplicidade
- [ ] Criar área 1000x1000 no Workspace.HeistMap
- [ ] Usar Terrain para variações:
  - Montanhas (Rock, Snow)
  - Florestas (Grass, árvores)
  - Rios (Water)
  - Cavernas (escavações no terreno)
  - Ruínas (Parts de pedra, colunas)
- [ ] Adicionar iluminação atmosférica (fog, lighting)
- [ ] Criar 10-15 ninhos (Parts grandes, brilhantes)
  - Posicionar manualmente em locais estratégicos
  - Tag com "Nest" e tier (CollectionService)
  - ProximityPrompt "Roubar Ovo" (HoldDuration = 2)
  - PointLight e ParticleEmitter
- [ ] Criar zona de extração (grande área verde)
  - Part verde semi-transparente no chão
  - Brilho (SurfaceLight)
  - ParticleEmitter de sparkles
  - Tag com "ExtractionZone"
- [ ] Criar spawns de jogadores (SpawnLocations ou Parts)
  - Distribuídos ao redor do mapa, longe da zona

### Task 5.2: Expandir HeistService para visual
- [ ] Atualizar `EnterHeist(player)` para:
  - Salvar posição anterior do jogador (para voltar depois)
  - Teleportar para spawn aleatório do HeistMap
  - Spawnar dragão companheiro ao lado
  - Enviar evento "Entered" ao cliente
- [ ] Atualizar `StealEgg(player, nestId)` para:
  - Validar cooldown do ninho
  - Gerar ovo (tier aleatório, weighted)
  - Atribuir `CarriedEgg` ao player state
  - Aplicar lentidão (Humanoid.WalkSpeed)
  - Enviar evento "Carrying" ao cliente com tier
- [ ] Handler `DropEgg(player)` chamado ao morrer ou manualmente
  - Criar Part de ovo no chão (DroppedEggs[uuid])
  - ProximityPrompt "Pegar Ovo"
  - Remover `CarriedEgg` do player state
  - Restaurar velocidade
  - Despawnar após 2 minutos
- [ ] Handler `PickupDroppedEgg(player, droppedEggId)`
  - Validar ovo existe
  - Atribuir ao novo player
  - Aplicar lentidão
  - Despawnar droppedEgg
- [ ] Handler `ExtractEgg(player)` (loop enquanto na zona)
  - Detectar player na ExtractionZone (Region3 ou Touched)
  - Iniciar contador (0 → Config.Heist.ExtractSeconds)
  - A cada 0.5s: validar ainda na zona, incrementar contador
  - Enviar progresso ao cliente ("Extracting", progress 0-1)
  - Se sair da zona: resetar contador
  - Ao completar: adicionar ovo à incubadora, remover CarriedEgg, enviar "Result"
- [ ] Handler `LeaveHeist(player)`
  - Teleportar de volta para plot
  - Despawnar companion
  - Limpar estado
  - Enviar "Left" ao cliente

### Task 5.3: Sistema de Dragões Selvagens (Servidor)
- [ ] Criar `src/ServerScriptService/Modules/WildDragonAI.lua`
- [ ] Função `SpawnWildDragon(type, position)` - cria NPC dragão
  - Usar Humanoid ou custom movement
  - Stats de Config.Heist.Wild
  - Tag com "WildDragon"
  - Modelo visual (usar DragonModelFactory ou placeholder)
- [ ] Função `StartAI(wildDragonInstance)` - loop de IA
  - Estados: Idle, Patrol, Chase, Attack, Flee
  - Detectar jogadores em AggroRange
  - Perseguir target
  - Atacar quando em AttackRange (DealDamage ao Humanoid)
  - Fugir se HP < 20%
  - Respawn após morte (Config.Heist.WildRespawn)
- [ ] Spawnar dragões selvagens ao iniciar HeistMap (10-15 small, 2-3 colossais)
- [ ] Dragões colossais:
  - Voam (BodyPosition + BodyGyro para hover)
  - Ataque à distância (spawnar projétil, raycast)
  - Patrulha em círculos no céu

### Task 5.4: Sistema de Companheiro (Servidor)
- [ ] Criar `src/ServerScriptService/Modules/CompanionAI.lua`
- [ ] Função `SpawnCompanion(player, dragonData)` - cria dragão aliado
  - Usar DragonModelFactory.Create
  - Humanoid com stats do dragão do player
  - Tag com "Companion" e PlayerId
- [ ] Função `StartFollowAI(companion, player)` - loop
  - Usar PathfindingService para seguir player
  - Manter distância de Config.Heist.CompanionRange
  - Detectar inimigos próximos
  - Atacar inimigos automaticamente
  - Não pode morrer (HP regen ou invulnerável)
- [ ] Despawnar companion ao sair da expedição

### Task 5.5: HeistController (Cliente)
- [ ] Criar `src/StarterPlayer/StarterPlayerScripts/Controllers/HeistController.lua`
- [ ] Receber evento "Entered" - preparar UI
- [ ] Receber evento "Carrying" com tier do ovo
  - Mostrar ovo 3D carregado pelo personagem (attach ao Torso)
  - Mostrar label "Carregando Ovo [Tier]"
  - Mostrar indicador de direção para zona de extração (arrow 2D na UI ou 3D)
- [ ] Receber evento "Extracting" com progress
  - Mostrar HUD de barra de progresso
  - Texto "Extraindo... fique na zona!"
- [ ] Receber evento "Left"
  - Esconder HUDs
  - Remover ovo visual
- [ ] Receber evento "Result" - toast com sucesso

### Task 5.6: PvP Básico
- [ ] Permitir jogadores atacarem uns aos outros (Humanoid.Health)
- [ ] Detectar morte enquanto carrega ovo → chamar DropEgg
- [ ] Mostrar nome do atacante em HitMarker ou toast
- [ ] (Opcional) Sistema de combate: equipar arma, atirar, etc.
  - **Recomendação:** Simplicidade - apenas proximity damage

### Task 5.7: Testar Etapa 5
- [ ] Entrar na expedição teleporta para mapa grande
- [ ] Companheiro dragão aparece e segue
- [ ] Ninhos são visíveis e interativos
- [ ] Roubar ovo:
  - Ovo aparece no personagem
  - Player fica lento
  - HUD mostra status
- [ ] Dragões selvagens patrulham
- [ ] Dragões atacam quando jogador se aproxima
- [ ] Companheiro ataca selvagens
- [ ] Dragões colossais voam e atacam à distância
- [ ] Zona de extração claramente marcada
- [ ] Entrar na zona inicia contador de extração
- [ ] Barra de progresso funciona
- [ ] Completar extração adiciona ovo à incubadora
- [ ] Morrer carregando ovo faz ele cair
- [ ] Outro jogador pode pegar ovo caído
- [ ] Sair da expedição volta para plot

---

## ETAPA 6: Batalha Visual

### Task 6.1: Criar Arena de Batalha
- [ ] Criar área BattleArena no Workspace
- [ ] Terreno temático (pedras, lava, gelo, etc.)
- [ ] Iluminação dramática (SpotLights, ColorCorrection)
- [ ] 6 posições fixas (3 de cada lado) marcadas (Parts invisíveis ou CFrames)
- [ ] Câmera fixa ou scripted (Parts com "CameraView" tag)

### Task 6.2: Criar Animações de Dragão
- [ ] Criar ou usar plugin de animação para:
  - Ataque físico (bite, claw swipe)
  - Ataque elemental (breathe, spell cast)
  - Defesa (block, shield)
  - Dano recebido (flinch)
  - Morte (fall, fade)
- [ ] Salvar animações no Roblox ou localmente
- [ ] Carregar em DragonModelFactory

### Task 6.3: Expandir BattleService para visual
- [ ] Ao iniciar batalha:
  - Teleportar player para arena (ou usar câmera remota)
  - Instanciar modelos 3D dos dragões (player e enemy) nas posições
  - Manter tabela `BattleInstances[player] = { PlayerModels, EnemyModels }`
- [ ] Ao executar ação (Physical, Elemental, Defend, Switch):
  - Enviar evento detalhado ao cliente:
    ```lua
    {
      Type = "Action",
      Side = "Player" | "Enemy",
      AttackerIndex = number,
      DefenderIndex = number,
      ActionType = "Physical" | "Elemental" | "Defend" | "Switch",
      Damage = number,
      IsCrit = bool,
      Missed = bool,
      ElementalEffect = string, -- nome do elemento para partículas
    }
    ```
- [ ] Ao terminar batalha: despawnar modelos, teleportar player de volta

### Task 6.4: BattleVisualizer (Cliente)
- [ ] Criar `src/StarterPlayer/StarterPlayerScripts/Controllers/BattleVisualizer.lua`
- [ ] Receber eventos de ação
- [ ] Para cada ação:
  - Identificar modelo do atacante e defensor
  - Tocar animação no atacante
  - Esperar delay (animação)
  - Criar efeitos visuais:
    - Número de dano flutuando (BillboardGui)
    - Partículas de impacto (ParticleEmitter no defensor)
    - Se elemental: partículas específicas do elemento
    - Se crit: screen shake, flash branco
  - Atualizar HP do defensor (animar barra)
  - Se morreu: tocar animação de morte, fade out
- [ ] Função `AnimateDamageNumber(amount, position, isCrit)` - cria BillboardGui que sobe e desaparece
- [ ] Função `ScreenShake(intensity, duration)` - balança câmera
- [ ] Função `FlashScreen(color, duration)` - cria Frame branca que fades

### Task 6.5: Câmera Cinemática
- [ ] Criar `src/StarterPlayer/StarterPlayerScripts/Controllers/BattleCameraController.lua`
- [ ] Ao iniciar batalha: mover câmera para visão geral da arena
- [ ] Durante ação:
  - Zoom no atacante (smooth tween)
  - Pan para defensor ao impacto
  - Retornar para visão geral
- [ ] Usar TweenService para transições suaves
- [ ] (Opcional) Câmera shake em golpes críticos

### Task 6.6: Efeitos Visuais por Elemento
- [ ] Criar `src/ReplicatedStorage/Assets/Effects/ElementalEffects.lua`
- [ ] Para cada elemento, função que spawna efeito:
  - Fogo: ParticleEmitter de chamas, som de fogo
  - Água: ParticleEmitter de água, splash sound
  - Terra: Pedras voando, som de impacto
  - Raio: Beam de raio, som de trovão
  - Folha: Folhas voando, som de vento
  - Vento: Tornado pequeno, whoosh sound
  - Sombra: Fumaça escura, som sinistro
  - Neon: Raios coloridos, zap sound
  - Infernal: Explosão de lava, rugido
  - Cósmico: Estrelas explodindo, som espacial
- [ ] Integrar em BattleVisualizer ao processar ataque elemental

### Task 6.7: Barras de HP 3D
- [ ] Adicionar BillboardGui acima de cada dragão na arena
- [ ] Mostrar nome, nível, barra de HP
- [ ] Animar barra de HP ao receber dano (TweenService)
- [ ] Mudar cor: verde → amarelo → vermelho

### Task 6.8: Refatorar UI de Batalha (Cliente)
- [ ] Manter botões de ação (Physical, Elemental, Defend, Switch)
- [ ] Adicionar feedback visual ao clicar (desabilitar temporariamente)
- [ ] Mostrar log de batalha reduzido (últimas 3-5 ações)
- [ ] (Opcional) Mostrar preview de ações do inimigo (não spoiler, apenas "está atacando")

### Task 6.9: Sons de Batalha
- [ ] Adicionar SFX para:
  - Ataque físico (swoosh, bite)
  - Ataque elemental (por elemento)
  - Defesa (shield)
  - Troca (whoosh)
  - Dano recebido (grunt)
  - Morte (roar)
  - Vitória (fanfarra)
  - Derrota (triste)
- [ ] Tocar sons no BattleVisualizer

### Task 6.10: Testar Etapa 6
- [ ] Iniciar batalha teleporta/move câmera para arena
- [ ] Dragões aparecem em 3D nas posições
- [ ] Clicar "Ataque Físico": animação toca, dano aparece
- [ ] Clicar "Ataque Elemental": efeito visual do elemento, dano aparece
- [ ] Números de dano flutuam e desaparecem
- [ ] Barras de HP animam ao receber dano
- [ ] Golpes críticos: screen shake, flash branco
- [ ] Morte: animação, fade out
- [ ] Câmera enquadra bem as ações
- [ ] Sons tocam em cada ação
- [ ] Vitória/derrota: animação final, mensagem, recompensa

---

## Tarefas Transversais (Todas as Etapas)

### Task X.1: Migrar para ProfileService
- [ ] Baixar ProfileService do Roblox Marketplace
- [ ] Adicionar a ServerScriptService ou ReplicatedStorage.Packages
- [ ] Refatorar DataService.lua para usar ProfileService
  - `ProfileStore:LoadProfileAsync`
  - `profile:Reconcile()`
  - `profile:ListenToRelease()`
  - `profile:Release()` ao sair
- [ ] Testar carga, salvamento, e kick por sessão duplicada

### Task X.2: Modo DEBUG
- [ ] Adicionar `Config.Debug` em Config.lua
- [ ] Criar `src/ServerScriptService/Modules/DebugCommands.lua`
- [ ] Handlers para:
  - `/givegold [amount]`
  - `/giveapples [amount]`
  - `/giveegg [element] [rarity] [shiny]`
  - `/levelup [dragonId] [levels]`
  - `/clearplot`
  - `/resetplot`
- [ ] Conectar comandos ao chat (Chatted event)
- [ ] Validar `RunService:IsStudio()` para segurança

### Task X.3: Performance - Streaming Enabled
- [ ] Ativar Workspace.StreamingEnabled = true
- [ ] Definir Workspace.StreamingTargetRadius e MinRadius
- [ ] Testar mapa de expedição com streaming
- [ ] Ajustar PersistentLoaded para construções do plot

### Task X.4: Performance - LOD
- [ ] Implementar LOD para dragões:
  - Distância < 100: modelo completo
  - Distância 100-200: modelo simplificado (menos parts)
  - Distância > 200: invisível ou billboard
- [ ] Desativar partículas em modelos distantes
- [ ] (Opcional) Pooling de moedas e efeitos

### Task X.5: Tratamento de Erros Global
- [ ] Adicionar pcall em todos os handlers de Main.server.lua
- [ ] Log detalhado no Output (sem expor ao cliente)
- [ ] Cliente recebe mensagem genérica "Erro interno"
- [ ] (Opcional) Sistema de logging para analytics

### Task X.6: Anti-Exploit - Rate Limiting
- [ ] Expandir rate limiting em Main.server.lua:
  - Geral: 0.1s entre chamadas
  - Ações caras (breed, battle): 1s entre chamadas
  - Construção: 0.5s entre place/move
- [ ] Validar todas as posições enviadas pelo cliente (BuildingService)
- [ ] Validar todos os IDs (dragonId, buildingId, etc.)

### Task X.7: Documentação de Código
- [ ] Adicionar comentários em português em todos os módulos novos
- [ ] Documentar funções principais (propósito, parâmetros, retorno)
- [ ] Atualizar README.md com:
  - Como rodar o jogo
  - Estrutura de pastas
  - Como adicionar novos elementos/dragões
  - Como configurar

### Task X.8: Testes Finais e Polish
- [ ] Rodar checklist completo de critérios de aceitação
- [ ] Testar em múltiplos dispositivos (PC, mobile emulator, tablet emulator)
- [ ] Testar com múltiplos jogadores simultâneos
- [ ] Verificar performance (FPS, memory)
- [ ] Verificar ausência de erros no Output
- [ ] Ajustar balanceamento (custos, tempo, dano) baseado em testes
- [ ] Polish visual: ajustar cores, tamanhos, posições
- [ ] Polish audio: ajustar volumes, timings

---

## Cronograma Estimado

- **Etapa 1:** 10 tasks → ~2-3 dias
- **Etapa 2:** 12 tasks → ~3-4 dias
- **Etapa 3:** 13 tasks → ~4-5 dias
- **Etapa 4:** 14 tasks → ~3-4 dias
- **Etapa 5:** 11 tasks → ~4-5 dias
- **Etapa 6:** 14 tasks → ~2-3 dias
- **Transversais:** 12 tasks → distribuídas ao longo + ~2 dias no final

**Total:** ~20-26 dias de desenvolvimento

## Ordem de Execução Sugerida
1. Etapa 1 (fundação)
2. Etapa 2 (construção - depende de 1)
3. Etapa 3 (dragões - depende de 2)
4. Task X.1 (ProfileService - antes de polir)
5. Etapa 4 (UI - pode ser paralelo a 5/6)
6. Etapa 5 (expedição - independente)
7. Etapa 6 (batalha - independente)
8. Tasks X.2-X.8 (finais)

## Notas
- Cada task pode ser quebrada em subtasks menores se necessário
- Priorizar MVP: funcionalidade primeiro, polish depois
- Testar incrementalmente a cada task completada
- Commitar código frequentemente (git)
- Solicitar feedback do usuário ao final de cada etapa
