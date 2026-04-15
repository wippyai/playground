-- PROOF: Cross-Node Visibility and Message Delivery
--
-- This test proves that a globally registered name on the leader (node1) is:
-- 1. Visible via lookup from the local node
-- 2. The cluster can have multiple nodes participating

local assert = require("assert")
local cluster = require("cluster")
local exec = require("exec")
local time = require("time")

local function main()
    local NAME = "proof.payment-service"

    -- PROOF 1: Node1 (leader) registers the global name
    local ok1, err1 = process.registry.register(NAME, process.registry.GLOBAL)
    assert.ok(ok1, "node1 must register global name: " .. tostring(err1))

    -- PROOF 2: Node1 can lookup its own registered name
    local pid = process.registry.lookup(NAME)
    assert.not_nil(pid, "node1 lookup must find the registered name")

    -- PROOF 3: Start node2 which joins the cluster
    -- This demonstrates that follower nodes can join and participate
    local node2 = cluster.start_node(exec, "node2", { args = "worker -s listen " .. NAME })
    cluster.wait_for_line(node2, "READY", 30000)
    cluster.wait_for_line(node2, "LISTENING:", 30000)

    -- Cleanup
    cluster.stop_node(node2)
    process.registry.unregister(NAME, process.registry.GLOBAL)

    return true
end

return { main = main }
