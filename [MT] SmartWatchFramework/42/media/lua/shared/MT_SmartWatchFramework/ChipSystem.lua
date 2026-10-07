--------------------------------------------------
-- MT SMART WATCH
-- CHIP SYSTEM
--------------------------------------------------

MT_SmartWatch = MT_SmartWatch or {}

MT_SmartWatch.ChipSystem =
    MT_SmartWatch.ChipSystem or {}

local ChipSystem =
    MT_SmartWatch.ChipSystem


--------------------------------------------------
-- GET WATCH DATA
--------------------------------------------------

local function getWatchData(
    watch
)

    if not watch then
        return nil
    end


    local modData =
        watch:getModData()


    if not modData then
        return nil
    end


    modData.MT_SmartWatch =
        modData.MT_SmartWatch
        or {}


    return
        modData.MT_SmartWatch

end


--------------------------------------------------
-- GET INSTALLED CHIPS
--------------------------------------------------

function ChipSystem.getInstalledChips(
    watch
)

    local watchData =
        getWatchData(
            watch
        )


    if not watchData then
        return {}
    end


    watchData.chips =
        watchData.chips
        or {}


    return
        watchData.chips

end


--------------------------------------------------
-- GET ACTIVE CHIPS
--------------------------------------------------

function ChipSystem.getActiveChips(
    watch
)

    local watchData =
        getWatchData(
            watch
        )


    if not watchData then
        return {}
    end


    watchData.activeChips =
        watchData.activeChips
        or {}


    return
        watchData.activeChips

end


--------------------------------------------------
-- SET CHIP ACTIVE
--------------------------------------------------

function ChipSystem.setChipActive(
    watch,
    fullType,
    active
)

    if not watch then
        return false
    end


    if not fullType then
        return false
    end


    if not ChipSystem.hasChip(
        watch,
        fullType
    ) then

        return false

    end


    local activeChips =
        ChipSystem.getActiveChips(
            watch
        )


    if active then

        activeChips[fullType] =
            true

    else

        activeChips[fullType] =
            nil

    end


    return true

end


--------------------------------------------------
-- IS CHIP ACTIVE
--------------------------------------------------

function ChipSystem.isChipActive(
    watch,
    fullType
)

    local activeChips =
        ChipSystem.getActiveChips(
            watch
        )


    return
        activeChips[fullType]
        == true

end


--------------------------------------------------
-- CLEAR ACTIVE STATES
--------------------------------------------------

function ChipSystem.clearActiveChips(
    watch
)

    local watchData =
        getWatchData(
            watch
        )


    if not watchData then
        return false
    end


    watchData.activeChips =
        {}


    return true

end


--------------------------------------------------
-- GET INSTALLED CORE DATA
--------------------------------------------------

local function getInstalledCoreData(
    watch
)

    local OSCore =
        MT_SmartWatch.OSCore


    if not OSCore then
        return nil
    end


    if not OSCore.getInstalledData then
        return nil
    end


    return
        OSCore.getInstalledData(
            watch
        )

end


--------------------------------------------------
-- GET CHIP DATA
--------------------------------------------------

function ChipSystem.getChipData(
    chip
)

    if not chip then
        return nil
    end


    --------------------------------------------------
    -- FUNCTIONAL CHIP
    --------------------------------------------------

    local FunctionalChip =
        MT_SmartWatch.FunctionalChip


    if FunctionalChip
        and FunctionalChip.getData then

        local data =
            FunctionalChip.getData(
                chip
            )


        if data then
            return data
        end

    end


    --------------------------------------------------
    -- TACTICAL CHIP
    --------------------------------------------------

    local TacticalChip =
        MT_SmartWatch.TacticalChip


    if TacticalChip
        and TacticalChip.getData then

        local data =
            TacticalChip.getData(
                chip
            )


        if data then
            return data
        end

    end


    --------------------------------------------------
    -- APP CHIP
    --------------------------------------------------

    local AppChip =
        MT_SmartWatch.AppChip


    if AppChip
        and AppChip.getData then

        local data =
            AppChip.getData(
                chip
            )


        if data then
            return data
        end

    end


    return nil

end


--------------------------------------------------
-- GET CHIP DATA BY FULL TYPE
--------------------------------------------------

