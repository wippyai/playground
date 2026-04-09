-- Test: pg.leave() with a table of groups (batch leave)
local assert = require("assert")
local pg = require("pg")

local function main()
    local groups = {"test.batch_leave.a", "test.batch_leave.b", "test.batch_leave.c"}

    -- join all groups individually first
    for _, group in ipairs(groups) do
        local ok, err = pg.join(group)
        assert.no_error(ok, err, "join " .. group)
    end

    -- verify all groups have members
    for _, group in ipairs(groups) do
        local members, err = pg.get_members(group)
        assert.no_error(members, err, "get_members " .. group)
        assert.eq(#members, 1, group .. " should have 1 member before leave")
    end

    -- batch leave all 3 groups at once
    local ok, err = pg.leave(groups)
    assert.no_error(ok, err, "batch leave should succeed")

    -- verify all groups are now empty
    for _, group in ipairs(groups) do
        local members, merr = pg.get_members(group)
        assert.no_error(members, merr, "get_members after leave " .. group)
        assert.eq(#members, 0, group .. " should be empty after batch leave")
    end
end

return { main = main }
