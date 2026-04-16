-- Test: spawn echo worker registered globally, send via name, verify echo arrives
local assert = require("assert")
local time = require("time")

local function main()
    local name = "test.send_to_global"

    -- set up channels before spawning
    local status_ch = process.listen("status")
    local reply_ch = process.listen("echo_reply")

    -- spawn echo worker
    local pid, serr = process.spawn_monitored(
        "app.test.registry:global_echo_worker",
        "app:processes"
    )
    assert.no_error(pid, serr, "spawn echo worker")

    -- send setup
    process.send(pid, "setup", { name = name, parent_pid = process.pid() })

    -- wait for worker to confirm registration
    local timeout = time.after("5s")
    local result = channel.select{
        status_ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "worker should confirm registration (not timeout)")
    assert.eq(result.value, "REGISTERED", "worker should report REGISTERED")

    -- send a message to the worker via its globally registered name
    local resolved_pid, lerr = process.registry.lookup(name)
    assert.no_error(resolved_pid, lerr, "lookup global name should succeed")
    process.send(resolved_pid, "echo", "hello_global")

    -- wait for echo reply
    timeout = time.after("5s")
    result = channel.select{
        reply_ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive echo reply (not timeout)")
    assert.eq(result.value, "hello_global", "echo reply should match sent message")

    -- cleanup: cancel the worker
    process.cancel(pid)
    time.sleep("200ms")

    return true
end

return { main = main }
