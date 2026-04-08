-- Test: empty topic for broadcast/broadcast_local returns errors
local assert = require("assert")
local pg = require("pg")

local function main()
    -- pg.broadcast with empty topic should error
    local ok, err = pg.broadcast("some-group", "", "data")
    assert.has_error(ok, err, "pg.broadcast with empty topic should return error")

    -- pg.broadcast_local with empty topic should error
    ok, err = pg.broadcast_local("some-group", "", "data")
    assert.has_error(ok, err, "pg.broadcast_local with empty topic should return error")
end

return { main = main }
