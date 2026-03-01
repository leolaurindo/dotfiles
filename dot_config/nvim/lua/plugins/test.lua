local M = {}

M["nvim-neotest/neotest"] = {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-neotest/nvim-nio",
      "nvim-neotest/neotest-go",
      "nvim-neotest/neotest-python",
    },
    config = function()
      local neotest = require("neotest")

      local function resolve_python()
        local venv = vim.env.VIRTUAL_ENV or vim.env.CONDA_PREFIX
        if venv and venv ~= "" then
          local python_candidates = {
            venv .. "/bin/python",
            venv .. "/Scripts/python.exe",
          }
          for _, python in ipairs(python_candidates) do
            if vim.fn.executable(python) == 1 then
              return python
            end
          end
        end

        local root = vim.fn.getcwd()
        if root and root ~= "" then
          local python_candidates = {
            root .. "/.venv/bin/python",
            root .. "/.venv/Scripts/python.exe",
          }
          for _, python in ipairs(python_candidates) do
            if vim.fn.executable(python) == 1 then
              return python
            end
          end
        end

        if vim.fn.executable("python3") == 1 then
          return vim.fn.exepath("python3")
        end
        if vim.fn.executable("python") == 1 then
          return vim.fn.exepath("python")
        end

        return (vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1) and "python" or "python3"
      end

      neotest.setup({
        adapters = {
          require("neotest-go")({}),
          require("neotest-python")({
            python = resolve_python,
          }),
        },
      })

      vim.keymap.set("n", "<leader>tt", function()
        neotest.run.run()
      end, { silent = true, desc = "Test nearest" })
      vim.keymap.set("n", "<leader>tT", function()
        neotest.run.run(vim.fn.expand("%"))
      end, { silent = true, desc = "Test file" })
      vim.keymap.set("n", "<leader>ts", function()
        neotest.run.run(vim.fn.getcwd())
      end, { silent = true, desc = "Test suite" })
      vim.keymap.set("n", "<leader>to", function()
        neotest.output.open({ enter = true })
      end, { silent = true, desc = "Test output" })
      vim.keymap.set("n", "<leader>tO", neotest.output_panel.toggle, { silent = true, desc = "Test output panel" })
    end,
  }

return M
