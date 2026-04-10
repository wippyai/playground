-- Test: rapidly join and leave a group 10 times
-- After each join, verify 1 member. After each leave, verify 0 members.
local assert = require("assert")
local pg = require("pg")
local scope = pg.open("app:pg")

local function main()
    local group = "test.rapid"

    for i = 1, 10 do
        -- join
        local ok, err = scope:join(group)
        assert.no_error(ok, err, "pg.join cycle " .. i .. " should succeed")

        local members, merr = scope:get_members(group)
        assert.no_error(members, merr, "get_members after join cycle " .. i)
        assert.eq(#members, 1, "should have 1 member after join cycle " .. i)

        -- leave
        ok, err = scope:leave(group)
        assert.no_error(ok, err, "pg.leave cycle " .. i .. " should succeed")

        members, merr = scope:get_members(group)
        assert.no_error(members, merr, "get_members after leave cycle " .. i)
        assert.eq(#members, 0, "should have 0 members after leave cycle " .. i)
    end

    -- verify the group is truly empty after the loop
    local members, merr = scope:get_members(group)
    assert.no_error(members, merr, "get_members final check")
    assert.eq(#members, 0, "group should be truly empty after all cycles")
end

return { main = main }
