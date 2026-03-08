local M = {}

M["3rd/image.nvim"] = {
    "3rd/image.nvim",
    enabled = vim.fn.has("win32") == 0 and vim.fn.has("win64") == 0,
    build = false,
    opts = {
      backend = "sixel",
      processor = "magick_cli",
      integrations = {
        markdown = {
          enabled = false,
        },
        neorg = {
          enabled = false,
        },
        typst = {
          enabled = false,
        },
        html = {
          enabled = false,
        },
        css = {
          enabled = false,
        },
      },
    },
  }

M["benlubas/molten-nvim"] = {
    "benlubas/molten-nvim",
    lazy = false,
    version = "^1.0.0",
    build = ":UpdateRemotePlugins",
    dependencies = {
      "willothy/wezterm.nvim",
    },
    init = function()
      local is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
      local is_wsl = vim.fn.has("wsl") == 1
      local in_wezterm = type(vim.env.WEZTERM_PANE) == "string" and vim.env.WEZTERM_PANE ~= ""

      if is_windows and not is_wsl then
        -- image.nvim does not support native Windows reliably.
        -- Use WezTerm's native image support when available, otherwise popup-only.
        vim.g.molten_image_provider = in_wezterm and "wezterm" or "none"
      else
        vim.g.molten_image_provider = "image.nvim"
      end

      vim.g.molten_auto_open_output = false
      vim.g.molten_output_win_max_height = 18
      vim.g.molten_output_show_more = true
      vim.g.molten_virt_text_output = true
      vim.g.molten_virt_text_max_lines = 20
      vim.g.molten_image_location = "virt"
      vim.g.molten_auto_image_popup = is_windows and not is_wsl and not in_wezterm
      vim.g.molten_wrap_output = true
      vim.g.create_kernel_auto_molten = false

      if vim.fn.executable("wslview") == 1 then
        vim.g.molten_open_cmd = vim.fn.exepath("wslview")
      end
    end,
  }

return M
