local M = {}

M["epwalsh/obsidian.nvim"] = {
    "epwalsh/obsidian.nvim",
    version = "*",
    cmd = { "Obsidian" },
    init = function()
      local group = vim.api.nvim_create_augroup("ObsidianAutoLoad", { clear = true })

      local function in_vault(start_path)
        local path = start_path
        if not path or path == "" then
          path = vim.uv.cwd()
        end

        local stat = vim.uv.fs_stat(path)
        local search_from = path
        if stat and stat.type ~= "directory" then
          search_from = vim.fs.dirname(path)
        end

        local matches = vim.fs.find(".obsidian", {
          path = search_from,
          upward = true,
          type = "directory",
          limit = 1,
        })

        return #matches > 0
      end

      vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
        group = group,
        pattern = "*.md",
        callback = function(args)
          if package.loaded["obsidian"] then
            return
          end

          local bufname = vim.api.nvim_buf_get_name(args.buf)
          if in_vault(bufname) then
            require("lazy").load({ plugins = { "epwalsh/obsidian.nvim" } })
          end
        end,
      })
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = {
      ui = {
        enable = false,
      },
      workspaces = {
        {
          name = "dynamic",
          path = function()
            local bufname = vim.api.nvim_buf_get_name(0)
            if bufname and bufname ~= "" then
              return assert(vim.fs.dirname(bufname))
            end
            return assert(vim.fn.getcwd())
          end,
          overrides = {
            notes_subdir = vim.NIL,
            new_notes_location = "current_dir",
            templates = {
              folder = vim.NIL,
            },
            disable_frontmatter = true,
          },
        },
      },
      completion = {
        nvim_cmp = true,
        min_chars = 2,
      },
      mappings = {},
    },
  }

return M
