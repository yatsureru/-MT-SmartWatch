-- HUD_Base.lua
MT_SmartWatch = MT_SmartWatch or {}
MT_SmartWatch.HUD = MT_SmartWatch.HUD or {}

if MT_SmartWatch.HUD.Base then return end

-- ============================================================
-- Время в мс (B42 safe)
-- ============================================================
local function getNowMs()
    if type(getTimestampMs) == "function" then return getTimestampMs() end
    if type(getTimeInMillis) == "function" then return getTimeInMillis() end
    if type(getTimestamp) == "function" then return getTimestamp() * 1000 end
    return 0
end

local FADE_DURATION = 0.5
local HOVER_SHRINK_PCT = 0.20

-- ============================================================
-- Отложенное создание класса
-- ============================================================
local function buildBaseClass()
    if MT_SmartWatch.HUD.Base then return end
    if not ISUIElement then
        print("[MT Smart Watch - HUD] FATAL: ISUIElement still not available at OnGameBoot")
        return
    end

    local Base = ISUIElement:derive("MT_SmartWatch_HUD_Base")
    MT_SmartWatch.HUD.Base = Base

    function Base:new(x, y, w, h, positionKey)
        local o = ISUIElement.new(self, x, y, w, h)
        setmetatable(o, self)
        self.__index = self

        o.positionKey    = positionKey
        o.fadeEnabled    = true
        o.dragEnabled    = true
        o.clickCallback  = nil
        o.visible        = false

        o.alpha          = 1
        o.hoverTimer     = 0
        o.hovered        = false

        o.moving                    = false
        o.dragging                  = false
        o.dragDistance              = 0
        o.dragThreshold             = 4
        o.suppressClickUntilRelease = false
        o.clickPending              = false

        o.mouseDownScreenX          = 0
        o.mouseDownScreenY          = 0
        o.mouseDownPanelX           = 0
        o.mouseDownPanelY           = 0

        o._lastMs                   = nil

        return o
    end

    function Base:getFadeTime()
        return (MT_SmartWatch.HUD.Settings and MT_SmartWatch.HUD.Settings.fadeTime) or 5
    end

    -- ========================================================
    -- Pin
    -- ========================================================
    function Base:getPositionSlot()
        local State = MT_SmartWatch.HUD.State
        if not State or not self.positionKey then return nil end
        return State.position[self.positionKey]
    end

    function Base:isPinned()
        local slot = self:getPositionSlot()
        return slot ~= nil and slot.pinned == true
    end

    function Base:setPinned(v)
        local slot = self:getPositionSlot()
        if not slot then return end
        slot.pinned = (v == true)
        local State = MT_SmartWatch.HUD.State
        if State then State.save() end
    end

    -- ========================================================
    -- Hover
    -- ========================================================
    function Base:updateHover()
        local mx, my = getMouseX(), getMouseY()
        local x, y, w, h = self:getX(), self:getY(), self:getWidth(), self:getHeight()

        local shrinkX = math.floor(w * HOVER_SHRINK_PCT + 0.5)
        local shrinkY = math.floor(h * HOVER_SHRINK_PCT + 0.5)

        local sx = x + shrinkX
        local sy = y + shrinkY
        local sw = w - shrinkX * 2
        local sh = h - shrinkY * 2

        self.hovered = mx >= sx and mx < sx + sw and my >= sy and my < sy + sh
    end

    -- ========================================================
    -- Fade
    -- ========================================================
    function Base:updateFade()
        if not self.fadeEnabled then
            self.alpha = 1
            return
        end

        if self.forceVisible then
            self.hoverTimer = 0
            self.alpha = 1
            self._lastMs = nil
            return
        end

        if self.moving or self.dragging or self.hovered then
            self.hoverTimer = 0
            self.alpha = 1
            self._lastMs = nil
            return
        end

        local fadeTime = self:getFadeTime()
        if fadeTime == 0 then
            self.alpha = 1
            self._lastMs = nil
            return
        end

        local nowMs = getNowMs()
        local dt = 0.016
        if self._lastMs and nowMs > 0 then
            local raw = (nowMs - self._lastMs) / 1000
            if raw < 0 then raw = 0 end
            dt = (raw > 0.25) and 0.016 or raw
        end
        self._lastMs = nowMs

        self.hoverTimer = self.hoverTimer + dt

        if self.hoverTimer < fadeTime then
            self.alpha = 1
        else
            local elapsed = self.hoverTimer - fadeTime
            self.alpha = math.max(0, 1 - elapsed / FADE_DURATION)
        end
    end

    -- ========================================================
    -- Позиция
    -- ========================================================
    function Base:savePosition()
        local slot = self:getPositionSlot()
        if not slot then return end
        slot.x = self:getX()
        slot.y = self:getY()
        local State = MT_SmartWatch.HUD.State
        if State then State.save() end
    end

    -- ========================================================
    -- Drag
    -- ========================================================
    function Base:onMouseDown(x, y)
        if not self.visible then return false end
        if x < 0 or y < 0 or x >= self:getWidth() or y >= self:getHeight() then
            return false
        end

        if self:isPinned() or not self.dragEnabled then
            self.clickPending = true
            self.moving       = false
            self.dragging     = false
            self.dragDistance = 0
            return true
        end

        self.moving = true
        self.dragging = false
        self.dragDistance = 0
        self.suppressClickUntilRelease = false
        self.clickPending = false

        self.mouseDownScreenX = getMouseX()
        self.mouseDownScreenY = getMouseY()
        self.mouseDownPanelX  = self:getX()
        self.mouseDownPanelY  = self:getY()

        self:bringToTop()
        self:setCapture(true)

        return true
    end

    function Base:updateDrag()
        if not self.moving or not self.dragEnabled then return end

        local dx = getMouseX() - self.mouseDownScreenX
        local dy = getMouseY() - self.mouseDownScreenY

        local newX = self.mouseDownPanelX + dx
        local newY = self.mouseDownPanelY + dy

        if math.abs(dx) > self.dragThreshold or math.abs(dy) > self.dragThreshold then
            self.dragging = true
            self.suppressClickUntilRelease = true
        end

        local screenW = getCore():getScreenWidth()
        local screenH = getCore():getScreenHeight()
        local maxX = math.max(0, screenW - self:getWidth())
        local maxY = math.max(0, screenH - self:getHeight())
        if newX < 0 then newX = 0 end
        if newY < 0 then newY = 0 end
        if newX > maxX then newX = maxX end
        if newY > maxY then newY = maxY end

        self:setX(newX)
        self:setY(newY)
    end

    function Base:onMouseMove(dx, dy)        self:updateDrag(); return true end
    function Base:onMouseMoveOutside(dx, dy) self:updateDrag(); return true end

    function Base:finishDrag()
        if not self.moving then return end

        local wasDragging   = self.dragging
        local wasSuppressed = self.suppressClickUntilRelease

        self.moving = false
        self.dragging = false
        self.dragDistance = 0
        self:setCapture(false)

        if wasDragging then
            self:savePosition()
        elseif not wasSuppressed and self.clickCallback then
            self.clickCallback(self)
        end

        self.suppressClickUntilRelease = false
    end

    function Base:onMouseUp(x, y)
        if self.clickPending then
            self.clickPending = false
            if self.clickCallback then
                self.clickCallback(self)
            end
            return true
        end
        self:finishDrag()
        return true
    end

    function Base:onMouseUpOutside(x, y)
        self.clickPending = false
        self:finishDrag()
        return true
    end

    function Base:onRightMouseUp(x, y)
        if not self.visible then return false end
        if x < 0 or y < 0 or x >= self:getWidth() or y >= self:getHeight() then
            return false
        end
        return false
    end

    print("[MT Smart Watch - HUD] Base loaded")
end

if ISUIElement then
    buildBaseClass()
else
    print("[MT Smart Watch - HUD] ISUIElement missing at load, deferring Base class to OnGameBoot")
    Events.OnGameBoot.Add(buildBaseClass)
end