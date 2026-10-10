-- HUD_Icon.lua
MT_SmartWatch = MT_SmartWatch or {}
MT_SmartWatch.HUD = MT_SmartWatch.HUD or {}

if MT_SmartWatch.HUD.Icon then return end

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

        o.texEmpty      = nil
        o.texOScore     = nil
        o.useOScoreIcon = false
        o.forceVisible  = false

        o.clickCallback = function()
            if MT_SmartWatch.HUD.openInterface then
                MT_SmartWatch.HUD.openInterface()
            end
        end

        return o
    end

    function Icon:initialise()
        ISUIElement.initialise(self)

        self.texEmpty = tryGetTexture({
            "media/UI/OnScreenSmartWatchHUD/OnScreenSmartWatchHUD_Empty.png",
            "UI/OnScreenSmartWatchHUD/OnScreenSmartWatchHUD_Empty.png",
        })

        self.texOScore = tryGetTexture({
            "media/UI/OnScreenSmartWatchHUD/OnScreenSmartWatchHUD_OScore.png",
            "UI/OnScreenSmartWatchHUD/OnScreenSmartWatchHUD_OScore.png",
        })
    end

    function Icon:setIconSize(size)
        self:setWidth(size)
        self:setHeight(size)
    end

    function Icon:render()
        if not self.visible then return end

        self:updateHover()
        self:updateFade()

        if self.alpha <= 0.01 then return end

        local tex = self.useOScoreIcon and self.texOScore or self.texEmpty
        if tex then
            self:drawTextureScaled(tex, 0, 0, self:getWidth(), self:getHeight(), self.alpha, 1, 1, 1)
        end
    end

    function Icon:onRightMouseUp(x, y)
        if not self.visible then return false end
        if x < 0 or y < 0 or x >= self:getWidth() or y >= self:getHeight() then
            return false
        end

        if MT_SmartWatch.HUD.openSettingsPanel then
            MT_SmartWatch.HUD.openSettingsPanel(self)
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