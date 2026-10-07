--------------------------------------------------
-- MT SMART WATCH
-- TACTICAL CHIP REGISTER
--------------------------------------------------

MT_SmartWatch = MT_SmartWatch or {}

MT_SmartWatch.TacticalChipRegister =
    MT_SmartWatch.TacticalChipRegister or {}

local Register =
    MT_SmartWatch.TacticalChipRegister


--------------------------------------------------
-- OFFICIAL TACTICAL CHIP DATA
--------------------------------------------------

Register.Data = {

    ["Base.MTSW_TChip_EMP"] = {

        id = "EMP",
        category = "TacticalChip",

        tier = 1,
        memoryCost = 8,

        batteryCost = 1,
        cooldown = 30,

        radius = 15,
        durationMinutes = 30,

    },

}


print(
    "[MT Smart Watch] "
    .. "TacticalChipRegister loaded"
)
