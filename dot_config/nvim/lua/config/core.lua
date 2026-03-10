-- === Leaders & base mappings ===
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Avoid netrw startup flashes when opening a directory (e.g. `nvim .`).
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- When starting Neovim with a single directory arg, switch cwd and clear the arg
-- so startup lands on the dashboard instead of a directory buffer.
if vim.fn.argc() == 1 then
  local arg0 = vim.fn.argv(0)
  if type(arg0) == "string" and arg0 ~= "" then
    local dir = vim.fn.fnamemodify(arg0, ":p")
    if vim.fn.isdirectory(dir) == 1 then
      vim.cmd("cd " .. vim.fn.fnameescape(dir))
      pcall(vim.cmd, "argdelete " .. vim.fn.fnameescape(arg0))
    end
  end
end

-- Fallback: if Neovim already opened a directory buffer, turn it into cwd and
-- clear the buffer immediately so startup can show the dashboard without flashes.
local startup_name = vim.api.nvim_buf_get_name(0)
if startup_name ~= "" and vim.fn.isdirectory(startup_name) == 1 then
  vim.cmd("cd " .. vim.fn.fnameescape(startup_name))
  vim.cmd("silent! enew")
end

vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })
vim.keymap.set({ "n", "v", "o" }, "\\", "<Space>", { remap = true, silent = true })

-- === Editor options (matches your Vim setup) ===
vim.opt.relativenumber = true
vim.opt.number = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.autoindent = true
vim.opt.termguicolors = true
vim.opt.guicursor = "a:block"

local forced_mode_cursors = {
  "n:block-blinkwait0-blinkon0-blinkoff0",
  "i:block-blinkwait0-blinkon0-blinkoff0",
}
local forced_modes = {
  n = true,
  i = true,
}

local function enforce_mode_block_cursor()
  local current = vim.o.guicursor
  if current == "" then
    vim.opt.guicursor = table.concat(forced_mode_cursors, ",")
    return
  end

  local updated = {}
  for _, part in ipairs(vim.split(current, ",", { plain = true, trimempty = true })) do
    local modes, args = part:match("^([^:]+):(.*)$")
    if not modes then
      table.insert(updated, part)
    else
      local kept_modes = {}
      for _, mode in ipairs(vim.split(modes, "-", { plain = true, trimempty = true })) do
        if not forced_modes[mode] then
          table.insert(kept_modes, mode)
        end
      end

      if #kept_modes > 0 then
        table.insert(updated, table.concat(kept_modes, "-") .. ":" .. args)
      end
    end
  end

  for _, part in ipairs(forced_mode_cursors) do
    table.insert(updated, part)
  end
  local next_value = table.concat(updated, ",")
  if next_value ~= current then
    vim.opt.guicursor = next_value
  end
end

local applying_insert_block_cursor = false
local insert_cursor_group = vim.api.nvim_create_augroup("ForceInsertBlockCursor", { clear = true })

vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, {
  group = insert_cursor_group,
  callback = function()
    if applying_insert_block_cursor then
      return
    end
    applying_insert_block_cursor = true
    enforce_mode_block_cursor()
    applying_insert_block_cursor = false
  end,
})

vim.api.nvim_create_autocmd("OptionSet", {
  group = insert_cursor_group,
  pattern = "guicursor",
  callback = function()
    if applying_insert_block_cursor then
      return
    end

    applying_insert_block_cursor = true
    vim.schedule(function()
      pcall(enforce_mode_block_cursor)
      applying_insert_block_cursor = false
    end)
  end,
})

vim.opt.cmdheight = 1
vim.opt.wildmode = "longest:full,full"
vim.opt.wildoptions = "pum"
vim.opt.pumheight = 12
vim.opt.pumblend = 8

-- Prefer a dedicated Neovim Python host if available.
if vim.g.python3_host_prog == nil then
  local candidates = {
    vim.fn.expand("~/.venvs/nvim/bin/python"),
    vim.fn.expand("~/.venvs/nvim/Scripts/python.exe"),
  }
  for _, candidate in ipairs(candidates) do
    if vim.fn.executable(candidate) == 1 then
      vim.g.python3_host_prog = candidate
      break
    end
  end
