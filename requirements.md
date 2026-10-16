# Dragon MVP - Requisitos de Reconstrução

## Visão Geral
Reconstruir o jogo Dragon MVP (inspirado em Dragon City + "Roube um Ovo") transformando um sistema de menus puro em um jogo 3D jogável e visualmente atraente para Roblox.

## Problemas Críticos a Resolver
1. **Ausência de mundo 3D**: Jogador nasce em Baseplate vazio
2. **Sistema de construção inexistente**: Itens comprados ficam "perdidos"
3. **Dragões invisíveis**: Existem apenas como dados, sem representação visual
4. **Interface não profissional**: Crua, sem identidade visual, sem feedback
5. **Falta de clareza nas ações**: Botões sem resposta ou feedback adequado

## Elementos Existentes (Reaproveitar)
- Sistema de elementos (10): Fogo, Terra, Água, Raio, Folha, Vento, Sombra, Neon, Infernal, Cósmico
- Sistema de atributos (5): Vitalidade, Poder Físico, Poder Elemental, Resistência, Agilidade
- Raridades: Comum, Raro, Épico, Lendário, Mítico + variante Shiny
- Lógica de servidor: DataService, DragonService, EconomyService, IncubatorService, HeistService, BattleService
- Economia: Ouro (habitat) e Maçãs (fazenda)
- Sistema de incubação e cruzamento
- Batalha 3v3 por turnos
- Modo "Roube um Ovo" (PvPvE)

## Requisitos Funcionais por Etapa

### ETAPA 1: Base 3D Bonita e Jogável
**FR-1.1 Sistema de Plot Individual**
- Cada jogador recebe uma ilha flutuante/tropical ao entrar
- Plot atribuído automaticamente com identificação persistente
- Terreno gerado proceduralmente usando Terrain API

**FR-1.2 Geração de Terreno**
- Grama, rocha, areia nas bordas
- Água ao redor (oceano ou nuvens)
- Relevo suave com elevações
- Decorações: árvores, pedras, flores, caminhos

**FR-1.3 Iluminação e Atmosfera**
- Lighting configurado para horário agradável (manhã/tarde)
- Atmosphere com densidade adequada
- Sky com textura apropriada
- Efeitos: Bloom, ColorCorrection, SunRays
- Câmera com configuração padrão melhorada

**FR-1.4 Sistema de Grid**
- Área delimitada para construção dentro do plot
- Grid visível ou invisível (snap automático)
- Validação de limites do plot

### ETAPA 2: Sistema de Construção e Inventário
**FR-2.1 Loja de Construções**
- NPC ou prédio com ProximityPrompt
- UI de loja com itens:
  - Fazenda
  - Habitats (10 tipos, um por elemento)
  - Incubadora
  - Decorações
  - Ovos básicos
- Compras validadas no servidor (custo, requisitos)

**FR-2.2 Sistema de Inventário**
- Aba "Construir" no menu principal
- Lista de itens possuídos pelo jogador
- Filtros por categoria
- Contador de quantidade

**FR-2.3 Modo Construir**
- Ativado ao selecionar item do inventário
- Preview "fantasma" seguindo cursor/toque:
  - Verde = pode colocar
  - Vermelho = colisão/fora do plot
- Snap automático no grid
- Rotação (tecla R / botão UI)
- Confirmação (clique) e cancelamento (ESC / botão)
- Funciona em PC e mobile

**FR-2.4 Gerenciamento de Construções**
- Modo edição: mover construções existentes
- Opção para guardar de volta no inventário
- Persistência de posição e rotação
- Validação servidor: limite plot, colisão, propriedade

### ETAPA 3: Dragões Visíveis no Mundo
**FR-3.1 Modelos 3D de Dragão**
- 10 modelos (um por elemento)
- Geração procedural com MeshParts/Parts:
  - Corpo, pescoço, cabeça, asas, cauda, chifres
  - Cores e materiais por elemento
  - Partículas elementais (fogo, água, raios, etc.)
- Animações básicas:
  - Idle
  - Asas batendo
  - Andar/voar
- Aura especial para Shiny (brilho, partículas extras)
- Módulo DragonModelFactory para fácil substituição

**FR-3.2 Dragões nos Habitats**
- Dragões passeando dentro dos habitats
- Animação de caminhada/voo
- Geração visual de moedas
- Coleta por clique/toque com efeito e som

