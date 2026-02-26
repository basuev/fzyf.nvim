---@class FzyfWindowConfig
---@field width number|fun():number Width of the floating window
---@field height number|fun():number Height of the floating window
---@field border string|"none"|"single"|"double"|"rounded"|"solid"|"shadow" Border style
---@field title string|nil Optional title for the window
---@field title_pos "left"|"center"|"right"|nil Title position

---@class FzyfFindConfig
---@field cmd string Command to use for finding files
---@field args string[] Arguments for the find command
---@field limit number|fun():number Maximum results to show
---@field cwd string|nil Working directory (nil for current)

---@class FzyfGrepConfig
---@field cmd string Command to use for grep
---@field args string[] Arguments for the grep command
---@field limit number Maximum results to show

---@class FzyfCacheConfig
---@field enabled boolean Enable caching
---@field ttl number Time to live in milliseconds
---@field max_items number Maximum items to cache

---@class FzyfKeymaps
---@field exit string Key to exit the picker
---@field select string Key to select item

---@class FzyfConfig
---@field win FzyfWindowConfig Window configuration
---@field find_files FzyfFindConfig Find files configuration
---@field live_grep FzyfGrepConfig Live grep configuration
---@field cache FzyfCacheConfig Cache configuration
---@field keymaps FzyfKeymaps Keymap configuration
---@field use_native_fzy boolean Use fzy-lua-native if available

local M = {}

-- Constants
M.WIN_MARGIN_HORIZONTAL = 30
M.WIN_MARGIN_VERTICAL = 10
M.GREP_RESULT_LIMIT = 25
M.CACHE_TTL = 60000 -- 60 seconds
M.CACHE_MAX_ITEMS = 10000

---@type FzyfConfig
M.defaults = {
  win = {
    width = function()
      return vim.o.columns - M.WIN_MARGIN_HORIZONTAL
    end,
    height = function()
      return vim.o.lines - M.WIN_MARGIN_VERTICAL
    end,
    border = "rounded",
    title = nil,
    title_pos = "center",
  },
  find_files = {
    cmd = "fd",
    args = { "-tf", "-cnever", "." },
    limit = function()
      return vim.o.lines - M.WIN_MARGIN_VERTICAL
    end,
    cwd = nil,
  },
  live_grep = {
    cmd = "rg",
    args = { "-i", "--vimgrep", "--max-count=10", "--max-filesize=1M", "." },
    limit = M.GREP_RESULT_LIMIT,
  },
  cache = {
    enabled = true,
    ttl = M.CACHE_TTL,
    max_items = M.CACHE_MAX_ITEMS,
  },
  keymaps = {
    exit = "<Esc>",
    select = "<CR>",
  },
  use_native_fzy = false,
}

---@type FzyfConfig
M.options = {}

---Resolve a value that can be either a literal or a function
---@param value any
---@return any
local function resolve(value)
  if type(value) == "function" then
    return value()
  end
  return value
end

---Setup configuration with user options
---@param opts? FzyfConfig User configuration
---@return FzyfConfig
function M.setup(opts)
  opts = opts or {}
  M.options = vim.tbl_deep_extend("force", M.defaults, opts)
  return M.options
end

---Get the current configuration
---@return FzyfConfig
function M.get()
  if vim.tbl_isempty(M.options) then
    return M.defaults
  end
  return M.options
end

---Get a specific config value (resolves functions)
---@param key string Dot-separated key path (e.g., "win.width")
---@return any
function M.get_value(key)
  local parts = vim.split(key, ".", { plain = true })
  local value = M.get()
  for _, part in ipairs(parts) do
    value = value[part]
    if value == nil then
      return nil
    end
  end
  return resolve(value)
end

return M
