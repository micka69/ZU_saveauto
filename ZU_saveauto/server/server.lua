ESX = exports["es_extended"]:getSharedObject()

-- Fonction pour tester la connexion à la base de données
local function testDatabaseConnection()
    MySQL.Async.fetchAll('SELECT 1', {}, function(result)
        if result then
            print("[DEBUG] Server: Test de connexion à la base de données réussi")
        else
            print("[DEBUG] Server: Échec du test de connexion à la base de données")
        end
    end)
end

-- Fonction pour vérifier la structure de la table
local function checkTableStructure()
    MySQL.Async.fetchAll('SHOW COLUMNS FROM users', {}, function(result)
        if result then
            print("[DEBUG] Server: Structure de la table users:")
            for i, column in ipairs(result) do
                print("  - " .. column.Field .. " (" .. column.Type .. ")")
            end
        else
            print("[DEBUG] Server: Impossible de récupérer la structure de la table users")
        end
    end)
end

-- Fonction pour sauvegarder la position
local function savePosition(identifier, coords, cb)
    local positionJson = json.encode(coords)
    MySQL.Async.execute('UPDATE users SET position = @position WHERE identifier = @identifier', {
        ['@position'] = positionJson,
        ['@identifier'] = identifier
    }, function(rowsChanged)
        print("[DEBUG] Server: Tentative de mise à jour pour " .. identifier .. ", lignes affectées: " .. rowsChanged)
        if rowsChanged > 0 then
            cb(true)
        else
            -- Si la mise à jour échoue, essayons une insertion
            MySQL.Async.execute('INSERT INTO users (identifier, position) VALUES (@identifier, @position) ON DUPLICATE KEY UPDATE position = @position', {
                ['@identifier'] = identifier,
                ['@position'] = positionJson
            }, function(insertRowsChanged)
                print("[DEBUG] Server: Tentative d'insertion/mise à jour pour " .. identifier .. ", lignes affectées: " .. insertRowsChanged)
                cb(insertRowsChanged > 0)
            end)
        end
    end)
end

-- Événement pour sauvegarder la position du joueur
RegisterServerEvent('savePlayerPosition')
AddEventHandler('savePlayerPosition', function(coords)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    
    if xPlayer then
        local identifier = xPlayer.getIdentifier()
        print("[DEBUG] Server: Tentative de sauvegarde pour " .. identifier)
        
        savePosition(identifier, coords, function(success)
            if success then
                print("[DEBUG] Server: Sauvegarde réussie pour " .. identifier)
                TriggerClientEvent('savePosition:notify', _source, true)
            else
                print("[DEBUG] Server: Échec de la sauvegarde pour " .. identifier)
                TriggerClientEvent('savePosition:notify', _source, false)
            end
        end)
    else
        print("[DEBUG] Server: Impossible de récupérer le joueur pour l'ID " .. _source)
    end
end)

-- Exécuter les tests au démarrage du script
Citizen.CreateThread(function()
    Citizen.Wait(5000) -- Attendre 5 secondes pour s'assurer que tout est initialisé
    print("[DEBUG] Server: Démarrage des tests de base de données")
    testDatabaseConnection()
    checkTableStructure()
end)