-- Test: multi-join same group and verify get_local_members count
-- Join 3 times, verify 3 entries (same PID), leave all 3, verify empty.
local assert = require("assert")
local pg = require("pg")
local scope = pg.open("app:pg")

local function main()
    local group = "test.mj_local"

    -- join the same group 3 times
    for i = 1, 3 do
        local ok, err = scope:join(group)
        assert.no_error(ok, err, "pg.join #" .. i .. " should succeed")
    end

    -- get_local_members should return 3 entries
    local local_members, lerr = scope:get_local_members(group)
    assert.no_error(local_members, lerr, "get_local_members should succeed")
    assert.eq(#local_members, 3, "get_local_members should return 3 entries for 3 joins")

    -- all entries should be the same PID
    local my_pid = local_members[1]
    for i = 2, 3 do
        assert.eq(local_members[i], my_pid, "all local members should be the same PID")
    end

    -- leave all 3
    for i = 1, 3 do
        local ok, err = scope:leave(group)
        assert.no_error(ok, err, "pg.leave #" .. i .. " should succeed")
    end

    -- verify get_local_members returns 0
    local_members, lerr = scope:get_local_members(group)
    assert.no_error(local_members, lerr, "get_local_members after all leaves")
    assert.eq(#local_members, 0, "get_local_members should be empty after all leaves")
end

return { main = main }
