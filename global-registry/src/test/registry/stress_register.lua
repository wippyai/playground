-- Test: register 50 unique global names, verify all lookup, unregister all, verify all gone
local assert = require("assert")

local function main()
    local count = 50
    local base = "test.stress_reg."
    local my_pid = process.pid()

    -- register all
    for i = 1, count do
        local name = base .. i
        local ok, err = process.registry.register(name, process.registry.GLOBAL)
        assert.no_error(ok, err, "register " .. name .. " should succeed")
        assert.ok(ok, "register " .. name .. " should return true")
    end

    -- verify all lookup
    for i = 1, count do
        local name = base .. i
        local pid, lerr = process.registry.lookup(name)
        assert.no_error(pid, lerr, "lookup " .. name .. " should succeed")
        assert.eq(pid, my_pid, "lookup " .. name .. " should return self PID")
    end

    -- unregister all
    for i = 1, count do
        local name = base .. i
        local removed, uerr = process.registry.unregister(name, process.registry.GLOBAL)
        assert.no_error(removed, uerr, "unregister " .. name .. " should succeed")
        assert.ok(removed, "unregister " .. name .. " should return true")
    end

    -- verify all gone
    for i = 1, count do
        local name = base .. i
        local val, err = process.registry.lookup(name)
        assert.has_error(val, err, "lookup " .. name .. " after unregister should fail")
    end

    return true
end

return { main = main }
