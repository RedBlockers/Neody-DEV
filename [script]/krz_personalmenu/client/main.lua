local PersonalMenu = {
    ItemSelected = {},
    ItemIndex = {},
    WeaponData = {},
    WalletIndex = {},
    WalletList = {i18nU('wallet_option_give'), i18nU('wallet_option_drop')},
    BillData = {},
    ClothesButtons = {'torso', 'pants', 'shoes', 'bag', 'bproof'},
    AccessoriesButtons = {'ears', 'glasses', 'helmet', 'mask'},
    DoorState = {
        FrontLeft = false,
        FrontRight = false,
        BackLeft = false,
        BackRight = false,
        Hood = false,
        Trunk = false
    },
    DoorIndex = 1,
    SeatIndex = 1,
    DoorList = {i18nU('vehicle_door_frontleft'), i18nU('vehicle_door_frontright'), i18nU('vehicle_door_backleft'), i18nU('vehicle_door_backright')},
    GPSIndex = 1,
    GPSList = {}
}
local lastSeatChangeTime = 0

PlayerVars = {
    isDead = false,
    crouched = false,
    handsup = false,
    pointing = false,
    noclip = false,
    godmode = false,
    ghostmode = false,
    showCoords = false,
    showName = false,
    group = 'user'
}

local drawContentOptions = { header = true, instructionalButton = true }
local ruiDrawContent = RageUI.DrawContent

local function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

local adminGroups = {
    ['mod'] = true,
    ['admin'] = true,
    ['superadmin'] = true,
    ['owner'] = true,
    ['_dev'] = true
}

CreateThread(function()
    if Config.Framework == 'esx' then
        while not ESX do
            Wait(100)
        end
    end
end)

for i = 1, #Config.GPS do
    PersonalMenu.GPSList[i] = Config.GPS[i].name
end

for i = 1, #Config.AdminCommands do
    local adminCommandCfg = Config.AdminCommands[i]
    local groupsById = {}

    for j = 1, #adminCommandCfg.groups do
        groupsById[adminCommandCfg.groups[j]] = true
    end

    adminCommandCfg.groupsById = groupsById
end

local mainMenu = RageUI.CreateMenu(Config.MenuTitle, i18nU('mainmenu_subtitle'), 0, 0, 'commonmenu', 'interaction_bgd', 255, 255, 255, 255)

local personalMenuCategories = {}
local personalMenuCategoriesById = {}

local function addPersonalMenuCategory(id, name, restriction)
    local menu = RageUI.CreateSubMenu(mainMenu, name)
    local pmCategory = { id = id, name = name, menu = menu, restriction = restriction }
    personalMenuCategories[#personalMenuCategories + 1] = pmCategory
    personalMenuCategoriesById[id] = pmCategory
    return pmCategory
end

local function getPersonalMenuCategory(id)
    return personalMenuCategoriesById[id]
end

addPersonalMenuCategory('wallet', i18nU('wallet_title'))
addPersonalMenuCategory('billing', i18nU('bills_title'))
addPersonalMenuCategory('clothes', i18nU('clothes_title'))
addPersonalMenuCategory('accessories', i18nU('accessories_title'))
local animationCategory = addPersonalMenuCategory('animation', i18nU('animation_title'))

addPersonalMenuCategory('vehicle', i18nU('vehicle_title'), function()
    return IsPedSittingInAnyVehicle(plyPed)
end)

addPersonalMenuCategory('boss', i18nU('bossmanagement_title'), function()
    return GetPlayerJob().isBoss
end)

if Config.DoubleJob then
    addPersonalMenuCategory('boss2', i18nU('bossmanagement2_title'), function()
        return GetPlayerJob2().isBoss
    end)
end

addPersonalMenuCategory('admin', i18nU('admin_title'), function()
    return adminGroups[PlayerVars.group] ~= nil
end)

for i = 1, #Config.Animations do
    local animationCfg = Config.Animations[i]
    animationCfg.menu = RageUI.CreateSubMenu(animationCategory.menu, animationCfg.name)
end

if Config.Framework == 'esx' then
    AddEventHandler('esx:onPlayerDeath', function()
        PlayerVars.isDead = true
        RageUI.CloseAll()
        ESX.UI.Menu.CloseAll()
    end)
end

AddEventHandler('playerSpawned', function()
    PlayerVars.isDead = false
end)

-- Admin Menu --
RegisterNetEvent('krz_personalmenu:Admin_BringC', function(plyCoords)
    SetEntityCoords(plyPed, plyCoords)
end)

--Message text joueur
local function Text(text)
    SetTextColour(186, 186, 186, 255)
    SetTextFont(0)
    SetTextScale(0.378, 0.378)
    SetTextWrap(0.0, 1.0)
    SetTextCentre(false)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 205)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.5, 0.03)
