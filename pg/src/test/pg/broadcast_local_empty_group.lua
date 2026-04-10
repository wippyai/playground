-- Test: broadcast_local to an empty group succeeds (no-op, no error)
local assert = require("assert")
local pg = require("pg")
local scope = pg.open("app:pg")

local function main()
    local group = "test.broadcast_local_empty_group_nonexistent"

    -- broadcast_local to a group with no members should succeed (no-op)
    local ok, err = scope:broadcast_local(group, "pg.broadcast", "hello nobody")
    assert.no_error(ok, err, "broadcast_local to empty group should succeed")
end

return { main = main }
