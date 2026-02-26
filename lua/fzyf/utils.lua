---@class FzyfUtils
local M = {}

---Check if all required binaries are available
---@return boolean
---@return string|nil missing Binary name that's missing, if any
function M.check_dependencies()
  local required = { "fzy", "fd" }
  for _, binary in ipairs(required) do
    if vim.fn.executable(binary) ~= 1 then
      return false, binary
    end
  end
  return true, nil
end

---Check if optional binaries are available
---@param binary string Binary name
---@return boolean
function M.has_binary(binary)
  return vim.fn.executable(binary) == 1
end

---Parse grep result line to extract file and line number
---Format: file:line:col:text
---@param line string The grep output line
---@return string|nil file The file path
---@return number|nil lnum The line number
function M.parse_grep_result(line)
  if not line or line == "" then
    return nil, nil
  end

  -- Match file:line:col:text format
  local file, lnum = line:match("^([^:]+):(%d+)")
  if file and lnum then
    return file, tonumber(lnum)
  end

  -- Fallback: just try to get file
  file = line:match("^([^:]+)")
  return file, 1
end

---Format a grep result for opening in vim
---@param line string The grep output line
---@return string|nil vim_cmd The vim command argument (e.g., "+42 path/to/file")
function M.format_grep_result(line)
  local file, lnum = M.parse_grep_result(line)
  if file then
    if lnum and lnum > 0 then
      return string.format("+%d %s", lnum, file)
    end
    return file
  end
  return nil
end

---Debounce a function
---@param fn function Function to debounce
---@param ms number Delay in milliseconds
---@return function debounced
function M.debounce(fn, ms)
  local timer = vim.loop.new_timer()
  return function(...)
    local args = { ... }
    timer:stop()
    timer:start(ms, 0, vim.schedule_wrap(function()
      fn(unpack(args))
    end))
  end
end

---Throttle a function
---@param fn function Function to throttle
---@param ms number Minimum time between calls in milliseconds
---@return function throttled
function M.throttle(fn, ms)
  local timer = vim.loop.new_timer()
  local running = false
  return function(...)
    if not running then
      running = true
      timer:start(ms, 0, function()
        running = false
      end)
      fn(...)
    end
  end
end

---Show an error notification
---@param msg string Error message
function M.error(msg)
  vim.notify("[fzyf] " .. msg, vim.log.levels.ERROR)
end

---Show a warning notification
---@param msg string Warning message
function M.warn(msg)
  vim.notify("[fzyf] " .. msg, vim.log.levels.WARN)
end

---Show an info notification
---@param msg string Info message
function M.info(msg)
  vim.notify("[fzyf] " .. msg, vim.log.levels.INFO)
end

---Safe execute with cleanup on error
---@param fn function Function to execute
---@param cleanup function|nil Optional cleanup function
---@return boolean success
---@return any result
function M.safe_execute(fn, cleanup)
  local ok, result = xpcall(fn, debug.traceback)
  if not ok then
    if cleanup then
      pcall(cleanup)
    end
    M.error(tostring(result))
  end
  return ok, result
end

return M
