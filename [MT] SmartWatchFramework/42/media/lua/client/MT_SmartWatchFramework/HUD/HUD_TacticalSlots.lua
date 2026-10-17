-- HUD_TacticalSlots.lua
MT_SmartWatch = MT_SmartWatch or {}
MT_SmartWatch.HUD = MT_SmartWatch.HUD or {}

if MT_SmartWatch.HUD.TacticalSlots then return end

local BASE_OUTER   = 56
local INNER_RATIO  = 64 / 84
local LOCK_BASE    = 10
local LOCK_SCALE   = 14
local CLICK_THRESH = 4
local SWEEP_BAND_H = 3
local SWEEP_PIXEL_X = 2

local LINE_BASE_HEIGHT = 16
local LINE_BASE_PAD    = 8
local LINE_LEFT_W      = 32
local LINE_TAIL_W      = 32
local LINE_OFFSET_X    = 25  -- Сдвиг полосы вправо

local TEXT_OFFSET_X    = 75  -- Сдвиг текста вправо от полосы
local TEXT_OFFSET_Y    = 5   -- Сдвиг текста вниз от полосы (было 15, теперь 5)

local CD_TEXT_COLOR   = { r = 0.78, g = 0.78, b = 0.78 }
local CD_BORDER_COLOR = { r = 0.851, g = 0.149, b = 0.149 }

local function tryGetTexture(paths)
    for _, p in ipairs(paths) do
        local tex = getTexture(p)
        if tex then return tex end
    end
    return nil
end

local function getChipTexture(fullType, data)
    if data then
        local path = data.texture or data.icon
        if path and type(path) == "string" then
            local tex = getTexture(path)
            if tex then return tex end
        end
    end
    if fullType and type(instanceItem) == "function" then
        local item = instanceItem(fullType)
        if item and item.getTexture then
            return item:getTexture()
        end
    end
    return nil
end

local function getChipCostText(data)
    if not data then return nil end
    local v = tonumber(data.batteryCost)
    if v and v > 0 then return tostring(math.floor(v + 0.5)) end
    return nil
end

local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end
local RAD_TO_DEG = 180 / math.pi

local function isPointTinted(dx, dy_up, angle_cleared)
    if angle_cleared <= 0.01 then return true end
    if angle_cleared >= 359.99 then return false end

    if dx == 0 and dy_up == 0 then
        return angle_cleared > 0 and false or true
    end
    if dx == 0 then
        local angle = (dy_up > 0) and 0 or 180
        return angle >= angle_cleared
    end
    if dy_up == 0 then
        local angle = (dx > 0) and 90 or 270
        return angle >= angle_cleared
    end

    local a = atan2(dx, dy_up) * RAD_TO_DEG
    if a < 0 then a = a + 360 end
    return a >= angle_cleared
end

local function drawClockSweep(ui, sx, sy, sw, sh, ratio, alpha)
    if ratio <= 0.001 then return end
    if ratio >= 0.999 then
        ui:drawRect(sx, sy, sw, sh, alpha, 0, 0, 0)
        return
    end

    local cx = sx + sw / 2
    local cy = sy + sh / 2
    local angle_cleared = (1 - ratio) * 360

    local row = 0
    while row < sh do
        local bandH = math.min(SWEEP_BAND_H, sh - row)
        local y_px = sy + row + bandH / 2
        local dy_up = cy - y_px

        local x = sx
        local strip_start = nil

        while x < sx + sw do
            local step_w = math.min(SWEEP_PIXEL_X, sx + sw - x)
            local dx = x + step_w / 2 - cx
            local tinted = isPointTinted(dx, dy_up, angle_cleared)

            if tinted then
                if not strip_start then strip_start = x end
            else
                if strip_start then
                    ui:drawRect(strip_start, sy + row, x - strip_start, bandH, alpha, 0, 0, 0)
                    strip_start = nil
                end
            end

            x = x + step_w
        end

        if strip_start then
            ui:drawRect(strip_start, sy + row, (sx + sw) - strip_start, bandH, alpha, 0, 0, 0)
        end

        row = row + bandH
    end
end

