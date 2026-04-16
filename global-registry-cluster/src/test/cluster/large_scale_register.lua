-- Test: large_scale_register
-- Node2 registers 20 global names, node1 verifies all 20 resolve.

local assert = require("assert")
local cluster = require("cluster")
local exec = require("exec")
local time = require("time")

local function main()
    local node2 = nil
    local PREFIX = "test.batch"
    local COUNT = 20

    local ok, err = pcall(function()
        -- Start node2 with register_batch action
        node2 = cluster.start_node(exec, "node2", {
            args = "worker -s register_batch " .. PREFIX .. " " .. tostring(COUNT)
        })

        -- Wait for node2 to be ready
        cluster.wait_for_line(node2, "READY", 15000)

        -- Wait for all 20 registrations
        for i = 1, COUNT do
            local expected = "REGISTERED:" .. PREFIX .. "." .. tostring(i)
            cluster.wait_for_line(node2, expected, 30000)
        end

        -- Verify all 20 names resolve on node1
        local all_found = false
        for attempt = 1, 240 do
            local found_count = 0
            for i = 1, COUNT do
                local name = PREFIX .. "." .. tostring(i)
                local pid = process.registry.lookup(name)
                if pid then
                    found_count = found_count + 1
                end
            end
            if found_count == COUNT then
                all_found = true
                break
            end
            time.sleep("250ms")
        end
        assert.ok(all_found, "expected all " .. tostring(COUNT) .. " global names to resolve on node1")

        -- Verify all PIDs reference node2
        for i = 1, COUNT do
            local name = PREFIX .. "." .. tostring(i)
            local pid = process.registry.lookup(name)
            assert.not_nil(pid, "name " .. name .. " should resolve")
            assert.ok(
                string.find(tostring(pid), "node2", 1, true),
                "PID for " .. name .. " should reference node2, got: " .. tostring(pid)
            )
        end
    end)

    -- Cleanup
    cluster.stop_node(node2)

    if not ok then error(err) end
    return true
end

return { main = main }