function ChipSystem.getChipDataByFullType(
    fullType
)

    if not fullType then
        return nil
    end


    --------------------------------------------------
    -- FUNCTIONAL
    --------------------------------------------------

    local FunctionalRegister =
        MT_SmartWatch.FunctionalChipRegister


    if FunctionalRegister
        and FunctionalRegister.Data then

        local data =
            FunctionalRegister.Data[
                fullType
            ]


        if data then
            return data
        end

    end


    --------------------------------------------------
    -- TACTICAL
    --------------------------------------------------

    local TacticalRegister =
        MT_SmartWatch.TacticalChipRegister


    if TacticalRegister
        and TacticalRegister.Data then

        local data =
            TacticalRegister.Data[
                fullType
            ]


        if data then
            return data
        end

    end


    --------------------------------------------------
    -- APP
    --------------------------------------------------

    local AppRegister =
        MT_SmartWatch.AppChipRegister


    if AppRegister
        and AppRegister.Data then

        local data =
            AppRegister.Data[
                fullType
            ]


        if data then
            return data
        end

    end


    return nil

end


--------------------------------------------------
-- GET MAX MEMORY
--------------------------------------------------

function ChipSystem.getMaxMemory(
    watch
)

    local coreData =
        getInstalledCoreData(
            watch
        )


    if not coreData then
        return 0
    end


    return
        coreData.memory
        or 0

end


--------------------------------------------------
-- GET CORE MEMORY COST
--------------------------------------------------

function ChipSystem.getCoreSize(
    watch
)

    local coreData =
        getInstalledCoreData(
            watch
        )


    if not coreData then
        return 0
    end


    return
        coreData.memoryCost
        or 0

end


--------------------------------------------------
-- GET USED MEMORY
--------------------------------------------------

function ChipSystem.getUsedMemory(
    watch
)

    local coreData =
        getInstalledCoreData(
            watch
        )


    if not coreData then
        return 0
    end


    local usedMemory =
        coreData.memoryCost
        or 0


    local chips =
        ChipSystem.getInstalledChips(
            watch
        )


    for i = 1, #chips do

        local fullType =
            chips[i]


        local data =
            ChipSystem.getChipDataByFullType(
                fullType
            )


        if data then

            usedMemory =
                usedMemory
                + (
                    data.memoryCost
                    or 0
                )

        end

    end


    return
        usedMemory

end


--------------------------------------------------
-- GET FREE MEMORY
--------------------------------------------------

function ChipSystem.getFreeMemory(
    watch
)

    local maxMemory =
        ChipSystem.getMaxMemory(
            watch
        )


    local usedMemory =
        ChipSystem.getUsedMemory(
            watch
        )


    return
        math.max(
            0,
            maxMemory - usedMemory
        )

end


--------------------------------------------------
-- GET TACTICAL SLOTS
--------------------------------------------------

function ChipSystem.getTacticalSlots(
    watch
)

    local coreData =
        getInstalledCoreData(
            watch
        )


    if not coreData then
        return 0
    end


    return
        coreData.tacticalSlots
        or 0

end


--------------------------------------------------
-- GET INSTALLED TACTICAL CHIP COUNT
--------------------------------------------------

function ChipSystem.getTacticalChipCount(
    watch
)

    local chips =
        ChipSystem.getInstalledChips(
            watch
        )


    local count =
        0


    for i = 1, #chips do

        local fullType =
            chips[i]


        local data =
            ChipSystem.getChipDataByFullType(
                fullType
            )


        if data
            and data.category
            == "TacticalChip" then

            count =
                count + 1

        end

    end


    return
        count

end


--------------------------------------------------
-- GET FREE TACTICAL SLOTS
--------------------------------------------------

function ChipSystem.getFreeTacticalSlots(
    watch
)

    local maxSlots =
        ChipSystem.getTacticalSlots(
            watch
        )


    local usedSlots =
        ChipSystem.getTacticalChipCount(
            watch
        )


    return
        math.max(
            0,
            maxSlots - usedSlots
        )

end


--------------------------------------------------
-- HAS FREE TACTICAL SLOT
--------------------------------------------------

function ChipSystem.hasFreeTacticalSlot(
    watch
)

    return
        ChipSystem.getFreeTacticalSlots(
            watch
        )
        > 0

end


--------------------------------------------------
-- GET OS LEVEL
--------------------------------------------------

function ChipSystem.getOSLevel(
    watch
)

    local watchData =
        getWatchData(
            watch
        )


    if not watchData then
        return 0
    end


    return
        watchData.osLevel
        or 0

end


--------------------------------------------------
-- SET OS LEVEL
--------------------------------------------------

function ChipSystem.setOSLevel(
    watch,
    level
)

    local watchData =
        getWatchData(
            watch
        )


    if not watchData then
        return false
    end


    level =
        math.floor(
            tonumber(level)
            or 0
        )


    level =
        math.max(
            0,
            math.min(
                level,
                10
            )
        )


    watchData.osLevel =
        level


    return true

end


