local database = require('server.database')
local utils = require('server.utils')
local QBCore = exports['qb-core']:GetCoreObject()

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then
        return
    end
    
    Wait(1000)
    
    database.createElevatorTable()
    database.importLiftLuaToDB()
    
    local data = database.fetchAllElevators()
    if data and type(data) == 'table' then
        Config.Data = data
        GlobalState.mri_Qelevators_data = Config.Data
        print('^2[SUCCESS] Elevadores carregados com sucesso!')
    else
        print('^1[ERROR] Falha ao carregar dados dos elevadores')
        Config.Data = {}
        GlobalState.mri_Qelevators_data = {}
    end
end)

RegisterNetEvent('mri_Qelevators:server:requestElevators', function()
    if Config.Data and next(Config.Data) and source then
        TriggerClientEvent('mri_Qelevators:client:updateElevators', source, Config.Data)
    end
end)

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    if Config.Data and next(Config.Data) then
        TriggerClientEvent('mri_Qelevators:client:updateElevators', source, Config.Data)
    end
end)

RegisterNetEvent('mri_Qelevators:server:liftCreatorSave', function(data)
    if not utils.isAdmin(source) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Acesso Negado',
            description = 'Você não tem permissão para criar elevadores',
            type = 'error'
        })
        return
    end
    
    for elevatorName, _ in pairs(data) do
        if Config.Data[elevatorName] then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Erro',
                description = 'Já existe um elevador com o nome "' .. elevatorName .. '"',
                type = 'error'
            })
            TriggerClientEvent('mri_Qelevators:client:creatorError', source)
            return
        end
    end
    
    for elevatorName, floors in pairs(data) do
        local usedLabels = {}
        for _, floor in ipairs(floors) do
            if usedLabels[floor.label] then
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Erro',
                    description = 'Andar "' .. floor.label .. '" duplicado no elevador "' .. elevatorName .. '"',
                    type = 'error'
                })
                TriggerClientEvent('mri_Qelevators:client:creatorError', source)
                return
            end
            usedLabels[floor.label] = true
        end
    end
    
    for k, v in pairs(data) do
        for _, j in ipairs(v) do
            database.insertElevator(k, j)
        end
    end
    for k, v in pairs(data) do Config.Data[k] = v end
    GlobalState.mri_Qelevators_data = Config.Data
    
    utils.logAdminAction(source, 'Criar Elevador', 'Criou elevador: ' .. next(data))
    
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Sucesso',
        description = 'Elevador criado com sucesso!',
        type = 'success'
    })
end)

RegisterNetEvent('mri_Qelevators:server:liftDeleteAndSave', function(data, elevatorToDelete)
    if not utils.isAdmin(source) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Acesso Negado',
            description = 'Você não tem permissão para excluir elevadores',
            type = 'error'
        })
        return
    end
    
    database.deleteElevator(elevatorToDelete)
    if Config.Data[elevatorToDelete] then Config.Data[elevatorToDelete] = nil end
    GlobalState.mri_Qelevators_data = Config.Data
    
    utils.logAdminAction(source, 'Excluir Elevador', 'Excluiu elevador: ' .. elevatorToDelete)
end)

lib.callback.register('mri_Qelevators:server:renameElevator', function(source, oldName, newName)
    if not utils.isAdmin(source) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Acesso Negado',
            description = 'Você não tem permissão para renomear elevadores',
            type = 'error'
        })
        return false
    end
    
    if Config.Data[newName] then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Erro',
            description = 'Já existe um elevador com o nome "' .. newName .. '"',
            type = 'error'
        })
        return false
    end
    
    database.updateElevatorName(oldName, newName)
    if Config.Data[oldName] then Config.Data[newName] = Config.Data[oldName]; Config.Data[oldName] = nil end
    GlobalState.mri_Qelevators_data = Config.Data
    
    utils.logAdminAction(source, 'Renomear Elevador', 'Renomeou de "' .. oldName .. '" para "' .. newName .. '"')
    
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Sucesso',
        description = 'Elevador renomeado de "' .. oldName .. '" para "' .. newName .. '"',
        type = 'success'
    })
    
    return true
end)

