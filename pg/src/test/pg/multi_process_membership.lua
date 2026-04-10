-- Test: multiple processes in the same group, one leaves, others remain
-- Erlang PG: leave only affects the specific process that called it
local assert = require("assert")
local pg = require("pg")
local scope = pg.open("app:pg")
local time = require("time")

local function main()
    local group = "test.multi_proc_membership"
    local num_workers = 3

    -- set up channels before spawning
    local ready_ch = process.listen("ready")
    local left_ch = process.listen("left")

    -- spawn workers
    local workers = {}
    for i = 1, num_workers do
        local pid, err = process.spawn_monitored(
            "app.test.pg:membership_worker",
            "app:processes"
        )
        assert.no_error(pid, err, "spawn worker " .. i)
        workers[i] = pid
    end

    -- send setup to each worker
    local my_pid = process.pid()
    for i, w_pid in ipairs(workers) do
        process.send(w_pid, "setup", {
            group = group,
            parent_pid = my_pid,
            worker_id = i,
        })
    end

    -- wait for all workers to be ready
    for i = 1, num_workers do
        local timeout = time.after("3s")
        local result = channel.select{
            ready_ch:case_receive(),
            timeout:case_receive(),
        }
        assert.neq(result.channel, timeout, "worker " .. i .. " should signal ready")
    end

    -- verify all 3 are in the group
    local members, err = scope:get_members(group)
    assert.no_error(members, err, "get_members should succeed")
    assert.eq(#members, num_workers, "group should have " .. num_workers .. " members")

    -- tell worker 2 to leave
    process.send(workers[2], "command", "leave")

    -- wait for confirmation that worker 2 left
    local timeout = time.after("3s")
    local result = channel.select{
        left_ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "worker 2 should confirm leave")

    -- small delay for pg to process
    time.sleep("100ms")

    -- verify group now has 2 members (worker 1 and worker 3)
    members, err = scope:get_members(group)
    assert.no_error(members, err, "get_members after leave")
    assert.eq(#members, num_workers - 1, "group should have " .. (num_workers - 1) .. " members after one leaves")

    -- tell remaining workers to exit (send "exit" command or just let them timeout)
    process.send(workers[1], "command", "exit")
    process.send(workers[3], "command", "exit")

    -- wait for all workers to finish
    time.sleep("1s")
end

return { main = main }