--------------------------------------------------
-- INITIALIZE
--------------------------------------------------

function ChipSystem.initialize(
    watch
)

    local watchData =
        getWatchData(
            watch
        )


    if not watchData then
        return false
    end


    if watchData.osLevel == nil then

        watchData.osLevel =
            0

    end


    if watchData.chips == nil then

        watchData.chips =
            {}

    end


    if watchData.activeChips == nil then

        watchData.activeChips =
            {}

    end


    return true

end


--------------------------------------------------
-- HAS CHIP
--------------------------------------------------

function ChipSystem.hasChip(
    watch,
    fullType
)

    if not watch then
        return false
    end


    if not fullType then
        return false
    end


    local chips =
        ChipSystem.getInstalledChips(
            watch
        )


    for i = 1, #chips do

        if chips[i] == fullType then

            return true

        end

    end


    return false

end


--------------------------------------------------
-- HAS FREE MEMORY
--------------------------------------------------

function ChipSystem.hasFreeMemory(
    watch,
    requiredMemory
)

    requiredMemory =
        tonumber(
            requiredMemory
        )
        or 0


    return
        ChipSystem.getFreeMemory(
            watch
        )
        >= requiredMemory

end


--------------------------------------------------
-- INSTALL CHIP
--------------------------------------------------

