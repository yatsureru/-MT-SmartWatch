--------------------------------------------------
-- MT SMART WATCH
-- FRAMEWORK (SHARED)
-- Проверка сборки модуля на старте игры.
-- Единая точка диагностики вместо молчаливых
-- сбоев в рантайме: любой пропавший модуль
-- будет виден одной строкой в консоли.
--------------------------------------------------

MT_SmartWatch = MT_SmartWatch or {}

MT_SmartWatch.Framework =
    MT_SmartWatch.Framework or {}

local Framework =
    MT_SmartWatch.Framework


--------------------------------------------------
-- REQUIRED SHARED MODULES
-- Обязательны и в SP, и на MP-сервере.
--------------------------------------------------

Framework.SharedModules = {

    "Watch",
    "Battery",
    "BatteryDrain",
    "ChipSystem",
    "OSCore",
    "OSCoreRegister",
    "FunctionalChip",
    "FunctionalChipRegister",
    "TacticalChip",
    "TacticalChipRegister",
    "AppChip",
    "AppChipRegister",

}


--------------------------------------------------
-- CLIENT MODULES
-- Существуют только на клиенте (UI, приложения,
-- дебаг-инструменты). Сервер их не проверяет.
--------------------------------------------------

Framework.ClientModules = {

    "RadioApp",
    "StaminaHUD",
    "TimeHUD",
    "Debug",

}


--------------------------------------------------
-- CHECK MODULES
--------------------------------------------------

function Framework.checkModules(
    modules,
    label
)

    local missing =
        false


    for i = 1, #modules do

        local name =
            modules[i]

        if type(MT_SmartWatch[name]) ~= "table" then

            missing =
                true


            print(
                "[MT Smart Watch] FRAMEWORK ERROR: "
                .. label
                .. " module missing: "
                .. tostring(name)
            )

        end

    end


    return
        not missing

end


--------------------------------------------------
-- ON GAME START
-- К моменту события весь Lua загружен:
-- проверка видит финальное состояние сборки.
--------------------------------------------------

Events.OnGameStart.Add(
    function()

        local sharedOk =
            Framework.checkModules(
                Framework.SharedModules,
                "SHARED"
            )


        local clientOk =
            true


        --------------------------------------------------
        -- CLIENT MODULES
        -- На выделенном сервере их нет — и это норма.
        -- В SP isClient() и isServer() оба false:
        -- проверка выполняется.
        --------------------------------------------------

        if not isServer() or isClient() then

            clientOk =
                Framework.checkModules(
                    Framework.ClientModules,
                    "CLIENT"
                )

        end


        if sharedOk
            and clientOk then

            print(
                "[MT Smart Watch] "
                .. "Framework: all modules OK"
            )

        end

    end
)


print(
    "[MT Smart Watch] "
    .. "Framework loaded (shared)"
)
