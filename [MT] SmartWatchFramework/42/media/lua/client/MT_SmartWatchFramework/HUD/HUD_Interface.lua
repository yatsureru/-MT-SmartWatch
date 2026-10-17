-- HUD_Interface.lua
MT_SmartWatch = MT_SmartWatch or {}
MT_SmartWatch.HUD = MT_SmartWatch.HUD or {}

if MT_SmartWatch.HUD.Interface then return end

require "MT_SmartWatchFramework/HUD/HUD_State"

local function L(key, fallback)
    if type(getTextOrNull) == "function" then
        local v = getTextOrNull(key)
        if v and v ~= "" then return v end
    end
    return fallback or key
end

local function buildInterfaceClass()
    if MT_SmartWatch.HUD.Interface then return end
    if not ISPanel then
        print("[MT Smart Watch - HUD] FATAL: ISPanel not available for Interface")
        return
    end

    local Panel = ISPanel:derive("MT_SmartWatch_HUD_Interface")
    MT_SmartWatch.HUD.Interface = Panel

    local HEADER_H = 26
    local PANEL_W  = 320
    local PANEL_H  = 200

    function Panel:new(x, y)
        local o = ISPanel:new(x, y, PANEL_W, PANEL_H)
        setmetatable(o, self)
        self.__index = self

        o.moving          = false
        o.backgroundColor = { r = 0.04, g = 0.04, b = 0.04, a = 0.95 }
        o.borderColor     = { r = 0.45, g = 0.45, b = 0.45, a = 1    }

        return o
    end

    function Panel:createChildren()
        ISPanel.createChildren(self)

        local y = HEADER_H + 24

        -- Tactical Chips button
        self.tacticalBtn = ISButton:new(20, y, self.width - 40, 32,
            L("UI_MTSW_HUD_TacticalChips", "Tactical Chips"),
            self, Panel.onTacticalClick)
        self.tacticalBtn:initialise()
        self:addChild(self.tacticalBtn)

        -- Close button (top-right)
        self.closeBtn = ISButton:new(self.width - 26, 3, 22, 20, "X",
            self, Panel.onClose)
        self.closeBtn:initialise()
        self.closeBtn.borderColor = { r = 1.0, g = 0.3, b = 0.3, a = 1 }
        self:addChild(self.closeBtn)
    end

    function Panel:onTacticalClick()
        if MT_SmartWatch.HUD.openInterfaceTacticalChips then
            MT_SmartWatch.HUD.openInterfaceTacticalChips(self)
        end
    end

    function Panel:onClose()
        self:close()
    end

    function Panel:close()
        self:setVisible(false)
        self:removeFromUIManager()

        if MT_SmartWatch.HUD.interfacePanel == self then
            MT_SmartWatch.HUD.interfacePanel = nil
        end

        -- Закрываем дочернюю панель тоже
        if MT_SmartWatch.HUD.interfaceTacticalChipsPanel then
            MT_SmartWatch.HUD.interfaceTacticalChipsPanel:close()
        end
    end

    -- ===== Drag за шапку =====
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

        self:drawRect(0, 0, self.width, HEADER_H, 0.75, 0.12, 0.12, 0.12)
        self:drawRectBorder(0, 0, self.width, self.height,
            self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)

        local title = L("UI_MTSW_HUD_Title", "MT SmartWatch")
        local tw = getTextManager():MeasureStringX(UIFont.Medium, title)
        self:drawText(title, (self.width - tw) / 2, 4, 1, 1, 1, 1, UIFont.Medium)
    end

    print("[MT Smart Watch - HUD] Interface class built")
end

-- ============================================================
-- Открытие (singleton + toggle)
-- ============================================================
function MT_SmartWatch.HUD.openInterface()
    local existing = MT_SmartWatch.HUD.interfacePanel

    -- Toggle: если уже открыта — закрываем
    if existing then
        existing:close()
        return
    end

    local Panel = MT_SmartWatch.HUD.Interface
    if not Panel then
        print("[MT Smart Watch - HUD] Interface class not ready")
        return
    end

    -- Позиция: рядом с иконкой часов
    local icon = MT_SmartWatch.HUD.icon
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local panelW, panelH = 320, 200

    local px, py = 100, 100
    if icon then
        px = icon:getX() - panelW - 20
        if px < 10 then px = icon:getX() + icon:getWidth() + 20 end
        py = icon:getY()
    end
    if px + panelW > screenW - 10 then px = screenW - panelW - 10 end
    if py + panelH > screenH - 10 then py = screenH - panelH - 10 end
    if px < 10 then px = 10 end
    if py < 10 then py = 10 end

    local panel = Panel:new(px, py)
    panel:initialise()
    panel:createChildren()
    panel:addToUIManager()
    panel:setAlwaysOnTop(true)
    panel:bringToTop()

    MT_SmartWatch.HUD.interfacePanel = panel
end

if ISPanel then
    buildInterfaceClass()
else
    Events.OnGameBoot.Add(buildInterfaceClass)
end