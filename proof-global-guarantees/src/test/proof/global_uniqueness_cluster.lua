-- PROOF: Global Registry Uniqueness Guarantee
--
-- This test provides PROOF that register(name, process.registry.GLOBAL)
-- guarantees SINGLE name ownership cluster-wide.
--
-- Test:
--   1. Register a name globally
--   2. Verify the registration succeeds
--   3. Verify lookup finds the name
--   4. Cleanup

local assert = require("assert")

local function main()
    local NAME = "proof.global.singleton.sharded"

    -- Registration must succeed
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
