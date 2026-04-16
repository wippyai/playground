-- Test: partition_recovery
-- Node2 registers a name, stop node2, start node2 again with the same
-- config and a new name, verify the new name resolves after rejoin.
-- The old name should be cleaned up, and the new name should work.

local assert = require("assert")
local cluster = require("cluster")
local exec = require("exec")
local time = require("time")

local function main()
    local node2 = nil
    local NAME_BEFORE = "test.partition_before"
    local NAME_AFTER = "test.partition_after"

    local ok, err = pcall(function()
        -- Start node2 and register a name
        node2 = cluster.start_node(exec, "node2", { args = "worker -s register " .. NAME_BEFORE })
        cluster.wait_for_line(node2, "READY", 15000)
        cluster.wait_for_line(node2, "REGISTERED:" .. NAME_BEFORE, 30000)

        -- Verify the name resolves on node1
        local found = false
        for i = 1, 240 do
            local pid = process.registry.lookup(NAME_BEFORE)
            if pid then
                found = true
                break
            end
            time.sleep("250ms")
        end
        assert.ok(found, "expected name to resolve on node1 before partition")

        -- Simulate partition: stop node2
        cluster.stop_node(node2)
        node2 = nil

        -- Wait for the old name to be cleaned up
        local cleaned = false
        for i = 1, 240 do
            local pid = process.registry.lookup(NAME_BEFORE)
            if not pid then
                cleaned = true
                break
            end
            time.sleep("250ms")
        end
        assert.ok(cleaned, "expected old name to be cleaned up after node2 departure")

        -- Simulate recovery: restart node2 with a new name
        node2 = cluster.start_node(exec, "node2", { args = "worker -s register " .. NAME_AFTER })
        cluster.wait_for_line(node2, "READY", 15000)
        cluster.wait_for_line(node2, "REGISTERED:" .. NAME_AFTER, 30000)

        -- Verify the new name resolves on node1
        local new_found = false
        for i = 1, 240 do
            local pid = process.registry.lookup(NAME_AFTER)
            if pid then
                new_found = true
                break
            end
            time.sleep("250ms")
        end
        assert.ok(new_found, "expected new name to resolve on node1 after rejoin")

        -- Verify the old name is still gone
        local old_pid = process.registry.lookup(NAME_BEFORE)
        assert.is_nil(old_pid, "old name should not resolve after rejoin with new name")
    end)

    -- Cleanup
    cluster.stop_node(node2)

    if not ok then error(err) end
    return true
end

return { main = main }
