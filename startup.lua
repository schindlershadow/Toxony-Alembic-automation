local names = peripheral.getNames()
local alembic = peripheral.wrap("right")
local inputInventory = peripheral.wrap("top")
local outputInventory = peripheral.wrap("bottom")

local slot1Inputs = { "toxony:glass_vial", "toxony:redstone_solution", "minecraft:leather", "toxony:empty_oil_pot" }
local slot2Inputs = { "toxony:toxic_formula", "toxony:toxen", "#toxony:ingredients/poisonous" } 
local recipes = { {1, 1}, {3, 2}, {2, 3}, {2, 4} }

if type(outputInventory) == "nil" then
    outputInventory = peripheral.wrap("left")
end

if type(alembic) == "nil" then
    error("No alembic found. Please place an alembic on the right and try again.")
end

if type(inputInventory) == "nil" then
    error("No input inventory found. Please place an input inventory on the top and try again.")
end

if type(outputInventory) == "nil" then
    error("No output inventory found. Please place an output inventory on the bottom or left and try again.")
end

print("Alembic found: " .. peripheral.getName(alembic))
print("Input inventory found: " .. peripheral.getName(inputInventory))
print("Output inventory found: " .. peripheral.getName(outputInventory))

local prevInput = ""
local prevAlembic = ""
local prevOutput = ""