**FR-3.3 Interação com Dragões**
- Clique abre painel detalhado:
  - Nome, nível, elemento, raridade
  - Status detalhados
  - Barra de experiência
  - Botão alimentar (gasta maçãs)
- Efeito visual ao evoluir (level up)
- Partículas, som, animação

**FR-3.4 Fazenda Física**
- Plantações crescendo visualmente
- Maçãs aparecem quando prontas
- Colheita por clique com efeito
- Estado visual por nível da fazenda

**FR-3.5 Incubadora Física**
- Ovo visível com modelo 3D
- Contador de tempo visível
- Animação de rachadura progressiva
- Nascimento com:
  - Animação de explosão do ovo
  - Partículas
  - Reveal do dragão
  - Som especial

### ETAPA 4: Interface Profissional
**FR-4.1 Design System**
- Paleta de cores única e vibrante
- Fontes consistentes (Gotham Bold/Medium)
- Cantos arredondados (UICorner)
- Sombras (dropshadow)
- Ícones para todas as ações
- Estilo cartoon tipo jogos populares do Roblox

**FR-4.2 HUD Melhorado**
- Ouro e maçãs com ícones
- Botões laterais com ícones claros:
  - Loja
  - Inventário/Construir
  - Dragões
  - Incubadora
  - Batalha
  - Expedição
- Indicador de loading
- Notificações toast

**FR-4.3 Animações UI**
- TweenService para transições:
  - Abrir/fechar painéis (scale/fade)
  - Botões "pulam" ao hover
  - Contadores sobem animados
  - Moedas voam para HUD
- Micro-interações em todos os cliques

**FR-4.4 Sistema de Sons**
- SFX para:
  - Clique em botão
  - Compra bem-sucedida
  - Moeda coletada
  - Dragão nascendo
  - Level up
  - Erro
  - Vitória/derrota
- Volume configurável

**FR-4.5 Sistema de Notificações**
- Toasts com cores por tipo:
  - Sucesso (verde)
  - Erro (vermelho)
  - Info (azul)
  - Aviso (amarelo)
- Animação de entrada/saída
- Fila automática

**FR-4.6 Tutorial Inicial**
- Primeira entrada:
  1. Ovo inicial grátis
  2. Guia para colocar habitat
  3. Assistir dragão nascer
  4. Colocar fazenda
  5. Primeira coleta
- Setas/highlights interativos
- Pode ser pulado

**FR-4.7 Responsividade Mobile**
- UIScale dinâmico
- UISizeConstraint para tamanhos mínimos
- Botões grandes o suficiente (48x48 mínimo)
- Testes no emulador

### ETAPA 5: Mapa da Expedição "Roube um Ovo"
**FR-5.1 Mapa Grande**
- Geração com Terrain:
  - Montanhas
  - Cavernas
  - Florestas
  - Rios
  - Ruínas
- Ninhos grandes e visíveis
- Brilho/partículas nos ninhos
- Zona de extração claramente marcada

**FR-5.2 IA de Dragões Selvagens**
- Patrulha por área
- Sistema de aggro (detecta jogador)
- Perseguição
- Ataque com telegrafagem
- Fuga quando com pouca vida
- Respawn após morte

**FR-5.3 Dragões Colossais**
- Voo em padrões definidos
- Ataque à distância (projéteis)
- Mais resistentes
- Recompensa maior

**FR-5.4 Sistema de Companheiro**
- Dragão seguindo jogador
- Modelo e animações reais
- Ataca inimigos automaticamente
- IA responsiva

**FR-5.5 Mecânica de Peso do Ovo**
- Lentidão baseada no tier do ovo
- Visual: jogador carregando ovo
- HUD de extração com progresso
- Bússola/indicador para zona
- Ovo cai ao morrer
- Outros podem roubar

**FR-5.6 Feedback PvP**
- Indicador de dano dado/recebido
- Nome do atacante
- Mini notificações

### ETAPA 6: Batalha 3v3 Visual
**FR-6.1 Arena de Batalha**
- Ambiente 3D dedicado
- Posições para 6 dragões
- Iluminação dramática

**FR-6.2 Animações de Combate**
- Ataque físico
- Ataque elemental com efeitos
- Defesa
- Troca
- Morte/desmaio

**FR-6.3 Câmera Cinemática**
- Enquadramento automático
- Zoom em ataques especiais
- Transições suaves

**FR-6.4 Efeitos Visuais**
- Números de dano flutuando
- Barras de vida 3D
- Efeitos por elemento
- Partículas de impacto

