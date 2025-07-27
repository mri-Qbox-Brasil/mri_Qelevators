local Utils = require('client.utils')

local addedFloor = {}
local isCreatingLift = false
local onStopCallback = nil
local debugZone = nil
local currentDebugSize = 2

local function showHelpText()
    local helpText = {
        '**Criador de Elevador**  \n',
        '[Y] Adicionar Andar  \n',
        '[Enter] Salvar  \n',
        '[Backspace] Cancelar  \n',
        '[SCROLL] Ajustar Tamanho  \n',
    }
    
    lib.showTextUI(table.concat(helpText), {
        icon = 'fa-edit',
        iconAnimation = 'bounce'
    })
end

local function addFloorToCreator()
    local playerpos = GetEntityCoords(cache.ped)
    local playerhead = GetEntityHeading(cache.ped)
    local input = lib.inputDialog('Criador de Elevador', {{
        type = 'input',
        label = 'Nome',
        placeholder = '1st Floor',
        required = true
    }, {
        type = 'number',
        label = 'Tamanho',
        placeholder = tostring(currentDebugSize),
        default = currentDebugSize,
        required = false
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
        placeholder = 'police'
    },{
        type = 'input',
        label = 'Gang (Opcional)',
        placeholder = 'ballas'
    }})

    if not input then
        return
    end

    local sizeValue = input[2] or 2
    local size = {
        x = sizeValue,
        y = sizeValue,
        z = sizeValue
    }
    
    currentDebugSize = sizeValue

    addedFloor[#addedFloor + 1] = {
        label = input[1],
        coords = playerpos,
        rot = playerhead,
        size = size,
        car = input[3] or false,
        job = input[4] or '',
        gang = input[5] or ''
    }
    
    lib.notify({
        title = "Andar Adicionado",
        description = "Andar '" .. input[1] .. "' adicionado com sucesso",
        type = "success"
    })
end

local function onFinishAction()
    local input = lib.inputDialog('Config Creator', {{
        type = 'input',
        label = 'Nome do Elevador',
        placeholder = 'Delegacia',
        required = true
    }})

    if not input then
        return
    end
    local label = input[1]:gsub(' ', '_')

    if Config.Data[label] then
        lib.notify({
            title = "Erro",
            description = "Já existe um elevador com o nome '" .. input[1] .. "'",
            type = "error"
        })
        onFinishAction()
        return
    end

    if #addedFloor == 0 then
        lib.notify({
            title = "Erro",
            description = "Você precisa adicionar pelo menos um andar antes de criar o elevador",
            type = "error"
        })
        SetTimeout(1500, function()
            if onStopCallback then
                onStopCallback()
            end
        end)
        return
    end

    local finalLift = {
        [label] = addedFloor
    }

    TriggerServerEvent('mri_Qelevators:server:liftCreatorSave', finalLift)
    addedFloor = {}
    currentDebugSize = 2
    
    SetTimeout(1500, function()
        if onStopCallback then
            onStopCallback()
        end
    end)
end

local function stopCreating()
    isCreatingLift = false
    lib.hideTextUI()
    addedFloor = {}
    currentDebugSize = 2
    
    if onStopCallback then
        onStopCallback()
    end
end

local function createLiftThread()
    while isCreatingLift do
        if not lib.isTextUIOpen() then
            showHelpText()
        end
        
        local playerpos = GetEntityCoords(cache.ped)
        local playerhead = GetEntityHeading(cache.ped)
        Utils.DrawBox3D(playerpos.x, playerpos.y, playerpos.z, currentDebugSize, playerhead)
        
        local debugText = string.format('Tamanho: %.fx%.fx%.f | Andares: %d', 
            currentDebugSize, currentDebugSize, currentDebugSize, #addedFloor)
        Utils.DrawText3D(playerpos.x, playerpos.y, playerpos.z + 1.0, debugText)
        
        local wheelUp = IsControlJustPressed(0, 96) -- Roda do mouse para cima
        local wheelDown = IsControlJustPressed(0, 97) -- Roda do mouse para baixo
        
        if wheelUp then
            currentDebugSize = currentDebugSize + 1
            if currentDebugSize > 100 then -- Limite máximo
                currentDebugSize = 100
            end
        elseif wheelDown then
            currentDebugSize = currentDebugSize - 1
            if currentDebugSize < 2 then -- Limite mínimo
                currentDebugSize = 2
            end
        end
        
        if IsControlJustPressed(0, 246) then -- Y
            addFloorToCreator()
        elseif IsControlJustPressed(0, 194) then -- Backspace
            stopCreating()
        elseif IsControlJustPressed(0, 201) then -- Enter
            isCreatingLift = false
            lib.hideTextUI()
            onFinishAction()
        end
        Wait(0)
    end
end

local function confirmStopCreating()
    local alert = lib.alertDialog({
        icon = 'warning',
        header = 'Aviso',
        content = 'Você ainda está criando um elevador, CONFIRME para DESATIVAR',
        centered = true,
        cancel = true
    })
    if alert == 'confirm' then
        stopCreating()
    end
end

local function startLiftCreator(cb)
    onStopCallback = cb
    if not isCreatingLift then
        if cb then
            cb()
        end
    else
        confirmStopCreating()
    end
end

local function liftCreation(cb)
    onStopCallback = cb
    if not isCreatingLift then
        isCreatingLift = true
        showHelpText()
        createLiftThread()
    else
        confirmStopCreating()
    end
end

return {
    startLiftCreator = startLiftCreator,
    liftCreation = liftCreation,
    stopCreating = stopCreating
} 