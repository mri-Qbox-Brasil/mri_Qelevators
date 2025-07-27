local QBCore = exports['qb-core']:GetCoreObject()
local Utils = require('client.utils')
local liftZone = {}
local inZone = nil

function UseElevator(x, y, z, rot, car)
    local vehicle = car and IsPedInAnyVehicle(cache.ped) and GetVehiclePedIsIn(cache.ped) or nil
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do
        Wait(10)
    end

    local int = GetInteriorAtCoords(vec3(x, y, z))
    PinInteriorInMemory(int)
    RequestCollisionAtCoord(x, y, z)
    while not HasCollisionLoadedAroundEntity(cache.ped) do
        Wait(0)
    end

    if car and vehicle ~= nil then
        SetEntityCoords(vehicle, x, y, z, false, false, false, true)
        SetEntityHeading(vehicle, rot)
    else
        SetEntityCoords(cache.ped, x, y, z, false, false, false, false)
        SetEntityHeading(cache.ped, rot)
    end
    Wait(1000)
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "liftSoundBellRing", 0.1)
    Wait(1500)
    DoScreenFadeIn(500)
end

function createLiftZone()
    if type(Config.Data) ~= "table" then
        return
    end

    for k, v in pairs(Config.Data) do
        for _, j in ipairs(v) do
            local zone = lib.zones.box({
                name = k .. 'lift_zone',
                coords = j.coords,
                size = j.size,
                rotation = j.rot,
                debug = Config.Debug,
                onEnter = function()
                    inZone = j.label
                    local passwordIcon = j.password and j.password ~= '' and '🔒 ' or ''
                    lib.showTextUI('[E] ' .. passwordIcon .. j.label .. ' (' .. string.gsub(k, '_', ' ') .. ')', {
                        icon = 'elevator',
                        iconAnimation = 'bounce'
                    })
                end,
                onExit = function()
                    inZone = nil
                    lib.hideTextUI()
                end,
                inside = function()
                    if IsControlJustPressed(0, 51) then
                        showLiftMenu(v)
                    end
                end
            })
            liftZone[#liftZone + 1] = zone
        end
    end
end

function init()
    for i = 1, #liftZone do
        if liftZone[i] and liftZone[i].remove then
            liftZone[i]:remove()
        end
    end
    liftZone = {}
    createLiftZone()
end

function cleanupZones()
    for i = 1, #liftZone do
        if liftZone[i] and liftZone[i].remove then
            liftZone[i]:remove()
        end
    end
    liftZone = {}
end

CreateThread(function()
    while true do
        local sleep = 1000
        if Config.Debug then
            sleep = 0
            for k, v in pairs(Config.Data) do
                for _, j in ipairs(v) do
                    local elevatorName = string.gsub(k, '_', ' ')
                    local floorName = j.label
                    local heading = string.format('%.1f°', j.rot or 0)
                    local text = 'Elevador: ' .. elevatorName .. '\nAndar: ' .. floorName .. '\nHeading: ' .. heading
                    Utils.DrawText3D(j.coords.x, j.coords.y, j.coords.z + 1.0, text)
                    Utils.DrawArrow3D(j.coords.x, j.coords.y, j.coords.z, j.rot or 0)
                end
            end
        end
        Wait(sleep)
    end
end)

function showLiftMenu(data)
    local menuOptions = {}
    local playerJob = ''
    local playerGang = ''
    local playerCoords = GetEntityCoords(cache.ped)
    local Player = QBCore.Functions.GetPlayerData()
    playerJob = Player.job.name
    playerGang = Player.gang.name

    for _, v in ipairs(data) do
        local hasAccess = (v.job ~= '' and playerJob == v.job) or (v.gang ~= '' and playerGang == v.gang) or (v.job == '' and v.gang == '')
        
        if hasAccess then
            local icon = 'elevator'
            local description = ''
            
            if v.password and v.password ~= '' then
                icon = 'fa-lock'
                description = '🔒 Andar protegido por senha'
            end
            
            menuOptions[#menuOptions + 1] = {
                title = v.label,
                description = description,
                icon = icon,
                disabled = v.label == inZone,
                onSelect = function()
                    if v.password and v.password ~= '' then
                        local input = lib.inputDialog('Senha Necessária', {{
                            type = 'input',
                            label = 'Digite a senha',
                            placeholder = 'Senha do andar',
                            required = true,
                            password = true
                        }})
                        
                        if not input then return end
                        
                        local password = input[1] and tostring(input[1]) or ''
                        
                        if password == v.password then
                            lib.notify({
                                title = 'Acesso Permitido',
                                description = 'Senha correta! Aguarde um momento...',
                                type = 'success',
                                duration = 5000
                            })
                            UseElevator(v.coords.x, v.coords.y, v.coords.z, v.rot, v.car)
                        else
                            lib.notify({
                                title = 'Acesso Negado',
                                description = 'Senha incorreta!',
                                type = 'error'
                            })
                        end
                    else
                        UseElevator(v.coords.x, v.coords.y, v.coords.z, v.rot, v.car)
                    end
                end
            }
        end
    end
    lib.registerContext({
        id = 'mri_Q_lift',
        title = 'Escolha o andar',
        options = menuOptions
    })
    lib.showContext('mri_Q_lift')
end

return {
    UseElevator = UseElevator,
    createLiftZone = createLiftZone,
    init = init,
    cleanupZones = cleanupZones,
    inZone = inZone,
    showLiftMenu = showLiftMenu
} 