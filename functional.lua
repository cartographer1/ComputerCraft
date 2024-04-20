-- functional programming with lua iterators
-- http://raw.githubusercontent.com/cartographer1/ComputerCraft/main/functional.lua

local function map(mapf, f, c, v)
    local args, res, idx
    res = {}
    return function()
        local ret
        idx, ret = next(res, idx)
        while ret == nil do
          args = { f(c, v) }
          v = table.unpack(args)
          if v == nil then return end
          res = { mapf(table.unpack(args)) }
          idx = nil
          idx, ret = next(res, idx)
        end
        return ret
    end
end

local function unroll(f, c, v)
    v = f(c, v)
    if v ~= nil then
        return v, unroll(f, c, v)
    end
end

return {
    map=map,
    unroll=unroll,
}