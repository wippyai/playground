-- Test: join_replication
-- Verifies that a process joining a PG group on node2 becomes visible
-- via get_members() on node1.

local assert = require("assert")
local cluster = require("cluster")
local exec = require("exec")
local pg = require("pg")
local time = require("time")

local function main()
    local node2 = nil
    local GROUP = "cluster:join_test"

    local ok, err = pcall(function()
        -- Open PG scope on node1
        local scope, perr = pg.open("app:pg")
        if perr then error("pg.open failed: " .. tostring(perr)) end

        -- Start node2 with the test-specific group
        node2 = cluster.start_node(exec, "node2", { group = GROUP })

        -- Wait for node2 worker to be ready
        local ready_line = cluster.wait_for_line(node2, "READY", 15000)

        -- Also check what groups node1 sees in its PG scope
        local all_groups = scope:which_groups()
        local groups_str = "none"
        if all_groups then
            groups_str = tostring(#all_groups)
            for _, g in ipairs(all_groups) do
                groups_str = groups_str .. " [" .. g .. "]"
            end
        end

        -- Poll get_members until we see a remote member
        local found = false
        local members = {}
        local debug_info = "groups=" .. groups_str
        for i = 1, 240 do
            local m, merr = scope:get_members(GROUP)
            if merr then
                debug_info = debug_info .. " get_members_err=" .. tostring(merr)
                break
            end
            members = m or {}
            if #members > 0 then
                found = true
                break
            end
            -- Check groups every 10 iterations
            if i % 10 == 0 then
                all_groups = scope:which_groups()
                local count = all_groups and #all_groups or 0
                debug_info = debug_info .. " poll" .. i .. ":groups=" .. count
            end
            time.sleep("250ms")
        end

        assert.ok(found, "expected to find remote member on node1, got 0 members after polling. ready_line=" .. tostring(ready_line) .. " debug=" .. debug_info)
        assert.gte(#members, 1, "expected at least 1 member from node2")

        -- Verify the member PID contains the node2 identifier
        local member_pid = members[1]
        assert.not_nil(member_pid, "member PID should not be nil")
        -- The PID string should reference node2
        local pid_str = tostring(member_pid)
        assert.ok(
            string.find(pid_str, "node2", 1, true),
            "member PID should reference node2, got: " .. pid_str
        )
    end)

    -- Cleanup
    cluster.stop_node(node2)

    if not ok then error(err) end
    return true
end

return { main = main }
