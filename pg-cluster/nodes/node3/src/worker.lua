-- worker.lua: PG worker for child wippy nodes in cluster tests.
-- (Same as node2/src/worker.lua — identical worker logic)

local io = require("io")
local pg = require("pg")
local time = require("time")
local channel = require("channel")

local function main(group_name)
    -- Open the PG scope
    local scope, err = pg.open("app:pg")
    if err then
        io.print("ERROR:pg.open failed: " .. tostring(err))
        return 1
    end

    -- First positional CLI arg is the group name (default: "cluster:test")
    local default_group = "cluster:test"
    if group_name and type(group_name) == "string" and #group_name > 0 then
        default_group = group_name
    end

    local action = "default"
    local groups = { default_group }
    local duration = "120s" -- 2 minutes; tests kill the node via SIGTERM well before this

    if action == "join_and_wait" then
        for _, group in ipairs(groups) do
            local _, join_err = scope:join(group)
            if join_err then
                io.print("ERROR:join failed for " .. group .. ": " .. tostring(join_err))
                return 1
            end
            io.print("JOINED:" .. group)
        end

        io.print("READY")

        local bcast_ch = process.inbox()
        local timer = time.after(duration)

        while true do
            local result = channel.select({
                bcast_ch:case_receive(),
                timer:case_receive(),
            })

            if result.channel == bcast_ch then
                local msg = result.value
                local topic = msg:topic() or ""
                local payload_obj = msg:payload()
                local payload_str = ""
                if payload_obj then
                    local data = payload_obj:data()
                    payload_str = data and tostring(data) or tostring(payload_obj)
                end
                io.print("BROADCAST_RECV:" .. topic .. ":" .. payload_str)
            elseif result.channel == timer then
                break
            end
        end

        for _, group in ipairs(groups) do
            scope:leave(group)
            io.print("LEFT:" .. group)
        end

    elseif action == "join_leave_and_exit" then
        for _, group in ipairs(groups) do
            local _, join_err = scope:join(group)
            if join_err then
                io.print("ERROR:join failed for " .. group .. ": " .. tostring(join_err))
                return 1
            end
            io.print("JOINED:" .. group)
        end

        io.print("READY")
        time.sleep(duration)

        for _, group in ipairs(groups) do
            scope:leave(group)
            io.print("LEFT:" .. group)
        end

    elseif action == "join_and_exit" then
        for _, group in ipairs(groups) do
            local _, join_err = scope:join(group)
            if join_err then
                io.print("ERROR:join failed for " .. group .. ": " .. tostring(join_err))
                return 1
            end
            io.print("JOINED:" .. group)
        end

        io.print("READY")
        time.sleep(duration)

    else
        local _, join_err = scope:join(default_group)
        if join_err then
            io.print("ERROR:join failed: " .. tostring(join_err))
            return 1
        end
        io.print("JOINED:" .. default_group)
        io.print("READY")

        -- Listen for broadcasts while waiting
        local bcast_ch = process.inbox()
        local timer = time.after(duration)

        while true do
            local result = channel.select({
                bcast_ch:case_receive(),
                timer:case_receive(),
            })

            if result.channel == bcast_ch then
                local msg = result.value
                local topic = msg:topic() or ""
                local payload_obj = msg:payload()
                local payload_str = ""
                if payload_obj then
                    local data = payload_obj:data()
                    payload_str = data and tostring(data) or tostring(payload_obj)
                end
                io.print("BROADCAST_RECV:" .. topic .. ":" .. payload_str)
            elseif result.channel == timer then
                break
            end
        end

        -- Leave group
        scope:leave(default_group)
        io.print("LEFT:" .. default_group)
    end

    io.print("DONE")
    return 0
end

return { main = main }
