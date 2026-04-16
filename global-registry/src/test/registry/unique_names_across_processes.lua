-- Test: spawn 5 workers, each registers a unique global name, verify all 5 resolve
local assert = require("assert")
local time = require("time")

local function main()
    local num_workers = 5
    local base_name = "test.unique_across."
    local status_ch = process.listen("status")
    local my_pid = process.pid()
    local workers = {}

    -- spawn workers, each registers a unique name
    for i = 1, num_workers do
        local pid, serr = process.spawn_monitored(
            "app.test.registry:global_echo_worker",
            "app:processes"
        )
        assert.no_error(pid, serr, "spawn worker " .. i)
        workers[i] = pid

        process.send(pid, "setup", {
            name = base_name .. i,
            parent_pid = my_pid,
        })
    end

    -- wait for all workers to confirm registration
    for i = 1, num_workers do
        local timeout = time.after("5s")
        local result = channel.select{
            status_ch:case_receive(),
            timeout:case_receive(),
        }
        assert.neq(result.channel, timeout, "worker " .. i .. " should confirm (not timeout)")
        assert.eq(result.value, "REGISTERED", "worker " .. i .. " should report REGISTERED")
    end

    -- verify all 5 names resolve
    for i = 1, num_workers do
        local name = base_name .. i
        local pid, lerr = process.registry.lookup(name)
        assert.no_error(pid, lerr, "lookup " .. name .. " should succeed")
        assert.not_nil(pid, "lookup " .. name .. " should return a PID")
    end

    -- cleanup: cancel all workers
    for _, pid in ipairs(workers) do
        process.cancel(pid)
    end
    time.sleep("300ms")

    return true
end

return { main = main }
