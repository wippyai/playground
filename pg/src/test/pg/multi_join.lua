-- Test: multi-join same group (PID appears multiple times)
local assert = require("assert")
local pg = require("pg")

local function main()
    local group = "test.multi_join"

    -- join the same group 3 times
    for i = 1, 3 do
        local ok, err = pg.join(group)
        assert.no_error(ok, err, "pg.join #" .. i .. " should succeed")
    end

    -- verify PID appears 3 times
    local members, err = pg.get_members(group)
    assert.no_error(members, err, "pg.get_members should succeed")
    assert.eq(#members, 3, "group should have 3 entries after 3 joins")

    -- leave once, should still have 2 entries
    local ok2, err2 = pg.leave(group)
    assert.no_error(ok2, err2, "first leave should succeed")

    members, err = pg.get_members(group)
    assert.no_error(members, err, "pg.get_members after 1 leave")
    assert.eq(#members, 2, "group should have 2 entries after 1 leave")

    -- leave remaining
    pg.leave(group)
    pg.leave(group)

    members, err = pg.get_members(group)
    assert.no_error(members, err, "pg.get_members after all leaves")
    assert.eq(#members, 0, "group should be empty after all leaves")
end

return { main = main }
