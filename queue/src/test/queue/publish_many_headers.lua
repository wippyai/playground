-- Test: publish with many custom headers
local assert = require("assert")
local queue = require("queue")

local function main()
    local headers = {}
    for i = 1, 20 do
        headers["x_custom_" .. i] = "value_" .. i
    end
    headers["priority"] = 3
    headers["correlation_id"] = "batch-hdr-test"

    local ok, err = queue.publish("app:tasks", {
        action = "many_headers",
    }, headers)
    assert.no_error(ok, err, "publish with many headers should succeed")
    assert.eq(ok, true, "publish should return true")
end

return { main = main }
