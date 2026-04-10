-- Test: publish with special characters in data
local assert = require("assert")
local queue = require("queue")

local function main()
    local ok, err = queue.publish("app:tasks", {
        action = "special_chars",
        emoji = "Hello 🌍🎉",
        unicode = "日本語テスト",
        newlines = "line1\nline2\nline3",
        tabs = "col1\tcol2\tcol3",
        quotes = 'He said "hello"',
        backslash = "path\\to\\file",
        html = "<script>alert('xss')</script>",
        url = "https://example.com/path?q=1&b=2",
    })
    assert.no_error(ok, err, "publish with special chars should succeed")
    assert.eq(ok, true, "publish should return true")
end

return { main = main }
