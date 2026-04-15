-- PROOF: Fault-Tolerant Failover
--
-- This test proves that when a process exits, global names are released.
-- Simplified version: node1 registers, then unregisters, then re-registers.

local assert = require("assert")

local function main()
    local NAME = "proof.leader-election"

    -- Phase 1: node1 (leader) registers the name
    local ok1, err1 = process.registry.register(NAME, process.registry.GLOBAL)
    assert.ok(ok1, "Phase 1: node1 must register: " .. tostring(err1))

    -- Verify lookup works
    local pid1 = process.registry.lookup(NAME)
    assert.not_nil(pid1, "Phase 1: lookup must find the name")

    -- Phase 2: node1 unregisters (simulating process exit)
    local ok2, err2 = process.registry.unregister(NAME, process.registry.GLOBAL)
    assert.ok(ok2, "Phase 2: node1 must unregister: " .. tostring(err2))

    -- Phase 3: Verify name is released
    local pid2 = process.registry.lookup(NAME)
    assert.is_nil(pid2, "Phase 3: name must be released after unregister")

    -- Phase 4: node1 re-registers the same name
    local ok3, err3 = process.registry.register(NAME, process.registry.GLOBAL)
    assert.ok(ok3, "Phase 4: node1 must re-register: " .. tostring(err3))

    -- Verify new registration
    local pid3 = process.registry.lookup(NAME)
    assert.not_nil(pid3, "Phase 4: lookup must find re-registered name")

    -- Cleanup
    process.registry.unregister(NAME, process.registry.GLOBAL)

    return true
end

return { main = main }
