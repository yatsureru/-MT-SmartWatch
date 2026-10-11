-- HUD_State.lua
MT_SmartWatch = MT_SmartWatch or {}
MT_SmartWatch.HUD = MT_SmartWatch.HUD or {}

if MT_SmartWatch.HUD.State then return end

-- ===== Settings =====
MT_SmartWatch.HUD.Settings = MT_SmartWatch.HUD.Settings or {
    iconSize        = 128,
    fadeTime        = 0.5,
    circleSpeed     = 3,   -- 1 = Never, 2 = Slow, 3 = Medium, 4 = Fast
    circleDirection = 2,   -- 1 = Left, 2 = Right
}

-- ===== Runtime state =====
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
        icon = { x = nil, y = nil, pinned = false },
    },
}
MT_SmartWatch.HUD.State = State

-- ===== .ini =====
local CONFIG_FILE    = "MT_SmartWatch_HUD.ini"
local CONFIG_VERSION = 3

local function validSpeed(v)
    return v == 1 or v == 2 or v == 3 or v == 4
end

local function validDirection(v)
    return v == 1 or v == 2
end

function State.load()
    local S = MT_SmartWatch.HUD.Settings

    State.position.icon.x      = nil
    State.position.icon.y      = nil
    State.position.icon.pinned = false

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
            elseif k == "icon.x" then
                State.position.icon.x = tonumber(v)
            elseif k == "icon.y" then
                State.position.icon.y = tonumber(v)
            elseif k == "icon.pinned" then
                State.position.icon.pinned = (v == "true")
            elseif k == "iconSize" then
                local n = tonumber(v); if n then S.iconSize = n end
            elseif k == "fadeTime" then
                local n = tonumber(v); if n then S.fadeTime = n end
            elseif k == "circleSpeed" then
                local n = tonumber(v)
                if n and validSpeed(n) then S.circleSpeed = n end
            elseif k == "circleDirection" then
                local n = tonumber(v)
                if n and validDirection(n) then S.circleDirection = n end
            end
        end
        line = reader:readLine()
    end
    reader:close()

    if version ~= CONFIG_VERSION then
        print("[MT Smart Watch - HUD] config version mismatch ("
            .. tostring(version) .. " → " .. tostring(CONFIG_VERSION)
            .. "), resetting HUD layout settings")
        -- сбрасываем только layout-настройки, iconSize/fadeTime сохраняем
        State.position.icon.x      = nil
        State.position.icon.y      = nil
        State.position.icon.pinned = false
        S.circleSpeed     = 3
        S.circleDirection = 2
    end

    print("[MT Smart Watch - HUD] loaded: iconSize=" .. tostring(S.iconSize)
        .. " fadeTime=" .. tostring(S.fadeTime)
        .. " circleSpeed=" .. tostring(S.circleSpeed)
        .. " circleDirection=" .. tostring(S.circleDirection)
        .. " pos=" .. tostring(State.position.icon.x) .. "," .. tostring(State.position.icon.y)
        .. " pinned=" .. tostring(State.position.icon.pinned))
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
    writer:write("icon.x=" .. tostring(State.position.icon.x or "") .. "\n")
    writer:write("icon.y=" .. tostring(State.position.icon.y or "") .. "\n")
    writer:write("icon.pinned=" .. tostring(State.position.icon.pinned == true) .. "\n")
    writer:close()
end

-- ===== Рантайм-обновление =====
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
    State.hasOScore = (OSCore and OSCore.hasInstalledCore and OSCore.hasInstalledCore(watch)) or false
    State.coreData  = State.hasOScore and OSCore.getInstalledData(watch) or nil

    local ChipSystem = MT_SmartWatch.ChipSystem
    State.chips       = (ChipSystem and ChipSystem.getInstalledChips(watch)) or {}
    State.activeChips = (ChipSystem and ChipSystem.getActiveChips(watch))   or {}

    if State.hasOScore then
        local Battery = MT_SmartWatch.Battery
        State.batteryPercent = (Battery and Battery.getPercent and Battery.getPercent(watch)) or nil
    else
        State.batteryPercent = nil
    end
end

print("[MT Smart Watch - HUD] State loaded")