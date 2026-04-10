-- Test: join on one instance is NOT visible on another instance (cross-instance isolation)
local assert = require("assert")
local pg = require("pg")

local function main()
    local group = "test.slgv"

    -- create two separate instances
    local s1 = pg.open("app:pg_alt")
    local s2 = pg.open("app:pg_alt2")

    -- join a group on instance 1
    local ok, err = s1:join(group)
    assert.no_error(ok, err, "instance 1 join should succeed")

    -- instance 1 should see the member
    local m1, e1 = s1:get_members(group)
    assert.no_error(m1, e1, "instance 1 get_members should succeed")
    assert.eq(#m1, 1, "instance 1 should have 1 member")

    -- instance 2 should NOT see the member (independent instances)
    local m2, e2 = s2:get_members(group)
    assert.no_error(m2, e2, "instance 2 get_members should succeed")
    assert.eq(#m2, 0, "instance 2 should have 0 members (isolated from instance 1)")

    -- leave via instance 1
    ok, err = s1:leave(group)
    assert.no_error(ok, err, "instance 1 leave should succeed")

    -- verify instance 1 is now empty too
    m1, e1 = s1:get_members(group)
    assert.no_error(m1, e1, "instance 1 get_members after leave")
    assert.eq(#m1, 0, "instance 1 should have 0 members after leave")
end

return { main = main }
