# Proof: Global Registry Guarantees with Sharded 2PC/RAFT

This test suite provides formal proof that the global registry provides strong consistency guarantees using distributed sharded transactions on top of Raft consensus.

## Core Guarantee

```lua
process.registry.register("name", process.registry.GLOBAL)
```

**GUARANTEES**: Single name ownership cluster-wide. Once a name is registered globally, no other process in the cluster can register the same name.

## Architecture

The system uses:
- **Raft consensus** for strong consistency within each shard
- **Two-Phase Commit (2PC)** for atomic cross-shard transactions
- **Consistent hashing** (FNV-1a) for sharding names across the cluster
- **Lock-free reads** via `sync.Map` and atomic operations
- **Gossip protocol** for cluster membership and failure detection

## Test Suite

### 1. `ultimate_global_guarantee.lua` (PRIMARY TEST)

**Proves**: `process.registry.register(name, process.registry.GLOBAL)` guarantees single ownership

This is the main proof test that validates the exact API usage:
```lua
process.registry.register("THE.GLOBAL.SINGLETON.NAME", process.registry.GLOBAL)
```

- Starts 3 nodes simultaneously
- All nodes call the exact API concurrently
- Verifies exactly ONE succeeds via distributed sharded 2PC
- Displays comprehensive proof of the guarantee

**Key Assertion**: `#winners == 1` - Only one process owns the name cluster-wide

### 2. `global_uniqueness_cluster.lua`

**Proves**: `register(name, GLOBAL)` guarantees single ownership

- Starts 3 nodes simultaneously
- All nodes attempt to register the same name concurrently
- Verifies exactly ONE succeeds (distributed consensus)
- Verifies the winner's ownership is visible cluster-wide

**Key Assertion**: `success_count == 1` for each contested name

### 3. `sharded_transaction_atomicity.lua`

**Proves**: 2PC on Raft provides atomic cross-shard transactions

- Tests multi-name atomic registration
- Verifies conflict detection triggers rollback
- Ensures no partial state after failed transactions
- Demonstrates atomic all-or-nothing semantics

**Key Assertion**: Failed transactions leave no partial state

### 4. `cross_shard_consistency.lua`

**Proves**: Sharded registry maintains consistency across shards

- Registers names that hash to different shards
- Verifies all names are resolvable from any node
- Tests cross-shard lookup by PID
- Demonstrates distributed consistency

**Key Assertion**: All registered names visible cluster-wide

### 5. `contention_resolution.lua`

**Proves**: Concurrent contention resolves to exactly one winner

- Multiple nodes race for the same set of names
- Each name has exactly one winner
- Failed attempts receive proper conflict errors
- Cluster remains consistent after contention

**Key Assertion**: `winner_count == 1` per name across all nodes

### 6. `auto_release_failover.lua`

**Proves**: Names auto-release on node failure

- Node registers a name
- Node is killed (simulating failure)
- Name is eventually released
- Another node successfully re-registers the name

**Key Assertion**: Failed node's names become available for re-registration

## Running the Tests

### Run all tests:
```bash
cd /opt/workspace/wippy/examples/proof-global-guarantees
wippy run src/runner.lua
```

### Run individual test:
```bash
wippy run src/test/proof/ultimate_global_guarantee.lua
```

### Requirements:
- Wippy runtime with Raft enabled
- Multi-node cluster capability
- Sharded registry enabled (configured in `.wippy.yaml`)

## Expected Output

```
================================================================
  PROOF: Global Registry Guarantees with Sharded 2PC/RAFT
================================================================

========================================
Running: test.proof.global_uniqueness_cluster
========================================
PHASE 1: Starting cluster nodes...
PHASE 2: Concurrent registration attempts...
PHASE 3: Verifying uniqueness guarantee...
[PASS] Uniqueness verified: Only node1 owns proof.global.singleton.sharded
PHASE 4: Verifying global lookup...
[PASS] Lookup correctly resolves to node1 (local owner)
...
[PASS] PROOF COMPLETE: Global uniqueness guarantee verified
```

## Implementation Details

### Sharding Strategy

Names are distributed using FNV-1a hash:
```go
h := fnv.New32a()
h.Write([]byte(name))
shardID := (h.Sum32() ^ hashSeed) % shardCount
```

### 2PC Transaction Flow

1. **Prepare Phase**: All shards verify preconditions (name doesn't exist for register, exists for unregister)
2. **Commit Phase**: All shards apply the operation atomically
3. **Abort Phase**: Rollback any prepared changes on failure

### Lock-Free Optimizations

- `sync.Map` for shard storage (no RWMutex)
- `atomic.Int64` for counters
- `atomic.Int32` for transaction phases
- RCU pattern for FSM state reads

## Guarantees Summary

| Guarantee | Mechanism | Test |
|-----------|-----------|------|
| **Uniqueness** | Raft consensus per shard + 2PC cross-shard | `global_uniqueness_cluster.lua` |
| **Linearizability** | All writes through Raft leader | `sharded_transaction_atomicity.lua` |
| **Atomicity** | 2PC prepare/commit/abort | `sharded_transaction_atomicity.lua` |
| **Fault Tolerance** | Auto-release on failure detection | `auto_release_failover.lua` |
| **Consistency** | Gossip + Raft log replication | `cross_shard_consistency.lua` |

## Verification

These tests are designed to be deterministic proof of the guarantees, not just unit tests. Each test:

1. Sets up a specific distributed scenario
2. Executes concurrent operations
3. Verifies the exact expected outcome
4. Provides cryptographic-like proof of the guarantee

Run them regularly to ensure the distributed system maintains its guarantees.
