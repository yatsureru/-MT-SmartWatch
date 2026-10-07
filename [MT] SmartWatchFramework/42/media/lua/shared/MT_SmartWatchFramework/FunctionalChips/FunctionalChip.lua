MT_SmartWatch = MT_SmartWatch or {}

MT_SmartWatch.FunctionalChip =
    MT_SmartWatch.FunctionalChip or {}

local FunctionalChip =
    MT_SmartWatch.FunctionalChip


--------------------------------------------------
-- GET REGISTER
--------------------------------------------------

local function getRegister()

    if not MT_SmartWatch.FunctionalChipRegister then

        print(
            "[MT Smart Watch] FunctionalChip ERROR: "
            .. "Register not loaded"
        )

        return nil

    end


    if not MT_SmartWatch.FunctionalChipRegister.Data then

        print(
            "[MT Smart Watch] FunctionalChip ERROR: "
            .. "Register.Data not found"
        )

        return nil

    end


    return MT_SmartWatch.FunctionalChipRegister.Data

end


--------------------------------------------------
-- GET FULL TYPE
--------------------------------------------------

function FunctionalChip.getFullType(chip)

    if not chip then
        return nil
    end


    if type(chip) == "string" then

        return chip

    end


    if chip.getFullType then

        return chip:getFullType()

    end


    return nil

end


--------------------------------------------------
-- GET DATA
--------------------------------------------------

function FunctionalChip.getData(chip)

    local fullType =
        FunctionalChip.getFullType(chip)


    if not fullType then
        return nil
    end


    local data =
        getRegister()


    if not data then
        return nil
    end


    return data[fullType]

end


--------------------------------------------------
-- CHECK CHIP
--------------------------------------------------

function FunctionalChip.isChip(chip)

    return
        FunctionalChip.getData(chip) ~= nil

end


--------------------------------------------------
-- GET ID
--------------------------------------------------

function FunctionalChip.getID(chip)

    local data =
        FunctionalChip.getData(chip)


    if not data then
        return nil
    end


    return data.id

end


--------------------------------------------------
-- GET CATEGORY
--------------------------------------------------

function FunctionalChip.getCategory(chip)

    local data =
        FunctionalChip.getData(chip)


    if not data then
        return nil
    end


    return data.category

end


--------------------------------------------------
-- GET TIER
--------------------------------------------------

function FunctionalChip.getTier(chip)

    local data =
        FunctionalChip.getData(chip)


    if not data then
        return 0
    end


    return data.tier or 0

end


--------------------------------------------------
-- GET MEMORY COST
--------------------------------------------------

function FunctionalChip.getMemoryCost(chip)

    local data =
        FunctionalChip.getData(chip)


    if not data then
        return 0
    end


    return data.memoryCost or 0

end


--------------------------------------------------
-- GET INFO
--------------------------------------------------

function FunctionalChip.getInfo(chip)

    local data =
        FunctionalChip.getData(chip)


    if not data then
        return nil
    end


    return {

        id = data.id,

        category = data.category,

        tier = data.tier,

        memoryCost = data.memoryCost,
    }

end