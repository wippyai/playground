-- Test: process that multi-joined (N times) a group is fully removed on exit
-- All N membership entries should be cleaned up, not just one.
local assert = require("assert")
local pg = require("pg")
local time = require("time")

local function main()
    local group = "test.auto_cleanup_multi_join"
    local join_count = 4

    -- set up channels before spawning
    local ready_ch = process.listen("ready")
    local events = process.events()

    -- spawn a worker that will multi-join the group
    local pid, err = process.spawn_monitored(
        "app.test.pg:multi_join_cleanup_worker",
        "app:processes"
    )
    assert.no_error(pid, err, "spawn worker")

    -- send setup
    process.send(pid, "setup", {
        group = group,
        join_count = join_count,
        parent_pid = process.pid(),
    })

    -- wait for ready
    local timeout = time.after("3s")
    local result = channel.select{
        ready_ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "worker should signal ready")

    -- verify the worker appears N times in get_members
    local members, merr = pg.get_members(group)
    assert.no_error(members, merr, "get_members should succeed")
    assert.eq(#members, join_count, "worker should appear " .. join_count .. " times")

    -- wait for the worker process to exit
    timeout = time.after("3s")
    result = channel.select{
        events:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive worker exit event")

    -- give pg service time to process the exit
    time.sleep("300ms")

    -- ALL membership entries should be removed
    members, merr = pg.get_members(group)
    assert.no_error(members, merr, "get_members after exit should succeed")
    assert.eq(#members, 0,
        "group should be empty after multi-joined worker exited, got " .. #members)
end

return { main = main }
