local M = {}

M["mfussenegger/nvim-dap"] = {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "theHamsta/nvim-dap-virtual-text",
      "jay-babu/mason-nvim-dap.nvim",
      "mason-org/mason.nvim",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      dapui.setup({})
      require("nvim-dap-virtual-text").setup({})

      local mason_path = vim.fn.stdpath("data") .. "/mason"
      local function mason_bin(bin)
        local path = mason_path .. "/bin/" .. bin
        if vim.fn.executable(path) == 1 then
          return path
        end
        return bin
      end

      local function get_free_port()
        local tcp = vim.loop.new_tcp()
        if not tcp then
          return 38697
        end

        local ok = pcall(tcp.bind, tcp, "127.0.0.1", 0)
        if not ok then
          tcp:close()
          return 38697
        end

        local sockname = tcp:getsockname()
        tcp:close()
        if sockname and sockname.port then
          return sockname.port
        end
        return 38697
      end

      require("mason-nvim-dap").setup({
        ensure_installed = { "delve", "debugpy", "codelldb", "js-debug-adapter" },
        automatic_setup = true,
      })

      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end

      dap.adapters.go = function(callback, _)
        local handle
        local pid_or_err
        local port = get_free_port()
        handle, pid_or_err = vim.loop.spawn(mason_bin("dlv"), {
          args = { "dap", "-l", "127.0.0.1:" .. port },
          detached = true,
        }, function()
          if handle then
            handle:close()
          end
        end)
        assert(handle, "Error running dlv: " .. tostring(pid_or_err))
        vim.defer_fn(function()
          callback({ type = "server", host = "127.0.0.1", port = port })
        end, 100)
      end

      dap.adapters.python = {
        type = "executable",
        command = (function()
          local debugpy_paths = {
            mason_path .. "/packages/debugpy/venv/bin/python",
            mason_path .. "/packages/debugpy/venv/Scripts/python.exe",
          }
          for _, path in ipairs(debugpy_paths) do
            if vim.fn.executable(path) == 1 then
              return path
            end
          end
          return debugpy_paths[1]
        end)(),
        args = { "-m", "debugpy.adapter" },
      }

      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = mason_path .. "/packages/codelldb/extension/adapter/codelldb",
          args = { "--port", "${port}" },
        },
      }

      dap.adapters["pwa-node"] = {
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = {
          command = "node",
          args = {
            mason_path .. "/packages/js-debug-adapter/js-debug/src/dapDebugServer.js",
            "${port}",
          },
        },
      }

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

      dap.configurations.go = {
        {
          type = "go",
          name = "Debug file",
          request = "launch",
          program = "${file}",
        },
        {
          type = "go",
          name = "Debug package",
          request = "launch",
          program = "${fileDirname}",
        },
      }

      dap.configurations.python = {
        {
          type = "python",
          name = "Launch file",
          request = "launch",
          program = "${file}",
          pythonPath = resolve_python,
        },
      }

      local codelldb_launch = {
        type = "codelldb",
        name = "Launch file",
        request = "launch",
        program = function()
          return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
      }

      dap.configurations.c = { codelldb_launch }
      dap.configurations.cpp = { codelldb_launch }
      dap.configurations.rust = { codelldb_launch }

      local node_launch = {
        type = "pwa-node",
        request = "launch",
        name = "Launch file",
        program = "${file}",
        cwd = "${workspaceFolder}",
        sourceMaps = true,
        protocol = "inspector",
        console = "integratedTerminal",
      }

      dap.configurations.javascript = { node_launch }
      dap.configurations.javascriptreact = { node_launch }
      dap.configurations.typescript = { node_launch }
      dap.configurations.typescriptreact = { node_launch }

      vim.keymap.set("n", "<F5>", dap.continue, { silent = true, desc = "DAP continue" })
      vim.keymap.set("n", "<F9>", dap.toggle_breakpoint, { silent = true, desc = "DAP breakpoint" })
      vim.keymap.set("n", "<F10>", dap.step_over, { silent = true, desc = "DAP step over" })
      vim.keymap.set("n", "<F11>", dap.step_into, { silent = true, desc = "DAP step into" })
      vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { silent = true, desc = "Toggle breakpoint" })
      vim.keymap.set("n", "<leader>dB", function()
        dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
      end, { silent = true, desc = "Conditional breakpoint" })
      vim.keymap.set("n", "<leader>dr", dap.repl.open, { silent = true, desc = "DAP REPL" })
      vim.keymap.set("n", "<leader>dl", dap.run_last, { silent = true, desc = "DAP run last" })
      vim.keymap.set("n", "<leader>du", dapui.toggle, { silent = true, desc = "DAP UI toggle" })
    end,
  }

return M
