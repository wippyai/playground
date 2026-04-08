-- Test: empty group name returns errors for all group-based operations
-- Erlang PG requires a valid group name (atom/term). We require non-empty string.
local assert = require("assert")
local pg = require("pg")

local function main()
    -- pg.join("") should error
    local ok, err = pg.join("")
    assert.has_error(ok, err, "pg.join('') should return error")

    -- pg.leave("") should error
    ok, err = pg.leave("")
    assert.has_error(ok, err, "pg.leave('') should return error")

    -- pg.get_members("") should error
    ok, err = pg.get_members("")
    assert.has_error(ok, err, "pg.get_members('') should return error")

    -- pg.get_local_members("") should error
    ok, err = pg.get_local_members("")
    assert.has_error(ok, err, "pg.get_local_members('') should return error")

    -- pg.broadcast("", "topic", "data") should error
    ok, err = pg.broadcast("", "topic", "data")
    assert.has_error(ok, err, "pg.broadcast('') should return error")

    -- pg.broadcast_local("", "topic", "data") should error
    ok, err = pg.broadcast_local("", "topic", "data")
    assert.has_error(ok, err, "pg.broadcast_local('') should return error")
end

return { main = main }
