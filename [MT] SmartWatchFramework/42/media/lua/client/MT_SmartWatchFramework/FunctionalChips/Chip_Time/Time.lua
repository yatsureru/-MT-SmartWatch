--------------------------------------------------
-- MT SMART WATCH
-- TIME FUNCTIONAL CHIP
--------------------------------------------------

require "ISUI/ISPanel"


--------------------------------------------------
-- NAMESPACE
--------------------------------------------------

MT_SmartWatch = MT_SmartWatch or {}

MT_SmartWatch.TimeHUD =
    MT_SmartWatch.TimeHUD or {}

local TimeHUD =
    MT_SmartWatch.TimeHUD


--------------------------------------------------
-- CHIP
--------------------------------------------------

TimeHUD.FULL_TYPE =
    "Base.MTSW_FChip_Time"


--------------------------------------------------
-- STATE
--------------------------------------------------

TimeHUD.Panel =
    TimeHUD.Panel or nil

TimeHUD.Active =
    false

TimeHUD.Hour =
    0

TimeHUD.Minute =
    0


--------------------------------------------------
-- PANEL
--------------------------------------------------

local HUDPanel =
    ISPanel:derive(
        "MTSW_TimeHUD"
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


    self.__index =
        self


    return o

end


--------------------------------------------------
-- INITIALISE
--------------------------------------------------

function HUDPanel:initialise()

    ISPanel.initialise(
        self
    )

end


--------------------------------------------------
-- POSITION
--------------------------------------------------

function TimeHUD.updatePosition()

    local panel =
        TimeHUD.Panel


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


    panel:setX(
        30
    )


    panel:setY(
        screenHeight - 155
    )

end


--------------------------------------------------
-- PRERENDER
--------------------------------------------------

function HUDPanel:prerender()

    if not TimeHUD.Active then
        return
    end


    local width =
        200


    local height =
        65


    --------------------------------------------------
    -- BACKGROUND
    --------------------------------------------------

    self:drawRect(
        0,
        0,
        width,
        height,
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
        width,
        height,
        0.8,
        0.7,
        0.7,
        0.7
    )


    --------------------------------------------------
    -- TITLE
    --------------------------------------------------

    self:drawText(
        "TIME",
        10,
        8,
        1,
        1,
        1,
        1,
        UIFont.Small
    )


    --------------------------------------------------
    -- VALUE
    --------------------------------------------------

    local hour =
        tonumber(
            TimeHUD.Hour
        )
        or 0


    local minute =
        tonumber(
            TimeHUD.Minute
        )
        or 0


    local text =
        string.format(
            "%02d:%02d",
            hour,
            minute
        )


    self:drawText(
        text,
        10,
        27,
        1,
        1,
        1,
        1,
        UIFont.Large
    )

end


--------------------------------------------------
-- CREATE
--------------------------------------------------

function TimeHUD.create()

    if TimeHUD.Panel then
        return TimeHUD.Panel
    end


    local panel =
        HUDPanel:new(
            30,
            30,
            200,
            65
        )


    panel:initialise()

    panel:addToUIManager()

    panel:setVisible(
        false
    )


    TimeHUD.Panel =
        panel


    print(
        "[MT Smart Watch] "
        .. "TimeHUD: Panel created"
    )


    return panel

end


--------------------------------------------------
-- UPDATE
--------------------------------------------------

function TimeHUD.update()

    local panel =
        TimeHUD.create()


    TimeHUD.Active =
        false


    panel:setVisible(
        false
    )


    --------------------------------------------------
    -- PLAYER
    --------------------------------------------------

    local player =
        getPlayer()


    if not player then
        return
    end


    --------------------------------------------------
    -- WATCH
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


    local watch =
        Watch.getEquippedWatch(
            player
        )


    if not watch then
        return
    end


    --------------------------------------------------
    -- CHIP
    --------------------------------------------------

    local ChipSystem =
        MT_SmartWatch.ChipSystem


    if type(ChipSystem) ~= "table" then
        return
    end


    if not ChipSystem.hasChip then
        return
    end


    if not ChipSystem.hasChip(
        watch,
        TimeHUD.FULL_TYPE
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


    if not Battery.initialize then
        return
    end


    Battery.initialize(
        watch
    )


    if Battery.isEmpty(
        watch
    ) then

        return

    end


    --------------------------------------------------
    -- GAME TIME
    --------------------------------------------------

    local gameTime =
        getGameTime()


    if not gameTime then
        return
    end


    local hour =
        gameTime:getHour()


    local minute =
        gameTime:getMinutes()


    if hour == nil
        or minute == nil then

        return

    end


    --------------------------------------------------
    -- CACHE
    --------------------------------------------------

    TimeHUD.Hour =
        hour

    TimeHUD.Minute =
        minute

    TimeHUD.Active =
        true


    TimeHUD.updatePosition()


    panel:setVisible(
        true
    )

end


--------------------------------------------------
-- START
--------------------------------------------------

function TimeHUD.start()

    print(
        "[MT Smart Watch] "
        .. "TimeHUD: Client system started"
    )


    TimeHUD.create()

end


--------------------------------------------------
-- EVENTS
--------------------------------------------------

Events.OnGameStart.Add(
    TimeHUD.start
)


Events.OnPlayerUpdate.Add(
    function()

        TimeHUD.update()

    end
)


--------------------------------------------------
-- LOADED
--------------------------------------------------

print(
    "[MT Smart Watch] "
    .. "Time.lua loaded"
)