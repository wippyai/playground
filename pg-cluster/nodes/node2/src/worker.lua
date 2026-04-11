-- worker.lua: PG worker for child wippy nodes in cluster tests.
--
-- This worker runs as a CLI command (wippy run worker) on child nodes.
-- It performs a sequence of PG operations and prints status lines to stdout
-- that the parent test process reads via exec stdout stream.
--
-- Protocol (stdout lines):
--   READY                           — worker is ready, PG scope acquired
--   JOINED:<group>                  — successfully joined a group
--   LEFT:<group>                    — successfully left a group
--   MEMBERS:<group>:<count>         — member count for a group
--   BROADCAST_RECV:<group>:<topic>:<payload> — received a broadcast message
--   ERROR:<message>                 — an error occurred
--   DONE                            — worker finished all operations
--
-- The worker reads commands from its arguments (passed after -- in the CLI).
-- Since wippy run doesn't support passing args directly to the worker,
-- we use a simpler approach: the worker joins predefined groups and stays alive.

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
        -- Join specified groups and stay alive
        for _, group in ipairs(groups) do
            local _, join_err = scope:join(group)
            if join_err then
                io.print("ERROR:join failed for " .. group .. ": " .. tostring(join_err))
                return 1
            end
            io.print("JOINED:" .. group)
        end

        io.print("READY")

        -- Use inbox to catch broadcast messages (topic varies per test)
        local bcast_ch = process.inbox()
        local timer = time.after(duration)

        while true do
            local result = channel.select({
                bcast_ch:case_receive(),
                timer:case_receive(),
            })

            if result.channel == bcast_ch then
                -- Broadcast received
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
                -- Timeout — time to leave
                break
            end
        end

        -- Leave all groups
        for _, group in ipairs(groups) do
            scope:leave(group)
            io.print("LEFT:" .. group)
        end

    elseif action == "join_leave_and_exit" then
        -- Join groups, signal ready, wait briefly, then leave and exit
        for _, group in ipairs(groups) do
            local _, join_err = scope:join(group)
            if join_err then
                io.print("ERROR:join failed for " .. group .. ": " .. tostring(join_err))
                return 1
            end
            io.print("JOINED:" .. group)
        end

        io.print("READY")

        -- Stay alive for the specified duration then leave
        time.sleep(duration)

        for _, group in ipairs(groups) do
            scope:leave(group)
            io.print("LEFT:" .. group)
        end

    elseif action == "join_and_exit" then
        -- Join groups, signal ready, wait briefly, then just exit (no explicit leave)
        -- This tests cleanup on node departure
        for _, group in ipairs(groups) do
            local _, join_err = scope:join(group)
            if join_err then
                io.print("ERROR:join failed for " .. group .. ": " .. tostring(join_err))
                return 1
            end
            io.print("JOINED:" .. group)
        end

        io.print("READY")

        -- Stay alive for the specified duration then exit without leaving
        time.sleep(duration)

    else
        -- Default: join the group, signal ready, listen for broadcasts, and wait
        local _, join_err = scope:join(default_group)
        if join_err then
            io.print("ERROR:join failed: " .. tostring(join_err))
            return 1
        end
        io.print("JOINED:" .. default_group)
        io.print("READY")

        -- Use inbox to catch broadcast messages (topic varies per test)
        local bcast_ch = process.inbox()
        local timer = time.after(duration)

        while true do
            local result = channel.select({
                bcast_ch:case_receive(),
                timer:case_receive(),
            })

            if result.channel == bcast_ch then
                -- Broadcast received
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
                -- Timeout — time to exit
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
