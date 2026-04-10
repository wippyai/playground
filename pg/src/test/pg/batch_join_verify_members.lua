-- Test: batch join followed by individual member verification and batch leave
local assert = require("assert")
local pg = require("pg")
local scope = pg.open("app:pg")

local function main()
    local groups = {"test.bjv.a", "test.bjv.b", "test.bjv.c"}

    -- batch join all 3 groups at once
    local ok, err = scope:join(groups)
    assert.no_error(ok, err, "batch join should succeed")

    -- verify each group individually has exactly 1 member
    for _, group in ipairs(groups) do
        local members, merr = scope:get_members(group)
        assert.no_error(members, merr, "get_members for " .. group)
        assert.eq(#members, 1, group .. " should have exactly 1 member")
    end

    -- batch leave all 3 groups at once
    ok, err = scope:leave(groups)
    assert.no_error(ok, err, "batch leave should succeed")

    -- verify all groups are now empty
    for _, group in ipairs(groups) do
        local members, merr = scope:get_members(group)
        assert.no_error(members, merr, "get_members after leave for " .. group)
        assert.eq(#members, 0, group .. " should be empty after batch leave")
    end
end

return { main = main }
