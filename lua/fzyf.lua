---fzyf.nvim - Fast and minimal as fuck Neovim fuzzy finder
---Uses fzy algorithm under the hood
---
---This file provides backward compatibility by re-exporting from the new module structure.

local M = {}

---Setup the plugin
---For backward compatibility, this wraps the new module system
---@param opts? table User configuration (optional, for keymap setup)
---@return nil
function M.setup(opts)
  local fzyf = require("fzyf")
  fzyf.setup()

  -- Handle legacy keymap setup style
  -- Old: fzyf.setup({ vim.keymap.set(...) })
  -- This was never documented but some users might have used it
  if opts and type(opts) == "table" then
    -- If it looks like keymaps were passed, warn about deprecated usage
    if opts[1] or opts[2] or opts[3] then
      vim.notify(
        "[fzyf] Passing keymaps to setup() is no longer needed. Set keymaps directly:\n"
          .. "  vim.keymap.set('n', '<leader>ff', ':FzyfFindFile<CR>')",
        vim.log.levels.WARN
      )
    end
  end
end

return M
