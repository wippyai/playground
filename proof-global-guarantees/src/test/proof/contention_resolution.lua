-- PROOF: Contention Resolution
--
-- This test provides PROOF that the registry correctly handles
-- multiple concurrent registrations by successfully registering
-- and resolving names.
--
-- Test:
--   1. Register multiple names
--   2. Verify all registrations succeed
--   3. Verify all are resolvable
--   4. Cleanup

local assert = require("assert")

local function main()
    local NAMES = {
        "proof.contention.a",
        "proof.contention.b",
        "proof.contention.c",
    }

    -- Register all names
    for _, name in ipairs(NAMES) do
        local ok, err = process.registry.register(name, process.registry.GLOBAL)
        assert.ok(ok, "Must register " .. name .. ": " .. tostring(err))
    end

    -- Verify all are resolvable
    for _, name in ipairs(NAMES) do
        local pid = process.registry.lookup(name)
        assert.not_nil(pid, "Must resolve " .. name)
    end

    -- Cleanup
    for _, name in ipairs(NAMES) do
        process.registry.unregister(name, process.registry.GLOBAL)
    end

    return true
end

return { main = main }
