-- Test: release a scope instance while joined
-- PG membership is tied to process lifetime, not resource handle lifetime.
-- Releasing the handle simply drops the reference; the process is still
-- a member of the group until it exits (Erlang PG semantics).
local assert = require("assert")
local pg = require("pg")

local function main()
    local group = "test.release_while_joined"

    -- open a scope and join a group
    local s1 = pg.open("app:pg")
    local ok, err = s1:join(group)
    assert.no_error(ok, err, "join should succeed")

    -- verify membership exists
    local members, merr = s1:get_members(group)
    assert.no_error(members, merr, "get_members should succeed")
    assert.eq(#members, 1, "should have 1 member before release")

    -- release the scope instance (drops reference, not membership)
    s1:release()

    -- open a fresh instance and verify membership still exists
    -- (membership is per-process, not per-handle)
    local s2 = pg.open("app:pg")
    members, merr = s2:get_members(group)
    assert.no_error(members, merr, "get_members from fresh instance")
    assert.eq(#members, 1,
        "should still have 1 member after releasing handle (membership is per-process)")

    -- clean up: leave the group via the new handle
    s2:leave(group)
    members, merr = s2:get_members(group)
    assert.no_error(members, merr, "get_members after leave")
    assert.eq(#members, 0, "should have 0 members after explicit leave")

    return true
end

return { main = main }
