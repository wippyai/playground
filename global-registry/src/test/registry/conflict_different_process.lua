-- Test: register globally, spawn worker that tries same name, worker gets error
local assert = require("assert")
local time = require("time")

local function main()
    local name = "test.conflict_diff_proc"

    -- register globally from this process
    local ok, err = process.registry.register(name, process.registry.GLOBAL)
    assert.no_error(ok, err, "register should succeed")

    -- spawn conflict worker that will try to register the same name
    local status_ch = process.listen("status")

    local pid, serr = process.spawn_monitored(
        "app.test.registry:global_conflict_worker",
        "app:processes"
    )
    assert.no_error(pid, serr, "spawn conflict worker")

    -- send setup
    process.send(pid, "setup", { name = name, parent_pid = process.pid() })

    -- wait for worker status
    local timeout = time.after("5s")
    local result = channel.select{
        status_ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "worker should report status (not timeout)")

    -- worker should have gotten a conflict
    local status = result.value
    assert.eq(type(status), "string", "status should be a string")
    assert.ok(string.find(status, "CONFLICT"), "worker should report CONFLICT, got: " .. status)

    -- cleanup
    process.registry.unregister(name, process.registry.GLOBAL)

    return true
end

return { main = main }
