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
-- FIX A: VALUE PRECISION
-- Все записи в ModData округляются до 2 знаков.
-- Убирает IEEE-754 мусор:
--   150 - 0.1 - ...  =>  "145.9", а не 145.8999...
--------------------------------------------------

local VALUE_PRECISION =
    100


--------------------------------------------------
-- FIX 1: THROTTLE CONFIG
-- Минимальный интервал между «рядовыми»
-- сетевыми синхронизациями, мс.
-- События crossedZero / reachedFull
-- игнорируют этот кулдаун.
--------------------------------------------------

local SYNC_MIN_INTERVAL_MS =
    2000


--------------------------------------------------
-- TIMESTAMP DETECTION
-- PZ предоставляет разные API в разных билдах:
--   getTimestampMs() -> миллисекунды
--   getTimestamp()   -> миллисекунды (в актуальных)
-- Fallback через os.clock() -> секунды * 1000.
-- Определяем один раз при загрузке.
--------------------------------------------------

local _timestampSource =
    "none"


local function nowMs()

    if type(getTimestampMs) == "function" then

        _timestampSource =
            "getTimestampMs"


        return
            getTimestampMs()

    end


    if type(getTimestamp) == "function" then

        _timestampSource =
            "getTimestamp"


        return
            getTimestamp()

    end


    _timestampSource =
        "os.clock"


    return
        math.floor(
            os.clock()
            * 1000
        )

end


--------------------------------------------------
-- ROUND
-- Округление half-up до N знаков.
--------------------------------------------------

function Battery.round(
    value
)

    if type(value) ~= "number" then
        return 0
    end


    return
        math.floor(
            value * VALUE_PRECISION + 0.5
        ) / VALUE_PRECISION

end


--------------------------------------------------
-- GET MAX BATTERY
--------------------------------------------------

function Battery.getMax(watch)

    if not watch then
        return 0
    end


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


    if not coreData then
        return 0
    end


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
-- Единственная точка записи заряда.
-- Кламп в [0, max] + округление до 2 знаков.
-- MP-синхронизация троттлинговая, с приоритетом
-- для событий «батарея кончилась» и «заряд полный».
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
    -- FIX A: ROUND
    --------------------------------------------------

    value =
        Battery.round(
            value
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


    local battery =
        modData.MT_SmartWatch.Battery


    --------------------------------------------------
    -- PREVIOUS VALUE
    --------------------------------------------------

    local previous =
        tonumber(battery.current)
        or 0


    battery.current =
        value


    --------------------------------------------------
    -- MP SYNC (THROTTLED, PRIORITIZED)
    --
    -- crossedZero  -> батарея умерла (previous > 0, value <= 0)
    -- reachedFull  -> батарея заряжена до максимума
    -- visibleChange-> изменилась целая часть
    --
    -- crossedZero и reachedFull игнорируют cooldown:
    -- это моменты, ради которых синк и существует.
    --------------------------------------------------

    if watch.transmitModData then

        local now =
            nowMs()


        local last =
            tonumber(
                battery.lastSync
            )
            or 0


        local crossedZero =
            ( previous > 0 )
            and ( value <= 0 )


        local reachedFull =
            ( value >= max )
            and ( previous < max )


        local visibleChange =
            math.floor( previous )
            ~= math.floor( value )


        local cooldownPassed =
            ( now - last )
            >= SYNC_MIN_INTERVAL_MS


        if crossedZero
            or reachedFull
            or (
                cooldownPassed
                and visibleChange
            ) then

            battery.lastSync =
                now


            watch:transmitModData()

        end

    end


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


    if max <= 0 then
        return false
    end


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


    if battery.current == nil then

        battery.current =
            Battery.round(
                max
            )

    else

        battery.current =
            Battery.round(
                math.max(
                    0,
                    math.min(
                        battery.current,
                        max
                    )
                )
            )

    end


    return true

end


--------------------------------------------------
-- DRAIN (STRICT)
-- Транзакция: всё или ничего.
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


    amount =
        tonumber(amount)
        or 0


    if amount <= 0 then
        return true
    end


    local current =
        Battery.getCurrent(
            watch
        )


    if current < amount then

        return false

    end


    return
        Battery.setCurrent(
            watch,
            current - amount
        )

end


--------------------------------------------------
-- DRAIN UP TO (PASSIVE)
--------------------------------------------------

function Battery.drainUpTo(
    watch,
    amount
)

    if not watch then
        return 0
    end


    amount =
        tonumber(amount)
        or 0


    if amount <= 0 then
        return 0
    end


    local current =
        Battery.getCurrent(
            watch
        )


    if current <= 0 then
        return 0
    end


    local drained =
        math.min(
            current,
            amount
        )


    if not Battery.setCurrent(
        watch,
        current - drained
    ) then

        return 0

    end


    return
        drained

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


    return
        (
            current
            / max
        ) * 100

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
        .. string.format(
            "%.2f",
            current
        )
    )


    print(
        "[MT Smart Watch] "
        .. "Battery Percent: "
        .. string.format(
            "%.2f",
            percent
        )
        .. "%"
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
-- Печатаем, какой источник времени выбран —
-- видно сразу в консоли, не надо угадывать.
--------------------------------------------------

-- Прогреваем детектор один раз, чтобы print
-- ниже показал реальный источник.
nowMs()


print(
    "[MT Smart Watch] "
    .. "Battery system loaded "
    .. "(sync timer: "
    .. tostring(_timestampSource)
    .. ")"
)