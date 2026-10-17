-- HUD_SettingsPanel_WatchOnScreen.lua
MT_SmartWatch = MT_SmartWatch or {}
MT_SmartWatch.HUD = MT_SmartWatch.HUD or {}

if MT_SmartWatch.HUD.SettingsPanel_WatchOnScreen then return end

require "MT_SmartWatchFramework/HUD/HUD_State"

local SIZE_VALUES = { 256, 128, 64 }
local SIZE_LABELS = { "256", "128", "64" }

local FADE_VALUES = { 0, 0.5, 1, 2, 3, 4, 5, 6 }
local FADE_LABEL_KEYS = {
    "UI_MTSW_HUD_Fade_Never",
    "UI_MTSW_HUD_Fade_05",
    "UI_MTSW_HUD_Fade_1",
    "UI_MTSW_HUD_Fade_2",
    "UI_MTSW_HUD_Fade_3",
    "UI_MTSW_HUD_Fade_4",
    "UI_MTSW_HUD_Fade_5",
    "UI_MTSW_HUD_Fade_6",
}
local FADE_LABEL_FALLBACKS = {
    "Never", "0.5 sec", "1 sec", "2 sec",
    "3 sec", "4 sec", "5 sec", "6 sec",
}

local SPEED_VALUES = { 1, 2, 3, 4 }
local SPEED_LABEL_KEYS = {
    "UI_MTSW_HUD_Speed_Never",
    "UI_MTSW_HUD_Speed_Slow",
    "UI_MTSW_HUD_Speed_Medium",
    "UI_MTSW_HUD_Speed_Fast",
}
local SPEED_LABEL_FALLBACKS = { "Never", "Slow", "Medium", "Fast" }

local DIRECTION_VALUES = { 1, 2 }
local DIRECTION_LABEL_KEYS = {
    "UI_MTSW_HUD_Direction_Left",
    "UI_MTSW_HUD_Direction_Right",
}
local DIRECTION_LABEL_FALLBACKS = { "Left", "Right" }

local function idxOf(tbl, v, fallback)
    for i, s in ipairs(tbl) do if s == v then return i end end
    return fallback
end

local function L(key, fallback)
    if type(getTextOrNull) == "function" then
        local v = getTextOrNull(key)
        if v and v ~= "" then return v end
    end
    return fallback or key
end

