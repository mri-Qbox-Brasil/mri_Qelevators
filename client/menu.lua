local elevator = require('client.elevator')
local creator = require('client.creator')

local CONSTANTS = {
    MIN_SIZE = 1,
    MAX_SIZE = 50,
    DEFAULT_SIZE = 2
}

local function createFloorData(label, coords, rot, size, car, job, gang, password)
    return {
        label = label,
        coords = coords,
        rot = rot,
        size = {x = size, y = size, z = size},
        car = car or false,
        job = job or '',
        gang = gang or '',
        password = password or ''
    }
end

local function floorExists(location, label)
    if not Config.Data[location] then return false end
    
    for _, floor in ipairs(Config.Data[location]) do
        if floor.label == label then
            return true
        end
    end
    return false
end

local function getRestrictionsText(elevators)
    local restrictions = {}
    for _, floor in ipairs(elevators) do
        if floor.job and floor.job ~= '' then
            restrictions[#restrictions + 1] = 'Job: ' .. floor.job
        end
        if floor.gang and floor.gang ~= '' then
            restrictions[#restrictions + 1] = 'Gang: ' .. floor.gang
        end
    end
    return #restrictions > 0 and ' • ' .. table.concat(restrictions, ', ') or ''
end

local function getFloorDescription(floorCount, firstFloor, restrictions)
    local baseDesc = string.format('%d andar%s • Coord: %.0f, %.0f, %.0f', 
        floorCount, 
        floorCount > 1 and 'es' or '', 
        firstFloor.coords.x, 
        firstFloor.coords.y, 
        firstFloor.coords.z
    )
    return baseDesc .. restrictions
end

local function teleportToLocation(coords, heading, locationName)
    SetEntityCoords(cache.ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(cache.ped, heading)
    lib.notify({
        title = "Teleportado",
        description = "Você foi teleportado para " .. locationName,
        type = "success"
    })
end

local function createMenuOption(config)
    local option = {
        title = config.title,
        description = config.description,
        icon = config.icon,
        onSelect = config.onSelect
    }
    
    if config.iconColor then
        option.iconColor = config.iconColor
    end
    
    if config.colorScheme then
        option.colorScheme = config.colorScheme
        option.progress = config.progress
        option.readOnly = config.readOnly
    end
    
    return option
end

local function createContextMenu(id, title, description, menuConfigs, parentMenu)
    local options = {}
    
    for _, config in ipairs(menuConfigs) do
        options[#options + 1] = createMenuOption(config)
    end
    
    local contextConfig = {
        id = id,
        title = title,
        options = options
    }
    
    if description then
        contextConfig.description = description
    end
    
    if parentMenu then
        contextConfig.menu = parentMenu
    end
    
    lib.registerContext(contextConfig)
    lib.showContext(id)
end

function liftList()
    local elevatorsList = {}
    
    elevatorsList[#elevatorsList + 1] = {
        title = 'Criar novo Elevador',
        description = 'Cria um elevador',
        icon = 'fa-plus',
        onSelect = function()
            creator.liftCreation(liftList)
        end
    }

    local debugTitle = Config.Debug and 'Desativar Debug' or 'Ativar Debug'
    local debugIcon = Config.Debug and 'fa-toggle-on' or 'fa-toggle-off'
    local debugColor = Config.Debug and 'green' or 'red'
    
    elevatorsList[#elevatorsList + 1] = {
        title = debugTitle,
        description = 'Alterna o modo debug dos elevadores',
        icon = debugIcon,
        iconColor = debugColor,
        onSelect = function()
            Config.Debug = not Config.Debug
            lib.notify({
                title = 'Modo Debug',
                description = Config.Debug and 'Debug ativado' or 'Debug desativado',
                type = Config.Debug and 'success' or 'info'
            })
            elevator.init()
            liftList()
        end
    }

    elevatorsList[#elevatorsList + 1] = {
        colorScheme = 'green',
        progress = 100,
        readOnly = true
    }

    for location, elevators in pairs(Config.Data) do
        local floorCount = #elevators
        local firstFloor = elevators[1]
        local restrictions = getRestrictionsText(elevators)
        local description = getFloorDescription(floorCount, firstFloor, restrictions)
        
        elevatorsList[#elevatorsList + 1] = {
            title = location,
            description = description,
            icon = 'fa-elevator',
            onSelect = function()
                liftOptions(location)
            end
        }
    end

    lib.registerContext({
        id = 'elevator_list',
        title = 'Gerenciar Elevadores',
        options = elevatorsList
    })

    lib.showContext('elevator_list')
end

function liftOptions(name)
    local menuConfigs = {
        {
            title = 'Mudar Nome',
            description = 'Altera nome do elevador',
            icon = 'fa-signature',
            onSelect = function() changeNameElevator(name) end
        },
        {
            title = 'Adicionar Andar',
            description = 'Adiciona um novo andar ao elevador',
            icon = 'fa-plus',
            onSelect = function() addFloorToElevator(name) end
        },
        {
            title = 'Teleportar',
            description = 'Teleporta ao elevador',
            icon = 'fa-location-dot',
            onSelect = function() teleportElevator(name) end
        },
        {
            title = 'Excluir Elevador',
            description = 'Exclui elevador',
            icon = 'fa-trash',
            iconColor = 'red',
            onSelect = function() deleteElevator(name) end
        },
        {
            colorScheme = 'green',
            progress = 100,
            readOnly = true
        }
    }
    
    for _, floor in ipairs(Config.Data[name]) do
        menuConfigs[#menuConfigs + 1] = {
            title = floor.label,
            description = string.format('Coords: %.1f, %.1f, %.1f', floor.coords.x, floor.coords.y, floor.coords.z),
            icon = 'fa-building',
            onSelect = function() floorOptions(name, floor) end
        }
    end

    createContextMenu('elevator_opts', 'Editando Elevador', name, menuConfigs, 'elevator_list')
end

function floorOptions(elevatorName, floor)
    local menuConfigs = {
        {
            title = 'Editar Andar',
            description = 'Edita as propriedades do andar',
            icon = 'fa-edit',
            onSelect = function() editFloor(elevatorName, floor) end
        },
        {
            title = 'Editar Senha',
            description = floor.password and floor.password ~= '' and 'Senha atual: ' .. floor.password or 'Nenhuma senha definida',
            icon = 'fa-lock',
            onSelect = function() editFloorPassword(elevatorName, floor) end
        },
        {
            title = 'Mover Andar',
            description = 'Move o andar para sua posição atual',
            icon = 'fa-location-arrow',
            onSelect = function() moveFloor(elevatorName, floor) end
        },
        {
            title = 'Teleportar',
            description = 'Teleporta para este andar',
            icon = 'fa-location-dot',
            onSelect = function()
                teleportToLocation(floor.coords, floor.rot, floor.label)
            end
        },
        {
            title = 'Excluir Andar',
            description = 'Remove este andar do elevador',
            icon = 'fa-trash',
            iconColor = 'red',
            onSelect = function() deleteFloor(elevatorName, floor) end
        }
    }

    createContextMenu('floor_opts', 'Gerenciar Andar', floor.label, menuConfigs, 'elevator_opts')
end

function editFloor(elevatorName, floor)
    local input = lib.inputDialog('Editar Andar', {{
        type = 'input',
        label = 'Nome do Andar',
        placeholder = 'Ex: 1º Andar',
        required = true,
        default = floor.label,
        min = 2,
        max = 50
    }, {
        type = 'number',
        label = 'Tamanho',
        placeholder = tostring(CONSTANTS.DEFAULT_SIZE),
        required = false,
        default = floor.size.x,
        min = CONSTANTS.MIN_SIZE,
        max = CONSTANTS.MAX_SIZE
    }, {
        type = 'select',
        label = 'Veículo',
        placeholder = 'Não',
        required = false,
        default = floor.car and 1 or 2,
        options = {{
            value = true,
            label = "Sim"
        }, {
            value = false,
            label = "Não"
        }}
    }, {
        type = 'input',
        label = 'Job (Opcional)',
        placeholder = 'Ex: police',
        default = floor.job or ''
    },{
        type = 'input',
        label = 'Gang (Opcional)',
        placeholder = 'Ex: ballas',
        default = floor.gang or ''
    }})

    if not input then return end

    local newFloorData = createFloorData(
        input[1],
        floor.coords,
        floor.rot,
        input[2],
        input[3],
        input[4],
        input[5],
        floor.password
    )

    TriggerServerEvent('mri_Qelevators:server:updateFloor', elevatorName, floor.label, newFloorData)
    
    lib.notify({
        title = "Andar Atualizado",
        description = "O andar foi atualizado com sucesso",
        type = "success"
    })
end

function moveFloor(elevatorName, floor)
    local result = lib.alertDialog({
        header = "Mover Andar",
        content = "Você tem certeza que deseja mover o andar '" .. floor.label .. "' para sua posição atual?",
        centered = true,
        cancel = true
    })

    if result == 'confirm' then
        local newCoords = GetEntityCoords(cache.ped)
        local newHeading = GetEntityHeading(cache.ped)
        
        local newFloorData = createFloorData(
            floor.label,
            newCoords,
            newHeading,
            floor.size.x,
            floor.car,
            floor.job,
            floor.gang
        )

        TriggerServerEvent('mri_Qelevators:server:updateFloor', elevatorName, floor.label, newFloorData)

        lib.notify({
            title = "Andar Movido",
            description = "O andar '" .. floor.label .. "' foi movido para sua posição atual",
            type = "success"
        })
    end
    floorOptions(elevatorName, floor)
end

function deleteFloor(elevatorName, floor)
    local result = lib.alertDialog({
        header = "Excluir Andar",
        content = "Você tem certeza que deseja excluir o andar '" .. floor.label .. "'?\n\n⚠️ Esta ação não pode ser desfeita!",
        centered = true,
        cancel = true
    })

    if result == 'confirm' then
        TriggerServerEvent('mri_Qelevators:server:deleteFloor', elevatorName, floor.label)
        
        lib.notify({
            title = "Andar Excluído",
            description = "O andar '" .. floor.label .. "' foi excluído com sucesso",
            type = "success"
        })
    else
        lib.notify({
            title = 'Operação Cancelada',
            description = 'Exclusão do andar cancelada',
            type = 'info'
        })
    end
end

function changeNameElevator(location)
    local input = lib.inputDialog('Renomear Elevador', {{
        type = 'input',
        label = 'Novo Nome do Elevador',
        placeholder = 'Ex: Delegacia Central',
        required = true,
        default = location,
        min = 2,
        max = 50
    }})

    if not input then return end

    local newName = input[1]
    
    if Config.Data[newName] then
        lib.notify({
            title = "Erro",
            description = "Já existe um elevador com o nome '" .. newName .. "'",
            type = "error"
        })
        return
    end

    local success = lib.callback.await('mri_Qelevators:server:renameElevator', false, location, newName)
    
    if success then
        lib.notify({
            title = "Elevador Renomeado",
            description = "O elevador foi renomeado para '" .. newName .. "'",
            type = "success"
        })
    else
        lib.notify({
            title = "Erro",
            description = "Não foi possível renomear o elevador",
            type = "error"
        })
        liftOptions(location)
    end
end

function addFloorToElevator(location)
    local input = lib.inputDialog('Adicionar Andar', {{
        type = 'input',
        label = 'Nome do Novo Andar',
        placeholder = 'Ex: 2º Andar',
        required = true,
        min = 2,
        max = 50
        }, {
            type = 'number',
            label = 'Tamanho',
            placeholder = tostring(CONSTANTS.DEFAULT_SIZE),
            required = false,
            min = CONSTANTS.MIN_SIZE,
            max = CONSTANTS.MAX_SIZE
        }, {
            type = 'select',
            label = 'Veículo (Opcional)',
            placeholder = 'Não',
            required = false,
            options = {{
                value = true,
                label = "Sim"
            }, {
                value = false,
                label = "Não"
            }}
        }, {
            type = 'input',
            label = 'Job (Opcional)',
            placeholder = 'Ex: police'
        },{
            type = 'input',
            label = 'Gang (Opcional)',
            placeholder = 'Ex: ballas'
        }
    })

    if not input then return end

    local label = input[1]
    
    if floorExists(location, label) then
        lib.notify({
            title = "Erro",
            description = "O andar '" .. label .. "' já existe no elevador",
            type = "error"
        })
        return
    end

    local newFloor = createFloorData(
        label,
        GetEntityCoords(cache.ped),
        GetEntityHeading(cache.ped),
        input[2],
        input[3],
        input[4],
        input[5],
        ''
    )
    
    TriggerServerEvent('mri_Qelevators:server:addFloorToElevator', location, newFloor)
    
    lib.notify({
        title = "Andar Adicionado",
        description = "O andar '" .. label .. "' foi adicionado com sucesso",
        type = "success"
    })
end

function teleportElevator(location)
    local elevator = Config.Data[location][1]
    teleportToLocation(elevator.coords, elevator.rot, "o elevador '" .. location .. "'")
end

function deleteElevator(location)
    local result = lib.alertDialog({
        header = "Excluir Elevador",
        content = "Você tem certeza que deseja excluir o elevador '" .. location .. "'?\n\n⚠️ Esta ação não pode ser desfeita!",
        centered = true,
        cancel = true
    })

    if result == 'confirm' then
        Config.Data[location] = nil

        TriggerServerEvent('mri_Qelevators:server:liftDeleteAndSave', Config.Data, location)

        lib.notify({
            title = "Elevador Excluído",
            description = "O elevador '" .. location .. "' foi excluído com sucesso",
            type = "success"
        })
    else
        lib.notify({
            title = 'Operação Cancelada',
            description = 'Exclusão do elevador cancelada',
            type = 'info'
        })
        liftOptions(location)
    end
end

function editFloorPassword(elevatorName, floor)
    local input = lib.inputDialog('Editar Senha do Andar', {{
        type = 'input',
        label = 'Senha',
        placeholder = 'Deixe vazio para remover a senha',
        required = false,
        default = floor.password or '',
        description = 'Digite uma senha para proteger o acesso a este andar. Deixe vazio para permitir acesso livre.'
    }})

    if not input then return floorOptions(elevatorName, floor) end

    local password = input[1] and tostring(input[1]) or ''
    
    TriggerServerEvent('mri_Qelevators:server:updateFloorPassword', elevatorName, floor.label, password)

    SetTimeout(1000, function()
        liftOptions(elevatorName)
    end)
end

return {
    liftList = liftList,
    liftOptions = liftOptions,
    floorOptions = floorOptions,
    editFloor = editFloor,
    editFloorPassword = editFloorPassword,
    moveFloor = moveFloor,
    deleteFloor = deleteFloor,
    changeNameElevator = changeNameElevator,
    addFloorToElevator = addFloorToElevator,
    teleportElevator = teleportElevator,
    deleteElevator = deleteElevator
} 