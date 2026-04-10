-- Test: broadcasting to an empty or non-existent group succeeds without error
-- Erlang PG: broadcast over get_members of empty group just iterates zero members
local assert = require("assert")
local pg = require("pg")
local scope = pg.open("app:pg")

local function main()
    -- broadcast to a group that has never been created
    local ok, err = scope:broadcast("test.nonexistent.bcast", "some.topic", "hello")
    assert.no_error(ok, err, "broadcast to non-existent group should not error")

    -- broadcast_local to a group that has never been created
    ok, err = scope:broadcast_local("test.nonexistent.bcast_local", "some.topic", "hello")
    assert.no_error(ok, err, "broadcast_local to non-existent group should not error")

    -- create a group, then empty it, then broadcast to it
    local group = "test.bcast_empty"
    scope:join(group)
    scope:leave(group)

    -- group is now empty (was created then emptied)
    local members, _ = scope:get_members(group)
    assert.eq(#members, 0, "group should be empty")

    ok, err = scope:broadcast(group, "some.topic", "hello")
    assert.no_error(ok, err, "broadcast to emptied group should not error")

    ok, err = scope:broadcast_local(group, "some.topic", "hello")
    assert.no_error(ok, err, "broadcast_local to emptied group should not error")
end

return { main = main }
