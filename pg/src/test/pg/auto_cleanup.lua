-- Test: process exit auto-removes from groups
local assert = require("assert")
local pg = require("pg")
local scope = pg.open("app:pg")
local time = require("time")

local function main()
    local group = "test.auto_cleanup"

    -- set up listen channels BEFORE spawning to avoid race conditions
    local ready_ch = process.listen("ready")
    local events = process.events()

    -- spawn a worker that will join the group and then exit
    local pid, err = process.spawn_monitored(
        "app.test.pg:cleanup_worker",
        "app:processes"
    )
    assert.no_error(pid, err, "spawn cleanup worker")

    -- send setup (include parent_pid so worker can reply)
    process.send(pid, "setup", { group = group, parent_pid = process.pid() })

    -- wait for worker to be ready (it joined the group)
    local timeout = time.after("3s")
    local result = channel.select{
        ready_ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "worker should signal ready (not timeout)")

    -- verify the worker is in the group
    local members, err2 = scope:get_members(group)
    assert.no_error(members, err2, "get_members should succeed")
    assert.gte(#members, 1, "group should have at least 1 member while worker is alive")

    -- wait for the worker process to exit (it sleeps 100ms then exits)
    -- also wait for the pg service to process the exit event
    timeout = time.after("3s")
    result = channel.select{
        events:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive worker exit event (not timeout)")

    -- give pg service time to process the exit
    time.sleep("300ms")

    -- verify the worker was auto-removed from the group
    members, err2 = scope:get_members(group)
    assert.no_error(members, err2, "get_members after exit should succeed")
    assert.eq(#members, 0, "group should be empty after worker exited")
end

return { main = main }
