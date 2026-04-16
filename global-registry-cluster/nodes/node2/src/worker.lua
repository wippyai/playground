-- worker.lua: Global registry worker for child wippy nodes in cluster tests.
--
-- This worker runs as a CLI command (wippy run worker) on child nodes.
-- It performs a sequence of global registry operations and prints status
-- lines to stdout that the parent test process reads via exec stdout stream.
--
-- Protocol (stdout lines):
--   READY                           — worker is ready
--   REGISTERED:<name>               — global name registered successfully
--   REGISTER_FAILED:<name>:<error>  — global registration failed
--   LOOKUP_OK:<name>:<pid>          — lookup returned a PID
--   LOOKUP_FAIL:<name>              — lookup returned nil
--   UNREGISTERED:<name>             — name unregistered
--   MSG_RECV:<data>                 — received a message via registered name
--   ERROR:<message>                 — an error occurred
--   DONE                            — worker finished all operations
--
-- The first CLI argument selects the action mode.
-- Subsequent arguments provide parameters (name, count, etc).

local io = require("io")
local time = require("time")
local channel = require("channel")

local function main(action, ...)
    local args = {...}
    local duration = "120s" -- 2 minutes; tests kill the node via SIGTERM well before this

    if action == "register" then
        -- Register a single global name, then wait for messages.
        -- Args: name
        local name = args[1] or "test.default"

        io.print("READY")

        -- Wait a moment for raft to stabilize after joining
        time.sleep("2s")

        local ok, err = process.registry.register(name, process.registry.GLOBAL)
        if ok then
            io.print("REGISTERED:" .. name)
        else
            io.print("REGISTER_FAILED:" .. name .. ":" .. tostring(err))
            io.print("DONE")
            return 0
        end

        -- Listen for incoming messages on the inbox
        local inbox = process.inbox()
        local timer = time.after(duration)

        while true do
            local result = channel.select({
                inbox:case_receive(),
                timer:case_receive(),
            })
            if result.channel == inbox then
                local msg = result.value
                local topic = msg:topic() or ""
                local payload_obj = msg:payload()
                local payload_str = ""
                if payload_obj then
                    local data = payload_obj:data()
                    payload_str = data and tostring(data) or tostring(payload_obj)
                end
                io.print("MSG_RECV:" .. payload_str)
            elseif result.channel == timer then
                break
            end
        end

    elseif action == "register_multi" then
        -- Register multiple global names, then wait.
        -- Args: name1, name2, ...
        io.print("READY")

        time.sleep("2s")

        for _, name in ipairs(args) do
            local ok, err = process.registry.register(name, process.registry.GLOBAL)
            if ok then
                io.print("REGISTERED:" .. name)
            else
                io.print("REGISTER_FAILED:" .. name .. ":" .. tostring(err))
            end
        end

        -- Wait until killed
        time.sleep(duration)

    elseif action == "register_batch" then
        -- Register N names with a prefix.
        -- Args: prefix, count
        local prefix = args[1] or "batch"
        local count = tonumber(args[2]) or 10

        io.print("READY")

        time.sleep("2s")

        for i = 1, count do
            local name = prefix .. "." .. tostring(i)
            local ok, err = process.registry.register(name, process.registry.GLOBAL)
            if ok then
                io.print("REGISTERED:" .. name)
            else
                io.print("REGISTER_FAILED:" .. name .. ":" .. tostring(err))
            end
        end

        -- Wait until killed
        time.sleep(duration)

    elseif action == "register_and_exit" then
        -- Register a global name then exit immediately (tests auto-release).
        -- Args: name
        local name = args[1] or "test.exit"

        io.print("READY")

        time.sleep("2s")

        local ok, err = process.registry.register(name, process.registry.GLOBAL)
        if ok then
            io.print("REGISTERED:" .. name)
        else
            io.print("REGISTER_FAILED:" .. name .. ":" .. tostring(err))
        end

        io.print("DONE")
        return 0

    elseif action == "register_echo" then
        -- Register a global name, listen for messages, echo them back via stdout.
        -- Args: name
        local name = args[1] or "test.echo"

        io.print("READY")

        time.sleep("2s")

        local ok, err = process.registry.register(name, process.registry.GLOBAL)
        if ok then
            io.print("REGISTERED:" .. name)
        else
            io.print("REGISTER_FAILED:" .. name .. ":" .. tostring(err))
            io.print("DONE")
            return 0
        end

        -- Listen for incoming messages
        local inbox = process.inbox()
        local timer = time.after(duration)

        while true do
            local result = channel.select({
                inbox:case_receive(),
                timer:case_receive(),
            })
            if result.channel == inbox then
                local msg = result.value
                local payload_obj = msg:payload()
                local payload_str = ""
                if payload_obj then
                    local data = payload_obj:data()
                    payload_str = data and tostring(data) or tostring(payload_obj)
                end
                io.print("MSG_RECV:" .. payload_str)
            elseif result.channel == timer then
                break
            end
        end

    elseif action == "lookup" then
        -- Lookup a global name and print the result.
        -- Args: name
        local name = args[1] or "test.default"

        io.print("READY")

        time.sleep("2s")

        local pid, lerr = process.registry.lookup(name)
        if pid then
            io.print("LOOKUP_OK:" .. name .. ":" .. tostring(pid))
        else
            io.print("LOOKUP_FAIL:" .. name)
        end

    else
        -- Default: just signal ready and wait
        io.print("READY")
        time.sleep(duration)
    end

    io.print("DONE")
    return 0
end

return { main = main }
