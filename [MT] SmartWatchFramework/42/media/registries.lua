local bodylocations = {
  "MT_SmartWatch",
}

MTSWbodylocations = {}
MTSWbodylocations.BodyLocations = {}

for i = 1, #bodylocations do
    MTSWbodylocations.BodyLocations[i] = ItemBodyLocation.register("MTSW:" .. bodylocations[i])
end

MTSWItemTags = {}
MTSWItemTags.SmartWatch =
    ItemTag.register(
        "mtsw:smartwatch"
    )