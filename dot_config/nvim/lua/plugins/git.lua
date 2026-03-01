local M = {}

M["lewis6991/gitsigns.nvim"] = {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        current_line_blame = false,
      })

      vim.api.nvim_create_user_command("BlameToggle", function()
        require("gitsigns").toggle_current_line_blame()
      end, {})
    end,
  }

M["tpope/vim-fugitive"] = {
    "tpope/vim-fugitive",
  }

M["sindrets/diffview.nvim"] = {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
  }

return M
