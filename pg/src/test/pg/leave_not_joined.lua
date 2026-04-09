-- Test: single leave for a group the process never joined returns error
local assert = require("assert")
local pg = require("pg")

local function main()
    local group = "test.leave_never_joined_at_all"

    -- attempting to leave a group we never joined should return an error
    local val, err = pg.leave(group)
    assert.has_error(val, err, "leaving a never-joined group should error")
end

return { main = main }
