-- worker.lua: Global registry worker for child wippy nodes in cluster tests.
-- (Same as node2/src/worker.lua — identical worker logic)

local io = require("io")
local time = require("time")
local channel = require("channel")

local function main(action, ...)
    local args = {...}
    local duration = "120s"

    if action == "register" then
        local name = args[1] or "test.default"

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

        time.sleep(duration)

    elseif action == "register_batch" then
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

        time.sleep(duration)

    elseif action == "register_and_exit" then
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
        io.print("READY")
        time.sleep(duration)
    end

    io.print("DONE")
    return 0
end

return { main = main }
