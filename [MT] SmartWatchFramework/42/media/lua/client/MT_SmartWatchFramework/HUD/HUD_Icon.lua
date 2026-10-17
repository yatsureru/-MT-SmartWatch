-- HUD_Icon.lua
MT_SmartWatch = MT_SmartWatch or {}
MT_SmartWatch.HUD = MT_SmartWatch.HUD or {}

if MT_SmartWatch.HUD.Icon then return end

-- ============================================================
-- Скорости вращения (секунд на один полный оборот)
-- ============================================================
local CIRCLE_SPEED_SEC = {
    [1] = 0,    -- Never (static)
    [2] = 64,   -- Slow
    [3] = 32,   -- Medium
    [4] = 16,   -- Fast
}

-- ============================================================
-- Pulse при <5%
-- ============================================================
local PULSE_PERIOD    = 0.89
local PULSE_MIN_ALPHA = 0.05

-- ============================================================
-- Время
-- ============================================================
local function getNowMs()
    if type(getTimestampMs) == "function" then return getTimestampMs() end
    if type(getTimeInMillis) == "function" then return getTimeInMillis() end
    if type(getTimestamp) == "function" then return getTimestamp() * 1000 end
    return 0
end

local function tryGetTexture(paths)
    for _, p in ipairs(paths) do
        local tex = getTexture(p)
        if tex then
            print("[MT Smart Watch - HUD] texture OK: " .. p)
            return tex
        end
    end
    print("[MT Smart Watch - HUD] texture NOT FOUND, tried: " .. table.concat(paths, ", "))
    return nil
end

