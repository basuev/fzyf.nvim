---@class FzyfCache
---@field data table<string, {items: string[], timestamp: number}>
local M = {}

local config = require("fzyf.config")

---@type table<string, {items: string[], timestamp: number}>
M.data = {}

---Get current timestamp in milliseconds
---@return number
local function now()
  return vim.loop.hrtime() / 1e6
end

---Check if cache is enabled
---@return boolean
local function is_enabled()
  return config.get_value("cache.enabled")
end

---Get TTL from config
---@return number
local function get_ttl()
  return config.get_value("cache.ttl")
end

---Get cached items if valid
---@param key string Cache key
---@return string[]|nil items Cached items or nil if not found/expired
function M.get(key)
  if not is_enabled() then
    return nil
  end

  local cached = M.data[key]
  if not cached then
    return nil
  end

  -- Check if expired
  if (now() - cached.timestamp) > get_ttl() then
    M.data[key] = nil
    return nil
  end

  return cached.items
end

---Set cached items
---@param key string Cache key
---@param items string[] Items to cache
function M.set(key, items)
  if not is_enabled() then
    return
  end

  -- Enforce max items limit
  local max_items = config.get_value("cache.max_items")
  if #items > max_items then
    items = vim.list_slice(items, 1, max_items)
  end

  M.data[key] = {
    items = items,
    timestamp = now(),
  }
end

---Invalidate a cache entry
---@param key string Cache key
function M.invalidate(key)
  M.data[key] = nil
end

---Clear all cache entries
function M.clear()
  M.data = {}
end

---Get cache statistics
---@return {entries: number, keys: string[]}
function M.stats()
  local keys = vim.tbl_keys(M.data)
  return {
    entries = #keys,
    keys = keys,
  }
end

---Check if cache has a valid entry
---@param key string Cache key
---@return boolean
function M.has(key)
  return M.get(key) ~= nil
end

return M
