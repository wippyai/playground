-- Test: close monitor with {flush=true} drains all buffered events
local assert = require("assert")
local pg = require("pg")
local scope = pg.open("app:pg")
local time = require("time")

local function main()
    local group = "test.monitor_close_flush"

    -- subscribe to monitor for this group
    local sub, members, err = scope:monitor(group)
    assert.no_error(sub, err, "pg.monitor should succeed")
    assert.eq(#members, 0, "initial members should be empty")

    local ch = sub:channel()

    -- join self multiple times to generate several events
    for i = 1, 3 do
        local ok, jerr = scope:join(group)
        assert.no_error(ok, jerr, "join #" .. i)
    end

    -- small sleep to let events buffer
    time.sleep("200ms")

    -- close with flush - should drain all buffered events
    local ok = sub:close({flush = true})
    assert.ok(ok, "close with flush should return true")

    -- after flush, channel should be drained; receive should return nil or timeout quickly
    local timeout = time.after("500ms")
    local pending_count = 0
    while true do
        local result = channel.select{
            ch:case_receive(),
            timeout:case_receive(),
        }
        if result.channel == timeout then
            break
        end
        -- if we get a value, it's a leftover drained event or nil (closed)
        if result.value == nil then
            break
        end
        pending_count = pending_count + 1
    end

    -- after flush, there should be no pending events left (all were drained)
    assert.eq(pending_count, 0, "no pending events should remain after flush")

    -- cleanup remaining joins
    for i = 1, 3 do
        scope:leave(group)
    end
end

return { main = main }
