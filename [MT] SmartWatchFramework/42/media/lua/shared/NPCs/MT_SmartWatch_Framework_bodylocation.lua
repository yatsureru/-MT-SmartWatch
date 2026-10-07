local group = BodyLocations.getGroup("Human")
for i = 1, #MTSWbodylocations.BodyLocations do
    group:getOrCreateLocation(MTSWbodylocations.BodyLocations[i])
end