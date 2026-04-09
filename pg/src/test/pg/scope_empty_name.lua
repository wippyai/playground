-- Test: pg.scope('') with empty name returns error
local assert = require("assert")
local pg = require("pg")

local function main()
    -- calling pg.scope with an empty string should return (nil, error)
    local s, err = pg.scope("")
    assert.has_error(s, err, "pg.scope('') should return an error")
end

return { main = main }
