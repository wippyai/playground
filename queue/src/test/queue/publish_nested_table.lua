-- Test: publish deeply nested table data
local assert = require("assert")
local queue = require("queue")

local function main()
    local data = {
        user = {
            name = "Alice",
            age = 30,
            address = {
                street = "123 Main St",
                city = "Wonderland",
                coords = {
                    lat = 51.5074,
                    lng = -0.1278,
                },
            },
            tags = { "admin", "active", "verified" },
        },
        metadata = {
            version = 2,
            created = true,
        },
    }

    local ok, err = queue.publish("app:tasks", data)
    assert.no_error(ok, err, "publish nested table should succeed")
    assert.eq(ok, true, "publish should return true")
end

return { main = main }
