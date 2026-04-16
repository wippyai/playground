-- Test: register_conflict_cross_node
-- Node1 registers "svc" globally. Start node2, node2 tries to register
-- the same name — should get a conflict error.

local assert = require("assert")
local cluster = require("cluster")
local exec = require("exec")
local time = require("time")

local function main()
    local node2 = nil
    local NAME = "test.conflict_cross"

    local ok, err = pcall(function()
        -- Register the name on node1 first
        local reg_ok, reg_err = process.registry.register(NAME, process.registry.GLOBAL)
        assert.no_error(reg_ok, reg_err, "node1 global register should succeed")
        assert.ok(reg_ok, "node1 global register should return true")

        -- Start node2 which will try to register the same name
        node2 = cluster.start_node(exec, "node2", { args = "worker -s register " .. NAME })

        -- Wait for node2 worker to be ready
        cluster.wait_for_line(node2, "READY", 15000)

        -- Node2 should report a registration failure (conflict)
        local line = cluster.wait_for_line(node2, "REGISTER", 30000)
        assert.ok(
            string.find(line, "REGISTER_FAILED", 1, true),
            "expected REGISTER_FAILED from node2, got: " .. line
        )

        -- Verify name still resolves to node1's PID
        local pid, lerr = process.registry.lookup(NAME)
        assert.no_error(pid, lerr, "lookup should still succeed")
        assert.eq(pid, process.pid(), "lookup should return node1's PID")

        -- Cleanup: unregister from node1
        process.registry.unregister(NAME, process.registry.GLOBAL)
    end)

    -- Cleanup
    cluster.stop_node(node2)

    -- Also cleanup registration in case pcall failed before unregister
    pcall(function() process.registry.unregister(NAME, process.registry.GLOBAL) end)

    if not ok then error(err) end
    return true
end

return { main = main }
