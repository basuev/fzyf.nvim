---@class FzyfCommands
local M = {}

local terminal = require("fzyf.terminal")
local config = require("fzyf.config")
local utils = require("fzyf.utils")

---Build find files command
---@return string cmd
---@return number limit
local function build_find_cmd()
  local cfg = config.get_value("find_files")
  local limit = type(cfg.limit) == "function" and cfg.limit() or cfg.limit

  local cmd_parts = { cfg.cmd }
  vim.list_extend(cmd_parts, cfg.args)

  return table.concat(cmd_parts, " "), limit
end

---Open selected file
---@param selection string File path
local function open_selection(selection)
  vim.cmd("edit " .. vim.fn.fnameescape(selection))
end

---Find files in current directory
function M.find_files()
  -- Check dependencies
  local ok, missing = utils.check_dependencies()
  if not ok then
    utils.error(string.format("Required binary '%s' not found", missing))
    return
  end

  local cmd, limit = build_find_cmd()
  local fzy_cmd = terminal.fzy_cmd(limit)
  local full_cmd = cmd .. " | " .. fzy_cmd

  terminal.open(full_cmd, function(selection)
    open_selection(selection)
  end, {
    title = " Find Files ",
  })
end

---Find files in Neovim config directory
function M.find_config()
  -- Check dependencies
  local ok, missing = utils.check_dependencies()
  if not ok then
    utils.error(string.format("Required binary '%s' not found", missing))
    return
  end

  local cfg = config.get_value("find_files")
  local limit = type(cfg.limit) == "function" and cfg.limit() or cfg.limit

  local cfgdir = vim.fn.stdpath("config")
  local cmd = string.format("fd -tf -cnever . %s", vim.fn.shellescape(cfgdir))
  local fzy_cmd = terminal.fzy_cmd(limit)
  local full_cmd = cmd .. " | " .. fzy_cmd

  terminal.open(full_cmd, function(selection)
    open_selection(selection)
  end, {
    title = " Config Files ",
  })
end

---Find open buffers
function M.buffers()
  -- Check dependencies
  local ok, missing = utils.check_dependencies()
  if not ok then
    utils.error(string.format("Required binary '%s' not found", missing))
    return
  end

  -- Get listed buffers
  local bufs = vim.tbl_filter(function(b)
    return vim.api.nvim_buf_is_loaded(b)
      and vim.bo[b].buflisted
      and vim.bo[b].buftype == ""
  end, vim.api.nvim_list_bufs())

  if #bufs == 0 then
    utils.info("No buffers to show")
    return
  end

  -- Build buffer list
  local buf_lines = {}
  for _, buf in ipairs(bufs) do
    local name = vim.api.nvim_buf_get_name(buf)
    if name and name ~= "" then
      table.insert(buf_lines, name)
    end
  end

  -- Create temp file with buffer list
  local limit = config.get_value("find_files.limit")
  limit = type(limit) == "function" and limit() or limit
  local fzy_cmd = terminal.fzy_cmd(limit)

  -- Use echo to pipe buffer list
  local input = table.concat(buf_lines, "\n")
  local full_cmd = string.format("echo '%s' | %s", input:gsub("'", "'\\''"), fzy_cmd)

  terminal.open(full_cmd, function(selection)
    -- Extract file path from selection
    local file = selection:match("^%s*(.-)%s*$")
    if file and file ~= "" then
      vim.cmd("edit " .. vim.fn.fnameescape(file))
    end
  end, {
    title = " Buffers ",
  })
end

return M
