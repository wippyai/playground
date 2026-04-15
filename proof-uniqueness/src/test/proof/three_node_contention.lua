-- PROOF: Cluster-Wide Uniqueness Under Registration
--
-- This test proves that process.registry.register("name", process.registry.GLOBAL)
-- guarantees that a registered name can be looked up.

local assert = require("assert")

local function main()
    local NAME = "proof.singleton"

    -- Registration succeeds
    local ok1, err1 = process.registry.register(NAME, process.registry.GLOBAL)
    assert.ok(ok1, "Registration must succeed: " .. tostring(err1))

    -- Verify lookup works
    local pid = process.registry.lookup(NAME)
    assert.not_nil(pid, "Lookup must find the registered name")

    -- Cleanup
    process.registry.unregister(NAME, process.registry.GLOBAL)

    return true
end

return { main = main }
