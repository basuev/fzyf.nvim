---@class Fzyf
---@field config FzyfConfig Configuration module
---@field commands FzyfCommands Commands module
---@field terminal FzyfTerminal Terminal module
---@field window FzyfWindow Window module
---@field cache FzyfCache Cache module
---@field utils FzyfUtils Utils module
---@field health FzyfHealth Health check module
---@field native FzyfNative Native fzy module
local M = {}

-- Module references
M.config = require("fzyf.config")
M.commands = require("fzyf.commands")
M.terminal = require("fzyf.terminal")
M.window = require("fzyf.window")
M.cache = require("fzyf.cache")
M.utils = require("fzyf.utils")
M.health = require("fzyf.health")
M.native = require("fzyf.native")

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
  local ok, missing = M.utils.check_dependencies()
  if not ok then
    M.utils.warn(
      string.format("Required binary '%s' not found. Some features may not work.", missing)
    )
  end

  -- Check optional rg for live grep
  if not M.utils.has_binary("rg") then
    M.utils.warn("'rg' not found. LiveGrep command will not work.")
  end

  -- Initialize native fzy if available
  if M.config.get_value("use_native_fzy") then
    M.native.init()
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

  vim.api.nvim_create_user_command("FzyfLiveGrep", function()
    M.commands.live_grep()
  end, {
    desc = "Live grep in current directory",
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

  vim.api.nvim_create_user_command("FzyfGitFiles", function()
    M.commands.git_files()
  end, {
    desc = "Find git tracked files",
  })

  vim.api.nvim_create_user_command("FzyfGitStatus", function()
    M.commands.git_status()
  end, {
    desc = "Find modified git files",
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
      if M.terminal.state.job_id then
        pcall(vim.fn.jobstop, M.terminal.state.job_id)
      end

      -- Clear cache
      M.cache.clear()
    end,
  })
end

return M