end

function KeyboardInput(entryTitle, textEntry, inputText, maxLength)
    AddTextEntry(entryTitle, textEntry)
    DisplayOnscreenKeyboard(1, entryTitle, '', inputText, '', '', '', maxLength)

    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
        Wait(0)
    end

    if UpdateOnscreenKeyboard() ~= 2 then
        local result = GetOnscreenKeyboardResult()
        Wait(500)
        return result
    else
        Wait(500)
        return nil
    end
end

function getCamDirection()
    local heading = GetGameplayCamRelativeHeading() + GetEntityPhysicsHeading(plyPed)
    local pitch = GetGameplayCamRelativePitch()
    local coords = vector3(-math.sin(heading * math.pi / 180.0), math.cos(heading * math.pi / 180.0), math.sin(pitch * math.pi / 180.0))
    local len = math.sqrt((coords.x * coords.x) + (coords.y * coords.y) + (coords.z * coords.z))

    if len ~= 0 then
        coords = coords / len
    end

    return coords
end

function startAttitude(animSet)
    if not animSet then
        ResetPedMovementClipset(plyPed, 1.0)
        return
    end

    LoadAnimSet(animSet)

    SetPedMotionBlur(plyPed, false)
    SetPedMovementClipset(plyPed, animSet, 1.0)

    RemoveAnimSet(animSet)
end

function startAnim(animDict, animName)
    LoadAnimDict(animDict)
    TaskPlayAnim(plyPed, animDict, animName, 8.0, 8.0, -1, 48, 0, false, false, false)
    RemoveAnimDict(animDict)
end

function startAnimAction(animDict, animName)
    LoadAnimDict(animDict)
    TaskPlayAnim(plyPed, animDict, animName, 8.0, 1.0, -1, 48, 0, false, false, false)
    RemoveAnimDict(animDict)
end

function setClothes(clotheId)
    TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
        TriggerEvent('skinchanger:getSkin', function(currentSkin)
            local clothes = nil

            if clotheId == 'torso' then
                startAnimAction('clothingtie', 'try_tie_neutral_a')
                Wait(1000)
                PlayerVars.handsup, PlayerVars.pointing = false, false
                ClearPedTasks(plyPed)

                if skin.torso_1 ~= currentSkin.torso_1 then
                    clothes = {['torso_1'] = skin.torso_1, ['torso_2'] = skin.torso_2, ['tshirt_1'] = skin.tshirt_1, ['tshirt_2'] = skin.tshirt_2, ['arms'] = skin.arms}
                else
                    clothes = {['torso_1'] = 15, ['torso_2'] = 0, ['tshirt_1'] = 15, ['tshirt_2'] = 0, ['arms'] = 15}
                end
            elseif clotheId == 'pants' then
                if skin.pants_1 ~= currentSkin.pants_1 then
                    clothes = {['pants_1'] = skin.pants_1, ['pants_2'] = skin.pants_2}
                else
                    if skin.sex == 0 then
                        clothes = {['pants_1'] = 61, ['pants_2'] = 1}
                    else
                        clothes = {['pants_1'] = 15, ['pants_2'] = 0}
                    end
                end
            elseif clotheId == 'shoes' then
                if skin.shoes_1 ~= currentSkin.shoes_1 then
                    clothes = {['shoes_1'] = skin.shoes_1, ['shoes_2'] = skin.shoes_2}
                else
                    if skin.sex == 0 then
                        clothes = {['shoes_1'] = 34, ['shoes_2'] = 0}
                    else
                        clothes = {['shoes_1'] = 35, ['shoes_2'] = 0}
                    end
                end
            elseif clotheId == 'bag' then
                if skin.bags_1 ~= currentSkin.bags_1 then
                    clothes = {['bags_1'] = skin.bags_1, ['bags_2'] = skin.bags_2}
                else
                    clothes = {['bags_1'] = 0, ['bags_2'] = 0}
                end
            elseif clotheId == 'bproof' then
                startAnimAction('clothingtie', 'try_tie_neutral_a')
                Wait(1000)
                PlayerVars.handsup, PlayerVars.pointing = false, false
                ClearPedTasks(plyPed)

                if skin.bproof_1 ~= currentSkin.bproof_1 then
                    clothes = {['bproof_1'] = skin.bproof_1, ['bproof_2'] = skin.bproof_2}
                else
                    clothes = {['bproof_1'] = 0, ['bproof_2'] = 0}
                end
            end

            TriggerEvent('skinchanger:loadClothes', currentSkin, clothes)
        end)
    end)
