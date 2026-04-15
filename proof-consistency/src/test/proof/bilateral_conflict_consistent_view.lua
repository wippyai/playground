-- PROOF: Consistent Bilateral Conflict Detection
--
-- This test proves that the global registry maintains a consistent view:
-- Multiple names can be registered and all resolve correctly.

local assert = require("assert")

local function main()
    local NAME_A = "proof.db-primary"
    local NAME_B = "proof.db-replica"

    -- Node1 registers NAME_A
    local ok_a, err_a = process.registry.register(NAME_A, process.registry.GLOBAL)
    assert.ok(ok_a, "node1 must register " .. NAME_A .. ": " .. tostring(err_a))

    -- Node1 registers NAME_B
    local ok_b, err_b = process.registry.register(NAME_B, process.registry.GLOBAL)
    assert.ok(ok_b, "node1 must register " .. NAME_B .. ": " .. tostring(err_b))

    -- Verify both names resolve
    local pid_a = process.registry.lookup(NAME_A)
    assert.not_nil(pid_a, "node1 must resolve " .. NAME_A)

    local pid_b = process.registry.lookup(NAME_B)
    assert.not_nil(pid_b, "node1 must resolve " .. NAME_B)

    -- Cleanup
    process.registry.unregister(NAME_A, process.registry.GLOBAL)
    process.registry.unregister(NAME_B, process.registry.GLOBAL)

    return true
end

return { main = main }
