--------------------------------------------------
-- MT SMART WATCH
-- APP CHIP SYSTEM
--------------------------------------------------

MT_SmartWatch = MT_SmartWatch or {}

MT_SmartWatch.AppChip =
    MT_SmartWatch.AppChip or {}

local AppChip =
    MT_SmartWatch.AppChip


--------------------------------------------------
-- GET REGISTER
--------------------------------------------------

local function getRegister()

    if not MT_SmartWatch.AppChipRegister then
        return nil
    end

    if not MT_SmartWatch.AppChipRegister.Data then
        return nil
    end

    return
        MT_SmartWatch.AppChipRegister.Data

end


--------------------------------------------------
-- GET FULL TYPE
--------------------------------------------------

function AppChip.getFullType(
    chip
)

    if not chip then
        return nil
    end

    if not chip.getFullType then
        return nil
    end

    return
        chip:getFullType()

end


--------------------------------------------------
-- GET DATA
--------------------------------------------------

function AppChip.getData(
    chip
)

    if not chip then
        return nil
    end

    local fullType =
        AppChip.getFullType(
            chip
        )

    if not fullType then
        return nil
    end

    local register =
        getRegister()

    if not register then
        return nil
    end

    return
        register[fullType]

end


--------------------------------------------------
-- IS APP CHIP
--------------------------------------------------

function AppChip.isChip(
    chip
)

    return
        AppChip.getData(
            chip
        ) ~= nil

end


--------------------------------------------------
-- GET ID
--------------------------------------------------

function AppChip.getID(
    chip
)

    local data =
        AppChip.getData(
            chip
        )

    if not data then
        return nil
    end

    return
        data.id

end


--------------------------------------------------
-- GET CATEGORY
--------------------------------------------------

function AppChip.getCategory(
    chip
)

    local data =
        AppChip.getData(
            chip
        )

    if not data then
        return nil
    end

    return
        data.category

end


--------------------------------------------------
-- GET TIER
--------------------------------------------------

function AppChip.getTier(
    chip
)

    local data =
        AppChip.getData(
            chip
        )

    if not data then
        return 0
    end

    return
        data.tier
        or 0

end


--------------------------------------------------
-- GET MEMORY COST
--------------------------------------------------

function AppChip.getMemoryCost(
    chip
)

    local data =
        AppChip.getData(
            chip
        )

    if not data then
        return 0
    end

    return
        data.memoryCost
        or 0

end


--------------------------------------------------
-- GET INFO
--------------------------------------------------

function AppChip.getInfo(
    chip
)

    local data =
        AppChip.getData(
            chip
    )

    if not data then
        return nil
    end

    return {

        fullType =
            AppChip.getFullType(
                chip
            ),

        id =
            data.id,

        category =
            data.category,

        tier =
            data.tier,

        memoryCost =
            data.memoryCost,

    }

end