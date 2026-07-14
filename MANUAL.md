# mri_Qelevators — Manual

Sistema de elevadores por zonas: cada andar é uma box zone que teleporta o jogador (ou o veículo dele) para o andar escolhido, com restrição por job/gang e senha opcional.

---

## Sumário

1. [Dependências](#dependências)
2. [Instalação](#instalação)
3. [Permissões (ACE)](#permissões-ace)
4. [Configuração](#configuração)
5. [Comandos](#comandos)
6. [Estrutura de um andar](#estrutura-de-um-andar)
7. [Banco de dados](#banco-de-dados)
8. [Criador de elevadores](#criador-de-elevadores)
9. [Menu de gerenciamento](#menu-de-gerenciamento)
10. [Uso pelo jogador](#uso-pelo-jogador)
11. [Logs administrativos](#logs-administrativos)
12. [Entrypoints para outros recursos](#entrypoints-para-outros-recursos)
13. [Estrutura de arquivos](#estrutura-de-arquivos)

---

## Dependências

| Recurso | Obrigatório | Observação |
|---|---|---|
| `ox_lib` | Sim | Box zones, textUI, menu de contexto, inputDialog, callbacks, notificações |
| `oxmysql` | Sim | Persistência dos elevadores |
| `qbx_core` | Sim | `exports['qb-core']:GetCoreObject()` (servido pelo `provide 'qb-core'` do qbx_core) para job/gang do jogador e dados do admin nos logs |
| `InteractSound` | Não | Som do sino ao chegar no andar (`InteractSound_SV:PlayOnSource`, som `liftSoundBellRing`) |

---

## Instalação

1. Copie a pasta `mri_Qelevators` para `resources/`.
2. Adicione ao `server.cfg`:
   ```
   ensure mri_Qelevators
   ```
3. Copie `_install/liftSoundBellRing.ogg` para a pasta de sons do seu `InteractSound` (normalmente `interact-sound/client/html/sounds/`). Sem isso, o elevador funciona, só não toca o sino.
4. Não há SQL para importar: a tabela `mri_qelevators` é criada no primeiro start, e a coluna `password` é adicionada automaticamente em instalações antigas.
5. Se você já tinha elevadores em um `data/lift.lua`, coloque o arquivo antigo no lugar **antes** do primeiro start — ele é importado para o banco apenas enquanto a tabela estiver vazia. Depois disso o banco passa a ser a fonte da verdade e o `lift.lua` é ignorado.
6. Ajuste o webhook de log (veja [Logs administrativos](#logs-administrativos)).

---

## Permissões (ACE)

O acesso de admin é verificado com `IsPlayerAceAllowed` contra cada entrada de `Config.Permissions` (padrão: `admin` e `mod`). O mesmo gate protege o comando e todos os eventos de escrita no servidor.

```
add_ace group.admin admin allow
add_ace group.mod mod allow
```

---

## Configuração

Arquivo: `config.lua`.

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `Config.Data` | tabela | Sim | Carregada de `data/lift.lua` no boot e substituída pelos dados do banco assim que o servidor inicia |
| `Config.Debug` | bool | Sim | Desenha as box zones, o nome do elevador/andar e uma seta com o heading de cada andar |
| `Config.Permissions` | lista | Sim | ACEs que dão acesso de admin. Padrão: `{'admin', 'mod'}` |

O webhook do Discord **não** está no config: ele é a constante `DISCORD_WEBHOOK` em `server/utils.lua`.

---

## Comandos

| Comando | Permissão | Descrição |
|---|---|---|
| `/elevador` | ACE de `Config.Permissions` (`admin` ou `mod`) | Abre o menu de criação e gerenciamento de elevadores |

---

## Estrutura de um andar

Um elevador é apenas um nome com uma lista de andares. Cada andar é uma linha na tabela e uma box zone no mundo.

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `label` | string | Sim | Nome do andar. Precisa ser único dentro do elevador |
| `coords` | `{x, y, z}` | Sim | Ponto de chegada e centro da zona |
| `size` | `{x, y, z}` | Sim | Tamanho da box zone |
| `rot` | number | Sim | Heading aplicado ao jogador (ou ao veículo) ao chegar, e rotação da zona |
| `car` | bool | Sim | Se `true` e o jogador estiver em um veículo, o veículo é teleportado junto |
| `job` | string | Não | Restringe o andar a um job. Vazio = sem restrição |
| `gang` | string | Não | Restringe o andar a uma gang. Vazio = sem restrição |
| `password` | string | Não | Senha pedida antes de viajar. Vazio = sem senha |

---

## Banco de dados

Tabela `mri_qelevators`, criada automaticamente. Cada linha é **um andar**; o elevador é a coluna `name`, repetida entre os andares dele.

| Coluna | Tipo | Descrição |
|---|---|---|
| `id` | INT AUTO_INCREMENT | Chave primária |
| `name` | VARCHAR(64) | Nome do elevador |
| `label` | VARCHAR(64) | Nome do andar |
| `x`, `y`, `z` | DOUBLE | Coordenadas do andar |
| `size_x`, `size_y`, `size_z` | DOUBLE | Tamanho da box zone |
| `rot` | DOUBLE | Heading |
| `car` | BOOLEAN | Elevador de veículo |
| `job` | VARCHAR(64) | Job exigido |
| `gang` | VARCHAR(64) | Gang exigida |
| `password` | VARCHAR(64) | Senha do andar |

---

## Criador de elevadores

`/elevador` → **Criar novo Elevador**. O criador roda no mundo, sem NUI:

| Tecla | Ação |
|---|---|
| `Y` | Adiciona um andar na posição e no heading atuais do personagem |
| `SCROLL` | Ajusta o tamanho da box zone |
| `Enter` | Salva o elevador |
| `Backspace` | Cancela |

Ao adicionar um andar, um diálogo pede nome, tamanho, se é elevador de veículo, job e gang. Ao salvar, o servidor rejeita elevadores com nome já existente e andares com `label` duplicado dentro do mesmo elevador.

---

## Menu de gerenciamento

O mesmo `/elevador` lista os elevadores existentes e permite alternar o **Modo Debug** (as box zones e os headings passam a ser desenhados).

Por elevador:

| Opção | Efeito |
|---|---|
| Mudar Nome | Renomeia o elevador (falha se o nome novo já existir) |
| Adicionar Andar | Cria um andar na posição atual do admin |
| Teleportar | Leva o admin até o elevador |
| Excluir Elevador | Apaga o elevador e todos os andares |

Por andar:

| Opção | Efeito |
|---|---|
| Editar Andar | Altera nome, tamanho, veículo, job e gang |
| Editar Senha | Define ou remove a senha (senha vazia remove) |
| Mover Andar | Reposiciona o andar na posição atual do admin |
| Teleportar | Leva o admin até o andar |
| Excluir Andar | Remove o andar |

Toda alteração grava no banco e atualiza o `GlobalState.mri_Qelevators_data`. Os clientes reagem à mudança do state bag e reconstroem as zonas na hora, sem restart.

---

## Uso pelo jogador

1. Ao entrar na zona de um andar, aparece o textUI `[E] <andar> (<elevador>)`. Andares com senha mostram um cadeado.
2. `E` abre o menu com os andares do elevador. O andar em que o jogador está aparece desabilitado.
3. O menu só lista andares a que o jogador tem acesso: andar sem `job` e sem `gang` é livre; com `job` ou `gang` definido, exige o job ou a gang correspondente.
4. Se o andar tiver senha, um diálogo a pede antes da viagem.
5. A tela escurece, o jogador (e o veículo, se `car` estiver ligado) é teleportado, o sino toca e a tela volta.

A senha é comparada no client, contra o valor que veio no `GlobalState`.

---

## Logs administrativos

Toda ação administrativa (criar, excluir, renomear, adicionar/editar/mover/excluir andar, definir ou remover senha) é registrada no console e enviada como embed para o Discord.

A URL do webhook está **hard-coded** na constante `DISCORD_WEBHOOK`, no topo de `server/utils.lua`. Troque-a pela do seu servidor — ou deixe a string vazia para desativar o envio. O embed inclui nome, citizenid, primeiro identificador, IP e coordenadas do admin.

---

## Entrypoints para outros recursos

O recurso não expõe exports. O que dá para consumir de fora:

### GlobalState

Todos os elevadores ficam replicados em um state bag global — qualquer recurso no client pode ler, sem callback:

```lua
local elevadores = GlobalState.mri_Qelevators_data
-- elevadores['nome_do_elevador'] = { { label = ..., coords = ..., job = ..., password = ... }, ... }
```

### Abrir o menu de um elevador

```lua
-- client: recebe a lista de andares (o array de um elevador) e abre o menu de escolha
TriggerClientEvent('mri_Qelevators:client:lift', source, andares)
```

### Callback de permissão

```lua
local isAdmin = lib.callback.await('mri_Qelevators:server:isAdmin', false)
```

Os demais eventos de servidor (`liftCreatorSave`, `liftDeleteAndSave`, `addFloorToElevator`, `updateFloor`, `deleteFloor`, `updateFloorPassword`, `renameElevator`) existem para o próprio criador e passam pelo gate de admin.

---

## Estrutura de arquivos

```
mri_Qelevators/
├── config.lua              — Config.Data, Debug e Permissions
├── data/
│   └── lift.lua            — seed de elevadores, importado só na primeira execução
├── client/
│   ├── elevator.lua        — box zones, textUI, menu de andares, senha e teleporte
│   ├── menu.lua            — menus de admin (criar, listar, editar elevador e andares)
│   ├── creator.lua         — criador em jogo (Y/SCROLL/Enter/Backspace)
│   ├── events.lua          — sync via state bag, requisição inicial, ciclo de vida
│   └── utils.lua           — DrawText3D e DrawArrow3D do modo debug
├── server/
│   ├── database.lua        — criação da tabela, migração, CRUD e importação do lift.lua
│   ├── events.lua          — gate de admin, escrita no banco e GlobalState
│   ├── commands.lua        — comando /elevador
│   └── utils.lua           — isAdmin (ACE) e log das ações no Discord
├── _install/
│   └── liftSoundBellRing.ogg  — som do sino (copiar para o InteractSound)
└── fxmanifest.lua
```
