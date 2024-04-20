-- functional programming with lua iterators

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

return {
    map=map,
}