local function drawBatteryEmpty(ui, cx, cy, size, alpha)
    if MT_SmartWatch.HUD.batteryEmptyTex == nil then
        local tex = tryGetTexture({
            "media/UI/OnScreenTacticalPanelHUD/OnScreenTacticalPanelHUD_BatteryEmpty.png",
            "UI/OnScreenTacticalPanelHUD/OnScreenTacticalPanelHUD_BatteryEmpty.png",
            "media/UI/OnScreenTacticalPanelHUD/battery_empty.png",
            "UI/OnScreenTacticalPanelHUD/battery_empty.png",
        })
        MT_SmartWatch.HUD.batteryEmptyTex = tex or false
    end

    local tex = MT_SmartWatch.HUD.batteryEmptyTex

    if tex and tex ~= false then
        local w = size
        local h = size
        ui:drawTextureScaled(tex, cx - w/2, cy - h/2, w, h, alpha, 1, 1, 1)
        return
    end

    local w = size
    local h = size * 0.55
    local x = cx - w/2 - (size * 0.06) / 2
    local y = cy - h/2

    ui:drawRectBorder(x, y, w, h, alpha, 0.85, 0.85, 0.85)
    local tipW = math.max(2, math.floor(size * 0.08))
    local tipH = math.floor(h * 0.4)
    ui:drawRect(x + w, y + (h - tipH)/2, tipW, tipH, alpha, 0.85, 0.85, 0.85)
end

