lib.addCommand('elevador', {
    help = 'Abrir menu do sistema de elevadores',
    restricted = Config.Permissions
}, function(source, args, raw)
    print('^2[DEBUG] Comando /elevador executado por: ' .. source .. '')
    TriggerClientEvent('mri_Qelevators:client:startLiftCreator', source)
end)