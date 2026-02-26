---@class FzyfPicker
---@field buf number|nil Buffer handle
---@field win number|nil Window handle
---@field items string[] Current items
---@field selected_idx number Currently selected item index
---@field prompt string Prompt text
---@field on_query_change fun(query: string)|nil Callback when query changes
---@field on_select fun(item: string)|nil Callback when item is selected
---@field debounce_timer uv_timer_t|nil Debounce timer
---@field querytick number Counter for invalidating stale results
local M = {}

local config = require("fzyf.config")
local window = require("fzyf.window")
local native = require("fzyf.native")

M.buf = nil
M.win = nil
M.items = {}
M.selected_idx = 1
M.prompt = "> "
M.on_query_change = nil
M.on_select = nil
M.debounce_timer = nil
M.querytick = 0

---Constants
M.PROMPT_LINE = 1
M.RESULTS_START_LINE = 2

---Get current query from prompt line
---@return string
local function get_query()
  if not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then
    return ""
  end
  local lines = vim.api.nvim_buf_get_lines(M.buf, 0, 1, false)
  if not lines or #lines == 0 then
    return ""
  end
  local line = lines[1] or ""
  -- Remove prompt prefix
  return line:sub(#M.prompt + 1)
end

---Set items in the results area
---@param items string[]
function M.set_items(items)
  M.items = items or {}
  M.selected_idx = 1

  if not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then
    return
  end

  -- Clear existing results
  local line_count = vim.api.nvim_buf_line_count(M.buf)
  if line_count > M.RESULTS_START_LINE then
    vim.api.nvim_buf_set_lines(M.buf, M.RESULTS_START_LINE - 1, line_count, false, {})
  end

  -- Add new items
  if #M.items > 0 then
    vim.api.nvim_buf_set_lines(M.buf, M.RESULTS_START_LINE - 1, -1, false, M.items)
  end

  -- Highlight selected line
  M.highlight_selected()
end

---Highlight the currently selected line
function M.highlight_selected()
  if not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then
    return
  end

  -- Clear all highlights
  vim.api.nvim_buf_clear_namespace(M.buf, vim.api.nvim_create_namespace("fzyf_picker"), 0, -1)

  if #M.items == 0 then
    return
  end

  -- Highlight selected line (0-indexed)
  local line_nr = M.RESULTS_START_LINE + M.selected_idx - 2
  if line_nr >= 0 then
    vim.api.nvim_buf_add_highlight(
      M.buf,
      vim.api.nvim_create_namespace("fzyf_picker"),
      "Visual",
      line_nr,
      0,
      -1
    )
  end
end

---Move selection up
function M.move_up()
  if #M.items == 0 then
    return
  end
  M.selected_idx = math.max(1, M.selected_idx - 1)
  M.highlight_selected()
end

---Move selection down
function M.move_down()
  if #M.items == 0 then
    return
  end
  M.selected_idx = math.min(#M.items, M.selected_idx + 1)
  M.highlight_selected()
end

---Select current item
function M.select()
  if #M.items == 0 then
    return
  end

  local item = M.items[M.selected_idx]
  if item and M.on_select then
    M.close()
    M.on_select(item)
  end
end

---Close the picker
function M.close()
  -- Cancel debounce timer
  if M.debounce_timer then
    M.debounce_timer:stop()
    M.debounce_timer:close()
    M.debounce_timer = nil
  end

  -- Close window and buffer
  window.close(M.win, M.buf)

  M.buf = nil
  M.win = nil
  M.items = {}
  M.selected_idx = 1
  M.on_query_change = nil
  M.on_select = nil
end

---Handle query change with debounce
local function handle_query_change()
  local query = get_query()

  -- Cancel existing timer
  if M.debounce_timer then
    M.debounce_timer:stop()
  end

  -- Increment querytick for invalidation
  M.querytick = M.querytick + 1
  local tick = M.querytick

  -- Debounce
  local debounce_ms = config.get_value("picker.debounce_ms") or 100

  if not M.debounce_timer then
    M.debounce_timer = vim.loop.new_timer()
  end

  M.debounce_timer:start(debounce_ms, 0, vim.schedule_wrap(function()
    -- Only process if still current
    if tick == M.querytick and M.on_query_change then
      M.on_query_change(query)
    end
  end))
end

---Set up keymaps
local function setup_keymaps()
  local keymaps = config.get_value("keymaps") or {}

  -- Navigation
  vim.keymap.set("n", "j", M.move_down, { buffer = M.buf, nowait = true })
  vim.keymap.set("n", "k", M.move_up, { buffer = M.buf, nowait = true })
  vim.keymap.set("n", "<C-n>", M.move_down, { buffer = M.buf, nowait = true })
  vim.keymap.set("n", "<C-p>", M.move_up, { buffer = M.buf, nowait = true })
  vim.keymap.set("i", "<C-n>", M.move_down, { buffer = M.buf, nowait = true })
  vim.keymap.set("i", "<C-p>", M.move_up, { buffer = M.buf, nowait = true })

  -- Selection
  vim.keymap.set("n", "<CR>", M.select, { buffer = M.buf, nowait = true })
  vim.keymap.set("i", "<CR>", function()
    vim.cmd("stopinsert")
    M.select()
  end, { buffer = M.buf, nowait = true })

  -- Exit
  vim.keymap.set("n", "<Esc>", M.close, { buffer = M.buf, nowait = true })
  vim.keymap.set("n", "<C-c>", M.close, { buffer = M.buf, nowait = true })
  vim.keymap.set("i", "<Esc>", function()
    vim.cmd("stopinsert")
    M.close()
  end, { buffer = M.buf, nowait = true })
  vim.keymap.set("i", "<C-c>", function()
    vim.cmd("stopinsert")
    M.close()
  end, { buffer = M.buf, nowait = true })
end

---Set up buffer attachment for input monitoring
local function setup_buffer_attachment()
  vim.api.nvim_buf_attach(M.buf, false, {
    on_lines = function()
      handle_query_change()
    end,
  })
end

---Open the picker
---@param opts { title?: string, prompt?: string, on_query_change: fun(query: string), on_select: fun(item: string) }
function M.open(opts)
  opts = opts or {}

  -- Close any existing picker
  if M.buf or M.win then
    M.close()
  end

  M.on_query_change = opts.on_query_change
  M.on_select = opts.on_select
  M.prompt = opts.prompt or "> "
  M.items = {}
  M.selected_idx = 1
  M.querytick = 0

  -- Create window
  local win_opts = {}
  if opts.title then
    win_opts.title = opts.title
  end

  M.buf, M.win = window.create(win_opts)

  -- Set buffer options
  vim.bo[M.buf].filetype = "fzyf"
  vim.bo[M.buf].modifiable = true

  -- Initialize with prompt
  vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, { M.prompt })

  -- Set up keymaps
  setup_keymaps()

  -- Set up buffer attachment
  setup_buffer_attachment()

  -- Move cursor to end of prompt
  vim.api.nvim_win_set_cursor(M.win, { 1, #M.prompt })

  -- Enter insert mode
  vim.cmd("startinsert!")

  return M.buf, M.win
end

---Check if picker is active
---@return boolean
function M.is_active()
  return M.buf ~= nil and M.win ~= nil and window.is_valid(M.win)
end

return M
