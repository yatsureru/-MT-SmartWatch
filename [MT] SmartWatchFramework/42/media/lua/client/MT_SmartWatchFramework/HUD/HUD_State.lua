-- HUD_State.lua
MT_SmartWatch = MT_SmartWatch or {}
MT_SmartWatch.HUD = MT_SmartWatch.HUD or {}

if MT_SmartWatch.HUD.State then return end

-- ============================================================
-- Settings
-- ============================================================
MT_SmartWatch.HUD.Settings = MT_SmartWatch.HUD.Settings or {
    iconSize           = 128,
    fadeTime           = 0,
    circleSpeed        = 3,
    circleDirection    = 2,
    tacticalLock       = false,
    tacticalScale      = 1.0,
    tacticalGap        = 2.5,
    tacticalFadeTime   = 0,
    tacticalLinePosition = "bottom",  -- "bottom" | "top"
}

-- ============================================================
-- Runtime state
-- ============================================================
local State = {
    watch          = nil,
    hasWatch       = false,
    hasOScore      = false,
    coreData       = nil,
    chips          = {},
    activeChips    = {},
    playerNum      = 0,
    batteryPercent = nil,

    position = {
        icon          = { x = nil, y = nil, pinned = false },
        tacticalSlots = { x = nil, y = nil, pinned = false },
    },
}
MT_SmartWatch.HUD.State = State

-- ============================================================
-- .ini
-- ============================================================
local CONFIG_FILE    = "MT_SmartWatch_HUD.ini"
local CONFIG_VERSION = 10

local VALID_SCALES = { [0.5]=true, [0.75]=true, [1.0]=true, [1.25]=true, [1.5]=true }
local VALID_GAPS   = { [0]=true, [2.5]=true, [5]=true, [7.5]=true, [10]=true }
local VALID_FADE   = { [0]=true, [0.5]=true, [1]=true, [2]=true, [3]=true, [4]=true, [5]=true, [6]=true }

local function validSpeed(v) return v == 1 or v == 2 or v == 3 or v == 4 end
local function validDirection(v) return v == 1 or v == 2 end
local function validScale(v) return VALID_SCALES[v] == true end
local function validGap(v) return VALID_GAPS[v] == true end
local function validFade(v) return VALID_FADE[v] == true end
local function validLinePos(v) return v == "bottom" or v == "top" end

function State.load()
    local S = MT_SmartWatch.HUD.Settings

    State.position.icon.x               = nil
    State.position.icon.y               = nil
    State.position.icon.pinned          = false
    State.position.tacticalSlots.x      = nil
    State.position.tacticalSlots.y      = nil
    State.position.tacticalSlots.pinned = false

    local reader = getFileReader(CONFIG_FILE, true)
    if not reader then
        print("[MT Smart Watch - HUD] no config yet, using defaults")
        return
    end

    local version = 0
    local line = reader:readLine()
    while line do
        local parts = string.split(line, "=")
        if #parts == 2 then
            local k, v = parts[1], parts[2]

            if k == "VERSION" then
                version = tonumber(v) or 0
            elseif k == "iconSize" then
                local n = tonumber(v); if n then S.iconSize = n end
            elseif k == "fadeTime" then
                local n = tonumber(v); if n and validFade(n) then S.fadeTime = n end
            elseif k == "circleSpeed" then
                local n = tonumber(v); if n and validSpeed(n) then S.circleSpeed = n end
            elseif k == "circleDirection" then
                local n = tonumber(v); if n and validDirection(n) then S.circleDirection = n end
            elseif k == "tacticalLock" then
                S.tacticalLock = (v == "true")
            elseif k == "tacticalScale" then
                local n = tonumber(v); if n and validScale(n) then S.tacticalScale = n end
            elseif k == "tacticalGap" then
                local n = tonumber(v); if n and validGap(n) then S.tacticalGap = n end
            elseif k == "tacticalFadeTime" then
                local n = tonumber(v); if n and validFade(n) then S.tacticalFadeTime = n end
            elseif k == "tacticalLinePosition" then
                if validLinePos(v) then S.tacticalLinePosition = v end
            elseif k == "icon.x" then
                State.position.icon.x = tonumber(v)
            elseif k == "icon.y" then
                State.position.icon.y = tonumber(v)
            elseif k == "icon.pinned" then
                State.position.icon.pinned = (v == "true")
            elseif k == "tacticalSlots.x" then
                State.position.tacticalSlots.x = tonumber(v)
            elseif k == "tacticalSlots.y" then
                State.position.tacticalSlots.y = tonumber(v)
            elseif k == "tacticalSlots.pinned" then
                State.position.tacticalSlots.pinned = (v == "true")
            end
        end
        line = reader:readLine()
    end
    reader:close()

    if version ~= CONFIG_VERSION then
        print("[MT Smart Watch - HUD] config version mismatch ("
            .. tostring(version) .. " -> " .. tostring(CONFIG_VERSION)
            .. "), resetting layout")

        State.position.icon.x               = nil
        State.position.icon.y               = nil
        State.position.icon.pinned          = false
        State.position.tacticalSlots.x      = nil
        State.position.tacticalSlots.y      = nil
        State.position.tacticalSlots.pinned = false

        S.fadeTime           = 0
        S.circleSpeed        = 3
        S.circleDirection    = 2
        S.tacticalLock       = false
        S.tacticalScale      = 1.0
        S.tacticalGap        = 2.5
        S.tacticalFadeTime   = 0
        S.tacticalLinePosition = "bottom"
    end

    print("[MT Smart Watch - HUD] loaded: iconSize=" .. tostring(S.iconSize)
        .. " fadeTime=" .. tostring(S.fadeTime)
        .. " tacticalScale=" .. tostring(S.tacticalScale)
        .. " tacticalGap=" .. tostring(S.tacticalGap)
        .. " tacticalFadeTime=" .. tostring(S.tacticalFadeTime)
        .. " tacticalLinePosition=" .. tostring(S.tacticalLinePosition))
