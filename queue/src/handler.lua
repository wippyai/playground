-- handler.lua: queue consumer handler for the tasks queue
local queue = require("queue")
local logger = require("logger")

local function handle()
    local msg, err = queue.message()
    if err then
        logger:error("failed to get message", { error = tostring(err) })
        return
    end

    local id = msg:id()
    local headers = msg:headers()

    logger:info("processing message", {
        msg_id = id,
        headers = headers,
    })
end

return { handle = handle }
