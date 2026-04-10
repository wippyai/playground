-- Test: process joined N times receives N broadcast messages (Erlang PG core semantic)
-- In Erlang's pg, get_members returns duplicate PIDs for multi-joined processes.
-- Broadcasting iterates over get_members, so each duplicate entry receives a message.
local assert = require("assert")
local pg = require("pg")
local scope = pg.open("app:pg")
local time = require("time")

local function main()
    local group = "test.bcast_multi_join"
    local join_count = 3

    -- set up channels before spawning
    local ready_ch = process.listen("ready")
    local result_ch = process.listen("result")
    local events = process.events()

    -- spawn worker that will join group N times
    local pid, err = process.spawn_monitored(
        "app.test.pg:multi_join_broadcast_worker",
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

    -- verify get_members shows N entries
    local members, merr = scope:get_members(group)
    assert.no_error(members, merr, "get_members")
    assert.eq(#members, join_count, "get_members should show " .. join_count .. " entries for multi-joined worker")

    -- small delay then broadcast once
    time.sleep("100ms")
    local ok, berr = scope:broadcast(group, "pg.multi.bcast", "single message")
    assert.no_error(ok, berr, "broadcast should succeed")

    -- wait for worker to report result
    timeout = time.after("5s")
    result = channel.select{
        result_ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "worker should report result")

    local report = result.value
    assert.eq(report.received_count, join_count,
        "worker joined " .. join_count .. " times should receive " .. join_count .. " messages, got " .. tostring(report.received_count))

    -- wait for worker to exit
    timeout = time.after("3s")
    result = channel.select{
        events:case_receive(),
        timeout:case_receive(),
    }
end

return { main = main }
