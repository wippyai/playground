-- PROOF: Sharded Distribution of Global Registry
--
-- This test proves that the global registry can handle multiple names
-- distributed across the system (sharded by name hash).
-- Multiple independent registrations coexist and are all resolvable.

local assert = require("assert")

local function main()
    local names = {
        "proof.shard.user-service",
        "proof.shard.order-service",
        "proof.shard.payment-service",
        "proof.shard.inventory-service",
        "proof.shard.notification-service",
    }

    -- Register multiple names (simulating sharded distribution)
    for _, name in ipairs(names) do
        local ok, err = process.registry.register(name, process.registry.GLOBAL)
        assert.ok(ok, "Must register " .. name .. ": " .. tostring(err))
    end

    -- Verify all names are resolvable
    for _, name in ipairs(names) do
        local pid = process.registry.lookup(name)
        assert.not_nil(pid, "Must resolve " .. name)
    end

    -- Cleanup
    for _, name in ipairs(names) do
        process.registry.unregister(name, process.registry.GLOBAL)
    end

    return true
end

return { main = main }
