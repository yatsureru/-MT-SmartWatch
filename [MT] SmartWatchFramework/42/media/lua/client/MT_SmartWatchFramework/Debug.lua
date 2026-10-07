MT_SmartWatch = MT_SmartWatch or {}

MT_SmartWatch.Debug =
    MT_SmartWatch.Debug or {}

local Debug =
    MT_SmartWatch.Debug


--------------------------------------------------
-- HELPERS
--------------------------------------------------

local function getEquippedWatch()

    if not getPlayer then
        return nil
    end

    local player =
        getPlayer()

    if not player then
        return nil
    end

    if not MT_SmartWatch.Watch then
        return nil
    end

    return
        MT_SmartWatch.Watch.getEquippedWatch(player)
end


--------------------------------------------------
-- 0
-- FULL WATCH TEST
--------------------------------------------------

function Debug.testEquippedWatch()

    print("[MT Smart Watch] ========== FULL WATCH TEST ==========")

    local player =
        getPlayer()

    if not player then
        print("[MT Smart Watch] Player: NOT FOUND")
        print("[MT Smart Watch] ========== FULL WATCH TEST END ==========")
        return
    end

    local Watch =
        MT_SmartWatch.Watch

    if not Watch then
        print("[MT Smart Watch] Watch module: NOT FOUND")
        print("[MT Smart Watch] ========== FULL WATCH TEST END ==========")
        return
    end

    local watch =
        Watch.getEquippedWatch(player)

    if not watch then
        print("[MT Smart Watch] Watch: NOT EQUIPPED")
        print("[MT Smart Watch] ========== FULL WATCH TEST END ==========")
        return
    end

    print("[MT Smart Watch] Watch: EQUIPPED")

    local fullType =
        watch:getFullType()

    print(
        "[MT Smart Watch] FullType: "
        .. tostring(fullType)
    )

    print(
        "[MT Smart Watch] Tag: "
        .. tostring(
            Watch.isSmartWatch(watch)
        )
    )


    --------------------------------------------------
    -- CORE
    --------------------------------------------------

    local OSCore =
        MT_SmartWatch.OSCore

    if not OSCore then

        print(
            "[MT Smart Watch] OSCore module: NOT FOUND"
        )

    else

        local coreFullType =
            OSCore.getInstalledFullType(watch)

        print(
            "[MT Smart Watch] Core: "
            .. tostring(coreFullType)
        )

        if coreFullType then

            local coreData =
                OSCore.getInstalledData(watch)

            if coreData then

                print(
                    "[MT Smart Watch] Core ID: "
                    .. tostring(coreData.id)
                )

                print(
                    "[MT Smart Watch] Battery Capacity: "
                    .. tostring(coreData.batteryCapacity)
                )

                print(
                    "[MT Smart Watch] Memory: "
                    .. tostring(coreData.memory)
                )

                print(
                    "[MT Smart Watch] Tier: "
                    .. tostring(coreData.minChipTier)
                    .. "-"
                    .. tostring(coreData.maxChipTier)
                )

            else

                print(
                    "[MT Smart Watch] Core Data: NOT FOUND"
                )

            end

        end

    end


    --------------------------------------------------
    -- MEMORY
    --------------------------------------------------

    local ChipSystem =
        MT_SmartWatch.ChipSystem

    if ChipSystem then

        print(
            "[MT Smart Watch] Memory: "
            .. tostring(
                ChipSystem.getUsedMemory(watch)
            )
            .. " / "
            .. tostring(
                ChipSystem.getMaxMemory(watch)
            )
        )

        print(
            "[MT Smart Watch] Free Memory: "
            .. tostring(
                ChipSystem.getFreeMemory(watch)
            )
        )

    else

        print(
            "[MT Smart Watch] ChipSystem module: NOT FOUND"
        )

    end


    --------------------------------------------------
    -- TACTICAL SLOTS
    --------------------------------------------------

    if ChipSystem then

        print(
            "[MT Smart Watch] Tactical Slots: "
            .. tostring(
                ChipSystem.getTacticalChipCount(watch)
            )
            .. " / "
            .. tostring(
                ChipSystem.getTacticalSlots(watch)
            )
        )

        print(
            "[MT Smart Watch] Free Tactical Slots: "
            .. tostring(
                ChipSystem.getFreeTacticalSlots(watch)
            )
        )

    end


    --------------------------------------------------
    -- CHIPS
    --------------------------------------------------

    local chips = {}

    if ChipSystem then

        chips =
            ChipSystem.getInstalledChips(watch)
            or {}

    end

    print(
        "[MT Smart Watch] Installed Chips: "
        .. tostring(#chips)
    )

    for i = 1, #chips do

        local chipFullType =
            chips[i]

        print(
            "[MT Smart Watch] Chip "
            .. tostring(i)
            .. ": "
            .. tostring(chipFullType)
            .. " | Active: "
            .. tostring(
                ChipSystem.isChipActive(
                    watch,
                    chipFullType
                )
            )
        )

    end


    --------------------------------------------------
    -- BATTERY
    --------------------------------------------------

    local Battery =
        MT_SmartWatch.Battery

    if Battery then

        print(
            "[MT Smart Watch] Battery: "
            .. tostring(
                Battery.getCurrent(watch)
            )
            .. " / "
            .. tostring(
                Battery.getMax(watch)
            )
        )

    else

        print(
            "[MT Smart Watch] Battery module: NOT FOUND"
        )

    end


    --------------------------------------------------
    -- RADIO
    --------------------------------------------------

    local RadioApp =
        MT_SmartWatch.RadioApp

    if RadioApp and RadioApp.isActive then

        print(
            "[MT Smart Watch] Radio App Active: "
            .. tostring(
                RadioApp.isActive()
            )
        )

    else

        print(
            "[MT Smart Watch] Radio App Active: false"
        )

    end

    print("[MT Smart Watch] ========== FULL WATCH TEST END ==========")
end


--------------------------------------------------
-- 9
-- BATTERY DRAIN TEST
--------------------------------------------------

function Debug.testBatteryDrain()

    print("[MT Smart Watch] ========== BATTERY DRAIN TEST ==========")

    local player =
        getPlayer()

    if not player then
        print(
            "[MT Smart Watch] Battery Test ERROR: Player not found"
        )

        print(
            "[MT Smart Watch] ========== BATTERY DRAIN TEST END =========="
        )

        return
    end

    local Watch =
        MT_SmartWatch.Watch

    if not Watch then
        print(
            "[MT Smart Watch] Battery Test ERROR: Watch module not found"
        )

        print(
            "[MT Smart Watch] ========== BATTERY DRAIN TEST END =========="
        )

        return
    end

    local watch =
        Watch.getEquippedWatch(player)

    if not watch then
        print(
            "[MT Smart Watch] Battery Test ERROR: Smart Watch not equipped"
        )

        print(
            "[MT Smart Watch] ========== BATTERY DRAIN TEST END =========="
        )

        return
    end

    local BatteryDrain =
        MT_SmartWatch.BatteryDrain

    local Battery =
        MT_SmartWatch.Battery

    if not BatteryDrain then
        print(
            "[MT Smart Watch] Battery Test ERROR: BatteryDrain module not found"
        )

        print(
            "[MT Smart Watch] ========== BATTERY DRAIN TEST END =========="
        )

        return
    end

    if not Battery then
        print(
            "[MT Smart Watch] Battery Test ERROR: Battery module not found"
        )

        print(
            "[MT Smart Watch] ========== BATTERY DRAIN TEST END =========="
        )

        return
    end


    --------------------------------------------------
    -- CURRENT CONFIG
    --------------------------------------------------

    local drainPerMinute =
        BatteryDrain.getDrainPerMinute(watch)

    print(
        "[MT Smart Watch] Drain / Game Minute: "
        .. tostring(drainPerMinute)
    )


    --------------------------------------------------
    -- BEFORE
    --------------------------------------------------

    local before =
        Battery.getCurrent(watch)

    print(
        "[MT Smart Watch] Battery Drain / 1 Game Minute"
    )

    print(
        "[MT Smart Watch] Configured Drain: "
        .. tostring(drainPerMinute)
    )

    print(
        "[MT Smart Watch] Before: "
        .. tostring(before)
    )


    --------------------------------------------------
    -- APPLY
    --------------------------------------------------

    local actual =
        BatteryDrain.applyMinutes(
            watch,
            1
        )


    --------------------------------------------------
    -- AFTER
    --------------------------------------------------

    local after =
        Battery.getCurrent(watch)

    print(
        "[MT Smart Watch] Actual Drain: "
        .. tostring(actual)
    )

    print(
        "[MT Smart Watch] After: "
        .. tostring(after)
    )

    print("[MT Smart Watch] ========== BATTERY DRAIN TEST END ==========")
end


--------------------------------------------------
-- ALL SYSTEMS
--------------------------------------------------

function Debug.testAllSystems()

    print("[MT Smart Watch] ========== ALL SYSTEMS TEST ==========")

    Debug.testEquippedWatch()

    Debug.testBatteryDrain()

    print("[MT Smart Watch] ========== ALL SYSTEMS TEST END ==========")
end


--------------------------------------------------
-- 1
-- INSTALL LOGIC CORE
--------------------------------------------------

function Debug.testInstallLogicCore()

    print("[MT Smart Watch] ========== INSTALL LOGIC CORE ==========")

    local player =
        getPlayer()

    if not player then
        print("[MT Smart Watch] ERROR: Player not found")
        return
    end

    local watch =
        MT_SmartWatch.Watch.getEquippedWatch(player)

    if not watch then
        print("[MT Smart Watch] ERROR: Smart Watch not equipped")
        return
    end

    local inventory =
        player:getInventory()

    local core =
        inventory:getFirstType(
            "Base.MTSW_Core_Logic"
        )

    if not core then
        print(
            "[MT Smart Watch] ERROR: Logic Core not found in inventory"
        )
        return
    end

    local result =
        MT_SmartWatch.OSCore.installCore(
            watch,
            core
        )

    print(
        "[MT Smart Watch] Logic Core Install Result: "
        .. tostring(result)
    )

    print(
        "[MT Smart Watch] ========== INSTALL LOGIC CORE END =========="
    )
end


--------------------------------------------------
-- 2
-- REMOVE CORE
--------------------------------------------------

function Debug.testRemoveOSCore()

    print("[MT Smart Watch] ========== REMOVE OS CORE ==========")

    local player =
        getPlayer()

    if not player then
        print("[MT Smart Watch] ERROR: Player not found")
        return
    end

    local watch =
        MT_SmartWatch.Watch.getEquippedWatch(player)

    if not watch then
        print("[MT Smart Watch] ERROR: Smart Watch not equipped")
        return
    end

    local result =
        MT_SmartWatch.OSCore.removeCore(
            watch,
            player
        )

    print(
        "[MT Smart Watch] Core Remove Result: "
        .. tostring(result)
    )

    print(
        "[MT Smart Watch] ========== REMOVE OS CORE END =========="
    )
end


--------------------------------------------------
-- 3
-- INSTALL TACTICAL CORE
--------------------------------------------------

function Debug.testInstallTacticalCore()

    print("[MT Smart Watch] ========== INSTALL TACTICAL CORE ==========")

    local player =
        getPlayer()

    if not player then
        print("[MT Smart Watch] ERROR: Player not found")
        return
    end

    local watch =
        MT_SmartWatch.Watch.getEquippedWatch(player)

    if not watch then
        print("[MT Smart Watch] ERROR: Smart Watch not equipped")
        return
    end

    local inventory =
        player:getInventory()

    local core =
        inventory:getFirstType(
            "Base.MTSW_Core_Tactical"
        )

    if not core then
        print(
            "[MT Smart Watch] ERROR: Tactical Core not found in inventory"
        )
        return
    end

    local result =
        MT_SmartWatch.OSCore.installCore(
            watch,
            core
        )

    print(
        "[MT Smart Watch] Tactical Core Install Result: "
        .. tostring(result)
    )

    print(
        "[MT Smart Watch] ========== INSTALL TACTICAL CORE END =========="
    )
end


--------------------------------------------------
-- 4
-- REMOVE TIME CHIP
--------------------------------------------------

function Debug.testRemoveTimeChip()

    print("[MT Smart Watch] ========== REMOVE TIME CHIP ==========")

    local player =
        getPlayer()

    if not player then
        print("[MT Smart Watch] ERROR: Player not found")
        return
    end

    local watch =
        MT_SmartWatch.Watch.getEquippedWatch(player)

    if not watch then
        print("[MT Smart Watch] ERROR: Smart Watch not equipped")
        return
    end

    local result =
        MT_SmartWatch.ChipSystem.removeChip(
            player,
            watch,
            "Base.MTSW_FChip_Time"
        )

    print(
        "[MT Smart Watch] Time Chip Remove Result: "
        .. tostring(result)
    )

    print(
        "[MT Smart Watch] ========== REMOVE TIME CHIP END =========="
    )
end


--------------------------------------------------
-- 5
-- INSTALL TIME CHIP
--------------------------------------------------

function Debug.testInstallTimeChip()

    print("[MT Smart Watch] ========== INSTALL TIME CHIP ==========")

    local player =
        getPlayer()

    if not player then
        print("[MT Smart Watch] ERROR: Player not found")
        return
    end

    local watch =
        MT_SmartWatch.Watch.getEquippedWatch(player)

    if not watch then
        print("[MT Smart Watch] ERROR: Smart Watch not equipped")
        return
    end

    local inventory =
        player:getInventory()

    local chip =
        inventory:getFirstType(
            "Base.MTSW_FChip_Time"
        )

    if not chip then
        print(
            "[MT Smart Watch] ERROR: Time Chip not found in inventory"
        )
        return
    end

    local result =
        MT_SmartWatch.ChipSystem.installChip(
            watch,
            chip
        )

    print(
        "[MT Smart Watch] Time Chip Install Result: "
        .. tostring(result)
    )

    print(
        "[MT Smart Watch] ========== INSTALL TIME CHIP END =========="
    )
end


--------------------------------------------------
-- 6
-- INSTALL RADIO CHIP
--------------------------------------------------

function Debug.testInstallRadioChip()

    print("[MT Smart Watch] ========== INSTALL RADIO CHIP ==========")

    local player =
        getPlayer()

    if not player then
        print("[MT Smart Watch] ERROR: Player not found")
        return
    end

    local watch =
        MT_SmartWatch.Watch.getEquippedWatch(player)

    if not watch then
        print("[MT Smart Watch] ERROR: Smart Watch not equipped")
        return
    end

    local inventory =
        player:getInventory()

    local chip =
        inventory:getFirstType(
            "Base.MTSW_AChip_Radio"
        )

    if not chip then
        print(
            "[MT Smart Watch] ERROR: Radio Chip not found in inventory"
        )
        return
    end

    local result =
        MT_SmartWatch.ChipSystem.installChip(
            watch,
            chip
        )

    print(
        "[MT Smart Watch] Radio Chip Install Result: "
        .. tostring(result)
    )

    print(
        "[MT Smart Watch] ========== INSTALL RADIO CHIP END =========="
    )
end


--------------------------------------------------
-- 7
-- RADIO APP TOGGLE
--------------------------------------------------

function Debug.testOpenRadio()

    print("[MT Smart Watch] ========== RADIO APP TOGGLE ==========")

    local RadioApp =
        MT_SmartWatch.RadioApp

    if not RadioApp then

        print(
            "[MT Smart Watch] RadioApp ERROR: module not found"
        )

        print(
            "[MT Smart Watch] ========== RADIO APP TOGGLE END =========="
        )

        return
    end


    --------------------------------------------------
    -- OPEN / CLOSE
    --------------------------------------------------

    if RadioApp.isActive
        and RadioApp.isActive() then

        print(
            "[MT Smart Watch] RadioApp: ACTIVE -> CLOSE"
        )

        if not RadioApp.close then

            print(
                "[MT Smart Watch] RadioApp ERROR: close() not found"
            )

            print(
                "[MT Smart Watch] ========== RADIO APP TOGGLE END =========="
            )

            return
        end

        RadioApp.close()

        print(
            "[MT Smart Watch] Radio Close Result: true"
        )

    else

        print(
            "[MT Smart Watch] RadioApp: INACTIVE -> OPEN"
        )

        if not RadioApp.open then

            print(
                "[MT Smart Watch] RadioApp ERROR: open() not found"
            )

            print(
                "[MT Smart Watch] ========== RADIO APP TOGGLE END =========="
            )

            return
        end

        local result =
            RadioApp.open()

        print(
            "[MT Smart Watch] Radio Open Result: "
            .. tostring(result)
        )

    end


    print(
        "[MT Smart Watch] ========== RADIO APP TOGGLE END =========="
    )
end


--------------------------------------------------
-- INSTALL EMP TACTICAL CHIP
--------------------------------------------------

function Debug.testUseEMP()

    print("[MT Smart Watch] ========== USE EMP TACTICAL CHIP ==========")

    local player =
        getPlayer()

    if not player then
        print("[MT Smart Watch] ERROR: Player not found")
        return
    end

    local watch =
        MT_SmartWatch.Watch.getEquippedWatch(player)

    if not watch then
        print("[MT Smart Watch] ERROR: Smart Watch not equipped")
        return
    end

    local EMP =
        MT_SmartWatch.TacticalEMP

    if not EMP or not EMP.activate then
        print("[MT Smart Watch] ERROR: TacticalEMP module not found")
        return
    end

    local result =
        EMP.activate(
            player,
            watch
        )

    print(
        "[MT Smart Watch] EMP Use Result: "
        .. tostring(result)
    )

    print(
        "[MT Smart Watch] ========== USE EMP TACTICAL CHIP END =========="
    )
end


--------------------------------------------------
-- INSTALL EMP TACTICAL CHIP
--------------------------------------------------

function Debug.testInstallEMP()

    print("[MT Smart Watch] ========== INSTALL EMP TACTICAL CHIP ==========")

    local player =
        getPlayer()

    if not player then
        print("[MT Smart Watch] ERROR: Player not found")
        return
    end

    local watch =
        MT_SmartWatch.Watch.getEquippedWatch(player)

    if not watch then
        print("[MT Smart Watch] ERROR: Smart Watch not equipped")
        return
    end

    local inventory =
        player:getInventory()

    local chip =
        inventory:getFirstType(
            "Base.MTSW_TChip_EMP"
        )

    if not chip then
        print("[MT Smart Watch] ERROR: EMP Tactical Chip not found in inventory")
        return
    end

    local result =
        MT_SmartWatch.ChipSystem.installChip(
            watch,
            chip
        )

    print(
        "[MT Smart Watch] EMP Install Result: "
        .. tostring(result)
    )

    print(
        "[MT Smart Watch] ========== INSTALL EMP TACTICAL CHIP END =========="
    )
end


--------------------------------------------------
-- REMOVE EMP TACTICAL CHIP
--------------------------------------------------

function Debug.testRemoveEMP()

    print("[MT Smart Watch] ========== REMOVE EMP TACTICAL CHIP ==========")

    local player =
        getPlayer()

    if not player then
        print("[MT Smart Watch] ERROR: Player not found")
        return
    end

    local watch =
        MT_SmartWatch.Watch.getEquippedWatch(player)

    if not watch then
        print("[MT Smart Watch] ERROR: Smart Watch not equipped")
        return
    end

    local result =
        MT_SmartWatch.ChipSystem.removeChip(
            player,
            watch,
            "Base.MTSW_TChip_EMP"
        )

    print(
        "[MT Smart Watch] EMP Remove Result: "
        .. tostring(result)
    )

    print(
        "[MT Smart Watch] ========== REMOVE EMP TACTICAL CHIP END =========="
    )
end




--------------------------------------------------
-- EMP STATUS
--------------------------------------------------

function Debug.testEMPStatus()

    print("[MT Smart Watch] ========== EMP STATUS ==========")

    local player =
        getPlayer()

    if not player then
        print("[MT Smart Watch] ERROR: Player not found")
        return
    end

    local watch =
        MT_SmartWatch.Watch.getEquippedWatch(player)

    if not watch then
        print("[MT Smart Watch] ERROR: Smart Watch not equipped")
        return
    end

    local EMP =
        MT_SmartWatch.TacticalEMP

    local Battery =
        MT_SmartWatch.Battery

    local ChipSystem =
        MT_SmartWatch.ChipSystem

    print(
        "[MT Smart Watch] EMP Installed: "
        .. tostring(
            ChipSystem
            and ChipSystem.hasChip
            and ChipSystem.hasChip(
                watch,
                "Base.MTSW_TChip_EMP"
            )
        )
    )

    if Battery then
        print(
            "[MT Smart Watch] Battery: "
            .. tostring(Battery.getCurrent(watch))
            .. " / "
            .. tostring(Battery.getMax(watch))
        )
    end

    if EMP and EMP.getCooldownRemaining then
        print(
            "[MT Smart Watch] EMP Cooldown Remaining: "
            .. string.format(
                "%.1f",
                EMP.getCooldownRemaining(watch)
            )
            .. " sec"
        )
    end

    print("[MT Smart Watch] ========== EMP STATUS END ==========")
end


--------------------------------------------------
-- TACTICAL SLOTS TEST
--------------------------------------------------

function Debug.testTacticalSlots()

    print("[MT Smart Watch] ========== TACTICAL SLOTS TEST ==========")

    local player =
        getPlayer()

    if not player then
        print("[MT Smart Watch] ERROR: Player not found")
        return
    end

    local watch =
        MT_SmartWatch.Watch.getEquippedWatch(player)

    if not watch then
        print("[MT Smart Watch] ERROR: Smart Watch not equipped")
        return
    end

    local ChipSystem =
        MT_SmartWatch.ChipSystem

    if not ChipSystem then
        print("[MT Smart Watch] ERROR: ChipSystem module not found")
        return
    end

    local tacticalSlots =
        ChipSystem.getTacticalSlots(watch)

    local tacticalCount =
        ChipSystem.getTacticalChipCount(watch)

    local freeTacticalSlots =
        ChipSystem.getFreeTacticalSlots(watch)

    local hasFreeSlot =
        ChipSystem.hasFreeTacticalSlot(watch)

    print(
        "[MT Smart Watch] Tactical Slots: "
        .. tostring(tacticalCount)
        .. " / "
        .. tostring(tacticalSlots)
    )

    print(
        "[MT Smart Watch] Free Tactical Slots: "
        .. tostring(freeTacticalSlots)
    )

    print(
        "[MT Smart Watch] Has Free Tactical Slot: "
        .. tostring(hasFreeSlot)
    )

    print("[MT Smart Watch] ========== TACTICAL SLOTS TEST END ==========")
end


--------------------------------------------------
-- DEBUG STATUS
--------------------------------------------------

function Debug.printStatus()

    print("[MT Smart Watch] ========== DEBUG STATUS ==========")

    local watch =
        getEquippedWatch()

    if not watch then

        print(
            "[MT Smart Watch] Status: Watch not equipped"
        )

        print(
            "[MT Smart Watch] ========== DEBUG STATUS END =========="
        )

        return
    end


    print(
        "[MT Smart Watch] Watch: "
        .. tostring(
            watch:getFullType()
        )
    )

    print(
        "[MT Smart Watch] SmartWatch: "
        .. tostring(
            MT_SmartWatch.Watch.isSmartWatch(watch)
        )
    )


    --------------------------------------------------
    -- CORE
    --------------------------------------------------

    local core =
        MT_SmartWatch.OSCore.getInstalledFullType(watch)

    print(
        "[MT Smart Watch] Core: "
        .. tostring(core)
    )


    --------------------------------------------------
    -- BATTERY
    --------------------------------------------------

    print(
        "[MT Smart Watch] Battery: "
        .. tostring(
            MT_SmartWatch.Battery.getCurrent(watch)
        )
        .. " / "
        .. tostring(
            MT_SmartWatch.Battery.getMax(watch)
        )
    )


    --------------------------------------------------
    -- MEMORY
    --------------------------------------------------

    print(
        "[MT Smart Watch] Memory: "
        .. tostring(
            MT_SmartWatch.ChipSystem.getUsedMemory(watch)
        )
        .. " / "
        .. tostring(
            MT_SmartWatch.ChipSystem.getMaxMemory(watch)
        )
    )


    --------------------------------------------------
    -- RADIO
    --------------------------------------------------

    local RadioApp =
        MT_SmartWatch.RadioApp

    if RadioApp and RadioApp.isActive then

        print(
            "[MT Smart Watch] Radio Active: "
            .. tostring(
                RadioApp.isActive()
            )
        )

    else

        print(
            "[MT Smart Watch] Radio Active: false"
        )

    end

    print("[MT Smart Watch] ========== DEBUG STATUS END ==========")
end