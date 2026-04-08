-- Worker: joins multiple groups and then exits after a short delay.
-- Used by auto_cleanup_multi_group test to verify all memberships are removed on exit.
local pg = require("pg")
local time = require("time")

local function main()
    local setup_ch = process.listen("setup")
    local setup_msg = setup_ch:receive()

    local groups = setup_msg.groups
    local parent_pid = setup_msg.parent_pid

    -- join all specified groups
    for _, g in ipairs(groups) do
        pg.join(g)
    end

    -- signal ready
    process.send(parent_pid, "ready", true)

    -- wait briefly, then exit
    time.sleep("100ms")
end

return { main = main }
