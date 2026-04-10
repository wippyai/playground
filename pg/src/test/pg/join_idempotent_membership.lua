-- Test: joining the same group twice causes PID to appear twice (Erlang PG multi-join semantic)
-- Each join adds one reference. Each leave removes exactly one.
local assert = require("assert")
local pg = require("pg")

local function main()
    local group = "test.join_idem"

    -- join the same group twice
    local ok, err = pg.join(group)
    assert.no_error(ok, err, "first join should succeed")
    ok, err = pg.join(group)
    assert.no_error(ok, err, "second join should succeed")

    -- get_members should return 2 entries (same PID twice)
    local members, merr = pg.get_members(group)
    assert.no_error(members, merr, "get_members after 2 joins")
    assert.eq(#members, 2, "group should have 2 entries after 2 joins")

    -- leave once -> 1 entry
    ok, err = pg.leave(group)
    assert.no_error(ok, err, "first leave should succeed")

    members, merr = pg.get_members(group)
    assert.no_error(members, merr, "get_members after 1 leave")
    assert.eq(#members, 1, "group should have 1 entry after 1 leave")

    -- leave again -> 0 entries
    ok, err = pg.leave(group)
    assert.no_error(ok, err, "second leave should succeed")

    members, merr = pg.get_members(group)
    assert.no_error(members, merr, "get_members after 2 leaves")
    assert.eq(#members, 0, "group should be empty after all leaves")

    -- leaving already-empty group should return error
    local val, lerr = pg.leave(group)
    assert.has_error(val, lerr, "leaving already-empty group should error")
end

return { main = main }
