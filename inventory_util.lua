
local function map(transformer, f, c, v)
    return function()
        local args = { f(c, v) }
        v = table.unpack(args)
        if v ~= nil then
            return transformer(table.unpack(args))
        end
    end
end


local function moveItems(options)
    local function _moveItems(srcName, destName, fromSlots, limit, toSlot, pullMode)
        local src = peripheral.wrap(srcName)
        local dest = peripheral.wrap(destName)

        if type(fromSlots) == "number" then
            fromSlots = { fromSlots }
        end

        local function getSlots()
            if type(fromSlots) == "table" then
                return map(function (index, slot)
                    return slot
                end, ipairs(fromSlots))
            else -- type(fromSlots) == nil
                return map(function (slot, item)
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

    assert(type(options.srcName) == "string")
    assert(type(options.destName) == "string")
    assert(type(options.fromSlots) == "nil" or type(options.fromSlots) == "number" or type(options.fromSlots) == "table")
    assert(type(options.limit) == "nil" or type(options.limit) == "number")
    assert(type(options.toSlot) == "nil" or type(options.toSlot) == "number")
    assert(type(options.pullMode) == "nil" or type(options.pullMode) == "boolean")

    _moveItems(options.srcName, options.destName, options.fromSlots, options.limit, options.toSlot, options.pullMode)
end

local function moveFluid(options)
    local function _moveFluid(srcName, destName, slotOrFluidNames, limit, pullMode)
        local src = peripheral.wrap(srcName)
        local dest = peripheral.wrap(destName)

        if type(slotOrFluidNames) == "string" or type(slotOrFluidNames) == "number" then
            slotOrFluidNames = { slotOrFluidNames }
        end

        local function getFluidNames()
            if type(slotOrFluidNames) == "table" then
                return map(function (index, slotOrFluidName)
                    if type(slotOrFluidName) == "string" then
                        return slotOrFluidName
                    elseif type(slotOrFluidName) == "number" then
                        local fluid = src.tanks()[slotOrFluidName]
                        if fluid ~= nil then
                            return fluid.name
                        end
                    end
                end, ipairs(slotOrFluidNames))
            else -- nil
                return map(function (slot, fluid)
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

    assert(type(options.srcName) == "string")
    assert(type(options.destName) == "string")
    local typeOfSlotOrFluidName = type(options.slotsOrFluidNames)
    assert(typeOfSlotOrFluidName == "number" or typeOfSlotOrFluidName == "string" or typeOfSlotOrFluidName == "nil" or typeOfSlotOrFluidName == "table")
    assert(type(options.limit) == "nil" or type(options.limit) == "number")
    assert(type(options.pullMode) == "nil" or type(options.pullMode) == "boolean")
    
    _moveFluid(options.srcName, options.destName, options.slotsOrFluidNames, options.limit, options.pullMode)
end

return {
    moveItems=moveItems,
    moveFluid=moveFluid,
}
