-- Test: spawn 5 workers that all try to register same name, exactly 1 succeeds
local assert = require("assert")
local time = require("time")

local function main()
    local name = "test.concurrent_register"
    local num_workers = 5
    local my_pid = process.pid()
    local status_ch = process.listen("status")
    local workers = {}

    -- spawn all workers (echo workers stay alive)
    for i = 1, num_workers do
        local pid, serr = process.spawn_monitored(
            "app.test.registry:global_echo_worker",
            "app:processes"
        )
        assert.no_error(pid, serr, "spawn worker " .. i)
        workers[i] = pid
    end

    -- send setup to all workers simultaneously (all try the same name)
    for _, pid in ipairs(workers) do
        process.send(pid, "setup", { name = name, parent_pid = my_pid })
    end

    -- collect results
    local registered_count = 0
    local conflict_count = 0

    for i = 1, num_workers do
        local timeout = time.after("5s")
        local result = channel.select{
            status_ch:case_receive(),
            timeout:case_receive(),
        }
        assert.neq(result.channel, timeout, "worker " .. i .. " should report status (not timeout)")

        local status = result.value
        if status == "REGISTERED" then
            registered_count = registered_count + 1
        elseif type(status) == "string" and string.find(status, "ERROR") then
            conflict_count = conflict_count + 1
        else
            error("unexpected status from worker: " .. tostring(status))
        end
    end

    -- exactly 1 should have succeeded (all workers are alive, no cleanup)
    assert.eq(registered_count, 1, "exactly 1 worker should register successfully")
    assert.eq(conflict_count, num_workers - 1, "remaining workers should get conflicts")

    -- cleanup: cancel all workers
    for _, pid in ipairs(workers) do
        process.cancel(pid)
    end
    time.sleep("500ms")

    return true
end

return { main = main }
