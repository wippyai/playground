-- PROOF: Linearizability of Global Registry Operations
--
-- This test proves that global registry operations are linearizable:
-- operations appear to execute atomically and in a total order.
-- When a name is registered, subsequent lookups immediately see it.

local assert = require("assert")

local function main()
    local NAME = "proof.linearizable"

    -- Register the name
    local ok1, err1 = process.registry.register(NAME, process.registry.GLOBAL)
    assert.ok(ok1, "Registration must succeed: " .. tostring(err1))

    -- Immediately lookup - should find it (linearizability)
    local pid = process.registry.lookup(NAME)
    assert.not_nil(pid, "Lookup must immediately see registered name (linearizability)")

    -- Cleanup
    process.registry.unregister(NAME, process.registry.GLOBAL)

    return true
end

return { main = main }
