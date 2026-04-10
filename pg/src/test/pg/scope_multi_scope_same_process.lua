-- Test: multiple scopes in the same process each maintain independent membership
local assert = require("assert")
local pg = require("pg")

local function main()
    local group = "test.multi_scope"

    -- create 3 scopes
    local s_alpha = pg.scope("alpha")
    local s_beta = pg.scope("beta")
    local s_gamma = pg.scope("gamma")

    -- join the same group name in each scope
    local ok, err
    ok, err = s_alpha.join(group)
    assert.no_error(ok, err, "alpha join should succeed")
    ok, err = s_beta.join(group)
    assert.no_error(ok, err, "beta join should succeed")
    ok, err = s_gamma.join(group)
    assert.no_error(ok, err, "gamma join should succeed")

    -- verify each scope's get_members returns 1 member
    local members, merr
    members, merr = s_alpha.get_members(group)
    assert.no_error(members, merr, "alpha get_members")
    assert.eq(#members, 1, "alpha scope should have 1 member")

    members, merr = s_beta.get_members(group)
    assert.no_error(members, merr, "beta get_members")
    assert.eq(#members, 1, "beta scope should have 1 member")

    members, merr = s_gamma.get_members(group)
    assert.no_error(members, merr, "gamma get_members")
    assert.eq(#members, 1, "gamma scope should have 1 member")

    -- verify each scope's which_groups returns the group
    local scopes = { { name = "alpha", scope = s_alpha }, { name = "beta", scope = s_beta }, { name = "gamma", scope = s_gamma } }
    for _, entry in ipairs(scopes) do
        local groups, gerr = entry.scope.which_groups()
        assert.no_error(groups, gerr, entry.name .. " which_groups")
        local found = false
        for _, g in ipairs(groups) do
            if g == group then
                found = true
            end
        end
        assert.ok(found, entry.name .. " which_groups should include " .. group)
    end

    -- verify global which_groups contains all 3 prefixed entries
    local all_groups, aerr = pg.which_groups()
    assert.no_error(all_groups, aerr, "global which_groups")
    local global_found = {}
    for _, g in ipairs(all_groups) do
        global_found[g] = true
    end
    assert.ok(global_found["alpha::" .. group], "global should contain alpha::" .. group)
    assert.ok(global_found["beta::" .. group], "global should contain beta::" .. group)
    assert.ok(global_found["gamma::" .. group], "global should contain gamma::" .. group)

    -- cleanup: leave all scopes
    s_alpha.leave(group)
    s_beta.leave(group)
    s_gamma.leave(group)
end

return { main = main }
