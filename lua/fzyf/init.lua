---@class Fzyf
local M = {}

-- Lazy module accessors — modules load on first use
local function lazy(mod)
  return setmetatable({}, {
    __index = function(_, k)
      return require(mod)[k]
    end,
    __call = function(_, ...)
      return require(mod)(...)
    end,
  })
end

-- Only config is needed at setup time; rest are lazy
M.config = require("fzyf.config")
M.commands = lazy("fzyf.commands")
M.terminal = lazy("fzyf.terminal")
M.window = lazy("fzyf.window")
M.cache = lazy("fzyf.cache")
M.utils = lazy("fzyf.utils")
M.health = lazy("fzyf.health")
M.native = lazy("fzyf.native")

-- Expose commands as direct functions for cleaner API
-- Usage: require('fzyf').find_files() instead of require('fzyf').commands.find_files()
M.find_files = function() return M.commands.find_files() end
M.find_config = function() return M.commands.find_config() end
M.buffers = function() return M.commands.buffers() end

-- Flag to track setup state
M._setup_done = false

---Setup the plugin
---@param opts? FzyfConfig User configuration
---@return nil
function M.setup(opts)
  -- Prevent double setup
  if M._setup_done then
    return
  end

  -- Load configuration
  M.config.setup(opts)

  -- Check dependencies
  local utils = require("fzyf.utils")
  local ok, missing = utils.check_dependencies()
  if not ok then
    utils.warn(
      string.format("Required binary '%s' not found. Some features may not work.", missing)
    )
  end

  -- Initialize native fzy if available
  if M.config.get_value("use_native_fzy") then
    require("fzyf.native").init()
  end

  -- Register commands
  M._register_commands()

  -- Setup cleanup autocmd
  M._setup_cleanup()

  M._setup_done = true
end

---Register user commands
---@private
function M._register_commands()
  vim.api.nvim_create_user_command("FzyfFindFile", function()
    M.commands.find_files()
  end, {
    desc = "Find files in current directory",
  })

  vim.api.nvim_create_user_command("FzyfLookupConfig", function()
    M.commands.find_config()
  end, {
    desc = "Find files in Neovim config directory",
  })

  vim.api.nvim_create_user_command("FzyfBuffers", function()
    M.commands.buffers()
  end, {
    desc = "Find open buffers",
  })
end

---Setup cleanup on VimLeave
---@private
function M._setup_cleanup()
  local group = vim.api.nvim_create_augroup("fzyf_cleanup", { clear = true })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      -- Close any open terminal
      local terminal = require("fzyf.terminal")
      if terminal.state.job_id then
        pcall(vim.fn.jobstop, terminal.state.job_id)
      end

      -- Clear cache
      require("fzyf.cache").clear()
    end,
  })
end

return M
