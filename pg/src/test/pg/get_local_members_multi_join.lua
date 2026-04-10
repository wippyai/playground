-- Test: get_local_members returns duplicate PIDs for multi-joined processes
-- In Erlang PG, a process joined N times appears N times in both
-- get_members and get_local_members.
local assert = require("assert")
local pg = require("pg")
local scope = pg.open("app:pg")

local function main()
    local group = "test.local_members_multi_join"

    -- join the same group 4 times
    for i = 1, 4 do
        local ok, err = scope:join(group)
        assert.no_error(ok, err, "pg.join #" .. i .. " should succeed")
    end

    -- get_members should show 4 entries (all same PID)
    local members, err = scope:get_members(group)
    assert.no_error(members, err, "get_members should succeed")
    assert.eq(#members, 4, "get_members should return 4 entries for 4 joins")

    -- get_local_members should also show 4 entries
    local local_members, lerr = scope:get_local_members(group)
    assert.no_error(local_members, lerr, "get_local_members should succeed")
    assert.eq(#local_members, 4, "get_local_members should return 4 entries for 4 joins")

    -- all entries should be the same PID
    local my_pid = members[1]
    for i = 2, 4 do
        assert.eq(members[i], my_pid, "all members should be the same PID")
        assert.eq(local_members[i], my_pid, "all local members should be the same PID")
    end

    -- cleanup
    for i = 1, 4 do
        scope:leave(group)
    end
end

return { main = main }
