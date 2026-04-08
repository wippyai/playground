-- Worker: joins a group and listens for broadcast messages.
-- Sends confirmation back to the parent when a message is received.
local pg = require("pg")
local time = require("time")

local function main()
    -- listen for setup instructions from parent
    local setup_ch = process.listen("setup")
    local setup_msg = setup_ch:receive()

    -- setup_msg contains: { group = "...", confirm_topic = "...", parent_pid = "..." }
    local group = setup_msg.group
    local confirm_topic = setup_msg.confirm_topic
    local parent_pid = setup_msg.parent_pid

    -- join the group
    pg.join(group)

    -- signal to parent that we are ready
    process.send(parent_pid, "ready", true)

    -- wait for a broadcast message on the broadcast topic
    local bcast_ch = process.listen("pg.broadcast", { message = true })
    local timeout = time.after("5s")

    local result = channel.select{
        bcast_ch:case_receive(),
        timeout:case_receive(),
    }

    if result.channel ~= timeout then
        -- got broadcast, send confirmation back to parent
        local msg = result.value
        process.send(parent_pid, confirm_topic, {
            received = true,
            payload = msg:payload(),
        })
    else
        -- timeout
        process.send(parent_pid, confirm_topic, {
            received = false,
            payload = "timeout",
        })
    end

    -- leave and exit
    pg.leave(group)
end

return { main = main }
