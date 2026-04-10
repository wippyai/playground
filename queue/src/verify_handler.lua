-- verify_handler.lua: consumer handler that verifies message content and
-- reports results back to the test process via process.send.
--
-- Protocol:
--   1. Test registers itself as "queue_test" in the process registry.
--   2. Test publishes a message with header "x_test_id" = <unique test id>.
--   3. This handler receives the message, extracts all info, and sends
--      the result back to the registered "queue_test" process.
local queue = require("queue")
local logger = require("logger")
local process = require("process")

local function handle()
    local msg, err = queue.message()
    if err then
        logger:error("verify_handler: failed to get message", { error = tostring(err) })
        return
    end

    local id = msg:id()
    local headers = msg:headers()

    -- look up the test process
    local test_pid, lookup_err = process.registry.lookup("queue_test")
    if lookup_err or not test_pid then
        -- no test process registered, just log and return (normal handler mode)
        logger:info("verify_handler: no test process registered, skipping", {
            msg_id = id,
        })
        return
    end

    -- extract x_test_id to route result to correct test
    local test_id = nil
    if headers then
        test_id = headers["x_test_id"]
    end

    -- build result payload
    local result = {
        msg_id = id,
        headers = headers or {},
        test_id = test_id,
        has_id = (id ~= nil and id ~= ""),
    }

    -- send individual header checks
    if headers then
        -- check specific header via msg:header()
        local priority, _ = msg:header("priority")
        result.header_priority = priority

        local correlation_id, _ = msg:header("correlation_id")
        result.header_correlation_id = correlation_id

        local nonexistent, _ = msg:header("nonexistent_key")
        result.header_nonexistent = nonexistent
    end

    -- send result back to test
    process.send(test_pid, "verify_result", result)
end

return { handle = handle }
