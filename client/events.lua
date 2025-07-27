local QBCore = exports['qb-core']:GetCoreObject()

local elevator = require('client.elevator')
local menu = require('client.menu')
local creator = require('client.creator')

RegisterNetEvent('mri_Qelevators:client:lift', function(data)
    elevator.showLiftMenu(data)
end)

RegisterNetEvent('mri_Qelevators:client:startLiftCreator', function()
    local isAdmin = lib.callback.await('mri_Qelevators:server:isAdmin', false)
    if not isAdmin then return end
    creator.startLiftCreator(menu.liftList)
end)

RegisterNetEvent('mri_Qelevators:client:updateElevators', function(elevators)
    if type(elevators) ~= "table" then
        print('^1[ERROR] Dados recebidos não são uma tabela válida')
        return
    end
    Config.Data = elevators
    elevator.init()
end)

RegisterNetEvent('mri_Qelevators:client:creatorError', function()
    local creator = require('client.creator')
    if creator and creator.stopCreating then
        creator.stopCreating()
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    elevator.cleanupZones()
end)

AddStateBagChangeHandler('mri_Qelevators_data', 'global', function(bagname, key, value)
    if value and type(value) == "table" then
        Config.Data = value
        elevator.init()
    end
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= cache.resource then
        return
    end
    Wait(5000)
    if Config.Data and next(Config.Data) ~= nil then
        elevator.init()
    else
        TriggerServerEvent('mri_Qelevators:server:requestElevators')
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then
        return
    end
    elevator.cleanupZones()
end) 