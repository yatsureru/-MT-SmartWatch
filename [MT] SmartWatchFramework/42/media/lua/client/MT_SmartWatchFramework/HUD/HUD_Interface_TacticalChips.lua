-- HUD_Interface_TacticalChips.lua
MT_SmartWatch = MT_SmartWatch or {}
MT_SmartWatch.HUD = MT_SmartWatch.HUD or {}

if MT_SmartWatch.HUD.Interface_TacticalChips then return end

require "MT_SmartWatchFramework/HUD/HUD_State"

local function L(key, fallback)
    if type(getTextOrNull) == "function" then
        local v = getTextOrNull(key)
        if v and v ~= "" then return v end
    end
    return fallback or key
end

-- ============================================================
-- Иконка чипа
-- ============================================================
local function getChipTexture(chip)
    if not chip then return nil end

    local data = chip.data
    if data then
        local path = data.texture or data.icon
        if path and type(path) == "string" then
            local tex = getTexture(path)
            if tex then return tex end
        end
    end

    if chip.fullType and type(instanceItem) == "function" then
        local item = instanceItem(chip.fullType)
        if item and item.getTexture then
            return item:getTexture()
        end
    end

    return nil
end

-- ============================================================
-- Имя чипа
-- ============================================================
local function resolveChipName(chip)
    if not chip then return "?" end
    local data     = chip.data or {}
    local fullType = chip.fullType or ""

    if data.nameKey and type(getTextOrNull) == "function" then
        local v = getTextOrNull(data.nameKey)
        if v and v ~= "" then return v end
    end

    if fullType ~= "" and type(instanceItem) == "function" then
        local item = instanceItem(fullType)
        if item and item.getName then
            local name = item:getName()
            if name and name ~= "" and name ~= fullType then
                return name
            end
        end
    end

    if type(getTextOrNull) == "function" then
        local v = getTextOrNull("ItemName_" .. fullType)
        if v and v ~= "" then return v end

        local short = fullType:gsub("^Base%.", "")
        v = getTextOrNull("ItemName_" .. short)
        if v and v ~= "" then return v end
    end

    if data.name        and data.name        ~= "" then return data.name        end
    if data.displayName and data.displayName ~= "" then return data.displayName end

    return fullType ~= "" and fullType or "?"
end

-- ============================================================
-- Rarity
-- ============================================================
local RARITY_FALLBACK = {
    Common    = "Common",
    Uncommon  = "Uncommon",
    Rare      = "Rare",
    Epic      = "Epic",
    Legendary = "Legendary",
}

local function resolveChipRarity(chip)
    if not chip then return nil end
    local data = chip.data or {}
    local r = data.rarity
    if r == nil or r == "" then return nil end

    if type(r) == "number" then return tostring(r) end

    if type(r) == "string" then
        if type(getTextOrNull) == "function" then
            local v = getTextOrNull("UI_MTSW_HUD_Rarity_" .. r)
            if v and v ~= "" then return v end
        end
        return RARITY_FALLBACK[r] or r
    end

    return nil
end

-- ============================================================
-- Список установленных тактических чипов
-- ============================================================
local function collectTacticalChips()
    local State = MT_SmartWatch.HUD.State
    local ChipSystem = MT_SmartWatch.ChipSystem
    local watch = State and State.watch

    if not watch or not ChipSystem then return {} end

    local installed = ChipSystem.getInstalledChips(watch) or {}
    local result = {}

    for i = 1, #installed do
        local fullType = installed[i]
        local data = ChipSystem.getChipDataByFullType(fullType)
        if data and data.category == "TacticalChip" then
            table.insert(result, {
                fullType = fullType,
                data     = data,
                texture  = getChipTexture({ fullType = fullType, data = data }),
            })
        end
    end

    return result
end

-- ============================================================
-- Drag Preview
-- ============================================================
local DragPreview = nil

local function ensureDragPreview()
    if DragPreview then return DragPreview end
    if not ISUIElement then return nil end

    local Preview = ISUIElement:derive("MT_SmartWatch_HUD_DragPreview")
    MT_SmartWatch.HUD.DragPreviewClass = Preview

    function Preview:new()
        local o = ISUIElement.new(self, -9999, -9999, 48, 48)
        setmetatable(o, self)
        self.__index = self
        o.tex     = nil
        o.visible = false
        o:setAlwaysOnTop(true)
        if o.javaObject then
            o.javaObject:setConsumeMouseEvents(false)
        end
        return o
    end

    function Preview:render()
        if not self.visible or not self.tex then return end
        local mx, my = getMouseX(), getMouseY()
        self:setX(mx - 24)
        self:setY(my - 24)
        self:drawTextureScaled(self.tex, 0, 0, 48, 48, 0.85, 1, 1, 1)
    end

    DragPreview = Preview:new()
    DragPreview:initialise()
    -- Добавляем ОДИН РАЗ навсегда. Больше не удаляем, только прячем.
    DragPreview:addToUIManager()
    DragPreview.visible = false
    MT_SmartWatch.HUD.dragPreview = DragPreview
    return DragPreview
