--------------------------------------------------
-- MT SMART WATCH
-- FUNCTIONAL CHIP REGISTER
--------------------------------------------------

MT_SmartWatch = MT_SmartWatch or {}

MT_SmartWatch.FunctionalChipRegister =
    MT_SmartWatch.FunctionalChipRegister or {}

local Register =
    MT_SmartWatch.FunctionalChipRegister


--------------------------------------------------
-- FUNCTIONAL CHIP DATA
--------------------------------------------------

Register.Data = {


    --------------------------------------------------
    -- STAMINA HUD
    --------------------------------------------------

    ["Base.MTSW_FChip_StaminaHUD"] = {

        id =
            "StaminaHUD",

        category =
            "FunctionalChip",

        tier =
            1,

        memoryCost =
            1,

        --------------------------------------------------
        -- BATTERY DRAIN
        -- DRAIN PER GAME MINUTE
        --------------------------------------------------

        batteryDrainPerMinute =
            0.10,

        batteryDrainMode =
            "installed",

    },


    --------------------------------------------------
    -- TIME HUD
    --------------------------------------------------

    ["Base.MTSW_FChip_Time"] = {

        id =
            "Time",

        category =
            "FunctionalChip",

        tier =
            1,

        memoryCost =
            1,

        --------------------------------------------------
        -- BATTERY DRAIN
        -- DRAIN PER GAME MINUTE
        --------------------------------------------------

        batteryDrainPerMinute =
            0.05,

        batteryDrainMode =
            "installed",

    },

}