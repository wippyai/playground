-- Worker: joins a group, signals ready, waits for a command, optionally leaves, then exits.
-- Used by multi_process_membership test.
local pg = require("pg")
local scope = pg.open("app:pg")
local time = require("time")

local function main()
    local setup_ch = process.listen("setup")
    local setup_msg = setup_ch:receive()

    local group = setup_msg.group
    local parent_pid = setup_msg.parent_pid
    local worker_id = setup_msg.worker_id

    -- join the group
    scope:join(group)

    -- signal ready with our worker_id
    process.send(parent_pid, "ready", { worker_id = worker_id })

    -- wait for a command from parent
    local cmd_ch = process.listen("command")
    local timeout = time.after("5s")
    local result = channel.select{
        cmd_ch:case_receive(),
        timeout:case_receive(),
    }

    if result.channel ~= timeout then
        local cmd = result.value
        if cmd == "leave" then
            scope:leave(group)
            process.send(parent_pid, "left", { worker_id = worker_id })
        end
    end

    -- keep alive briefly for parent to inspect state, then exit
    time.sleep("500ms")
end

return { main = main }