local function buildClass()
    if MT_SmartWatch.HUD.TacticalSlots then return end

    local Base = MT_SmartWatch.HUD.Base
    if not Base then
        Events.OnGameBoot.Add(buildClass)
        return
    end

    local Slots = Base:derive("MT_SmartWatch_HUD_TacticalSlots")
    MT_SmartWatch.HUD.TacticalSlots = Slots

    function Slots:new(x, y)
        local o = Base.new(self, x, y, BASE_OUTER, BASE_OUTER, "tacticalSlots")
        setmetatable(o, self)
        self.__index = self

        o.slotCount      = 0
        o.slotData       = {}
        o.texEmpty       = nil
        o.texLockOn      = nil
        o.texLockOff     = nil
        o.texLineLeft    = nil
        o.texLineCenter  = nil
        o.texLineTail    = nil
        o.clickCallback  = nil

        o.draggingChip   = nil
        o.draggingIdx    = nil
        o.dragStartX     = 0
        o.dragStartY     = 0
        o.draggingActive = false

        o.hoveredSlotIdx = nil

        return o
    end

    function Slots:initialise()
        ISUIElement.initialise(self)

        self.texEmpty   = tryGetTexture({
            "media/UI/OnScreenTacticalPanelHUD/OnScreenTacticalPanelHUD_SlotEmpty.png",
            "UI/OnScreenTacticalPanelHUD/OnScreenTacticalPanelHUD_SlotEmpty.png",
            "media/UI/OnScreenTacticalPanelHUD/slot_empty.png",
            "UI/OnScreenTacticalPanelHUD/slot_empty.png",
        })
        self.texLockOn  = tryGetTexture({
            "media/UI/OnScreenTacticalPanelHUD/OnScreenTacticalPanelHUD_LockClosed.png",
            "UI/OnScreenTacticalPanelHUD/OnScreenTacticalPanelHUD_LockClosed.png",
            "media/UI/OnScreenTacticalPanelHUD/lock_closed.png",
            "UI/OnScreenTacticalPanelHUD/lock_closed.png",
        })
        self.texLockOff = tryGetTexture({
            "media/UI/OnScreenTacticalPanelHUD/OnScreenTacticalPanelHUD_LockOpen.png",
            "UI/OnScreenTacticalPanelHUD/OnScreenTacticalPanelHUD_LockOpen.png",
            "media/UI/OnScreenTacticalPanelHUD/lock_open.png",
            "UI/OnScreenTacticalPanelHUD/lock_open.png",
        })

        self.texLineLeft   = tryGetTexture({
            "media/UI/OnScreenTacticalPanelHUD/OnScreenTacticalPanelHUD_LineLeft.png",
            "UI/OnScreenTacticalPanelHUD/OnScreenTacticalPanelHUD_LineLeft.png",
        })
        self.texLineCenter = tryGetTexture({
            "media/UI/OnScreenTacticalPanelHUD/OnScreenTacticalPanelHUD_LineCenter.png",
            "UI/OnScreenTacticalPanelHUD/OnScreenTacticalPanelHUD_LineCenter.png",
        })
        self.texLineTail   = tryGetTexture({
            "media/UI/OnScreenTacticalPanelHUD/OnScreenTacticalPanelHUD_LineTail.png",
            "UI/OnScreenTacticalPanelHUD/OnScreenTacticalPanelHUD_LineTail.png",
        })
    end

    function Slots:getFadeTime()
        return (MT_SmartWatch.HUD.Settings and MT_SmartWatch.HUD.Settings.tacticalFadeTime) or 0
    end

    function Slots:getScale()
        return (MT_SmartWatch.HUD.Settings and MT_SmartWatch.HUD.Settings.tacticalScale) or 1.0
    end

    function Slots:getLinePosition()
        local S = MT_SmartWatch.HUD.Settings
        return (S and S.tacticalLinePosition) or "bottom"
    end

    -- Для текста всегда используем Small (он базовый), а уменьшаем через масштаб
    function Slots:getBatteryFont()
        return UIFont.Small
    end

    function Slots:getOuterSize()
        return math.floor(BASE_OUTER * self:getScale() + 0.5)
    end

    function Slots:getInnerSize()
        return math.floor(self:getOuterSize() * INNER_RATIO + 0.5)
    end

    function Slots:getGap()
        local baseGap = (MT_SmartWatch.HUD.Settings and MT_SmartWatch.HUD.Settings.tacticalGap) or 2.5
        return math.floor(baseGap * self:getScale() + 0.5)
    end

    function Slots:getLockSize()
        return math.floor(LOCK_BASE + LOCK_SCALE * self:getScale() + 0.5)
    end

    function Slots:getLineHeight()
        return math.floor(LINE_BASE_HEIGHT * self:getScale() + 0.5)
    end

    function Slots:getLinePad()
        return math.floor(LINE_BASE_PAD * self:getScale() + 0.5)
    end

    function Slots:getLineLeftW()
        return math.floor(LINE_LEFT_W * self:getScale() + 0.5)
    end

    function Slots:getLineTailW()
        return math.floor(LINE_TAIL_W * self:getScale() + 0.5)
    end

    function Slots:getLineOffsetX()
        return math.floor(LINE_OFFSET_X * self:getScale() + 0.5)
    end

    function Slots:getSlotsOffsetY()
        if self:getLinePosition() == "top" then
            local font = self:getBatteryFont()
            local th = getTextManager():getFontHeight(font)
            local scaledTh = math.floor(th * 0.5 * self:getScale()) -- высота уменьшенного текста
            local textOffY = math.floor(TEXT_OFFSET_Y * self:getScale())
            return self:getLinePad() + self:getLineHeight() + textOffY + scaledTh + self:getLinePad()
        end
        return 0
    end

    function Slots:setSlotCount(count)
        self.slotCount = math.max(0, count)
        self:recalcSize()
    end

    function Slots:recalcSize()
        local outer    = self:getOuterSize()
        local gap      = self:getGap()
        local lockSize = self:getLockSize()
        local n        = self.slotCount

        local w = n * outer + math.max(0, n - 1) * gap
        if n > 0 then
            w = w + gap + lockSize
        end

        local extraH = 0
        if n > 0 then
            local font = self:getBatteryFont()
            local th = getTextManager():getFontHeight(font)
            local scaledTh = math.floor(th * 0.5 * self:getScale())
            local textOffY = math.floor(TEXT_OFFSET_Y * self:getScale())
            -- Высота: пад + линия + отступ текста + высота текста + пад
            extraH = self:getLinePad() + self:getLineHeight() + textOffY + scaledTh + self:getLinePad()
        end

        local width = math.max(w, outer)
        if n > 0 then
            width = width + self:getLineOffsetX()
        end

        self:setWidth(width)
        self:setHeight(outer + extraH)
    end

    function Slots:getSlotRect(i)
        local outer = self:getOuterSize()
        local gap   = self:getGap()
        local x     = (i - 1) * (outer + gap)
        return x, 0, outer, outer
    end

    function Slots:getLockRect()
        local n = self.slotCount
        if n <= 0 then return nil end
        local outer    = self:getOuterSize()
        local gap      = self:getGap()
        local lockSize = self:getLockSize()
        local lx = n * outer + (n - 1) * gap + gap
        local ly = self:getSlotsOffsetY() + math.floor((outer - lockSize) / 2)
        return lx, ly, lockSize, lockSize
    end

    function Slots:isPointInLock(px, py)
        local lx, ly, lw, lh = self:getLockRect()
        if not lx then return false end
        return px >= lx and px < lx + lw and py >= ly and py < ly + lh
    end

    function Slots:getSlotIndexAt(px, py)
        local slotsOffsetY = self:getSlotsOffsetY()
        local realY = py - slotsOffsetY
        if realY < 0 or realY > self:getOuterSize() then return nil end
        for i = 1, self.slotCount do
            local sx, _, sw, _ = self:getSlotRect(i)
            if px >= sx and px < sx + sw then return i end
        end
        return nil
    end

    function Slots:refresh()
        local State = MT_SmartWatch.HUD.State
        local ChipSystem = MT_SmartWatch.ChipSystem
        local watch = State and State.watch
        if not watch or not ChipSystem then
            self.slotData = {}
            self:recalcSize()
            return
        end

        ChipSystem.pruneHotbarSlots(watch)

        local assignments = ChipSystem.getHotbarSlots(watch) or {}
        local newData = {}

        for i = 1, self.slotCount do
            local fullType = assignments[i]
            if fullType then
                local data = ChipSystem.getChipDataByFullType(fullType)
                if data then
                    newData[i] = {
                        fullType = fullType,
                        data     = data,
                        texture  = getChipTexture(fullType, data),
                        costText = getChipCostText(data),
                    }
                end
            end
        end

        self.slotData = newData
        self:recalcSize()
    end

    function Slots:resetDragState()
        self.draggingChip   = nil
        self.draggingIdx    = nil
        self.draggingActive = false
        self.moving         = false
        self.dragging       = false
        self.dragDistance   = 0
        self.clickPending   = false
        self:setCapture(false)

        if MT_SmartWatch.HUD.hideDragPreview then
            MT_SmartWatch.HUD.hideDragPreview()
        end
    end

    function Slots:onMouseDown(px, py)
        if not self.visible then return false end

        if self:isPointInLock(px, py) then
            local S = MT_SmartWatch.HUD.Settings
            S.tacticalLock = not S.tacticalLock
            local State = MT_SmartWatch.HUD.State
            if State then State.save() end
            self:resetDragState()
            return true
        end

        local idx = self:getSlotIndexAt(px, py)
        if idx and self.slotData[idx] then
            self.draggingChip   = self.slotData[idx]
            self.draggingIdx    = idx
            self.dragStartX     = getMouseX()
            self.dragStartY     = getMouseY()
            self.draggingActive = false
            self:setCapture(true)
            return true
        end

        return Base.onMouseDown(self, px, py)
    end

    function Slots:updateChipDrag()
        if not self.draggingChip then return end
        local mx, my = getMouseX(), getMouseY()
        local dx = mx - self.dragStartX
        local dy = my - self.dragStartY
        local dist = math.sqrt(dx * dx + dy * dy)

        if not self.draggingActive and dist > CLICK_THRESH then
            self.draggingActive = true
            if MT_SmartWatch.HUD.showDragPreview then
                MT_SmartWatch.HUD.showDragPreview(self.draggingChip.texture)
            end
        end
    end

    function Slots:onMouseMove(dx, dy)
        if self.draggingChip then
            self:updateChipDrag()
            return true
        end
        return Base.onMouseMove(self, dx, dy)
    end

    function Slots:onMouseMoveOutside(dx, dy)
        if self.draggingChip then
            self:updateChipDrag()
            return true
        end
        return Base.onMouseMoveOutside(self, dx, dy)
    end

    function Slots:unassignSlot(idx)
        local State = MT_SmartWatch.HUD.State
        local ChipSystem = MT_SmartWatch.ChipSystem
        local watch = State and State.watch
        if not watch or not ChipSystem then return end

        ChipSystem.clearHotbarSlot(watch, idx)
        self:refresh()
    end

    function Slots:swapSlots(a, b)
        local State = MT_SmartWatch.HUD.State
        local ChipSystem = MT_SmartWatch.ChipSystem
        local watch = State and State.watch
        if not watch or not ChipSystem then return end

        local ftA = ChipSystem.getHotbarSlot(watch, a)
        local ftB = ChipSystem.getHotbarSlot(watch, b)
        ChipSystem.setHotbarSlot(watch, a, ftB)
        ChipSystem.setHotbarSlot(watch, b, ftA)
        self:refresh()
    end

    function Slots:finishChipDrag(px, py)
        if not self.draggingChip then return end

        local wasActive = self.draggingActive
        local srcIdx    = self.draggingIdx

        self.draggingChip   = nil
        self.draggingIdx    = nil
        self.draggingActive = false

        if MT_SmartWatch.HUD.hideDragPreview then
            MT_SmartWatch.HUD.hideDragPreview()
        end

        if wasActive then
            local inside = px >= 0 and px < self:getWidth()
                and py >= 0 and py < self:getHeight()
            local S = MT_SmartWatch.HUD.Settings
            if not inside then
                if not S.tacticalLock then
                    self:unassignSlot(srcIdx)
                end
            else
                local targetIdx = self:getSlotIndexAt(px, py)
                if targetIdx and targetIdx ~= srcIdx then
                    if not S.tacticalLock then
                        self:swapSlots(srcIdx, targetIdx)
                    end
                end
            end
        else
            local chip = self.slotData[srcIdx]
            if chip then
                local player = getPlayer()
                local State = MT_SmartWatch.HUD.State
                local ChipSystem = MT_SmartWatch.ChipSystem
                if player and State.watch and ChipSystem then
                    ChipSystem.activateChip(player, State.watch, chip.fullType)
                end
            end
        end
    end

    function Slots:onMouseUp(px, py)
        if self.draggingChip then
            self:finishChipDrag(px, py)
        end
        self.moving = false
        self.dragging = false
        self.dragDistance = 0
        self.clickPending = false
        self:setCapture(false)
        return true
    end

    function Slots:onMouseUpOutside(px, py)
        if self.draggingChip then
            self:finishChipDrag(px, py)
        end
        self.moving = false
        self.dragging = false
        self.dragDistance = 0
        self.clickPending = false
        self:setCapture(false)
        return true
    end

    function Slots:onRightMouseUp(px, py)
        if not self.visible then return false end
        if px < 0 or py < 0 or px >= self:getWidth() or py >= self:getHeight() then
            return false
        end
        if MT_SmartWatch.HUD.openHotbarSettingsPanel then
            MT_SmartWatch.HUD.openHotbarSettingsPanel(self)
        end
        return true
    end

    function Slots:render()
        if not self.visible then return end

        if self.moving and not isMouseButtonDown(0) then
            self.moving = false
            self.dragging = false
            self.dragDistance = 0
            self:setCapture(false)
        end

        if self.draggingActive and not isMouseButtonDown(0) then
            local mx, my = getMouseX(), getMouseY()
            local px = mx - self:getAbsoluteX()
            local py = my - self:getAbsoluteY()
            self:finishChipDrag(px, py)
        end

        self:updateHover()
        self:updateFade()

        if self.alpha <= 0.01 then return end

        local outer        = self:getOuterSize()
        local inner        = self:getInnerSize()
        local offset       = math.floor((outer - inner) / 2)
        local slotsOffsetY = self:getSlotsOffsetY()
        local lineOffsetX  = self:getLineOffsetX()
        local linePos      = self:getLinePosition()
        local locked       = MT_SmartWatch.HUD.Settings
            and MT_SmartWatch.HUD.Settings.tacticalLock

        local mx, my = getMouseX(), getMouseY()
        local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
        local px, py = mx - ax, my - ay
        self.hoveredSlotIdx = self:getSlotIndexAt(px, py)

        -- =========================================================
        -- ПОЛОСА + BATTERY STATUS
        -- =========================================================
        if self.slotCount > 0 then
            local gap    = self:getGap()
            local totalSlotsW = (self.slotCount * outer) + (math.max(0, self.slotCount - 1) * gap)

            local lineY
            if linePos == "top" then
                lineY = self:getLinePad()
            else
                lineY = outer + self:getLinePad()
            end

            local lineH = self:getLineHeight()

            local leftW = self:getLineLeftW()
            local tailW = self:getLineTailW()

            if leftW + tailW > totalSlotsW then
                local ratio = totalSlotsW / (leftW + tailW)
                leftW = math.floor(leftW * ratio)
                tailW = totalSlotsW - leftW
            end

            local centerW = totalSlotsW - leftW - tailW

            if self.texLineLeft and leftW > 0 then
                self:drawTextureScaled(self.texLineLeft,
                    lineOffsetX, lineY, leftW, lineH, self.alpha, 1, 1, 1)
            end

            if centerW > 0 then
                if self.texLineCenter then
                    self:drawTextureScaled(self.texLineCenter,
                        lineOffsetX + leftW, lineY, centerW, lineH, self.alpha, 1, 1, 1)
                else
                    self:drawRect(lineOffsetX + leftW,
                        lineY + lineH/2 - 1, centerW, 2, self.alpha, 0.8, 0.8, 0.8)
                end
            end

            if self.texLineTail and tailW > 0 then
                self:drawTextureScaled(self.texLineTail,
                    lineOffsetX + leftW + centerW, lineY, tailW, lineH, self.alpha, 1, 1, 1)
            elseif tailW > 0 then
                self:drawRect(lineOffsetX + leftW + centerW,
                    lineY + lineH/2 - 1, tailW - 4, 2, self.alpha, 0.8, 0.8, 0.8)
                self:drawRect(lineOffsetX + leftW + centerW + tailW - 4,
                    lineY + lineH/2, 4, 2, self.alpha, 0.8, 0.8, 0.8)
            end

            -- BATTERY STATUS (Текст)
            local State = MT_SmartWatch.HUD.State
            local watch = State and State.watch
            local Battery = MT_SmartWatch.Battery
            
            if watch and Battery and Battery.getCurrent then
                local cur = math.floor(Battery.getCurrent(watch) or 0)
                local max = math.floor(Battery.getMax(watch) or 0)
                
                if max > 0 then
                    local batText = "Battery Status: " .. tostring(cur) .. " \\ " .. tostring(max)
                    local font = self:getBatteryFont()
                    
                    local textX = lineOffsetX + math.floor(TEXT_OFFSET_X * self:getScale())
                    local textY = lineY + math.floor(TEXT_OFFSET_Y * self:getScale())
                    
                    -- Масштабируем текст в 2 раза меньше относительно текущего scale
                    local textScale = 0.5 * self:getScale()
                    
                    -- Проверка на наличие drawTextScaled (B42)
                    if self.drawTextScaled then
                        self:drawTextScaled(batText, textX, textY, textScale, 0.55, 0.55, 0.55, self.alpha, font)
                    else
                        self:drawText(batText, textX, textY, 0.55, 0.55, 0.55, self.alpha, font)
                    end
                end
            end
        end

        -- =========================================================
        -- СЛОТЫ
        -- =========================================================
        for i = 1, self.slotCount do
            local sx, sy, sw, sh = self:getSlotRect(i)
            sy = sy + slotsOffsetY

            local chip = self.slotData[i]

            if self.texEmpty then
                self:drawTextureScaled(self.texEmpty, sx, sy, sw, sh,
                    self.alpha, 1, 1, 1)
            else
                self:drawRect(sx, sy, sw, sh,
                    self.alpha * 0.35, 0.10, 0.10, 0.10)
                self:drawRectBorder(sx, sy, sw, sh,
                    self.alpha * 0.9, 0.40, 0.40, 0.40)
                self:drawRectBorder(sx + offset, sy + offset, inner, inner,
                    self.alpha * 0.8, 0.35, 0.35, 0.35)
            end

            if chip then
                if chip.texture then
                    self:drawTextureScaled(chip.texture,
                        sx + offset, sy + offset, inner, inner,
                        self.alpha, 1, 1, 1)
                end

                local State = MT_SmartWatch.HUD.State
                local watch = State and State.watch

                local batteryCost = tonumber(chip.data and chip.data.batteryCost) or 0
                local currentCharge = 0
                local Battery = MT_SmartWatch.Battery
                if Battery and Battery.getCurrent and watch then
                    currentCharge = Battery.getCurrent(watch) or 0
                end
                local notEnoughBattery = (batteryCost > 0) and (currentCharge < batteryCost)

                local cd = 0
                if watch and chip.data and chip.data.getCooldown then
                    local ok, val = pcall(chip.data.getCooldown, watch)
                    if ok then cd = tonumber(val) or 0 end
                end

                local nowMs = 0
                if type(getTimestampMs) == "function" then
                    nowMs = getTimestampMs()
                elseif type(getTimeInMillis) == "function" then
                    nowMs = getTimeInMillis()
                end
                local pulse = 0.5 + 0.5 * math.sin(nowMs / 350)

                if cd > 0 then
                    local dayLengthIdx = 3
                    if SandboxVars and SandboxVars.DayLength then
                        local dl = tonumber(SandboxVars.DayLength)
                        if dl and dl >= 1 and dl <= 7 then
                            dayLengthIdx = dl
                        end
                    end
                    local factorTable = { 0.625, 1.25, 2.5, 5, 7.5, 30, 60 }
                    local factor = factorTable[dayLengthIdx] or 2.5

                    local realSec      = cd * factor
                    local totalGameMin = (chip.data and chip.data.cooldownMinutes) or cd
                    local totalRealSec = totalGameMin * factor

                    local ratio = 1.0
                    if totalRealSec > 0 then
                        ratio = math.max(0, math.min(1, realSec / totalRealSec))
                    end

                    drawClockSweep(self, sx, sy, sw, sh, ratio, 0.82 * self.alpha)

                    local borderAlpha = pulse * self.alpha
                    self:drawRectBorder(sx, sy, sw, sh,
                        borderAlpha, CD_BORDER_COLOR.r, CD_BORDER_COLOR.g, CD_BORDER_COLOR.b)
                    self:drawRectBorder(sx + 1, sy + 1, sw - 2, sh - 2,
                        borderAlpha * 0.6, CD_BORDER_COLOR.r, CD_BORDER_COLOR.g, CD_BORDER_COLOR.b)

                    local secInt = math.ceil(realSec)
                    local text
                    if secInt < 60 then
                        text = tostring(secInt)
                    elseif secInt < 3600 then
                        text = string.format("%d:%02d",
                            math.floor(secInt / 60), secInt % 60)
                    else
                        text = string.format("%dh%02d",
                            math.floor(secInt / 3600),
                            math.floor((secInt % 3600) / 60))
                    end

                    local scale = self:getScale()
                    local prefFonts
                    if scale >= 1.25 then
                        prefFonts = { UIFont.Large, UIFont.Medium, UIFont.Small }
                    elseif scale >= 0.75 then
                        prefFonts = { UIFont.Medium, UIFont.Small }
                    else
                        prefFonts = { UIFont.Small }
                    end

                    local font = UIFont.Small
                    for _, f in ipairs(prefFonts) do
                        local w = getTextManager():MeasureStringX(f, text)
                        if w <= sw - 6 then
                            font = f
                            break
                        end
                    end

                    local textAlpha = (0.9 + 0.1 * pulse) * self.alpha

                    local tw = getTextManager():MeasureStringX(font, text)
                    local th = getTextManager():getFontHeight(font)
                    local tx = sx + math.floor((sw - tw) / 2)
                    local ty = sy + math.floor((sh - th) / 2)

                    self:drawText(text, tx - 1, ty - 1, 0, 0, 0, textAlpha, font)
                    self:drawText(text, tx + 1, ty - 1, 0, 0, 0, textAlpha, font)
                    self:drawText(text, tx - 1, ty + 1, 0, 0, 0, textAlpha, font)
                    self:drawText(text, tx + 1, ty + 1, 0, 0, 0, textAlpha, font)
                    self:drawText(text, tx, ty,
                        CD_TEXT_COLOR.r, CD_TEXT_COLOR.g, CD_TEXT_COLOR.b,
                        textAlpha, font)

                elseif notEnoughBattery then
                    self:drawRect(sx, sy, sw, sh, 0.82 * self.alpha, 0, 0, 0)

                    local battAlpha = (0.5 + 0.5 * pulse) * self.alpha
                    local battSize = inner
                    drawBatteryEmpty(self,
                        sx + sw / 2,
                        sy + sh / 2,
                        battSize,
                        battAlpha)

                    local borderAlpha = (0.3 + 0.4 * pulse) * self.alpha
                    self:drawRectBorder(sx, sy, sw, sh,
                        borderAlpha, CD_BORDER_COLOR.r, CD_BORDER_COLOR.g, CD_BORDER_COLOR.b)
                    self:drawRectBorder(sx + 1, sy + 1, sw - 2, sh - 2,
                        borderAlpha * 0.6, CD_BORDER_COLOR.r, CD_BORDER_COLOR.g, CD_BORDER_COLOR.b)
                end
            end
        end

        -- Замок
        local lx, ly, lw, lh = self:getLockRect()
        if lx then
            local tex = locked and self.texLockOn or self.texLockOff
            if tex then
                self:drawTextureScaled(tex, lx, ly, lw, lh,
                    self.alpha, 1, 1, 1)
            else
                local r, g, b = locked and 0.95 or 0.95,
                                locked and 0.25 or 0.80,
                                locked and 0.25 or 0.20
                self:drawRect(lx, ly, lw, lh, self.alpha * 0.8, r, g, b)
                self:drawRectBorder(lx, ly, lw, lh,
                    self.alpha * 0.9, 0.40, 0.40, 0.40)
            end
        end

        -- Tooltip
        if self.hoveredSlotIdx and self.slotData[self.hoveredSlotIdx] then
            local chip = self.slotData[self.hoveredSlotIdx]
            local name = (chip.data and chip.data.name) or chip.fullType or "?"
            local nameW = getTextManager():MeasureStringX(UIFont.Small, name)
            local costStr = chip.costText and ("Cost: " .. chip.costText) or ""
            local costW = getTextManager():MeasureStringX(UIFont.Small, costStr)
            local boxW = math.max(nameW, costW) + 12
            local boxH = 30
            local boxX = mx + 12
            local boxY = my - boxH - 8
            self:drawRect(boxX, boxY, boxW, boxH, 0.9, 0.05, 0.05, 0.05)
            self:drawRectBorder(boxX, boxY, boxW, boxH, 1, 0.6, 0.6, 0.6)
            self:drawText(name, boxX + 6, boxY + 4, 0.9, 0.9, 0.9, 1, UIFont.Small)
            if costStr ~= "" then
                self:drawText(costStr, boxX + 6, boxY + 16, 0.55, 0.55, 0.55, 1, UIFont.Small)
            end
        end
    end

    print("[MT Smart Watch - HUD] TacticalSlots class built")
