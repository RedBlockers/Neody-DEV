CreateThread(function()
    while not ESX do
        Wait(100)
        print("waiting esx")
    end


    --PNJ
    RequestModel(GetHashKey(Config.InterimPNJ.pedModel))
    while not HasModelLoaded(GetHashKey(Config.InterimPNJ.pedModel)) do
        Wait(100)
        print("waiting model")

    end
    local coords = Config.InterimPNJ.coords
    local pnj = CreatePed(5, GetHashKey(Config.InterimPNJ.pedModel), coords.x, coords.y, coords.z, coords.r, false, true)
    print(pnj)
    SetBlockingOfNonTemporaryEvents(pnj, true)
    SetEntityInvincible(pnj, true)
    SetPedCanRagdoll(pnj, false)
    SetPedCanRagdollFromPlayerImpact(pnj, false)
    SetPedCanBeTargetted(pnj, false)
    SetPedCanBeTargettedByPlayer(pnj, false)
    SetPedCanBeTargettedByTeam(pnj, false)
    SetPedCanBeKnockedOffVehicle(pnj, false)
    SetPedFleeAttributes(pnj, 0, false)
    SetPedCombatAttributes(pnj, 17, true)
    FreezeEntityPosition(pnj,true)


    --BLIPS
    local mainConf = Config.InterimPNJ
    local blipInter = AddBlipForCoord(mainConf.blipPos.x,mainConf.blipPos.y,mainConf.blipPos.z)
    SetBlipSprite(blipInter,mainConf.blipSprite)
    SetBlipColour(blipInter,mainConf.blipColor)
    SetBlipScale(blipInter, 0.90)
    SetBlipAsShortRange(blipInter, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString("intérimaire")
    EndTextCommandSetBlipName(blipInter)
end)
