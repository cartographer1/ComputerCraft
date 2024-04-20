-- http://raw.githubusercontent.com/cartographer1/ComputerCraft/main/distributed_processing.lua

local function update(name, url)
    shell.run(string.format("rm %s.lua", name))
    local result = shell.run(string.format("wget %s", url))
    assert(result, "Download Failed!")
end

update("inventory_util", "http://raw.githubusercontent.com/cartographer1/ComputerCraft/main/inventory_util.lua")

local inventory_util = require "inventory_util"
local moveItems = inventory_util.moveItems
local moveFluid = inventory_util.moveFluid

local function setup(srcName, destName, machineName, processFluid, itemOutputSlots, fluidOutputSlots, multiplexing)

    if not multiplexing then
        multiplexing = 1
    end

    local function dbg(...)
        if DEBUG then
            print(...)
        end
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

    local machines = {
        occupied = {},
        free = {},
        counter = {}
    }

    peripheral.find(machineName, function (name, _)
        machines.free[name] = true
        machines.counter[name] = 0
        transferAll(name, destName, itemOutputSlots, fluidOutputSlots)
    end)

    function machines.isOccupied(name)
        return machines.occupied[name] ~= nil
    end

    function machines.isFree(name)
        return machines.free[name] ~= nil
    end

    function machines.setOccupied(name)
        machines.counter[name] = machines.counter[name] + 1

        if machines.counter[name] == multiplexing then
            machines.free[name] = nil
            machines.occupied[name] = true
        end

        dbg(string.format("%s Occupied", name))
    end

    function machines.setFree(name)
        machines.occupied[name] = nil
        machines.free[name] = true
        machines.counter[name] =  0

        dbg(string.format("%s Freed", name))
    end

    function machines.getOccupied()
        return pairs(machines.occupied)
    end

    function machines.getFree()
        return pairs(machines.free)
    end
    
    local function collectOutput()
        while true do
            for name in machines.getOccupied() do
                transferAll(name, destName, itemOutputSlots, fluidOutputSlots)
                dbg(string.format("Trying to extract from %s", name))
                if isEmpty(name) then
                    machines.setFree(name)
                    dbg("Success")
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
                dbg(string.format("Tranferred ingredients to %s", name))
            end
            
            sleep(0.25)
        end
    end

    parallel.waitForAll(distributeInput, collectOutput)
end

return { setup=setup }