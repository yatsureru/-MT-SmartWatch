require "ISUI/ISPanel"


--------------------------------------------------
-- NAMESPACE
--------------------------------------------------

MT_SmartWatch = MT_SmartWatch or {}

MT_SmartWatch.StaminaHUD =
    MT_SmartWatch.StaminaHUD or {}

local StaminaHUD =
    MT_SmartWatch.StaminaHUD


--------------------------------------------------
-- CONSTANTS
--------------------------------------------------

StaminaHUD.FULL_TYPE =
    "Base.MTSW_FChip_StaminaHUD"


--------------------------------------------------
-- STATE
--------------------------------------------------

StaminaHUD.Panel =
    StaminaHUD.Panel or nil

StaminaHUD.Endurance =
    0

StaminaHUD.Percent =
    0

StaminaHUD.Active =
    false


--------------------------------------------------
-- PANEL CLASS
--------------------------------------------------

local HUDPanel =
    ISPanel:derive(
        "MTSW_StaminaHUD"
    )


--------------------------------------------------
-- NEW
--------------------------------------------------

function HUDPanel:new(
    x,
    y,
    width,
    height
)

    local o =
        ISPanel:new(
            x,
            y,
            width,
            height
        )

    setmetatable(
        o,
        self
    )

    self.__index = self

    return o

end


--------------------------------------------------
-- INITIALISE
--------------------------------------------------

function HUDPanel:initialise()

    ISPanel.initialise(self)

end


--------------------------------------------------
-- UPDATE POSITION
--------------------------------------------------

function StaminaHUD.updatePosition()

    local panel =
        StaminaHUD.Panel

    if not panel then
        return
    end

    local core =
        getCore()

    if not core then
        return
    end

    local screenHeight =
        core:getScreenHeight()

    panel:setX(30)

    panel:setY(
        screenHeight - 85
    )

end


--------------------------------------------------
-- PRERENDER
--------------------------------------------------

function HUDPanel:prerender()

    if not StaminaHUD.Active then
        return
    end


    --------------------------------------------------
    -- SIZE
    --------------------------------------------------

    local panelWidth = 180
    local panelHeight = 55

    local barX = 10
    local barY = 28

    local barWidth = 160
    local barHeight = 12


    --------------------------------------------------
    -- BACKGROUND
    --------------------------------------------------

    self:drawRect(
        0,
        0,
        panelWidth,
        panelHeight,
        0.65,
        0,
        0,
        0
    )


    --------------------------------------------------
    -- BORDER
    --------------------------------------------------

    self:drawRectBorder(
        0,
        0,
        panelWidth,
        panelHeight,
        0.8,
        0.7,
        0.7,
        0.7
    )


    --------------------------------------------------
    -- TITLE
    --------------------------------------------------

    self:drawText(
        "STAMINA",
        10,
        7,
        1,
        1,
        1,
        1,
        UIFont.Small
    )


    --------------------------------------------------
    -- PERCENT
    --------------------------------------------------

    self:drawText(
        tostring(
            StaminaHUD.Percent
        ) .. "%",
        125,
        7,
        1,
        1,
        1,
        1,
        UIFont.Small
    )


    --------------------------------------------------
    -- BAR BACKGROUND
    --------------------------------------------------

    self:drawRect(
        barX,
        barY,
        barWidth,
        barHeight,
        0.8,
        0.15,
        0.15,
        0.15
    )


    --------------------------------------------------
    -- BAR FILL
    --------------------------------------------------

    local fillWidth =
        barWidth
        * StaminaHUD.Endurance


    self:drawRect(
        barX,
        barY,
        fillWidth,
        barHeight,
        0.9,
        0.2,
        0.8,
        0.3
    )


    --------------------------------------------------
    -- BAR BORDER
    --------------------------------------------------

    self:drawRectBorder(
        barX,
        barY,
        barWidth,
        barHeight,
        0.9,
        0.8,
        0.8,
        0.8
    )

end


--------------------------------------------------
-- CREATE
--------------------------------------------------

function StaminaHUD.create()

    if StaminaHUD.Panel then
        return StaminaHUD.Panel
    end


    local panel =
        HUDPanel:new(
            30,
            30,
            180,
            55
        )


    panel:initialise()

    panel:addToUIManager()

    panel:setVisible(false)


    StaminaHUD.Panel =
        panel


    print(
        "[MT Smart Watch] StaminaHUD: "
        .. "Panel created"
    )


    return panel

