print(' ')
print('^1  ::::::::::::::::::::::::::::::::::::::::::::::::::::::::^0')
print('^1  ::  FRAKTION MANAGER: FiveM Integration geladen       ::^0')
print('^1  ::::::::::::::::::::::::::::::::::::::::::::::::::::::::^0')
print(' ')

local dashboardOpen = false

local function closeDashboard()
    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)
    dashboardOpen = false
end

RegisterCommand('fmdashboard', function()
    if dashboardOpen then
        closeDashboard()
        return
    end
    SetNuiFocus(true, true)
    Citizen.Wait(100)
    SendNUIMessage({ action = 'open' })
    dashboardOpen = true
end, false)

RegisterNUICallback('closeDashboard', function(_, cb)
    SetNuiFocus(false, false)
    dashboardOpen = false
    cb('ok')
end)

RegisterNUICallback('requestIngameToken', function(_, cb)
    TriggerServerEvent('fraktionmanager:requestIngameToken')
    cb('ok')
end)

RegisterNetEvent('fraktionmanager:ingameTokenReady')
AddEventHandler('fraktionmanager:ingameTokenReady', function(token, url)
    if token and url then
        SendNUIMessage({ action = 'ingameToken', token = token, url = url })
    else
        SendNUIMessage({ action = 'ingameTokenError' })
    end
end)