end

function setAccessory(accessoryId)
    TriggerServerCallback('esx_accessories:get', function(hasAccessory, accessorySkin)
        if not hasAccessory then
            local localeKey = ('accessories_no_%s'):format(accessoryId)
            GameNotification(i18nU(localeKey))
            return
        end

        TriggerEvent('skinchanger:getSkin', function(currentSkin)
            local propIdx = -1
            local propTex = 0

            if accessoryId == 'ears' then
                startAnimAction('mini@ears_defenders', 'takeoff_earsdefenders_idle')
                Wait(250)
                PlayerVars.handsup, PlayerVars.pointing = false, false
                ClearPedTasks(plyPed)
            elseif accessoryId == 'glasses' then
                startAnimAction('clothingspecs', 'try_glasses_positive_a')
                Wait(1000)
                PlayerVars.handsup, PlayerVars.pointing = false, false
                ClearPedTasks(plyPed)
            elseif accessoryId == 'helmet' then
                startAnimAction('missfbi4', 'takeoff_mask')
                Wait(1000)
                PlayerVars.handsup, PlayerVars.pointing = false, false
                ClearPedTasks(plyPed)
            elseif accessoryId == 'mask' then
                propIdx = 0
                startAnimAction('missfbi4', 'takeoff_mask')
                Wait(850)
                PlayerVars.handsup, PlayerVars.pointing = false, false
                ClearPedTasks(plyPed)
            end

            local accessoryIdxKey = ('%s_1'):format(accessoryId)
            local accessoryTexKey = ('%s_2'):format(accessoryId)

            if currentSkin[accessoryIdxKey] == 0 then
                propIdx = accessorySkin[accessoryIdxKey]
                propTex = accessorySkin[accessoryTexKey]
            end

            TriggerEvent('skinchanger:loadClothes', currentSkin, {
                [accessoryIdxKey] = propIdx,
                [accessoryTexKey] = propTex
            })
        end)
    end, firstToUpper(accessoryId))
end

function CheckQuantity(number)
    number = tonumber(number)
    if type(number) ~= 'number' then
        return false, number
    end

    number = MathRound(number)
    if number <= 0 then
        return false, number
    end

    return true, number
end

function DrawPersonalMenu()
    ruiDrawContent(drawContentOptions, function()
        for i = 1, #personalMenuCategories do
            local pmCategory = personalMenuCategories[i]
            local canOpen = not pmCategory.restriction or pmCategory.restriction()
            RageUI.Button(pmCategory.name, nil, canOpen and { RightLabel = "→→→" } or { RightBadge = RageUI.BadgeStyle.Lock }, canOpen, nil, pmCategory.menu)
        end

        RageUI.List(i18nU('mainmenu_gps_button'), PersonalMenu.GPSList, PersonalMenu.GPSIndex, nil, nil, true, function(Hovered, Active, Selected, Index)
            PersonalMenu.GPSIndex = Index

            if not Selected then return end

            local gpsCfg = Config.GPS[Index]

            if gpsCfg.coords then
                SetNewWaypoint(gpsCfg.coords)
            else
                DeleteWaypoint()
            end

            GameNotification(i18nU('gps', gpsCfg.name))
        end)
    end)
end

local accountInPockets = {
    ['money'] = 'wallet_money_button',
    ['black_money'] = 'wallet_blackmoney_button'
}

