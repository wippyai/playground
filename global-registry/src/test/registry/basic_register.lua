-- Test: register with GLOBAL, verify lookup, unregister, verify lookup fails
local assert = require("assert")

local function main()
    local name = "test.basic_register"

    -- register globally
    local ok, err = process.registry.register(name, process.registry.GLOBAL)
    assert.no_error(ok, err, "global register should succeed")
    assert.ok(ok, "global register should return true")

    -- lookup should return our PID
    local pid, lerr = process.registry.lookup(name)
    assert.no_error(pid, lerr, "lookup after register should succeed")
    assert.eq(pid, process.pid(), "lookup should return self PID")

    -- unregister
    local removed, uerr = process.registry.unregister(name, process.registry.GLOBAL)
    assert.no_error(removed, uerr, "global unregister should succeed")
    assert.ok(removed, "unregister should return true")

    -- lookup should now fail
    local val, err2 = process.registry.lookup(name)
    assert.has_error(val, err2, "lookup after unregister should fail")

    return true
end

return { main = main }
