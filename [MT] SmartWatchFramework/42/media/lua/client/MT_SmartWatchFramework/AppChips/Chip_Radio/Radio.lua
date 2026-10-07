--------------------------------------------------
-- MT SMART WATCH
-- RADIO APP CHIP
--------------------------------------------------

require "RadioCom/ISRadioWindow"


--------------------------------------------------
-- NAMESPACE
--------------------------------------------------

MT_SmartWatch = MT_SmartWatch or {}

MT_SmartWatch.RadioApp =
    MT_SmartWatch.RadioApp or {}

local RadioApp =
    MT_SmartWatch.RadioApp


--------------------------------------------------
-- CHIP
--------------------------------------------------

RadioApp.FULL_TYPE =
    "Base.MTSW_AChip_Radio"


--------------------------------------------------
-- STATE
--------------------------------------------------

RadioApp.Active =
    false

RadioApp.Window =
    nil

RadioApp.Device =
    nil

RadioApp.Watch =
    nil


--------------------------------------------------
-- CREATE VIRTUAL RADIO
--------------------------------------------------

function RadioApp.createDevice()

    --------------------------------------------------
    -- B42 RADIO TYPES
    --------------------------------------------------

    local candidates = {

        "Base.RadioRed",

        "Base.WalkieTalkie4",

        "Base.WalkieTalkie3",

        "Base.WalkieTalkie2",

        "Base.WalkieTalkie1",

    }


    --------------------------------------------------
    -- TRY EACH TYPE
    --------------------------------------------------

    for i = 1, #candidates do

        local fullType =
            candidates[i]


        local device =
            nil


        --------------------------------------------------
        -- INSTANCE ITEM
        --------------------------------------------------

        if type(instanceItem) == "function" then

            device =
                instanceItem(
                    fullType
                )

        end


        --------------------------------------------------
        -- FACTORY FALLBACK
        --------------------------------------------------

        if not device
            and InventoryItemFactory
            and InventoryItemFactory.CreateItem then

            device =
                InventoryItemFactory.CreateItem(
                    fullType
                )

        end


        --------------------------------------------------
        -- VALIDATE
        --------------------------------------------------

        if device then

            print(
                "[MT Smart Watch] "
                .. "RadioApp: Created "
                .. tostring(
                    fullType
                )
            )


            print(
                "[MT Smart Watch] "
                .. "RadioApp: Device class = "
                .. tostring(
                    typeof(device)
                )
            )


            --------------------------------------------------
            -- RADIO CHECK
            --------------------------------------------------

            if instanceof(
                device,
                "Radio"
            ) then

                local data =
                    device:getDeviceData()


                if data then

                    --------------------------------------------------
                    -- NAME
                    --------------------------------------------------

                    if data.setDeviceName then

                        data:setDeviceName(
                            "Smart Watch Radio"
                        )

                    end


                    --------------------------------------------------
                    -- POWER
                    --------------------------------------------------

                    if data.setInitialPower then

                        data:setInitialPower()

                    end


                    if data.setPower then

                        data:setPower(
                            1.0
                        )

                    end


                    if data.setIsTurnedOn then

                        data:setIsTurnedOn(
                            true
                        )

                    end


                    print(
                        "[MT Smart Watch] "
                        .. "RadioApp: Virtual Radio ready"
                    )


                    return device

                end

            end

        end

    end


    print(
        "[MT Smart Watch] "
        .. "RadioApp ERROR: "
        .. "Could not create virtual radio"
    )


    return nil

end


--------------------------------------------------
-- RADIO WINDOW
--------------------------------------------------

local RadioWindow =
    ISRadioWindow:derive(
        "MTSW_RadioWindow"
    )


--------------------------------------------------
-- NEW
--------------------------------------------------

function RadioWindow:new(
    x,
    y,
    width,
    height,
    player
)

    local o =
        ISRadioWindow.new(
            self,
            x,
            y,
            width,
            height,
            player
        )


    return o

end


--------------------------------------------------
-- UPDATE
--------------------------------------------------

function RadioWindow:update()

    --------------------------------------------------
    -- BASE COLLAPSABLE WINDOW
    --------------------------------------------------

    ISCollapsableWindow.update(
        self
    )


    --------------------------------------------------
    -- APP STATE
    --------------------------------------------------

    if not RadioApp.Active then
        return
    end


    --------------------------------------------------
    -- PLAYER
    --------------------------------------------------

    local player =
        self.player


    if not player then

        RadioApp.close()

        return

    end


    --------------------------------------------------
    -- WATCH
    --------------------------------------------------

    local Watch =
        MT_SmartWatch.Watch


    if not Watch then

        RadioApp.close()

        return

    end


    local watch =
        Watch.getEquippedWatch(
            player
        )


    if not watch then

        RadioApp.close()

        return

    end


    --------------------------------------------------
    -- CHIP
    --------------------------------------------------

    local ChipSystem =
        MT_SmartWatch.ChipSystem


    if not ChipSystem then

        RadioApp.close()

        return

    end


    if not ChipSystem.hasChip(
        watch,
        RadioApp.FULL_TYPE
    ) then

        RadioApp.close()

        return

    end


    --------------------------------------------------
    -- BATTERY
    --------------------------------------------------

    local Battery =
        MT_SmartWatch.Battery


    if not Battery then

        RadioApp.close()

        return

    end


    Battery.initialize(
        watch
    )


    if Battery.isEmpty(
        watch
    ) then

        RadioApp.close()

        return

    end

end


--------------------------------------------------
-- CLOSE WINDOW
--------------------------------------------------

