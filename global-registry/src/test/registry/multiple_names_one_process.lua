-- Test: single process registers 3 different global names, all lookups work
local assert = require("assert")

local function main()
    local names = {
        "test.multi_name_1",
        "test.multi_name_2",
        "test.multi_name_3",
    }
    local my_pid = process.pid()

    -- register all 3 names
    for _, name in ipairs(names) do
        local ok, err = process.registry.register(name, process.registry.GLOBAL)
        assert.no_error(ok, err, "register " .. name .. " should succeed")
        assert.ok(ok, "register " .. name .. " should return true")
    end

    -- verify all 3 resolve to our PID
    for _, name in ipairs(names) do
        local pid, lerr = process.registry.lookup(name)
        assert.no_error(pid, lerr, "lookup " .. name .. " should succeed")
        assert.eq(pid, my_pid, "lookup " .. name .. " should return self PID")
    end

    -- cleanup
    for _, name in ipairs(names) do
        process.registry.unregister(name, process.registry.GLOBAL)
    end

    return true
end

return { main = main }