end

function State.save()
    local S = MT_SmartWatch.HUD.Settings

    local writer = getFileWriter(CONFIG_FILE, true, false)
    if not writer then return end

    writer:write("VERSION=" .. CONFIG_VERSION .. "\n")
    writer:write("iconSize=" .. tostring(S.iconSize or "") .. "\n")
    writer:write("fadeTime=" .. tostring(S.fadeTime or "") .. "\n")
    writer:write("circleSpeed=" .. tostring(S.circleSpeed or "") .. "\n")
    writer:write("circleDirection=" .. tostring(S.circleDirection or "") .. "\n")
    writer:write("tacticalLock=" .. tostring(S.tacticalLock == true) .. "\n")
    writer:write("tacticalScale=" .. tostring(S.tacticalScale or "") .. "\n")
    writer:write("tacticalGap=" .. tostring(S.tacticalGap or "") .. "\n")
    writer:write("tacticalFadeTime=" .. tostring(S.tacticalFadeTime or "") .. "\n")
    writer:write("tacticalLinePosition=" .. tostring(S.tacticalLinePosition or "bottom") .. "\n")
    writer:write("icon.x=" .. tostring(State.position.icon.x or "") .. "\n")
    writer:write("icon.y=" .. tostring(State.position.icon.y or "") .. "\n")
    writer:write("icon.pinned=" .. tostring(State.position.icon.pinned == true) .. "\n")
    writer:write("tacticalSlots.x=" .. tostring(State.position.tacticalSlots.x or "") .. "\n")
    writer:write("tacticalSlots.y=" .. tostring(State.position.tacticalSlots.y or "") .. "\n")
    writer:write("tacticalSlots.pinned=" .. tostring(State.position.tacticalSlots.pinned == true) .. "\n")

    writer:close()
end

-- ============================================================
-- Рантайм-обновление
-- ============================================================
function State.update(player)
    if not player then
        State.watch, State.hasWatch, State.hasOScore = nil, false, false
        State.coreData, State.chips, State.activeChips = nil, {}, {}
        State.batteryPercent = nil
        return
    end

    State.playerNum = player:getPlayerNum()

    local Watch = MT_SmartWatch.Watch
    local watch = Watch and Watch.getEquippedWatch and Watch.getEquippedWatch(player)

    State.watch    = watch
    State.hasWatch = watch ~= nil

    if not watch then
        State.hasOScore, State.coreData = false, nil
        State.chips, State.activeChips = {}, {}
        State.batteryPercent = nil
        return
    end

    local OSCore = MT_SmartWatch.OSCore
    State.hasOSCore = (OSCore and OSCore.hasInstalledCore and OSCore.hasInstalledCore(watch)) or false
    State.coreData  = State.hasOSCore and OSCore.getInstalledData(watch) or nil

    local ChipSystem = MT_SmartWatch.ChipSystem
    State.chips       = (ChipSystem and ChipSystem.getInstalledChips(watch)) or {}
    State.activeChips = (ChipSystem and ChipSystem.getActiveChips(watch))   or {}

    if State.hasOSCore then
        local Battery = MT_SmartWatch.Battery
        State.batteryPercent = (Battery and Battery.getPercent and Battery.getPercent(watch)) or nil
    else
        State.batteryPercent = nil
    end
end

print("[MT Smart Watch - HUD] State loaded")