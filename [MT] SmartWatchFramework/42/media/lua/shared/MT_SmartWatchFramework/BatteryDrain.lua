--------------------------------------------------
-- MT SMART WATCH
-- BATTERY DRAIN SYSTEM
--------------------------------------------------

MT_SmartWatch = MT_SmartWatch or {}

MT_SmartWatch.BatteryDrain =
    MT_SmartWatch.BatteryDrain or {}

local BatteryDrain =
    MT_SmartWatch.BatteryDrain


--------------------------------------------------
-- IS CHIP DRAIN ACTIVE
-- Единый ответ на вопрос:
--   «Этот чип прямо сейчас расходует батарею?»
--
-- Учитывает batteryDrainMode:
--   "installed" -> активен всегда, пока вставлен
--   "active"    -> активен, только если открыто
--                  его приложение
--   "none"/nil  -> не расходует
--
-- Этот же критерий используется и в UI/дебаге,
-- чтобы у FChip-чипов корректно показывалось
-- Draining: true.
--------------------------------------------------

function BatteryDrain.isChipDrainActive(
    watch,
    fullType
)

    if not watch then
        return false
    end


    if not fullType then
        return false
    end


    local ChipSystem =
        MT_SmartWatch.ChipSystem


    if not ChipSystem then
        return false
    end


    if type(
        ChipSystem.getChipDataByFullType
    ) ~= "function" then

        return false

    end


    local data =
        ChipSystem.getChipDataByFullType(
            fullType
        )


    if not data then
        return false
    end


    local rate =
        tonumber(
            data.batteryDrainPerMinute
        )
        or 0


    if rate <= 0 then
        return false
    end


    local mode =
        data.batteryDrainMode
        or "none"


    --------------------------------------------------
    -- INSTALLED MODE
    --------------------------------------------------

    if mode == "installed" then

        return true

    end


    --------------------------------------------------
    -- ACTIVE APP MODE
    --------------------------------------------------

    if mode == "active" then

        if type(
            ChipSystem.isChipActive
        ) ~= "function" then

            return false

        end


        return
            ChipSystem.isChipActive(
                watch,
                fullType
            )
            and true
            or false

    end


    return false

end


--------------------------------------------------
-- GET DRAIN PER MINUTE
-- Суммарный расход за игровую минуту
-- по всем чипам, реально потребляющим
-- батарею прямо сейчас.
--------------------------------------------------

function BatteryDrain.getDrainPerMinute(
    watch
)

    local ChipSystem =
        MT_SmartWatch.ChipSystem


    if not ChipSystem then
        return 0
    end


    if type(
        ChipSystem.getInstalledChips
    ) ~= "function" then

        return 0

    end


    local chips =
        ChipSystem.getInstalledChips(
            watch
        )


    if not chips then
        return 0
    end


    local total =
        0


    for i = 1, #chips do

        local fullType =
            chips[i]


        if fullType
            and BatteryDrain.isChipDrainActive(
                watch,
                fullType
            ) then

            local data =
                ChipSystem.getChipDataByFullType(
                    fullType
                )


            if data then

                total =
                    total
                    + (
                        tonumber(
                            data.batteryDrainPerMinute
                        )
                        or 0
                    )

            end

        end

    end


    return
        total

end


--------------------------------------------------
-- APPLY MINUTES
-- Возвращает фактически списанное.
--------------------------------------------------

function BatteryDrain.applyMinutes(
    watch,
    minutes
)

    if not watch then
        return 0
    end


    minutes =
        tonumber(
            minutes
        )
        or 0


    if minutes <= 0 then
        return 0
    end


    local Battery =
        MT_SmartWatch.Battery


    if not Battery then
        return 0
    end


    if not Battery.initialize(
        watch
    ) then

        return 0

    end


    if Battery.isEmpty(
        watch
    ) then

        return 0

    end


    local perMinute =
        BatteryDrain.getDrainPerMinute(
            watch
        )


    if perMinute <= 0 then
        return 0
    end


    return
        Battery.drainUpTo(
            watch,
            perMinute * minutes
        )

end


--------------------------------------------------
-- INITIALIZE FOR WATCH
-- ChipSystem.initialize вызывается один раз
-- на конкретные часы (флаг в ModData).
-- Повторные тики его уже не дёргают.
--------------------------------------------------