local function buildPanelClass()
    if MT_SmartWatch.HUD.SettingsPanel_WatchOnScreen then return end
    if not ISPanel then
        print("[MT Smart Watch - HUD] FATAL: ISPanel not available")
        return
    end

    local Panel = ISPanel:derive("MT_SmartWatch_HUD_SettingsPanel_WatchOnScreen")
    MT_SmartWatch.HUD.SettingsPanel_WatchOnScreen = Panel

    local HEADER_H = 26
    local PAD      = 12
    local PANEL_W  = 260

    function Panel:new(x, y, ownerIcon)
        local o = ISPanel:new(x, y, PANEL_W, 230)
        setmetatable(o, self)
        self.__index = self

        o.ownerIcon = ownerIcon
        o.moving    = false
        o.dragging  = false

        o.backgroundColor = { r = 0.05, g = 0.05, b = 0.05, a = 0.9 }
        o.borderColor     = { r = 0.6,  g = 0.6,  b = 0.6,  a = 1   }

        return o
    end

    function Panel:createChildren()
        ISPanel.createChildren(self)

        local y = HEADER_H + PAD
        local S = MT_SmartWatch.HUD.Settings

        -- Pin
        self.pinBox = ISTickBox:new(PAD, y, self.width - PAD * 2, 24, "")
        self.pinBox.choicesColor = { r = 1, g = 1, b = 1, a = 1 }
        self.pinBox:initialise()
        self.pinBox:addOption(L("UI_MTSW_HUD_PinIcon", "Pin icon"))
        self.pinBox:setSelected(1, self.ownerIcon and self.ownerIcon:isPinned() or false)
        self:addChild(self.pinBox)
        y = y + 32

        -- Icon size
        self:addChild(self:makeLabel(PAD, y, L("UI_MTSW_HUD_IconSize", "Icon size")))
        y = y + 22

        self.sizeCombo = ISComboBox:new(PAD, y, self.width - PAD * 2, 24, self, nil)
        self.sizeCombo:initialise()
        for _, label in ipairs(SIZE_LABELS) do
            self.sizeCombo:addOption(label)
        end
        self.sizeCombo.selected = idxOf(SIZE_VALUES, S.iconSize, 2)
        self:addChild(self.sizeCombo)
        y = y + 32

        -- Fade time
        self:addChild(self:makeLabel(PAD, y, L("UI_MTSW_HUD_FadeTime", "Fade time")))
        y = y + 22

        self.fadeCombo = ISComboBox:new(PAD, y, self.width - PAD * 2, 24, self, nil)
        self.fadeCombo:initialise()
        for i, key in ipairs(FADE_LABEL_KEYS) do
            self.fadeCombo:addOption(L(key, FADE_LABEL_FALLBACKS[i]))
        end
        self.fadeCombo.selected = idxOf(FADE_VALUES, S.fadeTime, 1)
        self:addChild(self.fadeCombo)
        y = y + 32

        -- Circle speed
        self:addChild(self:makeLabel(PAD, y, L("UI_MTSW_HUD_CircleSpeed", "Circle speed")))
        y = y + 22

        self.speedCombo = ISComboBox:new(PAD, y, self.width - PAD * 2, 24, self, nil)
        self.speedCombo:initialise()
        for i, key in ipairs(SPEED_LABEL_KEYS) do
            self.speedCombo:addOption(L(key, SPEED_LABEL_FALLBACKS[i]))
        end
        self.speedCombo.selected = idxOf(SPEED_VALUES, S.circleSpeed, 3)
        self:addChild(self.speedCombo)
        y = y + 32

        -- Circle direction
        self:addChild(self:makeLabel(PAD, y, L("UI_MTSW_HUD_CircleDirection", "Circle direction")))
        y = y + 22

        self.dirCombo = ISComboBox:new(PAD, y, self.width - PAD * 2, 24, self, nil)
        self.dirCombo:initialise()
        for i, key in ipairs(DIRECTION_LABEL_KEYS) do
            self.dirCombo:addOption(L(key, DIRECTION_LABEL_FALLBACKS[i]))
        end
        self.dirCombo.selected = idxOf(DIRECTION_VALUES, S.circleDirection, 2)
        self:addChild(self.dirCombo)
        y = y + 40

        -- Save
        self.saveBtn = ISButton:new(PAD, y, self.width - PAD * 2, 26,
            L("UI_MTSW_HUD_Save", "Save"), self, Panel.onSave)
        self.saveBtn:initialise()
        self:addChild(self.saveBtn)

        self:setHeight(y + 26 + PAD)
    end

    function Panel:makeLabel(x, y, text)
        local lbl = ISLabel:new(x, y, 20, text, 1, 1, 1, 1, UIFont.Small, true)
        lbl:initialise()
        return lbl
    end

    function Panel:onSave()
        local sizeIdx   = self.sizeCombo.selected or 2
        local fadeIdx   = self.fadeCombo.selected or 1
        local speedIdx  = self.speedCombo.selected or 3
        local dirIdx    = self.dirCombo.selected or 2
        local pinned    = self.pinBox:isSelected(1) == true

        local S = MT_SmartWatch.HUD.Settings
        S.iconSize        = SIZE_VALUES[sizeIdx] or 128
        S.fadeTime        = FADE_VALUES[fadeIdx] or 0
        S.circleSpeed     = SPEED_VALUES[speedIdx] or 3
        S.circleDirection = DIRECTION_VALUES[dirIdx] or 2

        if self.ownerIcon then
            self.ownerIcon:setPinned(pinned)
            self.ownerIcon:setIconSize(S.iconSize)
        end

        local State = MT_SmartWatch.HUD.State
        if State then State.save() end

        print("[MT Smart Watch - HUD] watch settings saved: iconSize=" .. tostring(S.iconSize)
            .. " fadeTime=" .. tostring(S.fadeTime)
            .. " circleSpeed=" .. tostring(S.circleSpeed)
            .. " circleDirection=" .. tostring(S.circleDirection)
            .. " pinned=" .. tostring(pinned))

        self:close()
    end

    function Panel:close()
        if self.ownerIcon then
            self.ownerIcon.forceVisible = false
        end
        self:setVisible(false)
        self:removeFromUIManager()
        if MT_SmartWatch.HUD.settingsPanelWatchOnScreenInstance == self then
            MT_SmartWatch.HUD.settingsPanelWatchOnScreenInstance = nil
        end
    end

    function Panel:onMouseDown(x, y)
        if y <= HEADER_H then
            self.moving   = true
            self.dragging = false
            self:setCapture(true)
            return true
        end
        return ISPanel.onMouseDown(self, x, y)
    end

    function Panel:onMouseMove(dx, dy)
        if self.moving then
            self.dragging = true
            self:setX(self:getX() + dx)
            self:setY(self:getY() + dy)
            return true
        end
        return ISPanel.onMouseMove(self, dx, dy)
    end

    function Panel:onMouseMoveOutside(dx, dy)
        if self.moving then
            self.dragging = true
            self:setX(self:getX() + dx)
            self:setY(self:getY() + dy)
            return true
        end
        return ISPanel.onMouseMoveOutside(self, dx, dy)
    end

    function Panel:onMouseUp(x, y)
        if self.moving then
            self.moving = false
            self:setCapture(false)
            return true
        end
        return ISPanel.onMouseUp(self, x, y)
    end

    function Panel:onMouseUpOutside(x, y)
        if self.moving then
            self.moving = false
            self:setCapture(false)
            return true
        end
        return ISPanel.onMouseUpOutside(self, x, y)
    end

    function Panel:prerender()
        ISPanel.prerender(self)

        self:drawRect(0, 0, self.width, HEADER_H, 0.6, 0.15, 0.15, 0.15)
        self:drawRectBorder(0, 0, self.width, self.height,
            self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)

        local title = L("UI_MTSW_HUD_Title", "MT SmartWatch")
        local tw = getTextManager():MeasureStringX(UIFont.Medium, title)
        self:drawText(title, (self.width - tw) / 2, 4, 1, 1, 1, 1, UIFont.Medium)
    end

    print("[MT Smart Watch - HUD] SettingsPanel_WatchOnScreen class built")
