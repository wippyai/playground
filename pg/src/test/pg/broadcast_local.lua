-- Test: broadcast_local delivers to local members only
local assert = require("assert")
local pg = require("pg")
local time = require("time")

local function main()
    local group = "test.broadcast_local"

    -- set up listen channels BEFORE spawning to avoid race conditions
    local ready_ch = process.listen("ready")
    local confirm_topic = "confirm.local"
    local confirm_ch = process.listen(confirm_topic)

    -- spawn a single worker
    local pid, err = process.spawn_monitored(
        "app.test.pg:broadcast_worker",
        "app:processes"
    )
    assert.no_error(pid, err, "spawn worker")

    -- send setup to worker (include parent_pid so worker can reply)
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
    assert.neq(result.channel, timeout, "worker should signal ready (not timeout)")

    -- small delay
    time.sleep("200ms")

    -- broadcast_local to the group
    local ok, err2 = pg.broadcast_local(group, "pg.broadcast", "local hello")
    assert.no_error(ok, err2, "pg.broadcast_local should succeed")

    -- collect confirmation
    timeout = time.after("3s")
    result = channel.select{
        confirm_ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "worker should confirm receipt (not timeout)")
    local confirmation = result.value
    assert.ok(confirmation.received, "worker should have received local broadcast")

    -- wait for worker to exit
    time.sleep("500ms")
end

return { main = main }
