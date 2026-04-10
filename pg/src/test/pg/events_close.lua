-- Test: scope:events() subscription close is clean and idempotent
local assert = require("assert")
local pg = require("pg")
local scope = pg.open("app:pg")

local function main()
    -- subscribe to pg events
    local sub, groups, err = scope:events()
    assert.no_error(sub, err, "pg.events should succeed")

    -- get channel to verify it works
    local ch = sub:channel()
    assert.not_nil(ch, "channel should not be nil")

    -- close the subscription
    local ok = sub:close()
    assert.ok(ok, "close should return true")

    -- close again (idempotent)
    ok = sub:close()
    assert.ok(ok, "second close should also return true")
end

return { main = main }
