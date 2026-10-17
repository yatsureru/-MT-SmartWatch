-- HUD_Battery.lua
MT_SmartWatch = MT_SmartWatch or {}
MT_SmartWatch.HUD = MT_SmartWatch.HUD or {}

if MT_SmartWatch.HUD.Battery then return end

-- ============================================================
-- TIERS
-- ============================================================
local TIERS = {
    { min = 75, suffix = "100" },
    { min = 50, suffix = "75"  },
    { min = 25, suffix = "50"  },
    { min = 5,  suffix = "25"  },
    { min = -1, suffix = "5"   },
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

local function getSuffix(percent)
    for _, tier in ipairs(TIERS) do
        if percent >= tier.min then return tier.suffix end
    end
    return TIERS[#TIERS].suffix
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
--- @param textureAlpha number? — override для _Battery_5 (пульс)
function Battery.render(icon, baseAlpha, textureAlpha)
    local State = MT_SmartWatch.HUD.State
    if not State then return end
    local percent = State.batteryPercent
    if percent == nil then return end

    -- Кэш: пересчёт тира только при смене целого %
    local intPercent = math.floor(percent + 0.5)
    local cache = icon._batCache
    if not cache then
        cache = {}
        icon._batCache = cache
        ensureTextures()
    end

    if cache.intPercent ~= intPercent then
        cache.intPercent = intPercent
        cache.tex        = TEXTURES[getSuffix(percent)]
    end

    if not cache.tex then return end

    local size     = icon:getWidth()
    local texAlpha = textureAlpha or baseAlpha

    icon:drawTextureScaled(cache.tex, 0, 0, size, size, texAlpha, 1, 1, 1)
end

MT_SmartWatch.HUD.Battery = Battery

if type(getTexture) == "function" then
    ensureTextures()
end

print("[MT Smart Watch - HUD] Battery module loaded")