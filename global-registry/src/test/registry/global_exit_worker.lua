-- Worker: registers globally with a given name, then immediately exits.
-- Tests auto-cleanup of global names on process exit.
-- Setup: { name = "...", parent_pid = "..." }

local function main()
    local setup_ch = process.listen("setup")
    local setup_msg = setup_ch:receive()

    local name = setup_msg.name
    local parent_pid = setup_msg.parent_pid

    -- register globally
    local ok, err = process.registry.register(name, process.registry.GLOBAL)
    if not ok then
        process.send(parent_pid, "status", "ERROR:" .. tostring(err))
        return
    end

    -- confirm registration then exit immediately
    process.send(parent_pid, "status", "REGISTERED")
end

return { main = main }