getPersonalMenuCategory('wallet').drawer = function()
    local playerJob = GetPlayerJob()
    RageUI.Button(i18nU('wallet_job_button', playerJob.name, playerJob.gradeName), nil, nil, true, nil)

    if Config.DoubleJob then
        local playerJob2 = GetPlayerJob2()
        RageUI.Button(i18nU('wallet_job2_button', playerJob2.name, playerJob2.gradeName), nil, nil, true, nil)
    end

    local playerAccounts = GetPlayerAccounts()
    for i = 1, #playerAccounts do
        local account = playerAccounts[i]

        if accountInPockets[account.name] then
            if PersonalMenu.WalletIndex[account.name] == nil then PersonalMenu.WalletIndex[account.name] = 1 end

            RageUI.List(i18nU(accountInPockets[account.name], GroupDigits(account.money)), PersonalMenu.WalletList, PersonalMenu.WalletIndex[account.name] or 1, nil, nil, true, function(Hovered, Active, Selected, Index)
                if not Selected then return end

                if Index == 1 then
                    local post, quantity = CheckQuantity(KeyboardInput('PM_BOX_AMOUNT', i18nU('dialogbox_amount'), '', 8))

                    if post then
                        local closestPlayer, closestDistance = GetClosestPlayer()
                        if closestDistance == -1 or closestDistance > 3 then
                            GameNotification(i18nU('players_nearby'))
                            return
                        end

                        local closestPed = GetPlayerPed(closestPlayer)

                        if not IsPedSittingInAnyVehicle(closestPed) then
                            TriggerServerEvent('esx:giveInventoryItem', GetPlayerServerId(closestPlayer), 'item_account', account.name, quantity)
                            RageUI.CloseAll()
                        else
                            GameNotification(i18nU('in_vehicle_give', 'de l\'argent'))
                        end
                    else
                        GameNotification(i18nU('amount_invalid'))
                    end
                elseif Index == 2 then
                    local post, quantity = CheckQuantity(KeyboardInput('PM_BOX_AMOUNT', i18nU('dialogbox_amount'), '', 8))

                    if post then
                        if not IsPedSittingInAnyVehicle(plyPed) then
                            TriggerServerEvent('esx:removeInventoryItem', 'item_account', account.name, quantity)
                            RageUI.CloseAll()
                        else
                            GameNotification(i18nU('in_vehicle_drop', 'de l\'argent'))
                        end
                    else
                        GameNotification(i18nU('amount_invalid'))
                    end
                end

                PersonalMenu.WalletIndex[account.name] = Index
            end)
        elseif account.name == 'bank' then
            RageUI.Button(i18nU('wallet_bankmoney_button', GroupDigits(account.money)), nil, nil, true, nil)
        end
    end

    if Config.JSFourIDCard then
        RageUI.Button(i18nU('wallet_show_idcard_button'), nil, nil, true, function(Hovered, Active, Selected)
            if not Selected then return end

            local closestPlayer, closestDistance = GetClosestPlayer()

            if closestDistance ~= -1 and closestDistance <= 3.0 then
                TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(closestPlayer))
            else
                GameNotification(i18nU('players_nearby'))
            end
        end)

        RageUI.Button(i18nU('wallet_check_idcard_button'), nil, nil, true, function(Hovered, Active, Selected)
            if not Selected then return end
            TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(PlayerId()))
        end)

        RageUI.Button(i18nU('wallet_show_driver_button'), nil, nil, true, function(Hovered, Active, Selected)
            if not Selected then return end

            local closestPlayer, closestDistance = GetClosestPlayer()

            if closestDistance ~= -1 and closestDistance <= 3.0 then
                TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(closestPlayer), 'driver')
            else
                GameNotification(i18nU('players_nearby'))
            end
        end)

        RageUI.Button(i18nU('wallet_check_driver_button'), nil, nil, true, function(Hovered, Active, Selected)
            if not Selected then return end
            TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(PlayerId()), 'driver')
        end)

        RageUI.Button(i18nU('wallet_show_firearms_button'), nil, nil, true, function(Hovered, Active, Selected)
            if not Selected then return end

            local closestPlayer, closestDistance = GetClosestPlayer()

            if closestDistance ~= -1 and closestDistance <= 3.0 then
                TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(closestPlayer), 'weapon')
            else
                GameNotification(i18nU('players_nearby'))
            end
        end)

        RageUI.Button(i18nU('wallet_check_firearms_button'), nil, nil, true, function(Hovered, Active, Selected)
            if not Selected then return end
            TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(PlayerId()), 'weapon')
        end)
    end
end

getPersonalMenuCategory('billing').drawer = function()
    for i = 1, #PersonalMenu.BillData do
        local billData = PersonalMenu.BillData[i]

        RageUI.Button(billData.label, nil, { RightLabel = ('$%s'):format(GroupDigits(billData.amount)) }, true, function(Hovered, Active, Selected)
            if not Selected then return end

            TriggerServerCallback('esx_billing:payBill', function()
                TriggerServerCallback('krz_personalmenu:Bill_getBills', function(bills) PersonalMenu.BillData = bills end)
            end, billData.id)
        end)
    end
end

getPersonalMenuCategory('clothes').drawer = function()
    for i = 1, #PersonalMenu.ClothesButtons do
        local clotheId = PersonalMenu.ClothesButtons[i]

        RageUI.Button(i18nU(('clothes_%s'):format(clotheId)), nil, {RightBadge = RageUI.BadgeStyle.Clothes}, true, function(Hovered, Active, Selected)
            if not Selected then return end
            setClothes(clotheId)
        end)
    end
end

