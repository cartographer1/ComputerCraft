-- http://raw.githubusercontent.com/cartographer1/ComputerCraft/main/distributed_processing.lua

local function update(name, url)
    shell.run(string.format("rm %s.lua", name))
    local result = shell.run(string.format("wget %s", url))
    assert(result, "Download Failed!")
end

update("inventory_util", "http://raw.githubusercontent.com/cartographer1/ComputerCraft/main/inventory_util.lua")
-- update("functional", "http://raw.githubusercontent.com/cartographer1/ComputerCraft/main/functional.lua")

local inventory_util = require "inventory_util"
local functional = require "functional"
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

    local ignored_slots = {}
    local ignored_fluid = {}

    local function isEmpty(name)
        local inv = peripheral.wrap(name)

        local items = functional.map(function (slot, item)
            if not ignored_slots[slot] then
                return item.name
            end
        end, inv.list())
        local no_items = items() == nil

        local no_fluid = true
        if processFluid then
            local fluids = functional.map(function (_, fluid)
                if not ignored_fluid[fluid.name] then
                    return fluid.name
                end
            end, inv.tanks())
            no_fluid = fluids() == nil
        end

        return no_items and no_fluid
    end

    local function transferAll(nameFrom, nameTo, fromSlots, fromSlotsFluid, slotFilter, fluidFilter, pullMode)
        moveItems({srcName=nameFrom, destName=nameTo, fromSlots=fromSlots, slotFilter=slotFilter, pullMode=pullMode})
        if processFluid then
            moveFluid({srcName=nameFrom, destName=nameTo, slotsOrFluidNames=fromSlotsFluid, filter=fluidFilter, pullMode=pullMode})
        end
    end

    local machines = {
        occupied = {},
        free = {},
        counter = {}
    }

    peripheral.find(machineName, function (name, inv)
        machines.free[name] = true
        machines.counter[name] = 0
        transferAll(name, destName, itemOutputSlots, fluidOutputSlots)

        for slot, _ in pairs(inv.list()) do
            ignored_slots[slot] = true
        end

        if processFluid then
            for _, fluid in pairs(inv.tanks()) do
                ignored_fluid[fluid.name] = true
            end
        end
    end)

    function machines.isOccupied(name)
        return machines.occupied[name] ~= nil
    end

    function machines.isFree(name)
        return machines.free[name] ~= nil
    end

    function machines.setOccupied(name)
        machines.counter[name] = machines.counter[name] + 1
        machines.occupied[name] = true

        if machines.counter[name] == multiplexing then
            machines.free[name] = nil
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

    local function filterSlots(slot)
        return not ignored_slots[slot]
    end

    local function filterFluid(fluid)
        return not ignored_fluid[fluid]
    end
    
    local function collectOutput()
        while true do
            for name in machines.getOccupied() do
                transferAll(name, destName, itemOutputSlots, fluidOutputSlots, filterSlots, filterFluid)
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
                transferAll(srcName, name, nil, nil, nil, nil, true)
                machines.setOccupied(name)
                dbg(string.format("Tranferred ingredients to %s", name))
            end
            
            sleep(0.25)
        end
    end

    parallel.waitForAll(distributeInput, collectOutput)
end

return { setup=setup }