while true do
    ::continue::

    local inputItems = inputInventory.list()
    local alembicItems = alembic.list()
    local outputItems = outputInventory.list()

    local inputStr = textutils.serialize(inputItems)
    local alembicStr = textutils.serialize(alembicItems)
    local outputStr = textutils.serialize(outputItems)

    -- Only proceed if something changed in input, alembic, or output
    if inputStr == prevInput and alembicStr == prevAlembic and outputStr == prevOutput then
        os.sleep(1)
        goto continue
    end

    prevInput = inputStr
    prevAlembic = alembicStr
    prevOutput = outputStr

    for slot, item in pairs(alembicItems) do
        print("Slot " .. slot .. ": " .. item.name .. " x" .. item.count)
    end

    -- Try to fill blaze powder as before
    if alembicItems[3] == nil or alembicItems[3].count < 64 then
        for slot, item in pairs(inputItems) do
            if item.name == "minecraft:blaze_powder" and item.count > 0 then
                print("Filling Alembic Blaze Powder...")
                local amountToTransfer = math.min(item.count, 64 - (alembicItems[3] and alembicItems[3].count or 0))
                if amountToTransfer > 0 then
                    print("Transferring " .. amountToTransfer .. " blaze powder to alembic...")
                    alembic.pullItems(peripheral.getName(inputInventory), slot, amountToTransfer, 3)
                end
            end
        end
    end

    -- Try to find a valid recipe and fill slots
    local foundRecipe = false
    for _, recipe in ipairs(recipes) do
        local slot1Name = slot1Inputs[recipe[1]]
        local slot2Name = slot2Inputs[recipe[2]]

        local slot1Count = 0
        local slot2Count = 0

        -- Check alembic slot 1
        if alembicItems[1] and alembicItems[1].name == slot1Name then
            slot1Count = alembicItems[1].count
        end

        -- Check alembic slot 2
        if slot2Name == "#toxony:ingredients/poisonous" then
            if alembicItems[2] then
                local detail = alembic.getItemDetail(2)
                if detail and detail.tags and detail.tags["toxony:ingredients/poisonous"] then
                    slot2Count = alembicItems[2].count
                end
            end
        elseif alembicItems[2] and alembicItems[2].name == slot2Name then
            slot2Count = alembicItems[2].count
        end

        -- Check input inventory for slot 1 item
        for inputSlot, inputItem in pairs(inputItems) do
            if inputItem.name == slot1Name then
                slot1Count = slot1Count + inputItem.count
            end
        end

        -- Check input inventory for slot 2 item
        for inputSlot, inputItem in pairs(inputItems) do
            if slot2Name == "#toxony:ingredients/poisonous" then
                local detail = inputInventory.getItemDetail(inputSlot)
                if detail and detail.tags and detail.tags["toxony:ingredients/poisonous"] then
                    slot2Count = slot2Count + inputItem.count
                end
            elseif inputItem.name == slot2Name then
                slot2Count = slot2Count + inputItem.count
            end
        end

        -- Check output inventory for slot 1 item
        for outputSlot, outputItem in pairs(outputItems) do
            if outputItem.name == slot1Name then
                slot1Count = slot1Count + outputItem.count
            end
        end

        -- Check output inventory for slot 2 item
        for outputSlot, outputItem in pairs(outputItems) do
            if slot2Name == "#toxony:ingredients/poisonous" then
                local detail = outputInventory.getItemDetail(outputSlot)
                if detail and detail.tags and detail.tags["toxony:ingredients/poisonous"] then
                    slot2Count = slot2Count + outputItem.count
                end
            elseif outputItem.name == slot2Name then
                slot2Count = slot2Count + outputItem.count
            end
        end

        -- Slot 1: If wrong item or empty, move correct item in
        if not alembicItems[1] or alembicItems[1].name ~= slot1Name then
            if alembicItems[1] then
                print("Clearing unwanted item from alembic slot 1: " .. alembicItems[1].name)
                alembic.pushItems(peripheral.getName(outputInventory), 1)
            end
            -- Find and move correct item from inputInventory or outputInventory
            local moved = false
            for inputSlot, inputItem in pairs(inputItems) do
                if inputItem.name == slot1Name then
                    local amountToTransfer = math.min(inputItem.count, 64)
                    print("Moving " .. slot1Name .. " to alembic slot 1 from inputInventory")
                    alembic.pullItems(peripheral.getName(inputInventory), inputSlot, amountToTransfer, 1)
                    moved = true
                    break
                end
            end
            if not moved then
                for outputSlot, outputItem in pairs(outputItems) do
                    if outputItem.name == slot1Name then
                        local amountToTransfer = math.min(outputItem.count, 64)
                        print("Moving " .. slot1Name .. " to alembic slot 1 from outputInventory")
                        alembic.pullItems(peripheral.getName(outputInventory), outputSlot, amountToTransfer, 1)
                        break
                    end
                end
            end
        end

        -- Slot 2: If wrong item or empty, move correct item in
        local needsSlot2 = true
        if slot2Name == "#toxony:ingredients/poisonous" then
            if alembicItems[2] then
                local detail = alembic.getItemDetail(2)
                if detail and detail.tags and detail.tags["toxony:ingredients/poisonous"] then
                    needsSlot2 = false
                else
                    print("Clearing unwanted item from alembic slot 2: " .. alembicItems[2].name)
                    alembic.pushItems(peripheral.getName(outputInventory), 2)
                end
            end
        elseif alembicItems[2] and alembicItems[2].name == slot2Name then
            needsSlot2 = false
        else
            if alembicItems[2] then
                print("Clearing unwanted item from alembic slot 2: " .. alembicItems[2].name)
                alembic.pushItems(peripheral.getName(outputInventory), 2)
            end
        end

        if needsSlot2 then
            local moved = false
            for inputSlot, inputItem in pairs(inputItems) do
                if slot2Name == "#toxony:ingredients/poisonous" then
                    local detail = inputInventory.getItemDetail(inputSlot)
                    if detail and detail.tags and detail.tags["toxony:ingredients/poisonous"] then
                        local amountToTransfer = math.min(inputItem.count, 64)
                        print("Moving poisonous ingredient to alembic slot 2 from inputInventory")
                        alembic.pullItems(peripheral.getName(inputInventory), inputSlot, amountToTransfer, 2)
                        moved = true
                        break
                    end
                elseif inputItem.name == slot2Name then
                    local amountToTransfer = math.min(inputItem.count, 64)
                    print("Moving " .. slot2Name .. " to alembic slot 2 from inputInventory")
                    alembic.pullItems(peripheral.getName(inputInventory), inputSlot, amountToTransfer, 2)
                    moved = true
                    break
                end
            end
            if not moved then
                for outputSlot, outputItem in pairs(outputItems) do
                    if slot2Name == "#toxony:ingredients/poisonous" then
                        local detail = outputInventory.getItemDetail(outputSlot)
                        if detail and detail.tags and detail.tags["toxony:ingredients/poisonous"] then
                            local amountToTransfer = math.min(outputItem.count, 64)
                            print("Moving poisonous ingredient to alembic slot 2 from outputInventory")
                            alembic.pullItems(peripheral.getName(outputInventory), outputSlot, amountToTransfer, 2)
                            break
                        end
                    elseif outputItem.name == slot2Name then
                        local amountToTransfer = math.min(outputItem.count, 64)
                        print("Moving " .. slot2Name .. " to alembic slot 2 from outputInventory")
                        alembic.pullItems(peripheral.getName(outputInventory), outputSlot, amountToTransfer, 2)
                        break
                    end
                end
            end
        end

        -- Top up slot 2 if already correct
        if alembicItems[2] and (
            (slot2Name == "#toxony:ingredients/poisonous" and alembic.getItemDetail(2).tags and alembic.getItemDetail(2).tags["toxony:ingredients/poisonous"]) or
            (alembicItems[2].name == slot2Name)
        ) and alembicItems[2].count < 64 then
            for inputSlot, inputItem in pairs(inputItems) do
                if slot2Name == "#toxony:ingredients/poisonous" then
                    local detail = inputInventory.getItemDetail(inputSlot)
                    if detail and detail.tags and detail.tags["toxony:ingredients/poisonous"] then
                        local amountToTransfer = math.min(inputItem.count, 64 - alembicItems[2].count)
                        if amountToTransfer > 0 then
                            print("Topping up poisonous ingredient in alembic slot 2")
                            alembic.pullItems(peripheral.getName(inputInventory), inputSlot, amountToTransfer, 2)
                        end
                    end
                elseif inputItem.name == slot2Name then
                    local amountToTransfer = math.min(inputItem.count, 64 - alembicItems[2].count)
                    if amountToTransfer > 0 then
                        print("Topping up " .. slot2Name .. " in alembic slot 2")
                        alembic.pullItems(peripheral.getName(inputInventory), inputSlot, amountToTransfer, 2)
                    end
                end
            end
        end

        -- Slot 1 logic unchanged...

        break -- Only do one recipe at a time
    end
    -- If no recipe found, clear unwanted items from alembic slots 1 and 2
    if not foundRecipe then
        local keepSlot1 = false
        local keepSlot2 = false

        -- Check if alembic slots match any valid recipe
        for _, recipe in ipairs(recipes) do
            local slot1Name = slot1Inputs[recipe[1]]
            local slot2Name = slot2Inputs[recipe[2]]

            -- Slot 1 check
            if alembicItems[1] and alembicItems[1].name == slot1Name then
                keepSlot1 = true
            end

            -- Slot 2 check
            if slot2Name == "#toxony:ingredients/poisonous" then
                if alembicItems[2] then
                    local detail = alembic.getItemDetail(2)
                    if detail and detail.tags and detail.tags["toxony:ingredients/poisonous"] then
                        keepSlot2 = true
                    end
                end
            elseif alembicItems[2] and alembicItems[2].name == slot2Name then
                keepSlot2 = true
            end
        end

        if alembicItems[1] and not keepSlot1 then
            print("No valid recipe, clearing alembic slot 1: " .. alembicItems[1].name)
            alembic.pushItems(peripheral.getName(outputInventory), 1)
        end
        if alembicItems[2] and not keepSlot2 then
            print("No valid recipe, clearing alembic slot 2: " .. alembicItems[2].name)
            alembic.pushItems(peripheral.getName(outputInventory), 2)
        end
    end

    os.sleep(5)
end

