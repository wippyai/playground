-- Test: events_cross_node
-- Verifies that pg.events() on node1 receives join/leave events
-- from processes on node2.

local assert = require("assert")
local cluster = require("cluster")
local exec = require("exec")
local pg = require("pg")
local time = require("time")
local channel = require("channel")

local function main()
    local node2 = nil
    local GROUP = "cluster:events_test"

    local ok, err = pcall(function()
        -- Open PG scope on node1
        local scope, perr = pg.open("app:pg")
        if perr then error("pg.open failed: " .. tostring(perr)) end

        -- Subscribe to events on node1 BEFORE node2 joins (events() has no args — subscribes to all groups)
        local sub, snap, events_err = scope:events()
        if events_err then error("events() failed: " .. tostring(events_err)) end
        if not sub then error("events() returned nil subscription") end

        -- Start node2 — worker joins the test-specific group
        node2 = cluster.start_node(exec, "node2", { group = GROUP })

        -- Wait for node2 to be ready
        cluster.wait_for_line(node2, "READY", 30000)

        -- Wait for a join event from the remote node
        local join_received = false
        local event_ch = sub:channel()
        local timeout_ch = time.after("60s")

        for i = 1, 120 do
            local result = channel.select({
                event_ch:case_receive(),
                timeout_ch:case_receive(),
            })

            if result.channel == event_ch then
                local ev = result.value
                if ev and ev.kind == "member.joined" and ev.path == GROUP then
                    join_received = true
                    -- Verify the PIDs contain a reference to node2
                    assert.not_nil(ev.data, "join event should have data")
                    assert.not_nil(ev.data.PIDs, "join event should have PIDs")
                    assert.gt(#ev.data.PIDs, 0, "join event should have at least 1 pid")
                    break
                end
                -- Keep reading if we got a different event
            else
                -- Timeout
                break
            end
        end

        assert.ok(join_received, "expected to receive a member.joined event from node2")

        -- Now stop node2 and wait for leave event
        cluster.stop_node(node2)
        node2 = nil -- Prevent double-stop in cleanup

        local leave_received = false
        local timeout_ch2 = time.after("30s") -- node leave detection can take longer

        for i = 1, 120 do
            local result = channel.select({
                event_ch:case_receive(),
                timeout_ch2:case_receive(),
            })

            if result.channel == event_ch then
                local ev = result.value
                if ev and ev.kind == "member.left" and ev.path == GROUP then
                    leave_received = true
                    break
                end
            else
                break
            end
        end

        assert.ok(leave_received, "expected to receive a member.left event after node2 departure")

        -- Close subscription
        sub:close()
    end)

    -- Cleanup
    cluster.stop_node(node2)

    if not ok then error(err) end
    return true
end

return { main = main }
