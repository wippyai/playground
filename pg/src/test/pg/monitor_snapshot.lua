-- Test: pg.monitor() returns non-empty initial snapshot when group has members
local assert = require("assert")
local pg = require("pg")

local function main()
    local group = "test.monitor_snapshot"

    -- join the group BEFORE subscribing to monitor
    local ok, err = pg.join(group)
    assert.no_error(ok, err, "join should succeed")

    -- join a second time to verify snapshot shows multi-join
    ok, err = pg.join(group)
    assert.no_error(ok, err, "join #2 should succeed")

    -- now subscribe to monitor — snapshot should be non-empty
    local sub, members, merr = pg.monitor(group)
    assert.no_error(sub, merr, "pg.monitor should succeed")
    assert.not_nil(sub, "subscription should not be nil")
    assert.is_table(members, "members snapshot should be a table")
    assert.eq(#members, 2, "snapshot should show 2 entries (multi-join)")

    -- all entries should be the same PID (ours)
    local my_pid = members[1]
    assert.eq(members[2], my_pid, "both entries should be our PID")

    -- cleanup
    sub:close()
    pg.leave(group)
    pg.leave(group)
end

return { main = main }
