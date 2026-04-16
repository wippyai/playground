-- Test: lookup("nonexistent") returns nil + error
local assert = require("assert")

local function main()
    local val, err = process.registry.lookup("test.nonexistent_name_xyz")
    assert.has_error(val, err, "lookup nonexistent should return nil+error")

    return true
end

return { main = main }
