-- Test: multiple instances in the same process each maintain independent membership
local assert = require("assert")
local pg = require("pg")

local function main()
    local group = "test.multi_scope"

    -- create 3 instances
    local s_alpha = pg.open("app:pg")
    local s_beta = pg.open("app:pg_alt")
    local s_gamma = pg.open("app:pg_alt2")

    -- join the same group name in each instance
    local ok, err
    ok, err = s_alpha:join(group)
    assert.no_error(ok, err, "alpha join should succeed")
    ok, err = s_beta:join(group)
    assert.no_error(ok, err, "beta join should succeed")
    ok, err = s_gamma:join(group)
    assert.no_error(ok, err, "gamma join should succeed")

    -- verify each instance's get_members returns 1 member
    local members, merr
    members, merr = s_alpha:get_members(group)
    assert.no_error(members, merr, "alpha get_members")
    assert.eq(#members, 1, "alpha instance should have 1 member")

    members, merr = s_beta:get_members(group)
    assert.no_error(members, merr, "beta get_members")
    assert.eq(#members, 1, "beta instance should have 1 member")

    members, merr = s_gamma:get_members(group)
    assert.no_error(members, merr, "gamma get_members")
    assert.eq(#members, 1, "gamma instance should have 1 member")

    -- verify each instance's which_groups returns the group
    local instances = { { name = "alpha", scope = s_alpha }, { name = "beta", scope = s_beta }, { name = "gamma", scope = s_gamma } }
    for _, entry in ipairs(instances) do
        local groups, gerr = entry.scope:which_groups()
        assert.no_error(groups, gerr, entry.name .. " which_groups")
        local found = false
        for _, g in ipairs(groups) do
            if g == group then
                found = true
            end
        end
        assert.ok(found, entry.name .. " which_groups should include " .. group)
    end

    -- cleanup: leave all instances
    s_alpha:leave(group)
    s_beta:leave(group)
    s_gamma:leave(group)
end

return { main = main }
