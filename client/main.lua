local ox_target = exports.ox_target
local spawnedPeds = {}

AddEventHandler('onResourceStart', function(resourceName)
    ox_target:addModel(Config.atmModels, {
        {
            label = "Use ATM",
            icon = "fa-solid fa-money-bill-wave",
            distance = 1.5,
            canInteract = function(entity, distance, coords, name, bone)
                return true
            end,
            onSelect = function(data)
                SetNuiFocus(true, true)
                SendNUIMessage({ openNUI = true })
            end
        }
    })
end)

local function createBlip(location, name)
    local blip = AddBlipForCoord(location.x, location.y, location.z)
    SetBlipSprite(blip, 280)
    SetBlipColour(blip, 3)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(name)
    EndTextCommandSetBlipName(blip)
    return blip
end

local function spawnPed(location, name, pedModel)
    lib.requestModel(pedModel, 50000)
    local ped = CreatePed(4, GetHashKey(pedModel), location.x, location.y, location.z - 1.0, location.w, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetModelAsNoLongerNeeded(pedModel)

    ox_target:addLocalEntity(ped, {
        {
            name = name .. "_interaction",
            label = "Interact",
            icon = "fas fa-comment",
            distance = 2.5,
            onSelect = function()
                TriggerEvent("qtm:client:openPedMenu")
            end
        }
    })

    spawnedPeds[name] = ped
    return ped
end

for name, location in pairs(Config.BankLocations) do
    createBlip(location, name)
    lib.points.new({
        coords = vector3(location.x, location.y, location.z),
        radius = 10.0,
        onEnter = function()
            if Config.BankLocations[name] then
                spawnPed(location, name, Config.BankPed)
            end
        end,
        onExit = function()
            if spawnedPeds[name] then
                DeleteEntity(spawnedPeds[name])
                ox_target:removeLocalEntity(spawnedPeds[name])
            end
        end
    })
end

RegisterNUICallback('getCCData', function(data, cb)
    local ccData = lib.callback.await("qtm:server:awaitccData", false)
    cb(ccData and { success = true, ccData = ccData } or { success = false, message = "Failed to fetch credit card data." })
end)

RegisterNUICallback('getBalance', function(data, cb)
    local balance = lib.callback.await("qtm:server:awaitBalance", false)
    cb(balance and { success = true, balance = balance } or { success = false, message = "Failed to fetch balance." })
end)

RegisterNUICallback('history', function(data, cb)
    local history = lib.callback.await("qtm:server:awaitHistory", false)
    cb(history and { success = true, history = history } or { success = false, message = "Failed to fetch history." })
end)

RegisterNUICallback('deposit', function(data, cb)
    local amount = tonumber(data.amount)
    local newBalance = lib.callback.await("qtm:server:awaitDeposit", false, amount)
    cb(newBalance and { success = true, newBalance = newBalance } or { success = false, message = "Invalid amount" })
end)

RegisterNUICallback('withdraw', function(data, cb)
    local amount = tonumber(data.amount)
    local newBalance = lib.callback.await("qtm:server:awaitWithdrawal", false, amount)
    cb(newBalance and { success = true, newBalance = newBalance } or { success = false, message = "Invalid amount" })
end)
