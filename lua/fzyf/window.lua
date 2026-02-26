---@class FzyfWindow
---@field buf number|nil Buffer handle
---@field win number|nil Window handle
---@field config FzyfWindowConfig Configuration
local M = {}

local config = require("fzyf.config")

---Create a new floating window
---@param opts? FzyfWindowConfig Optional window configuration
---@return number buf Buffer handle
---@return number win Window handle
function M.create(opts)
  opts = vim.tbl_deep_extend("force", config.get_value("win"), opts or {})

  local width = type(opts.width) == "function" and opts.width() or opts.width
  local height = type(opts.height) == "function" and opts.height() or opts.height

  -- Calculate centered position
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  -- Create scratch buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buflisted = false

  -- Window configuration
  local win_config = {
    relative = "editor",
    style = "minimal",
    width = width,
    height = height,
    col = col,
    row = row,
    border = opts.border or "rounded",
    zindex = 50,
  }

  -- Add title if specified
  if opts.title then
    win_config.title = opts.title
    win_config.title_pos = opts.title_pos or "center"
  end

  -- Create window
  local win = vim.api.nvim_open_win(buf, true, win_config)

  -- Set window options
  vim.wo[win].winhl = "Normal:NormalFloat,FloatBorder:FloatBorder"
  vim.wo[win].winblend = 0

  return buf, win
end

---Close the window and buffer
---@param win number|nil Window handle
---@param buf number|nil Buffer handle
function M.close(win, buf)
  -- Close window first
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end

  -- Then delete buffer
  if buf and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end

---Check if window is valid
---@param win number|nil
---@return boolean
function M.is_valid(win)
  return win ~= nil and vim.api.nvim_win_is_valid(win)
end

---Check if buffer is valid
---@param buf number|nil
---@return boolean
function M.is_buf_valid(buf)
  return buf ~= nil and vim.api.nvim_buf_is_valid(buf)
end

---Update window title
---@param win number Window handle
---@param title string New title
function M.set_title(win, title)
  if M.is_valid(win) then
    vim.api.nvim_win_set_config(win, { title = title })
  end
end

---Get current window dimensions
---@return number width
---@return number height
function M.get_dimensions()
  local cfg = config.get_value("win")
  local width = type(cfg.width) == "function" and cfg.width() or cfg.width
  local height = type(cfg.height) == "function" and cfg.height() or cfg.height
  return width, height
end

return M