function BatteryDrain.initializeForWatch(
    watch
)

    if not watch then
        return
    end


    local ChipSystem =
        MT_SmartWatch.ChipSystem


    if not ChipSystem then
        return
    end


    if type(
        ChipSystem.initialize
    ) ~= "function" then

        return

    end


    local modData =
        watch:getModData()


    if not modData then
        return
    end


    modData.MT_SmartWatch =
        modData.MT_SmartWatch
        or {}


    if modData.MT_SmartWatch
        .ChipsInitialized then

        return

    end


    ChipSystem.initialize(
        watch
    )


    modData.MT_SmartWatch
        .ChipsInitialized =
        true

end


--------------------------------------------------
-- RESET INIT FLAG
-- На случай, если чипы меняются «на лету»
-- и требуется пересобрать состояние.
-- Вызывать из ChipSystem.installChip /
-- removeChip, если там это уместно.
--------------------------------------------------

function BatteryDrain.resetInitializeFlag(
    watch
)

    if not watch then
        return
    end


    local modData =
        watch:getModData()


    if not modData
        or not modData.MT_SmartWatch then

        return

    end


    modData.MT_SmartWatch
        .ChipsInitialized =
        nil

end


--------------------------------------------------
-- DRAIN PLAYER
--------------------------------------------------

function BatteryDrain.drainPlayer(
    player
)

    if not player then
        return 0
    end


    local Watch =
        MT_SmartWatch.Watch


    if not Watch
        or type(
            Watch.getEquippedWatch
        ) ~= "function" then

        return 0

    end


    local watch =
        Watch.getEquippedWatch(
            player
        )


    if not watch then
        return 0
    end


    BatteryDrain.initializeForWatch(
        watch
    )


    return
        BatteryDrain.applyMinutes(
            watch,
            1
        )

end


--------------------------------------------------
-- DEBUG
-- SP-инструмент: ручной тик для консоли.
--------------------------------------------------

function BatteryDrain.debugOneMinute()

    local player =
        getPlayer()


    if not player then
        return
    end


    local Watch =
        MT_SmartWatch.Watch


    if not Watch then
        return
    end


    local watch =
        Watch.getEquippedWatch(
            player
        )


    if not watch then
        return
    end


    local Battery =
        MT_SmartWatch.Battery


    if not Battery then
        return
    end


    Battery.initialize(
        watch
    )


    local perMinute =
        BatteryDrain.getDrainPerMinute(
            watch
        )


    local before =
        Battery.getCurrent(
            watch
        )


    local actual =
        BatteryDrain.applyMinutes(
            watch,
            1
        )


    local after =
        Battery.getCurrent(
            watch
        )


    print(
        "[MT Smart Watch] "
        .. "Battery Drain / 1 Game Minute"
    )


    print(
        "[MT Smart Watch] "
        .. "Configured Drain: "
        .. tostring(
            perMinute
        )
    )


    print(
        "[MT Smart Watch] "
        .. "Before: "
        .. string.format(
            "%.2f",
            before
        )
    )


    print(
        "[MT Smart Watch] "
        .. "Actual Drain: "
        .. string.format(
            "%.2f",
            actual
        )
    )


    print(
        "[MT Smart Watch] "
        .. "After: "
        .. string.format(
            "%.2f",
            after
        )
    )

end


--------------------------------------------------
-- EVENTS
--------------------------------------------------

Events.EveryOneMinute.Add(
    function()

        --------------------------------------------------
        -- MP CLIENT: PASSIVE
        --------------------------------------------------

        if isClient()
            and not isServer() then

            return

        end


        --------------------------------------------------
        -- MP SERVER: ALL ONLINE PLAYERS
        --------------------------------------------------

        if isServer() then

            local players =
                getOnlinePlayers()


            if not players then
                return
            end


            for i = 0, players:size() - 1 do

                local player =
                    players:get(i)


                if player then

                    BatteryDrain.drainPlayer(
                        player
                    )

                end

            end


            return

        end


        --------------------------------------------------
        -- SINGLE PLAYER
        --------------------------------------------------

        BatteryDrain.drainPlayer(
            getPlayer()
        )

    end
)


--------------------------------------------------
-- LOADED
--------------------------------------------------

print(
    "[MT Smart Watch] "
    .. "BatteryDrain system loaded (shared)"
)