end

if ISUIElement and MT_SmartWatch.HUD.Base then
    buildClass()
else
    Events.OnGameBoot.Add(buildClass)
end

-- ============================================================
-- handleChipDrop
-- ============================================================
function MT_SmartWatch.HUD.handleChipDrop(chip, mx, my)
    if not chip or not chip.fullType then return false end

    local S = MT_SmartWatch.HUD.Settings
    if S and S.tacticalLock then
        print("[MT Smart Watch - HUD] drop ignored: hotbar is locked")
        return false
    end

    local slots = MT_SmartWatch.HUD.tacticalSlots
    if not slots or not slots.visible then return false end

    local px = mx - slots:getAbsoluteX()
    local py = my - slots:getAbsoluteY()

    if px < 0 or px >= slots:getWidth() or py < 0 or py >= slots:getHeight() then
        return false
    end

    local idx = slots:getSlotIndexAt(px, py)
    if not idx then return false end

    local State = MT_SmartWatch.HUD.State
    local ChipSystem = MT_SmartWatch.ChipSystem
    local watch = State and State.watch
    if not watch or not ChipSystem then return false end

    ChipSystem.setHotbarSlot(watch, idx, chip.fullType)
    slots:refresh()

    print("[MT Smart Watch - HUD] chip attached to slot " .. tostring(idx)
        .. ": " .. tostring(chip.fullType))
    return true
end