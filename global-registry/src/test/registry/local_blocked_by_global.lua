-- Test: register "name" globally, try register("name") locally, fails because global exists
local assert = require("assert")

local function main()
    local name = "test.local_blocked_by_global"

    -- register globally
    local ok, err = process.registry.register(name, process.registry.GLOBAL)
    assert.no_error(ok, err, "global register should succeed")
    assert.ok(ok, "global register should return true")

    -- try local register of the same name (should fail)
    local val, lerr = process.registry.register(name, process.registry.LOCAL)
    assert.has_error(val, lerr, "local register should fail when global exists")

    -- cleanup
    process.registry.unregister(name, process.registry.GLOBAL)

    return true
end

return { main = main }
