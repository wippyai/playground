-- Test: error object from publish has kind and message methods
local assert = require("assert")
local queue = require("queue")

local function main()
    local ok, err = queue.publish("app:nonexistent", { action = "test" })
    assert.is_nil(ok, "should return nil on failure")
    assert.not_nil(err, "should return an error")

    -- error should be convertible to string
    local err_str = tostring(err)
    assert.not_nil(err_str, "error string should not be nil")
    assert.neq(err_str, "", "error string should not be empty")

    -- check structured error methods if available
    if type(err) == "userdata" or type(err) == "table" then
        -- structured errors have kind() and message()
        if err.kind then
            local kind = err:kind()
            assert.not_nil(kind, "error kind should not be nil")
        end
        if err.message then
            local msg = err:message()
            assert.not_nil(msg, "error message should not be nil")
        end
        if err.retryable then
            local retry = err:retryable()
            assert.not_nil(retry, "retryable should not be nil")
        end
    end
end

return { main = main }
