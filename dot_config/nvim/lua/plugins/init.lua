local modules = {
  require("plugins.ui"),
  require("plugins.editor"),
  require("plugins.treesitter"),
  require("plugins.git"),
  require("plugins.ai"),
  require("plugins.lsp"),
  require("plugins.dap"),
  require("plugins.lint"),
  require("plugins.test"),
  require("plugins.jupyter"),
  require("plugins.notes"),
  require("plugins.session"),
}

local specs_by_repo = {}
for _, module_specs in ipairs(modules) do
  for repo_name, spec in pairs(module_specs) do
    specs_by_repo[repo_name] = spec
  end
end

local ordered_repos = {
  "folke/tokyonight.nvim",
  "catppuccin/nvim",
  "sainnhe/everforest",
  "rose-pine/neovim",
  "navarasu/onedark.nvim",
  "rebelot/kanagawa.nvim",
  "EdenEast/nightfox.nvim",
  "ellisonleao/gruvbox.nvim",
  "sainnhe/sonokai",
  "projekt0n/github-nvim-theme",
  "nvimdev/zephyr-nvim",
  "samharju/synthweave.nvim",
  "Mofiqul/dracula.nvim",
  "marko-cerovac/material.nvim",
  "windwp/nvim-autopairs",
  "numToStr/Comment.nvim",
  "folke/flash.nvim",
  "folke/todo-comments.nvim",
  "nvim-mini/mini.splitjoin",
  "nvim-mini/mini.jump",
  "nvim-mini/mini.surround",
  "nvim-mini/mini.move",
  "nvim-treesitter/nvim-treesitter",
  "lewis6991/gitsigns.nvim",
  "tpope/vim-fugitive",
  "sindrets/diffview.nvim",
  "yujinyuz/gitpad.nvim",
  "nvim-lualine/lualine.nvim",
  "folke/snacks.nvim",
  "3rd/image.nvim",
  "benlubas/molten-nvim",
  "stevearc/oil.nvim",
  "sudo-tee/opencode.nvim",
  "folke/sidekick.nvim",
  "epwalsh/obsidian.nvim",
  "zbirenbaum/copilot.lua",
  "nvim-neo-tree/neo-tree.nvim",
  "mason-org/mason.nvim",
  "mason-org/mason-lspconfig.nvim",
  "neovim/nvim-lspconfig",
  "mfussenegger/nvim-dap",
  "mfussenegger/nvim-lint",
  "nvim-neotest/neotest",
  "hrsh7th/nvim-cmp",
  "rcarriga/nvim-notify",
  "folke/noice.nvim",
  "folke/which-key.nvim",
  "folke/trouble.nvim",
  "stevearc/aerial.nvim",
  "SmiteshP/nvim-navic",
  "arnamak/stay-centered.nvim",
  "folke/zen-mode.nvim",
  "goolord/alpha-nvim",
  "folke/persistence.nvim",
}

local specs = {}
for _, repo_name in ipairs(ordered_repos) do
  local spec = specs_by_repo[repo_name]
  if spec then
    specs[#specs + 1] = spec
  end
end

return specs
