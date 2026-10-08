--------------------------------------------------
-- MT Smart Watch: Tactical EMP — Revision N+2
-- Target: PZ Build 42.21 (SP + MP)
-- -------------------------------------------------
-- Revision N+2:
--  * Поле регистра: cooldownMinutes (было cooldown).
--  * Публичный API: + getCooldownRemainingMinutes.
--  * LEGACY_COOLDOWN_THRESHOLD: 1e10 -> 1e9.
-- Revision N+1:
--  * Кулдаун переведён на ИГРОВОЕ время
--    (worldAgeHours): пауза останавливает
--    кулдаун вместе с эффектом.
--  * Legacy-кулдауны (реальные мс) мигрируют:
--    считаются истёкшими и чистятся.
--  * F10/Debug: остаток в игровых минутах.
-- Revision M +:
--  * isObjectLocked: throttle cleanup (500 мс)
--  * ISRadioAction: fallback на action.object
--  * MP activate: pending=true до ответа сервера
--  * Battery.drain == false or == nil
--  * startup sweep: лог ожидания игрока
--  * runActivation(): единая точка activate/onClientCommand
--  * ACTIVATED_BY_KIND: O(1) lookup
-- Архитектура (refcount, activeLockSet, sweep, authority,
-- Variant B, транзакция, P0 fix restoreTarget) — не изменена.
--------------------------------------------------

MT_SmartWatch = MT_SmartWatch or {}
MT_SmartWatch.TacticalEMP =
    MT_SmartWatch.TacticalEMP or {}

local EMP = MT_SmartWatch.TacticalEMP

local FULL_TYPE = "Base.MTSW_TChip_EMP"

local HARD_LOCK_INTERVAL_MS = 100
local VEHICLE_ACTION_THROTTLE_MS = 700
local EMP_SAY_COOLDOWN_MS = 3000
local CLICK_LOG_COOLDOWN_MS = 1000
local UNSUPPORTED_LOG_LIMIT = 100
local PATCH_RETRY_INTERVAL_MS = 1000
local PATCH_WARN_TIMEOUT_MS = 30000
local SWEEP_INTERVAL_MS = 60000
local SWEEP_RADIUS = 15
local STARTUP_SWEEP_RADIUS = 20
local STARTUP_SWEEP_RETRY_MS = 30000
local RESULT_ERROR_TTL_MS = 5000

-- Throttle для тяжёлой части isObjectLocked.
local CLEANUP_THROTTLE_MS = 500

-- TTL pending-результата в MP: до прихода EMPResult от сервера.
local PENDING_TTL_MS = 3000

local MIN_WORLD_Z = -8
local MAX_WORLD_Z = 15

local BATT_COST_MIN = 0
local BATT_COST_MAX = 100000
local RADIUS_MIN = 1
local RADIUS_MAX = 50
local DURATION_MIN = 1
local DURATION_MAX = 1440


--------------------------------------------------
-- STATE
--------------------------------------------------

local activePulses = {}
local activeLockSet = {}

local worldReady = false
local lastSweepMs = 0
local lastCleanupMs = 0

local empSayCooldown = setmetatable({}, { __mode = "k" })
local clickLogCooldown = setmetatable({}, { __mode = "k" })
local vehicleActionCooldown = setmetatable({}, { __mode = "k" })


--------------------------------------------------
-- FORWARD
--------------------------------------------------

local restoreFromState
local getKnownPlayers
local clearStaleLocksAround
local performPeriodicSweep
local buildEMPResult


--------------------------------------------------
-- ENV
--------------------------------------------------

local function isDedicatedServer()
    if not isServer() then return false end
    if isClient() then return false end
    return getPlayer() == nil
end


local function isAuthority()
    return (not isClient()) or isServer()
end


--------------------------------------------------
-- ACTIVE LOCK SET
--------------------------------------------------

local function addPulseToLockSet(pulse)
    if not pulse or not pulse.affected then return end
    for i = 1, #pulse.affected do
        local obj = pulse.affected[i].object
        if obj then
            activeLockSet[obj] = (activeLockSet[obj] or 0) + 1
        end
    end
end


local function removePulseFromLockSet(pulse)
    if not pulse or not pulse.affected then return end
    for i = 1, #pulse.affected do
        local obj = pulse.affected[i].object
        if obj then
            local n = activeLockSet[obj]
            if n and n > 1 then
                activeLockSet[obj] = n - 1
            else
                activeLockSet[obj] = nil
            end
        end
    end
end


--------------------------------------------------
-- CONFIG
--------------------------------------------------

local function clampNumber(v, minv, maxv, default)
    v = tonumber(v)
    if not v then return default end
    if v < minv then return minv end
    if v > maxv then return maxv end
    return v
end


local function getData()
    local register = MT_SmartWatch.TacticalChipRegister
    if not register or not register.Data then return nil end
    return register.Data[FULL_TYPE]
end


local function getWatchData(watch)
    if not watch then return nil end
    local modData = watch:getModData()
    if not modData then return nil end
    modData.MT_SmartWatch = modData.MT_SmartWatch or {}
    return modData.MT_SmartWatch
end


local function getCooldowns(watch)
    local watchData = getWatchData(watch)
    if not watchData then return nil end
    watchData.tacticalCooldowns =
        watchData.tacticalCooldowns or {}
    return watchData.tacticalCooldowns
end


--------------------------------------------------
-- COOLDOWN UNITS
-- Кулдаун в ИГРОВЫХ минутах.
-- Живёт на worldAgeHours — тех же часах,
-- что и длительность эффекта. Пауза
-- останавливает оба таймера разом.
--------------------------------------------------

local COOLDOWN_GAME_MIN_MIN = 0
local COOLDOWN_GAME_MIN_MAX = 1440

local DEFAULT_COOLDOWN_GAME_MINUTES = 31

-- Миграция: в modData мог остаться кулдаун старого
-- формата (реальные мс, epoch ~1.7e12). Такие значения
-- считаем истёкшими и чистим при первом чтении.
-- Порог 1e9: миллисекунды epoch (~1.7e12) отсекаются
-- с большим запасом; игровые секунды (hours * 3600)
-- до такого значения практически не дотянут.
local LEGACY_COOLDOWN_THRESHOLD = 1e9


local function nowGameSeconds()

    local gt = getGameTime()

    if not gt then
        return nil
    end


    local ok, hours = pcall(function()
        return gt:getWorldAgeHours()
    end)


    if not ok or type(hours) ~= "number" then
        return nil
    end


    return hours * 3600

end


function EMP.getCooldownRemaining(watch)

    local cooldowns = getCooldowns(watch)

    if not cooldowns then
        return 0
    end


    local readyAt = tonumber(cooldowns.EMP)

    if not readyAt then
        return 0
    end


    -- Legacy-значение из старых сейвов: чистим.
    if readyAt > LEGACY_COOLDOWN_THRESHOLD then
        cooldowns.EMP = nil
        return 0
    end


    local now = nowGameSeconds()

    if not now then
        return 0
    end


    return
        math.max(0, readyAt - now)

end


--------------------------------------------------
-- GET COOLDOWN REMAINING (MINUTES)
-- Удобная обёртка для UI / дебага.
-- Не меняет контракт getCooldownRemaining
-- (тот по-прежнему возвращает секунды).
--------------------------------------------------

function EMP.getCooldownRemainingMinutes(watch)

    return
        EMP.getCooldownRemaining(watch)
        / 60

end


--------------------------------------------------
-- SAFE HELPERS
--------------------------------------------------

local function safeCall(object, methodName, ...)
    if not object then return false, nil end
    local method = object[methodName]
    if type(method) ~= "function" then return false, nil end
    local ok, result = pcall(method, object, ...)
    if not ok then return false, nil end
    return true, result
end


local function safeInstanceOf(object, className)
    if not object then return false end
    local ok, result = pcall(function()
        return instanceof(object, className)
    end)
    return ok and result == true
end


local function isObjectInWorld(object)
    if not object then return false end
    local ok, square = pcall(function()
        return object:getSquare()
    end)
    return ok and square ~= nil
end


--------------------------------------------------
-- LOCALIZATION
--------------------------------------------------

local function sayEMPBlocked(player)
    if not player then return end
    local localization =
        MT_SmartWatch.TacticalEMP
        and MT_SmartWatch.TacticalEMP.Localization
    if not localization
        or not localization.sayObjectBlocked then
        return
    end
    local now = getTimestampMs()
    local last = empSayCooldown[player]
    if last and (now - last) < EMP_SAY_COOLDOWN_MS then
        return
    end
    empSayCooldown[player] = now
    localization.sayObjectBlocked(player)
