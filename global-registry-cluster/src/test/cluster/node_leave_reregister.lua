-- Test: node_leave_reregister
-- Start node2, node2 registers "svc", stop node2, wait for cleanup,
-- then node1 registers the same name — should succeed.

local assert = require("assert")
local cluster = require("cluster")
local exec = require("exec")
local time = require("time")

local function main()
    local node2 = nil
    local NAME = "test.leave_reregister"

    local ok, err = pcall(function()
        -- Start node2 which registers the name
        node2 = cluster.start_node(exec, "node2", { args = "worker -s register " .. NAME })

        -- Wait for node2 to be ready and register
        cluster.wait_for_line(node2, "READY", 15000)
        cluster.wait_for_line(node2, "REGISTERED:" .. NAME, 30000)

        -- Verify the name resolves on node1
        local found = false
        for i = 1, 240 do
            local pid = process.registry.lookup(NAME)
            if pid then
                found = true
                break
            end
            time.sleep("250ms")
        end
        assert.ok(found, "expected name to resolve on node1 before stopping node2")

        -- Stop node2
        cluster.stop_node(node2)
        node2 = nil

        -- Wait for name to be cleaned up
        local cleaned = false
        for i = 1, 240 do
            local pid = process.registry.lookup(NAME)
            if not pid then
                cleaned = true
                break
            end
            time.sleep("250ms")
        end
        assert.ok(cleaned, "expected name to be cleaned up after node2 departure")

        -- Now register the same name on node1
        local reg_ok, reg_err = process.registry.register(NAME, process.registry.GLOBAL)
        assert.no_error(reg_ok, reg_err, "node1 should be able to register after cleanup")
        assert.ok(reg_ok, "register should return true")

        -- Verify it resolves to node1's PID
        local pid, lerr = process.registry.lookup(NAME)
        assert.no_error(pid, lerr, "lookup should succeed")
        assert.eq(pid, process.pid(), "lookup should return node1's PID")

        -- Cleanup
        process.registry.unregister(NAME, process.registry.GLOBAL)
    end)

    -- Cleanup
    cluster.stop_node(node2)
    pcall(function() process.registry.unregister(NAME, process.registry.GLOBAL) end)

    if not ok then error(err) end
    return true
end

return { main = main }
