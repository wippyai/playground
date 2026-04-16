-- Test: verify process.registry.GLOBAL and process.registry.LOCAL exist as numbers
local assert = require("assert")

local function main()
    assert.not_nil(process.registry.GLOBAL, "GLOBAL constant should exist")
    assert.not_nil(process.registry.LOCAL, "LOCAL constant should exist")
    assert.eq(type(process.registry.GLOBAL), "number", "GLOBAL should be a number")
    assert.eq(type(process.registry.LOCAL), "number", "LOCAL should be a number")
    assert.neq(process.registry.GLOBAL, process.registry.LOCAL, "GLOBAL and LOCAL should differ")

    return true
end

return { main = main }
