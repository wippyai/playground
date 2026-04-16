-- Test: three_node_register
-- Start node2 and node3, each registers a unique global name.
-- Node1 also registers a name. Verify all 3 names resolve on node1.

local assert = require("assert")
local cluster = require("cluster")
local exec = require("exec")
local time = require("time")

local function main()
    local node2 = nil
    local node3 = nil
    local NAME1 = "test.three_node_1"
    local NAME2 = "test.three_node_2"
    local NAME3 = "test.three_node_3"

    local ok, err = pcall(function()
        -- Register name1 on node1
        local reg_ok, reg_err = process.registry.register(NAME1, process.registry.GLOBAL)
        assert.no_error(reg_ok, reg_err, "node1 register should succeed")

        -- Start node2 which registers name2
        node2 = cluster.start_node(exec, "node2", { args = "worker -s register " .. NAME2 })
        cluster.wait_for_line(node2, "READY", 15000)
        cluster.wait_for_line(node2, "REGISTERED:" .. NAME2, 30000)

        -- Start node3 which registers name3
        node3 = cluster.start_node(exec, "node3", { args = "worker -s register " .. NAME3 })
        cluster.wait_for_line(node3, "READY", 15000)
        cluster.wait_for_line(node3, "REGISTERED:" .. NAME3, 30000)

        -- Wait until all 3 names resolve on node1
        local all_found = false
        for i = 1, 240 do
            local pid1 = process.registry.lookup(NAME1)
            local pid2 = process.registry.lookup(NAME2)
            local pid3 = process.registry.lookup(NAME3)
            if pid1 and pid2 and pid3 then
                all_found = true
                break
            end
            time.sleep("250ms")
        end
        assert.ok(all_found, "expected all 3 global names to resolve on node1")

        -- Verify name2 PID references node2
        local pid2 = process.registry.lookup(NAME2)
        assert.ok(
            string.find(tostring(pid2), "node2", 1, true),
            "name2 PID should reference node2, got: " .. tostring(pid2)
        )

        -- Verify name3 PID references node3
        local pid3 = process.registry.lookup(NAME3)
        assert.ok(
            string.find(tostring(pid3), "node3", 1, true),
            "name3 PID should reference node3, got: " .. tostring(pid3)
        )

        -- Cleanup node1 registration
        process.registry.unregister(NAME1, process.registry.GLOBAL)
    end)

    -- Cleanup
    cluster.stop_node(node3)
    cluster.stop_node(node2)
    pcall(function() process.registry.unregister(NAME1, process.registry.GLOBAL) end)

    if not ok then error(err) end
    return true
end

return { main = main }
