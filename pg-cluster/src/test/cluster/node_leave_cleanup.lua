-- Test: node_leave_cleanup
-- Verifies that when node2 leaves the cluster (SIGTERM), its members
-- are automatically removed from PG groups on node1.

local assert = require("assert")
local cluster = require("cluster")
local exec = require("exec")
local pg = require("pg")
local time = require("time")

local function main()
    local node2 = nil
    local GROUP = "cluster:leave_test"

    local ok, err = pcall(function()
        -- Open PG scope on node1
        local scope, perr = pg.open("app:pg")
        if perr then error("pg.open failed: " .. tostring(perr)) end

        -- Start node2 — worker joins the test-specific group
        node2 = cluster.start_node(exec, "node2", { group = GROUP })

        -- Wait for node2 to be ready
        cluster.wait_for_line(node2, "READY", 30000)

        -- Wait until we see the remote member
        local found = false
        for i = 1, 240 do
            local members = scope:get_members(GROUP) or {}
            if #members > 0 then
                found = true
                break
            end
            time.sleep("250ms")
        end
        assert.ok(found, "expected to see node2 member before stopping it")

        -- Verify we have exactly 1 remote member
        local members_before = scope:get_members(GROUP) or {}
        assert.eq(#members_before, 1, "expected exactly 1 member from node2")

        -- Stop node2 (graceful SIGTERM)
        cluster.stop_node(node2)
        node2 = nil -- Prevent double-stop in cleanup

        -- Poll until the remote member is removed
        -- Gossip node-left detection + PG cleanup can take several seconds
        local cleaned = false
        for i = 1, 240 do
            local members = scope:get_members(GROUP) or {}
            if #members == 0 then
                cleaned = true
                break
            end
            time.sleep("250ms")
        end
        assert.ok(cleaned, "expected remote members to be cleaned up after node2 departure")

        -- Verify which_groups also reflects the cleanup
        local groups = scope:which_groups() or {}
        for _, g in ipairs(groups) do
            assert.neq(g, GROUP,
                "group should not appear in which_groups after all members removed")
        end
    end)

    -- Cleanup
    cluster.stop_node(node2)

    if not ok then error(err) end
    return true
end

return { main = main }