end


--------------------------------------------------
-- DEBUG NAME
--------------------------------------------------

local function getObjectDebugName(object)
    local objectName = "unknown"
    local okName, name = safeCall(object, "getObjectName")
    if okName and name then
        objectName = tostring(name)
    else
        local okSprite, sprite = safeCall(object, "getSprite")
        if okSprite and sprite then
            local okSpriteName, spriteName =
                safeCall(sprite, "getName")
            if okSpriteName and spriteName then
                objectName = tostring(spriteName)
            end
        end
    end
    return objectName
end


--------------------------------------------------
-- MOD DATA
--------------------------------------------------

local function getObjectModData(object)
    if not object then return nil end
    local ok, modData = safeCall(object, "getModData")
    if ok and modData then return modData end
    return nil
end


local EMP_LOCK_KEY = "MTSW_EMP_LOCK"


--------------------------------------------------
-- SNAPSHOT
--------------------------------------------------

local function snapshotOriginalState(target)
    local state = {}
    for k, v in pairs(target) do
        if k ~= "object" then
            state[k] = v
        end
    end
    return state
end


--------------------------------------------------
-- INCREMENT LOCK
--------------------------------------------------

local function incrementLock(object, target)
    local modData = getObjectModData(object)
    if not modData then return false end

    local lock = modData[EMP_LOCK_KEY]

    if type(lock) == "table"
        and (tonumber(lock.lockCount) or 0) > 0
        and not activeLockSet[object] then

        modData[EMP_LOCK_KEY] = nil
        lock = nil
    end

    if lock == true then
        modData[EMP_LOCK_KEY] = nil
        lock = nil
    end

    if type(lock) ~= "table" then
        lock = { lockCount = 0, originalState = nil }
        modData[EMP_LOCK_KEY] = lock
    end

    local current = tonumber(lock.lockCount) or 0

    if current == 0 or not lock.originalState then
        lock.originalState = snapshotOriginalState(target)
    end

    lock.lockCount = current + 1

    safeCall(object, "transmitModData")
    return true
end


--------------------------------------------------
-- DECREMENT LOCK COMMIT
--------------------------------------------------

local function decrementLockCommit(object, restoreFn)
    local modData = getObjectModData(object)
    if not modData then return false, nil end

    local lock = modData[EMP_LOCK_KEY]

    if lock == true then
        if isAuthority() then
            modData[EMP_LOCK_KEY] = nil
            safeCall(object, "transmitModData")
        end
        return false, nil
    end

    if type(lock) ~= "table" then
        return false, nil
    end

    local current = tonumber(lock.lockCount) or 0

    if current <= 0 then
        if isAuthority() then
            modData[EMP_LOCK_KEY] = nil
            safeCall(object, "transmitModData")
        end
        return false, nil
    end

    local newCount = current - 1
    lock.lockCount = newCount

    if newCount > 0 then
        safeCall(object, "transmitModData")
        return false, lock.originalState
    end

    local originalState = lock.originalState
    modData[EMP_LOCK_KEY] = nil

    if restoreFn and originalState then
        pcall(restoreFn, object, originalState)
    end

    safeCall(object, "transmitModData")
    return true, originalState
end


--------------------------------------------------
-- CLEANUP STALE LOCK
--------------------------------------------------

local function cleanupStaleLock(object)
    if not object then return false end

    local modData = getObjectModData(object)
    if not modData then return false end

    local lock = modData[EMP_LOCK_KEY]
    if lock == nil then return false end

    if type(lock) ~= "table" then
        if isAuthority() then
            modData[EMP_LOCK_KEY] = nil
            safeCall(object, "transmitModData")
        end
        return true
    end

    local count = tonumber(lock.lockCount) or 0
    if count <= 0 then
        if isAuthority() then
            modData[EMP_LOCK_KEY] = nil
            safeCall(object, "transmitModData")
        end
        return true
    end

    if activeLockSet[object] then
        return false
    end

    if not isAuthority() then
        return false
    end

    local originalState = lock.originalState
    modData[EMP_LOCK_KEY] = nil

    if originalState
        and originalState.kind == "lightSwitch"
        and originalState.canBeModified ~= nil
        and isObjectInWorld(object) then

        safeCall(
            object,
            "setCanBeModified",
            originalState.canBeModified == true
        )
    end

    safeCall(object, "transmitModData")
    return true
end


-- Hot path: вызывается из каждого патченного isValid/perform.
-- Лёгкая проверка (чтение lockCount) — каждый вызов.
-- Тяжёлая зачистка stale-локов — throttle раз в CLEANUP_THROTTLE_MS.
function EMP.isObjectLocked(object)
    if not object then return false end

    local modData = getObjectModData(object)
    if not modData then return false end

    local lock = modData[EMP_LOCK_KEY]
    if type(lock) ~= "table" then return false end

    local count = tonumber(lock.lockCount) or 0
    if count <= 0 then return false end

    local now = getTimestampMs()
    if (now - lastCleanupMs) >= CLEANUP_THROTTLE_MS then
        lastCleanupMs = now
        cleanupStaleLock(object)
    end

    return true
end


--------------------------------------------------
-- ADD TARGET
--------------------------------------------------