getPersonalMenuCategory('accessories').drawer = function()
    for i = 1, #PersonalMenu.AccessoriesButtons do
        local accessoryId = PersonalMenu.AccessoriesButtons[i]

        RageUI.Button(i18nU(('accessories_%s'):format(accessoryId)), nil, {RightBadge = RageUI.BadgeStyle.Clothes}, true, function(Hovered, Active, Selected)
            if not Selected then return end
            setAccessory(accessoryId)
        end)
    end
end

getPersonalMenuCategory('animation').drawer = function()
    for i = 1, #Config.Animations do
        local animationCfg = Config.Animations[i]
        RageUI.Button(animationCfg.name, nil, {RightLabel = "→→→"}, true, nil, animationCfg.menu)
    end
end

function DrawAnimationsCategory(animationCfg)
    ruiDrawContent(drawContentOptions, function()
        for i = 1, #animationCfg.items do
            local animItemCfg = animationCfg.items[i]

            RageUI.Button(animItemCfg.name, nil, nil, true, function(Hovered, Active, Selected)
                if not Selected then return end

                if animItemCfg.type == 'anim' then
                    startAnim(animItemCfg.animDict, animItemCfg.animName)
                elseif animItemCfg.type == 'scenario' then
                    TaskStartScenarioInPlace(plyPed, animItemCfg.scenarioName, 0, false)
                elseif animItemCfg.type == 'attitude' then
                    startAttitude(animItemCfg.animSet)
                end
            end)
        end
    end)
end

getPersonalMenuCategory('vehicle').drawer = function()

    if not IsPedSittingInAnyVehicle(plyPed) then
        RageUI.CloseAll()
        GameNotification(i18nU('no_vehicle'))
        return
    end

    local plyVeh = GetVehiclePedIsIn(plyPed, false)
    local maxPassangers = GetVehicleMaxNumberOfPassengers(plyVeh) -1
    local seatsTaken = {}
    local seatIndex = {}
    local seatList = {}
    for i = -1,maxPassangers, 1 do
        --table.insert(seatsTaken,IsVehicleSeatFree(plyVeh,i))
        if IsVehicleSeatFree(plyVeh,i) then
            if i == -1 then
                table.insert(seatIndex,i)
                table.insert(seatList,'conducteur')

            else
                table.insert(seatIndex,i)
                table.insert(seatList,'passager ' .. i+1)
            end
        end


    end

    if GetPedInVehicleSeat(GetVehiclePedIsIn(plyPed, false), -1) == plyPed then

        RageUI.Button(i18nU('vehicle_engine_button'), nil, nil, true, function(Hovered, Active, Selected)
            if not Selected then return end

            if not IsPedSittingInAnyVehicle(plyPed) then
                GameNotification(i18nU('no_vehicle'))
                return
            end

            local plyVeh = GetVehiclePedIsIn(plyPed, false)

            if GetIsVehicleEngineRunning(plyVeh) then
                SetVehicleEngineOn(plyVeh, false, false, true)
                SetVehicleUndriveable(plyVeh, true)
            elseif not GetIsVehicleEngineRunning(plyVeh) then
                SetVehicleEngineOn(plyVeh, true, false, true)
                SetVehicleUndriveable(plyVeh, false)
            end
        end)

        RageUI.List(i18nU('vehicle_door_button'), PersonalMenu.DoorList, PersonalMenu.DoorIndex, nil, nil, true, function(Hovered, Active, Selected, Index)
            PersonalMenu.DoorIndex = Index

            if not Selected then return end

            if not IsPedSittingInAnyVehicle(plyPed) then
                GameNotification(i18nU('no_vehicle'))
                return
            end

            local plyVeh = GetVehiclePedIsIn(plyPed, false)

            if Index == 1 then
                if not PersonalMenu.DoorState.FrontLeft then
                    PersonalMenu.DoorState.FrontLeft = true
                    SetVehicleDoorOpen(plyVeh, 0, false, false)
                elseif PersonalMenu.DoorState.FrontLeft then
                    PersonalMenu.DoorState.FrontLeft = false
                    SetVehicleDoorShut(plyVeh, 0, false, false)
                end
            elseif Index == 2 then
                if not PersonalMenu.DoorState.FrontRight then
                    PersonalMenu.DoorState.FrontRight = true
                    SetVehicleDoorOpen(plyVeh, 1, false, false)
                elseif PersonalMenu.DoorState.FrontRight then
                    PersonalMenu.DoorState.FrontRight = false
                    SetVehicleDoorShut(plyVeh, 1, false, false)
                end
            elseif Index == 3 then
                if not PersonalMenu.DoorState.BackLeft then
                    PersonalMenu.DoorState.BackLeft = true
                    SetVehicleDoorOpen(plyVeh, 2, false, false)
                elseif PersonalMenu.DoorState.BackLeft then
                    PersonalMenu.DoorState.BackLeft = false
                    SetVehicleDoorShut(plyVeh, 2, false, false)
                end
            elseif Index == 4 then
                if not PersonalMenu.DoorState.BackRight then
                    PersonalMenu.DoorState.BackRight = true
                    SetVehicleDoorOpen(plyVeh, 3, false, false)
                elseif PersonalMenu.DoorState.BackRight then
                    PersonalMenu.DoorState.BackRight = false
                    SetVehicleDoorShut(plyVeh, 3, false, false)
                end
            end
        end)

        RageUI.Button(i18nU('vehicle_hood_button'), nil, nil, true, function(Hovered, Active, Selected)
            if not Selected then return end

            if not IsPedSittingInAnyVehicle(plyPed) then
                GameNotification(i18nU('no_vehicle'))
                return
            end

            local plyVeh = GetVehiclePedIsIn(plyPed, false)

            if not PersonalMenu.DoorState.Hood then
                PersonalMenu.DoorState.Hood = true
                SetVehicleDoorOpen(plyVeh, 4, false, false)
            elseif PersonalMenu.DoorState.Hood then
                PersonalMenu.DoorState.Hood = false
                SetVehicleDoorShut(plyVeh, 4, false, false)
            end
        end)

        RageUI.Button(i18nU('vehicle_trunk_button'), nil, nil, true, function(Hovered, Active, Selected)
            if not Selected then return end

            if not IsPedSittingInAnyVehicle(plyPed) then
                GameNotification(i18nU('no_vehicle'))
                return
            end

            local plyVeh = GetVehiclePedIsIn(plyPed, false)

            if not PersonalMenu.DoorState.Trunk then
                PersonalMenu.DoorState.Trunk = true
                SetVehicleDoorOpen(plyVeh, 5, false, false)
            elseif PersonalMenu.DoorState.Trunk then
                PersonalMenu.DoorState.Trunk = false
                SetVehicleDoorShut(plyVeh, 5, false, false)
            end
        end)
    end

    if maxPassangers ~= -1 then
        RageUI.List('sièges', seatList, PersonalMenu.SeatIndex, nil, nil, true, function(Hovered, Active, Selected, Index)
            PersonalMenu.SeatIndex = Index
            if not Selected then return end

            if not IsPedSittingInAnyVehicle(plyPed) then
                GameNotification(i18nU('no_vehicle'))
                return
            end

            local currentTime = GetGameTimer()
            if currentTime - lastSeatChangeTime < 5000 then
                GameNotification('Vous devez attendre un peux pour cela')
                return
            end
            lastSeatChangeTime = currentTime

            local plyVeh = GetVehiclePedIsIn(plyPed, false)
            print(seatIndex[Index])
            TaskWarpPedIntoVehicle(plyPed,plyVeh,seatIndex[Index])
        end)
    end
