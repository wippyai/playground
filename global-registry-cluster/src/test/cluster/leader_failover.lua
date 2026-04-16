-- Test: leader_failover
-- Register a global name on node1, start node2 and register on node2,
-- stop node2, verify node1's name still resolves, restart node2 with
-- a new name, verify both the old (node1) and new (node2) names resolve.

local assert = require("assert")
local cluster = require("cluster")
local exec = require("exec")
local time = require("time")

local function main()
    local node2 = nil
    local NAME1 = "test.failover_leader"
    local NAME2 = "test.failover_follower"
    local NAME3 = "test.failover_new"

    local ok, err = pcall(function()
        -- Register name1 on node1 (the leader)
        local reg_ok, reg_err = process.registry.register(NAME1, process.registry.GLOBAL)
        assert.no_error(reg_ok, reg_err, "node1 register should succeed")

        -- Start node2, register name2
        node2 = cluster.start_node(exec, "node2", { args = "worker -s register " .. NAME2 })
        cluster.wait_for_line(node2, "READY", 15000)
        cluster.wait_for_line(node2, "REGISTERED:" .. NAME2, 30000)

        -- Verify both names resolve on node1
        local found = false
        for i = 1, 240 do
            local pid1 = process.registry.lookup(NAME1)
            local pid2 = process.registry.lookup(NAME2)
            if pid1 and pid2 then
                found = true
                break
            end
            time.sleep("250ms")
        end
        assert.ok(found, "expected both names to resolve before stopping node2")

        -- Stop node2
        cluster.stop_node(node2)
        node2 = nil

        -- Wait for node2's name to be cleaned up
        local cleaned = false
        for i = 1, 240 do
            local pid2 = process.registry.lookup(NAME2)
            if not pid2 then
                cleaned = true
                break
            end
            time.sleep("250ms")
        end
        assert.ok(cleaned, "expected node2's name to be cleaned up")

        -- Node1's name should still resolve
        local pid1, lerr = process.registry.lookup(NAME1)
        assert.no_error(pid1, lerr, "node1's name should still resolve after node2 departure")
        assert.eq(pid1, process.pid(), "should resolve to node1's PID")

        -- Restart node2 with a new name
        node2 = cluster.start_node(exec, "node2", { args = "worker -s register " .. NAME3 })
        cluster.wait_for_line(node2, "READY", 15000)
        cluster.wait_for_line(node2, "REGISTERED:" .. NAME3, 30000)

        -- Verify both node1's original name and node2's new name resolve
        local both_found = false
        for i = 1, 240 do
            local p1 = process.registry.lookup(NAME1)
            local p3 = process.registry.lookup(NAME3)
            if p1 and p3 then
                both_found = true
                break
            end
            time.sleep("250ms")
        end
        assert.ok(both_found, "expected both names to resolve after node2 restart")

        -- Cleanup node1 registration
        process.registry.unregister(NAME1, process.registry.GLOBAL)
    end)

    -- Cleanup
    cluster.stop_node(node2)
    pcall(function() process.registry.unregister(NAME1, process.registry.GLOBAL) end)

    if not ok then error(err) end
    return true
end

return { main = main }