function RadioWindow:close()

    local watch =
        RadioApp.Watch


    --------------------------------------------------
    -- RADIO POWER OFF
    --------------------------------------------------

    if self.deviceData
        and self.deviceData.setIsTurnedOn then

        self.deviceData:setIsTurnedOn(
            false
        )

    end


    --------------------------------------------------
    -- CHIP INACTIVE
    --------------------------------------------------

    if watch
        and MT_SmartWatch.ChipSystem then

        MT_SmartWatch.ChipSystem.setChipActive(
            watch,
            RadioApp.FULL_TYPE,
            false
        )

    end


    --------------------------------------------------
    -- RESET APP
    --------------------------------------------------

    RadioApp.Active =
        false

    RadioApp.Window =
        nil

    RadioApp.Device =
        nil

    RadioApp.Watch =
        nil


    --------------------------------------------------
    -- VANILLA CLOSE
    --------------------------------------------------

    ISRadioWindow.close(
        self
    )

end


--------------------------------------------------
-- OPEN
--------------------------------------------------

function RadioApp.open()

    --------------------------------------------------
    -- ALREADY OPEN
    --------------------------------------------------

    if RadioApp.Active
        and RadioApp.Window then

        return true

    end


    --------------------------------------------------
    -- PLAYER
    --------------------------------------------------

    local player =
        getPlayer()


    if not player then

        print(
            "[MT Smart Watch] "
            .. "RadioApp: Player missing"
        )

        return false

    end


    --------------------------------------------------
    -- WATCH
    --------------------------------------------------

    local Watch =
        MT_SmartWatch.Watch


    if not Watch then
        return false
    end


    local watch =
        Watch.getEquippedWatch(
            player
        )


    if not watch then

        print(
            "[MT Smart Watch] "
            .. "RadioApp: Watch not equipped"
        )

        return false

    end


    --------------------------------------------------
    -- CHIP
    --------------------------------------------------

    local ChipSystem =
        MT_SmartWatch.ChipSystem


    if not ChipSystem then
        return false
    end


    if not ChipSystem.hasChip(
        watch,
        RadioApp.FULL_TYPE
    ) then

        print(
            "[MT Smart Watch] "
            .. "RadioApp: Radio Chip not installed"
        )

        return false

    end


    --------------------------------------------------
    -- BATTERY
    --------------------------------------------------

    local Battery =
        MT_SmartWatch.Battery


    if not Battery then
        return false
    end


    Battery.initialize(
        watch
    )


    if Battery.isEmpty(
        watch
    ) then

        print(
            "[MT Smart Watch] "
            .. "RadioApp: Battery empty"
        )

        return false

    end


    --------------------------------------------------
    -- CREATE VIRTUAL DEVICE
    --------------------------------------------------

    local device =
        RadioApp.createDevice()


    if not device then
        return false
    end


    --------------------------------------------------
    -- WINDOW SIZE
    --------------------------------------------------

    local width =
        250


    if getCore()
        and getCore().getOptionFontSizeReal then

        width =
            width
            + (
                getCore():getOptionFontSizeReal()
                * 50
            )

    end


    local height =
        500


    --------------------------------------------------
    -- WINDOW
    --------------------------------------------------

    local window =
        RadioWindow:new(
            100,
            100,
            width,
            height,
            player
        )


    window:initialise()

    window:instantiate()


    --------------------------------------------------
    -- READ DEVICE
    --------------------------------------------------

    window:readFromObject(
        player,
        device
    )


    if not window.deviceData then

        print(
            "[MT Smart Watch] "
            .. "RadioApp ERROR: "
            .. "DeviceData initialization failed"
        )


        window:close()

        return false

    end


    --------------------------------------------------
    -- STATE
    --------------------------------------------------

    RadioApp.Device =
        device

    RadioApp.Window =
        window

    RadioApp.Watch =
        watch

    RadioApp.Active =
        true


    --------------------------------------------------
    -- CHIP ACTIVE
    --------------------------------------------------

    ChipSystem.setChipActive(
        watch,
        RadioApp.FULL_TYPE,
        true
    )


    --------------------------------------------------
    -- UI
    --------------------------------------------------

    window:addToUIManager()

    window:setVisible(
        true
    )


    print(
        "[MT Smart Watch] "
        .. "RadioApp: OPEN"
    )


    print(
        "[MT Smart Watch] "
        .. "RadioApp: Battery drain ACTIVE"
    )


    return true

end


--------------------------------------------------
-- CLOSE APP
--------------------------------------------------

function RadioApp.close()

    local window =
        RadioApp.Window


    if window then

        window:close()

        return

    end


    RadioApp.Active =
        false


    local watch =
        RadioApp.Watch


    if watch
        and MT_SmartWatch.ChipSystem then

        MT_SmartWatch.ChipSystem.setChipActive(
            watch,
            RadioApp.FULL_TYPE,
            false
        )

    end


end


--------------------------------------------------
-- IS ACTIVE
--------------------------------------------------

function RadioApp.isActive()

    return
        RadioApp.Active
        == true

end


--------------------------------------------------
-- START
--------------------------------------------------

function RadioApp.start()

    RadioApp.Active =
        false

    RadioApp.Window =
        nil

    RadioApp.Device =
        nil

    RadioApp.Watch =
        nil


    print(
        "[MT Smart Watch] "
        .. "RadioApp: Client system started"
    )

end


--------------------------------------------------
-- EVENTS
--------------------------------------------------

Events.OnGameStart.Add(
    RadioApp.start
)


--------------------------------------------------
-- LOADED
--------------------------------------------------

print(
    "[MT Smart Watch] "
    .. "Radio.lua loaded"
)