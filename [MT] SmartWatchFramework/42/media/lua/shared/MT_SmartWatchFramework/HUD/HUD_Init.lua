-- HUD_Init.lua
-- Entry point HUD-подсистемы.

require "MT_SmartWatchFramework/HUD/HUD_State"
require "MT_SmartWatchFramework/HUD/HUD_Base"
require "MT_SmartWatchFramework/HUD/HUD_SettingsPanel"
require "MT_SmartWatchFramework/HUD/HUD_Icon"
-- require "MT_SmartWatchFramework/HUD/HUD_ModOptions"   ← отключено, настройки в ПКМ-панели

MT_SmartWatch = MT_SmartWatch or {}
MT_SmartWatch.HUD = MT_SmartWatch.HUD or {}

local State = MT_SmartWatch.HUD.State

-- Точка расширения: полный интерфейс часов
if not MT_SmartWatch.HUD.openInterface then
    MT_SmartWatch.HUD.openInterface = function()
        print("[MT Smart Watch - HUD] openInterface() — TODO: полный интерфейс часов")
    end
end

local function ensureIcon()
    if MT_SmartWatch.HUD.icon then return MT_SmartWatch.HUD.icon end

    local Icon = MT_SmartWatch.HUD.Icon
    if not Icon then return nil end

    local settings = MT_SmartWatch.HUD.Settings
    local size = settings.iconSize or 128
    local pos  = State.position.icon

    local defX = (pos.x ~= nil) and pos.x or (getCore():getScreenWidth() - size - 20)
    local defY = (pos.y ~= nil) and pos.y or 20

    local icon = Icon:new(defX, defY)
    icon:initialise()
    icon:addToUIManager()
    icon:backMost()
    MT_SmartWatch.HUD.icon = icon

    print("[MT Smart Watch - HUD] icon created at " .. defX .. "," .. defY)
    return icon
end

local UPDATE_INTERVAL = 8
local tick = 0
local lastTick = -9999

local function onPlayerUpdate(player)
    tick = tick + 1
    if (tick - lastTick) < UPDATE_INTERVAL then return end
    lastTick = tick

    if not player then return end

    State.update(player)

    local icon = ensureIcon()
    if not icon then return end

    local wantSize = MT_SmartWatch.HUD.Settings.iconSize or 128
    if icon:getWidth() ~= wantSize then
        icon:setIconSize(wantSize)
    end

    icon.visible       = State.hasWatch
    icon.useOScoreIcon = State.hasOScore
end

local function onGameStart()
    -- .ini — единственный источник правды
    State.load()

    local icon = MT_SmartWatch.HUD.icon
    if icon then
        local pos = State.position.icon
        if pos.x and pos.y then
            icon:setX(pos.x)
            icon:setY(pos.y)
        end
        icon:setIconSize(MT_SmartWatch.HUD.Settings.iconSize or 128)
    end
end

local function onPlayerDeath()
    if MT_SmartWatch.HUD.icon then
        MT_SmartWatch.HUD.icon.visible = false
    end
    if MT_SmartWatch.HUD.settingsPanelInstance then
        MT_SmartWatch.HUD.settingsPanelInstance:close()
    end
end

Events.OnGameStart.Add(onGameStart)
Events.OnPlayerDeath.Add(onPlayerDeath)
Events.OnPlayerUpdate.Add(onPlayerUpdate)

print("[MT Smart Watch - HUD] Init complete")