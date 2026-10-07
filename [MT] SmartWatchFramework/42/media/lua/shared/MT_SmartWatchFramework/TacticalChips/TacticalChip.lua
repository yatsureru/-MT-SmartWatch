--------------------------------------------------
-- MT SMART WATCH
-- TACTICAL CHIP
--------------------------------------------------

MT_SmartWatch = MT_SmartWatch or {}

MT_SmartWatch.TacticalChip =
    MT_SmartWatch.TacticalChip or {}

local TacticalChip =
    MT_SmartWatch.TacticalChip


--------------------------------------------------
-- GET REGISTER
--------------------------------------------------

local function getRegister()

    if not MT_SmartWatch.TacticalChipRegister then

        print(
            "[MT Smart Watch] TacticalChip ERROR: "
            .. "TacticalChipRegister not found"
        )

        return nil

    end


    if not MT_SmartWatch.TacticalChipRegister.Data then

        print(
            "[MT Smart Watch] TacticalChip ERROR: "
            .. "TacticalChipRegister.Data not found"
        )

        return nil

    end


    return
        MT_SmartWatch.TacticalChipRegister.Data

end


--------------------------------------------------
-- GET FULL TYPE
--------------------------------------------------

function TacticalChip.getFullType(chip)

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

function TacticalChip.getData(chip)

    if not chip then
        return nil
    end


    local fullType =
        TacticalChip.getFullType(
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
-- IS TACTICAL CHIP
--------------------------------------------------

function TacticalChip.isTacticalChip(chip)

    return
        TacticalChip.getData(
            chip
        )
        ~= nil

end


print(
    "[MT Smart Watch] "
    .. "TacticalChip loaded"
)