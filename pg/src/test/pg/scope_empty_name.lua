-- Test: pg.open('') with empty resource ID returns error
local assert = require("assert")
local pg = require("pg")

local function main()
    -- calling pg.open with an empty string should return (nil, error)
    local s, err = pg.open("")
    assert.has_error(s, err, "pg.open('') should return an error")
end

return { main = main }
