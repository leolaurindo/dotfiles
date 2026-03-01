local M = {}

M["sudo-tee/opencode.nvim"] = {
    "sudo-tee/opencode.nvim",
    cmd = "Opencode",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "MeanderingProgrammer/render-markdown.nvim",
        opts = {
          anti_conceal = { enabled = false },
          file_types = { "markdown", "opencode_output" },
        },
        ft = { "markdown", "Avante", "copilot-chat", "opencode_output" },
      },
    },
    config = function()
      require("opencode").setup({
        default_global_keymaps = false,
      })
    end,
  }

M["folke/sidekick.nvim"] = {
    "folke/sidekick.nvim",
    event = "VeryLazy",
    opts = {
      cli = {
        picker = "snacks",
      },
    },
  }

M["zbirenbaum/copilot.lua"] = {
    "zbirenbaum/copilot.lua",
    event = "InsertEnter",
    cmd = "Copilot",
    config = function()
      if vim.g.copilot_attached == nil then
        vim.g.copilot_attached = false
      end
      require("copilot").setup({
        suggestion = {
          enabled = true,
          auto_trigger = true,
          keymap = {
            accept = false,
            dismiss = false,
            next = false,
            prev = false,
          },
        },
        panel = { enabled = false },
        should_attach = function()
          return vim.g.copilot_attached == true
        end,
      })
    end,
  }

return M
