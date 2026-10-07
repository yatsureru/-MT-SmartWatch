--------------------------------------------------
-- MT SMART WATCH
-- APP CHIP REGISTER
--------------------------------------------------

MT_SmartWatch = MT_SmartWatch or {}

MT_SmartWatch.AppChipRegister =
    MT_SmartWatch.AppChipRegister or {}

local Register =
    MT_SmartWatch.AppChipRegister


--------------------------------------------------
-- APP CHIP DATA
--------------------------------------------------

Register.Data = {


    --------------------------------------------------
    -- RADIO
    --------------------------------------------------

    ["Base.MTSW_AChip_Radio"] = {

        id =
            "Radio",

        category =
            "AppChip",

        tier =
            1,

        memoryCost =
            3,

        --------------------------------------------------
        -- BATTERY DRAIN
        -- ONLY WHILE APP IS ACTIVE
        --------------------------------------------------

        batteryDrainPerMinute =
            0.25,

        batteryDrainMode =
            "active",

    },

}