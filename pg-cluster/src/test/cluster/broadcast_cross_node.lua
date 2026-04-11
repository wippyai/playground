-- Test: broadcast_cross_node
-- Verifies that pg:broadcast() on node1 delivers messages to members on node2.

local assert = require("assert")
local cluster = require("cluster")
local exec = require("exec")
local pg = require("pg")
local time = require("time")

local function main()
    local node2 = nil
    local GROUP = "cluster:bcast_test"

    local ok, err = pcall(function()
        -- Open PG scope on node1
        local scope, perr = pg.open("app:pg")
        if perr then error("pg.open failed: " .. tostring(perr)) end

        -- Start node2 — worker joins the test-specific group and listens for broadcasts
        node2 = cluster.start_node(exec, "node2", { group = GROUP })

        -- Wait for node2 worker to be ready
        cluster.wait_for_line(node2, "READY", 30000)

        -- Wait until we see the remote member in our local view
        local found = false
        for i = 1, 240 do
            local members = scope:get_members(GROUP) or {}
            if #members > 0 then
                found = true
                break
            end
            time.sleep("250ms")
        end
        assert.ok(found, "expected to see node2 member before broadcasting")

        -- Also join the group on node1 so we can broadcast
        local _, join_err = scope:join(GROUP)
        if join_err then error("join failed on node1: " .. tostring(join_err)) end

        -- Small delay for state to settle
        time.sleep("1s")

        -- Broadcast a message to the group
        local _, bcast_err = scope:broadcast(GROUP, "test.ping", "hello_from_node1")
        if bcast_err then error("broadcast failed: " .. tostring(bcast_err)) end

        -- Wait for the BROADCAST_RECV line from node2 (instead of sleeping + reading)
        local recv_line = cluster.wait_for_line(node2, "BROADCAST_RECV", 15000)

        assert.ok(recv_line ~= nil, "expected BROADCAST_RECV in node2 output")
        assert.ok(
            string.find(recv_line, "test.ping", 1, true),
            "broadcast line should contain topic 'test.ping', got: " .. recv_line
        )
        assert.ok(
            string.find(recv_line, "hello_from_node1", 1, true),
            "broadcast line should contain payload 'hello_from_node1', got: " .. recv_line
        )

        -- Clean up local membership
        scope:leave(GROUP)
    end)

    -- Cleanup
    cluster.stop_node(node2)

    if not ok then error(err) end
    return true
end

return { main = main }
