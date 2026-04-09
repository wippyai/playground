-- Test: batch leave when not joined to any group returns error
local assert = require("assert")
local pg = require("pg")

local function main()
    local groups = {
        "test.batch_leave_none.x",
        "test.batch_leave_none.y",
        "test.batch_leave_none.z",
    }

    -- process is not in any of these groups
    local ok, err = pg.leave(groups)
    assert.has_error(ok, err, "batch leave should fail when not in any group")
end

return { main = main }
