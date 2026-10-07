--------------------------------------------------
-- MT SMART WATCH
-- OS CORE SYSTEM
--------------------------------------------------

print(
    "[MT Smart Watch] >>> OScore.lua LOADING <<<"
)


--------------------------------------------------
-- NAMESPACE
--------------------------------------------------

MT_SmartWatch = MT_SmartWatch or {}

MT_SmartWatch.OSCore =
    MT_SmartWatch.OSCore or {}

local OSCore =
    MT_SmartWatch.OSCore


--------------------------------------------------
-- GET REGISTER
--------------------------------------------------

local function getRegister()

    if not MT_SmartWatch.OSCoreRegister then

        print(
            "[MT Smart Watch] OSCore ERROR: "
            .. "OSCoreRegister not found"
        )

        return nil

    end


    if not MT_SmartWatch.OSCoreRegister.Data then

        print(
            "[MT Smart Watch] OSCore ERROR: "
            .. "OSCoreRegister.Data not found"
        )

        return nil

    end


    return
        MT_SmartWatch.OSCoreRegister.Data

end


--------------------------------------------------
-- GET FULL TYPE
--------------------------------------------------

function OSCore.getFullType(core)

    if not core then
        return nil
    end


    if not core.getFullType then
        return nil
    end


    return
        core:getFullType()

end


--------------------------------------------------
-- GET DATA
--------------------------------------------------

