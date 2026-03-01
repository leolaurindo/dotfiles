local M = {}

M["mfussenegger/nvim-lint"] = {
    "mfussenegger/nvim-lint",
    config = function()
      local lint = require("lint")
      local is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1

      lint.linters_by_ft = {}

      local function project_root_from_buf(bufnr)
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        local start = nil
        if bufname and bufname ~= "" then
          start = vim.fs.dirname(bufname)
        else
          start = vim.fn.getcwd()
        end

        local found = vim.fs.find({ ".venv", "pyproject.toml", "setup.cfg", "setup.py", "requirements.txt", ".git" }, {
          path = start,
          upward = true,
        })
        if found and found[1] then
          return vim.fs.dirname(found[1])
        end
        return vim.fn.getcwd()
      end

      local function resolve_ruff(root_dir)
        local venv = vim.env.VIRTUAL_ENV or vim.env.CONDA_PREFIX
        if venv and venv ~= "" then
          local ruff_candidates = {
            venv .. "/bin/ruff",
            venv .. "/Scripts/ruff.exe",
          }
          for _, ruff in ipairs(ruff_candidates) do
            if vim.fn.executable(ruff) == 1 then
              return ruff, nil
            end
          end
        end

        if root_dir and root_dir ~= "" then
          local ruff_candidates = {
            root_dir .. "/.venv/bin/ruff",
            root_dir .. "/.venv/Scripts/ruff.exe",
          }
          for _, ruff in ipairs(ruff_candidates) do
            if vim.fn.executable(ruff) == 1 then
              return ruff, nil
            end
          end
        end

        if vim.fn.executable("uv") == 1 then
          return "uv", { "tool", "run", "ruff" }
        end

        if vim.fn.executable("ruff") == 1 then
          return "ruff", nil
        end

        return nil, nil
      end

      local ruff_base_args = nil
      local function ensure_ruff_linter(bufnr)
        local ok, ruff = pcall(require, "lint.linters.ruff")
        if not ok then
          return false
        end

        if not ruff_base_args then
          ruff_base_args = vim.deepcopy(ruff.args or {})
        end

        local root_dir = project_root_from_buf(bufnr)
        local cmd, prefix = resolve_ruff(root_dir)
        if not cmd then
          return false
        end

        ruff.cmd = cmd
        ruff.args = vim.deepcopy(ruff_base_args)
        if prefix then
          ruff.args = vim.list_extend(vim.deepcopy(prefix), ruff.args)
        end
        lint.linters.ruff = ruff
        return true
      end

      local debounce_ms = 200
      local lint_timer = vim.loop.new_timer()
      local function debounce_lint()
        if not lint_timer then
          lint_timer = vim.loop.new_timer()
        end
        lint_timer:stop()
        lint_timer:start(debounce_ms, 0, vim.schedule_wrap(function()
          local bufnr = vim.api.nvim_get_current_buf()
          if vim.bo[bufnr].filetype == "python" then
            if ensure_ruff_linter(bufnr) then
              lint.linters_by_ft.python = { "ruff" }
            else
              lint.linters_by_ft.python = {}
            end
          end
          lint.try_lint()
        end))
      end

      local function set_linter(ft, linters)
        lint.linters_by_ft[ft] = linters
      end

      local function resolve_node_linter_cmd(bin, bufnr)
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        local start = (bufname and bufname ~= "") and vim.fs.dirname(bufname) or vim.fn.getcwd()
        local node_modules = vim.fs.find("node_modules", {
          path = start,
          upward = true,
          type = "directory",
        })

        if node_modules and node_modules[1] then
          local local_bin = node_modules[1] .. "/.bin/" .. bin .. (is_windows and ".cmd" or "")
          if vim.fn.executable(local_bin) == 1 then
            return local_bin
          end
        end

        local with_ext = is_windows and (bin .. ".cmd") or bin
        if vim.fn.executable(with_ext) == 1 then
          return with_ext
        end
        if vim.fn.executable(bin) == 1 then
          return bin
        end
        return nil
      end

      local function configure_node_linter(bin)
        local ok, linter = pcall(require, "lint.linters." .. bin)
        if not ok then
          return false
        end

        linter.cmd = function()
          return resolve_node_linter_cmd(bin, vim.api.nvim_get_current_buf()) or bin
        end
        lint.linters[bin] = linter

        return resolve_node_linter_cmd(bin, vim.api.nvim_get_current_buf()) ~= nil
      end

      if vim.fn.executable("golangci-lint") == 1 then
        set_linter("go", { "golangcilint" })
      end

      local eslint = nil
      if configure_node_linter("eslint_d") then
        eslint = "eslint_d"
      elseif configure_node_linter("eslint") then
        eslint = "eslint"
      end
      if eslint then
        set_linter("javascript", { eslint })
        set_linter("javascriptreact", { eslint })
        set_linter("typescript", { eslint })
        set_linter("typescriptreact", { eslint })
      end

      if vim.fn.executable("cargo") == 1 then
        set_linter("rust", { "clippy" })
      end
      if vim.fn.executable("clang-tidy") == 1 then
        set_linter("c", { "clangtidy" })
        set_linter("cpp", { "clangtidy" })
      end

      local group = vim.api.nvim_create_augroup("Lint", { clear = true })
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter", "InsertLeave" }, {
        group = group,
        callback = function()
          debounce_lint()
        end,
      })
    end,
  }

return M
