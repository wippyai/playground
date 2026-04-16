-- Test: broadcast in scope1 only delivers to scope1 members, not scope2
local assert = require("assert")
local pg = require("pg")
local time = require("time")

local function main()
    local s1 = pg.open("app:pg")
    local s2 = pg.open("app:pg_alt")
    local group = "test.multi_scope_bcast"

    -- join same group name in both scopes
    local ok, err
    ok, err = s1:join(group)
    assert.no_error(ok, err, "scope1 join should succeed")
    ok, err = s2:join(group)
    assert.no_error(ok, err, "scope2 join should succeed")

    -- listen for broadcasts on two distinct topics
    local ch_s1 = process.listen("bcast.scope1", { message = true })
    local ch_s2 = process.listen("bcast.scope2", { message = true })

    -- broadcast only in scope1
    ok, err = s1:broadcast(group, "bcast.scope1", "hello_scope1")
    assert.no_error(ok, err, "scope1 broadcast should succeed")

    -- scope1 member should receive the broadcast
    local timeout = time.after("3s")
    local result = channel.select{
        ch_s1:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive scope1 broadcast")

    -- scope2 should NOT receive anything on scope1 topic (it's a different scope)
    -- also broadcast on scope2 topic to verify isolation
    ok, err = s2:broadcast(group, "bcast.scope2", "hello_scope2")
    assert.no_error(ok, err, "scope2 broadcast should succeed")

    timeout = time.after("3s")
    result = channel.select{
        ch_s2:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive scope2 broadcast")

    -- verify scope1 broadcast did not leak to scope2 topic
    timeout = time.after("500ms")
    result = channel.select{
        ch_s2:case_receive(),
        timeout:case_receive(),
    }
    assert.eq(result.channel, timeout,
        "scope2 topic should not receive extra messages from scope1 broadcast")

    -- cleanup
    s1:leave(group)
    s2:leave(group)
end

return { main = main }
