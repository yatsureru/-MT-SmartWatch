--------------------------------------------------
-- MT SMART WATCH
-- DEBUG KEY SYSTEM
--------------------------------------------------

local function onKeyPressed(key)

    --------------------------------------------------
    -- F1
    -- USE EMP
    --------------------------------------------------

    if key == Keyboard.KEY_F1 then

        print(
            "[MT Smart Watch] "
            .. "F1 USE EMP TACTICAL CHIP"
        )

        if MT_SmartWatch.Debug
            and MT_SmartWatch.Debug.testUseEMP then

            MT_SmartWatch.Debug.testUseEMP()

        end

    end


    --------------------------------------------------
    -- F3
    -- REMOVE EMP
    --------------------------------------------------

    if key == Keyboard.KEY_F3 then

        print(
            "[MT Smart Watch] "
            .. "F3 REMOVE EMP TACTICAL CHIP"
        )

        if MT_SmartWatch.Debug
            and MT_SmartWatch.Debug.testRemoveEMP then

            MT_SmartWatch.Debug.testRemoveEMP()

        end

    end


    --------------------------------------------------
    -- F4
    -- TACTICAL SLOTS TEST
    --------------------------------------------------

    if key == Keyboard.KEY_F4 then

        print(
            "[MT Smart Watch] "
            .. "F4 TACTICAL SLOTS TEST"
        )

        if MT_SmartWatch.Debug
            and MT_SmartWatch.Debug.testTacticalSlots then

            MT_SmartWatch.Debug.testTacticalSlots()

        end

    end




    --------------------------------------------------
    -- F5
    -- INSTALL EMP
    --------------------------------------------------

    if key == Keyboard.KEY_F5 then

        print(
            "[MT Smart Watch] "
            .. "F5 INSTALL EMP TACTICAL CHIP"
        )

        if MT_SmartWatch.Debug
            and MT_SmartWatch.Debug.testInstallEMP then

            MT_SmartWatch.Debug.testInstallEMP()

        end

    end


    --------------------------------------------------
    -- F10
    -- EMP STATUS
    --------------------------------------------------

    if key == Keyboard.KEY_F10 then

        print(
            "[MT Smart Watch] "
            .. "F10 EMP STATUS"
        )

        if MT_SmartWatch.Debug
            and MT_SmartWatch.Debug.testEMPStatus then

            MT_SmartWatch.Debug.testEMPStatus()

        end

    end


    --------------------------------------------------
    -- 9
    -- BATTERY
    --------------------------------------------------

    if key == Keyboard.KEY_9 then

        print(
            "[MT Smart Watch] "
            .. "9 BATTERY DRAIN TEST"
        )

        if MT_SmartWatch.Debug
            and MT_SmartWatch.Debug.testBatteryDrain then

            MT_SmartWatch.Debug.testBatteryDrain()

        end

    end


    --------------------------------------------------
    -- 8
    -- ALL SYSTEMS
    --------------------------------------------------

    if key == Keyboard.KEY_8 then

        print(
            "[MT Smart Watch] "
            .. "8 ALL SYSTEM TEST"
        )

        if MT_SmartWatch.Debug
            and MT_SmartWatch.Debug.testAllSystems then

            MT_SmartWatch.Debug.testAllSystems()

        end

    end


    --------------------------------------------------
    -- 7
    -- OPEN / CLOSE RADIO
    --------------------------------------------------

    if key == Keyboard.KEY_7 then

        print(
            "[MT Smart Watch] "
            .. "7 OPEN / CLOSE RADIO APP"
        )

        if MT_SmartWatch.Debug
            and MT_SmartWatch.Debug.testOpenRadio then

            MT_SmartWatch.Debug.testOpenRadio()

        end

    end


    --------------------------------------------------
    -- 6
    -- INSTALL RADIO CHIP
    --------------------------------------------------

    if key == Keyboard.KEY_6 then

        print(
            "[MT Smart Watch] "
            .. "6 INSTALL RADIO CHIP"
        )

        if MT_SmartWatch.Debug
            and MT_SmartWatch.Debug.testInstallRadioChip then

            MT_SmartWatch.Debug.testInstallRadioChip()

        end

    end


    --------------------------------------------------
    -- 5
    -- INSTALL TIME
    --------------------------------------------------

    if key == Keyboard.KEY_5 then

        print(
            "[MT Smart Watch] "
            .. "5 INSTALL TIME CHIP"
        )

        if MT_SmartWatch.Debug
            and MT_SmartWatch.Debug.testInstallTimeChip then

            MT_SmartWatch.Debug.testInstallTimeChip()

        end

    end


    --------------------------------------------------
    -- 4
    -- REMOVE TIME
    --------------------------------------------------

    if key == Keyboard.KEY_4 then

        print(
            "[MT Smart Watch] "
            .. "4 REMOVE TIME CHIP"
        )

        if MT_SmartWatch.Debug
            and MT_SmartWatch.Debug.testRemoveTimeChip then

            MT_SmartWatch.Debug.testRemoveTimeChip()

        end

    end


    --------------------------------------------------
    -- 3
    -- TACTICAL CORE
    --------------------------------------------------

    if key == Keyboard.KEY_3 then

        print(
            "[MT Smart Watch] "
            .. "3 INSTALL TACTICAL CORE"
        )

        if MT_SmartWatch.Debug
            and MT_SmartWatch.Debug.testInstallTacticalCore then

            MT_SmartWatch.Debug.testInstallTacticalCore()

        end

    end


    --------------------------------------------------
    -- 2
    -- REMOVE CORE
    --------------------------------------------------

    if key == Keyboard.KEY_2 then

        print(
            "[MT Smart Watch] "
            .. "2 REMOVE OS CORE"
        )

        if MT_SmartWatch.Debug
            and MT_SmartWatch.Debug.testRemoveOSCore then

            MT_SmartWatch.Debug.testRemoveOSCore()

        end

    end


    --------------------------------------------------
    -- 1
    -- LOGIC CORE
    --------------------------------------------------

    if key == Keyboard.KEY_1 then

        print(
            "[MT Smart Watch] "
            .. "1 INSTALL LOGIC CORE"
        )

        if MT_SmartWatch.Debug
            and MT_SmartWatch.Debug.testInstallLogicCore then

            MT_SmartWatch.Debug.testInstallLogicCore()

        end

    end


    --------------------------------------------------
    -- 0
    -- FULL WATCH TEST
    --------------------------------------------------

    if key == Keyboard.KEY_0 then

        print(
            "[MT Smart Watch] "
            .. "0 FULL WATCH TEST"
        )

        if MT_SmartWatch.Debug
            and MT_SmartWatch.Debug.testEquippedWatch then

            MT_SmartWatch.Debug.testEquippedWatch()

        end

    end

end


--------------------------------------------------
-- REGISTER
--------------------------------------------------

Events.OnKeyPressed.Add(
    onKeyPressed
)


--------------------------------------------------
-- LOADED
--------------------------------------------------

print(
    "[MT Smart Watch] "
    .. "DebugKey system loaded"
)
