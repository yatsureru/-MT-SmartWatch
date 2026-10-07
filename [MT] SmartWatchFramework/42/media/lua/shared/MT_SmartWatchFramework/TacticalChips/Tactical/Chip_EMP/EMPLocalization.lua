--------------------------------------------------
-- MT SMART WATCH
-- EMP CHIP LOCALIZATION
--------------------------------------------------

MT_SmartWatch =
    MT_SmartWatch
    or {}


--------------------------------------------------
-- EMP NAMESPACE
--------------------------------------------------

MT_SmartWatch.TacticalEMP =
    MT_SmartWatch.TacticalEMP
    or {}


local EMP =
    MT_SmartWatch.TacticalEMP


--------------------------------------------------
-- LOCALIZATION NAMESPACE
--------------------------------------------------

EMP.Localization =
    EMP.Localization
    or {}


local Localization =
    EMP.Localization


--------------------------------------------------
-- TRANSLATION IDS
--------------------------------------------------

Localization.ObjectBlocked =
    "UI_MTSW_EMP_ObjectBlocked"


--------------------------------------------------
-- GET TEXT
--------------------------------------------------

function Localization.get(
    key
)

    if not key then
        return ""
    end

    return getText(
        key
    )
end


--------------------------------------------------
-- EMP OBJECT BLOCKED
--------------------------------------------------

function Localization.getObjectBlocked()

    return Localization.get(
        Localization.ObjectBlocked
    )
end


--------------------------------------------------
-- SPEECH COOLDOWN
--------------------------------------------------

local SPEECH_COOLDOWN_MS =
    1500

local lastSpeechTime =
    0


--------------------------------------------------
-- CHARACTER SPEECH
--------------------------------------------------

function Localization.sayObjectBlocked(
    player
)

    if not player then
        return
    end


    local now =
        getTimestampMs()


    if (
        now - lastSpeechTime
    ) < SPEECH_COOLDOWN_MS then

        return
    end


    local text =
        Localization.getObjectBlocked()


    if not text
        or text == "" then

        return
    end


    lastSpeechTime =
        now


    player:Say(
        text
    )
end


--------------------------------------------------
-- DEBUG
--------------------------------------------------

function Localization.debug()

    print(
        "[MT Smart Watch] EMP Localization loaded"
    )


    print(
        "[MT Smart Watch] EMP ObjectBlocked ID: "
        .. tostring(
            Localization.ObjectBlocked
        )
    )


    print(
        "[MT Smart Watch] EMP ObjectBlocked Text: "
        .. tostring(
            Localization.getObjectBlocked()
        )
    )
end


--------------------------------------------------
-- LOAD LOG
--------------------------------------------------

print(
    "[MT Smart Watch] EMP Localization loaded"
)