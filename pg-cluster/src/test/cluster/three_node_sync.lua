-- Test: three_node_sync
-- Verifies that PG state is correctly replicated across 3 nodes.
-- Each node joins the same group, and all nodes should eventually
-- see members from all 3 nodes.

local assert = require("assert")
local cluster = require("cluster")
local exec = require("exec")
local pg = require("pg")
local time = require("time")

local function main()
    local node2 = nil
    local node3 = nil
    local GROUP = "cluster:sync_test"

    local ok, err = pcall(function()
        -- Open PG scope on node1
        local scope, perr = pg.open("app:pg")
        if perr then error("pg.open failed: " .. tostring(perr)) end

        -- Join the group on node1
        local _, join_err = scope:join(GROUP)
        if join_err then error("join failed on node1: " .. tostring(join_err)) end

        -- Start node2 with the test-specific group
        node2 = cluster.start_node(exec, "node2", { group = GROUP })
        cluster.wait_for_line(node2, "READY", 30000)

        -- Start node3 with the test-specific group
        node3 = cluster.start_node(exec, "node3", { group = GROUP })
        cluster.wait_for_line(node3, "READY", 30000)

        -- Wait until node1 sees members from all 3 nodes (including itself)
        -- All nodes join the same group. Node1 should see at least 3 members
        -- (1 local + 2 remote).
        local found_all = false
        local members = {}
        for i = 1, 240 do
            members = scope:get_members(GROUP) or {}
            if #members >= 3 then
                found_all = true
                break
            end
            time.sleep("250ms")
        end
        assert.ok(found_all,
            string.format("expected at least 3 members in %s, got %d", GROUP, #members))

        -- Verify we see members from both node2 and node3
        local has_node2 = false
        local has_node3 = false
        for _, m in ipairs(members) do
            local pid_str = tostring(m)
            if string.find(pid_str, "node2", 1, true) then has_node2 = true end
            if string.find(pid_str, "node3", 1, true) then has_node3 = true end
        end
        assert.ok(has_node2, "expected to find a member from node2")
        assert.ok(has_node3, "expected to find a member from node3")

        -- Clean up node1 membership
        scope:leave(GROUP)
    end)

    -- Cleanup — stop both nodes
    cluster.stop_node(node3)
    cluster.stop_node(node2)

    if not ok then error(err) end
    return true
end

return { main = main }
