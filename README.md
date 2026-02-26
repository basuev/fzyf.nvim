<div align="center">

# fzyf.nvim

![neovim version](https://img.shields.io/badge/neovim-0.9+-57a143?style=flat-square&logo=neovim)
![license](https://img.shields.io/badge/license-mit-yellow?style=flat-square)

fast and minimal neovim fuzzy finder that uses fzy under the hood

[installation](#installation) · [quick start](#quick-start) · [configuration](#configuration) · [commands](#commands)

![demo](./doc/ex.png)

</div>

## features

- minimal codebase (~1000 loc)
- fast fuzzy matching with fzy
- configurable floating window
- multiple pickers: files, grep, buffers, git
- optional caching
- health checks via `:checkhealth fzyf`
- works with neovim 0.9+

## requirements

| dependency | required? | purpose | install |
|------------|-----------|---------|---------|
| [fzy](https://github.com/jhawthorn/fzy) | yes | fuzzy matching | `brew install fzy` / `apt install fzy` |
| [fd](https://github.com/sharkdp/fd) | yes | file finding | `brew install fd` / `apt install fd` |
| [ripgrep](https://github.com/burntSushi/ripgrep) | recommended | live grep | `brew install ripgrep` / `apt install ripgrep` |
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

-- set your keymaps
vim.keymap.set("n", "<c-p>", ":fzyffindfile<cr>", { desc = "find files" })
vim.keymap.set("n", "<c-g>", ":fzyflivegrep<cr>", { desc = "live grep" })
vim.keymap.set("n", "<c-b>", ":fzyfbuffers<cr>", { desc = "find buffers" })
```

that's it. press `<c-p>` to find files.

## commands

| command | description |
|---------|-------------|
| `:fzyffindfile` | find files in current directory |
| `:fzyflivegrep` | live grep search |
| `:fzyflookupconfig` | find files in neovim config directory |
| `:fzyfbuffers` | find open buffers |
| `:fzyfgitfiles` | find git tracked files |
| `:fzyfgitstatus` | find modified git files |

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
  live_grep = {
    cmd = "rg",
    args = { "-i", "--vimgrep", "." },
    limit = 25,
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
| `live_grep.cmd` | `string` | `"rg"` | command for grep |
| `live_grep.args` | `string[]` | `{ "-i", "--vimgrep", "." }` | arguments for grep |
| `live_grep.limit` | `number` | `25` | max results to show |
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
  ok 'rg' is installed (optional)

fzyf.nvim: version
  ok neovim v0.10.0 (supported)
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
# macos
brew install fzy

# ubuntu/debian
sudo apt install fzy

# arch
sudo pacman -s fzy
```

### live grep not working

install ripgrep:

```bash
# macos
brew install ripgrep

# ubuntu/debian
sudo apt install ripgrep

# arch
sudo pacman -s ripgrep
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
vim.keymap.set("n", "<c-p>", ":fzyffindfile<cr>")
```

</details>

## comparison

| feature | fzyf.nvim | telescope.nvim | fzf-lua |
|---------|-----------|----------------|---------|
| lines of code | ~1,200 | ~15,000+ | ~10,000+ |
| dependencies | fzy, fd | plenary + more | fzf |
| preview | no | yes | yes |
| speed | fast | medium | fast |
| setup complexity | minimal | medium | medium |

pick fzyf.nvim if you want minimal and fast.
pick telescope/fzf-lua if you need previews and more features.

## related projects

- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) - highly extendable fuzzy finder
- [fzf-lua](https://github.com/ibhagwan/fzf-lua) - fzf integration for neovim
- [mini.pick](https://github.com/echasnovski/mini.pick) - minimal picker module
- [snacks.picker](https://github.com/folke/snacks.nvim) - picker from snacks.nvim

## license

mit