end

getPersonalMenuCategory('boss').drawer = function()
    if societyMoney then
        RageUI.Button(i18nU('bossmanagement_chest_button'), nil, { RightLabel = ('$%s'):format(GroupDigits(societyMoney)) }, true, nil)
    end

    RageUI.Button(i18nU('bossmanagement_hire_button'), nil, nil, true, function(Hovered, Active, Selected)
        if not Selected then return end

        local playerJob = GetPlayerJob()

        if not playerJob.isBoss then
            GameNotification(i18nU('missing_rights'))
            return
        end

        local closestPlayer, closestDistance = GetClosestPlayer()
        if closestPlayer == -1 or closestDistance > 3.0 then
            GameNotification(i18nU('players_nearby'))
            return
        end

        TriggerServerEvent('krz_personalmenu:Boss_recruterplayer', GetPlayerServerId(closestPlayer))
    end)

    RageUI.Button(i18nU('bossmanagement_fire_button'), nil, nil, true, function(Hovered, Active, Selected)
        if not Selected then return end

        local playerJob = GetPlayerJob()

        if not playerJob.isBoss then
            GameNotification(i18nU('missing_rights'))
            return
        end

        local closestPlayer, closestDistance = GetClosestPlayer()
        if closestPlayer == -1 or closestDistance > 3.0 then
            GameNotification(i18nU('players_nearby'))
            return
        end

        TriggerServerEvent('krz_personalmenu:Boss_virerplayer', GetPlayerServerId(closestPlayer))
    end)

    RageUI.Button(i18nU('bossmanagement_promote_button'), nil, nil, true, function(Hovered, Active, Selected)
        if not Selected then return end

        local playerJob = GetPlayerJob()

        if not playerJob.isBoss then
            GameNotification(i18nU('missing_rights'))
            return
        end

        local closestPlayer, closestDistance = GetClosestPlayer()
        if closestPlayer == -1 or closestDistance > 3.0 then
            GameNotification(i18nU('players_nearby'))
            return
        end

        TriggerServerEvent('krz_personalmenu:Boss_promouvoirplayer', GetPlayerServerId(closestPlayer))
    end)

    RageUI.Button(i18nU('bossmanagement_demote_button'), nil, nil, true, function(Hovered, Active, Selected)
        if not Selected then return end

        local playerJob = GetPlayerJob()

        if not playerJob.isBoss then
            GameNotification(i18nU('missing_rights'))
            return
        end

        local closestPlayer, closestDistance = GetClosestPlayer()
        if closestPlayer == -1 or closestDistance > 3.0 then
            GameNotification(i18nU('players_nearby'))
            return
        end

        TriggerServerEvent('krz_personalmenu:Boss_destituerplayer', GetPlayerServerId(closestPlayer))
    end)
