MT_SmartWatch = MT_SmartWatch or {}

MT_SmartWatch.Watch =
    MT_SmartWatch.Watch or {}

local Watch =
    MT_SmartWatch.Watch


--------------------------------------------------
-- SMART WATCH TAG
--------------------------------------------------

local function getSmartWatchTag()

    if not MTSWItemTags then

        return nil

    end


    return MTSWItemTags.SmartWatch

end


--------------------------------------------------
-- CHECK SMART WATCH
--------------------------------------------------

function Watch.isSmartWatch(item)

    if not item then

        return false

    end


    local tag =
        getSmartWatchTag()


    if not tag then

        print(
            "[MT Smart Watch] Watch ERROR: "
            .. "Smart Watch ItemTag not found"
        )

        return false

    end


    if not item.hasTag then

        print(
            "[MT Smart Watch] Watch ERROR: "
            .. "InventoryItem.hasTag not found"
        )

        return false

    end


    return item:hasTag(tag)

end


--------------------------------------------------
-- GET EQUIPPED SMART WATCH
--------------------------------------------------

function Watch.getEquippedWatch(player)

    if not player then

        return nil

    end


    local wornItems =
        player:getWornItems()


    if not wornItems then

        return nil

    end


    for i = 0, wornItems:size() - 1 do

        local wornItem =
            wornItems:get(i)


        if wornItem then

            local item =
                wornItem:getItem()


            if item
                and Watch.isSmartWatch(item) then

                return item

            end

        end

    end


    return nil

end