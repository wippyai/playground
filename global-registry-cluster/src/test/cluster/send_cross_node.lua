-- Test: send_cross_node
-- Node2 registers "svc" globally, node1 sends a message via the registered
-- name, node2 receives and echoes it back via stdout.

local assert = require("assert")
local cluster = require("cluster")
local exec = require("exec")
local time = require("time")

local function main()
    local node2 = nil
    local NAME = "test.send_cross"

    local ok, err = pcall(function()
        -- Start node2 with register_echo action — registers and echoes messages
        node2 = cluster.start_node(exec, "node2", { args = "worker -s register_echo " .. NAME })

        -- Wait for node2 to be ready and register
        cluster.wait_for_line(node2, "READY", 15000)
        cluster.wait_for_line(node2, "REGISTERED:" .. NAME, 30000)

        -- Wait for name to resolve on node1
        local resolved_pid = nil
        for i = 1, 240 do
            local pid = process.registry.lookup(NAME)
            if pid then
                resolved_pid = pid
                break
            end
            time.sleep("250ms")
        end
        assert.not_nil(resolved_pid, "expected global name to resolve on node1")

        -- Send a message to the remote process via its PID
        process.send(resolved_pid, "inbox", "hello_cross_node")

        -- Wait for node2 to echo the message back via stdout
        local line = cluster.wait_for_line(node2, "MSG_RECV:", 15000)
        assert.ok(
            string.find(line, "hello_cross_node", 1, true),
            "expected MSG_RECV with 'hello_cross_node', got: " .. line
        )
    end)

    -- Cleanup
    cluster.stop_node(node2)

    if not ok then error(err) end
    return true
end

return { main = main }
