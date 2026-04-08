-- Test: concurrent join/leave from multiple workers
-- Multiple workers join the same group, some leave, verify final membership consistency.
local assert = require("assert")
local pg = require("pg")
local time = require("time")

local function main()
    local group = "test.concurrent_membership"

    -- set up channels
    local ready_ch = process.listen("ready")
    local left_ch = process.listen("left")

    -- spawn 4 workers that all join the same group
    local workers = {}
    for i = 1, 4 do
        local pid, err = process.spawn_monitored(
            "app.test.pg:membership_worker",
            "app:processes"
        )
        assert.no_error(pid, err, "spawn worker " .. i)
        workers[i] = pid
    end

    -- send setup to all workers
    local my_pid = process.pid()
    for i, pid in ipairs(workers) do
        process.send(pid, "setup", {
            group = group,
            parent_pid = my_pid,
            worker_id = i,
        })
    end

    -- wait for all 4 workers to be ready
    for i = 1, 4 do
        local timeout = time.after("3s")
        local result = channel.select{
            ready_ch:case_receive(),
            timeout:case_receive(),
        }
        assert.neq(result.channel, timeout, "worker " .. i .. " should signal ready")
    end

    -- all 4 should be members
    local members, merr = pg.get_members(group)
    assert.no_error(members, merr, "get_members should succeed")
    assert.eq(#members, 4, "should have 4 members initially")

    -- tell workers 1 and 3 to leave
    process.send(workers[1], "command", "leave")
    process.send(workers[3], "command", "leave")

    -- wait for leave confirmations
    for i = 1, 2 do
        local timeout = time.after("3s")
        local result = channel.select{
            left_ch:case_receive(),
            timeout:case_receive(),
        }
        assert.neq(result.channel, timeout, "should receive leave confirmation " .. i)
    end

    -- give pg a moment to process
    time.sleep("100ms")

    -- should have 2 remaining members (workers 2 and 4)
    members, merr = pg.get_members(group)
    assert.no_error(members, merr, "get_members after leaves should succeed")
    assert.eq(#members, 2, "should have 2 members after 2 leaves")

    -- the remaining members should be workers 2 and 4
    local has_w2 = false
    local has_w4 = false
    for _, pid in ipairs(members) do
        if pid == workers[2] then has_w2 = true end
        if pid == workers[4] then has_w4 = true end
    end
    assert.ok(has_w2, "worker 2 should still be a member")
    assert.ok(has_w4, "worker 4 should still be a member")

    -- cleanup: tell remaining workers to exit
    process.send(workers[2], "command", "exit")
    process.send(workers[4], "command", "exit")
    time.sleep("500ms")
end

return { main = main }