end

-- ============================================================
-- Открытие панели (singleton + toggle)
-- ============================================================
function MT_SmartWatch.HUD.openSettingsPanel_WatchOnScreen(ownerIcon)
    local existing = MT_SmartWatch.HUD.settingsPanelWatchOnScreenInstance
    if existing then
        existing:close()
        return
    end

    local Panel = MT_SmartWatch.HUD.SettingsPanel_WatchOnScreen
    if not Panel then
        print("[MT Smart Watch - HUD] SettingsPanel_WatchOnScreen class not ready")
        return
    end

    local iconX, iconY = ownerIcon:getX(), ownerIcon:getY()
    local iconW, iconH = ownerIcon:getWidth(), ownerIcon:getHeight()
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()

    local panelW, panelH = 260, 380
    local px = iconX + iconW + 10
    if px + panelW > screenW - 10 then
        px = iconX - panelW - 10
    end
    if px < 10 then px = 10 end
    if px + panelW > screenW - 10 then px = screenW - panelW - 10 end

    local py = iconY
    if py + panelH > screenH - 10 then py = screenH - panelH - 10 end
    if py < 10 then py = 10 end

    local panel = Panel:new(px, py, ownerIcon)
    panel:initialise()
    panel:createChildren()
    panel:addToUIManager()
    panel:setAlwaysOnTop(true)
    panel:bringToTop()

    if ownerIcon then
        ownerIcon.forceVisible = true
        ownerIcon.alpha = 1
    end

    MT_SmartWatch.HUD.settingsPanelWatchOnScreenInstance = panel
    return panel
end

if ISPanel then
    buildPanelClass()
else
    Events.OnGameBoot.Add(buildPanelClass)
end