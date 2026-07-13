# MANUAL - mri_Qelevators

## O que o recurso faz (descrição funcional)
Sistema avançado de elevadores para FiveM com suporte a multiandares, proteção por senha, restrições de emprego/gangue e suporte a veículos. Inclui ferramenta de criação in-game para admins.

## Funcionalidades principais
- **Multiandares**: Suporte para andares ilimitados por elevador.
- **Proteção por senha**: Andares protegidos com senha configurável.
- **Restrições de acesso**: Limitação por job + patente ou gangue + patente.
- **Elevadores de veículos**: Move veículos entre andares com verificação de altura.
- **Criador admin**: GUI para criação e gerenciamento de elevadores in-game.
- **Logs Discord**: Registro de uso, criação, deleção e tentativas de acesso.

## Como funciona (fluxo de trabalho)

### Uso do elevador (jogador)
1. Jogador interage com elevador (via target ou trigger).
2. Menu abre listando andares disponíveis.
3. Se andar protegido por senha, solicita senha.
4. Se andar restrito, verifica job/gangue e patente.
5. Elevador move jogador (e veículo, se aplicável) para o andar selecionado.

### Criação de elevador (admin)
1. Admin usa comando `/elevador`.
2. GUI abre para definir: label, coordenadas, se é elevador de veículo.
3. Adiciona andares: define coords, label, senha (opcional), job/gangue restritos.
4. Elevador é salvo no DB e sincronizado com todos os clients.

## Opções de configuração disponíveis
Configurações em config/config.lua:

| Opção | Padrão | Descrição |
|-------|--------|-----------|
| Config.MaxFloors | 20 | Máximo de andares por elevador. |
| Config.ElevatorSpeed | 2.0 | Velocidade da animação. |
| Config.SoundEnabled | true | Ativar/desativar sons. |
| Config.VehicleElevators.enabled | true | Habilita elevadores de veículos. |
| Config.VehicleElevators.maxHeight | 3.0 | Altura máxima do veículo. |
| Config.PasswordProtection.enabled | true | Habilita proteção por senha. |
| Config.Discord.enabled | true | Habilita logs Discord. |
| Config.Discord.webhook | 'SUA_URL_WEBHOOK' | URL do webhook Discord. |

## Comandos disponíveis
| Comando | Permissão | Descrição |
|---------|------------|-------------|
| `/elevador` | Admin/Mod | Abre menu criador/admin de elevadores. |

## Eventos que dispara/ouve

### Cliente → Servidor
| Evento | Parâmetros | Descrição |
|--------|------------|-----------|
| mri_Qelevators:client:openElevator | elevatorId, floorId | Abre menu do elevador. |
| mri_Qelevators:client:useElevator | elevatorId, targetFloor | Usa elevador para ir ao andar. |
| mri_Qelevators:client:enterPassword | elevatorId, floorId | Solicita senha do andar. |
| mri_Qelevators:client:createElevator | none | Abre criador de elevadores. |

### Servidor → Cliente
| Evento | Parâmetros | Descrição |
|--------|------------|-----------|
| mri_Qelevators:server:createElevator | elevatorData | Cria novo elevador. |
| mri_Qelevators:server:deleteElevator | elevatorId | Deleta elevador. |
| mri_Qelevators:server:addFloor | elevatorId, floorData | Adiciona andar. |
| mri_Qelevators:server:removeFloor | elevatorId, floorId | Remove andar. |
| mri_Qelevators:server:checkAccess | elevatorId, floorId, playerData | Verifica acesso. |
| mri_Qelevators:server:logUsage | playerData, elevatorId, floorId | Registra uso. |

## Exports que fornece/consome

### Exports do cliente
| Export | Parâmetros | Descrição |
|--------|------------|-----------|
| openElevator | elevatorId, currentFloor | Abre menu do elevador. |
| checkFloorAccess | elevatorId, floorId | Verifica acesso ao andar. |
| getElevator | elevatorId | Obtém dados do elevador. |
| getFloors | elevatorId | Obtém andares do elevador. |

### Exports do servidor
| Export | Parâmetros | Descrição |
|--------|------------|-----------|
| createElevator | elevatorData | Cria elevador. |
| deleteElevator | elevatorId | Deleta elevador. |
| addFloor | elevatorId, floorData | Adiciona andar. |
| removeFloor | elevatorId, floorId | Remove andar. |
| checkAccess | source, elevatorId, floorId | Verifica acesso. |

### Exports consumidos
Usa ox_lib para UI, oxmysql para persistência, interact-sound (opcional) para efeitos sonoros.

## Integração com outros recursos MRI Qbox
- **ox_lib**: Componentes UI, notificações e interações.
- **oxmysql**: Persistência de elevadores e andares.
- **interact-sound**: Efeitos sonoros de elevador (opcional).
- Outros recursos podem usar exports para integração com sistemas de prédos/apartamentos.

## Casos de uso / exemplos práticos
1. **Prédio de apartamentos**: Admin cria elevador com 10 andares, cada andar vai para um apartamento diferente.
2. **Elevador de garagem**: Elevador de veículos leva carros do térreo ao 5º andar da garagem.
3. **Andar restrito**: Andar 10 restrito a job "police" com patente "boss", outros não acessam.
4. **Andar com senha**: Andar VIP protegido por senha, apenas quem sabe a senha pode acessar.

## Dicas de solução de problemas
- **Elevador não abre**: Verifique se o jogador está próximo e se o target está funcionando.
- **Andar não aparece**: Confira se o andar foi adicionado corretamente no DB.
- **Veículo não sobe**: Verifique se a altura do veículo é menor que Config.VehicleElevators.maxHeight.
- **Logs não aparecem**: Confirme se o webhook do Discord está correto e habilitado.
- **Erros de banco de dados**: Importe sql/elevators.sql e sql/floors.sql, verifique oxmysql.
