-- HUD_Init.lua
require "MT_SmartWatchFramework/HUD/HUD_State"
require "MT_SmartWatchFramework/HUD/HUD_Base"
require "MT_SmartWatchFramework/HUD/HUD_SettingsPanel_WatchOnScreen"
require "MT_SmartWatchFramework/HUD/HUD_SettingsPanel_Hotbar"
require "MT_SmartWatchFramework/HUD/HUD_Battery"
require "MT_SmartWatchFramework/HUD/HUD_Icon"
require "MT_SmartWatchFramework/HUD/HUD_TacticalSlots"
require "MT_SmartWatchFramework/HUD/HUD_Interface"
require "MT_SmartWatchFramework/HUD/HUD_Interface_TacticalChips"

MT_SmartWatch = MT_SmartWatch or {}
MT_SmartWatch.HUD = MT_SmartWatch.HUD or {}

local State = MT_SmartWatch.HUD.State

local function clampToScreen(x, y, w, h)
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()

    if x + w > screenW then x = screenW - w end
    if y + h > screenH then y = screenH - h end
    if x < 0 then x = 0 end
    if y < 0 then y = 0 end

    return x, y
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

    defX, defY = clampToScreen(defX, defY, size, size)

    local icon = Icon:new(defX, defY)
    icon:initialise()
    icon:addToUIManager()
    icon:backMost()
    MT_SmartWatch.HUD.icon = icon

    print("[MT Smart Watch - HUD] icon created at " .. defX .. "," .. defY)
    return icon
end

local function ensureTacticalSlots()
    if MT_SmartWatch.HUD.tacticalSlots then return MT_SmartWatch.HUD.tacticalSlots end

    local Slots = MT_SmartWatch.HUD.TacticalSlots
    if not Slots then return nil end

    local pos = State.position.tacticalSlots

    local icon = MT_SmartWatch.HUD.icon
    local defX, defY = 100, 100
    if icon then
        defX = icon:getX()
        defY = icon:getY() + icon:getHeight() + 10
    end

    local px = (pos.x ~= nil) and pos.x or defX
    local py = (pos.y ~= nil) and pos.y or defY

    px, py = clampToScreen(px, py, 300, 84)

    local slots = Slots:new(px, py)
    slots:initialise()
    slots:addToUIManager()
    slots:backMost()
    MT_SmartWatch.HUD.tacticalSlots = slots

    print("[MT Smart Watch - HUD] tactical slots created at " .. px .. "," .. py)
    return slots
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

    -- Иконка
    local icon = ensureIcon()
    if icon then
        local wantSize = MT_SmartWatch.HUD.Settings.iconSize or 128
        if icon:getWidth() ~= wantSize then
            icon:setIconSize(wantSize)
        end
        icon.visible   = State.hasWatch
        icon.hasOSCore = State.hasOSCore
    end

    -- Хотбар
    local slots = ensureTacticalSlots()
    if slots then
        local ChipSystem = MT_SmartWatch.ChipSystem
        local watch = State.watch

        local count = 0
        if State.hasOSCore and ChipSystem and ChipSystem.getTacticalSlots then
            count = ChipSystem.getTacticalSlots(watch) or 0
        end

        if count > 0 then
            slots:setSlotCount(count)
            slots.visible = true
            slots:refresh()
        else
            slots.visible = false
            slots.slotCount = 0
            slots.slotData = {}
        end
    end
end

local function onGameStart()
    State.load()

    local icon = MT_SmartWatch.HUD.icon
    if icon then
        local pos = State.position.icon
        local size = MT_SmartWatch.HUD.Settings.iconSize or 128
        local x = (pos.x ~= nil) and pos.x or icon:getX()
        local y = (pos.y ~= nil) and pos.y or icon:getY()
        x, y = clampToScreen(x, y, size, size)
        icon:setX(x)
        icon:setY(y)
        icon:setIconSize(size)
    end

    local slots = MT_SmartWatch.HUD.tacticalSlots
    if slots then
        local pos = State.position.tacticalSlots
        local x = (pos.x ~= nil) and pos.x or slots:getX()
        local y = (pos.y ~= nil) and pos.y or slots:getY()
        x, y = clampToScreen(x, y, 300, 84)
        slots:setX(x)
        slots:setY(y)
    end
end

local function onPlayerDeath()
    if MT_SmartWatch.HUD.icon then
        MT_SmartWatch.HUD.icon.visible = false
    end
    if MT_SmartWatch.HUD.tacticalSlots then
        MT_SmartWatch.HUD.tacticalSlots.visible = false
    end
    if MT_SmartWatch.HUD.settingsPanelWatchOnScreenInstance then
        MT_SmartWatch.HUD.settingsPanelWatchOnScreenInstance:close()
    end
    if MT_SmartWatch.HUD.hotbarSettingsPanelInstance then
        MT_SmartWatch.HUD.hotbarSettingsPanelInstance:close()
    end
    if MT_SmartWatch.HUD.interfacePanel then
        MT_SmartWatch.HUD.interfacePanel:close()
    end
    if MT_SmartWatch.HUD.interfaceTacticalChipsPanel then
        MT_SmartWatch.HUD.interfaceTacticalChipsPanel:close()
    end
end

Events.OnGameStart.Add(onGameStart)
Events.OnPlayerDeath.Add(onPlayerDeath)
Events.OnPlayerUpdate.Add(onPlayerUpdate)

print("[MT Smart Watch - HUD] Init complete")