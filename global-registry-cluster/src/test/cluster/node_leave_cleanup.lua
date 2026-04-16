-- Test: node_leave_cleanup
-- Start node2, node2 registers 2 global names, stop node2,
-- node1 polls until both names are gone — verifying cleanup on departure.

local assert = require("assert")
local cluster = require("cluster")
local exec = require("exec")
local time = require("time")

local function main()
    local node2 = nil
    local NAME1 = "test.leave_cleanup_a"
    local NAME2 = "test.leave_cleanup_b"

    local ok, err = pcall(function()
        -- Start node2 which will register 2 names
        node2 = cluster.start_node(exec, "node2", {
            args = "worker -s register_multi " .. NAME1 .. " " .. NAME2
        })

        -- Wait for node2 to be ready
        cluster.wait_for_line(node2, "READY", 15000)

        -- Wait for both registrations
        cluster.wait_for_line(node2, "REGISTERED:" .. NAME1, 30000)
        cluster.wait_for_line(node2, "REGISTERED:" .. NAME2, 30000)

        -- Verify both names resolve on node1
        local found_both = false
        for i = 1, 240 do
            local pid1 = process.registry.lookup(NAME1)
            local pid2 = process.registry.lookup(NAME2)
            if pid1 and pid2 then
                found_both = true
                break
            end
            time.sleep("250ms")
        end
        assert.ok(found_both, "expected both names to resolve on node1 before stopping node2")

        -- Stop node2 (graceful SIGTERM)
        cluster.stop_node(node2)
        node2 = nil -- Prevent double-stop in cleanup

        -- Poll until both names are cleaned up
        local cleaned = false
        for i = 1, 240 do
            local pid1 = process.registry.lookup(NAME1)
            local pid2 = process.registry.lookup(NAME2)
            if not pid1 and not pid2 then
                cleaned = true
                break
            end
            time.sleep("250ms")
        end
        assert.ok(cleaned, "expected both global names to be cleaned up after node2 departure")
    end)

    -- Cleanup
    cluster.stop_node(node2)

    if not ok then error(err) end
    return true
end

return { main = main }
