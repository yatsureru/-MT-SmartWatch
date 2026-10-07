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
-- STATE
--------------------------------------------------

BatteryDrain.LastWorldMinute =
    nil

BatteryDrain.Initialized =
    false


--------------------------------------------------
-- GET WORLD MINUTE
--------------------------------------------------

function BatteryDrain.getWorldMinute()

    local gameTime =
        getGameTime()


    if not gameTime then
        return nil
    end


    local hours =
        gameTime:getWorldAgeHours()


    if hours == nil then
        return nil
    end


    return
        math.floor(
            hours * 60
        )

end


--------------------------------------------------
-- GET DRAIN PER MINUTE
--------------------------------------------------

function BatteryDrain.getDrainPerMinute(
    watch
)

    local ChipSystem =
        MT_SmartWatch.ChipSystem


    if not ChipSystem then
        return 0
    end


    local chips =
        ChipSystem.getInstalledChips(
            watch
        )


    local total =
        0


    for i = 1, #chips do

        local fullType =
            chips[i]


        local data =
            ChipSystem.getChipDataByFullType(
                fullType
            )


        if data then

            local rate =
                tonumber(
                    data.batteryDrainPerMinute
                )
                or 0


            local mode =
                data.batteryDrainMode
                or "none"


            local active =
                false


            --------------------------------------------------
            -- INSTALLED MODE
            --------------------------------------------------

            if mode == "installed" then

                active =
                    true

            --------------------------------------------------
            -- ACTIVE APP MODE
            --------------------------------------------------

            elseif mode == "active" then

                active =
                    ChipSystem.isChipActive(
                        watch,
                        fullType
                    )

            end


            if active
                and rate > 0 then

                total =
                    total
                    + rate

            end

        end

    end


    return
        total

end


--------------------------------------------------
-- APPLY DRAIN
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


    Battery.initialize(
        watch
    )


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


    local amount =
        perMinute
        * minutes


    local before =
        Battery.getCurrent(
            watch
        )


    Battery.drain(
        watch,
        amount
    )


    local after =
        Battery.getCurrent(
            watch
        )


    return
        before - after

end


--------------------------------------------------
-- INITIALIZE
--------------------------------------------------

function BatteryDrain.initializeForWatch(
    watch
)

    local ChipSystem =
        MT_SmartWatch.ChipSystem


    if not ChipSystem then
        return
    end


    ChipSystem.initialize(
        watch
    )


end


--------------------------------------------------
-- PROCESS
--------------------------------------------------

function BatteryDrain.process(
    player
)

    if not player then
        return
    end


    local Watch =
        MT_SmartWatch.Watch


    if not Watch
        or not Watch.getEquippedWatch then

        return

    end


    local watch =
        Watch.getEquippedWatch(
            player
        )


    if not watch then
        return
    end


    --------------------------------------------------
    -- INITIALIZE
    --------------------------------------------------

    if not BatteryDrain.Initialized then

        BatteryDrain.initializeForWatch(
            watch
        )


        BatteryDrain.Initialized =
            true

    end


    --------------------------------------------------
    -- CURRENT MINUTE
    --------------------------------------------------

    local currentMinute =
        BatteryDrain.getWorldMinute()


    if currentMinute == nil then
        return
    end


    --------------------------------------------------
    -- FIRST TICK
    --------------------------------------------------

    if BatteryDrain.LastWorldMinute == nil then

        BatteryDrain.LastWorldMinute =
            currentMinute

        return

    end


    --------------------------------------------------
    -- DELTA
    --------------------------------------------------

    local delta =
        currentMinute
        - BatteryDrain.LastWorldMinute


    if delta <= 0 then
        return
    end


    BatteryDrain.LastWorldMinute =
        currentMinute


    --------------------------------------------------
    -- APPLY
    --------------------------------------------------

    BatteryDrain.applyMinutes(
        watch,
        delta
    )

end


--------------------------------------------------
-- DEBUG
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
        .. tostring(
            before
        )
    )


    print(
        "[MT Smart Watch] "
        .. "Actual Drain: "
        .. tostring(
            actual
        )
    )


    print(
        "[MT Smart Watch] "
        .. "After: "
        .. tostring(
            after
        )
    )

end


--------------------------------------------------
-- GAME START
--------------------------------------------------

Events.OnGameStart.Add(
    function()

        BatteryDrain.LastWorldMinute =
            nil

        BatteryDrain.Initialized =
            false

    end
)


--------------------------------------------------
-- PLAYER UPDATE
--------------------------------------------------

Events.OnPlayerUpdate.Add(
    function(player)

        BatteryDrain.process(
            player
        )

    end
)


--------------------------------------------------
-- LOADED
--------------------------------------------------

print(
    "[MT Smart Watch] "
    .. "BatteryDrain system loaded"
)