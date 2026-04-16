-- Test: rapidly join/leave same group 10 times, verify we get at least 10 join and 10 leave events
local assert = require("assert")
local pg = require("pg")
local scope = pg.open("app:pg")
local time = require("time")

local function main()
    local group = "test.events_rapid_jl"

    -- subscribe to events first
    local sub, groups, err = scope:events()
    assert.no_error(sub, err, "pg.events should succeed")
    local ch = sub:channel()

    -- rapidly join/leave 10 times
    for i = 1, 10 do
        local ok, jerr = scope:join(group)
        assert.no_error(ok, jerr, "join #" .. i)
        local lok, lerr = scope:leave(group)
        assert.no_error(lok, lerr, "leave #" .. i)
    end

    -- collect events with a timeout
    local join_count = 0
    local leave_count = 0
    local timeout = time.after("5s")

    while true do
        local result = channel.select{
            ch:case_receive(),
            timeout:case_receive(),
        }
        if result.channel == timeout then
            break
        end

        local evt = result.value
        if evt and evt.kind == "member.joined" and evt.data and evt.data.Group == group then
            join_count = join_count + 1
        elseif evt and evt.kind == "member.left" and evt.data and evt.data.Group == group then
            leave_count = leave_count + 1
        end

        -- once we have enough, stop
        if join_count >= 10 and leave_count >= 10 then
            break
        end
    end

    assert.ok(join_count >= 10,
        "should receive at least 10 join events, got " .. join_count)
    assert.ok(leave_count >= 10,
        "should receive at least 10 leave events, got " .. leave_count)

    -- cleanup
    sub:close()
end

return { main = main }
