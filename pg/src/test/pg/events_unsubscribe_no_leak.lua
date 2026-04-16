-- Test: after closing events subscription, no events are received
local assert = require("assert")
local pg = require("pg")
local scope = pg.open("app:pg")
local time = require("time")

local function main()
    local group = "test.events_unsub_no_leak"

    -- subscribe to events
    local sub, groups, err = scope:events()
    assert.no_error(sub, err, "pg.events should succeed")
    local ch = sub:channel()

    -- close the subscription immediately
    local ok = sub:close()
    assert.ok(ok, "close should return true")

    -- now join and leave a group - should not produce any events
    local jok, jerr = scope:join(group)
    assert.no_error(jok, jerr, "join should succeed")
    local lok, lerr = scope:leave(group)
    assert.no_error(lok, lerr, "leave should succeed")

    -- wait a bit to see if anything leaks through
    time.sleep("500ms")

    -- try to receive from the closed channel - should get nil or timeout
    local timeout = time.after("500ms")
    local event_count = 0
    while true do
        local result = channel.select{
            ch:case_receive(),
            timeout:case_receive(),
        }
        if result.channel == timeout then
            break
        end
        if result.value == nil then
            break
        end
        event_count = event_count + 1
    end

    assert.eq(event_count, 0,
        "no events should be received after closing subscription, got " .. event_count)
end

return { main = main }
