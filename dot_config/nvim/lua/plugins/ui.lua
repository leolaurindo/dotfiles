local M = {}

M["folke/tokyonight.nvim"] = { "folke/tokyonight.nvim", lazy = false, priority = 1000 }

M["catppuccin/nvim"] = { "catppuccin/nvim", name = "catppuccin", lazy = true }

M["sainnhe/everforest"] = { "sainnhe/everforest", lazy = true }

M["rose-pine/neovim"] = { "rose-pine/neovim", name = "rose-pine", lazy = true }

M["navarasu/onedark.nvim"] = { "navarasu/onedark.nvim", lazy = true }

M["rebelot/kanagawa.nvim"] = { "rebelot/kanagawa.nvim", lazy = true }

M["EdenEast/nightfox.nvim"] = { "EdenEast/nightfox.nvim", name = "nightfox", lazy = true }

M["ellisonleao/gruvbox.nvim"] = { "ellisonleao/gruvbox.nvim", lazy = true }

M["sainnhe/sonokai"] = { "sainnhe/sonokai", lazy = true }

M["projekt0n/github-nvim-theme"] = { "projekt0n/github-nvim-theme", lazy = true }

M["nvimdev/zephyr-nvim"] = { "nvimdev/zephyr-nvim", lazy = true }

M["samharju/synthweave.nvim"] = { "samharju/synthweave.nvim", lazy = true }

M["Mofiqul/dracula.nvim"] = { "Mofiqul/dracula.nvim", lazy = true }

M["marko-cerovac/material.nvim"] = { "marko-cerovac/material.nvim", lazy = true }

M["fxn/vim-monochrome"] = { "fxn/vim-monochrome", lazy = true }

M["kdheepak/monochrome.nvim"] = { "kdheepak/monochrome.nvim", lazy = true }

M["wnkz/monoglow.nvim"] = {
    "wnkz/monoglow.nvim",
    lazy = true,
    opts = {
      on_colors = function(colors)
        colors.glow = "#7dcfff"
      end,
    },
  }

M["nvim-lualine/lualine.nvim"] = {
    "nvim-lualine/lualine.nvim",
    name = "lualine",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
     config = function()
       local mode_map = {
         ["NORMAL"] = "N",
         ["O-PENDING"] = "O",
         ["INSERT"] = "I",
         ["VISUAL"] = "V",
         ["V-LINE"] = "VL",
         ["V-BLOCK"] = "VB",
         ["SELECT"] = "S",
         ["S-LINE"] = "SL",
         ["S-BLOCK"] = "SB",
         ["REPLACE"] = "R",
         ["V-REPLACE"] = "VR",
         ["COMMAND"] = "C",
         ["EX"] = "EX",
         ["MORE"] = "M",
         ["CONFIRM"] = "CF",
         ["SHELL"] = "SH",
         ["TERMINAL"] = "T",
       }

        require("lualine").setup({
          options = {
            theme = "auto",
            -- NOTE for future agents: user requested square/rectangular separators.
            -- Keep old rounded separators commented for quick rollback if requested.
            -- section_separators = { left = "", right = "" },
            -- component_separators = { left = "", right = "" },
            section_separators = { left = "", right = "" },
            component_separators = { left = "|", right = "|" },
          },
         sections = {
           lualine_a = {
             {
               "mode",
               fmt = function(str)
                 return mode_map[str] or str
               end,
             },
           },
           lualine_b = { "branch" },
           lualine_c = { { "filename", path = 1 } },
           lualine_x = { "diff" },
           lualine_y = { "progress" },
           lualine_z = {},
         },
         inactive_sections = {
           lualine_a = {},
           lualine_b = {},
           lualine_c = { { "filename", path = 1 } },
           lualine_x = { "diff" },
           lualine_y = {},
           lualine_z = {},
         },
       })
     end,
  }

