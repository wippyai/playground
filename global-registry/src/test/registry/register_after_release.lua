-- Test: worker registers globally, exits (auto-release), new worker registers same name
local assert = require("assert")
local time = require("time")

local function main()
    local name = "test.register_after_release"
    local my_pid = process.pid()

    -- set up channels
    local status_ch = process.listen("status")
    local events = process.events()

    -- spawn first exit worker (registers then exits immediately)
    local pid1, serr1 = process.spawn_monitored(
        "app.test.registry:global_exit_worker",
        "app:processes"
    )
    assert.no_error(pid1, serr1, "spawn first exit worker")
    process.send(pid1, "setup", { name = name, parent_pid = my_pid })

    -- wait for first worker to confirm
    local timeout = time.after("5s")
    local result = channel.select{
        status_ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "first worker should confirm (not timeout)")
    assert.eq(result.value, "REGISTERED", "first worker should report REGISTERED")

    -- wait for first worker EXIT
    timeout = time.after("5s")
    result = channel.select{
        events:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive first worker EXIT (not timeout)")

    -- poll until name is released
    local released = false
    for _ = 1, 40 do
        local val = process.registry.lookup(name)
        if val == nil then
            released = true
            break
        end
        time.sleep("250ms")
    end
    assert.ok(released, "lookup should fail after first worker exited")

    -- spawn second worker (echo worker, stays alive) that registers the same name
    local pid2, serr2 = process.spawn_monitored(
        "app.test.registry:global_echo_worker",
        "app:processes"
    )
    assert.no_error(pid2, serr2, "spawn second exit worker")
    process.send(pid2, "setup", { name = name, parent_pid = my_pid })

    -- wait for second worker to confirm
    timeout = time.after("5s")
    result = channel.select{
        status_ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "second worker should confirm (not timeout)")
    assert.eq(result.value, "REGISTERED", "second worker should report REGISTERED")

    -- verify name resolves to second worker
    local found_pid, lerr = process.registry.lookup(name)
    assert.no_error(found_pid, lerr, "lookup should succeed for second worker")
    assert.eq(found_pid, pid2, "lookup should return second worker PID")

    -- cleanup
    process.cancel(pid2)
    time.sleep("500ms")

    return true
end

return { main = main }