end


--------------------------------------------------
-- UPDATE
--------------------------------------------------

function StaminaHUD.update()

    local panel =
        StaminaHUD.create()


    --------------------------------------------------
    -- DEFAULT STATE
    --------------------------------------------------

    StaminaHUD.Active =
        false

    panel:setVisible(false)


    --------------------------------------------------
    -- PLAYER
    --------------------------------------------------

    local player =
        getPlayer()

    if not player then
        return
    end


    --------------------------------------------------
    -- WATCH SYSTEM
    --------------------------------------------------

    local Watch =
        MT_SmartWatch
        and MT_SmartWatch.Watch

    if type(Watch) ~= "table" then
        return
    end

    if type(
        Watch.getEquippedWatch
    ) ~= "function" then
        return
    end


    --------------------------------------------------
    -- EQUIPPED WATCH
    --------------------------------------------------

    local watch =
        Watch.getEquippedWatch(
            player
        )

    if not watch then
        return
    end


    --------------------------------------------------
    -- CHIP SYSTEM
    --------------------------------------------------

    local ChipSystem =
        MT_SmartWatch.ChipSystem

    if type(ChipSystem) ~= "table" then
        return
    end

    if type(
        ChipSystem.hasChip
    ) ~= "function" then
        return
    end


    if not ChipSystem.hasChip(
        watch,
        StaminaHUD.FULL_TYPE
    ) then

        return

    end


    --------------------------------------------------
    -- BATTERY
    --------------------------------------------------

    local Battery =
        MT_SmartWatch.Battery

    if type(Battery) ~= "table" then
        return
    end

    if type(
        Battery.isEmpty
    ) ~= "function" then
        return
    end


    if Battery.isEmpty(
        watch
    ) then

        return

    end


    --------------------------------------------------
    -- STATS
    --------------------------------------------------

    local stats =
        player:getStats()

    if not stats then
        return
    end


    --------------------------------------------------
    -- CHARACTER STAT API
    --------------------------------------------------

    if not CharacterStat then

        print(
            "[MT Smart Watch] StaminaHUD ERROR: "
            .. "CharacterStat is nil"
        )

        return

    end


    if not CharacterStat.ENDURANCE then

        print(
            "[MT Smart Watch] StaminaHUD ERROR: "
            .. "CharacterStat.ENDURANCE is nil"
        )

        return

    end


    if not stats.get then

        print(
            "[MT Smart Watch] StaminaHUD ERROR: "
            .. "Stats:get() is nil"
        )

        return

    end


    --------------------------------------------------
    -- ENDURANCE
    --------------------------------------------------

    local endurance =
        stats:get(
            CharacterStat.ENDURANCE
        )


    if endurance == nil then

        print(
            "[MT Smart Watch] StaminaHUD ERROR: "
            .. "Endurance value is nil"
        )

        return

    end


    --------------------------------------------------
    -- CLAMP
    --------------------------------------------------

    endurance =
        math.max(
            0,
            math.min(
                endurance,
                1
            )
        )


    --------------------------------------------------
    -- PERCENT
    --------------------------------------------------

    local percent =
        math.floor(
            endurance * 100 + 0.5
        )


    --------------------------------------------------
    -- CACHE
    --------------------------------------------------

    StaminaHUD.Endurance =
        endurance

    StaminaHUD.Percent =
        percent

    StaminaHUD.Active =
        true


    --------------------------------------------------
    -- POSITION
    --------------------------------------------------

    StaminaHUD.updatePosition()


    --------------------------------------------------
    -- SHOW
    --------------------------------------------------

    panel:setVisible(true)

end


--------------------------------------------------
-- START
--------------------------------------------------

function StaminaHUD.start()

    print(
        "[MT Smart Watch] StaminaHUD: "
        .. "Client system started"
    )


    StaminaHUD.create()

end


--------------------------------------------------
-- EVENTS
--------------------------------------------------

Events.OnGameStart.Add(
    StaminaHUD.start
)


Events.OnPlayerUpdate.Add(
    function()

        StaminaHUD.update()

    end
)