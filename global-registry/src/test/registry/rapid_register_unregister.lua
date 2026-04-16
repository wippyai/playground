-- Test: register/unregister same name 50x in a loop, verify final state is clean
local assert = require("assert")

local function main()
    local name = "test.rapid_reg_unreg"
    local iterations = 50

    for i = 1, iterations do
        local ok, err = process.registry.register(name, process.registry.GLOBAL)
        assert.no_error(ok, err, "register iteration " .. i .. " should succeed")
        assert.ok(ok, "register iteration " .. i .. " should return true")

        local removed, uerr = process.registry.unregister(name, process.registry.GLOBAL)
        assert.no_error(removed, uerr, "unregister iteration " .. i .. " should succeed")
        assert.ok(removed, "unregister iteration " .. i .. " should return true")
    end

    -- verify final state is clean
    local val, err = process.registry.lookup(name)
    assert.has_error(val, err, "lookup after all unregisters should fail")

    return true
end

return { main = main }
