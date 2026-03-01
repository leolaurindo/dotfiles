local M = {}

M["nvim-treesitter/nvim-treesitter"] = {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "go",
          "gomod",
          "gosum",
          "python",
          "markdown",
          "markdown_inline",
          "lua",
          "vim",
          "vimdoc",
          "query",
          "javascript",
          "typescript",
          "tsx",
          "rust",
          "c",
          "cpp",
        },
        highlight = { enable = true },
      })
    end,
  }

return M
