-- Test: pg.events() receives events for another process joining
-- Subscribe, spawn a worker that joins a group, verify event includes worker PID.
local assert = require("assert")
local pg = require("pg")
local time = require("time")

local function main()
    local group = "test.events_from_other"

    -- subscribe to pg events first
    local sub, groups, err = pg.events()
    assert.no_error(sub, err, "pg.events should succeed")
    local ch = sub:channel()

    -- set up ready channel
    local ready_ch = process.listen("ready")

    -- spawn the events_worker
    local pid, serr = process.spawn_monitored(
        "app.test.pg:events_worker",
        "app:processes"
    )
    assert.no_error(pid, serr, "spawn events_worker")

    -- send setup to worker
    process.send(pid, "setup", {
        group = group,
        parent_pid = process.pid(),
    })

    -- wait for worker to signal ready (it has joined)
    local timeout = time.after("3s")
    local result = channel.select{
        ready_ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "worker should signal ready")

    -- receive the member.joined event
    timeout = time.after("3s")
    result = channel.select{
        ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive join event from worker")

    local evt = result.value
    assert.eq(evt.kind, "member.joined", "event should be member.joined")
    assert.eq(evt.data.Group, group, "event group should match")
    assert.not_nil(evt.data.PIDs, "event PIDs should not be nil")
    assert.is_table(evt.data.PIDs, "event PIDs should be a table")

    -- the PID in the event should be the worker's PID, not ours
    local found_worker_pid = false
    for _, p in ipairs(evt.data.PIDs) do
        if p == pid then
            found_worker_pid = true
        end
    end
    assert.ok(found_worker_pid, "event PIDs should contain worker PID " .. tostring(pid))

    -- wait for worker to exit, then verify leave event
    time.sleep("500ms")

    timeout = time.after("3s")
    result = channel.select{
        ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive leave event after worker exit")
    assert.eq(result.value.kind, "member.left", "event should be member.left")

    -- cleanup
    sub:close()
end

return { main = main }
