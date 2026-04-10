-- Test: auto-cleanup emits join and leave events via scope:events()
-- Spawns a cleanup_worker, observes join event, then worker exits and leave event fires.
local assert = require("assert")
local pg = require("pg")
local scope = pg.open("app:pg")
local time = require("time")

local function main()
    local group = "test.auto_evt"

    -- subscribe to pg events BEFORE spawning worker
    local sub, _, serr = scope:events()
    assert.no_error(sub, serr, "pg.events should succeed")
    local ch = sub:channel()

    -- set up listen channels BEFORE spawning to avoid race conditions
    local ready_ch = process.listen("ready")
    local events = process.events()

    -- spawn a cleanup worker that joins the group and then exits
    local pid, err = process.spawn_monitored(
        "app.test.pg:cleanup_worker",
        "app:processes"
    )
    assert.no_error(pid, err, "spawn cleanup worker")

    -- send setup
    process.send(pid, "setup", { group = group, parent_pid = process.pid() })

    -- wait for worker to be ready (it joined the group)
    local timeout = time.after("3s")
    local result = channel.select{
        ready_ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "worker should signal ready (not timeout)")

    -- receive the join event from pg events subscription
    timeout = time.after("3s")
    result = channel.select{
        ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive join event from pg events")
    assert.eq(result.value.kind, "member.joined", "event should be member.joined")
    assert.eq(result.value.path, group, "join event path should be the group name")

    -- wait for the worker process to exit
    timeout = time.after("3s")
    result = channel.select{
        events:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive worker exit event")

    -- give pg service time to process the exit
    time.sleep("300ms")

    -- receive the leave event from pg events subscription
    timeout = time.after("3s")
    result = channel.select{
        ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive leave event from pg events")
    assert.eq(result.value.kind, "member.left", "event should be member.left")
    assert.eq(result.value.path, group, "leave event path should be the group name")

    -- cleanup
    sub:close()
end

return { main = main }