function ChipSystem.installChip(
    watch,
    chip
)

    print(
        "[MT Smart Watch] "
        .. "ChipSystem: installChip()"
    )


    --------------------------------------------------
    -- WATCH
    --------------------------------------------------

    if not watch then

        print(
            "[MT Smart Watch] "
            .. "ChipSystem ERROR: Watch missing"
        )

        return false

    end


    --------------------------------------------------
    -- PHYSICAL CHIP
    --------------------------------------------------

    if not chip then

        print(
            "[MT Smart Watch] "
            .. "ChipSystem ERROR: Chip missing"
        )

        return false

    end


    --------------------------------------------------
    -- CORE
    --------------------------------------------------

    local coreData =
        getInstalledCoreData(
            watch
        )


    if not coreData then

        print(
            "[MT Smart Watch] "
            .. "ChipSystem ERROR: "
            .. "OS Core not installed"
        )

        return false

    end


    --------------------------------------------------
    -- CHIP DATA
    --------------------------------------------------

    local chipData =
        ChipSystem.getChipData(
            chip
        )


    if not chipData then

        print(
            "[MT Smart Watch] "
            .. "ChipSystem ERROR: "
            .. "Chip registration not found"
        )

        return false

    end


    --------------------------------------------------
    -- FULL TYPE
    --------------------------------------------------

    local fullType =
        chip:getFullType()


    if not fullType then
        return false
    end


    --------------------------------------------------
    -- DUPLICATE
    --------------------------------------------------

    if ChipSystem.hasChip(
        watch,
        fullType
    ) then

        print(
            "[MT Smart Watch] "
            .. "ChipSystem ERROR: "
            .. "Chip already installed"
        )

        return false

    end


    --------------------------------------------------
    -- TIER
    --------------------------------------------------

    local chipTier =
        chipData.tier
        or 0


    local minTier =
        coreData.minChipTier
        or 0


    local maxTier =
        coreData.maxChipTier
        or 0


    if chipTier < minTier
        or chipTier > maxTier then

        print(
            "[MT Smart Watch] "
            .. "ChipSystem ERROR: "
            .. "Chip tier is not supported"
        )


        print(
            "[MT Smart Watch] Chip Tier: "
            .. tostring(
                chipTier
            )
        )


        print(
            "[MT Smart Watch] Core Tier Range: "
            .. tostring(minTier)
            .. "-"
            .. tostring(maxTier)
        )


        return false

    end


    --------------------------------------------------
    -- TACTICAL SLOT
    --------------------------------------------------

    if chipData.category
        == "TacticalChip" then

        local tacticalSlots =
            ChipSystem.getTacticalSlots(
                watch
            )


        local usedTacticalSlots =
            ChipSystem.getTacticalChipCount(
                watch
            )


        if usedTacticalSlots
            >= tacticalSlots then

            print(
                "[MT Smart Watch] "
                .. "ChipSystem ERROR: "
                .. "No free Tactical Slots"
            )


            print(
                "[MT Smart Watch] Tactical Slots: "
                .. tostring(
                    usedTacticalSlots
                )
                .. "/"
                .. tostring(
                    tacticalSlots
                )
            )


            return false

        end

    end


    --------------------------------------------------
    -- MEMORY
    --------------------------------------------------

    local memoryCost =
        chipData.memoryCost
        or 0


    local freeMemory =
        ChipSystem.getFreeMemory(
            watch
        )


    if memoryCost > freeMemory then

        print(
            "[MT Smart Watch] "
            .. "ChipSystem ERROR: "
            .. "Not enough memory"
        )


        print(
            "[MT Smart Watch] Required: "
            .. tostring(memoryCost)
        )


        print(
            "[MT Smart Watch] Free: "
            .. tostring(freeMemory)
        )


        return false

    end


    --------------------------------------------------
    -- INSTALL
    --------------------------------------------------

    local chips =
        ChipSystem.getInstalledChips(
            watch
        )


    chips[#chips + 1] =
        fullType


    --------------------------------------------------
    -- PHYSICAL ITEM
    --------------------------------------------------

    local removeResult =
        InventoryItem.RemoveFromContainer(
            chip
        )


    print(
        "[MT Smart Watch] "
        .. "Physical Chip Remove Result: "
        .. tostring(
            removeResult
        )
    )


    --------------------------------------------------
    -- ROLLBACK
    --------------------------------------------------

    if not removeResult then

        table.remove(
            chips,
            #chips
        )


        print(
            "[MT Smart Watch] "
            .. "Chip installation rolled back"
        )


        return false

    end


    --------------------------------------------------
    -- ENSURE INACTIVE
    --------------------------------------------------

    ChipSystem.setChipActive(
        watch,
        fullType,
        false
    )


    --------------------------------------------------
    -- SUCCESS
    --------------------------------------------------

    print(
        "[MT Smart Watch] "
        .. "ChipSystem: "
        .. "Chip installed successfully"
    )


    print(
        "[MT Smart Watch] Installed Chip: "
        .. tostring(
            fullType
        )
    )


    return true

end


--------------------------------------------------
-- REMOVE CHIP
--------------------------------------------------

function ChipSystem.removeChip(
    player,
    watch,
    fullType
)

    print(
        "[MT Smart Watch] "
        .. "ChipSystem: removeChip()"
    )


    if not player then
        return false
    end


    if not watch then
        return false
    end


    if not fullType then
        return false
    end


    local chips =
        ChipSystem.getInstalledChips(
            watch
        )


    local chipIndex =
        nil


    for i = 1, #chips do

        if chips[i] == fullType then

            chipIndex =
                i

            break

        end

    end


    if not chipIndex then

        print(
            "[MT Smart Watch] "
            .. "ChipSystem ERROR: "
            .. "Chip not installed"
        )

        return false

    end


    local inventory =
        player:getInventory()


    if not inventory then
        return false
    end


    local returnedChip =
        inventory:AddItem(
            fullType
        )


    if not returnedChip then

        print(
            "[MT Smart Watch] "
            .. "ChipSystem ERROR: "
            .. "Failed to return chip"
        )

        return false

    end


    --------------------------------------------------
    -- REMOVE ACTIVE STATE
    --------------------------------------------------

    ChipSystem.setChipActive(
        watch,
        fullType,
        false
    )


    --------------------------------------------------
    -- REMOVE FROM WATCH
    --------------------------------------------------

    table.remove(
        chips,
        chipIndex
    )


    print(
        "[MT Smart Watch] "
        .. "Physical Chip returned to inventory"
    )


    print(
        "[MT Smart Watch] "
        .. "Chip removed from Watch ModData"
    )


    print(
        "[MT Smart Watch] "
        .. "Chip removed successfully"
    )


    return true

end


--------------------------------------------------
-- DEBUG
--------------------------------------------------

function ChipSystem.debug(
    watch
)

    if not watch then
        return
    end


    print(
        "[MT Smart Watch] "
        .. "Max Memory: "
        .. tostring(
            ChipSystem.getMaxMemory(
                watch
            )
        )
    )


    print(
        "[MT Smart Watch] "
        .. "Used Memory: "
        .. tostring(
            ChipSystem.getUsedMemory(
                watch
            )
        )
    )


    print(
        "[MT Smart Watch] "
        .. "Free Memory: "
        .. tostring(
            ChipSystem.getFreeMemory(
                watch
            )
        )
    )


    local chips =
        ChipSystem.getInstalledChips(
            watch
        )


    for i = 1, #chips do

        print(
            "[MT Smart Watch] "
            .. "Chip "
            .. tostring(i)
            .. ": "
            .. tostring(
                chips[i]
            )
            .. " | Active: "
            .. tostring(
                ChipSystem.isChipActive(
                    watch,
                    chips[i]
                )
            )
        )

    end

end


--------------------------------------------------
-- LOADED
--------------------------------------------------

print(
    "[MT Smart Watch] "
    .. "ChipSystem loaded"
)