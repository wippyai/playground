local M = {}

function M.eq(actual, expected, msg)
    if actual ~= expected then
        local m = msg or "assertion failed"
        error(string.format("%s: expected %s, got %s", m, tostring(expected), tostring(actual)), 2)
    end
end

function M.neq(actual, expected, msg)
    if actual == expected then
        local m = msg or "assertion failed"
        error(string.format("%s: expected value different from %s", m, tostring(expected)), 2)
    end
end

function M.ok(val, msg)
    if not val then
        error(msg or "expected truthy value, got falsy", 2)
    end
end

function M.is_nil(val, msg)
    if val ~= nil then
        error(string.format("%s: expected nil, got %s", msg or "assertion failed", tostring(val)), 2)
    end
end

function M.not_nil(val, msg)
    if val == nil then
        error(msg or "expected non-nil value, got nil", 2)
    end
end

function M.is_table(val, msg)
    if type(val) ~= "table" then
        error(string.format("%s: expected table, got %s", msg or "assertion failed", type(val)), 2)
    end
end

function M.gt(actual, expected, msg)
    if actual <= expected then
        local m = msg or "assertion failed"
        error(string.format("%s: expected %s > %s", m, tostring(actual), tostring(expected)), 2)
    end
end

function M.gte(actual, expected, msg)
    if actual < expected then
        local m = msg or "assertion failed"
        error(string.format("%s: expected %s >= %s", m, tostring(actual), tostring(expected)), 2)
    end
end

function M.contains(tbl, value, msg)
    if type(tbl) ~= "table" then
        error(string.format("%s: expected table, got %s", msg or "assertion failed", type(tbl)), 2)
    end
    for _, v in ipairs(tbl) do
        if v == value then return end
    end
    error(string.format("%s: value %s not found in table", msg or "assertion failed", tostring(value)), 2)
end

function M.has_error(val, err, msg)
    if val ~= nil then
        error(string.format("%s: expected nil result, got %s", msg or "assertion failed", tostring(val)), 2)
    end
    if err == nil then
        error(string.format("%s: expected error, got nil", msg or "assertion failed"), 2)
    end
end

function M.no_error(val, err, msg)
    if err ~= nil then
        error(string.format("%s: unexpected error: %s", msg or "assertion failed", tostring(err)), 2)
    end
end

return M