end

if Config.DoubleJob then
    getPersonalMenuCategory('boss2').drawer = function()
        if societyMoney ~= nil then
            RageUI.Button(i18nU('bossmanagement2_chest_button'), nil, { RightLabel = ('$%s'):format(GroupDigits(societyMoney2)) }, true, nil)
        end

        RageUI.Button(i18nU('bossmanagement2_hire_button'), nil, nil, true, function(Hovered, Active, Selected)
            if not Selected then return end

            local playerJob = GetPlayerJob2()

            if not playerJob.isBoss then
                GameNotification(i18nU('missing_rights'))
                return
            end

            local closestPlayer, closestDistance = GetClosestPlayer()
            if closestPlayer == -1 or closestDistance > 3.0 then
                GameNotification(i18nU('players_nearby'))
                return
            end

            TriggerServerEvent('krz_personalmenu:Boss_recruterplayer2', GetPlayerServerId(closestPlayer))
        end)

        RageUI.Button(i18nU('bossmanagement2_fire_button'), nil, nil, true, function(Hovered, Active, Selected)
            if not Selected then return end

            local playerJob = GetPlayerJob2()

            if not playerJob.isBoss then
                GameNotification(i18nU('missing_rights'))
                return
            end

            local closestPlayer, closestDistance = GetClosestPlayer()
            if closestPlayer == -1 or closestDistance > 3.0 then
                GameNotification(i18nU('players_nearby'))
                return
            end

            TriggerServerEvent('krz_personalmenu:Boss_virerplayer2', GetPlayerServerId(closestPlayer))
        end)

        RageUI.Button(i18nU('bossmanagement2_promote_button'), nil, nil, true, function(Hovered, Active, Selected)
            if not Selected then return end

            local playerJob = GetPlayerJob2()

            if not playerJob.isBoss then
                GameNotification(i18nU('missing_rights'))
                return
            end

            local closestPlayer, closestDistance = GetClosestPlayer()
            if closestPlayer == -1 or closestDistance > 3.0 then
                GameNotification(i18nU('players_nearby'))
                return
            end

            TriggerServerEvent('krz_personalmenu:Boss_promouvoirplayer2', GetPlayerServerId(closestPlayer))
        end)

        RageUI.Button(i18nU('bossmanagement2_demote_button'), nil, nil, true, function(Hovered, Active, Selected)
            if not Selected then return end

            local playerJob = GetPlayerJob2()

            if not playerJob.isBoss then
                GameNotification(i18nU('missing_rights'))
                return
            end

            local closestPlayer, closestDistance = GetClosestPlayer()
            if closestPlayer == -1 or closestDistance > 3.0 then
                GameNotification(i18nU('players_nearby'))
                return
            end

            TriggerServerEvent('krz_personalmenu:Boss_destituerplayer2', GetPlayerServerId(closestPlayer))
        end)
    end
end

getPersonalMenuCategory('admin').drawer = function()
    for i = 1, #Config.AdminCommands do
        local adminCommandCfg = Config.AdminCommands[i]

        if adminCommandCfg.groupsById[PlayerVars.group] then
            RageUI.Button(adminCommandCfg.name, nil, nil, true, function(Hovered, Active, Selected)
                if not Selected then return end
                adminCommandCfg.command()
            end)
        else
            RageUI.Button(adminCommandCfg.name, nil, {RightBadge = RageUI.BadgeStyle.Lock}, false, nil)
        end
    end
end