end

local function showDragPreview(tex)
    local preview = ensureDragPreview()
    if not preview then return end
    preview.tex = tex
    preview.visible = true
end

local function hideDragPreview()
    if DragPreview then
        DragPreview.visible = false
        DragPreview.tex = nil
        DragPreview:setX(-9999)
        DragPreview:setY(-9999)
    end
end

local function updateDragPreviewPosition()
    -- no-op, превью двигается в render
end

MT_SmartWatch.HUD.showDragPreview           = showDragPreview
MT_SmartWatch.HUD.hideDragPreview           = hideDragPreview
MT_SmartWatch.HUD.updateDragPreviewPosition = updateDragPreviewPosition

-- ============================================================
-- Класс панели
-- ============================================================
local function buildTacticalClass()
    if MT_SmartWatch.HUD.Interface_TacticalChips then return end
    if not ISPanel then
        print("[MT Smart Watch - HUD] FATAL: ISPanel not available for Interface_TacticalChips")
        return
    end

    local Panel = ISPanel:derive("MT_SmartWatch_HUD_Interface_TacticalChips")
    MT_SmartWatch.HUD.Interface_TacticalChips = Panel

    local HEADER_H  = 26
    local PANEL_W   = 340
    local ROW_H     = 32
    local PAD       = 12
    local ICON_SIZE = 24

    function Panel:new(x, y, chips)
        local panelH = HEADER_H + PAD * 2 + math.max(#chips, 1) * ROW_H + 8
        local o = ISPanel:new(x, y, PANEL_W, panelH)
        setmetatable(o, self)
        self.__index = self

        o.chips           = chips
        o.moving          = false
        o.draggingChip    = nil
        o.dragStartX      = 0
        o.dragStartY      = 0
        o.draggingActive  = false
        o.backgroundColor = { r = 0.04, g = 0.04, b = 0.04, a = 0.95 }
        o.borderColor     = { r = 0.45, g = 0.45, b = 0.45, a = 1    }

        return o
    end

    function Panel:createChildren()
        ISPanel.createChildren(self)

        self.closeBtn = ISButton:new(self.width - 26, 3, 22, 20, "X",
            self, Panel.onClose)
        self.closeBtn:initialise()
        self.closeBtn.borderColor = { r = 1.0, g = 0.3, b = 0.3, a = 1 }
        self:addChild(self.closeBtn)
    end

    function Panel:onClose()
        hideDragPreview()
        self:close()
    end

    function Panel:close()
        hideDragPreview()
        self:setVisible(false)
        self:removeFromUIManager()
        if MT_SmartWatch.HUD.interfaceTacticalChipsPanel == self then
            MT_SmartWatch.HUD.interfaceTacticalChipsPanel = nil
        end
    end

    function Panel:getRowAt(x, y)
        if y <= HEADER_H + PAD then return nil end

        local top = HEADER_H + PAD
        local idx = math.floor((y - top) / ROW_H) + 1
        if idx >= 1 and idx <= #self.chips then
            return idx
        end
        return nil
    end

    function Panel:onMouseDown(x, y)
        if y <= HEADER_H then
            self.moving = true
            self:setCapture(true)
            return true
        end

        local rowIndex = self:getRowAt(x, y)
        if rowIndex then
            local chip = self.chips[rowIndex]
            self.draggingChip   = chip
            self.draggingActive = false
            self.dragStartX     = getMouseX()
            self.dragStartY     = getMouseY()
            self:setCapture(true)
            return true
        end

        return ISPanel.onMouseDown(self, x, y)
    end

    function Panel:updateChipDrag()
        if not self.draggingChip then return end

        local mx, my = getMouseX(), getMouseY()
        local dx = mx - self.dragStartX
        local dy = my - self.dragStartY
        local dist = math.sqrt(dx * dx + dy * dy)

        if not self.draggingActive and dist > 4 then
            self.draggingActive = true
            showDragPreview(self.draggingChip.texture)
        end
    end

    function Panel:onMouseMove(dx, dy)
        if self.moving then
            self:setX(self:getX() + dx)
            self:setY(self:getY() + dy)
            return true
        end
        if self.draggingChip then
            self:updateChipDrag()
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
        if self.draggingChip then
            self:updateChipDrag()
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

        if self.draggingChip then
            local chip = self.draggingChip
            local wasActive = self.draggingActive

            self.draggingChip = nil
            self.draggingActive = false
            self:setCapture(false)
            hideDragPreview()

            if wasActive then
                if MT_SmartWatch.HUD.handleChipDrop then
                    MT_SmartWatch.HUD.handleChipDrop(chip, getMouseX(), getMouseY())
                else
                    print("[MT Smart Watch - HUD] chip drop: " .. tostring(chip.fullType))
                end
            end
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

        if self.draggingChip then
            self.draggingChip = nil
            self.draggingActive = false
            self:setCapture(false)
            hideDragPreview()
            return true
        end

        return ISPanel.onMouseUpOutside(self, x, y)
    end

    function Panel:prerender()
        ISPanel.prerender(self)

        self:drawRect(0, 0, self.width, HEADER_H, 0.75, 0.12, 0.12, 0.12)
        self:drawRectBorder(0, 0, self.width, self.height,
            self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)

        local title = L("UI_MTSW_HUD_TacticalChips", "Tactical Chips")
        local tw = getTextManager():MeasureStringX(UIFont.Medium, title)
        self:drawText(title, (self.width - tw) / 2, 4, 1, 1, 1, 1, UIFont.Medium)
    end

    function Panel:render()
        ISPanel.render(self)

        local chips = self.chips or {}
        local y = HEADER_H + PAD

        if #chips == 0 then
            local text = L("UI_MTSW_HUD_NoChips", "No tactical chips installed")
            self:drawText(text, PAD, y + 4, 0.6, 0.6, 0.6, 1, UIFont.Small)
            return
        end

        for i = 1, #chips do
            local chip   = chips[i]
            local name   = resolveChipName(chip)
            local rarity = resolveChipRarity(chip)

            if chip.texture then
                self:drawTextureScaled(chip.texture,
                    PAD, y + math.floor((ROW_H - ICON_SIZE) / 2),
                    ICON_SIZE, ICON_SIZE, 1, 1, 1, 1)
            end

            local textX   = PAD + ICON_SIZE + 8
            local textY   = y + math.floor((ROW_H - 12) / 2)

            self:drawText(tostring(name), textX, textY,
                0.9, 0.9, 0.9, 1, UIFont.Small)

            if rarity then
                local rw    = getTextManager():MeasureStringX(UIFont.Small, rarity)
                local nameW = getTextManager():MeasureStringX(UIFont.Small, tostring(name))
                local rarityX = textX + nameW + 8
                if rarityX + rw > self.width - PAD then
                    rarityX = self.width - PAD - rw
                end
                self:drawText(rarity, rarityX, textY,
                    0.55, 0.65, 0.85, 1, UIFont.Small)
            end

            y = y + ROW_H
        end
    end

    print("[MT Smart Watch - HUD] Interface_TacticalChips class built")
end

-- ============================================================
-- Открытие
-- ============================================================
function MT_SmartWatch.HUD.openInterfaceTacticalChips(parentPanel)
    local existing = MT_SmartWatch.HUD.interfaceTacticalChipsPanel
    if existing then
        existing:close()
        return
    end

    local Panel = MT_SmartWatch.HUD.Interface_TacticalChips
    if not Panel then
        print("[MT Smart Watch - HUD] Interface_TacticalChips class not ready")
        return
    end

    local chips = collectTacticalChips()

    local px, py = 100, 100
    if parentPanel then
        px = parentPanel:getX() + parentPanel:getWidth() + 10
        py = parentPanel:getY()
    end

    local screenW = getCore():getScreenWidth()
    local panelW = 340
    if px + panelW > screenW - 10 then
        px = screenW - panelW - 10
    end
    if px < 10 then px = 10 end

    local panel = Panel:new(px, py, chips)
    panel:initialise()
    panel:createChildren()
    panel:addToUIManager()
    panel:setAlwaysOnTop(true)
    panel:bringToTop()

    MT_SmartWatch.HUD.interfaceTacticalChipsPanel = panel
end

if ISPanel then
    buildTacticalClass()
else
    Events.OnGameBoot.Add(buildTacticalClass)
end