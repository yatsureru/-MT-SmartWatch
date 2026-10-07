MT_SmartWatch = MT_SmartWatch or {}

MT_SmartWatch.OSCoreRegister =
    MT_SmartWatch.OSCoreRegister or {}

local Register =
    MT_SmartWatch.OSCoreRegister


--------------------------------------------------
-- OFFICIAL OS CORE DATA
--------------------------------------------------

Register.Data = {

    ["Base.MTSW_Core_Logic"] = {

        id = "Logic",
        rarity = "I",
        batteryCapacity = 100,
        memory = 64,
        memoryCost = 12,
        minChipTier = 1,
        tacticalSlots = 1,
        maxChipTier = 2,

    },

    ["Base.MTSW_Core_Tactical"] = {

        id = "Tactical",
        rarity = "II",
        batteryCapacity = 150,
        memory = 76,
        memoryCost = 12,
        minChipTier = 1,
        tacticalSlots = 2,
        maxChipTier = 3,

    },

    ["Base.MTSW_Core_Quantum"] = {

        id = "Quantum",
        rarity = "III",
        batteryCapacity = 225,
        memory = 92,
        memoryCost = 12,
        minChipTier = 1,
        tacticalSlots = 3,
        maxChipTier = 4,

    },

    ["Base.MTSW_Core_BlackBox"] = {

        id = "BlackBox",
        rarity = "IV",
        batteryCapacity = 350,
        memory = 110,
        memoryCost = 12,
        minChipTier = 1,
        tacticalSlots = 4,
        maxChipTier = 5,

    },

    ["Base.MTSW_Core_042"] = {

        id = "042",
        rarity = "V",
        batteryCapacity = 500,
        memory = 128,
        memoryCost = 12,
        minChipTier = 1,
        tacticalSlots = 5,
        maxChipTier = 5,

    },

}