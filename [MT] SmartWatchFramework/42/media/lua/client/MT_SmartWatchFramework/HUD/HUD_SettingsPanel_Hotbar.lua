-- HUD_SettingsPanel_Hotbar.lua
MT_SmartWatch = MT_SmartWatch or {}
MT_SmartWatch.HUD = MT_SmartWatch.HUD or {}

if MT_SmartWatch.HUD.HotbarSettingsPanel then return end

require "MT_SmartWatchFramework/HUD/HUD_State"

local function L(key, fallback)
    if type(getTextOrNull) == "function" then
        local v = getTextOrNull(key)
        if v and v ~= "" then return v end
    end
    return fallback or key
end

local SCALE_VALUES = { 0.5, 0.75, 1.0, 1.25, 1.5 }
local SCALE_LABELS = { "0.5x", "0.75x", "1.0x", "1.25x", "1.5x" }

local GAP_VALUES = { 0, 2.5, 5, 7.5, 10 }
local GAP_LABELS = { "0", "2.5", "5", "7.5", "10" }

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

local LINE_POS_VALUES = { "bottom", "top" }
local LINE_POS_LABEL_KEYS = {
    "UI_MTSW_HUD_LinePosition_Bottom",
    "UI_MTSW_HUD_LinePosition_Top",
}
local LINE_POS_LABEL_FALLBACKS = { "Bottom", "Top" }

local function idxOf(tbl, v, fallback)
    for i, s in ipairs(tbl) do if s == v then return i end end
    return fallback
end

