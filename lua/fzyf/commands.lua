---@class FzyfCommands
local M = {}

local terminal = require("fzyf.terminal")
local config = require("fzyf.config")
local cache = require("fzyf.cache")
local utils = require("fzyf.utils")
local picker = require("fzyf.picker")
local grep_job = require("fzyf.grep_job")
local native = require("fzyf.native")

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

---Build live grep command (optimized - single awk pass)
---@return string cmd
---@return number limit
local function build_grep_cmd()
  local cfg = config.get_value("live_grep")
  local limit = cfg.limit

  local cmd_parts = { cfg.cmd }
  vim.list_extend(cmd_parts, cfg.args)

  return table.concat(cmd_parts, " "), limit
end

---Open selected file
---@param selection string File path or grep result
---@param is_grep boolean Whether this is a grep result
local function open_selection(selection, is_grep)
  if is_grep then
    -- Parse grep result
    local vim_cmd = utils.format_grep_result(selection)
    if vim_cmd then
      vim.cmd("edit " .. vim_cmd)
    else
      utils.error("Could not parse selection: " .. selection)
    end
  else
    -- Direct file path
    vim.cmd("edit " .. vim.fn.fnameescape(selection))
  end
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
    open_selection(selection, false)
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
    open_selection(selection, false)
  end, {
    title = " Config Files ",
  })
end

---Live grep in current directory (using interactive picker)
function M.live_grep()
  -- Check for rg
  if not utils.has_binary("rg") then
    utils.error("'rg' (ripgrep) is required for live grep. Please install it.")
    return
  end

  -- Check other dependencies
  local ok, missing = utils.check_dependencies()
  if not ok then
    utils.error(string.format("Required binary '%s' not found", missing))
    return
  end

  local limit = config.get_value("live_grep.limit") or 25
  local querytick = 0

  -- Open picker with query callback
  picker.open({
    title = " Live Grep ",
    on_query_change = function(query)
      -- Increment querytick for invalidation
      querytick = querytick + 1
      local tick = querytick

      -- Handle empty query
      if not query or query == "" then
        picker.set_items({})
        return
      end

      -- Spawn grep job
      grep_job.spawn(query, {
        on_result = function(line)
          -- Results are collected in grep_job
        end,
        on_done = function(results)
          -- Ignore stale results
          if tick ~= querytick then
            return
          end

          -- Filter and limit results
          local filtered = results
          if native.is_available() then
            filtered = native.filter(query, results, limit)
          else
            -- Fallback: substring match
            filtered = vim.tbl_filter(function(line)
              return line:lower():find(query:lower(), 1, true)
            end, results)
            if #filtered > limit then
              filtered = vim.list_slice(filtered, 1, limit)
            end
          end

          picker.set_items(filtered)
        end,
      })
    end,
    on_select = function(selection)
      open_selection(selection, true)
    end,
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
  local buf_map = {}
  for _, buf in ipairs(bufs) do
    local name = vim.api.nvim_buf_get_name(buf)
    if name and name ~= "" then
      local line = string.format("%s", name)
      table.insert(buf_lines, line)
      buf_map[name] = buf
    end
  end

  -- Create temp file with buffer list
  local limit = config.get_value("find_files.limit")
  limit = type(limit) == "function" and limit() or limit
  local fzy_cmd = terminal.fzy_cmd(limit)

  -- Use process substitution or echo
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

---Find git files
function M.git_files()
  -- Check dependencies
  local ok, missing = utils.check_dependencies()
  if not ok then
    utils.error(string.format("Required binary '%s' not found", missing))
    return
  end

  -- Check if in git repo
  if vim.fn.system("git rev-parse --is-inside-work-tree 2>/dev/null"):gsub("%s+$", "") ~= "true" then
    utils.info("Not in a git repository")
    return
  end

  local limit = config.get_value("find_files.limit")
  limit = type(limit) == "function" and limit() or limit
  local fzy_cmd = terminal.fzy_cmd(limit)

  terminal.open("git ls-files | " .. fzy_cmd, function(selection)
    open_selection(selection, false)
  end, {
    title = " Git Files ",
  })
end

---Find git modified files
function M.git_status()
  -- Check dependencies
  local ok, missing = utils.check_dependencies()
  if not ok then
    utils.error(string.format("Required binary '%s' not found", missing))
    return
  end

  -- Check if in git repo
  if vim.fn.system("git rev-parse --is-inside-work-tree 2>/dev/null"):gsub("%s+$", "") ~= "true" then
    utils.info("Not in a git repository")
    return
  end

  local limit = config.get_value("find_files.limit")
  limit = type(limit) == "function" and limit() or limit
  local fzy_cmd = terminal.fzy_cmd(limit)

  terminal.open("git status --short | cut -c4- | " .. fzy_cmd, function(selection)
    open_selection(selection, false)
  end, {
    title = " Git Status ",
  })
end

return M
