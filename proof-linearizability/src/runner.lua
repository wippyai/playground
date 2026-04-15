local io = require("io")
local registry = require("registry")
local funcs = require("funcs")
local time = require("time")

local function main()
    io.print("")
    io.print("=== PROOF: Linearizability of Global Registry Operations ===")
    io.print("")

    -- discover all tests
    local entries = registry.find({ ["meta.type"] = "test" })
    if not entries or #entries == 0 then
        io.print("no tests found")
        return 1
    end

    -- sort by order
    table.sort(entries, function(a, b)
        local oa = (a.meta or {}).order or 999
        local ob = (b.meta or {}).order or 999
        if oa ~= ob then return oa < ob end
        return a.id < b.id
    end)

    local passed = 0
    local failed = 0
    local failures = {}

    -- Optional: filter to specific test for debugging
    local filter = nil -- set to nil to run all tests

    for _, entry in ipairs(entries) do
        local desc = (entry.meta or {}).description or entry.id

        -- Skip tests that don't match filter
        if filter and not string.find(entry.id, filter, 1, true) and not string.find(desc, filter, 1, true) then
            goto continue
        end

        local ok, err = pcall(function()
            -- retry up to 3 times for pool not found errors
            for attempt = 1, 3 do
                local result, call_err = funcs.call(entry.id)
                if call_err then
                    local err_str = tostring(call_err)
                    if string.find(err_str, "pool not found") and attempt < 3 then
                        time.sleep("500ms")
                    else
                        error(err_str)
                    end
                else
                    return result
                end
            end
        end)

        if ok then
            passed = passed + 1
            io.print("  [PASS] " .. desc)
        else
            failed = failed + 1
            io.print("  [FAIL] " .. desc)
            table.insert(failures, { desc = desc, err = tostring(err) })
        end

        -- Allow cluster state to settle between tests
        time.sleep("5s")

        ::continue::
    end

    io.print("")
    io.print(string.format("results: %d passed, %d failed, %d total",
        passed, failed, passed + failed))

    if #failures > 0 then
        io.print("")
        io.print("--- failures ---")
        for _, f in ipairs(failures) do
            io.print("")
            io.print("  " .. f.desc)
            io.print("    " .. f.err)
        end
    end

    io.print("")
    if failed > 0 then
        return 1
    end
    return 0
end

return { main = main }
