-- Worker: joins a group N times and counts how many broadcast messages it receives.
-- Reports the count back to the parent. Tests Erlang PG semantics where
-- N joins = N entries in get_members = N broadcast deliveries.
local pg = require("pg")
local time = require("time")

local function main()
    local setup_ch = process.listen("setup")
    local setup_msg = setup_ch:receive()

    local group = setup_msg.group
    local join_count = setup_msg.join_count
    local parent_pid = setup_msg.parent_pid

    -- join the group N times
    for i = 1, join_count do
        pg.join(group)
    end

    -- signal ready
    process.send(parent_pid, "ready", true)

    -- listen for broadcast messages and count them
    local bcast_ch = process.listen("pg.multi.bcast", { message = true })
    local received_count = 0

    -- collect messages: we expect exactly join_count messages
    -- use a short timeout to detect when no more messages arrive
    while true do
        local timeout = time.after("2s")
        local result = channel.select{
            bcast_ch:case_receive(),
            timeout:case_receive(),
        }

        if result.channel == timeout then
            break
        end

        received_count = received_count + 1
    end

    -- report result back to parent
    process.send(parent_pid, "result", {
        received_count = received_count,
        join_count = join_count,
    })

    -- leave all
    for i = 1, join_count do
        pg.leave(group)
    end
end

return { main = main }
