-- Test: 10 workers rapidly join/leave same group 20 times each, verify consistent final state
local assert = require("assert")
local pg = require("pg")
local scope = pg.open("app:pg")
local time = require("time")

local function main()
    local group = "test.stress_conc_jl"
    local num_workers = 10
    local cycles = 20

    -- listen for done signals
    local done_ch = process.listen("done")

    -- spawn 10 workers that each join/leave 20 times then exit
    local pids = {}
    for i = 1, num_workers do
        local pid, err = process.spawn_monitored(
            "app.test.pg:stress_jl_worker",
            "app:processes"
        )
        assert.no_error(pid, err, "spawn worker " .. i)
        pids[i] = pid
    end

    -- send setup to all workers
    local my_pid = process.pid()
    for i, pid in ipairs(pids) do
        process.send(pid, "setup", {
            group = group,
            parent_pid = my_pid,
            cycles = cycles,
        })
    end

    -- wait for all workers to signal done
    for i = 1, num_workers do
        local timeout = time.after("10s")
        local result = channel.select{
            done_ch:case_receive(),
            timeout:case_receive(),
        }
        assert.neq(result.channel, timeout, "worker " .. i .. " should signal done")
    end

    -- give pg a moment to process all leaves
    time.sleep("500ms")

    -- after all workers have exited, get_members should return 0
    local members, merr = scope:get_members(group)
    assert.no_error(members, merr, "get_members should succeed")
    assert.eq(#members, 0,
        "group should have 0 members after all workers exited, got " .. #members)
end

return { main = main }
