local QBCore = exports['qb-core']:GetCoreObject()

RegisterCommand('queue', function()
    TriggerServerEvent('hiype-jobqueue:server:print-queue')
end, false)