-- ============================================================
-- Построение класса
-- ============================================================
local function buildIconClass()
    if MT_SmartWatch.HUD.Icon then return end

    local Base = MT_SmartWatch.HUD.Base
    if not Base then
        print("[MT Smart Watch - HUD] FATAL: Base class not available, cannot build Icon")
        return
    end

    local Icon = Base:derive("MT_SmartWatch_HUD_Icon")
    MT_SmartWatch.HUD.Icon = Icon

    function Icon:new(x, y)
        local size = (MT_SmartWatch.HUD.Settings and MT_SmartWatch.HUD.Settings.iconSize) or 128
        local o = Base.new(self, x, y, size, size, "icon")
        setmetatable(o, self)
        self.__index = self

        o.texBase       = nil
        o.texCircles    = {}    -- [256]=tex, [128]=tex, [64]=tex
        o.hasOSCore     = false
        o.showBattery   = true
        o.forceVisible  = false

        o.circleAngle       = 0
        o.pulsePhase        = 0
        o.batteryPulseAlpha = nil
        o._animLastMs       = nil

        o.clickCallback = function()
            if MT_SmartWatch.HUD.openInterface then
                MT_SmartWatch.HUD.openInterface()
            end
        end

        return o
    end

    function Icon:initialise()
        ISUIElement.initialise(self)

        self.texBase = tryGetTexture({
            "media/UI/OnScreenSmartWatchHUD/OnScreenSmartWatchHUD.png",
            "UI/OnScreenSmartWatchHUD/OnScreenSmartWatchHUD.png",
        })

        -- Три текстуры кольца под размеры 256 / 128 / 64
        self.texCircles[256] = tryGetTexture({
            "media/UI/OnScreenSmartWatchHUD/OnScreenSmartWatchHUD_Circle.png",
            "UI/OnScreenSmartWatchHUD/OnScreenSmartWatchHUD_Circle.png",
        })
        self.texCircles[128] = tryGetTexture({
            "media/UI/OnScreenSmartWatchHUD/OnScreenSmartWatchHUD_Circle_128.png",
            "UI/OnScreenSmartWatchHUD/OnScreenSmartWatchHUD_Circle_128.png",
        })
        self.texCircles[64] = tryGetTexture({
            "media/UI/OnScreenSmartWatchHUD/OnScreenSmartWatchHUD_Circle_64.png",
            "UI/OnScreenSmartWatchHUD/OnScreenSmartWatchHUD_Circle_64.png",
        })
    end

    function Icon:setIconSize(size)
        self:setWidth(size)
        self:setHeight(size)
    end

    -- ========================================================
    -- Delta-time
    -- ========================================================
    function Icon:getAnimDt()
        local nowMs = getNowMs()
        local dt = 0.016
        if self._animLastMs and nowMs > 0 then
            dt = (nowMs - self._animLastMs) / 1000
            if dt < 0 then dt = 0 end
            if dt > 0.25 then dt = 0.016 end
        end
        self._animLastMs = nowMs
        return dt
    end

    -- ========================================================
    -- Circle rotation (в градусах)
    -- ========================================================
    function Icon:updateCircle(dt)
        local S = MT_SmartWatch.HUD.Settings
        local speedIdx = (S and S.circleSpeed) or 3
        local dirIdx   = (S and S.circleDirection) or 2

        if speedIdx == 1 then
            self.circleAngle = 0
            return
        end

        local secondsPerRev = CIRCLE_SPEED_SEC[speedIdx] or 32
        local dirMult = (dirIdx == 1) and -1 or 1

        local degPerSec = 360 / secondsPerRev
        self.circleAngle = (self.circleAngle + degPerSec * dirMult * dt) % 360
    end

    -- ========================================================
    -- Alpha (fade + pulse для <5%)
    -- ========================================================
    function Icon:updateAlpha(dt)
        local State = MT_SmartWatch.HUD.State
        local Battery = MT_SmartWatch.HUD.Battery
        local critical = Battery and State and Battery.isCritical(State.batteryPercent)

        if critical then
            self.hoverTimer = 0
            self._lastMs = nil
            self.alpha = 1

            self.pulsePhase = (self.pulsePhase or 0)
                + dt * (2 * math.pi / PULSE_PERIOD)
            local wave = 0.5 + 0.5 * math.sin(self.pulsePhase)
            self.batteryPulseAlpha = PULSE_MIN_ALPHA
                + (1 - PULSE_MIN_ALPHA) * wave
        else
            self.pulsePhase = 0
            self.batteryPulseAlpha = nil
            self:updateFade()
        end
    end

    -- ========================================================
    -- Draw circle
    -- ========================================================
    function Icon:drawCircle(w, h)
        local size = self:getWidth()
        local tex  = self.texCircles[size] or self.texCircles[256]
        if not tex then return end

        local angleDeg = self.circleAngle
        local j        = self.javaObject

        -- Единственный рабочий API в B42.21 (градусы, native size, anchor = центр)
        if j and type(j.DrawTextureAngle) == "function" then
            local ok = pcall(function()
                j:DrawTextureAngle(tex, w / 2, h / 2, angleDeg)
            end)
            if ok then return end
        end

        -- Последний fallback: без вращения
        self:drawTextureScaled(tex, 0, 0, w, h, self.alpha, 1, 1, 1)
    end

    -- ========================================================
    -- Render
    -- ========================================================
    function Icon:render()
        if not self.visible then return end

        local dt = self:getAnimDt()

        self:updateHover()
        self:updateAlpha(dt)
        self:updateCircle(dt)

        if self.alpha <= 0.01 then return end

        local w = self:getWidth()
        local h = self:getHeight()

        -- 1. Базовая иконка часов
        if self.texBase then
            self:drawTextureScaled(self.texBase, 0, 0, w, h, self.alpha, 1, 1, 1)
        end

        -- 2. Circle
        if self.hasOSCore then
            self:drawCircle(w, h)
        end

        -- 3. Батарейка + текст %
        if self.hasOSCore and self.showBattery and MT_SmartWatch.HUD.Battery then
            MT_SmartWatch.HUD.Battery.render(self, self.alpha, self.batteryPulseAlpha)
        end
    end

    -- ========================================================
    -- ПКМ
    -- ========================================================
    function Icon:onRightMouseUp(x, y)
        if not self.visible then return false end
        if x < 0 or y < 0 or x >= self:getWidth() or y >= self:getHeight() then
            return false
        end
        if MT_SmartWatch.HUD.openSettingsPanel_WatchOnScreen then
            MT_SmartWatch.HUD.openSettingsPanel_WatchOnScreen(self)
        end
        return true
    end

    print("[MT Smart Watch - HUD] Icon loaded")
end

if MT_SmartWatch.HUD.Base then
    buildIconClass()
else
    Events.OnGameBoot.Add(buildIconClass)
end