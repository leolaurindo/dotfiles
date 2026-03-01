require("config.core")
require("config.globals")

-- === Plugin manager bootstrap (lazy.nvim) ===
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- === Plugins ===

require("lazy").setup(require("plugins"))

require("config.formatting")
require("config.diagnostics")
require("config.commands")
require("config.filetypes")
require("config.jupyter")
require("config.keymaps")
require("config.ai")
require("config.leader_help")
require("config.ui")
