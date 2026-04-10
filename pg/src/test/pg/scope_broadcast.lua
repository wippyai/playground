-- Test: instance broadcast and broadcast_local deliver to group members
local assert = require("assert")
local pg = require("pg")
local time = require("time")

local function main()
    local s = pg.open("app:pg")
    local group = "test.scope_broadcast"

    -- set up listen channels BEFORE spawning workers
    local ready_ch = process.listen("ready")
    local confirm_topic = "confirm.scope_bcast"
    local confirm_ch = process.listen(confirm_topic)

    -- spawn a broadcast_worker
    local pid, err = process.spawn_monitored(
        "app.test.pg:broadcast_worker",
        "app:processes"
    )
    assert.no_error(pid, err, "spawn broadcast_worker")

    -- send setup with group name so worker joins the group
    process.send(pid, "setup", {
        group = group,
        confirm_topic = confirm_topic,
        parent_pid = process.pid(),
    })

    -- wait for worker to be ready
    local timeout = time.after("3s")
    local result = channel.select{
        ready_ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "worker should signal ready")

    time.sleep("200ms")

    -- use instance broadcast
    local ok, err2 = s:broadcast(group, "pg.broadcast", "scoped hello")
    assert.no_error(ok, err2, "broadcast should succeed")

    -- collect confirmation
    timeout = time.after("3s")
    result = channel.select{
        confirm_ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "worker should confirm receipt")
    assert.ok(result.value.received, "worker should have received broadcast")

    -- wait for worker to exit
    time.sleep("500ms")

    -- --- Now test broadcast_local ---
    -- spawn another worker for broadcast_local
    local ready_ch2 = process.listen("ready2")
    local confirm_topic2 = "confirm.scope_bcast_local"
    local confirm_ch2 = process.listen(confirm_topic2)

    local pid2, err3 = process.spawn_monitored(
        "app.test.pg:broadcast_worker",
        "app:processes"
    )
    assert.no_error(pid2, err3, "spawn broadcast_worker for local")

    process.send(pid2, "setup", {
        group = group,
        confirm_topic = confirm_topic2,
        parent_pid = process.pid(),
    })

    -- wait for worker ready (worker sends on "ready" topic)
    local ready_ch_any = process.listen("ready")
    timeout = time.after("3s")
    result = channel.select{
        ready_ch_any:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "worker2 should signal ready")

    time.sleep("200ms")

    -- use instance broadcast_local
    ok, err2 = s:broadcast_local(group, "pg.broadcast", "scoped local hello")
    assert.no_error(ok, err2, "broadcast_local should succeed")

    -- collect confirmation
    timeout = time.after("3s")
    result = channel.select{
        confirm_ch2:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "worker should confirm local broadcast receipt")
    assert.ok(result.value.received, "worker should have received broadcast_local")

    -- wait for worker to exit
    time.sleep("500ms")
end

return { main = main }
