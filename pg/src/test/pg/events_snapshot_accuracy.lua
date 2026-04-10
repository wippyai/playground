-- Test: pg.events() snapshot accurately reflects groups joined before subscribing
local assert = require("assert")
local pg = require("pg")

local function main()
    local group_a = "test.evt_snap.a"
    local group_b = "test.evt_snap.b"

    -- join two groups BEFORE calling pg.events()
    local ok, err
    ok, err = pg.join(group_a)
    assert.no_error(ok, err, "join group_a")
    ok, err = pg.join(group_b)
    assert.no_error(ok, err, "join group_b")

    -- call pg.events() - snapshot should contain both groups
    local sub, snapshot, serr = pg.events()
    assert.no_error(sub, serr, "pg.events should succeed")
    assert.not_nil(sub, "subscription should not be nil")
    assert.is_table(snapshot, "snapshot should be a table")

    -- verify group_a is in the snapshot with 1 PID
    assert.not_nil(snapshot[group_a], "snapshot should contain group_a")
    assert.is_table(snapshot[group_a], "group_a value should be a table of PIDs")
    assert.eq(#snapshot[group_a], 1, "group_a should have exactly 1 PID")

    -- verify group_b is in the snapshot with 1 PID
    assert.not_nil(snapshot[group_b], "snapshot should contain group_b")
    assert.is_table(snapshot[group_b], "group_b value should be a table of PIDs")
    assert.eq(#snapshot[group_b], 1, "group_b should have exactly 1 PID")

    -- cleanup
    sub:close()
    pg.leave(group_a)
    pg.leave(group_b)
end

return { main = main }
