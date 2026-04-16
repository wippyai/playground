-- Worker: registers globally with a given name, echoes messages back.
-- Setup: { name = "...", parent_pid = "..." }
local time = require("time")

local function main()
    local setup_ch = process.listen("setup")
    local setup_msg = setup_ch:receive()

    local name = setup_msg.name
    local parent_pid = setup_msg.parent_pid

    -- register globally
    local ok, err = process.registry.register(name, process.registry.GLOBAL)
    if not ok then
        process.send(parent_pid, "status", "ERROR:" .. tostring(err))
        return
    end

    -- confirm registration
    process.send(parent_pid, "status", "REGISTERED")

    -- echo loop: receive messages on "echo" topic and send them back
    local echo_ch = process.listen("echo")
    local timeout = time.after("10s")

    while true do
        local result = channel.select{
            echo_ch:case_receive(),
            timeout:case_receive(),
        }
        if result.channel == timeout then
            break
        end
        -- echo the payload back to parent
        process.send(parent_pid, "echo_reply", result.value)
    end

    -- deregister on exit
    process.registry.unregister(name, process.registry.GLOBAL)
end

return { main = main }
