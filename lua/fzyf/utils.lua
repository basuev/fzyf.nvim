---@class FzyfUtils
local M = {}

local _deps_ok = nil
local _deps_missing = nil

---Check if all required binaries are available (cached after first call)
---@return boolean
---@return string|nil missing Binary name that's missing, if any
function M.check_dependencies()
  if _deps_ok ~= nil then
    return _deps_ok, _deps_missing
  end
  local required = { "fzy", "fd" }
  for _, binary in ipairs(required) do
    if vim.fn.executable(binary) ~= 1 then
      _deps_ok = false
      _deps_missing = binary
      return false, binary
    end
  end
  _deps_ok = true
  _deps_missing = nil
  return true, nil
end

---Check if optional binaries are available
---@param binary string Binary name
---@return boolean
function M.has_binary(binary)
  return vim.fn.executable(binary) == 1
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