RegisterCommand('+openpersonal', function()
    if PlayerVars.isDead then return end
    if RageUI.Visible(mainMenu) then return end

    TriggerServerCallback('krz_personalmenu:Admin_getUsergroup', function(plyGroup)
        PlayerVars.group = plyGroup
    end)

    TriggerServerCallback('krz_personalmenu:Bill_getBills', function(bills)
        PersonalMenu.BillData = bills
    end)

    TriggerEvent('krz_personalmenu:menuOpening')
    RageUI.Visible(mainMenu, true)
    DrawPersonalMenu()
end, false)

RegisterCommand('-openpersonal', function() end, false)

RegisterKeyMapping('+openpersonal', 'Ouvrir le menu personnel', 'KEYBOARD', Config.Controls.OpenMenu.keyboard)
TriggerEvent('chat:removeSuggestion', '/+openpersonal')
TriggerEvent('chat:removeSuggestion', '/-openpersonal')

CreateThread(function()
    local ruiVisible = RageUI.Visible

    while true do
        if ruiVisible(mainMenu) then
            DrawPersonalMenu()
            goto continue
        end

        for i = 1, #personalMenuCategories do
            local pmCategory = personalMenuCategories[i]

            if ruiVisible(pmCategory.menu) then
                if not pmCategory.restriction or pmCategory.restriction() then
                    ruiDrawContent(drawContentOptions, pmCategory.drawer)
                else
                    RageUI.GoBack()
                end

                goto continue
            end
        end

        for i = 1, #Config.Animations do
            local animationCfg = Config.Animations[i]

            if ruiVisible(animationCfg.menu) then
                DrawAnimationsCategory(animationCfg)
                goto continue
            end
        end

        ::continue::
        Wait(0)
    end
end)

RegisterCommand('+stoptask', function()
    local playerPed = PlayerPedId()

    if (not IsPedArmed(playerPed, tonumber('111', 2)) or IsPedInAnyVehicle(playerPed)) and not PlayerVars.isDead then
        if GetScriptTaskStatus(playerPed, `SCRIPT_TASK_START_SCENARIO_IN_PLACE`) == 1 or GetScriptTaskStatus(playerPed, `SCRIPT_TASK_PLAY_ANIM`) == 1 then
            ResetOtherAnimsVals()
            ClearPedTasks(plyPed)
        end
    end
end, false)

RegisterCommand('-stoptask', function() end, false)

RegisterKeyMapping('+stoptask', 'Annulez animation', 'KEYBOARD', Config.Controls.StopTasks.keyboard)
TriggerEvent('chat:removeSuggestion', '/+stoptask')
TriggerEvent('chat:removeSuggestion', '/-stoptask')

function tpMarker()
    local waypointHandle = GetFirstBlipInfoId(8)

    if not DoesBlipExist(waypointHandle) then
        GameNotification(i18nU('admin_nomarker'))
        return
    end

    CreateThread(function()
        local waypointCoords = GetBlipInfoIdCoord(waypointHandle)
        local foundGround, zCoords, zPos = false, -500.0, 0.0

        while not foundGround do
            zCoords = zCoords + 10.0
            RequestCollisionAtCoord(waypointCoords.x, waypointCoords.y, zCoords)
            Wait(0)
            foundGround, zPos = GetGroundZFor_3dCoord(waypointCoords.x, waypointCoords.y, zCoords, false)

            if not foundGround and zCoords >= 2000.0 then
                foundGround = true
            end
        end

        SetPedCoordsKeepVehicle(plyPed, waypointCoords.x, waypointCoords.y, zPos)
        GameNotification(i18nU('admin_tpmarker'))
    end)
end

CreateThread(function()
    while true do
        plyPed = PlayerPedId()

        if (IsControlPressed(0, Config.Controls.TPMarker.keyboard1) or IsDisabledControlPressed(0, Config.Controls.TPMarker.keyboard1)) and
            (IsControlJustReleased(0, Config.Controls.TPMarker.keyboard2) or IsDisabledControlJustReleased(0, Config.Controls.TPMarker.keyboard2)) and
            IsUsingKeyboard(2) and
            not PlayerVars.isDead
        then
            TriggerServerCallback('krz_personalmenu:Admin_getUsergroup', function(plyGroup)
                if not adminGroups[plyGroup] then
                    return
                end

                tpMarker()
            end)
        end

        if PlayerVars.showCoords then
            local plyCoords = GetEntityCoords(plyPed, false)
            Text('~r~X~s~: ' .. MathRound(plyCoords.x, 2) .. '\n~b~Y~s~: ' .. MathRound(plyCoords.y, 2) .. '\n~g~Z~s~: ' .. MathRound(plyCoords.z, 2) .. '\n~y~Angle~s~: ' .. MathRound(GetEntityPhysicsHeading(plyPed), 2))
        end

        Wait(0)
    end
end)
