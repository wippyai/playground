# Examples

End-to-end example apps and test suites for the wippy runtime.

## Running tests

Each subdirectory is a standalone wippy app. To run its tests:

```
cd <example>
../../runtime/dist/wippy run test -s
```

Build the runtime binary first if needed:

```
cd ../../runtime
go build -o dist/wippy ./cmd/wippy
```

## Examples

| Directory          | Description |
|--------------------|-------------|
| `pg/`              | Erlang-style distributed process groups (`pg` module) |
| `pg-cluster/`      | Multi-node `pg` cluster example |
| `queue/`           | Message queue publish/consume with in-memory driver (`queue` module) |
| `private-module/`  | Minimal private module fixture for CLI e2e tests (publish, add, install) |
