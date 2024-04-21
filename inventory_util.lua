-- http://raw.githubusercontent.com/cartographer1/ComputerCraft/main/inventory_util.lua

local function update(name, url)
    shell.run(string.format("rm %s.lua", name))
    local result = shell.run(string.format("wget %s", url))
    assert(result, "Download Failed!")
end

update("functional", "http://raw.githubusercontent.com/cartographer1/ComputerCraft/main/functional.lua")

local expect_mod = require "cc.expect"
local expect, field = expect_mod.expect, expect_mod.field

local functional = require("functional")
local map = functional.map

local function moveItems(options)
    local function _moveItems(srcName, destName, fromSlots, slotFilter, itemFilter, limit, toSlot, pullMode)
        local src = peripheral.wrap(srcName)
        local dest = peripheral.wrap(destName)

        if type(fromSlots) == "number" then
            fromSlots = { fromSlots }
        end

        local function getSlots()
            if type(fromSlots) == "table" then
                return map(function (_, slot)
                    if slotFilter and not slotFilter(slot) then
                        return
                    end
                    local name = src.list()[slot]
                    if itemFilter and not itemFilter(name) then
                        return
                    end

                    return slot
                end, ipairs(fromSlots))
            else -- type(fromSlots) == nil
                return map(function (slot, item)
                    if slotFilter and not slotFilter(slot) then
                        return
                    end
                    local name = item.name
                    if itemFilter and not itemFilter(name) then
                        return
                    end

                    return slot
                end, pairs(src.list()))
            end
        end

        for slot in getSlots() do
            if pullMode then
                dest.pullItems(srcName, slot, limit, toSlot)
            else
                src.pushItems(destName, slot, limit, toSlot)
            end
        end
    end

    field(options, "srcName", "string")
    field(options, "destName", "string")
    field(options, "fromSlots", "number", "table", "nil")
    field(options, "slotFilter", "function", "nil")
    field(options, "itemFilter", "function", "nil")
    field(options, "limit", "number", "nil")
    field(options, "toSlot", "number", "nil")
    field(options, "pullMode", "boolean", "nil")

    _moveItems(options.srcName, options.destName, options.fromSlots, options.slotFilter, options.itemFilter, options.limit, options.toSlot, options.pullMode)
end

local function moveFluid(options)
    local function _moveFluid(srcName, destName, slotOrFluidNames, filter, limit, pullMode)
        local src = peripheral.wrap(srcName)
        local dest = peripheral.wrap(destName)

        if type(slotOrFluidNames) == "string" or type(slotOrFluidNames) == "number" then
            slotOrFluidNames = { slotOrFluidNames }
        end

        local function getFluidNames()
            if type(slotOrFluidNames) == "table" then
                return map(function (index, slotOrFluidName)
                    local fluidName
                    if type(slotOrFluidName) == "string" then
                        fluidName = slotOrFluidName
                    elseif type(slotOrFluidName) == "number" then
                        local fluid = src.tanks()[slotOrFluidName]
                        if fluid ~= nil then
                            fluidName = fluid.name
                        end
                    end

                    if filter and not filter(fluidName) then
                        return
                    end
                    return fluidName
                end, ipairs(slotOrFluidNames))
            else -- nil
                return map(function (slot, fluid)
                    if filter and not filter(fluid.name) then
                        return
                    end
                    return fluid.name
                end, pairs(src.tanks()))
            end
        end

        for fluidName in getFluidNames() do
            if pullMode then
                dest.pullFluid(srcName, limit, fluidName)
            else
                src.pushFluid(destName, limit, fluidName)
            end
        end
    end

    field(options, "srcName", "string")
    field(options, "destName", "string")
    field(options, "slotsOrFluidNames", "string", "number", "table", "nil")
    field(options, "filter", "function", "nil")
    field(options, "limit", "number", "nil")
    field(options, "pullMode", "boolean", "nil")
    
    _moveFluid(options.srcName, options.destName, options.slotsOrFluidNames, options.filter, options.limit, options.pullMode)
end

return {
    moveItems=moveItems,
    moveFluid=moveFluid,
}
