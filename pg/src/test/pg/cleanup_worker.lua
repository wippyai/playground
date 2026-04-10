-- Worker: joins a group and then exits after a short delay.
-- Used by auto_cleanup test to verify automatic group removal on process exit.
local pg = require("pg")
local scope = pg.open("app:pg")
local time = require("time")

local function main()
    -- listen for setup instructions
    local setup_ch = process.listen("setup")
    local setup_msg = setup_ch:receive()

    local group = setup_msg.group
    local parent_pid = setup_msg.parent_pid

    -- join the group
    scope:join(group)

    -- signal to parent that we joined
    process.send(parent_pid, "ready", true)

    -- wait briefly, then exit (process exit should auto-remove from group)
    time.sleep("100ms")
end

return { main = main }
