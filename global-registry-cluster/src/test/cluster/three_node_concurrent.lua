-- Test: three_node_concurrent
-- Start node2 and node3, all 3 nodes try to register the same global name.
-- Exactly 1 should succeed; the other 2 should get conflicts.

local assert = require("assert")
local cluster = require("cluster")
local exec = require("exec")
local time = require("time")

local function main()
    local node2 = nil
    local node3 = nil
    local NAME = "test.concurrent_race"

    local ok, err = pcall(function()
        -- Start node2 and node3 which will each try to register the same name
        node2 = cluster.start_node(exec, "node2", { args = "worker -s register " .. NAME })
        node3 = cluster.start_node(exec, "node3", { args = "worker -s register " .. NAME })

        -- Wait for both to be ready
        cluster.wait_for_line(node2, "READY", 15000)
        cluster.wait_for_line(node3, "READY", 15000)

        -- Node1 also tries to register the same name
        -- Give nodes time to join raft and attempt registration
        time.sleep("3s")
        local node1_ok, node1_err = process.registry.register(NAME, process.registry.GLOBAL)

        -- Wait for node2 and node3 to report their registration outcome
        local line2 = cluster.wait_for_line(node2, "REGISTER", 30000)
        local line3 = cluster.wait_for_line(node3, "REGISTER", 30000)

        -- Count successes and failures
        local successes = 0
        local failures = 0

        if node1_ok then
            successes = successes + 1
        else
            failures = failures + 1
        end

        if string.find(line2, "REGISTERED:", 1, true) and not string.find(line2, "REGISTER_FAILED", 1, true) then
            successes = successes + 1
        else
            failures = failures + 1
        end

        if string.find(line3, "REGISTERED:", 1, true) and not string.find(line3, "REGISTER_FAILED", 1, true) then
            successes = successes + 1
        else
            failures = failures + 1
        end

        assert.eq(successes, 1,
            string.format("expected exactly 1 success, got %d (node1=%s, node2=%s, node3=%s)",
                successes, tostring(node1_ok), line2, line3))
        assert.eq(failures, 2, "expected exactly 2 failures")

        -- Verify the name resolves to exactly one PID
        local pid, lerr = process.registry.lookup(NAME)
        assert.not_nil(pid, "lookup should resolve to the single winner")

        -- Cleanup node1 registration if we won
        if node1_ok then
            process.registry.unregister(NAME, process.registry.GLOBAL)
        end
    end)

    -- Cleanup
    cluster.stop_node(node3)
    cluster.stop_node(node2)
    pcall(function() process.registry.unregister(NAME, process.registry.GLOBAL) end)

    if not ok then error(err) end
    return true
end

return { main = main }
