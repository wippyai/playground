-- Test: batch leave with partial membership (best-effort semantics)
-- Process is in groups A and C but NOT B. pg.leave({"A","B","C"}) should
-- succeed (leave A and C, skip B) — not fail because of B.
local assert = require("assert")
local pg = require("pg")

local function main()
    local groupA = "test.batch_leave_partial.a"
    local groupB = "test.batch_leave_partial.b"
    local groupC = "test.batch_leave_partial.c"

    -- join A and C only (not B)
    local ok, err = pg.join(groupA)
    assert.no_error(ok, err, "join groupA")
    ok, err = pg.join(groupC)
    assert.no_error(ok, err, "join groupC")

    -- verify membership
    local members
    members, err = pg.get_members(groupA)
    assert.no_error(members, err, "get_members groupA")
    assert.eq(#members, 1, "groupA should have 1 member")

    members, err = pg.get_members(groupB)
    assert.no_error(members, err, "get_members groupB")
    assert.eq(#members, 0, "groupB should be empty (never joined)")

    members, err = pg.get_members(groupC)
    assert.no_error(members, err, "get_members groupC")
    assert.eq(#members, 1, "groupC should have 1 member")

    -- batch leave all 3 — should succeed because A and C were left
    ok, err = pg.leave({groupA, groupB, groupC})
    assert.no_error(ok, err, "batch leave should succeed (best-effort)")

    -- verify all are now empty
    members, err = pg.get_members(groupA)
    assert.no_error(members, err, "get_members groupA after leave")
    assert.eq(#members, 0, "groupA should be empty after leave")

    members, err = pg.get_members(groupC)
    assert.no_error(members, err, "get_members groupC after leave")
    assert.eq(#members, 0, "groupC should be empty after leave")
end

return { main = main }
