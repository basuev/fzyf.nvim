---@class FzyfGrepJob
---@field job_id number|nil Current running job ID
---@field results string[] Collected results
---@field on_result fun(line: string)|nil Callback for each result line
---@field on_done fun(results: string[])|nil Callback when job completes
local M = {}

local config = require("fzyf.config")

---@type number|nil
M.job_id = nil

---@type string[]
M.results = {}

---Build rg command arguments
---@param query string Search query
---@return string[] args
local function build_args(query)
  local cfg = config.get_value("live_grep")
  local args = {
    "--line-number",
    "--column",
    "--no-heading",
    "--color=never",
    "--smart-case",
    "--",
    query,
    ".",
  }
  return args
end

---Stop the current running job
function M.stop()
  if M.job_id then
    vim.fn.jobstop(M.job_id)
    M.job_id = nil
  end
  M.results = {}
end

---Check if a job is currently running
---@return boolean
function M.is_running()
  return M.job_id ~= nil
end

---Spawn a new grep job
---@param query string Search query
---@param opts { on_result: fun(line: string), on_done: fun(results: string[]) } Callbacks
---@return number job_id
function M.spawn(query, opts)
  -- Stop any existing job
  M.stop()

  M.results = {}
  M.on_result = opts.on_result
  M.on_done = opts.on_done

  -- Handle empty query
  if not query or query == "" then
    if M.on_done then
      vim.schedule(function()
        M.on_done({})
      end)
    end
    return 0
  end

  local args = build_args(query)
  local stdout_buf = {}

  M.job_id = vim.fn.jobstart({ "rg", unpack(args) }, {
    stdout_buffered = false,
    on_stdout = function(_, data, _)
      if not data then
        return
      end

      for _, line in ipairs(data) do
        if line and line ~= "" then
          table.insert(M.results, line)
          table.insert(stdout_buf, line)
        end
      end
    end,
    on_exit = function(_, exit_code, _)
      -- Only process if this is still the current job
      if M.on_done then
        vim.schedule(function()
          M.on_done(M.results)
        end)
      end
      M.job_id = nil
    end,
    env = {
      LANG = "C",
    },
  })

  if M.job_id <= 0 then
    M.job_id = nil
    if M.on_done then
      vim.schedule(function()
        M.on_done({})
      end)
    end
    return 0
  end

  return M.job_id
end

return M
