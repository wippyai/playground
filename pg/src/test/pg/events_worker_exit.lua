-- Test: pg.events() receives events when a worker process joins then exits
local assert = require("assert")
local pg = require("pg")
local time = require("time")

local function main()
    local group = "test.events_worker_exit"

    -- subscribe to pg events BEFORE spawning the worker
    local sub, groups, err = pg.events()
    assert.no_error(sub, err, "pg.events should succeed")

    local ch = sub:channel()

    -- set up listen channel for worker ready signal
    local ready_ch = process.listen("ready")

    -- spawn a monitored worker that will join the group and then exit
    local pid, spawn_err = process.spawn_monitored(
        "app.test.pg:events_worker",
        "app:processes"
    )
    assert.no_error(pid, spawn_err, "spawn events worker")

    -- send setup to worker
    process.send(pid, "setup", {
        group = group,
        parent_pid = process.pid(),
    })

    -- wait for worker to signal ready (it joined the group)
    local timeout = time.after("3s")
    local result = channel.select{
        ready_ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "worker should signal ready (not timeout)")

    -- receive the member.joined event from the worker joining
    timeout = time.after("3s")
    result = channel.select{
        ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive join event (not timeout)")
    assert.eq(result.value.kind, "member.joined", "event should be member.joined")
    assert.eq(result.value.data.Group, group, "event group should match")

    -- wait for the worker to exit and for the pg service to process the exit
    -- the worker exits after 100ms, then pg cleanup happens asynchronously
    time.sleep("500ms")

    -- receive the member.left event from the worker exiting
    timeout = time.after("3s")
    result = channel.select{
        ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive leave event after worker exit (not timeout)")
    assert.eq(result.value.kind, "member.left", "event should be member.left")
    assert.eq(result.value.data.Group, group, "leave event group should match")

    -- cleanup
    sub:close()
end

return { main = main }
