<div align="center">

# fzyf.nvim

![neovim version](https://img.shields.io/badge/neovim-0.9+-57a143?style=flat-square&logo=neovim)
![license](https://img.shields.io/badge/license-mit-yellow?style=flat-square)

fast and minimal Neovim fuzzy finder that uses fzy under the hood

[installation](#installation) · [quick start](#quick-start) · [configuration](#configuration) · [commands](#commands)

![demo](./doc/ex.png)

</div>

## features

- minimal codebase (~800 loc)
- fast fuzzy matching with fzy
- configurable floating window
- pickers: files, config files, buffers
- optional caching
- health checks via `:checkhealth fzyf`
- works with Neovim 0.9+

## requirements

| dependency | required? | purpose | install |
|------------|-----------|---------|---------|
| [fzy](https://github.com/jhawthorn/fzy) | yes | fuzzy matching | `brew install fzy` / `apt install fzy` |
| [fd](https://github.com/sharkdp/fd) | yes | file finding | `brew install fd` / `apt install fd` |
| [fzy-lua-native](https://github.com/romgrk/fzy-lua-native) | optional | faster native matching | see [native fzy](#native-fzy) |

## installation

### lazy.nvim

```lua
{
  "tmybsv/fzyf.nvim",
  config = function()
    require("fzyf").setup()
  end,
}
```

### packer.nvim

```lua
use {
  "tmybsv/fzyf.nvim",
  config = function()
    require("fzyf").setup()
  end,
}
```

### vim-plug

```vim
plug "tmybsv/fzyf.nvim"
lua require("fzyf").setup()
```

## quick start

get started in 30 seconds:

```lua
require("fzyf").setup()

-- set your keymaps (recommended: function-based)
vim.keymap.set("n", "<c-p>", function() require("fzyf").find_files() end, { desc = "Find files" })
vim.keymap.set("n", "<c-c>", function() require("fzyf").find_config() end, { desc = "Find config" })
vim.keymap.set("n", "<c-b>", function() require("fzyf").buffers() end, { desc = "Find buffers" })

-- alternative: command-based keymaps
-- vim.keymap.set("n", "<c-p>", "<cmd>FzyfFindFile<cr>", { desc = "Find files" })
```

that's it. press `<c-p>` to find files.

## commands

| Command | Description |
|---------|-------------|
| `:FzyfFindFile` | Find files in current directory |
| `:FzyfLookupConfig` | Find files in Neovim config directory |
| `:FzyfBuffers` | Find open buffers |

## API

you can also call functions directly for more control:

```lua
local fzyf = require("fzyf")

fzyf.find_files()    -- Find files
fzyf.find_config()   -- Neovim config files
fzyf.buffers()       -- Find buffers
```

this is useful for custom keymaps or integration with other plugins.

## configuration

```lua
require("fzyf").setup({
  win = {
    width = function() return vim.o.columns - 30 end,
    height = function() return vim.o.lines - 10 end,
    border = "rounded",
  },
  find_files = {
    cmd = "fd",
    args = { "-tf", "-cnever", "." },
    limit = function() return vim.o.lines - 10 end,
  },
  cache = {
    enabled = true,
    ttl = 60000,  -- 60 seconds
  },
})
```

<details>
<summary>full configuration reference</summary>

### options

| option | type | default | description |
|--------|------|---------|-------------|
| `win.width` | `number\|fun()` | `columns - 30` | window width |
| `win.height` | `number\|fun()` | `lines - 10` | window height |
| `win.border` | `string` | `"rounded"` | border style: `"none"`, `"single"`, `"double"`, `"rounded"`, `"solid"`, `"shadow"` |
| `win.title` | `string\|nil` | `nil` | window title |
| `find_files.cmd` | `string` | `"fd"` | command for finding files |
| `find_files.args` | `string[]` | `{ "-tf", "-cnever", "." }` | arguments for find command |
| `find_files.limit` | `number\|fun()` | `lines - 10` | max results to show |
| `cache.enabled` | `boolean` | `true` | enable caching |
| `cache.ttl` | `number` | `60000` | cache ttl in ms |
| `cache.max_items` | `number` | `10000` | max cached items |
| `use_native_fzy` | `boolean` | `false` | use fzy-lua-native if available |

</details>

## native fzy

for faster fuzzy matching, you can optionally use [fzy-lua-native](https://github.com/romgrk/fzy-lua-native):

```lua
-- add as dependency with lazy.nvim
{
  "tmybsv/fzyf.nvim",
  dependencies = {
    "romgrk/fzy-lua-native",
    build = "make",
  },
  config = function()
    require("fzyf").setup({ use_native_fzy = true })
  end,
}
```

## health check

run `:checkhealth fzyf` to verify your setup:

```
fzyf.nvim: dependencies
  ok 'fzy' is installed
  ok 'fd' is installed

fzyf.nvim: version
  ok Neovim v0.10.0 (supported)
```

## troubleshooting

<details>
<summary>common issues</summary>

### "fzy not found" error

make sure fzy is installed and in your path:

```bash
which fzy  # should return something like /usr/local/bin/fzy
```

if not, install it:

```bash
# macOS
brew install fzy

# Ubuntu/Debian
sudo apt install fzy

# Arch
sudo pacman -s fzy
```

### window size issues

adjust window dimensions in config:

```lua
require("fzyf").setup({
  win = {
    width = function() return vim.o.columns - 50 end,
    height = function() return vim.o.lines - 15 end,
  }
})
```

### keymaps not working

make sure you're calling `setup()` before setting keymaps:

```lua
require("fzyf").setup()
vim.keymap.set("n", "<c-p>", function() require("fzyf").find_files() end)
```

</details>

## comparison

| feature | fzyf.nvim | telescope.nvim | fzf-lua |
|---------|-----------|----------------|---------|
| lines of code | ~800 | ~15,000+ | ~10,000+ |
| dependencies | fzy, fd | plenary + more | fzf |
| preview | no | yes | yes |
| speed | fast | medium | fast |
| setup complexity | minimal | medium | medium |

Pick fzyf.nvim if you want minimal and fast.
Pick telescope/fzf-lua if you need previews and more features.

## related projects

- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) - highly extendable fuzzy finder
- [fzf-lua](https://github.com/ibhagwan/fzf-lua) - fzf integration for Neovim
- [mini.pick](https://github.com/echasnovski/mini.pick) - minimal picker module
- [snacks.picker](https://github.com/folke/snacks.nvim) - picker from snacks.nvim

## license

MIT
