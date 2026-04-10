-- Worker: joins a group, listens for a broadcast, reports payload back.
-- Used by broadcast_multi_payload and broadcast_no_payload tests.
local pg = require("pg")
local scope = pg.open("app:pg")
local time = require("time")

local function main()
    local setup_ch = process.listen("setup")
    local setup_msg = setup_ch:receive()

    local group = setup_msg.group
    local parent_pid = setup_msg.parent_pid

    -- join the group
    scope:join(group)

    -- signal ready
    process.send(parent_pid, "ready", true)

    -- listen for broadcast
    local bcast_ch = process.listen("pg.multi.payload", { message = true })
    local timeout = time.after("5s")

    local result = channel.select{
        bcast_ch:case_receive(),
        timeout:case_receive(),
    }

    if result.channel ~= timeout then
        local msg = result.value
        process.send(parent_pid, "confirm", {
            received = true,
            payload = msg:payload(),
        })
    else
        process.send(parent_pid, "confirm", {
            received = false,
        })
    end

    scope:leave(group)
end

return { main = main }
