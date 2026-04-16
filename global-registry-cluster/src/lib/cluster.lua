-- cluster.lua: Helper functions for managing child wippy instances in cluster tests.
--
-- Usage (from a test function):
--   local cluster = require("cluster")
--   local node = cluster.start_node(exec, "node2")
--   cluster.wait_for_line(node, "READY", 15000)
--   -- ... run assertions ...
--   cluster.stop_node(node)

local M = {}

-- Default path to the wippy binary relative to nodes/<name>/ (child work_dir)
M.WIPPY_BIN = "../../../../runtime/dist/wippy-darwin-arm64"

--- Start a child wippy node.
-- @param exec_mod  module  The exec module reference
-- @param name      string  Node directory name under nodes/ (e.g. "node2", "node3")
-- @param opts      table   Optional overrides:
--                            wippy_bin: path to wippy binary (default M.WIPPY_BIN)
--                            args: extra CLI args string (default "worker -s")
-- @return node table   { name, proc, stdout, stderr, executor }
function M.start_node(exec_mod, name, opts)
    opts = opts or {}
    local bin = opts.wippy_bin or M.WIPPY_BIN
    local args = opts.args or "worker -s"
    local work_dir = "nodes/" .. name

    local executor, err = exec_mod.get("app:exec")
    if err then error("exec.get failed: " .. tostring(err)) end

    local cmd = bin .. " run " .. args
    local proc, perr = executor:exec(cmd, { work_dir = work_dir })
    if perr then
        executor:release()
        error("exec failed for " .. name .. ": " .. tostring(perr))
    end

    local stdout, serr = proc:stdout_stream()
    if serr then
        executor:release()
        error("stdout_stream failed for " .. name .. ": " .. tostring(serr))
    end

    local stderr, sterr = proc:stderr_stream()
    if sterr then
        executor:release()
        error("stderr_stream failed for " .. name .. ": " .. tostring(sterr))
    end

    local ok, start_err = proc:start()
    if start_err then
        executor:release()
        error("start failed for " .. name .. ": " .. tostring(start_err))
    end

    return {
        name = name,
        proc = proc,
        stdout = stdout,
        stderr = stderr,
        executor = executor,
    }
end

--- Read lines from a node's stdout until a line containing `marker` is found,
--- or timeout expires.
-- @param node     table   Node returned by start_node
-- @param marker   string  Substring to search for in each line
-- @param timeout  number  Timeout in milliseconds (default 15000)
-- @return line    string  The matching line
function M.wait_for_line(node, marker, timeout)
    timeout = timeout or 15000
    local collected = {}
    local start_sec = os.time()
    local timeout_sec = math.ceil(timeout / 1000)

    while true do
        -- Check timeout using wall-clock time
        local elapsed_sec = os.time() - start_sec
        if elapsed_sec >= timeout_sec then
            error(string.format(
                "timeout (%dms) waiting for '%s' from %s. collected output:\n%s",
                timeout, marker, node.name, table.concat(collected, "\n")
            ))
        end

        local data, rerr = node.stdout:read(4096)
        if rerr then
            error(string.format(
                "read error from %s: %s. collected output:\n%s",
                node.name, tostring(rerr), table.concat(collected, "\n")
            ))
        end
        if data == nil then
            -- EOF — child process exited
            error(string.format(
                "EOF from %s while waiting for '%s'. collected output:\n%s",
                node.name, marker, table.concat(collected, "\n")
            ))
        end
        if #data > 0 then
            -- Process line by line
            for line in (data .. "\n"):gmatch("([^\n]*)\n") do
                if #line > 0 then
                    table.insert(collected, line)
                    if string.find(line, marker, 1, true) then
                        return line
                    end
                end
            end
        end
    end
end

--- Collect all available stdout output from a node (reads until EOF).
-- @param node  table  Node returned by start_node
-- @return lines table Array of lines collected
function M.read_remaining(node)
    local collected = {}
    while true do
        local data, rerr = node.stdout:read(4096)
        if rerr then break end
        if data == nil then break end  -- EOF
        if #data > 0 then
            for line in (data .. "\n"):gmatch("([^\n]*)\n") do
                if #line > 0 then
                    table.insert(collected, line)
                end
            end
        end
    end
    return collected
end

--- Read and return any available stderr output from a node.
-- @param node  table  Node returned by start_node
-- @return string  Stderr output (may be empty)
function M.read_stderr(node)
    if not node or not node.stderr then return "" end
    local parts = {}
    for _ = 1, 100 do
        local ok, data, rerr = pcall(function() return node.stderr:read(4096) end)
        if not ok then break end
        if rerr then break end
        if data == nil then break end  -- EOF
        if #data > 0 then
            table.insert(parts, data)
        else
            break
        end
    end
    return table.concat(parts)
end

--- Stop a child node gracefully (SIGTERM), then wait for exit.
-- @param node     table   Node returned by start_node
function M.stop_node(node)
    if not node then return end

    -- Send SIGTERM (signal 15) without closing the handle
    pcall(function() node.proc:signal(15) end)

    -- Wait for process to exit (blocks until child terminates)
    pcall(function() node.proc:wait() end)

    -- Now close the handle
    pcall(function() node.proc:close(false) end)

    -- Close streams
    pcall(function() node.stdout:close() end)
    pcall(function() node.stderr:close() end)

    -- Release executor
    pcall(function() node.executor:release() end)
end

return M
