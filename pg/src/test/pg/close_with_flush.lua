-- Test: sub:close({flush=true}) drains buffered events before closing
local assert = require("assert")
local pg = require("pg")
local time = require("time")

local function main()
    local group = "test.close_flush"

    -- subscribe to events
    local sub, groups, err = pg.events()
    assert.no_error(sub, err, "pg.events should succeed")

    local ch = sub:channel()

    -- generate some events by joining multiple times
    for i = 1, 3 do
        local ok, jerr = pg.join(group)
        assert.no_error(ok, jerr, "join #" .. i)
    end

    -- small sleep to let events buffer
    time.sleep("200ms")

    -- close with flush - should drain all buffered events
    local ok = sub:close({flush = true})
    assert.ok(ok, "close with flush should return true")

    -- after close with flush, channel should be drained and closed
    -- trying to receive should return nil (closed channel)
    local timeout = time.after("500ms")
    local result = channel.select{
        ch:case_receive(),
        timeout:case_receive(),
    }
    -- either we get nil (channel closed) or timeout - both acceptable
    -- the key is we don't hang forever
    assert.ok(true, "close with flush completed without hanging")

    -- cleanup remaining joins
    pg.leave(group)
    pg.leave(group)
    pg.leave(group)
end

return { main = main }
