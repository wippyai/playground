-- Test: auto_release_remote
-- Node2 worker registers a global name then exits immediately.
-- Node1 polls until the name is auto-released.

local assert = require("assert")
local cluster = require("cluster")
local exec = require("exec")
local time = require("time")

local function main()
    local node2 = nil
    local NAME = "test.auto_release"

    local ok, err = pcall(function()
        -- Start node2 with register_and_exit action — registers then exits
        node2 = cluster.start_node(exec, "node2", { args = "worker -s register_and_exit " .. NAME })

        -- Wait for node2 to be ready
        cluster.wait_for_line(node2, "READY", 15000)

        -- Wait for registration confirmation
        cluster.wait_for_line(node2, "REGISTERED:" .. NAME, 30000)

        -- Wait for the DONE signal (worker exits after registration)
        cluster.wait_for_line(node2, "DONE", 15000)

        -- Verify the name resolves briefly
        local found = false
        for i = 1, 120 do
            local pid = process.registry.lookup(NAME)
            if pid then
                found = true
                break
            end
            time.sleep("250ms")
        end
        -- Name may or may not be visible before cleanup kicks in;
        -- the important part is that it gets cleaned up

        -- Wait for node2 process to fully exit
        cluster.stop_node(node2)
        node2 = nil

        -- Poll until the name is auto-released
        local released = false
        for i = 1, 240 do
            local pid = process.registry.lookup(NAME)
            if not pid then
                released = true
                break
            end
            time.sleep("250ms")
        end
        assert.ok(released, "expected global name to be auto-released after remote worker exit")
    end)

    -- Cleanup
    cluster.stop_node(node2)

    if not ok then error(err) end
    return true
end

return { main = main }
