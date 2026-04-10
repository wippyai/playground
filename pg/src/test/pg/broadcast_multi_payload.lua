-- Test: broadcast with multiple payload arguments (variadic payloads)
-- The Go implementation supports collecting all args from position 3 onward.
local assert = require("assert")
local pg = require("pg")
local scope = pg.open("app:pg")
local time = require("time")

local function main()
    local group = "test.broadcast_multi_payload"

    -- set up channels before spawning
    local ready_ch = process.listen("ready")
    local confirm_ch = process.listen("confirm")

    -- spawn a worker to receive the broadcast
    local pid, err = process.spawn_monitored(
        "app.test.pg:broadcast_payload_worker",
        "app:processes"
    )
    assert.no_error(pid, err, "spawn worker")

    -- send setup
    process.send(pid, "setup", {
        group = group,
        parent_pid = process.pid(),
    })

    -- wait for ready
    local timeout = time.after("3s")
    local result = channel.select{
        ready_ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "worker should signal ready")

    time.sleep("100ms")

    -- broadcast with multiple payload args
    local ok, berr = scope:broadcast(group, "pg.multi.payload", "arg1", "arg2", "arg3")
    assert.no_error(ok, berr, "broadcast with multiple payloads should succeed")

    -- wait for confirmation
    timeout = time.after("3s")
    result = channel.select{
        confirm_ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "worker should confirm receipt")
    assert.ok(result.value.received, "worker should have received broadcast")

    -- wait for worker to exit
    time.sleep("500ms")
end

return { main = main }
