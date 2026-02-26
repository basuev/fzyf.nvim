---@class FzyfNative
---@field has_native boolean Whether fzy-lua-native is available
local M = {}

local config = require("fzyf.config")

---@type boolean
M.has_native = false

---@type table|nil
M.native_module = nil

---Initialize native fzy module
---@return boolean success
function M.init()
  if not config.get_value("use_native_fzy") then
    return false
  end

  local ok, native = pcall(require, "fzy_native")
  if ok and native then
    M.has_native = true
    M.native_module = native
    return true
  end

  return false
end

---Check if native implementation is available
---@return boolean
function M.is_available()
  if M.has_native == nil then
    M.init()
  end
  return M.has_native
end

---Filter items using native fzy (if available)
---@param query string Search query
---@param items string[] Items to filter
---@param limit number|nil Maximum results
---@return string[] filtered Filtered and sorted items
function M.filter(query, items, limit)
  if M.is_available() and M.native_module then
    local results = M.native_module.filter(query, items)
    if limit and #results > limit then
      results = vim.list_slice(results, 1, limit)
    end
    -- Extract just the items (native returns {item, score} pairs)
    local filtered = {}
    for _, result in ipairs(results) do
      if type(result) == "table" then
        table.insert(filtered, result[1])
      else
        table.insert(filtered, result)
      end
    end
    return filtered
  end

  -- Fallback: return items as-is (external fzy will handle filtering)
  return items
end

---Check if a string matches a query
---@param query string Search query
---@param str string String to check
---@return boolean matches
function M.has_match(query, str)
  if M.is_available() and M.native_module then
    return M.native_module.has_match(query, str)
  end

  -- Fallback: simple substring match
  return str:lower():find(query:lower(), 1, true) ~= nil
end

---Get match positions for highlighting
---@param query string Search query
---@param str string String to match
---@return number[]|nil positions Match positions (0-indexed)
function M.positions(query, str)
  if M.is_available() and M.native_module then
    return M.native_module.positions(query, str)
  end

  return nil
end

return M
