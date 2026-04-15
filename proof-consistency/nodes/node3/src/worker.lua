-- worker.lua: Global registry worker for child wippy nodes in cluster tests.

local io = require("io")
local time = require("time")
local channel = require("channel")

local function main(action, ...)
    local args = {...}
    local duration = "120s"

    if action == "register" then
        local name = args[1] or "test.default"

        io.print("READY")

        time.sleep("3s")

        local ok, err
        for attempt = 1, 30 do
            ok, err = process.registry.register(name, process.registry.GLOBAL)
            if ok then break end
            local err_str = tostring(err)
            if string.find(err_str, "not available", 1, true) or
               string.find(err_str, "not the raft leader", 1, true) or
               string.find(err_str, "global registry", 1, true) then
                time.sleep("1s")
            else
                break
            end
        end
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

    elseif action == "listen" then
        -- Just listen for messages on inbox, don't register anything
        -- Used for testing message routing to a node
        local name = args[1] or "test.listen"

        io.print("READY")
        time.sleep("100ms")  -- Allow output to flush
        io.print("LISTENING:" .. name)
        time.sleep("100ms")  -- Allow output to flush

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

    elseif action == "register_echo" then
        local name = args[1] or "test.echo"

        io.print("READY")

        time.sleep("3s")

        local ok, err
        for attempt = 1, 30 do
            ok, err = process.registry.register(name, process.registry.GLOBAL)
            if ok then break end
            local err_str = tostring(err)
            if string.find(err_str, "not available", 1, true) or
               string.find(err_str, "not the raft leader", 1, true) or
               string.find(err_str, "global registry", 1, true) then
                time.sleep("1s")
            else
                break
            end
        end
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
