QBCore = exports['qbr-core']:GetCoreObject()
camera = -1
isNewPlayer = false
local staticClothingRoom = vector4(-767.76, -1295.21, 43.84, 286.88)

BeforePosition = nil

SkinData = {}
ClothesData = {}
PreviousSkinData = {}
PreviousClothesData = {}
PreviewSkinData = {}
PreviewClothesData = {}

Skins = {}
Skins.Male = {}
Skins.Female = {}
Clothes = {}
Clothes.Male = {}
Clothes.Female = {}

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    if NetworkIsInTutorialSession() then
        NetworkEndTutorialSession()
        print('Removing from session')
    end
end)

RegisterNetEvent('qbr-clothing:client:newPlayer', function()
    SetEntityVisible(PlayerPedId(), true)
    SetEntityHeading(PlayerPedId(), 105.68)
    isNewPlayer = true
    openMenu(true, true, true)
end)

CreateThread(function()
    while true do
        local sleep = 1000
        if isNewPlayer then
            sleep = 0
            DrawLightWithRange(-558.71 - 5.0, -3781.6 - 5.0, 238.6 + 1.0, 255, 255, 204, 50.5, 50.0)
        end
        Wait(sleep)
    end
end)

CreateThread(function()
    for k,v in pairs(Config.Stores) do
        if Config.Stores[k].shopType == "clothing" then
            exports['qbr-prompts']:createPrompt(v.name, v.coords, 0xCEFD9220, 'Open Clothing Menu', {
                type = 'client',
                event = 'qbr-clothing:client:openMenu',
                args = { false, true, false },
            })
            local clothingShop = N_0x554d9d53f696d002(1664425300, Config.Stores[k].coords)
            SetBlipSprite(clothingShop, 1195729388, 1)
            SetBlipScale(clothingShop, 0.7)
            Citizen.InvokeNative(0x9CB1A1623062F402, blip, "Clothing store")
        elseif Config.Stores[k].shopType == "outfits" then
            exports['qbr-prompts']:createPrompt(v.name, v.coords, 0xF3830D8E, 'Open Outfits Menu', {
                type = 'client',
                event = 'qbr-clothing:client:openOutfits',
                args = { false, true, false },
            })
        end

    end
end)

RegisterNetEvent('qbr-clothing:client:openMenu', function(skinsMenu, clothesMenu, new)
    openMenu(skinsMenu, clothesMenu, new)
end)

RegisterNetEvent('qbr-clothing:client:openOutfits', function()
    openOutfitsMenu()
end)

