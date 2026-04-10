-- Test: process exit auto-removes from ALL groups it joined
-- Erlang PG: when a process exits, all its group memberships are cleaned up
local assert = require("assert")
local pg = require("pg")
local scope = pg.open("app:pg")
local time = require("time")

local function main()
    local groups = {
        "test.cleanup_multi.alpha",
        "test.cleanup_multi.beta",
        "test.cleanup_multi.gamma",
    }

    -- set up channels before spawning
    local ready_ch = process.listen("ready")
    local events = process.events()

    -- spawn a worker that will join all three groups
    local pid, err = process.spawn_monitored(
        "app.test.pg:multi_group_worker",
        "app:processes"
    )
    assert.no_error(pid, err, "spawn multi_group_worker")

    -- send setup with groups list
    process.send(pid, "setup", {
        groups = groups,
        parent_pid = process.pid(),
    })

    -- wait for worker to be ready
    local timeout = time.after("3s")
    local result = channel.select{
        ready_ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "worker should signal ready")

    -- verify worker is a member of all three groups
    for _, g in ipairs(groups) do
        local members, merr = scope:get_members(g)
        assert.no_error(members, merr, "get_members " .. g)
        assert.gte(#members, 1, g .. " should have at least 1 member while worker alive")
    end

    -- wait for worker to exit
    timeout = time.after("3s")
    result = channel.select{
        events:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive worker exit event")

    -- give pg service time to process the exit
    time.sleep("300ms")

    -- verify worker was auto-removed from ALL groups
    for _, g in ipairs(groups) do
        local members, merr = scope:get_members(g)
        assert.no_error(members, merr, "get_members " .. g .. " after exit")
        assert.eq(#members, 0, g .. " should be empty after worker exited")
    end
end

return { main = main }
