-- Worker: joins and leaves a group N times, then signals done and exits.
-- Used by stress_concurrent_join_leave test.
local pg = require("pg")
local scope = pg.open("app:pg")
local time = require("time")

local function main()
    local setup_ch = process.listen("setup")
    local setup_msg = setup_ch:receive()

    local group = setup_msg.group
    local parent_pid = setup_msg.parent_pid
    local cycles = setup_msg.cycles or 20

    -- rapidly join/leave the group N times
    for i = 1, cycles do
        scope:join(group)
        scope:leave(group)
    end

    -- signal done
    process.send(parent_pid, "done", true)

    -- brief delay before exit
    time.sleep("100ms")
end

return { main = main }
