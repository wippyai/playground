-- Test: a single process can join multiple different groups simultaneously
-- Erlang PG: each group is independent, joining group A does not affect group B
local assert = require("assert")
local pg = require("pg")
local scope = pg.open("app:pg")

local function main()
    local groups = {
        "test.multi_grp.alpha",
        "test.multi_grp.beta",
        "test.multi_grp.gamma",
    }

    -- join all three groups
    for _, g in ipairs(groups) do
        local ok, err = scope:join(g)
        assert.no_error(ok, err, "join " .. g .. " should succeed")
    end

    -- verify membership in each group independently
    for _, g in ipairs(groups) do
        local members, err = scope:get_members(g)
        assert.no_error(members, err, "get_members " .. g)
        assert.eq(#members, 1, g .. " should have exactly 1 member")
    end

    -- all three groups should appear in which_groups
    local all_groups, err = scope:which_groups()
    assert.no_error(all_groups, err, "which_groups should succeed")
    for _, g in ipairs(groups) do
        local found = false
        for _, wg in ipairs(all_groups) do
            if wg == g then found = true; break end
        end
        assert.ok(found, g .. " should appear in which_groups")
    end

    -- leave group beta only
    local ok, err2 = scope:leave(groups[2])
    assert.no_error(ok, err2, "leave beta should succeed")

    -- alpha and gamma should still have 1 member, beta should have 0
    local m_alpha, _ = scope:get_members(groups[1])
    assert.eq(#m_alpha, 1, "alpha should still have 1 member after leaving beta")

    local m_beta, _ = scope:get_members(groups[2])
    assert.eq(#m_beta, 0, "beta should have 0 members after leave")

    local m_gamma, _ = scope:get_members(groups[3])
    assert.eq(#m_gamma, 1, "gamma should still have 1 member after leaving beta")

    -- cleanup remaining
    scope:leave(groups[1])
    scope:leave(groups[3])
end

return { main = main }
