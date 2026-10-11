-- HUD_Battery.lua
MT_SmartWatch = MT_SmartWatch or {}
MT_SmartWatch.HUD = MT_SmartWatch.HUD or {}

if MT_SmartWatch.HUD.Battery then return end

-- ============================================================
-- LAYOUT
-- ============================================================
local NATIVE_SIZE   = 256
local TEXT_OFFSET_X = 75
local TEXT_FONT     = UIFont.Small

-- ============================================================
-- TIERS
-- ============================================================
local TIERS = {
    { min = 75, suffix = "100", r = 0.55, g = 0.95, b = 0.55 },
    { min = 50, suffix = "75",  r = 0.95, g = 0.90, b = 0.35 },
    { min = 25, suffix = "50",  r = 0.95, g = 0.70, b = 0.30 },
    { min = 5,  suffix = "25",  r = 0.95, g = 0.55, b = 0.20 },
    { min = -1, suffix = "5",   r = 0.95, g = 0.25, b = 0.25 },
}

local CRITICAL_THRESHOLD = 5

-- ============================================================
-- Текстуры
-- ============================================================
local TEXTURES = {}

local function loadTex(suffix)
    local paths = {
        "media/UI/OnScreenSmartWatchHUD/OnScreenSmartWatchHUD_Battery_" .. suffix .. ".png",
        "UI/OnScreenSmartWatchHUD/OnScreenSmartWatchHUD_Battery_" .. suffix .. ".png",
    }
    for _, p in ipairs(paths) do
        local tex = getTexture(p)
        if tex then
            print("[MT Smart Watch - HUD] battery texture OK: " .. p)
            return tex
        end
    end
    print("[MT Smart Watch - HUD] battery texture NOT FOUND: suffix=" .. suffix)
    return nil
end

local function ensureTextures()
    for _, tier in ipairs(TIERS) do
        if not TEXTURES[tier.suffix] then
            TEXTURES[tier.suffix] = loadTex(tier.suffix)
        end
    end
end

local function getTier(percent)
    for _, tier in ipairs(TIERS) do
        if percent >= tier.min then return tier end
    end
    return TIERS[#TIERS]
end

-- ============================================================
-- Public
-- ============================================================
local Battery = {}

function Battery.isCritical(percent)
    return percent ~= nil and percent < CRITICAL_THRESHOLD
end

--- @param icon         MT_SmartWatch_HUD_Icon
--- @param baseAlpha    number
--- @param textureAlpha number? — override для _Battery_5
function Battery.render(icon, baseAlpha, textureAlpha)
    local State = MT_SmartWatch.HUD.State
    if not State then return end
    local percent = State.batteryPercent
    if percent == nil then return end

    -- === Кэш: пропускаем работу, если ничего не изменилось ===
    local intPercent = math.floor(percent + 0.5)
    local cache = icon._batCache
    if not cache then
        cache = {}
        icon._batCache = cache
        ensureTextures()
    end

    -- Пересчёт текста/ширины/тика — только при смене целого %
    if cache.intPercent ~= intPercent then
        cache.intPercent = intPercent
        cache.text       = string.format("%d%%", intPercent)
        cache.textW      = getTextManager():MeasureStringX(TEXT_FONT, cache.text)
        cache.textH      = getTextManager():getFontHeight(TEXT_FONT)
        cache.tier       = getTier(percent)
        cache.tex        = TEXTURES[cache.tier.suffix]
    end

    if not cache.tex then return end

    local size  = icon:getWidth()
    local scale = size / NATIVE_SIZE
    local texAlpha = textureAlpha or baseAlpha

    -- Батарейка
    icon:drawTextureScaled(cache.tex, 0, 0, size, size, texAlpha, 1, 1, 1)

    -- Текст (с кэшированными размерами)
    local cx = size / 2
    local cy = size / 2
    local tx = cx + TEXT_OFFSET_X * scale
    local ty = cy - cache.textH / 2

    icon:drawText(cache.text, tx, ty,
        cache.tier.r, cache.tier.g, cache.tier.b, baseAlpha, TEXT_FONT)
end

MT_SmartWatch.HUD.Battery = Battery

if type(getTexture) == "function" then
    ensureTextures()
end

print("[MT Smart Watch - HUD] Battery module loaded")