ESX = nil
local playerOilwell = nil
local playerBlip = nil
local blips = {}
local ESX = nil

local oilwellBlips = {}

function CreateOilwellBlips()
    for oilwellName, oilwellData in pairs(Config.Oilwells) do
        local blip = AddBlipForCoord(oilwellData.coords.x, oilwellData.coords.y, oilwellData.coords.z)
        SetBlipSprite(blip, 365)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 1)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Oilwell")
        EndTextCommandSetBlipName(blip)

        table.insert(oilwellBlips, blip)
    end
end

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
		CreateOilwellBlips()
    end
end)

local inMarker = false
local currentMarker = nil

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        local playerCoords = GetEntityCoords(PlayerPedId())
        local isInMarker = false
        local currentOilwell = nil

        for oilwellName, oilwellData in pairs(Config.Oilwells) do
            local distance = #(playerCoords - vector3(oilwellData.coords.x, oilwellData.coords.y, oilwellData.coords.z))

            if distance < Config.DrawDistance then
                DrawMarker(1, oilwellData.coords.x, oilwellData.coords.y, oilwellData.coords.z, 0, 0, 0, 0, 0, 0, 1.5, 1.5, 1.0, oilwellData.color.r, oilwellData.color.g, oilwellData.color.b, 100, false, true, 2, false, false, false, false)

                if distance < 1.5 then
                    isInMarker = true
                    currentOilwell = oilwellName
                end
            end
        end

        if isInMarker and not menuOpen then
            ESX.ShowHelpNotification("Press ~INPUT_CONTEXT~ to interact with the oilwell.")

            if IsControlJustReleased(0, 38) then
                ESX.TriggerServerCallback('esx_oilwells:getOilwellOwner', function(identifier)
                    if identifier == ESX.GetPlayerData().identifier then
                        OpenOilwellMenu(currentOilwell)
                    else
                        ESX.ShowNotification("~r~You do not own this oil well.")
                    end
                end, currentOilwell)
            end
        end

        if not isInMarker and menuOpen then
            ESX.UI.Menu.CloseAll()
            menuOpen = false
        end
    end
end)

function OpenOilwellMenu(oilwellName)
    local menuOpen = true
    local menu = nil

    local function RefreshMenu()
        ESX.TriggerServerCallback('esx_oilwells:getMoneyGenerated', function(moneyGenerated)
            local elements = {
                {label = "Claim Money", value = "claim_money"},
                {label = "Money Generated: $" .. moneyGenerated, value = "money_generated"}
            }

            if menu then
                menu.setElementItems(elements)
                menu.update()
            else
                ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'oilwell_menu', {
                title = "Oilwell - " .. oilwellName,
                align = 'center',
                elements = elements
                }, function(data, _menu)
                if data.current.value == 'claim_money' then
                 ESX.TriggerServerCallback('esx_oilwells:claimMoney', function(success)
            if success then
                ESX.ShowNotification("~y~You have claimed your oilwell money.")
            else
                ESX.ShowNotification("An error occurred while claiming your money!")
            end
        end, oilwellName)
        _menu.close()
       end
         end, function(data, _menu)
            menuOpen = false
            _menu.close()
            menu = nil
        end)
                menu = ESX.UI.Menu.GetOpened(GetCurrentResourceName(), 'oilwell_menu')
            end
        end, oilwellName)
    end

    RefreshMenu()
end



