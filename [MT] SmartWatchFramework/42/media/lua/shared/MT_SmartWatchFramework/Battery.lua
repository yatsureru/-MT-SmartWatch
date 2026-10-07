--------------------------------------------------
-- MT SMART WATCH
-- BATTERY SYSTEM
--------------------------------------------------

MT_SmartWatch = MT_SmartWatch or {}

MT_SmartWatch.Battery =
    MT_SmartWatch.Battery or {}

local Battery =
    MT_SmartWatch.Battery


--------------------------------------------------
-- GET MAX BATTERY
--------------------------------------------------

function Battery.getMax(watch)

    if not watch then
        return 0
    end


    --------------------------------------------------
    -- OS CORE
    --------------------------------------------------

    local OSCore =
        MT_SmartWatch.OSCore


    if type(OSCore) ~= "table" then
        return 0
    end


    if type(
        OSCore.getInstalledData
    ) ~= "function" then

        return 0

    end


    local coreData =
        OSCore.getInstalledData(
            watch
        )


    --------------------------------------------------
    -- NO CORE
    --------------------------------------------------

    if not coreData then

        return 0

    end


    --------------------------------------------------
    -- CAPACITY
    --------------------------------------------------

    return
        coreData.batteryCapacity
        or 0

end


--------------------------------------------------
-- GET CURRENT BATTERY
--------------------------------------------------

function Battery.getCurrent(
    watch
)

    if not watch then
        return 0
    end


    local modData =
        watch:getModData()


    if not modData then
        return 0
    end


    local watchData =
        modData.MT_SmartWatch


    if not watchData then
        return 0
    end


    local battery =
        watchData.Battery


    if not battery then
        return 0
    end


    return
        battery.current
        or 0

end


--------------------------------------------------
-- SET CURRENT BATTERY
--------------------------------------------------

function Battery.setCurrent(
    watch,
    value
)

    if not watch then
        return false
    end


    local max =
        Battery.getMax(
            watch
        )


    --------------------------------------------------
    -- NO CORE
    --------------------------------------------------

    if max <= 0 then

        local modData =
            watch:getModData()


        modData.MT_SmartWatch =
            modData.MT_SmartWatch
            or {}


        modData.MT_SmartWatch.Battery =
            modData.MT_SmartWatch.Battery
            or {}


        modData.MT_SmartWatch.Battery.current =
            0


        return false

    end


    --------------------------------------------------
    -- CLAMP
    --------------------------------------------------

    value =
        math.max(
            0,
            math.min(
                value,
                max
            )
        )


    --------------------------------------------------
    -- MOD DATA
    --------------------------------------------------

    local modData =
        watch:getModData()


    if not modData then
        return false
    end


    modData.MT_SmartWatch =
        modData.MT_SmartWatch
        or {}


    modData.MT_SmartWatch.Battery =
        modData.MT_SmartWatch.Battery
        or {}


    modData.MT_SmartWatch.Battery.current =
        value


    return true

end


--------------------------------------------------
-- INITIALIZE
--------------------------------------------------

function Battery.initialize(
    watch
)

    if not watch then
        return false
    end


    local max =
        Battery.getMax(
            watch
        )


    --------------------------------------------------
    -- NO CORE
    --------------------------------------------------

    if max <= 0 then

        return false

    end


    --------------------------------------------------
    -- MOD DATA
    --------------------------------------------------

    local modData =
        watch:getModData()


    if not modData then
        return false
    end


    modData.MT_SmartWatch =
        modData.MT_SmartWatch
        or {}


    modData.MT_SmartWatch.Battery =
        modData.MT_SmartWatch.Battery
        or {}


    local battery =
        modData.MT_SmartWatch.Battery


    --------------------------------------------------
    -- INITIAL VALUE
    --------------------------------------------------

    if battery.current == nil then

        battery.current =
            max

    else

        battery.current =
            math.max(
                0,
                math.min(
                    battery.current,
                    max
                )
            )

    end


    return true

end


--------------------------------------------------
-- DRAIN
--------------------------------------------------

function Battery.drain(
    watch,
    amount
)

    if not watch then
        return false
    end


    if not amount then
        return false
    end


    if amount <= 0 then
        return true
    end


    --------------------------------------------------
    -- CURRENT
    --------------------------------------------------

    local current =
        Battery.getCurrent(
            watch
        )


    --------------------------------------------------
    -- SET
    --------------------------------------------------

    return
        Battery.setCurrent(
            watch,
            current - amount
        )

end


--------------------------------------------------
-- IS EMPTY
--------------------------------------------------

function Battery.isEmpty(
    watch
)

    if not watch then
        return true
    end


    local max =
        Battery.getMax(
            watch
        )


    --------------------------------------------------
    -- NO CORE
    --------------------------------------------------

    if max <= 0 then
        return true
    end


    local current =
        Battery.getCurrent(
            watch
        )


    return
        current <= 0

end


--------------------------------------------------
-- GET PERCENT
--------------------------------------------------

function Battery.getPercent(
    watch
)

    if not watch then
        return 0
    end


    local max =
        Battery.getMax(
            watch
        )


    if max <= 0 then
        return 0
    end


    local current =
        Battery.getCurrent(
            watch
        )


    local percent =
        (
            current
            / max
        ) * 100


    return percent

end


--------------------------------------------------
-- DEBUG
--------------------------------------------------

function Battery.debug(
    watch
)

    if not watch then

        print(
            "[MT Smart Watch] "
            .. "Battery: Watch missing"
        )

        return

    end


    local max =
        Battery.getMax(
            watch
        )


    local current =
        Battery.getCurrent(
            watch
        )


    local percent =
        Battery.getPercent(
            watch
        )


    print(
        "[MT Smart Watch] "
        .. "Battery Max: "
        .. tostring(max)
    )


    print(
        "[MT Smart Watch] "
        .. "Battery Current: "
        .. tostring(current)
    )


    print(
        "[MT Smart Watch] "
        .. "Battery Percent: "
        .. tostring(percent)
    )


    print(
        "[MT Smart Watch] "
        .. "Battery Empty: "
        .. tostring(
            Battery.isEmpty(
                watch
            )
        )
    )

end


--------------------------------------------------
-- LOADED
--------------------------------------------------

print(
    "[MT Smart Watch] "
    .. "Battery system loaded"
)