end

-- === Swap/backup/undo paths ===
vim.opt.swapfile = true
vim.opt.undofile = true
vim.opt.backup = true
vim.opt.writebackup = true

local cache = vim.fn.stdpath("cache")
local state = vim.fn.stdpath("state")

local backupdir = cache .. "/backup//"
local swapdir = cache .. "/swap//"
local undodir = state .. "/undo//"

vim.opt.backupdir = backupdir
vim.opt.directory = swapdir
vim.opt.undodir = undodir

vim.fn.mkdir(backupdir, "p")
vim.fn.mkdir(swapdir, "p")
vim.fn.mkdir(undodir, "p")

-- === Clipboard provider ===

local function set_clipboard_provider()
  if vim.g.clipboard then
    return
  end

  local has = vim.fn.has
  local exe = vim.fn.executable
  local clipboard = nil

  if has("wsl") == 1 then
    if exe("win32yank.exe") == 1 then
      clipboard = {
        name = "win32yank-wsl",
        copy = {
          ["+"] = { "win32yank.exe", "-i", "--crlf" },
          ["*"] = { "win32yank.exe", "-i", "--crlf" },
        },
        paste = {
          ["+"] = { "win32yank.exe", "-o", "--lf" },
          ["*"] = { "win32yank.exe", "-o", "--lf" },
        },
        cache_enabled = 0,
      }
    elseif exe("clip.exe") == 1 and exe("powershell.exe") == 1 then
      clipboard = {
        name = "wsl-clip",
        copy = {
          ["+"] = { "clip.exe" },
          ["*"] = { "clip.exe" },
        },
        paste = {
          ["+"] = { "powershell.exe", "-NoProfile", "-Command", "Get-Clipboard" },
          ["*"] = { "powershell.exe", "-NoProfile", "-Command", "Get-Clipboard" },
        },
        cache_enabled = 0,
      }
    end
  elseif has("mac") == 1 then
    if exe("pbcopy") == 1 and exe("pbpaste") == 1 then
      clipboard = {
        name = "macos-clipboard",
        copy = {
          ["+"] = { "pbcopy" },
          ["*"] = { "pbcopy" },
        },
        paste = {
          ["+"] = { "pbpaste" },
          ["*"] = { "pbpaste" },
        },
        cache_enabled = 0,
      }
    end
  elseif has("unix") == 1 then
    if vim.env.WAYLAND_DISPLAY and exe("wl-copy") == 1 and exe("wl-paste") == 1 then
      clipboard = {
        name = "wayland-clipboard",
        copy = {
          ["+"] = { "wl-copy" },
          ["*"] = { "wl-copy" },
        },
        paste = {
          ["+"] = { "wl-paste", "--no-newline" },
          ["*"] = { "wl-paste", "--no-newline" },
        },
        cache_enabled = 0,
      }
    elseif exe("xclip") == 1 then
      clipboard = {
        name = "xclip-clipboard",
        copy = {
          ["+"] = { "xclip", "-selection", "clipboard" },
          ["*"] = { "xclip", "-selection", "clipboard" },
        },
        paste = {
          ["+"] = { "xclip", "-selection", "clipboard", "-o" },
          ["*"] = { "xclip", "-selection", "clipboard", "-o" },
        },
        cache_enabled = 0,
      }
    elseif exe("xsel") == 1 then
      clipboard = {
        name = "xsel-clipboard",
        copy = {
          ["+"] = { "xsel", "--clipboard", "--input" },
          ["*"] = { "xsel", "--clipboard", "--input" },
        },
        paste = {
          ["+"] = { "xsel", "--clipboard", "--output" },
          ["*"] = { "xsel", "--clipboard", "--output" },
        },
        cache_enabled = 0,
      }
    end
  end

  if clipboard ~= nil then
    vim.g.clipboard = clipboard
  end
end

set_clipboard_provider()
