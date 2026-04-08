-- Test: broadcasting to an empty or non-existent group succeeds without error
-- Erlang PG: broadcast over get_members of empty group just iterates zero members
local assert = require("assert")
local pg = require("pg")

local function main()
    -- broadcast to a group that has never been created
    local ok, err = pg.broadcast("test.nonexistent.bcast", "some.topic", "hello")
    assert.no_error(ok, err, "broadcast to non-existent group should not error")

    -- broadcast_local to a group that has never been created
    ok, err = pg.broadcast_local("test.nonexistent.bcast_local", "some.topic", "hello")
    assert.no_error(ok, err, "broadcast_local to non-existent group should not error")

    -- create a group, then empty it, then broadcast to it
    local group = "test.bcast_empty"
    pg.join(group)
    pg.leave(group)

    -- group is now empty (was created then emptied)
    local members, _ = pg.get_members(group)
    assert.eq(#members, 0, "group should be empty")

    ok, err = pg.broadcast(group, "some.topic", "hello")
    assert.no_error(ok, err, "broadcast to emptied group should not error")

    ok, err = pg.broadcast_local(group, "some.topic", "hello")
    assert.no_error(ok, err, "broadcast_local to emptied group should not error")
end

return { main = main }