## Requisitos Técnicos

**RT-1 Arquitetura**
- Luau tipado onde possível
- Módulos organizados por responsabilidade
- Servidor autoritativo (cliente só requisita)
- Zero confiança em dados do cliente

**RT-2 Persistência**
- Migrar de DataStore para ProfileService
- Sessão travada (evita duplicação)
- Autosave a cada 2 minutos
- Save ao sair

**RT-3 Performance**
- Sem loops por jogador caros
- Cálculo por tempo decorrido
- Streaming Enabled para mapas grandes
- LOD para modelos distantes

**RT-4 Anti-Exploit**
- Todas as RemoteFunctions validam:
  - Propriedade dos dados
  - Custos
  - Cooldowns
  - Limites
- Rate limiting
- Valores sensíveis só no servidor

**RT-5 Modo DEBUG**
- Comando/tecla (só no Studio):
  - `/givegold [amount]`
  - `/giveapples [amount]`
  - `/giveegg [element] [rarity] [shiny]`
  - `/levelup [dragonId] [levels]`
- Facilita testes

**RT-6 Geração Procedural**
- Determinística (mesma seed = mesmo resultado)
- Configurável via Config.lua
- Modular para fácil ajuste

## Requisitos de Qualidade

**RQ-1 Usabilidade**
- Tutorial claro para novos jogadores
- Feedback em toda ação
- Mensagens de erro descritivas
- Interface intuitiva

**RQ-2 Acessibilidade**
- Textos legíveis (contraste, tamanho)
- Botões tocáveis (mobile)
- Cores não são única forma de informação
- Suporte a controles mobile e desktop

**RQ-3 Manutenibilidade**
- Código comentado (português)
- Estrutura modular
- Fácil adicionar novos elementos/dragões
- Config centralizados

**RQ-4 Testabilidade**
- Modo debug funcional
- Logs claros no Output
- Sem erros silenciosos

## Critérios de Aceitação (Checklist)

### Etapa 1
- [ ] Spawn em ilha bonita com céu e iluminação
- [ ] Sem erros no Output
- [ ] Terreno variado com decorações
- [ ] Câmera funcionando bem

### Etapa 2
- [ ] Comprar item na loja
- [ ] Item aparece no inventário
- [ ] Preview verde/vermelho funciona
- [ ] Consegue colocar, girar e mover
- [ ] Guardar de volta no inventário
- [ ] Tudo persiste ao sair/entrar
- [ ] Funciona em mobile (emulador)

### Etapa 3
- [ ] Dragão aparece no habitat (modelo 3D)
- [ ] Dragão passeia animado
- [ ] Moedas aparecem e podem ser coletadas
- [ ] Clicar no dragão abre painel
- [ ] Alimentar mostra efeito de level up
- [ ] Fazenda tem visual de plantação
- [ ] Maçãs podem ser colhidas
- [ ] Ovo visível na incubadora
- [ ] Nascimento tem animação completa

### Etapa 4
- [ ] Interface com identidade visual
- [ ] Ícones em todos os botões
- [ ] Animações suaves ao abrir painéis
- [ ] Sons em ações principais
- [ ] Notificações aparecem corretamente
- [ ] Tutorial guia novo jogador
- [ ] Funciona bem em mobile

### Etapa 5
- [ ] Mapa grande com variedade
- [ ] Ninhos visíveis e interativos
- [ ] Dragões selvagens patrulham
- [ ] Companheiro segue e ataca
- [ ] Peso do ovo deixa lento
- [ ] HUD de extração funciona
- [ ] Ovo cai ao morrer
- [ ] Extrair ovo vai para incubadora

### Etapa 6
- [ ] Arena visual com dragões 3D
- [ ] Animações de ataque funcionam
- [ ] Efeitos visuais por elemento
- [ ] Câmera enquadra bem
- [ ] Números de dano aparecem

### Geral
- [ ] Ovo inicial grátis funciona
- [ ] Cruzamento gera ovo correto
- [ ] Tudo persiste entre sessões
- [ ] Nenhum botão é "morto" (todos dão feedback)
- [ ] Sem erros no Output durante jogo normal
- [ ] Performance aceitável (60 FPS)

## Fora de Escopo (Futuro)
- Sistema de quests/missões
- Chat de guild/clã
- Trading entre jogadores
- Eventos temporários
- Skins/customização de ilha
- Áudio ambiente/música
- Multiplayer síncrono em batalha
- Ranking global
- Sistema de achievements
