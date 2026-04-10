-- Test: which_groups returns groups from all processes
-- Spawns workers that join different groups, verifies which_groups sees them all.
local assert = require("assert")
local pg = require("pg")
local scope = pg.open("app:pg")
local time = require("time")

local function main()
    local group_a = "test.isolation.group_a"
    local group_b = "test.isolation.group_b"
    local group_c = "test.isolation.group_c"

    -- set up channels before spawning
    local ready_ch = process.listen("ready")

    -- spawn two workers into different groups
    local pid1, err1 = process.spawn_monitored(
        "app.test.pg:membership_worker",
        "app:processes"
    )
    assert.no_error(pid1, err1, "spawn worker 1")

    local pid2, err2 = process.spawn_monitored(
        "app.test.pg:membership_worker",
        "app:processes"
    )
    assert.no_error(pid2, err2, "spawn worker 2")

    -- send setup: worker 1 joins group_a, worker 2 joins group_b
    process.send(pid1, "setup", {
        group = group_a,
        parent_pid = process.pid(),
        worker_id = 1,
    })
    process.send(pid2, "setup", {
        group = group_b,
        parent_pid = process.pid(),
        worker_id = 2,
    })

    -- wait for both to be ready
    for i = 1, 2 do
        local timeout = time.after("3s")
        local result = channel.select{
            ready_ch:case_receive(),
            timeout:case_receive(),
        }
        assert.neq(result.channel, timeout, "worker " .. i .. " should be ready")
    end

    -- our own process joins group_c
    local ok, jerr = scope:join(group_c)
    assert.no_error(ok, jerr, "main join group_c should succeed")

    -- which_groups should list all three groups
    local groups, gerr = scope:which_groups()
    assert.no_error(groups, gerr, "which_groups should succeed")

    local found_a, found_b, found_c = false, false, false
    for _, g in ipairs(groups) do
        if g == group_a then found_a = true end
        if g == group_b then found_b = true end
        if g == group_c then found_c = true end
    end
    assert.ok(found_a, "which_groups should contain group_a")
    assert.ok(found_b, "which_groups should contain group_b")
    assert.ok(found_c, "which_groups should contain group_c")

    -- cleanup: tell workers to exit, leave our group
    process.send(pid1, "command", "exit")
    process.send(pid2, "command", "exit")
    scope:leave(group_c)
    time.sleep("500ms")
end

return { main = main }
