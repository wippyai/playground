-- Worker: tries to register globally with a given name.
-- Reports REGISTERED on success, or CONFLICT:<error> on failure.
-- Setup: { name = "...", parent_pid = "..." }

local function main()
    local setup_ch = process.listen("setup")
    local setup_msg = setup_ch:receive()

    local name = setup_msg.name
    local parent_pid = setup_msg.parent_pid

    -- try to register globally
    local ok, err = process.registry.register(name, process.registry.GLOBAL)
    if ok then
        process.send(parent_pid, "status", "REGISTERED")
    else
        process.send(parent_pid, "status", "CONFLICT:" .. tostring(err))
    end
end

return { main = main }