RegisterNetEvent('mri_Qelevators:server:addFloorToElevator', function(elevatorName, floorData)
    if not utils.isAdmin(source) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Acesso Negado',
            description = 'Você não tem permissão para adicionar andares',
            type = 'error'
        })
        return
    end
    
    if Config.Data[elevatorName] then
        for _, floor in ipairs(Config.Data[elevatorName]) do
            if floor.label == floorData.label then
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Erro',
                    description = 'Já existe um andar com o nome "' .. floorData.label .. '" neste elevador',
                    type = 'error'
                })
                return
            end
        end
    end
    
    database.insertElevator(elevatorName, floorData)
    if not Config.Data[elevatorName] then Config.Data[elevatorName] = {} end
    Config.Data[elevatorName][#Config.Data[elevatorName] + 1] = floorData
    GlobalState.mri_Qelevators_data = Config.Data
    
    utils.logAdminAction(source, 'Adicionar Andar', 'Adicionou andar "' .. floorData.label .. '" ao elevador "' .. elevatorName .. '"')
    
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Sucesso',
        description = 'Andar "' .. floorData.label .. '" adicionado ao elevador',
        type = 'success'
    })
end)

RegisterNetEvent('mri_Qelevators:server:updateFloor', function(elevatorName, oldFloorLabel, newFloorData)
    if not utils.isAdmin(source) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Acesso Negado',
            description = 'Você não tem permissão para editar andares',
            type = 'error'
        })
        return
    end
    
    if Config.Data[elevatorName] then
        for _, floor in ipairs(Config.Data[elevatorName]) do
            if floor.label == newFloorData.label and floor.label ~= oldFloorLabel then
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Erro',
                    description = 'Já existe um andar com o nome "' .. newFloorData.label .. '" neste elevador',
                    type = 'error'
                })
                return
            end
        end
    end
    
    database.updateFloor(elevatorName, oldFloorLabel, newFloorData)
    if Config.Data[elevatorName] then
        for i, floor in ipairs(Config.Data[elevatorName]) do
            if floor.label == oldFloorLabel then
                Config.Data[elevatorName][i] = newFloorData
                break
            end
        end
    end
    GlobalState.mri_Qelevators_data = Config.Data
    
    utils.logAdminAction(source, 'Atualizar Andar', 'Atualizou andar "' .. oldFloorLabel .. '" para "' .. newFloorData.label .. '" no elevador "' .. elevatorName .. '"')
    
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Sucesso',
        description = 'Andar "' .. oldFloorLabel .. '" atualizado para "' .. newFloorData.label .. '"',
        type = 'success'
    })
end)

RegisterNetEvent('mri_Qelevators:server:deleteFloor', function(elevatorName, floorLabel)
    if not utils.isAdmin(source) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Acesso Negado',
            description = 'Você não tem permissão para excluir andares',
            type = 'error'
        })
        return
    end
    
    database.deleteFloor(elevatorName, floorLabel)
    if Config.Data[elevatorName] then
        for i, floor in ipairs(Config.Data[elevatorName]) do
            if floor.label == floorLabel then table.remove(Config.Data[elevatorName], i); break end
        end
    end
    GlobalState.mri_Qelevators_data = Config.Data
    
    utils.logAdminAction(source, 'Excluir Andar', 'Excluiu andar "' .. floorLabel .. '" do elevador "' .. elevatorName .. '"')
end)

RegisterNetEvent('mri_Qelevators:server:updateFloorPassword', function(elevatorName, floorLabel, password)
    if not utils.isAdmin(source) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Acesso Negado',
            description = 'Você não tem permissão para alterar senhas',
            type = 'error'
        })
        return
    end
    
    database.updateFloorPassword(elevatorName, floorLabel, password)
    if Config.Data[elevatorName] then
        for i, floor in ipairs(Config.Data[elevatorName]) do
            if floor.label == floorLabel then
                Config.Data[elevatorName][i].password = password
                break
            end
        end
    end
    GlobalState.mri_Qelevators_data = Config.Data
    
    local action = password and password ~= '' and 'Definir Senha' or 'Remover Senha'
    local details = password and password ~= '' and 
        'Definiu senha para andar "' .. floorLabel .. '" no elevador "' .. elevatorName .. '"' or
        'Removeu senha do andar "' .. floorLabel .. '" no elevador "' .. elevatorName .. '"'
    
    utils.logAdminAction(source, action, details)
    
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Sucesso',
        description = password and password ~= '' and 
            'Senha definida para o andar "' .. floorLabel .. '"' or
            'Senha removida do andar "' .. floorLabel .. '"',
        type = 'success'
    })
end)

lib.callback.register('mri_Qelevators:server:isAdmin', function(source)
    return utils.isAdmin(source)
end)