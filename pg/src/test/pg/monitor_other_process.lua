-- Test: pg.monitor() receives events from another process (cross-process)
-- Monitor a group, spawn an events_worker that joins it, verify join/leave events.
local assert = require("assert")
local pg = require("pg")
local time = require("time")

local function main()
    local group = "test.monitor_other_process"

    -- subscribe to monitor for this group
    local sub, members, err = pg.monitor(group)
    assert.no_error(sub, err, "pg.monitor should succeed")
    assert.eq(#members, 0, "initial members should be empty")

    local ch = sub:channel()

    -- set up ready channel
    local ready_ch = process.listen("ready")

    -- spawn events_worker (it joins, signals ready, then exits)
    local pid, serr = process.spawn_monitored(
        "app.test.pg:events_worker",
        "app:processes"
    )
    assert.no_error(pid, serr, "spawn events_worker")

    -- send setup
    process.send(pid, "setup", {
        group = group,
        parent_pid = process.pid(),
    })

    -- wait for worker to signal ready
    local timeout = time.after("3s")
    local result = channel.select{
        ready_ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "worker should signal ready")

    -- receive join event from monitor
    timeout = time.after("3s")
    result = channel.select{
        ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive join event from worker")

    local evt = result.value
    assert.eq(evt.kind, "member.joined", "event should be member.joined")
    assert.eq(evt.path, group, "event path should match group")
    assert.not_nil(evt.data.PIDs, "event PIDs should not be nil")

    -- verify the PID in the event is the worker's PID
    local found = false
    for _, p in ipairs(evt.data.PIDs) do
        if p == pid then found = true end
    end
    assert.ok(found, "event PIDs should contain worker PID")

    -- wait for worker to exit — should trigger leave event
    time.sleep("500ms")

    timeout = time.after("3s")
    result = channel.select{
        ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive leave event after worker exit")
    assert.eq(result.value.kind, "member.left", "should be member.left")

    -- cleanup
    sub:close()
end

return { main = main }
