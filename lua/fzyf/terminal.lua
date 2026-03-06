---@class FzyfTerminal
---@field state {buf: number|nil, win: number|nil, job_id: number|nil}
local M = {}

local window = require("fzyf.window")
local utils = require("fzyf.utils")

---@type {buf: number|nil, win: number|nil, job_id: number|nil}
M.state = {
  buf = nil,
  win = nil,
  job_id = nil,
}

---Check if we're on Neovim 0.11+
---@return boolean
local function has_nvim_011()
  return vim.fn.has("nvim-0.11") == 1
end

---Extract the last non-empty line from a terminal buffer
---@param buf number Buffer handle
---@return string|nil
local function extract_selection(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return nil
  end
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  for i = #lines, 1, -1 do
    if lines[i] and lines[i] ~= "" then
      return lines[i]
    end
  end
  return nil
end

---Open terminal with job (compatible with Neovim 0.10+)
---@param cmd string Command to run
---@param buf number Buffer to use
---@param on_exit fun(exit_code: number, selection: string|nil) Callback on exit
---@param opts? {cwd: string|nil} Options
---@return number|nil job_id
local function open_terminal_job(cmd, buf, on_exit, opts)
  opts = opts or {}

  local function handle_exit(_, exit_code)
    on_exit(exit_code, extract_selection(buf))
  end

  if has_nvim_011() then
    return vim.fn.jobstart(cmd, {
      term = true,
      cwd = opts.cwd,
      on_exit = handle_exit,
    })
  else
    ---@diagnostic disable-next-line: deprecated
    return vim.fn.termopen(cmd, {
      cwd = opts.cwd,
      on_exit = handle_exit,
    })
  end
end

---Cleanup current state
function M.cleanup()
  if M.state.job_id then
    pcall(vim.fn.jobstop, M.state.job_id)
    M.state.job_id = nil
  end

  window.close(M.state.win, M.state.buf)

  M.state.win = nil
  M.state.buf = nil
end

---Open a fuzzy finder terminal
---@param cmd string Command to run (will pipe through fzy)
---@param on_select fun(selection: string) Callback when user selects
---@param opts? {title: string|nil, cwd: string|nil} Options
function M.open(cmd, on_select, opts)
  opts = opts or {}

  -- Cleanup any previous state
  M.cleanup()

  -- Create floating window
  local win_config = {}
  if opts.title then
    win_config.title = opts.title
  end

  local buf, win = window.create(win_config)
  M.state.buf = buf
  M.state.win = win

  -- Open terminal
  M.state.job_id = open_terminal_job(cmd, buf, function(exit_code, selection)
    -- Cleanup
    M.cleanup()

    -- Call callback if successful
    if exit_code == 0 and selection and selection ~= "" then
      on_select(selection)
    end
  end, { cwd = opts.cwd })

  -- Handle job start failure
  if not M.state.job_id or M.state.job_id <= 0 then
    M.cleanup()
    utils.error("Failed to start terminal job")
    return
  end

  -- Enter insert mode
  vim.cmd("startinsert")
end

---Build fzy command with limit
---@param limit number Maximum lines
---@return string
function M.fzy_cmd(limit)
  return string.format("fzy -l%d", limit)
end

---Check if terminal is active
---@return boolean
function M.is_active()
  return M.state.job_id ~= nil and window.is_valid(M.state.win)
end

return M
