-- Test: broadcast delivers to all group members
local assert = require("assert")
local pg = require("pg")
local time = require("time")

local function main()
    local group = "test.broadcast"
    local num_workers = 2

    -- set up listen channels BEFORE spawning workers to avoid race conditions
    local ready_ch = process.listen("ready")

    -- spawn workers
    local workers = {}
    for i = 1, num_workers do
        local pid, err = process.spawn_monitored(
            "app.test.pg:broadcast_worker",
            "app:processes"
        )
        assert.no_error(pid, err, "spawn worker " .. i)
        workers[i] = { pid = pid, confirm_topic = "confirm." .. i }
    end

    -- set up confirm channels before sending setup
    local confirm_channels = {}
    for i, w in ipairs(workers) do
        confirm_channels[i] = process.listen(w.confirm_topic)
    end

    -- send setup to each worker (include parent_pid so workers can reply)
    local my_pid = process.pid()
    for i, w in ipairs(workers) do
        process.send(w.pid, "setup", {
            group = group,
            confirm_topic = w.confirm_topic,
            parent_pid = my_pid,
        })
    end

    -- wait for all workers to be ready
    for i = 1, num_workers do
        local timeout = time.after("3s")
        local result = channel.select{
            ready_ch:case_receive(),
            timeout:case_receive(),
        }
        assert.neq(result.channel, timeout, "worker " .. i .. " should signal ready (not timeout)")
    end

    -- small delay to ensure workers are listening
    time.sleep("200ms")

    -- broadcast a message to the group
    local ok, err = pg.broadcast(group, "pg.broadcast", "hello from test")
    assert.no_error(ok, err, "pg.broadcast should succeed")

    -- collect confirmations from workers
    for i, w in ipairs(workers) do
        local timeout = time.after("3s")
        local result = channel.select{
            confirm_channels[i]:case_receive(),
            timeout:case_receive(),
        }
        assert.neq(result.channel, timeout, "worker " .. i .. " should confirm receipt (not timeout)")
        local confirmation = result.value
        assert.ok(confirmation.received, "worker " .. i .. " should have received broadcast")
    end

    -- wait for workers to exit
    time.sleep("500ms")
end

return { main = main }
