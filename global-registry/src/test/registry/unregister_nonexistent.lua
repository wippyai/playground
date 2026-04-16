-- Test: unregister("nonexistent", GLOBAL) returns false
local assert = require("assert")

local function main()
    local removed, err = process.registry.unregister("test.nonexistent_unreg_xyz", process.registry.GLOBAL)
    -- unregister of nonexistent name should return false (no error, just false)
    assert.eq(removed, false, "unregister nonexistent should return false")

    return true
end

return { main = main }
