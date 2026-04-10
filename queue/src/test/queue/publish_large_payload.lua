-- Test: publish a message with a large payload
local assert = require("assert")
local queue = require("queue")

local function main()
    -- build a table with 100 items
    local items = {}
    for i = 1, 100 do
        items[i] = {
            id = i,
            name = "item_" .. i,
            value = i * 3.14,
            active = (i % 2 == 0),
            tags = { "tag_" .. i, "batch" },
        }
    end

    local ok, err = queue.publish("app:tasks", {
        action = "bulk_import",
        items = items,
        count = 100,
    })
    assert.no_error(ok, err, "publish large payload should succeed")
    assert.eq(ok, true, "publish should return true")
end

return { main = main }
