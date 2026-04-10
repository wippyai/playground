-- Test: multi-join process exit emits leave event with correct PID multiplicity
-- When a worker joined group "A" 3 times and exits, the leave event's data.PIDs
-- should contain the worker PID 3 times (matching Erlang PG semantics).
local assert = require("assert")
local pg = require("pg")
local scope = pg.open("app:pg")
local time = require("time")

local function main()
    local group = "test.multi_join_exit_events"
    local join_count = 3

    -- subscribe to pg events BEFORE spawning the worker
    local sub, groups, err = scope:events()
    assert.no_error(sub, err, "pg.events should succeed")

    local ch = sub:channel()

    -- set up channels before spawning
    local ready_ch = process.listen("ready")
    local events = process.events()

    -- spawn a monitored worker that will multi-join then exit
    local pid, spawn_err = process.spawn_monitored(
        "app.test.pg:multi_join_cleanup_worker",
        "app:processes"
    )
    assert.no_error(pid, spawn_err, "spawn worker")

    -- send setup to worker
    process.send(pid, "setup", {
        group = group,
        join_count = join_count,
        parent_pid = process.pid(),
    })

    -- wait for worker to signal ready
    local timeout = time.after("3s")
    local result = channel.select{
        ready_ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "worker should signal ready")

    -- consume the join events (one per join)
    for i = 1, join_count do
        timeout = time.after("3s")
        result = channel.select{
            ch:case_receive(),
            timeout:case_receive(),
        }
        assert.neq(result.channel, timeout, "should receive join event #" .. i)
        assert.eq(result.value.kind, "member.joined", "event should be member.joined")
    end

    -- wait for worker to exit
    timeout = time.after("3s")
    result = channel.select{
        events:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive worker exit")

    -- give pg service time to process the exit
    time.sleep("300ms")

    -- receive the leave event — should be exactly one event for this group
    timeout = time.after("3s")
    result = channel.select{
        ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive leave event after worker exit")
    assert.eq(result.value.kind, "member.left", "event should be member.left")
    assert.eq(result.value.data.Group, group, "leave event group should match")

    -- The PID list should contain the worker PID repeated join_count times
    local leave_pids = result.value.data.PIDs
    assert.not_nil(leave_pids, "leave event data.PIDs should not be nil")
    assert.is_table(leave_pids, "leave event data.PIDs should be a table")
    assert.eq(#leave_pids, join_count,
        "leave event should have " .. join_count .. " PIDs (one per join), got " .. #leave_pids)

    -- all PIDs in the list should be the worker's PID
    for i = 1, #leave_pids do
        assert.eq(leave_pids[i], pid, "PIDs[" .. i .. "] should be the worker PID")
    end

    -- cleanup
    sub:close()
end

return { main = main }
