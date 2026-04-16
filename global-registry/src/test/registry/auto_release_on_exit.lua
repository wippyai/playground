-- Test: spawn worker that registers globally then exits, verify name is released
local assert = require("assert")
local time = require("time")

local function main()
    local name = "test.auto_release_exit"

    -- set up channels before spawning
    local status_ch = process.listen("status")
    local events = process.events()

    -- spawn exit worker (registers then immediately exits)
    local pid, serr = process.spawn_monitored(
        "app.test.registry:global_exit_worker",
        "app:processes"
    )
    assert.no_error(pid, serr, "spawn exit worker")

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

    -- the exit worker exits immediately after sending REGISTERED
    -- wait for the EXIT event
    timeout = time.after("5s")
    result = channel.select{
        events:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive worker EXIT event (not timeout)")

    -- poll until name is released (Raft apply is async)
    local released = false
    for _ = 1, 40 do
        local val = process.registry.lookup(name)
        if val == nil then
            released = true
            break
        end
        time.sleep("250ms")
    end
    assert.ok(released, "name should be auto-released after worker exit")

    return true
end

return { main = main }
