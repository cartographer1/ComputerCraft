local inventory_util = require "inventory_util"
local moveItems = inventory_util.moveItems
local moveFluid = inventory_util.moveFluid

local function setup(srcName, destName, machineName, processFluid, itemOutputSlots, fluidOutputSlots)
    
    local machines = {
        occupied = {},
        free = {},
    }

    peripheral.find(machineName, function (name, _)
        machines.free[name] = true
    end)

    function machines.isOccupied(name)
        return machines.occupied[name] ~= nil
    end

    function machines.isFree(name)
        return machines.free[name] ~= nil
    end

    function machines.setOccupied(name)
        machines.free[name] = nil
        machines.occupied[name] = true

        print(string.format("%s Occupied", name))
    end

    function machines.setFree(name)
        machines.occupied[name] = nil
        machines.free[name] = true

        print(string.format("%s Freed", name))
    end

    function machines.getOccupied()
        return pairs(machines.occupied)
    end

    function machines.getFree()
        return pairs(machines.free)
    end
    
    local function isEmpty(name)
        local inv = peripheral.wrap(name)
        local no_items = next(inv.list()) == nil
        local no_fluid = true
        if processFluid then
            no_fluid = next(inv.tanks()) == nil
        end
    
        return no_items and no_fluid
    end

    local function transferAll(nameFrom, nameTo, fromSlots, fromSlotsFluid, pullMode)
        moveItems({srcName=nameFrom, destName=nameTo, fromSlots=fromSlots, pullMode=pullMode})
        if processFluid then
            moveFluid({srcName=nameFrom, destName=nameTo, slotsOrFluidNames=fromSlotsFluid, pullMode=pullMode})
        end
    end
    
    local function collectOutput()
        while true do
            for name in machines.getOccupied() do
                transferAll(name, destName, itemOutputSlots, fluidOutputSlots)
                print(string.format("Trying to extract from %s", name))
                if isEmpty(name) then
                    machines.setFree(name)
                    print("Success")
                end
            end

            sleep(0.25)
        end
    end

    local function distributeInput()
        while true do
            while not isEmpty(srcName) do
                local name = next(machines.free)
                if name == nil then
                    break
                end
                transferAll(srcName, name, nil, nil, true)
                machines.setOccupied(name)
                print(string.format("Tranferred ingredients to %s", name))
            end
            
            sleep(0.25)
        end
    end

    parallel.waitForAll(distributeInput, collectOutput)
end

return { setup=setup }