local function addAffected(affected, seen, object, target)
    if not object then return false end
    if seen[object] then return false end
    if not incrementLock(object, target) then return false end
    target.object = object
    affected[#affected + 1] = target
    seen[object] = true
    return true
end


--------------------------------------------------
-- PARENT
--------------------------------------------------

local function getParentObject(object)
    local okParent, parent = safeCall(object, "getParent")
    if okParent and parent
        and safeInstanceOf(parent, "IsoObject") then
        return parent
    end
    return nil
end


--------------------------------------------------
-- ACTIVATED-KINDS
--------------------------------------------------

local ACTIVATED_KINDS = {
    { kind = "generator",
      cls = "IsoGenerator",
      read = "isActivated" },

    { kind = "stove",
      cls = "IsoStove",
      read = "Activated" },

    { kind = "carBatteryCharger",
      cls = "IsoCarBatteryCharger",
      read = "isActivated" },

    { kind = "clothingWasher",
      cls = "IsoClothingWasher",
      read = "isActivated" },

    { kind = "clothingDryer",
      cls = "IsoClothingDryer",
      read = "isActivated" },

    { kind = "combinationWasherDryer",
      cls = "IsoCombinationWasherDryer",
      read = "isActivated" },
}


local ACTIVATED_BY_KIND = {}
for i = 1, #ACTIVATED_KINDS do
    local d = ACTIVATED_KINDS[i]
    ACTIVATED_BY_KIND[d.kind] = d
end


local function readActivated(object, methodName)
    local ok, v = safeCall(object, methodName)
    if not ok then return false, false end
    return true, v == true
end


--------------------------------------------------
-- UNSUPPORTED COUNTER
--------------------------------------------------

local function recordUnsupported(counts, objectName)
    local existing = counts.unsupported[objectName]
    if existing then
        counts.unsupported[objectName] = existing + 1
    elseif (counts.unsupportedCount or 0) < UNSUPPORTED_LOG_LIMIT then
        counts.unsupported[objectName] = 1
        counts.unsupportedCount =
            (counts.unsupportedCount or 0) + 1
    else
        counts.unsupportedDropped =
            (counts.unsupportedDropped or 0) + 1
    end
end


--------------------------------------------------
-- DISABLE TARGET
--------------------------------------------------

local function disableTarget(object, affected, seen, counts)
    if not object then return end

    for i = 1, #ACTIVATED_KINDS do
        local d = ACTIVATED_KINDS[i]
        if safeInstanceOf(object, d.cls) then
            local okRead, wasActivated =
                readActivated(object, d.read)
            if not okRead then return end

            local target = {
                kind = d.kind,
                activated = wasActivated,
            }
            if addAffected(
                affected, seen, object, target
            ) then
                if wasActivated then
                    safeCall(object, "setActivated", false)
                end
            end
            return
        end
    end

    if safeInstanceOf(object, "IsoLightSwitch") then
        local okActivated, wasActivated =
            safeCall(object, "isActivated")
        if not okActivated then return end

        local okCanModify, canBeModified =
            safeCall(object, "getCanBeModified")

        wasActivated = wasActivated == true
        canBeModified =
            (not okCanModify or canBeModified == true)

        local target = {
            kind = "lightSwitch",
            activated = wasActivated,
            canBeModified = canBeModified,
        }
        if addAffected(affected, seen, object, target) then
            safeCall(object, "setCanBeModified", false)
            if wasActivated then
                safeCall(object, "setActive", false, false, true)
            end
            safeCall(object, "setActivated", false)
        end
        return
    end

    if safeInstanceOf(object, "IsoStackedWasherDryer") then
        local okWasher, washerActive =
            safeCall(object, "isWasherActivated")
        local okDryer, dryerActive =
            safeCall(object, "isDryerActivated")
        if not okWasher or not okDryer then return end
        washerActive = washerActive == true
        dryerActive = dryerActive == true

        local target = {
            kind = "stackedWasherDryer",
            washerActivated = washerActive,
            dryerActivated = dryerActive,
        }
        if addAffected(affected, seen, object, target) then
            if washerActive then
                safeCall(object, "setWasherActivated", false)
            end
            if dryerActive then
                safeCall(object, "setDryerActivated", false)
            end
        end
        return
    end

    if safeInstanceOf(object, "IsoWaveSignal") then
        local okData, deviceData =
            safeCall(object, "getDeviceData")
        if okData and deviceData then
            local okOn, turnedOn =
                safeCall(deviceData, "getIsTurnedOn")
            local target = {
                kind = "deviceData",
                turnedOn = (okOn and turnedOn == true),
            }
            if addAffected(affected, seen, object, target) then
                if okOn and turnedOn == true then
                    safeCall(deviceData, "setIsTurnedOn", false)
                end
            end
        end
        return
    end

    if not safeInstanceOf(object, "IsoLightSwitch") then
        local okLight, lightSource =
            safeCall(object, "getLightSource")
        if okLight and lightSource then
            local okActive, active =
                safeCall(lightSource, "isActive")
            local okHydro, hydroPowered =
                safeCall(lightSource, "isHydroPowered")
            local isPowered =
                (not okHydro or hydroPowered == true)

            if isPowered then
                local parent = getParentObject(lightSource)
                    or object
                local isParent =
                    parent
                    and not safeInstanceOf(
                        parent, "IsoLightSource"
                    )

                if isParent then
                    local wasActive =
                        (okActive and active == true)
                    local target = {
                        kind = "lightSource",
                        active = wasActive,
                        unknownState = not okActive,
                    }
                    if addAffected(
                        affected, seen, parent, target
                    ) then
                        if okActive and wasActive then
                            safeCall(
                                lightSource, "setActive", false
                            )
                        end
                    end
                end
            end
        end
    end

    local okP, powered =
        safeCall(object, "couldBePoweredByGenerator")
    local okC, consumption =
        safeCall(object, "getGeneratorPowerConsumption")
    local poweredByGenerator = okP and powered == true
    local powerConsumption = okC and tonumber(consumption) or 0

    if poweredByGenerator and powerConsumption > 0 then
        if not seen[object] then
            local okIsActivated, isActivated =
                safeCall(object, "isActivated")
            local okActivatedMethod, dummy =
                safeCall(object, "Activated")
            local hasSetActivated =
                type(object.setActivated) == "function"

            if (okIsActivated or okActivatedMethod)
                and hasSetActivated then
                local currentActive =
                    (okIsActivated and isActivated == true)
                    or (okActivatedMethod and dummy == true)
                local target = {
                    kind = "genericActivated",
                    activated = currentActive,
                }
                if addAffected(
                    affected, seen, object, target
                ) then
                    safeCall(object, "setActivated", false)
                end
            end
        end

        if not seen[object] then
            local okActivated, active =
                safeCall(object, "Activated")
            local hasToggle =
                type(object.Toggle) == "function"
            if okActivated and hasToggle then
                local target = {
                    kind = "genericToggle",
                    activated = active == true,
                }
                if addAffected(
                    affected, seen, object, target
                ) then
                    if active == true then
                        safeCall(object, "Toggle")
                    end
                end
            end
        end

        if not seen[object] then
            recordUnsupported(
                counts, getObjectDebugName(object)
            )
        end
    end
end


--------------------------------------------------
-- DISABLE VEHICLE
--------------------------------------------------

local function disableVehicle(vehicle, affected, seen, counts)
    if not vehicle then return end

    local okStarted, wasStarted =
        safeCall(vehicle, "isEngineStarted")
    local okRunning, wasRunning =
        safeCall(vehicle, "isEngineRunning")
    wasStarted = okStarted and wasStarted == true
    wasRunning = okRunning and wasRunning == true

    local okHeadlights, headlightsOn =
        safeCall(vehicle, "getHeadlightsOn")
    local okWindowLights, windowLightsOn =
        safeCall(vehicle, "getWindowLightsOn")
    headlightsOn = okHeadlights and headlightsOn == true
    windowLightsOn = okWindowLights and windowLightsOn == true

    local target = {
        kind = "vehicle",
        headlightsOn = headlightsOn,
        windowLightsOn = windowLightsOn,
    }

    if addAffected(affected, seen, vehicle, target) then
        if wasStarted or wasRunning then
            safeCall(vehicle, "shutOff")
        end
        if headlightsOn then
            safeCall(vehicle, "setHeadlightsOn", false)
        end
        if windowLightsOn then
            safeCall(vehicle, "setWindowLightsOn", false)
        end
    end
end


--------------------------------------------------
-- PULSE TARGETS
--------------------------------------------------

local function pulseTargets(
    player, radius, affected, seen, counts
)
    local cell = getCell()
    if not cell then return false end

    radius = math.floor(radius)

    local centerX = math.floor(player:getX())
    local centerY = math.floor(player:getY())
    local centerZ = math.floor(player:getZ())

    local minX = centerX - radius
    local maxX = centerX + radius
    local minY = centerY - radius
    local maxY = centerY + radius
    local minZ = math.max(MIN_WORLD_Z, centerZ - radius)
    local maxZ = math.min(MAX_WORLD_Z, centerZ + radius)

    counts.effectiveMinZ = minZ
    counts.effectiveMaxZ = maxZ

    local r2 = radius * radius

    for x = minX, maxX do
        local dx = x - centerX
        for y = minY, maxY do
            local dy = y - centerY
            local dxy2 = dx * dx + dy * dy
            if dxy2 <= r2 then
                for z = minZ, maxZ do
                    local dz = z - centerZ
                    if dxy2 + dz * dz <= r2 then
                        local square =
                            cell:getGridSquare(x, y, z)
                        if square then
                            local objects = square:getObjects()
                            if objects then
                                for i = 0,
                                    objects:size() - 1 do
                                    local object = objects:get(i)
                                    if object then
                                        disableTarget(
                                            object,
                                            affected,
                                            seen,
                                            counts
                                        )
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    local vehicles = cell:getVehicles()
    if vehicles then
        local iterator = vehicles:iterator()
        while iterator:hasNext() do
            local vehicle = iterator:next()
            if vehicle then
                local vx = math.floor(vehicle:getX())
                local vy = math.floor(vehicle:getY())
                local vz = math.floor(vehicle:getZ())
                local ddx = vx - centerX
                local ddy = vy - centerY
                local ddz = vz - centerZ
                if ddx*ddx + ddy*ddy + ddz*ddz <= r2 then
                    disableVehicle(
                        vehicle, affected, seen, counts
                    )
                end
            end
        end
    end

    if IsoGenerator
        and IsoGenerator.updateSurroundingNow then
        IsoGenerator.updateSurroundingNow()
    end

    return true
end


--------------------------------------------------
-- REMAINING TIME
--------------------------------------------------

function EMP.getActiveRemainingGameMinutes(owner)
    if not worldReady then return 0 end
    local gt = getGameTime()
    if not gt then return 0 end
    local now = gt:getWorldAgeHours()
    local remaining = 0

    for i = 1, #activePulses do
        local pulse = activePulses[i]
        if pulse and pulse.expiresAt > now then
            local matchesOwner =
                owner == nil
                or pulse.owner == owner
                or pulse.watch == owner
            if matchesOwner then
                local value = (pulse.expiresAt - now) * 60
                if value > remaining then
                    remaining = value
                end
            end
        end
    end
    return remaining
end


--------------------------------------------------
-- ENFORCE TARGET OFF
--------------------------------------------------

local function enforceTargetOff(target)
    if not target or not target.object then
        return false
    end
    local object = target.object
    if not isObjectInWorld(object) then return false end

    local kind = target.kind

    local d = ACTIVATED_BY_KIND[kind]
    if d and safeInstanceOf(object, d.cls) then
        local okRead, active =
            readActivated(object, d.read)
        if okRead and active then
            safeCall(object, "setActivated", false)
            return true
        end
        return false
    end

    if kind == "lightSwitch"
        and safeInstanceOf(object, "IsoLightSwitch") then
        local changed = false
        local okCanModify, canBeModified =
            safeCall(object, "getCanBeModified")
        if not okCanModify or canBeModified ~= false then
            safeCall(object, "setCanBeModified", false)
            changed = true
        end
        local okActivated, active =
            safeCall(object, "isActivated")
        if okActivated and active == true then
            safeCall(object, "setActive", false, false, true)
            safeCall(object, "setActivated", false)
            changed = true
        end
        return changed
    end

    if kind == "stackedWasherDryer"
        and safeInstanceOf(object, "IsoStackedWasherDryer") then
        local changed = false
        local okWasher, washerActive =
            safeCall(object, "isWasherActivated")
        if okWasher and washerActive == true then
            safeCall(object, "setWasherActivated", false)
            changed = true
        end
        local okDryer, dryerActive =
            safeCall(object, "isDryerActivated")
        if okDryer and dryerActive == true then
            safeCall(object, "setDryerActivated", false)
            changed = true
        end
        return changed
    end

    if kind == "deviceData" then
        local okData, deviceData =
            safeCall(object, "getDeviceData")
        if okData and deviceData then
            local okOn, turnedOn =
                safeCall(deviceData, "getIsTurnedOn")
            if okOn and turnedOn == true then
                safeCall(deviceData, "setIsTurnedOn", false)
                return true
            end
        end
        return false
    end

    if kind == "lightSource" then
        local okLight, lightSource =
            safeCall(object, "getLightSource")
        if okLight and lightSource then
            local okActive, active =
                safeCall(lightSource, "isActive")
            if okActive and active == true then
                safeCall(lightSource, "setActive", false)
                return true
            end
        end
        return false
    end

    if kind == "genericActivated" then
        local okIsActivated, isActivated =
            safeCall(object, "isActivated")
        local okActivatedMethod, activatedResult =
            safeCall(object, "Activated")
        local active =
            (okIsActivated and isActivated == true)
            or (okActivatedMethod
                and activatedResult == true)
        if active then
            safeCall(object, "setActivated", false)
            return true
        end
        return false
    end

    if kind == "genericToggle" then
        local okActivated, active =
            safeCall(object, "Activated")
        if okActivated and active == true
            and type(object.Toggle) == "function" then
            safeCall(object, "Toggle")
            return true
        end
        return false
    end

    if kind == "vehicle" then
        local changed = false
        local okStarted, started =
            safeCall(object, "isEngineStarted")
        local okRunning, running =
            safeCall(object, "isEngineRunning")
        if (okStarted and started == true)
            or (okRunning and running == true) then
            safeCall(object, "shutOff")
            changed = true
        end
        local okHeadlights, headlightsOn =
            safeCall(object, "getHeadlightsOn")
        if okHeadlights and headlightsOn == true then
            safeCall(object, "setHeadlightsOn", false)
            changed = true
        end
        local okWindowLights, windowLightsOn =
            safeCall(object, "getWindowLightsOn")
        if okWindowLights and windowLightsOn == true then
            safeCall(object, "setWindowLightsOn", false)
            changed = true
        end
        return changed
    end

    EMP._unknownKindLogged = EMP._unknownKindLogged or {}
    if not EMP._unknownKindLogged[kind] then
        EMP._unknownKindLogged[kind] = true
        print(
            "[MT Smart Watch] EMP unknown target kind: "
            .. tostring(kind)
        )
    end
    return false
end


--------------------------------------------------
-- RESTORE FROM STATE
--------------------------------------------------

restoreFromState = function(object, originalState)
    if not object
        or type(originalState) ~= "table" then
        return false
    end

    if not isObjectInWorld(object) then
        return false
    end

    local kind = originalState.kind

    local d = ACTIVATED_BY_KIND[kind]
    if d and safeInstanceOf(object, d.cls) then
        return (safeCall(
            object, "setActivated",
            originalState.activated == true
        ))
    end

    if kind == "lightSwitch"
        and safeInstanceOf(object, "IsoLightSwitch") then
        local ok1 = safeCall(
            object, "setActive",
            originalState.activated == true,
            false, true
        )
        local ok2 = safeCall(
            object, "setActivated",
            originalState.activated == true
        )
        local ok3 = false
        if originalState.canBeModified ~= nil then
            ok3 = safeCall(
                object, "setCanBeModified",
                originalState.canBeModified == true
            )
        end
        return ok1 or ok2 or ok3
    end

    if kind == "stackedWasherDryer"
        and safeInstanceOf(object, "IsoStackedWasherDryer") then
        local ok1 = true
        local ok2 = true
        if originalState.washerActivated ~= nil then
            ok1 = safeCall(
                object, "setWasherActivated",
                originalState.washerActivated == true
            )
        end
        if originalState.dryerActivated ~= nil then
            ok2 = safeCall(
                object, "setDryerActivated",
                originalState.dryerActivated == true
            )
        end
        return ok1 or ok2
    end

    if kind == "deviceData" then
        local okData, deviceData =
            safeCall(object, "getDeviceData")
        if okData and deviceData then
            return (safeCall(
                deviceData, "setIsTurnedOn",
                originalState.turnedOn == true
            ))
        end
        return false
    end

    if kind == "lightSource" then
        if originalState.unknownState then
            return true
        end
        local okLight, lightSource =
            safeCall(object, "getLightSource")
        if okLight and lightSource then
            return (safeCall(
                lightSource, "setActive",
                originalState.active == true
            ))
        end
        return false
    end

    if kind == "genericActivated" then
        return (safeCall(
            object, "setActivated",
            originalState.activated == true
        ))
    end

    if kind == "genericToggle" then
        local okActivated, active =
            safeCall(object, "Activated")
        if not okActivated then return false end

        local wantActive =
            originalState.activated == true

        if active ~= wantActive
            and type(object.Toggle) == "function" then
            return (safeCall(object, "Toggle"))
        end
        return (active == wantActive)
    end

    if kind == "vehicle" then
        local ok1 = safeCall(
            object, "setHeadlightsOn",
            originalState.headlightsOn == true
        )
        local ok2 = safeCall(
            object, "setWindowLightsOn",
            originalState.windowLightsOn == true
        )
        return ok1 or ok2
    end

    return false
end


--------------------------------------------------
-- RESTORE TARGET
--------------------------------------------------

local function restoreTarget(target)
    if not target or not target.object then
        return false
    end
    local object = target.object

    if not isObjectInWorld(object) then
        return false
    end

    local released = decrementLockCommit(
        object, restoreFromState
    )
    return released == true
end


--------------------------------------------------
-- STALE CLEANUP
--------------------------------------------------

local function clearStaleLocksInSquare(square)
    if not square then return 0 end
    local objects = square:getObjects()
    if not objects then return 0 end

    local cleared = 0
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        if object and cleanupStaleLock(object) then
            cleared = cleared + 1
        end
    end
    return cleared
end


clearStaleLocksAround = function(player, radius)
    if not player then return 0 end
    local cell = getCell()
    if not cell then return 0 end

    radius = math.floor(tonumber(radius) or SWEEP_RADIUS)

    local centerX = math.floor(player:getX())
    local centerY = math.floor(player:getY())
    local centerZ = math.floor(player:getZ())

    local minX = centerX - radius
    local maxX = centerX + radius
    local minY = centerY - radius
    local maxY = centerY + radius
    local minZ = math.max(MIN_WORLD_Z, centerZ - radius)
    local maxZ = math.min(MAX_WORLD_Z, centerZ + radius)

    local r2 = radius * radius
    local cleared = 0

    for x = minX, maxX do
        local dx = x - centerX
        for y = minY, maxY do
            local dy = y - centerY
            local dxy2 = dx * dx + dy * dy
            if dxy2 <= r2 then
                for z = minZ, maxZ do
                    local dz = z - centerZ
                    if dxy2 + dz * dz <= r2 then
                        local square =
                            cell:getGridSquare(x, y, z)
                        if square then
                            cleared = cleared
                                + clearStaleLocksInSquare(square)
                        end
                    end
                end
            end
        end
    end

    local vehicles = cell:getVehicles()
    if vehicles then
        local iterator = vehicles:iterator()
        while iterator:hasNext() do
            local vehicle = iterator:next()
            if vehicle then
                local vx = math.floor(vehicle:getX())
                local vy = math.floor(vehicle:getY())
                local vz = math.floor(vehicle:getZ())
                local ddx = vx - centerX
                local ddy = vy - centerY
                local ddz = vz - centerZ
                if ddx*ddx + ddy*ddy + ddz*ddz
                    <= r2 then
                    if cleanupStaleLock(vehicle) then
                        cleared = cleared + 1
                    end
                end
            end
        end
    end

    return cleared
end


--------------------------------------------------
-- KNOWN PLAYERS
--------------------------------------------------

local function tryAppendPlayerList(result, list)
    if not list then return end
    local okSize, size = pcall(function()
        return list:size()
    end)
    if okSize and size then
        for i = 0, size - 1 do
            local okP, p = pcall(function()
                return list:get(i)
            end)
            if okP and p then result[#result + 1] = p end
        end
        return
    end
    for i = 1, #list do
        local p = list[i]
        if p then result[#result + 1] = p end
    end
end


getKnownPlayers = function()
    local result = {}

    if getOnlinePlayers then
        local ok, list = pcall(function()
            return getOnlinePlayers()
        end)
        if ok then tryAppendPlayerList(result, list) end
    end

    if #result == 0 and getPlayers then
        local ok, list = pcall(function()
            return getPlayers()
        end)
        if ok then tryAppendPlayerList(result, list) end
    end

    if #result == 0 then
        local p = getPlayer()
        if p then result[#result + 1] = p end
    end
    return result
end


--------------------------------------------------
-- SWEEP
--------------------------------------------------

performPeriodicSweep = function()
    if not isAuthority() then return end
    if not worldReady then return end

    local now = getTimestampMs()
    if (now - lastSweepMs) < SWEEP_INTERVAL_MS then
        return
    end
    lastSweepMs = now

    if not getCell() then return end

    local players = getKnownPlayers()
    if #players == 0 then
        EMP._sweepEmptyLogged =
            (EMP._sweepEmptyLogged or 0) + 1
        if EMP._sweepEmptyLogged == 1 then
            print(
                "[MT Smart Watch] EMP sweep: no players found"
            )
        end
        return
    end

    local total = 0
    for i = 1, #players do
        total = total
            + clearStaleLocksAround(players[i], SWEEP_RADIUS)
    end

    if total > 0 then
        print(
            "[MT Smart Watch] EMP periodic sweep cleared locks: "
            .. tostring(total)
        )
    end
end


local function tryStartupSweep()
    if EMP._startupSweepDone then return true end
    if not isAuthority() then
        EMP._startupSweepDone = true
        return true
    end

    if not getCell() then return false end

    local players = getKnownPlayers()
    if #players == 0 then
        if not EMP._startupSweepWaitingLogged then
            EMP._startupSweepWaitingLogged = true
            print(
                "[MT Smart Watch] EMP startup sweep: "
                .. "waiting for first player"
            )
        end
        return false
    end

    local cleared = 0
    for i = 1, #players do
        cleared = cleared + clearStaleLocksAround(
            players[i], STARTUP_SWEEP_RADIUS
        )
    end

    if cleared > 0 then
        print(
            "[MT Smart Watch] EMP startup sweep cleared locks: "
            .. tostring(cleared)
        )
    end

    EMP._startupSweepDone = true
    return true
end


--------------------------------------------------
-- RESULT BUILDER
--------------------------------------------------

buildEMPResult = function(
    ok, reason, remainingMinutes, durationMinutes
)
    local nowMs = getTimestampMs()
    local expectedEndWorldAgeHours = nil

    if ok and durationMinutes and durationMinutes > 0 then
        local gt = getGameTime()
        if gt then
            expectedEndWorldAgeHours =
                gt:getWorldAgeHours() + durationMinutes / 60
        end
    end

    local expiresAtMs = nil
    if not ok or not expectedEndWorldAgeHours then
        expiresAtMs = nowMs + RESULT_ERROR_TTL_MS
    end

    return {
        ok = ok == true,
        reason = tostring(reason or "unknown"),
        remainingMinutes = tonumber(remainingMinutes) or 0,
        durationMinutes = tonumber(durationMinutes) or 0,
        receivedAtMs = nowMs,
        expiresAtMs = expiresAtMs,
        expectedEndWorldAgeHours = expectedEndWorldAgeHours,
    }
end


--------------------------------------------------
-- ACTIVATE EMP (internal)
--------------------------------------------------

local function activateEMPInternal(player, watch)
    if not player then
        print("[MT Smart Watch] EMP ERROR: Player missing")
        return false, "no_player", 0
    end
    if not watch then
        print("[MT Smart Watch] EMP ERROR: Watch missing")
        return false, "no_watch", 0
    end

    local chipSystem = MT_SmartWatch.ChipSystem
    if not chipSystem or not chipSystem.hasChip then
        print(
            "[MT Smart Watch] EMP ERROR: ChipSystem unavailable"
        )
        return false, "no_chipsystem", 0
    end
    if not chipSystem.hasChip(watch, FULL_TYPE) then
        print(
            "[MT Smart Watch] EMP ERROR: EMP chip not installed"
        )
        return false, "no_chip", 0
    end

    local data = getData()
    if not data then
        print("[MT Smart Watch] EMP ERROR: data missing")
        return false, "no_data", 0
    end

    if EMP.getCooldownRemaining(watch) > 0 then
        print("[MT Smart Watch] EMP ERROR: Cooldown active")
        return false, "cooldown", 0
    end

    if EMP.getActiveRemainingGameMinutes(watch) > 0 then
        print(
            "[MT Smart Watch] EMP ERROR: already active"
        )
        return false, "already_active", 0
    end

    local Battery = MT_SmartWatch.Battery
    if not Battery then
        print(
            "[MT Smart Watch] EMP ERROR: Battery module missing"
        )
        return false, "no_battery_module", 0
    end

    local okInit = pcall(function()
        Battery.initialize(watch)
    end)
    if not okInit then
        return false, "battery_init_failed", 0
    end

    local batteryCost = clampNumber(
        data.batteryCost,
        BATT_COST_MIN, BATT_COST_MAX, 0
    )
    local batteryBefore = Battery.getCurrent(watch)
    if batteryBefore < batteryCost then
        print("[MT Smart Watch] EMP ERROR: Not enough battery")
        return false, "no_battery", 0
    end

    local radius = clampNumber(
        data.radius, RADIUS_MIN, RADIUS_MAX, 15
    )
    local durationMinutes = clampNumber(
        data.durationMinutes,
        DURATION_MIN, DURATION_MAX, 30
    )
    local cooldownGameMinutes = clampNumber(
        data.cooldownMinutes,
        COOLDOWN_GAME_MIN_MIN,
        COOLDOWN_GAME_MIN_MAX,
        DEFAULT_COOLDOWN_GAME_MINUTES
    )

    local affected = {}
    local seen = {}

    local counts = {
        effectiveMinZ = 0,
        effectiveMaxZ = 0,
        unsupported = {},
        unsupportedCount = 0,
        unsupportedDropped = 0,
    }

    local savedCooldowns = getCooldowns(watch)
    local savedCooldownValue =
        savedCooldowns and savedCooldowns.EMP

    local pulseAdded = false

    local commitOk, commitErr = pcall(function()
        local scanOk, scanResult = pcall(
            pulseTargets,
            player, radius, affected, seen, counts
        )
        if not scanOk or scanResult == false then
            error("scan_failed")
        end

        local gt = getGameTime()
        local nowWorldAgeHours =
            gt and gt:getWorldAgeHours() or 0

        local pulse = {
            startedAt = nowWorldAgeHours,
            expiresAt =
                nowWorldAgeHours
                + durationMinutes / 60,
            affected = affected,
            owner = player,
            watch = watch,
            nextEnforceAtMs =
                getTimestampMs() + HARD_LOCK_INTERVAL_MS,
        }

        addPulseToLockSet(pulse)
        activePulses[#activePulses + 1] = pulse
        pulseAdded = true

        -- Контракт: Battery.drain атомарен и возвращает false/nil
        -- при провале. Откат батареи при partial-spend не выполняется —
        -- мы восстанавливаем только cooldown и локи.
        local drained = Battery.drain(watch, batteryCost)
        if drained == false or drained == nil then
            error("battery_drain_failed")
        end

        -- Кулдаун в игровых секундах на worldAgeHours.
        -- Если игровой таймер недоступен — кулдаун
        -- в этот каст не ставится (rollback не задет).
        if savedCooldowns then
            local now = nowGameSeconds()
            if now then
                savedCooldowns.EMP =
                    now
                    + cooldownGameMinutes * 60
            end
        end

        if isClient() or isServer() then
            safeCall(watch, "transmitModData")
        end
    end)

    if not commitOk then
        print(
            "[MT Smart Watch] EMP ERROR: commit failed: "
            .. tostring(commitErr)
        )

        if pulseAdded then
            local last = activePulses[#activePulses]
            if last then
                removePulseFromLockSet(last)
                table.remove(activePulses, #activePulses)
            end
        end

        for i = 1, #affected do
            local target = affected[i]
            if target and target.object then
                decrementLockCommit(
                    target.object, restoreFromState
                )
            end
        end

        if savedCooldowns then
            savedCooldowns.EMP = savedCooldownValue
        end

        return false, "commit_failed", 0
    end

    local batteryAfter = Battery.getCurrent(watch)

    print("[MT Smart Watch] EMP ACTIVATED")
    print("[MT Smart Watch] EMP Radius: " .. tostring(radius))
    print(
        "[MT Smart Watch] EMP Vertical Range: "
        .. tostring(counts.effectiveMinZ)
        .. " to " .. tostring(counts.effectiveMaxZ)
    )
    print(
        "[MT Smart Watch] EMP Duration: "
        .. tostring(durationMinutes) .. " game minutes"
    )
    print(
        "[MT Smart Watch] EMP Total Targets: "
        .. tostring(#affected)
    )
    print(
        "[MT Smart Watch] EMP Battery: "
        .. tostring(batteryBefore)
        .. " -> " .. tostring(batteryAfter)
    )
    print(
        "[MT Smart Watch] EMP Cooldown: "
        .. tostring(cooldownGameMinutes)
        .. " game minutes"
    )

    local unsupportedCount = 0
    for objectName, amount in pairs(counts.unsupported) do
        unsupportedCount = unsupportedCount + 1
        print(
            "[MT Smart Watch] EMP Unsupported Power Object: "
            .. tostring(objectName)
            .. " x" .. tostring(amount)
        )
    end
    if unsupportedCount == 0 then
        print(
            "[MT Smart Watch] EMP Unsupported Power Objects: none"
        )
    end
    if (counts.unsupportedDropped or 0) > 0 then
        print(
            "[MT Smart Watch] EMP Unsupported (truncated): "
            .. tostring(counts.unsupportedDropped)
        )
    end

    return true, "ok", durationMinutes
end


--------------------------------------------------
-- RUN ACTIVATION (единая точка)
-- Возвращает (result, ok, reason).
-- result записывается в EMP._lastServerResult.
--------------------------------------------------

local function runActivation(player, watch)
    local ok, reason, durationMinutes =
        activateEMPInternal(player, watch)

    local remainingMinutes = 0
    if ok then
        remainingMinutes =
            EMP.getActiveRemainingGameMinutes(watch)
    end

    local result = buildEMPResult(
        ok, reason, remainingMinutes, durationMinutes
    )

    EMP._lastServerResult = result

    return result, ok, reason
end


--------------------------------------------------
-- UPDATE ACTIVE PULSES
--------------------------------------------------

local function updateActivePulses()
    local gameTime = getGameTime()
    if not gameTime then return end

    local nowWorldAgeHours =
        gameTime:getWorldAgeHours()
    local nowMs = getTimestampMs()
    local changed = false

    for index = #activePulses, 1, -1 do
        local pulse = activePulses[index]

        if not pulse then
            table.remove(activePulses, index)

        elseif nowWorldAgeHours >= pulse.expiresAt then
            for i = 1, #pulse.affected do
                if restoreTarget(pulse.affected[i]) then
                    changed = true
                end
            end
            removePulseFromLockSet(pulse)
            table.remove(activePulses, index)
            print("[MT Smart Watch] EMP BLACKOUT EXPIRED")

        elseif nowMs >= (pulse.nextEnforceAtMs or 0) then
            for i = 1, #pulse.affected do
                if enforceTargetOff(pulse.affected[i]) then
                    changed = true
                end
            end
            pulse.nextEnforceAtMs =
                nowMs + HARD_LOCK_INTERVAL_MS
        end
    end

    if changed
        and IsoGenerator
        and IsoGenerator.updateSurroundingNow then
        IsoGenerator.updateSurroundingNow()
    end
end


--------------------------------------------------
-- RESULT EXPIRY
--------------------------------------------------

local function updateResultExpiry()
    local r = EMP._lastServerResult
    if not r then return end

    local nowMs = getTimestampMs()

    if r.expiresAtMs and nowMs >= r.expiresAtMs then
        EMP._lastServerResult = nil
        return
    end

    if r.expectedEndWorldAgeHours then
        local gt = getGameTime()
        if gt
            and gt:getWorldAgeHours()
                >= r.expectedEndWorldAgeHours then
            EMP._lastServerResult = nil
        end
    end
end


--------------------------------------------------
-- TICK DISPATCHER
--------------------------------------------------

local function onTick()
    if not worldReady then return end

    if not EMP._startupSweepDone then
        local now = getTimestampMs()
        local lastTry = EMP._startupSweepLastTryMs or 0
        if (now - lastTry) >= STARTUP_SWEEP_RETRY_MS then
            EMP._startupSweepLastTryMs = now
            tryStartupSweep()
        end
    end

    updateActivePulses()
    updateResultExpiry()
    performPeriodicSweep()
end


--------------------------------------------------
-- VEHICLE INPUT
--------------------------------------------------

local function enforceLockedVehicleInput(player)
    if not player then return end

    local vehicle = player:getVehicle()
    if not vehicle then return end

    local okDriver, isDriver =
        safeCall(vehicle, "isDriver", player)
    if not okDriver then return end
    if isDriver ~= true then return end

    if not EMP.isObjectLocked(vehicle) then return end

    local wDown = false
    if Keyboard and Keyboard.KEY_W then
        local okKey, keyDown = pcall(function()
            return isKeyDown(Keyboard.KEY_W)
        end)
        if okKey then wDown = keyDown == true end
    end

    local now = getTimestampMs()
    local lastAction =
        vehicleActionCooldown[vehicle] or 0
    local canAct =
        (now - lastAction) >= VEHICLE_ACTION_THROTTLE_MS

    if wDown then
        sayEMPBlocked(player)
        if canAct then
            vehicleActionCooldown[vehicle] = now
            safeCall(vehicle, "engineDoStartingFailed")
            safeCall(vehicle, "shutOff")
        end
    end

    local okStarted, started =
        safeCall(vehicle, "isEngineStarted")
    local okRunning, running =
        safeCall(vehicle, "isEngineRunning")

    if canAct
        and ((okStarted and started == true)
            or (okRunning and running == true)) then
        vehicleActionCooldown[vehicle] = now
        safeCall(vehicle, "engineDoStartingFailed")
        safeCall(vehicle, "shutOff")
    end

    local okHeadlights, headlightsOn =
        safeCall(vehicle, "getHeadlightsOn")
    if okHeadlights and headlightsOn == true then
        safeCall(vehicle, "setHeadlightsOn", false)
    end

    local okWindowLights, windowLightsOn =
        safeCall(vehicle, "getWindowLightsOn")
    if okWindowLights and windowLightsOn == true then
        safeCall(vehicle, "setWindowLightsOn", false)
    end
end


--------------------------------------------------
-- PUBLIC ACTIVATE
--------------------------------------------------

function EMP.activate(player, watch)
    player = player or getPlayer()
    if not player then return false, "no_player" end

    if not watch
        and MT_SmartWatch.Watch
        and MT_SmartWatch.Watch.getEquippedWatch then
        watch = MT_SmartWatch.Watch
            .getEquippedWatch(player)
    end

    if isClient() and not isServer() then
        sendClientCommand(
            "MTSW_Tactical", "ActivateEMP", {}
        )
        print(
            "[MT Smart Watch] EMP request sent to server"
        )

        -- Pending-результат до прихода EMPResult от сервера.
        -- UI может проверять поле .pending.
        local nowMs = getTimestampMs()
        EMP._lastServerResult = {
            ok = false,
            reason = "sent",
            pending = true,
            remainingMinutes = 0,
            durationMinutes = 0,
            receivedAtMs = nowMs,
            expiresAtMs = nowMs + PENDING_TTL_MS,
            expectedEndWorldAgeHours = nil,
        }

        return true, "sent"
    end

    local _, ok, reason = runActivation(player, watch)
    return ok, reason
end


--------------------------------------------------
-- SERVER COMMAND
--------------------------------------------------

if isServer() then
    local function onClientCommand(module, command, player)
        if module ~= "MTSW_Tactical" then return end
        if command ~= "ActivateEMP" then return end

        local watch = nil
        if player
            and MT_SmartWatch.Watch
            and MT_SmartWatch.Watch.getEquippedWatch then
            watch = MT_SmartWatch.Watch
                .getEquippedWatch(player)
        end

        local result, ok, reason =
            runActivation(player, watch)

        sendServerCommand(player, "MTSW_Tactical",
            "EMPResult", {
                ok = ok == true,
                reason = tostring(reason or "unknown"),
                remainingMinutes =
                    tonumber(result.remainingMinutes) or 0,
                durationMinutes =
                    tonumber(result.durationMinutes) or 0,
            })
    end

    Events.OnClientCommand.Add(onClientCommand)
end


--------------------------------------------------
-- CLIENT: EMPResult
--------------------------------------------------

if isClient() then
    local function onServerCommand(module, command, args)
        if module ~= "MTSW_Tactical" then return end
        if command ~= "EMPResult" then return end

        -- Перезаписывает pending-результат.
        EMP._lastServerResult = buildEMPResult(
            args and args.ok == true,
            args and args.reason or "unknown",
            args and args.remainingMinutes or 0,
            args and args.durationMinutes or 0
        )

        print(
            "[MT Smart Watch] EMP RESULT: "
            .. tostring(EMP._lastServerResult.ok)
            .. " / " .. EMP._lastServerResult.reason
        )
    end

    Events.OnServerCommand.Add(onServerCommand)
end


--------------------------------------------------
-- PATCHABLE CLASSES
--------------------------------------------------

local PATCHABLE_CLASSES = {
    {
        name = "ISToggleStoveAction",
        fields = { "stove", "object" },
        req = { "isValid", "perform" },
    },
    {
        name = "ISToggleClothingWasher",
        fields = { "washer", "object" },
        req = { "isValid", "perform" },
    },
    {
        name = "ISToggleClothingDryer",
        fields = { "dryer", "object" },
        req = { "isValid", "perform" },
    },
    {
        name = "ISToggleComboWasherDryer",
        fields = {
            "comboWasherDryer",
            "combinationWasherDryer",
            "object",
        },
        req = { "isValid", "perform" },
    },
    {
        name = "ISActivateCarBatteryChargerAction",
        fields = { "carBatteryCharger", "object" },
        req = { "isValid", "perform" },
    },
    {
        name = "ISToggleLightSourceAction",
        fields = { "lightSource", "light", "object" },
        req = { "isValid", "perform" },
    },
    {
        name = "ISToggleLightAction",
        fields = { "object" },
        req = { "isValid" },
    },
    {
        name = "ISStartVehicleEngine",
        fields = { "vehicle", "car", "object" },
        req = { "isValid", "perform" },
    },
    {
        name = "ISConfigHeadlight",
        fields = { "vehicle", "car", "object" },
        req = { "isValid", "perform" },
    },
}


local PATCHABLE_BY_NAME = {}
for i = 1, #PATCHABLE_CLASSES do
    local e = PATCHABLE_CLASSES[i]
    PATCHABLE_BY_NAME[e.name] = e
end


--------------------------------------------------
-- ACTION OBJECT
--------------------------------------------------

local function isEMPWorldObject(value)
    if not value then return false end
    if safeInstanceOf(value, "IsoObject") then return true end
    return safeInstanceOf(value, "BaseVehicle")
end


local function getActionObject(action, className)
    if not action then return nil end

    -- Radio: device / deviceData:getParent() / object fallback.
    if className == "ISRadioAction" then
        if action.device
            and isEMPWorldObject(action.device) then
            return action.device
        end
        if action.deviceData then
            local okParent, parent = pcall(function()
                return action.deviceData:getParent()
            end)
            if okParent and parent
                and isEMPWorldObject(parent) then
                return parent
            end
        end
        if action.object
            and isEMPWorldObject(action.object) then
            return action.object
        end
        return nil
    end

    local entry = PATCHABLE_BY_NAME[className]
    if entry then
        for i = 1, #entry.fields do
            local v = action[entry.fields[i]]
            if v and isEMPWorldObject(v) then
                return v
            end
        end
    end

    -- Vehicle: fallback через character:getVehicle()
    if className == "ISStartVehicleEngine"
        or className == "ISConfigHeadlight" then
        if action.character then
            local okVehicle, vehicle = pcall(function()
                return action.character:getVehicle()
            end)
            if okVehicle and vehicle
                and isEMPWorldObject(vehicle) then
                return vehicle
            end
        end
    end

    return nil
end


local function shouldBlockAction(action, className)
    if className == "ISRadioAction" then
        return action.mode == "ToggleOnOff"
    end
    if PATCHABLE_BY_NAME[className] then
        return true
    end
    return false
end


local function isActionEMPBlocked(action, className)
    if not shouldBlockAction(action, className) then
        return false, nil
    end
    local object = getActionObject(action, className)
    if object and EMP.isObjectLocked(object) then
        return true, object
    end
    return false, object
end


local function logBlockedAction(action, className, object)
    if action and action._MTSW_EMP_BlockLogged then
        return
    end
    if action then
        action._MTSW_EMP_BlockLogged = true
    end
    print(
        "[MT Smart Watch] EMP BLOCKED ACTION: "
        .. tostring(className)
        .. " | Object: "
        .. tostring(getObjectDebugName(object))
    )
    if action and action.character then
        sayEMPBlocked(action.character)
    end
end


local function logBlockedClick(object, message)
    local now = getTimestampMs()
    local last = clickLogCooldown[object] or 0
    if (now - last) >= CLICK_LOG_COOLDOWN_MS then
        clickLogCooldown[object] = now
        print(
            "[MT Smart Watch] EMP BLOCKED OBJECT CLICK: "
            .. tostring(message)
        )
    end
end


--------------------------------------------------
-- GENERIC PATCH HELPERS
--------------------------------------------------

local function wrapperField(methodName)
    return "_MTSW_EMP_" .. methodName .. "_Wrapper"
end


local function patchMethod(
    class, methodName, wrapperF, makeWrapper
)
    if not class then return false end
    local original = class[methodName]
    if type(original) ~= "function" then return false end
    if class[wrapperF] == original then return false end

    local wrapper = makeWrapper(original)
    class[methodName] = wrapper
    class[wrapperF] = wrapper
    return true
end


local function isMethodPatched(class, methodName, wrapperF)
    if not class then return false end
    local m = class[methodName]
    return type(m) == "function"
        and class[wrapperF] == m
end


local function makeGuardWrapper(
    original, className, returnOnBlock
)
    return function(action, ...)
        local blocked, object =
            isActionEMPBlocked(action, className)
        if blocked then
            logBlockedAction(action, className, object)
            return returnOnBlock
        end
        return original(action, ...)
    end
end


--------------------------------------------------
-- PATCH ACTION CLASS
--------------------------------------------------

local function patchActionClass(entry)
    local className = entry.name
    local class = _G[className]
    if not class then return false end

    local patchedNow = false

    for i = 1, #entry.req do
        local m = entry.req[i]
        local returnOnBlock =
            (m == "isValid") and false or nil

        patchedNow = patchMethod(
            class, m, wrapperField(m),
            function(original)
                return makeGuardWrapper(
                    original, className, returnOnBlock
                )
            end
        ) or patchedNow
    end

    return patchedNow
end


local function isClassFullyPatched(entry)
    local class = _G[entry.name]
    if not class then return false end

    for i = 1, #entry.req do
        local m = entry.req[i]
        if not isMethodPatched(class, m, wrapperField(m)) then
            return false
        end
    end
    return true
end


--------------------------------------------------
-- RADIO PATCH
--------------------------------------------------

local RADIO_REQUIREMENTS = {
    "isValidToggleOnOff",
    "performToggleOnOff",
}


local function makeRadioWrapper(original, methodName)
    local returnOnBlock =
        (methodName == "isValidToggleOnOff")
        and false or nil

    return function(action, ...)
        local blocked, object = isActionEMPBlocked(
            action, "ISRadioAction"
        )
        if blocked then
            logBlockedAction(action,
                "ISRadioAction.ToggleOnOff", object)
            return returnOnBlock
        end
        return original(action, ...)
    end
end


local function patchRadioAction()
    if not ISRadioAction then return false end
    local patchedNow = false

    for i = 1, #RADIO_REQUIREMENTS do
        local m = RADIO_REQUIREMENTS[i]
        patchedNow = patchMethod(
            ISRadioAction, m, wrapperField(m),
            function(original)
                return makeRadioWrapper(original, m)
            end
        ) or patchedNow
    end

    return patchedNow
end


local function isRadioFullyPatched()
    if not ISRadioAction then return false end
    for i = 1, #RADIO_REQUIREMENTS do
        local m = RADIO_REQUIREMENTS[i]
        if not isMethodPatched(
            ISRadioAction, m, wrapperField(m)
        ) then
            return false
        end
    end
    return true
end


--------------------------------------------------
-- DIRECT CLICK
--------------------------------------------------

local DIRECT_CLICK_REQUIREMENTS = {
    "doClick",
    "doClickSpecificObject",
}


local function installDirectClickLock()
    if not ISObjectClickHandler then return false end
    local anyPatched = false

    anyPatched = patchMethod(
        ISObjectClickHandler,
        "doClickSpecificObject",
        wrapperField("doClickSpecificObject"),
        function(original)
            return function(object, playerNum, playerObj)
                if object
                    and safeInstanceOf(object, "IsoLightSwitch")
                    and EMP.isObjectLocked(object) then
                    logBlockedClick(object, "LightSwitch")
                    sayEMPBlocked(playerObj)
                    return true
                end
                return original(object, playerNum, playerObj)
            end
        end
    ) or anyPatched

    anyPatched = patchMethod(
        ISObjectClickHandler,
        "doClick",
        wrapperField("doClick"),
        function(original)
            return function(object, x, y)
                if object
                    and safeInstanceOf(object, "IsoLightSwitch")
                    and EMP.isObjectLocked(object) then
                    logBlockedClick(object, "LightSwitch")
                    return
                end
                return original(object, x, y)
            end
        end
    ) or anyPatched

    return anyPatched
end


local function isDirectClickFullyPatched()
    if not ISObjectClickHandler then return false end
    for i = 1, #DIRECT_CLICK_REQUIREMENTS do
        local m = DIRECT_CLICK_REQUIREMENTS[i]
        if not isMethodPatched(
            ISObjectClickHandler, m, wrapperField(m)
        ) then
            return false
        end
    end
    return true
end


--------------------------------------------------
-- LIGHT ACTION (ISWorldObjectContextMenu)
--------------------------------------------------

local function installLightActionLock()
    if not ISWorldObjectContextMenu then
        return false
    end

    return patchMethod(
        ISWorldObjectContextMenu,
        "onToggleLight",
        wrapperField("onToggleLight"),
        function(original)
            return function(worldobjects, light, player)
                if light and EMP.isObjectLocked(light) then
                    logBlockedClick(light, "LightSwitch")
                    sayEMPBlocked(player)
                    safeCall(light,
                        "setCanBeModified", false)
                    safeCall(light, "setActive",
                        false, false, true)
                    safeCall(light, "setActivated", false)
                    return
                end
                return original(
                    worldobjects, light, player
                )
            end
        end
    )
end


local function isLightActionFullyPatched()
    if ISWorldObjectContextMenu
        and type(ISWorldObjectContextMenu.onToggleLight)
            == "function"
        and not isMethodPatched(
            ISWorldObjectContextMenu,
            "onToggleLight",
            wrapperField("onToggleLight")
        ) then
        return false
    end
    return true
end


--------------------------------------------------
-- TIMED ACTION QUEUE
--------------------------------------------------

local QUEUE_REQUIREMENTS = {
    "add",
    "addAfter",
    "addToQueue",
}


local function makeQueueReturnOnBlock(original)
    return function(action, ...)
        local className =
            action and action.Type or "UnknownAction"
        local blocked, object =
            isActionEMPBlocked(action, className)
        if blocked then
            logBlockedAction(action, className, object)

            if action and action.character
                and ISTimedActionQueue
                    .getTimedActionQueue then
                local okQ, q = pcall(function()
                    return ISTimedActionQueue
                        :getTimedActionQueue(
                            action.character
                        )
                end)
                if okQ and q then return q end
            end

            return action
        end
        return original(action, ...)
    end
end


local function installTimedActionQueueLocks()
    if isDedicatedServer() then return true end
    if not ISTimedActionQueue then return false end

    local anyPatched = false

    anyPatched = patchMethod(
        ISTimedActionQueue, "addToQueue",
        wrapperField("addToQueue"),
        function(original)
            return function(queue, action)
                local className =
                    action and action.Type or "UnknownAction"
                local blocked, object =
                    isActionEMPBlocked(action, className)
                if blocked then
                    logBlockedAction(
                        action, className, object
                    )
                    return queue
                end
                return original(queue, action)
            end
        end
    ) or anyPatched

    anyPatched = patchMethod(
        ISTimedActionQueue, "add",
        wrapperField("add"),
        function(original)
            return makeQueueReturnOnBlock(original)
        end
    ) or anyPatched

    anyPatched = patchMethod(
        ISTimedActionQueue, "addAfter",
        wrapperField("addAfter"),
        function(original)
            return makeQueueReturnOnBlock(original)
        end
    ) or anyPatched

    return anyPatched
end


local function isQueueFullyPatched()
    if not ISTimedActionQueue then return false end
    for i = 1, #QUEUE_REQUIREMENTS do
        local m = QUEUE_REQUIREMENTS[i]
        if not isMethodPatched(
            ISTimedActionQueue, m, wrapperField(m)
        ) then
            return false
        end
    end
    return true
end


--------------------------------------------------
-- CHECK / INSTALL
--------------------------------------------------

local function checkAllPatches()
    local classesPatched = 0
    local classesTotal = #PATCHABLE_CLASSES
    local hooksMissing = 0

    for i = 1, #PATCHABLE_CLASSES do
        if isClassFullyPatched(PATCHABLE_CLASSES[i]) then
            classesPatched = classesPatched + 1
        else
            hooksMissing = hooksMissing + 1
        end
    end

    if not isRadioFullyPatched() then
        hooksMissing = hooksMissing + 1
    end
    if not isDirectClickFullyPatched() then
        hooksMissing = hooksMissing + 1
    end
    if not isLightActionFullyPatched() then
        hooksMissing = hooksMissing + 1
    end
    if not isQueueFullyPatched() then
        hooksMissing = hooksMissing + 1
    end

    return classesPatched, classesTotal, hooksMissing
end


local function installClientInteractionLock()
    if isDedicatedServer() then
        return true, #PATCHABLE_CLASSES,
            #PATCHABLE_CLASSES, 0
    end

    installDirectClickLock()
    installLightActionLock()
    installTimedActionQueueLocks()

    for i = 1, #PATCHABLE_CLASSES do
        patchActionClass(PATCHABLE_CLASSES[i])
    end

    patchRadioAction()

    local classesPatched, classesTotal, hooksMissing =
        checkAllPatches()

    local complete =
        hooksMissing == 0
        and classesPatched == classesTotal

    return complete, classesPatched, classesTotal,
        hooksMissing
end


--------------------------------------------------
-- WORLD READY
--------------------------------------------------

local function onWorldReady()
    if worldReady then return end
    worldReady = true

    activePulses = {}
    activeLockSet = {}

    EMP._clientInteractionLockComplete = false
    EMP._clientInteractionLockWarned = false
    EMP._clientInteractionLockStartMs = getTimestampMs()
    EMP._clientInteractionLockLastTryMs = 0

    EMP._sweepEmptyLogged = 0
    EMP._unknownKindLogged = {}
    EMP._startupSweepWaitingLogged = false

    lastSweepMs = 0
    lastCleanupMs = 0

    EMP._startupSweepDone = false
    EMP._startupSweepLastTryMs = 0
end


--------------------------------------------------
-- EVENTS
--------------------------------------------------

Events.OnGameStart.Add(onWorldReady)

Events.OnGameTimeLoaded.Add(function()
    if not worldReady then onWorldReady() end
end)

Events.OnTick.Add(onTick)


if not isDedicatedServer() then
    Events.OnTick.Add(function()
        if not worldReady then return end
        if EMP._clientInteractionLockComplete then return end

        local now = getTimestampMs()
        local lastTry = EMP._clientInteractionLockLastTryMs or 0
        if (now - lastTry) < PATCH_RETRY_INTERVAL_MS then
            return
        end
        EMP._clientInteractionLockLastTryMs = now

        local complete, patched, total, missing =
            installClientInteractionLock()

        if complete then
            EMP._clientInteractionLockComplete = true
            print(
                "[MT Smart Watch] EMP patch status: "
                .. tostring(patched) .. "/" .. tostring(total)
                .. " classes patched, all hooks installed"
            )
        else
            local startMs =
                EMP._clientInteractionLockStartMs or now
            if (now - startMs) >= PATCH_WARN_TIMEOUT_MS
                and not EMP._clientInteractionLockWarned then
                EMP._clientInteractionLockWarned = true
                print(
                    "[MT Smart Watch] EMP patch WARNING: "
                    .. tostring(patched) .. "/"
                    .. tostring(total) .. " classes, "
                    .. tostring(missing)
                    .. " hooks missing (will keep retrying)"
                )
            end
        end
    end)
end


if not isDedicatedServer() then
    Events.OnPlayerUpdate.Add(function(player)
        if player and worldReady then
            enforceLockedVehicleInput(player)
        end
    end)
end


print(
    "[MT Smart Watch] Tactical EMP loaded "
    .. "(B42 / SP+MP, refcount, revision N+2)"
)