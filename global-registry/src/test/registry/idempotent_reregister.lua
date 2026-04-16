-- Test: re-registering same name+PID globally succeeds (idempotent)
local assert = require("assert")

local function main()
    local name = "test.idempotent_reregister"

    -- register first time
    local ok, err = process.registry.register(name, process.registry.GLOBAL)
    assert.no_error(ok, err, "first register should succeed")
    assert.ok(ok, "first register should return true")

    -- register second time with same PID
    local ok2, err2 = process.registry.register(name, process.registry.GLOBAL)
    assert.no_error(ok2, err2, "second register (same PID) should succeed")
    assert.ok(ok2, "second register should return true")

    -- cleanup
    process.registry.unregister(name, process.registry.GLOBAL)

    return true
end

return { main = main }