M["rcarriga/nvim-notify"] = {
    "rcarriga/nvim-notify",
    lazy = false,
    opts = {
      stages = "fade",
      timeout = 120,
      fps = 60,
      top_down = false,
    },
    config = function(_, opts)
      local notify = require("notify")
      notify.setup(opts)
      vim.notify = notify
    end,
  }

M["folke/noice.nvim"] = {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    opts = {
      messages = {
        enabled = false,
      },
      notify = {
        enabled = true,
      },
      cmdline = {
        enabled = false,
      },
      popupmenu = {
        enabled = false,
      },
      lsp = {
        progress = {
          enabled = false,
        },
        message = {
          enabled = false,
        },
        signature = {
          enabled = vim.g.lsp_signature_help_enabled ~= false,
          auto_open = {
            enabled = vim.g.lsp_signature_help_enabled ~= false,
          },
        },
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = vim.g.noice_cmp_docs_override_enabled ~= false,
        },
      },
      presets = {
        command_palette = false,
        long_message_to_split = true,
        lsp_doc_border = true,
      },
    },
  }

M["folke/which-key.nvim"] = {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "modern",
      plugins = {
        spelling = false,
      },
      win = {
        border = "single",
      },
    },
    config = function(_, opts)
      local wk = require("which-key")
      wk.setup(opts)
      wk.add({
        { "<leader>.", group = "Scratch" },
      })
    end,
  }

M["stevearc/aerial.nvim"] = {
    "stevearc/aerial.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("aerial").setup({
        backends = { "lsp", "treesitter" },
        disable_max_lines = 50000,
        layout = { width = 35, default_direction = "right" },
        show_guides = true,
        autojump = true,
      })
    end,
  }

M["SmiteshP/nvim-navic"] = {
     "SmiteshP/nvim-navic",
     dependencies = "neovim/nvim-lspconfig",
      opts = {
        highlight = true,
        separator = " > ",
        depth_limit = 3,
      },
   }

M["arnamak/stay-centered.nvim"] = {
     "arnamak/stay-centered.nvim",
     config = function()
         require("stay-centered").setup({
           skip_filetypes = {},
           enabled = false,  -- Start disabled, toggle with :TW
           allow_scroll_move = false,   -- ALWAYS center when cursor moves (no scrolling exceptions)
           disable_on_mouse = true,    -- Disable centering during mouse selection
         })
     end,
   }

M["folke/zen-mode.nvim"] = {
      "folke/zen-mode.nvim",
      config = function()
        require("zen-mode").setup({
          window = {
            backdrop = 0.95,
            width = 80,
            height = 1,
            options = {
              signcolumn = "no",
              number = false,
              relativenumber = false,
              cursorline = false,
              cursorcolumn = false,
              foldcolumn = "0",
              list = false,
            },
          },
          plugins = {
            options = {
              enabled = true,
              ruler = false,
              showcmd = false,
            },
            twilight = { enabled = false },
            gitsigns = { enabled = false },
            tmux = { enabled = false },
          },
        })
      end,
    }

