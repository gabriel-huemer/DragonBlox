# Dragon MVP — Roblox

MVP com: 10 elementos, 5 atributos, base idle (ouro + maçãs), incubadora/cruzamento,
torneio 3v3 por turnos e o modo **Roube um Ovo** (PvPvE de extração).

## Onde colocar cada arquivo (Roblox Studio, manualmente)

| Arquivo | Tipo no Studio | Local |
|---|---|---|
| `Config.lua` | ModuleScript, nome **Config** | `ReplicatedStorage > Shared` (crie a Folder **Shared**) |
| `DragonUtil.lua` | ModuleScript, nome **DragonUtil** | `ReplicatedStorage > Shared` |
| `Main.server.lua` | **Script**, nome **Main** | `ServerScriptService` |
| `DataService.lua` | ModuleScript, nome **DataService** | `ServerScriptService > Services` (crie a Folder **Services**) |
| `DragonService.lua` | ModuleScript | `ServerScriptService > Services` |
| `EconomyService.lua` | ModuleScript | `ServerScriptService > Services` |
| `IncubatorService.lua` | ModuleScript | `ServerScriptService > Services` |
| `HeistService.lua` | ModuleScript | `ServerScriptService > Services` |
| `BattleService.lua` | ModuleScript | `ServerScriptService > Services` |
| `Client.client.lua` | **LocalScript**, nome **Client** | `StarterPlayer > StarterPlayerScripts` |

Os nomes dos ModuleScripts precisam ser exatamente os da tabela (sem `.lua`).
Os sufixos `.server.lua` / `.client.lua` só existem para o Rojo; no Studio use o tipo certo de script.

### Com Rojo
Abra a pasta `DragonMVP` e rode `rojo serve`; o `default.project.json` já monta tudo.

## Estrutura final no Explorer

```
ReplicatedStorage
└─ Shared (Folder)
   ├─ Config
   └─ DragonUtil
ServerScriptService
├─ Main (Script)
└─ Services (Folder)
   ├─ DataService
   ├─ DragonService
   ├─ EconomyService
   ├─ IncubatorService
   ├─ HeistService
   └─ BattleService
StarterPlayer
└─ StarterPlayerScripts
   └─ Client (LocalScript)
```

Os Remotes (`ReplicatedStorage > Remotes`) e o mapa de teste da expedição são criados
automaticamente em tempo de execução.

## Como testar

1. Cole os arquivos conforme a tabela e aperte **Play**.
2. Aba **Base**: compre um ovo (150 ouro) → aba **Incubadora**: aguarde 60 s (ou "Acelerar", grátis no Studio) e **Chocar**.
3. Aba **Dragões**: alimente com maçãs, monte o time, selecione 2 dragões nível 3+ para **Cruzar**.
4. Aba **Batalha**: **Lutar!** (turnos: físico, elemental com recarga, defender, trocar).
5. Aba **Expedição**: **Entrar**. Você é teletransportado para o mapa de teste (longe da base).
   Segure **E** num ninho para roubar um ovo, fuja para a zona verde e fique parado ~4 s.
   Teste PvP com *Test > Clients and Servers* (2+ jogadores).
6. Tecla **M** abre/fecha o menu.

Para salvar dados no Studio: *Game Settings > Security > Enable Studio Access to API Services*.
Sem isso o jogo roda normalmente, mas não persiste.

## Onde mexer no balanceamento
Tudo em `Config.lua`: raridades, chance de Shiny, receitas de cruzamento, custos, tempos de
incubação (hoje curtos para teste; há comentários com os valores de produção), vantagens de elemento,
tiers de ovo, vida/dano dos dragões selvagens.

## Robux (acelerar incubadora)
Crie um Developer Product, coloque o ID em `Config.SkipProductId`. O `ProcessReceipt` já está no `Main`.

## Limitações conhecidas do MVP
- A base é por **menus** (sem tycoon 3D com habitats físicos). Dá para ligar cada habitat a um modelo depois.
- Dragões são modelos de Parts simples (placeholders). Troque `buildDragonModel` por seus modelos/animações.
- O companheiro da expedição é invulnerável e ataca automaticamente.
- O mapa gerado é plano com colinas. Use o seu próprio seguindo o formato descrito no topo de `HeistService.lua`.
- Cosmico está forte de propósito (vantagem contra 4 elementos); ajuste em `Config.Advantage`.
- Para produção: troque o DataStore simples por ProfileService/ProfileStore e adicione telemetria anti-exploit.
