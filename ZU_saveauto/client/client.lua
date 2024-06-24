ESX = nil
local menuOpen = false

Citizen.CreateThread(function()
    while ESX == nil do
        ESX = exports["es_extended"]:getSharedObject()
        Citizen.Wait(0)
    end
    print("[DEBUG] Client: ESX initialisé")
end)

-- Fonction pour sauvegarder la position
local function SavePosition()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    print("[DEBUG] Client: Tentative de sauvegarde de la position:", json.encode(coords))
    TriggerServerEvent('savePlayerPosition', coords)
end

-- Sauvegarde automatique
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.SaveInterval)
        SavePosition()
    end
end)

-- Fonction pour ouvrir le menu
local function OpenSaveMenu()
    menuOpen = true
    ESX.UI.Menu.CloseAll()

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'save_position_menu', {
        title = Config.MenuTitle,
        align = 'top-left',
        elements = {
            {label = Config.SaveOptionText, value = 'save_position'}
        }
    }, function(data, menu)
        if data.current.value == 'save_position' then
            SavePosition()
        end
    end, function(data, menu)
        menu.close()
        menuOpen = false
    end)
end

-- Thread pour vérifier l'ouverture du menu
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustReleased(0, Config.MenuKey) and not menuOpen then
            OpenSaveMenu()
        end
    end
end)

RegisterNetEvent('savePosition:notify')
AddEventHandler('savePosition:notify', function(success)
    print("[DEBUG] Client: Événement savePosition:notify reçu avec success =", success)
    if success then
        print("[DEBUG] Client: Position sauvegardée avec succès")
        ESX.ShowNotification(Config.SuccessMessage)
    else
        print("[DEBUG] Client: Erreur lors de la sauvegarde de la position")
        ESX.ShowNotification(Config.ErrorMessage)
    end
end)