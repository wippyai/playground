-- Test: empty group name returns errors for all group-based operations
-- Erlang PG requires a valid group name (atom/term). We require non-empty string.
local assert = require("assert")
local pg = require("pg")
local scope = pg.open("app:pg")

local function main()
    -- scope:join("") should error
    local ok, err = scope:join("")
    assert.has_error(ok, err, "scope:join('') should return error")

    -- scope:leave("") should error
    ok, err = scope:leave("")
    assert.has_error(ok, err, "scope:leave('') should return error")

    -- scope:get_members("") should error
    ok, err = scope:get_members("")
    assert.has_error(ok, err, "scope:get_members('') should return error")

    -- scope:get_local_members("") should error
    ok, err = scope:get_local_members("")
    assert.has_error(ok, err, "scope:get_local_members('') should return error")

    -- scope:broadcast("", "topic", "data") should error
    ok, err = scope:broadcast("", "topic", "data")
    assert.has_error(ok, err, "scope:broadcast('') should return error")

    -- scope:broadcast_local("", "topic", "data") should error
    ok, err = scope:broadcast_local("", "topic", "data")
    assert.has_error(ok, err, "scope:broadcast_local('') should return error")
end

return { main = main }
