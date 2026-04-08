-- Test: multi-join reference counting (Erlang PG core semantic)
-- Each pg.join adds one reference. Each pg.leave removes exactly one reference.
-- A process must leave as many times as it joined to be fully removed.
local assert = require("assert")
local pg = require("pg")

local function main()
    local group = "test.leave_refcount"
    local join_count = 5

    -- join the group N times
    for i = 1, join_count do
        local ok, err = pg.join(group)
        assert.no_error(ok, err, "join #" .. i .. " should succeed")
    end

    -- verify N membership entries
    local members, err = pg.get_members(group)
    assert.no_error(members, err, "get_members after joins")
    assert.eq(#members, join_count, "should have " .. join_count .. " entries after " .. join_count .. " joins")

    -- all entries should be the same PID (our own)
    local my_pid = members[1]
    for i = 2, #members do
        assert.eq(members[i], my_pid, "all entries should be the same PID")
    end

    -- leave one at a time and verify count decreases by exactly 1
    for i = 1, join_count do
        local ok2, err2 = pg.leave(group)
        assert.no_error(ok2, err2, "leave #" .. i .. " should succeed")

        local remaining = join_count - i
        members, err = pg.get_members(group)
        assert.no_error(members, err, "get_members after leave #" .. i)
        assert.eq(#members, remaining, "should have " .. remaining .. " entries after " .. i .. " leaves")
    end

    -- one more leave should error (not joined)
    local val, leave_err = pg.leave(group)
    assert.has_error(val, leave_err, "leaving fully-left group should error")
end

return { main = main }