M["goolord/alpha-nvim"] = {
  "goolord/alpha-nvim",
  event = "VimEnter",
  config = function()
    local alpha = require("alpha")
    local dashboard = require("alpha.themes.dashboard")

    local function dash_button(shortcut, label, cmd)
      local b = dashboard.button(shortcut:lower(), "   " .. label:lower(), cmd)
      b.opts.align_shortcut = "left"
      b.opts.cursor = 1
      b.opts.width = 30
      b.opts.hl = "Normal"
      b.opts.hl_shortcut = "Keyword"
      return b
    end
--   ============== THE CAPYBARAS ==============
    dashboard.section.header.val = {
      -- "⠀⠀⠀⠀⠀⠀⠀⠀⢤⣞⣆⢀⣠⢶⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      -- "⠀⣄⣀⡤⠤⠖⠒⠋⠉⣉⠉⠹⢫⠾⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      -- "⢨⡏⣶⡇⠸⣿⠟⠛⠛⣿⢇⠀⠀⠀⠈⠙⠦⣄⡀⢀⣀⣠⡤⠤⠶⠒⠒⢿⠋⠙⢈⣒⡒⠲⠤⣄⡀⠀⠀⠀⠀⠀⠀",
      -- "⢸⠀⢸⠈⠀⠀⠀⠀⠀⠀⣀⡀⠀⠀⠀⠀⠀⠀⠈⠉⠀⠴⠂⣀⠀⠀⣴⡄⠉⢷⡄⠚⠀⢤⣒⠦⠉⠳⣇⡯⡵⠀⠀",
      -- "⠸⡿⠾⠶⠏⠀⠀⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡤⠀⠀⡀⠀⠀⠀⠀⠀⠀⠀⣄⡂⠠⣀⠐⠍⠂⠙⣗⣇⠀",
      -- "⠀⠙⠦⢄⣈⣁⣀⣀⡀⠀⢷⠀⢦⠀⠠⣄⠀⠀⠀⠀⠀⠀⠀⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠰⡇⠠⣀⠱⠘⣧⠀",
      -- "⠀⠀⠀⠀⠀⠀⠀⠈⠉⢷⣧⡄⢼⠀⢀⠀⠈⠀⠀⠀⠀⠀⠀⣙⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⡈⠀⢄⢸⡄",
      -- "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⣿⡀⠃⠘⠂⠲⡀⠀⠀⠀⠀⠀⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⠀⡈⢘⡇",
      -- "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢫⡑⠣⠰⠀⢁⢀⡀⠀⠐⠒⠆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠁⣸⠁",
      -- "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⣯⠂⡀⢨⠀⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡆⣾⡄⠀⠀⡄⠀⣀⠐⡅⣴⠁⠀",
      -- "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣧⡈⡀⢠⣧⣤⣀⣀⡀⣄⡀⠀⠀⢀⣼⣀⠉⡟⢸⢀⡀⠘⢓⣤⡟⠁⠀⠀",
      -- "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢺⡁⢁⣸⡏⠀⠀⠀⠀⠑⠀⠉⠉⠁⠹⡟⢢⢱⠀⣿⣷⠶⠻⡇⠀⠀⠀⠀",
      -- "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢈⡏⠈⡟⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠑⢄⠁⠀⡿⣿⠀⠀⣹⠁⠀⠀⠀",
      -- "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⡤⠚⠃⣰⣥⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⠼⢹⡷⡻⠀⡼⠁⠀⠀⠀⠀",
      -- "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠟⠿⡿⠕⠊⠉⠀⠀⠀⠀⠀⠀⠀⠀⣠⣴⣶⣾⣛⣿⣷⣟⣚⣁⡼⠁⠀⠀⠀⠀⠀",
      -- "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠙⠋⠁⠉⠀⠀⠈⠀⠀⠀⠀⠀⠀⠀⠀ ",
--
-- "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⡿⢿⣿⣿⡿⣿⣦⣤⣤⣄⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
-- "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⡿⠁⠈⡾⠃⠀⠟⣙⣿⡿⠙⠛⠿⣾⣤⡠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
-- "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣴⡿⠁⠀⠀⠀⠀⠀⠈⠛⢿⣆⠀⠀⠀⠀⠙⠻⣧⣆⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
-- "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⡿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠛⠛⣿⡆⠀⠀⠀⠀⠙⢿⣵⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
-- "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣼⡿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡴⠋⠁⠀⠀⠀⠀⠀⠘⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
-- "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣶⠿⠋⠀⠀⠀⠀⠀⠀⠀⠀⡠⠤⠂⠤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠹⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
-- "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⡿⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⢀⠋⠀⠀⠀⠀⠀⠉⢢⡀⠀⠀⠀⠀⠀⠀⣿⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
-- "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠰⣿⡏⠀⠀⠀⠀⠀⣀⠀⠀⠀⠀⢀⡎⠀⠀⠀⣠⣄⠀⠀⠀⠱⡀⠀⠀⠀⠀⠀⢸⣿⢷⣦⡀⡀⠀⠀⠀⠀⠀⠀⠀",
-- "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢂⣿⡇⠀⠀⠀⠀⠿⠟⠁⠀⠀⠀⡜⠀⠀⠀⣰⣿⢿⣧⠀⠀⠀⢳⠀⠀⠀⠀⠀⢸⣿⡀⠙⢿⣦⣀⠀⠀⠀⠀⠀⠀",
-- "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣾⡿⢿⣶⣤⣄⡀⠀⠀⠀⠀⠀⡼⠀⠀⠀⣴⣿⠃⠈⣿⡇⠀⠀⢸⠀⠀⠀⠀⠀⢸⣿⢿⣦⠀⠻⣿⣥⡀⠀⠀⠀⠀",
-- "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⣀⢀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⡾⠟⠁⢀⣠⣤⣾⣿⣿⣶⣄⠀⢀⡴⠁⠀⢀⣴⡿⠃⠀⠀⣿⡇⠀⠀⡞⠀⠀⠀⠀⠀⢸⡇⠀⠹⣷⡄⠘⢿⣷⠀⠀⠀⠀",
-- "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⢀⣴⣿⣿⣷⣄⣀⣤⣿⠾⣵⠀⠀⠀⠀⠀⠀⠀⣠⡾⠋⢁⣠⡶⠟⠋⠀⣰⣿⠟⠉⠙⢿⣮⣄⢀⣠⣾⠟⠁⠀⠀⢰⣿⠃⣀⠜⠀⠀⠀⠀⠀⠀⣿⡇⠀⠀⠘⣿⡄⠈⢿⣏⠀⠀⠀",
-- "⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣴⠾⠛⢋⠩⢉⠁⡉⠸⢿⣏⣿⢖⡟⠀⠀⠀⠀⠀⢀⣾⠋⢀⣴⠿⠉⠁⠀⢀⣾⡟⠁⠀⠀⠀⠀⠉⣿⡿⠛⠁⠀⠀⠀⠀⡿⠏⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣿⡄⠈⣿⡆⠀⠀",
-- "⠀⠀⠀⠀⠀⠀⢀⣤⠾⢋⠡⢀⠂⡁⢂⠰⢀⠒⠠⢁⠂⠹⠞⠋⠿⣶⡀⠀⠀⣰⡟⢡⣴⠿⠃⠀⠀⠀⢨⣾⠟⠀⠀⠀⠀⠀⠀⣼⡟⡀⠀⣀⣀⡤⠔⠊⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⡀⠸⣷⠀⠀",
-- "⠀⠀⠀⢀⣠⡶⢋⠁⢂⠄⠒⡈⠐⡐⢾⠿⠗⢈⠐⠂⠌⢂⠌⠒⠠⠙⣷⣀⣴⠏⣠⡿⠋⠀⠀⠀⠀⢀⣿⠏⠀⠀⠀⠀⠀⢀⣾⠋⠀⠈⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⣧⠀⢿⡇⠀",
-- "⠀⠀⣼⣿⣍⢀⠂⠌⠤⢈⠐⠄⣁⠂⠌⡐⠈⡄⠌⢂⢁⠂⠌⡐⢁⠂⠌⠻⣯⣴⠟⠁⠀⠀⠀⠀⠀⣾⠏⠀⠀⠀⠀⠀⢠⣾⠋⢆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⡄⣸⡟⠀",
-- "⠐⣾⣿⡝⡾⣇⢈⠰⠐⡀⢊⠐⢠⠈⠒⡈⢐⠠⠌⣀⠢⠈⠔⠠⡁⠌⢂⠡⢀⠛⠶⣔⣂⡀⠀⠀⣸⡏⠀⠀⠀⠀⠀⢠⣿⡇⠀⠈⢆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣻⣷⣿⣥⣄",
-- "⢸⣿⢾⣿⡹⢿⡆⠠⢁⠒⠠⠉⠄⠨⡐⠐⡈⠄⢡⠀⢂⢁⠊⡐⠠⠘⡀⠒⢠⠈⡐⠠⢉⠛⠛⣳⡿⠀⠀⠀⠀⠀⢠⡿⢻⣷⠀⠀⠈⠢⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣿⢋⣿⡿⠁",
-- "⠐⣿⣿⣿⣝⣻⡇⠄⠃⠌⡐⢁⠊⠡⢀⠃⡐⡈⠄⠌⣀⠂⢂⢁⠂⠅⡐⢁⠂⠌⢠⠁⠆⡈⢄⣿⠃⠀⠀⠀⠀⣰⣿⣷⠀⢿⣆⠀⠀⠀⠉⠦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡠⠊⣽⣿⣿⠟⠀⠀",
-- "⠀⠉⣿⣿⣞⡽⣦⣌⡐⢂⠁⠢⠌⡁⢂⠌⡐⢠⠘⠠⡀⠌⠄⢂⠌⡐⠈⡄⠌⢂⠡⠈⠔⠠⢸⡟⠀⠀⠀⠀⣠⡿⡉⢿⣆⡈⢻⣧⠀⠀⠀⠀⠈⠒⠄⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡀⠤⠊⠁⢀⣾⣿⠟⠃⠀⠀⠀",
-- "⠀⠀⠀⠙⠻⢿⣷⣻⣻⣟⣶⣷⣤⣴⣢⣴⣤⡆⠈⠔⠠⡈⠔⢂⠐⠠⠡⠐⡈⠄⢂⠉⠄⠡⣾⠇⠀⠀⠀⢰⡿⢃⠐⠠⠛⢿⡶⠿⣷⣄⠀⠀⠀⠀⠀⠀⠉⠑⠒⠂⠤⠠⠐⠒⠒⠂⠉⠁⠀⠀⢀⣴⣿⠟⠉⠀⠀⠀⠀⠀",
-- "⠀⠀⠀⠀⠀⠀⠈⠉⠉⠉⣻⣟⡿⣻⡏⢉⠡⢀⠉⠄⡡⠐⡈⠄⣈⠁⣂⠡⢐⠨⢀⠊⠌⢰⣿⠀⠀⠀⣠⣿⠃⠄⠌⡠⠁⠌⢿⡄⠘⠽⢿⣦⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣤⣾⣿⣿⠅⠀⠀⠀⠀⠀⠀⠀",
-- "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⢿⡾⣵⣻⣆⠐⡈⠰⠈⠄⠡⠐⡈⠄⢂⠄⢂⠂⠤⠁⠌⡐⣸⡏⠀⠀⢠⣿⠃⠌⡐⠂⠄⡡⠈⠌⣷⠀⠀⠀⠘⣿⣿⠿⣶⣦⣤⣤⣤⣤⣤⣄⣤⣤⣾⠿⠻⣿⡁⢹⣿⠂⠀⠀⠀⠀⠀⠀⠀",
-- "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢿⣳⣭⢟⣶⣀⠡⠌⡈⠔⠡⠐⡈⠤⢈⡐⠈⠤⢁⠂⣤⣹⡇⠀⢠⣿⠇⡈⢐⠠⢁⠒⠠⡁⠌⣹⡆⠀⠀⠀⢸⣿⢀⣿⡏⠉⠉⠉⠉⠙⠛⠛⠋⠀⠀⠀⢿⡇⣺⣿⠀⠀⠀⠀⠀⠀⠀⠀",
-- "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠿⣾⢯⣞⢿⣳⣤⡐⡈⠄⡑⠠⠒⠠⠠⢉⠐⢠⣾⡿⣿⠀⢀⣿⢃⠐⠠⢁⠂⠂⡌⠐⡐⠠⢸⡇⠀⠀⠀⠈⣿⣼⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣹⣿⠀⠀⠀⠀⠀⠀⠀⠀",
-- "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⣾⣏⢾⣿⣟⡷⣤⣄⠁⢊⠐⡁⠂⣌⣿⢯⣳⣿⢀⣾⠏⠠⢈⠒⠠⡈⢡⠠⠡⠠⢁⢺⡇⠀⠀⠀⠀⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⢿⣿⠀⠀⠀⠀⠀⠀⠀⠀",
-- "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣿⣷⣿⣯⠾⣝⣯⣿⡶⣷⢶⡿⣻⣿⣏⢷⣿⣼⠏⠠⢁⠂⠌⡐⢐⡀⢂⢁⠒⡀⣿⠁⠀⠀⠀⠀⣿⡿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⢸⣿⠀⠀⠀⠀⠀⠀⠀⠀",
-- "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⣯⢹⣿⣿⣹⢶⣿⣽⣧⣟⣾⡽⣿⢮⣛⣿⡋⠄⡁⠂⠌⡐⠈⡄⠰⢀⢂⣰⣼⡏⠁⠀⠀⠀⠀⣿⡇⢿⣷⣄⣀⣀⢀⡀⢸⣿⣶⣶⣶⣶⣿⠏⢸⣿⡀⠀⠀⠀⠀⠀⠀⠀",
-- "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⢿⢸⣟⣯⠉⣿⣧⠀⠀⠉⠉⠉⢻⣯⢷⡹⣟⣶⣤⣉⣐⣠⣥⣤⡷⣾⣻⣿⠟⠀⠀⠀⠀⣠⣿⡟⠁⢀⠈⠙⠛⠛⢿⣿⠀⣿⣇⣀⣦⠀⢀⡆⠀⢿⣧⢄⠀⠀⠀⠀⠀⠀",
-- "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣾⡿⣿⣴⣿⠏⠀⠀⠀⠀⠀⠈⢹⣿⣽⣝⡞⣷⢫⡿⣹⣎⣷⣽⠷⠛⠁⠀⠀⠀⠀⠘⣾⣏⡼⠆⠘⢷⡀⠀⢛⣿⣿⠿⠿⣿⣯⣄⢀⡾⠁⠰⣬⣻⣷⣄⡀⠀⠀⠀⠀",
-- "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⠙⠋⠁⠻⠟⠋⠀⠀⠀⠀⠀⠀⠀⠜⠿⠿⠿⠷⠿⠾⠳⠛⠛⠋⠉⠀⠀⠀⠀⠀⠀⠀⠠⣿⣿⣧⣤⣤⣈⣷⣠⣾⠟⠉⠀⠀⠉⠻⣿⣾⣧⣤⣶⣽⣿⣿⣿⣅⠀⠀⠀⠀",
-- "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠟⠉⠉⠉⠉⠛⠛⢿⡏⠀⠀⠀⠀⠀⠀⠈⠉⠉⠉⠁⠉⠉⠉⠽⠟⠀⠀⠀⠀",
"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⣀⣀⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢤⡿⠹⣿⠟⣿⠶⣶⢶⣤⣄⡄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢨⡟⠁⠀⠁⠀⠐⠿⣯⠀⠀⠉⠛⢶⣤⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣴⡿⠁⠀⠀⠀⠀⠀⠐⠛⣻⠄⠀⠀⠀⠹⣶⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⡾⠋⠀⠀⠀⠀⠀⠀⣀⢀⡈⠁⠀⠀⠀⠀⠀⢹⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀",
"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⡶⠟⠉⠀⠀⠀⠀⠀⠀⢠⠉⠀⠀⠀⠑⢄⠀⠀⠀⠀⠀⣿⡠⡀⠀⠀⠀⠀⠀⠀⠀",
"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⠁⠀⠀⢀⣠⡀⠀⠀⢠⠃⠀⠀⣴⣄⠀⠀⢡⠀⠀⠀⠀⢸⡟⢷⣄⠀⠀⠀⠀⠀⠀",
"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣦⣀⡀⠈⠉⠀⠀⢀⠆⠀⢀⣾⠏⢿⡆⠀⠀⡄⠀⠀⠀⢸⣷⣄⠙⣷⡦⠀⠀⠀⠀",
"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⡾⠋⢀⣨⣭⣿⣶⣄⡀⢀⠎⠀⢀⣾⠏⠀⢸⡇⠀⢠⠁⠀⠀⠀⢸⡇⠙⣧⡈⢻⣇⠀⠀⠀",
"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣰⡿⠿⠷⣤⣴⡟⣳⠄⠀⠀⠀⠀⣠⡞⢃⣠⡾⠏⠁⣰⡿⠃⠈⠻⣧⣄⣴⡿⠁⠀⢀⣾⣇⠴⠃⠀⠀⠀⠀⠿⠀⠀⠈⢷⡀⢻⣆⠀⠀",
"⠀⠀⠀⠀⠀⠀⣀⡴⠞⠋⠡⠐⡀⠂⡄⡉⢳⣯⢿⣀⠀⠀⢀⡴⢋⣴⠟⠁⠀⢠⣼⠏⠀⠀⠀⠀⣰⠟⠁⠀⠀⣀⠔⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣷⠀⢿⡀⠀",
"⠀⠀⠀⢀⡴⢋⠡⢀⠂⠡⢂⢵⠶⢁⠐⠠⠂⡄⠠⠙⣧⣠⡞⣡⠞⠁⠀⠀⢀⣾⠃⠀⠀⠀⠀⣴⠋⠈⠀⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⣇⠸⣧⠀",
"⠀⣀⣾⣯⡐⠀⠆⢂⠉⡐⠤⢈⠐⠠⢊⠁⢂⠄⡑⢠⠈⠻⣴⠋⠀⠀⠀⠀⣸⠇⠀⠀⠀⠀⣼⠋⢆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⢠⡿⠀",
"⢰⣿⣿⡜⣷⠡⠈⢄⠘⡀⢂⠌⡀⠣⠄⢨⠀⢂⠌⠠⠘⢠⠐⡙⠲⠶⢤⣤⡏⠀⠀⠀⢀⡾⣷⠀⠈⢂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⠿⣷⠗",
"⠘⢿⣿⣏⣿⠀⠡⢂⠂⣁⠢⠐⠄⢂⠌⠠⠌⠠⠌⡐⢁⠂⠔⠠⢁⠂⢄⡿⠀⠀⠀⢀⣾⡇⢹⣆⠀⠀⠑⢄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡠⢺⣿⣾⠋⠀",
"⠀⠩⢿⣾⡽⣦⣅⣂⠰⢀⠂⠥⠈⠤⢈⡐⠈⠔⢂⠐⡈⠌⠠⢃⠐⡈⢼⡇⠀⠀⢀⡾⠍⢿⣄⡹⣦⠀⠀⠀⠑⠢⢀⡀⠀⠀⠀⠀⠀⠀⢀⡀⠄⠂⠁⣰⡿⠏⠀⠀⠀",
"⠀⠀⠀⠈⠛⠷⠯⠿⣿⣷⣾⡶⠷⠒⠠⢀⠃⠌⡀⠆⡐⡈⣁⠂⢂⠐⣿⠀⠀⢀⣾⠃⠌⠠⠙⣯⠙⢷⣤⡀⠀⠀⠀⠀⠈⠉⠉⠉⠉⠀⠀⠀⣀⣴⡾⠛⠀⠀⠀⠀⠀",
"⠀⠀⠀⠀⠀⠀⠀⠀⢹⡾⡵⣧⠠⢁⠡⠂⠌⡠⢁⠂⢄⠡⢀⠌⠠⢘⡇⠀⢀⣾⠃⠌⠠⢁⠂⠜⡆⠈⠈⠹⣷⣶⣤⣤⣀⣀⣀⣀⣀⣤⡶⢿⡟⢹⡗⠀⠀⠀⠀⠀⠀",
"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠻⣽⣽⣳⣄⢂⠁⠒⡀⠆⡈⠄⠒⡈⠄⣡⣾⠇⠀⣾⠃⠌⠠⡁⠂⢌⠐⢻⠀⠀⠀⣿⡆⣿⠉⠉⠉⠉⠉⠙⠁⠀⠀⣿⢸⣏⠀⠀⠀⠀⠀⠀",
"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢾⣗⡯⢿⣦⣅⡐⠠⢁⡘⠠⠐⣴⡿⣿⠀⣼⢋⠐⡈⠡⢀⠍⠠⠌⣸⠀⠀⠀⢸⣷⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⣾⡏⠀⠀⠀⠀⠀⠀",
"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⣿⣯⣿⣝⠿⣶⣦⣤⣥⣾⣟⡷⣿⣸⠏⡀⢂⠁⠆⠡⠈⠔⡀⡿⠀⠀⠀⢸⡿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣧⠀⠀⠀⠀⠀⠀",
"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⡏⣿⣯⣟⣽⠾⣵⣯⣞⣿⣼⢻⣏⠠⠐⡠⠡⠈⠔⣁⣢⣼⠋⠀⠀⠀⣸⡇⠿⣦⣄⣀⣀⠰⣷⠶⢶⣶⠿⠈⣿⠀⠀⠀⠀⠀⠀",
"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣿⣼⣿⠠⣿⠀⠀⠀⠀⠙⣾⣏⡾⣷⢶⣤⡵⣾⣞⣿⠿⠋⠀⠀⢠⣶⠟⡀⢤⡀⠉⢭⣿⣄⣿⣦⠶⠀⡸⢀⠹⣧⣀⠀⠀⠀⠀",
"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⠙⠋⠻⠿⠉⠀⠀⠀⠀⠀⠻⠿⠷⠿⠿⠞⠛⠛⠉⠀⠀⠀⠀⠀⢀⣿⣾⣥⣤⣱⣤⣾⠋⠁⠉⠙⢷⣾⣥⣤⣽⣿⣷⣆⠀⠀⠀",
"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠋⠀⠀⠉⠉⠻⠇⠀⠀⠀⠀⠀⠈⠀⠀⠀⠀⠉⠋⠀⠀⠀",
}

    dashboard.section.buttons.val = {
      dash_button("/", "Search files (cwd)", "<cmd>DashboardSearchCwd<CR>"),
      dash_button("r", "Restore session (cwd)", "<cmd>SessionRestore<CR>"),
      dash_button("o", "Open Oil", "<cmd>Oil<CR>"),
      dash_button("n", "New file", "<cmd>ene<CR>"),
    }
    alpha.setup(dashboard.config)

    -- Keep startup simple: force the capybara dashboard on bare startup.
    -- Guard against calling :Alpha when already on alpha buffer, since that
    -- command can close the dashboard (it tries to jump to alternate buffer).
    vim.schedule(function()
      local name = vim.api.nvim_buf_get_name(0)
      local empty_buf = name == "" and vim.bo.buftype == "" and vim.api.nvim_buf_line_count(0) <= 1
      if empty_buf then
        local line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] or ""
        empty_buf = line == ""
      end

      if (vim.fn.argc() == 0 or empty_buf) and vim.bo.filetype ~= "alpha" then
        pcall(vim.cmd, "Alpha")
      end
    end)
  end,
}

return M
