-- Test: register_cross_node_lookup
-- Start node2, node2 registers "svc" globally, node1 polls until
-- lookup("svc") succeeds — verifying cross-node global name replication.

local assert = require("assert")
local cluster = require("cluster")
local exec = require("exec")
local time = require("time")

local function main()
    local node2 = nil
    local NAME = "test.cross_lookup"

    local ok, err = pcall(function()
        -- Start node2 which will register the name globally
        node2 = cluster.start_node(exec, "node2", { args = "worker -s register " .. NAME })

        -- Wait for node2 worker to be ready
        cluster.wait_for_line(node2, "READY", 15000)

        -- Wait for node2 to confirm registration
        cluster.wait_for_line(node2, "REGISTERED:" .. NAME, 30000)

        -- Poll lookup on node1 until the global name resolves
        local found = false
        local resolved_pid = nil
        for i = 1, 240 do
            local pid, lerr = process.registry.lookup(NAME)
            if pid then
                found = true
                resolved_pid = pid
                break
            end
            time.sleep("250ms")
        end

        assert.ok(found, "expected global name '" .. NAME .. "' to resolve on node1")
        assert.not_nil(resolved_pid, "resolved PID should not be nil")

        -- The PID should reference node2
        local pid_str = tostring(resolved_pid)
        assert.ok(
            string.find(pid_str, "node2", 1, true),
            "resolved PID should reference node2, got: " .. pid_str
        )
    end)

    -- Cleanup
    cluster.stop_node(node2)

    if not ok then error(err) end
    return true
end

return { main = main }
