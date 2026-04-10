-- Worker: joins a group N times then exits after a short delay.
-- Used by auto_cleanup_multi_join test.
local pg = require("pg")
local scope = pg.open("app:pg")
local time = require("time")

local function main()
    local setup_ch = process.listen("setup")
    local setup_msg = setup_ch:receive()

    local group = setup_msg.group
    local join_count = setup_msg.join_count
    local parent_pid = setup_msg.parent_pid

    -- join the group N times
    for i = 1, join_count do
        scope:join(group)
    end

    -- signal ready
    process.send(parent_pid, "ready", true)

    -- exit after a short delay (auto-cleanup should remove all N entries)
    time.sleep("100ms")
end

return { main = main }
