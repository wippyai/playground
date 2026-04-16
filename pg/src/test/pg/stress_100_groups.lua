-- Test: create 100 groups, verify which_groups returns 100, leave all, verify 0
local assert = require("assert")
local pg = require("pg")
local scope = pg.open("app:pg")

local function main()
    local base = "test.stress100."

    -- join 100 groups
    for i = 1, 100 do
        local ok, err = scope:join(base .. i)
        assert.no_error(ok, err, "join group " .. i)
    end

    -- verify which_groups returns at least 100 groups
    local groups, gerr = scope:which_groups()
    assert.no_error(groups, gerr, "which_groups should succeed")

    -- count how many of our groups are present
    local count = 0
    for _, g in ipairs(groups) do
        -- check if this is one of our stress test groups
        if g:sub(1, #base) == base then
            count = count + 1
        end
    end
    assert.eq(count, 100, "should have 100 stress groups, got " .. count)

    -- leave all 100 groups
    for i = 1, 100 do
        local ok, err = scope:leave(base .. i)
        assert.no_error(ok, err, "leave group " .. i)
    end

    -- verify our groups are gone
    groups, gerr = scope:which_groups()
    assert.no_error(groups, gerr, "which_groups after leave should succeed")

    count = 0
    for _, g in ipairs(groups) do
        if g:sub(1, #base) == base then
            count = count + 1
        end
    end
    assert.eq(count, 0, "should have 0 stress groups after leaving, got " .. count)
end

return { main = main }