function OSCore.getData(core)

    if not core then
        return nil
    end


    local fullType =
        OSCore.getFullType(
            core
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
-- IS CORE
--------------------------------------------------

function OSCore.isCore(core)

    if not core then
        return false
    end


    return
        OSCore.getData(core)
        ~= nil

end


--------------------------------------------------
-- GET ID
--------------------------------------------------

function OSCore.getID(core)

    local data =
        OSCore.getData(
            core
        )


    if not data then
        return nil
    end


    return
        data.id

end


--------------------------------------------------
-- GET RARITY
--------------------------------------------------

function OSCore.getRarity(core)

    local data =
        OSCore.getData(
            core
        )


    if not data then
        return nil
    end


    return
        data.rarity

end


--------------------------------------------------
-- GET BATTERY CAPACITY
--------------------------------------------------

function OSCore.getBatteryCapacity(core)

    local data =
        OSCore.getData(
            core
        )


    if not data then
        return 0
    end


    return
        data.batteryCapacity
        or 0

end


--------------------------------------------------
-- GET MEMORY
--------------------------------------------------

function OSCore.getMemory(core)

    local data =
        OSCore.getData(
            core
        )


    if not data then
        return 0
    end


    return
        data.memory
        or 0

end


--------------------------------------------------
-- GET MEMORY COST
--------------------------------------------------

function OSCore.getMemoryCost(core)

    local data =
        OSCore.getData(
            core
        )


    if not data then
        return 0
    end


    return
        data.memoryCost
        or 0

end


--------------------------------------------------
-- GET MIN CHIP TIER
--------------------------------------------------

function OSCore.getMinChipTier(core)

    local data =
        OSCore.getData(
            core
        )


    if not data then
        return 0
    end


    return
        data.minChipTier
        or 0

end


--------------------------------------------------
-- GET MAX CHIP TIER
--------------------------------------------------

function OSCore.getMaxChipTier(core)

    local data =
        OSCore.getData(
            core
        )


    if not data then
        return 0
    end


    return
        data.maxChipTier
        or 0

end


--------------------------------------------------
-- GET TACTICAL SLOTS
--------------------------------------------------

function OSCore.getTacticalSlots(core)

    local data =
        OSCore.getData(
            core
        )


    if not data then
        return 0
    end


    return
        data.tacticalSlots
        or 0

end


--------------------------------------------------
-- GET INFO
--------------------------------------------------

function OSCore.getInfo(core)

    local data =
        OSCore.getData(
            core
        )


    if not data then
        return nil
    end


    return {

        fullType =
            OSCore.getFullType(
                core
            ),

        id =
            data.id,

        rarity =
            data.rarity,

        batteryCapacity =
            data.batteryCapacity,

        memory =
            data.memory,

        memoryCost =
            data.memoryCost,

        minChipTier =
            data.minChipTier,

        maxChipTier =
            data.maxChipTier,

        tacticalSlots =
            data.tacticalSlots,

    }

end


--------------------------------------------------
-- GET INSTALLED CORE FULL TYPE
--------------------------------------------------

function OSCore.getInstalledFullType(
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


    local watchData =
        modData.MT_SmartWatch


    if not watchData then
        return nil
    end


    local coreData =
        watchData.OSCore


    if not coreData then
        return nil
    end


    return
        coreData.fullType

end


--------------------------------------------------
-- GET INSTALLED CORE DATA
--------------------------------------------------

function OSCore.getInstalledData(
    watch
)

    if not watch then
        return nil
    end


    local fullType =
        OSCore.getInstalledFullType(
            watch
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
-- HAS INSTALLED CORE
--------------------------------------------------

function OSCore.hasInstalledCore(
    watch
)

    return
        OSCore.getInstalledFullType(
            watch
        )
        ~= nil

end


--------------------------------------------------
-- INSTALL CORE
--------------------------------------------------

function OSCore.installCore(
    watch,
    core
)

    print(
        "[MT Smart Watch] OSCore: "
        .. "installCore()"
    )


    --------------------------------------------------
    -- VALIDATE WATCH
    --------------------------------------------------

    if not watch then

        print(
            "[MT Smart Watch] OSCore: "
            .. "Watch missing"
        )

        return false

    end


    --------------------------------------------------
    -- VALIDATE CORE
    --------------------------------------------------

    if not core then

        print(
            "[MT Smart Watch] OSCore: "
            .. "Core missing"
        )

        return false

    end


    --------------------------------------------------
    -- CHECK EXISTING CORE
    --------------------------------------------------

    if OSCore.hasInstalledCore(
        watch
    ) then

        print(
            "[MT Smart Watch] OSCore: "
            .. "Core already installed"
        )

        return false

    end


    --------------------------------------------------
    -- VALIDATE CORE DATA
    --------------------------------------------------

    local coreFullType =
        OSCore.getFullType(
            core
        )


    if not coreFullType then

        print(
            "[MT Smart Watch] OSCore: "
            .. "Core FullType missing"
        )

        return false

    end


    local coreData =
        OSCore.getData(
            core
        )


    if not coreData then

        print(
            "[MT Smart Watch] OSCore: "
            .. "Core validation failed"
        )

        return false

    end


    print(
        "[MT Smart Watch] Core Validation: PASS"
    )


    print(
        "[MT Smart Watch] Core FullType: "
        .. tostring(
            coreFullType
        )
    )


    --------------------------------------------------
    -- MOD DATA
    --------------------------------------------------

    local modData =
        watch:getModData()


    if not modData then

        print(
            "[MT Smart Watch] OSCore: "
            .. "Watch ModData unavailable"
        )

        return false

    end


    modData.MT_SmartWatch =
        modData.MT_SmartWatch
        or {}


    --------------------------------------------------
    -- WRITE CORE
    --------------------------------------------------

    modData.MT_SmartWatch.OSCore = {

        fullType =
            coreFullType,

    }


    print(
        "[MT Smart Watch] "
        .. "Core written to Watch ModData"
    )


    --------------------------------------------------
    -- REMOVE PHYSICAL CORE
    --------------------------------------------------

    local removeResult =
        InventoryItem.RemoveFromContainer(
            core
        )


    print(
        "[MT Smart Watch] "
        .. "Physical Core Remove Result: "
        .. tostring(removeResult)
    )


    --------------------------------------------------
    -- ROLLBACK
    --------------------------------------------------

    if not removeResult then

        modData.MT_SmartWatch.OSCore =
            nil


        print(
            "[MT Smart Watch] OSCore: "
            .. "Physical Core removal failed"
        )


        print(
            "[MT Smart Watch] OSCore: "
            .. "Installation rolled back"
        )


        return false

    end


    --------------------------------------------------
    -- SUCCESS
    --------------------------------------------------

    print(
        "[MT Smart Watch] "
        .. "Core installed successfully"
    )


    return true

end


--------------------------------------------------
-- REMOVE CORE
--------------------------------------------------

function OSCore.removeCore(
    watch,
    player
)

    print(
        "[MT Smart Watch] OSCore: "
        .. "removeCore()"
    )


    --------------------------------------------------
    -- VALIDATE WATCH
    --------------------------------------------------

    if not watch then

        print(
            "[MT Smart Watch] OSCore: "
            .. "Watch missing"
        )

        return false

    end


    --------------------------------------------------
    -- VALIDATE PLAYER
    --------------------------------------------------

    if not player then

        print(
            "[MT Smart Watch] OSCore: "
            .. "Player missing"
        )

        return false

    end


    --------------------------------------------------
    -- MOD DATA
    --------------------------------------------------

    local modData =
        watch:getModData()


    if not modData then

        print(
            "[MT Smart Watch] OSCore: "
            .. "Watch ModData missing"
        )

        return false

    end


    local watchData =
        modData.MT_SmartWatch


    if not watchData then

        print(
            "[MT Smart Watch] OSCore: "
            .. "Watch data missing"
        )

        return false

    end


    --------------------------------------------------
    -- INSTALLED CORE
    --------------------------------------------------

    local coreData =
        watchData.OSCore


    if not coreData then

        print(
            "[MT Smart Watch] OSCore: "
            .. "No Core installed"
        )

        return false

    end


    local coreFullType =
        coreData.fullType


    if not coreFullType then

        print(
            "[MT Smart Watch] OSCore: "
            .. "Installed Core FullType missing"
        )

        return false

    end


    print(
        "[MT Smart Watch] OSCore: "
        .. "Core FullType: "
        .. tostring(
            coreFullType
        )
    )


    --------------------------------------------------
    -- CHECK INSTALLED CHIPS
    --------------------------------------------------

    local chips =
        watchData.chips


    if type(chips) == "table"
        and #chips > 0 then

        print(
            "[MT Smart Watch] OSCore: "
            .. "Cannot remove Core"
        )


        print(
            "[MT Smart Watch] OSCore: "
            .. "Installed Chips: "
            .. tostring(
                #chips
            )
        )


        return false

    end


    print(
        "[MT Smart Watch] OSCore: "
        .. "No installed chips"
    )


    --------------------------------------------------
    -- PLAYER INVENTORY
    --------------------------------------------------

    local inventory =
        player:getInventory()


    if not inventory then

        print(
            "[MT Smart Watch] OSCore: "
            .. "Player inventory missing"
        )

        return false

    end


    --------------------------------------------------
    -- RETURN CORE
    --------------------------------------------------

    print(
        "[MT Smart Watch] OSCore: "
        .. "Adding physical Core to inventory"
    )


    local addResult =
        inventory:AddItem(
            coreFullType
        )


    print(
        "[MT Smart Watch] OSCore: "
        .. "AddItem Result: "
        .. tostring(
            addResult
        )
    )


    if not addResult then

        print(
            "[MT Smart Watch] OSCore: "
            .. "Failed to add physical Core"
        )

        return false

    end


    --------------------------------------------------
    -- VERIFY CORE
    --------------------------------------------------

    local returnedCore =
        inventory:getItemFromType(
            coreFullType,
            true,
            true
        )


    if not returnedCore then

        print(
            "[MT Smart Watch] OSCore: "
            .. "Core was not found "
            .. "after AddItem"
        )

        return false

    end


    print(
        "[MT Smart Watch] OSCore: "
        .. "Physical Core verified "
        .. "in inventory"
    )


    --------------------------------------------------
    -- REMOVE FROM WATCH
    --------------------------------------------------

    watchData.OSCore =
        nil


    print(
        "[MT Smart Watch] OSCore: "
        .. "Core removed from "
        .. "Watch ModData"
    )


    --------------------------------------------------
    -- SUCCESS
    --------------------------------------------------

    print(
        "[MT Smart Watch] OSCore: "
        .. "Core removed successfully"
    )


    return true

end


--------------------------------------------------
-- DEBUG
--------------------------------------------------

function OSCore.debug(core)

    if not core then

        print(
            "[MT Smart Watch] OSCore: "
            .. "No Core"
        )

        return

    end


    local data =
        OSCore.getData(
            core
        )


    if not data then

        print(
            "[MT Smart Watch] OSCore: "
            .. "Core Registration: INVALID"
        )

        return

    end


    print(
        "[MT Smart Watch] OSCore: "
        .. "Core FullType: "
        .. tostring(
            core:getFullType()
        )
    )


    print(
        "[MT Smart Watch] OSCore: "
        .. "Core ID: "
        .. tostring(data.id)
    )


    print(
        "[MT Smart Watch] OSCore: "
        .. "Rarity: "
        .. tostring(data.rarity)
    )


    print(
        "[MT Smart Watch] OSCore: "
        .. "Battery Capacity: "
        .. tostring(
            data.batteryCapacity
        )
    )


    print(
        "[MT Smart Watch] OSCore: "
        .. "Memory: "
        .. tostring(
            data.memory
        )
    )


    print(
        "[MT Smart Watch] OSCore: "
        .. "Memory Cost: "
        .. tostring(
            data.memoryCost
        )
    )


    print(
        "[MT Smart Watch] OSCore: "
        .. "Min Chip Tier: "
        .. tostring(
            data.minChipTier
        )
    )


    print(
        "[MT Smart Watch] OSCore: "
        .. "Max Chip Tier: "
        .. tostring(
            data.maxChipTier
        )
    )

end


--------------------------------------------------
-- DEBUG INSTALLED CORE
--------------------------------------------------

function OSCore.debugInstalled(
    watch
)

    local fullType =
        OSCore.getInstalledFullType(
            watch
        )


    if not fullType then

        print(
            "[MT Smart Watch] OSCore: "
            .. "Installed Core: NONE"
        )

        return

    end


    local data =
        OSCore.getInstalledData(
            watch
        )


    if not data then

        print(
            "[MT Smart Watch] OSCore: "
            .. "Installed Core Data: INVALID"
        )

        return

    end


    print(
        "[MT Smart Watch] OSCore: "
        .. "Installed Core FullType: "
        .. tostring(fullType)
    )


    print(
        "[MT Smart Watch] OSCore: "
        .. "Core ID: "
        .. tostring(data.id)
    )


    print(
        "[MT Smart Watch] OSCore: "
        .. "Rarity: "
        .. tostring(data.rarity)
    )


    print(
        "[MT Smart Watch] OSCore: "
        .. "Battery Capacity: "
        .. tostring(
            data.batteryCapacity
        )
    )


    print(
        "[MT Smart Watch] OSCore: "
        .. "Memory: "
        .. tostring(
            data.memory
        )
    )


    print(
        "[MT Smart Watch] OSCore: "
        .. "Memory Cost: "
        .. tostring(
            data.memoryCost
        )
    )


    print(
        "[MT Smart Watch] OSCore: "
        .. "Min Chip Tier: "
        .. tostring(
            data.minChipTier
        )
    )


    print(
        "[MT Smart Watch] OSCore: "
        .. "Max Chip Tier: "
        .. tostring(
            data.maxChipTier
        )
    )

end


--------------------------------------------------
-- LOAD DIAGNOSTICS
--------------------------------------------------

print(
    "[MT Smart Watch] "
    .. "OScore functions registered"
)

print(
    "[MT Smart Watch] getData = "
    .. tostring(
        type(
            OSCore.getData
        )
    )
)

print(
    "[MT Smart Watch] installCore = "
    .. tostring(
        type(
            OSCore.installCore
        )
    )
)

print(
    "[MT Smart Watch] removeCore = "
    .. tostring(
        type(
            OSCore.removeCore
        )
    )
)

print(
    "[MT Smart Watch] hasInstalledCore = "
    .. tostring(
        type(
            OSCore.hasInstalledCore
        )
    )
)

print(
    "[MT Smart Watch] >>> OScore.lua LOADED <<<"
)