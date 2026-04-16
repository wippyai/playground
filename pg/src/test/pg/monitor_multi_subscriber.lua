-- Test: 3 separate monitors on same group from same process all receive events
local assert = require("assert")
local pg = require("pg")
local scope = pg.open("app:pg")
local time = require("time")

local function main()
    local group = "test.monitor_multi_sub"

    -- create 3 monitors on the same group
    local subs = {}
    local channels = {}
    for i = 1, 3 do
        local sub, members, err = scope:monitor(group)
        assert.no_error(sub, err, "monitor #" .. i .. " should succeed")
        assert.eq(#members, 0, "initial members for monitor #" .. i .. " should be empty")
        subs[i] = sub
        channels[i] = sub:channel()
    end

    -- join the group - should trigger a join event on all 3 monitors
    local ok, err = scope:join(group)
    assert.no_error(ok, err, "pg.join should succeed")

    -- verify all 3 monitors receive the join event
    for i = 1, 3 do
        local timeout = time.after("3s")
        local result = channel.select{
            channels[i]:case_receive(),
            timeout:case_receive(),
        }
        assert.neq(result.channel, timeout,
            "monitor #" .. i .. " should receive join event (not timeout)")

        local evt = result.value
        assert.not_nil(evt, "monitor #" .. i .. " event should not be nil")
        assert.eq(evt.kind, "member.joined",
            "monitor #" .. i .. " event kind should be 'member.joined'")
        assert.eq(evt.path, group,
            "monitor #" .. i .. " event path should be the group name")
    end

    -- cleanup
    scope:leave(group)
    for i = 1, 3 do
        subs[i]:close()
    end
end

return { main = main }
