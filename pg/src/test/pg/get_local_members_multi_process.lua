-- Test: get_local_members returns all local processes in a group
-- Verifies that when multiple local processes join, get_local_members returns them all.
local assert = require("assert")
local pg = require("pg")
local time = require("time")

local function main()
    local group = "test.local_members_multi"

    -- set up channels before spawning
    local ready_ch = process.listen("ready")

    -- spawn 3 workers that will join the group
    local workers = {}
    for i = 1, 3 do
        local pid, err = process.spawn_monitored(
            "app.test.pg:membership_worker",
            "app:processes"
        )
        assert.no_error(pid, err, "spawn worker " .. i)
        workers[i] = pid
    end

    -- send setup
    local my_pid = process.pid()
    for i, w_pid in ipairs(workers) do
        process.send(w_pid, "setup", {
            group = group,
            parent_pid = my_pid,
            worker_id = i,
        })
    end

    -- wait for all workers to be ready
    for i = 1, 3 do
        local timeout = time.after("3s")
        local result = channel.select{
            ready_ch:case_receive(),
            timeout:case_receive(),
        }
        assert.neq(result.channel, timeout, "worker " .. i .. " should signal ready")
    end

    -- get_local_members should return all 3
    local members, err = pg.get_local_members(group)
    assert.no_error(members, err, "get_local_members should succeed")
    assert.eq(#members, 3, "get_local_members should return 3 local members")

    -- get_members should also return all 3 (all are local)
    members, err = pg.get_members(group)
    assert.no_error(members, err, "get_members should succeed")
    assert.eq(#members, 3, "get_members should also return 3 members")

    -- tell all workers to exit
    for _, w_pid in ipairs(workers) do
        process.send(w_pid, "command", "exit")
    end

    time.sleep("1s")
end

return { main = main }
