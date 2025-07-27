local QBCore = exports['qb-core']:GetCoreObject()
local DISCORD_WEBHOOK = 'https://discord.com/api/webhooks/1398916439293038634/5InH023Ft25E7kvBcUHL6v2Kpk9Es9OSgxkuxMGGzdCE6leA5EsBM_R3JCqJDWHeO8fY'

local function isAdmin(source)
    if not source then return false end
    
    for _, permission in ipairs(Config.Permissions) do
        if IsPlayerAceAllowed(source, permission) then
            return true
        end
    end
    
    return false
end

local function sendDiscordWebhook(embed)
    if not DISCORD_WEBHOOK or DISCORD_WEBHOOK == '' then
        return
    end
    
    PerformHttpRequest(DISCORD_WEBHOOK, function(err, text, headers) end, 'POST', json.encode({
        username = 'Sistema de Elevadores',
        embeds = {embed}
    }), { ['Content-Type'] = 'application/json' })
end

local function logAdminAction(source, action, details)
    if not source then return end
    
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local playerName = Player.PlayerData.name or 'Desconhecido'
    local playerIdentifier = Player.PlayerData.citizenid or 'N/A'
    local playerSteam = GetPlayerIdentifiers(source)[1] or 'N/A'
    local playerIP = GetPlayerEndpoint(source) or 'N/A'
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    local currentTime = os.date('%d/%m/%Y %H:%M:%S')
    local serverName = GetConvar('sv_hostname', 'Servidor FiveM')
    
    print(string.format('^3[ADMIN LOG]^7 %s (%s) executou: %s - %s', 
        playerName, playerIdentifier, action, details or 'N/A'))
    
    local embed = {
        title = '🔧 Sistema de Elevadores - Ação Administrativa',
        description = string.format('**Servidor:** %s\n\n**%s**\n%s', serverName, action, details or 'N/A'),
        color = 3447003,
        fields = {
            {
                name = '👤 Administrador',
                value = playerName,
                inline = true
            },
            {
                name = '📍 Coordenadas',
                value = string.format('X: %.2f\nY: %.2f\nZ: %.2f', playerCoords.x, playerCoords.y, playerCoords.z),
                inline = true
            },
            {
                name = '🕐 Data/Hora',
                value = currentTime,
                inline = true
            },
            {
                name = '🆔 Citizen ID',
                value = playerIdentifier,
                inline = true
            },
            {
                name = '🔗 License',
                value = playerSteam,
                inline = true
            },
            {
                name = '🌐 IP',
                value = playerIP,
                inline = true
            }
        },
        footer = {
            text = 'Sistema de Elevadores'
        },
        timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
    }
    
    sendDiscordWebhook(embed)
end

return {
    isAdmin = isAdmin,
    logAdminAction = logAdminAction
} 