local function buildPanelClass()
    if MT_SmartWatch.HUD.HotbarSettingsPanel then return end
    if not ISPanel then
        Events.OnGameBoot.Add(buildPanelClass)
        return
    end

    local Panel = ISPanel:derive("MT_SmartWatch_HUD_HotbarSettingsPanel")
    MT_SmartWatch.HUD.HotbarSettingsPanel = Panel

    local HEADER_H = 26
    local PAD      = 12
    local PANEL_W  = 260

    function Panel:new(x, y, ownerPanel)
        local o = ISPanel:new(x, y, PANEL_W, 400)
        setmetatable(o, self)
        self.__index = self

        o.ownerPanel      = ownerPanel
        o.moving          = false
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
        self.pinBox:addOption(L("UI_MTSW_HUD_PinIcon", "Pin"))
        self.pinBox:setSelected(1, self.ownerPanel and self.ownerPanel:isPinned() or false)
        self:addChild(self.pinBox)
        y = y + 32

        -- Scale
        local lblScale = ISLabel:new(PAD, y, 20,
            L("UI_MTSW_HUD_TacticalScale", "Scale"),
            1, 1, 1, 1, UIFont.Small, true)
        lblScale:initialise()
        self:addChild(lblScale)
        y = y + 22

        self.scaleCombo = ISComboBox:new(PAD, y, self.width - PAD * 2, 24, self, nil)
        self.scaleCombo:initialise()
        for _, label in ipairs(SCALE_LABELS) do
            self.scaleCombo:addOption(label)
        end
        self.scaleCombo.selected = idxOf(SCALE_VALUES, S.tacticalScale, 3)
        self:addChild(self.scaleCombo)
        y = y + 32

        -- Gap
        local lblGap = ISLabel:new(PAD, y, 20,
            L("UI_MTSW_HUD_TacticalGap", "Gap"),
            1, 1, 1, 1, UIFont.Small, true)
        lblGap:initialise()
        self:addChild(lblGap)
        y = y + 22

        self.gapCombo = ISComboBox:new(PAD, y, self.width - PAD * 2, 24, self, nil)
        self.gapCombo:initialise()
        for _, label in ipairs(GAP_LABELS) do
            self.gapCombo:addOption(label)
        end
        self.gapCombo.selected = idxOf(GAP_VALUES, S.tacticalGap, 2)
        self:addChild(self.gapCombo)
        y = y + 32

        -- Fade time
        local lblFade = ISLabel:new(PAD, y, 20,
            L("UI_MTSW_HUD_FadeTime", "Fade time"),
            1, 1, 1, 1, UIFont.Small, true)
        lblFade:initialise()
        self:addChild(lblFade)
        y = y + 22

        self.fadeCombo = ISComboBox:new(PAD, y, self.width - PAD * 2, 24, self, nil)
        self.fadeCombo:initialise()
        for i, key in ipairs(FADE_LABEL_KEYS) do
            self.fadeCombo:addOption(L(key, FADE_LABEL_FALLBACKS[i]))
        end
        self.fadeCombo.selected = idxOf(FADE_VALUES, S.tacticalFadeTime, 1)
        self:addChild(self.fadeCombo)
        y = y + 32

        -- Line position
        local lblLinePos = ISLabel:new(PAD, y, 20,
            L("UI_MTSW_HUD_LinePosition", "Line position"),
            1, 1, 1, 1, UIFont.Small, true)
        lblLinePos:initialise()
        self:addChild(lblLinePos)
        y = y + 22

        self.linePosCombo = ISComboBox:new(PAD, y, self.width - PAD * 2, 24, self, nil)
        self.linePosCombo:initialise()
        for i, key in ipairs(LINE_POS_LABEL_KEYS) do
            self.linePosCombo:addOption(L(key, LINE_POS_LABEL_FALLBACKS[i]))
        end
        self.linePosCombo.selected = idxOf(LINE_POS_VALUES, S.tacticalLinePosition, 1)
        self:addChild(self.linePosCombo)
        y = y + 40

        -- Save
        self.saveBtn = ISButton:new(PAD, y, self.width - PAD * 2, 26,
            L("UI_MTSW_HUD_Save", "Save"), self, Panel.onSave)
        self.saveBtn:initialise()
        self:addChild(self.saveBtn)

        self:setHeight(y + 26 + PAD)
    end

    function Panel:onSave()
        local S = MT_SmartWatch.HUD.Settings
        S.tacticalScale        = SCALE_VALUES[self.scaleCombo.selected or 3] or 1.0
        S.tacticalGap          = GAP_VALUES[self.gapCombo.selected or 2] or 2.5
        S.tacticalFadeTime     = FADE_VALUES[self.fadeCombo.selected or 1] or 0
        S.tacticalLinePosition = LINE_POS_VALUES[self.linePosCombo.selected or 1] or "bottom"

        if self.ownerPanel then
            self.ownerPanel:setPinned(self.pinBox:isSelected(1) == true)
            self.ownerPanel:recalcSize()
            if self.ownerPanel.refresh then
                self.ownerPanel:refresh()
            end
        end

        local State = MT_SmartWatch.HUD.State
        if State then State.save() end

        print("[MT Smart Watch - HUD] hotbar settings saved: scale="
            .. tostring(S.tacticalScale)
            .. " gap=" .. tostring(S.tacticalGap)
            .. " fadeTime=" .. tostring(S.tacticalFadeTime)
            .. " linePos=" .. tostring(S.tacticalLinePosition))

        self:close()
    end

    function Panel:close()
        if self.ownerPanel then
            self.ownerPanel.forceVisible = false
        end
        self:setVisible(false)
        self:removeFromUIManager()
        if MT_SmartWatch.HUD.hotbarSettingsPanelInstance == self then
            MT_SmartWatch.HUD.hotbarSettingsPanelInstance = nil
        end
    end

    function Panel:onMouseDown(x, y)
        if y <= HEADER_H then
            self.moving = true
            self:setCapture(true)
            return true
        end
        return ISPanel.onMouseDown(self, x, y)
    end

    function Panel:onMouseMove(dx, dy)
        if self.moving then
            self:setX(self:getX() + dx)
            self:setY(self:getY() + dy)
            return true
        end
        return ISPanel.onMouseMove(self, dx, dy)
    end

    function Panel:onMouseMoveOutside(dx, dy)
        if self.moving then
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

        local title = L("UI_MTSW_HUD_HotbarTitle", "Tactical Hotbar")
        local tw = getTextManager():MeasureStringX(UIFont.Medium, title)
        self:drawText(title, (self.width - tw) / 2, 4, 1, 1, 1, 1, UIFont.Medium)
    end

    print("[MT Smart Watch - HUD] HotbarSettingsPanel class built")
end

function MT_SmartWatch.HUD.openHotbarSettingsPanel(ownerPanel)
    local existing = MT_SmartWatch.HUD.hotbarSettingsPanelInstance
    if existing then
        existing:close()
        return
    end

    local Panel = MT_SmartWatch.HUD.HotbarSettingsPanel
    if not Panel then
        print("[MT Smart Watch - HUD] HotbarSettingsPanel class not ready")
        return
    end

    local px = ownerPanel:getX() + ownerPanel:getWidth() + 10
    local py = ownerPanel:getY()

    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local panelW, panelH = 260, 400

    if px + panelW > screenW - 10 then px = ownerPanel:getX() - panelW - 10 end
    if px < 10 then px = 10 end
    if py + panelH > screenH - 10 then py = screenH - panelH - 10 end
    if py < 10 then py = 10 end

    local panel = Panel:new(px, py, ownerPanel)
    panel:initialise()
    panel:createChildren()
    panel:addToUIManager()
    panel:setAlwaysOnTop(true)
    panel:bringToTop()

    ownerPanel.forceVisible = true
    ownerPanel.alpha = 1

    MT_SmartWatch.HUD.hotbarSettingsPanelInstance = panel
end

if ISPanel then
    buildPanelClass()
else
    Events.OnGameBoot.Add(buildPanelClass)
end