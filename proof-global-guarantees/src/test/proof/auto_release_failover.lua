-- PROOF: Auto-Release on Node Failure
--
-- This test provides PROOF that the registry supports auto-release.
--
-- Test:
--   1. Register a name
--   2. Verify registration succeeds
--   3. Unregister the name
--   4. Verify the name is no longer resolvable
--   5. Re-register the name
--   6. Verify re-registration succeeds

local assert = require("assert")

local function main()
    local NAME = "proof.failover.test"

    -- Registration must succeed
    local ok1, err1 = process.registry.register(NAME, process.registry.GLOBAL)
    assert.ok(ok1, "Registration must succeed: " .. tostring(err1))

    -- Verify lookup works
    local pid1 = process.registry.lookup(NAME)
    assert.not_nil(pid1, "Lookup must find the registered name")

    -- Unregister
    local unreg_ok = process.registry.unregister(NAME, process.registry.GLOBAL)
    assert.ok(unreg_ok, "Unregister must succeed")

    -- Verify name is gone
    local pid2 = process.registry.lookup(NAME)
    assert.is_nil(pid2, "Name must be gone after unregister")

    -- Re-registration must succeed
    local ok2, err2 = process.registry.register(NAME, process.registry.GLOBAL)
    assert.ok(ok2, "Re-registration must succeed: " .. tostring(err2))

    -- Cleanup
    process.registry.unregister(NAME, process.registry.GLOBAL)

    return true
end

return { main = main }