CreateThread(function()
    for _,v in pairs(cloth_hash_names) do
        if v.category_hashname == "heads"
                or v.category_hashname == "eyes"
                or v.category_hashname == "teeth"
                or v.category_hashname == "BODIES_UPPER"
                or v.category_hashname == "BODIES_LOWER"
                or v.category_hashname == "beard"
                or v.category_hashname == "hair" then
            if v.ped_type == 'male' and v.hashname ~= "" and v.is_multiplayer then
                if not Skins.Male[v.category_hashname] then
                    Skins.Male[v.category_hashname] = {}
                end
                Skins.Male[v.category_hashname][#Skins.Male[v.category_hashname]+1] = v.hash
            elseif v.ped_type == 'female' and v.hashname ~= "" and v.is_multiplayer then
                if not Skins.Female[v.category_hashname] then
                    Skins.Female[v.category_hashname] = {}
                end
                Skins.Female[v.category_hashname][#Skins.Female[v.category_hashname]+1] = v.hash
            end
        else
            if v.ped_type == "male" and v.is_multiplayer and v.category_hashname ~= "" then
                if not Clothes.Male[v.category_hashname] then
                    Clothes.Male[v.category_hashname] = {}
                end
                Clothes.Male[v.category_hashname][#Clothes.Male[v.category_hashname]+1] = v.hash
            elseif v.ped_type == "female" and v.is_multiplayer and v.category_hashname ~= "" then
                if not Clothes.Female[v.category_hashname] then
                    Clothes.Female[v.category_hashname] = {}
                end
                Clothes.Female[v.category_hashname][#Clothes.Female[v.category_hashname]+1] = v.hash
            end
        end
    end
end)

function getSkinMaxValues()
    local sex = IsPedMale(PlayerPedId()) and 'Male' or 'Female'
    local skins = {}
    skins.overlays = {}
    for k,v in pairs(Skins[sex]) do
        if (k ~= 'BODIES_UPPER' and k ~= 'BODIES_LOWER') then
            if (SkinData[k]) then
                skins[#skins+1] = {name = k or 'unnamed', minValue = 0, maxValue = #v, currentValue = SkinData[k]}
            else
                skins[#skins+1] = {name = k or 'unnamed', minValue = 0, maxValue = #v, currentValue = 0}
            end
        end
    end

    if (SkinData.skin) then
        skins[#skins+1] = {name = 'skin', minValue = 0, maxValue = 6, currentValue = SkinData.skin}
    else
        skins[#skins+1] = {name = 'skin', minValue = 0, maxValue = 6, currentValue = 0}
    end

    for k,v in pairs(Config.Features) do
        if (SkinData[k]) then
            skins[#skins+1] = {name = k or 'unnamed', minValue = -100, maxValue = 100, currentValue = SkinData[k]}
        else
            skins[#skins+1] = {name = k or 'unnamed', minValue = -100, maxValue = 100, currentValue = 0}
        end
    end

    if #skins > 0 then
        return skins
    end
    return false
end

function getClothesMaxValues()
    local sex = IsPedMale(PlayerPedId()) and 'Male' or 'Female'
    local clothes = {}
    for k,v in pairs(Clothes[sex]) do
        if (ClothesData[k]) then
            clothes[#clothes+1] = {name = k or 'unnamed', minValue = 0, maxValue = #v, currentValue = ClothesData[k]}
        else
            clothes[#clothes+1] = {name = k or 'unnamed', minValue = 0, maxValue = #v, currentValue = 0}
        end
    end

    if #clothes > 0 then
        return clothes
    end

    return false
end

RegisterCommand('openMenu', function()
    openMenu(true, true)
end)

function openOutfitsMenu()
    QBCore.Functions.TriggerCallback('qbr-clothing:server:getOutfits', function(outfits)
        SendNUIMessage({
            type = 'setOutfits',
            data = outfits
        })
        SetNuiFocus(true, true)
    end)
end

function openMenu(skinMenu, clothesMenu, new)
    --TODO Refactor this code
    if new then
        local skins = getSkinMaxValues()
        local clothes = getClothesMaxValues()
        SendNUIMessage({
            type = 'setNew',
            data = {skins = skins, clothes = clothes}
        })
    elseif skinMenu and not clothesMenu then
        local skins = getSkinMaxValues()
        SendNUIMessage({
            type = 'setSkins',
            data = skins
        })
    elseif not skinMenu and clothesMenu then
        clothingRoomTransition(staticClothingRoom, true)
        local clothes = getClothesMaxValues()
        SendNUIMessage({
            type = 'setClothes',
            data = clothes
        })
    elseif skinMenu and clothesMenu then
        local skins = getSkinMaxValues()
        local clothes = getClothesMaxValues()
        SendNUIMessage({
            type = 'setBoth',
            data = {skins = skins, clothes = clothes}
        })
    end
    SetNuiFocus(true, true)
    SetCursorLocation(0.9, 0.25)
    FreezeEntityPosition(PlayerPedId(), true)
    enableCam()
end

function clothingRoomTransition(coords, makeInvisible)
    if makeInvisible then
        if not NetworkIsInTutorialSession() then
            NetworkStartSoloTutorialSession()
            print('adding to session')
        end
    else
        if (NetworkIsInTutorialSession()) then
            NetworkEndTutorialSession()
            print('removing from session')
        end
    end
    local pedCoords = GetEntityCoords(PlayerPedId(), true)
    local heading = GetEntityHeading(PlayerPedId())
    BeforePosition = vector4(pedCoords.x, pedCoords.y, pedCoords.z, heading)
    DoScreenFadeOut(1000)
    while IsScreenFadingOut() do
        Wait(10)
    end
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z - 1.0)
    SetEntityHeading(PlayerPedId(), coords.w or 0.0)
    Wait(1000)
    DoScreenFadeIn(1000)
    while IsScreenFadingIn() do
        Wait(10)
    end
end

function enableCam()
    -- Camera
    local coords = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0, 2.0, 0)
    RenderScriptCams(false, false, 0, 1, 0)
    DestroyCam(camera, false)
    if not DoesCamExist(camera) then
        camera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        SetCamActive(camera, true)
        RenderScriptCams(true, false, 0, true, true)
        SetCamCoord(camera, coords.x, coords.y, coords.z + 0.5)
        SetCamRot(camera, 0.0, 0.0, GetEntityHeading(PlayerPedId()) + 180)
    end

    if customCamLocation then
        SetCamCoord(camera, customCamLocation.x, customCamLocation.y, customCamLocation.z)
    end
end

function disableCam()
    RenderScriptCams(false, true, 250, 1, 0)
    DestroyCam(camera, false)
    SetNuiFocus(false, false)
    FreezeEntityPosition(PlayerPedId(), false)
end

function RequestAndSetModel(model)
    local requestedModel = GetHashKey(model)
    RequestModel(requestedModel)
    while not HasModelLoaded(requestedModel) do
        Wait(0)
    end
    Wait(200)
    Citizen.InvokeNative(0xED40380076A31506, PlayerId(), requestedModel, false)
    Citizen.InvokeNative(0x77FF8D35EEC6BBC4, PlayerPedId(), 0, 0)
    Wait(200)
    Citizen.InvokeNative(0xD710A5007C2AC539, PlayerPedId(), 0x1D4C528A, 0)
    Citizen.InvokeNative(0xD710A5007C2AC539, PlayerPedId(), 0x3F1F01E5, 0)
    Citizen.InvokeNative(0xD710A5007C2AC539, PlayerPedId(), 0xDA0E2C55, 0)
end

exports('RequestAndSetModel', RequestAndSetModel)

AddEventHandler('onResourceStart', function(resource)
    if GetCurrentResourceName() == resource then
        disableCam()
        DestroyAllCams(true)
    end
end)
