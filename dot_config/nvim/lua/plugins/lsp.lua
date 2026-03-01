local globals = require("config.globals")

local M = {}

M["mason-org/mason.nvim"] = { "mason-org/mason.nvim", opts = {} }

M["mason-org/mason-lspconfig.nvim"] = {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim" },
    opts = {
      ensure_installed = { "gopls", "basedpyright", "ts_ls", "rust_analyzer", "clangd", "jdtls" },
      automatic_enable = false,
    },
  }

M["neovim/nvim-lspconfig"] = {
    "neovim/nvim-lspconfig",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "SmiteshP/nvim-navic",
    },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      local function resolve_python(root_dir, bufname)
        local function venv_python(venv_dir)
          if not venv_dir or venv_dir == "" then
            return nil
          end

          local unix_python = venv_dir .. "/bin/python"
          if vim.fn.executable(unix_python) == 1 then
            return unix_python
          end

          local windows_python = venv_dir .. "/Scripts/python.exe"
          if vim.fn.executable(windows_python) == 1 then
            return windows_python
          end

          return nil
        end

        local function add_candidate(candidates, seen, path)
          if type(path) ~= "string" or path == "" then
            return
          end
          local normalized = vim.fs.normalize(path)
          if not seen[normalized] then
            seen[normalized] = true
            candidates[#candidates + 1] = normalized
          end
        end

        local venv = vim.env.VIRTUAL_ENV or vim.env.CONDA_PREFIX
        if venv and venv ~= "" then
          local python = venv_python(vim.fs.normalize(venv))
          if python then
            return { python = python, venv = vim.fs.normalize(venv) }
          end
        end

        local normalized_root = type(root_dir) == "string" and root_dir ~= "" and vim.fs.normalize(root_dir) or nil
        local buf_dir = type(bufname) == "string" and bufname ~= "" and vim.fs.normalize(vim.fs.dirname(bufname)) or nil

        local candidates = {}
        local seen = {}
        add_candidate(candidates, seen, buf_dir)
        add_candidate(candidates, seen, normalized_root)
        add_candidate(candidates, seen, vim.fn.getcwd())

        for _, start in ipairs(candidates) do
          local local_venv = vim.fs.normalize(start .. "/.venv")
          local local_python = venv_python(local_venv)
          if local_python then
            return { python = local_python, venv = local_venv }
          end

        end

        if buf_dir then
          local find_opts = {
            path = buf_dir,
            upward = true,
            type = "directory",
          }
          if normalized_root and vim.startswith(buf_dir, normalized_root) then
            find_opts.stop = normalized_root
          end

          local found = vim.fs.find(".venv", find_opts)
          local venv_dir = found and found[1] or nil
          local found_python = venv_python(venv_dir)
          if found_python then
            return { python = found_python, venv = vim.fs.normalize(venv_dir) }
          end
        end

        if vim.fn.executable("python3") == 1 then
          return { python = vim.fn.exepath("python3") }
        end
        if vim.fn.executable("python") == 1 then
          return { python = vim.fn.exepath("python") }
        end

        return nil
      end

      local gopls_hint_profiles = {
        minimal = {
          assignVariableTypes = false,
          compositeLiteralFields = true,
          compositeLiteralTypes = true,
          constantValues = true,
          functionTypeParameters = true,
          parameterNames = true,
          rangeVariableTypes = false,
        },
        verbose = {
          assignVariableTypes = true,
          compositeLiteralFields = true,
          compositeLiteralTypes = true,
          constantValues = true,
          functionTypeParameters = true,
          parameterNames = true,
          rangeVariableTypes = true,
        },
      }
      local gopls_hint_profile = "minimal"

      local rust_hint_profiles = {
        minimal = {
          typeHints = { enable = false },
          parameterHints = { enable = true },
          chainingHints = { enable = true },
          closingBraceHints = { enable = true },
        },
        verbose = {
          typeHints = { enable = true },
          parameterHints = { enable = true },
          chainingHints = { enable = true },
          closingBraceHints = { enable = true },
        },
      }
      local rust_hint_profile = "minimal"

      local basedpyright_hint_profiles = {
        minimal = {
          variableTypes = false,
          callArgumentNames = true,
          callArgumentNamesMatching = false,
          functionReturnTypes = false,
          genericTypes = false,
        },
        verbose = {
          variableTypes = true,
          callArgumentNames = true,
          callArgumentNamesMatching = true,
          functionReturnTypes = true,
          genericTypes = true,
        },
      }
      local basedpyright_hint_profile = "minimal"

      local ts_hint_profiles = {
        minimal = {
          includeInlayParameterNameHints = "literals",
          includeInlayParameterNameHintsWhenArgumentMatchesName = false,
          includeInlayFunctionParameterTypeHints = false,
          includeInlayVariableTypeHints = false,
          includeInlayVariableTypeHintsWhenTypeMatchesName = false,
          includeInlayPropertyDeclarationTypeHints = false,
          includeInlayFunctionLikeReturnTypeHints = false,
          includeInlayEnumMemberValueHints = false,
        },
        verbose = {
          includeInlayParameterNameHints = "all",
          includeInlayParameterNameHintsWhenArgumentMatchesName = true,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayVariableTypeHints = true,
          includeInlayVariableTypeHintsWhenTypeMatchesName = true,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayEnumMemberValueHints = true,
        },
      }
      local ts_hint_profile = "minimal"

      local clangd_hint_profiles = {
        minimal = {
          Enabled = true,
          ParameterNames = true,
          DeducedTypes = false,
          Designators = false,
          BlockEnd = false,
        },
        verbose = {
          Enabled = true,
          ParameterNames = true,
          DeducedTypes = true,
          Designators = true,
          BlockEnd = true,
        },
      }
      local clangd_hint_profile = "minimal"

      local java_hint_profiles = {
        minimal = {
          parameterNames = { enabled = "literals" },
        },
        verbose = {
          parameterNames = { enabled = "all" },
        },
      }
      local java_hint_profile = "minimal"

      local function refresh_enabled_inlay_hints_for_client(client_name)
        if not vim.lsp.inlay_hint then
          return
        end

        vim.defer_fn(function()
          local seen = {}
          for _, lsp_client in ipairs(vim.lsp.get_clients({ name = client_name })) do
            for _, bufnr in ipairs(vim.lsp.get_buffers_by_client_id(lsp_client.id)) do
              if not seen[bufnr] and vim.api.nvim_buf_is_loaded(bufnr) then
                seen[bufnr] = true
                if vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }) then
                  vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
                end
              end
            end
          end
        end, 120)
      end

      local function apply_gopls_hint_profile(profile)
        if not gopls_hint_profiles[profile] then
          return
        end

        gopls_hint_profile = profile
        local settings = {
          gopls = {
            hints = vim.deepcopy(gopls_hint_profiles[gopls_hint_profile]),
          },
        }

        local has_clients = false
        for _, gopls_client in ipairs(vim.lsp.get_clients({ name = "gopls" })) do
          has_clients = true
          gopls_client.settings = vim.tbl_deep_extend("force", gopls_client.settings or {}, settings)
          gopls_client.notify("workspace/didChangeConfiguration", { settings = gopls_client.settings })
        end

        if has_clients then
          refresh_enabled_inlay_hints_for_client("gopls")
        end

        vim.notify("gopls hints: " .. gopls_hint_profile)
      end

      local function apply_rust_hint_profile(profile)
        if not rust_hint_profiles[profile] then
          return
        end

        rust_hint_profile = profile
        local settings = {
          ["rust-analyzer"] = {
            inlayHints = vim.deepcopy(rust_hint_profiles[rust_hint_profile]),
          },
        }

        local has_clients = false
        for _, rust_client in ipairs(vim.lsp.get_clients({ name = "rust_analyzer" })) do
          has_clients = true
          rust_client.settings = vim.tbl_deep_extend("force", rust_client.settings or {}, settings)
          rust_client.notify("workspace/didChangeConfiguration", { settings = rust_client.settings })
        end

        if has_clients then
          refresh_enabled_inlay_hints_for_client("rust_analyzer")
        end

        vim.notify("rust-analyzer hints: " .. rust_hint_profile)
      end

      local function apply_basedpyright_hint_profile(profile)
        if not basedpyright_hint_profiles[profile] then
          return
        end

        basedpyright_hint_profile = profile
        local settings = {
          basedpyright = {
            analysis = {
              inlayHints = vim.deepcopy(basedpyright_hint_profiles[basedpyright_hint_profile]),
            },
          },
        }

        local has_clients = false
        for _, python_client in ipairs(vim.lsp.get_clients({ name = "basedpyright" })) do
          has_clients = true
          python_client.settings = vim.tbl_deep_extend("force", python_client.settings or {}, settings)
          python_client.notify("workspace/didChangeConfiguration", { settings = python_client.settings })
        end

        if has_clients then
          refresh_enabled_inlay_hints_for_client("basedpyright")
        end

        vim.notify("basedpyright hints: " .. basedpyright_hint_profile)
      end

      local function apply_ts_hint_profile(profile)
        if not ts_hint_profiles[profile] then
          return
        end

        ts_hint_profile = profile
        local settings = {
          typescript = {
            inlayHints = vim.deepcopy(ts_hint_profiles[ts_hint_profile]),
          },
          javascript = {
            inlayHints = vim.deepcopy(ts_hint_profiles[ts_hint_profile]),
          },
        }

        local has_clients = false
        for _, ts_client in ipairs(vim.lsp.get_clients({ name = "ts_ls" })) do
          has_clients = true
          ts_client.settings = vim.tbl_deep_extend("force", ts_client.settings or {}, settings)
          ts_client.notify("workspace/didChangeConfiguration", { settings = ts_client.settings })
        end

        if has_clients then
          refresh_enabled_inlay_hints_for_client("ts_ls")
        end

        vim.notify("ts_ls hints: " .. ts_hint_profile)
      end

      local function apply_clangd_hint_profile(profile)
        if not clangd_hint_profiles[profile] then
          return
        end

        clangd_hint_profile = profile
        local settings = {
          clangd = {
            InlayHints = vim.deepcopy(clangd_hint_profiles[clangd_hint_profile]),
          },
        }

        local has_clients = false
        for _, c_client in ipairs(vim.lsp.get_clients({ name = "clangd" })) do
          has_clients = true
          c_client.settings = vim.tbl_deep_extend("force", c_client.settings or {}, settings)
          c_client.notify("workspace/didChangeConfiguration", { settings = c_client.settings })
        end

        if has_clients then
          refresh_enabled_inlay_hints_for_client("clangd")
        end

        vim.notify("clangd hints: " .. clangd_hint_profile)
      end

      local function apply_java_hint_profile(profile)
        if not java_hint_profiles[profile] then
          return
        end

        java_hint_profile = profile
        local settings = {
          java = {
            inlayHints = vim.deepcopy(java_hint_profiles[java_hint_profile]),
          },
        }

        local has_clients = false
        for _, java_client in ipairs(vim.lsp.get_clients({ name = "jdtls" })) do
          has_clients = true
          java_client.settings = vim.tbl_deep_extend("force", java_client.settings or {}, settings)
          java_client.notify("workspace/didChangeConfiguration", { settings = java_client.settings })
        end

        if has_clients then
          refresh_enabled_inlay_hints_for_client("jdtls")
        end

        vim.notify("jdtls hints: " .. java_hint_profile)
      end

      vim.api.nvim_create_user_command("GoHints", function(opts)
        local arg = vim.trim(opts.args or "")
        if arg == "" or arg == "toggle" then
          local next_profile = gopls_hint_profile == "minimal" and "verbose" or "minimal"
          apply_gopls_hint_profile(next_profile)
          return
        end

        if gopls_hint_profiles[arg] then
          apply_gopls_hint_profile(arg)
          return
        end

        vim.notify("Usage: :GoHints [minimal|verbose|toggle]", vim.log.levels.ERROR)
      end, {
        nargs = "?",
        complete = function(arg_lead)
          local items = { "minimal", "verbose", "toggle" }
          return vim.tbl_filter(function(item)
            return item:find("^" .. vim.pesc(arg_lead)) ~= nil
          end, items)
        end,
        desc = "Set gopls inlay hint profile",
      })

      vim.api.nvim_create_user_command("RustHints", function(opts)
        local arg = vim.trim(opts.args or "")
        if arg == "" or arg == "toggle" then
          local next_profile = rust_hint_profile == "minimal" and "verbose" or "minimal"
          apply_rust_hint_profile(next_profile)
          return
        end

        if rust_hint_profiles[arg] then
          apply_rust_hint_profile(arg)
          return
        end

        vim.notify("Usage: :RustHints [minimal|verbose|toggle]", vim.log.levels.ERROR)
      end, {
        nargs = "?",
        complete = function(arg_lead)
          local items = { "minimal", "verbose", "toggle" }
          return vim.tbl_filter(function(item)
            return item:find("^" .. vim.pesc(arg_lead)) ~= nil
          end, items)
        end,
        desc = "Set rust-analyzer inlay hint profile",
      })

      vim.api.nvim_create_user_command("PyHints", function(opts)
        local arg = vim.trim(opts.args or "")
        if arg == "" or arg == "toggle" then
          local next_profile = basedpyright_hint_profile == "minimal" and "verbose" or "minimal"
          apply_basedpyright_hint_profile(next_profile)
          return
        end

        if basedpyright_hint_profiles[arg] then
          apply_basedpyright_hint_profile(arg)
          return
        end

        vim.notify("Usage: :PyHints [minimal|verbose|toggle]", vim.log.levels.ERROR)
      end, {
        nargs = "?",
        complete = function(arg_lead)
          local items = { "minimal", "verbose", "toggle" }
          return vim.tbl_filter(function(item)
            return item:find("^" .. vim.pesc(arg_lead)) ~= nil
          end, items)
        end,
        desc = "Set basedpyright inlay hint profile",
      })

      vim.api.nvim_create_user_command("TsHints", function(opts)
        local arg = vim.trim(opts.args or "")
        if arg == "" or arg == "toggle" then
          local next_profile = ts_hint_profile == "minimal" and "verbose" or "minimal"
          apply_ts_hint_profile(next_profile)
          return
        end

        if ts_hint_profiles[arg] then
          apply_ts_hint_profile(arg)
          return
        end

        vim.notify("Usage: :TsHints [minimal|verbose|toggle]", vim.log.levels.ERROR)
      end, {
        nargs = "?",
        complete = function(arg_lead)
          local items = { "minimal", "verbose", "toggle" }
          return vim.tbl_filter(function(item)
            return item:find("^" .. vim.pesc(arg_lead)) ~= nil
          end, items)
        end,
        desc = "Set ts_ls inlay hint profile",
      })

      vim.api.nvim_create_user_command("CHints", function(opts)
        local arg = vim.trim(opts.args or "")
        if arg == "" or arg == "toggle" then
          local next_profile = clangd_hint_profile == "minimal" and "verbose" or "minimal"
          apply_clangd_hint_profile(next_profile)
          return
        end

        if clangd_hint_profiles[arg] then
          apply_clangd_hint_profile(arg)
          return
        end

        vim.notify("Usage: :CHints [minimal|verbose|toggle]", vim.log.levels.ERROR)
      end, {
        nargs = "?",
        complete = function(arg_lead)
          local items = { "minimal", "verbose", "toggle" }
          return vim.tbl_filter(function(item)
            return item:find("^" .. vim.pesc(arg_lead)) ~= nil
          end, items)
        end,
        desc = "Set clangd inlay hint profile",
      })

      vim.api.nvim_create_user_command("JavaHints", function(opts)
        local arg = vim.trim(opts.args or "")
        if arg == "" or arg == "toggle" then
          local next_profile = java_hint_profile == "minimal" and "verbose" or "minimal"
          apply_java_hint_profile(next_profile)
          return
        end

        if java_hint_profiles[arg] then
          apply_java_hint_profile(arg)
          return
        end

        vim.notify("Usage: :JavaHints [minimal|verbose|toggle]", vim.log.levels.ERROR)
      end, {
        nargs = "?",
        complete = function(arg_lead)
          local items = { "minimal", "verbose", "toggle" }
          return vim.tbl_filter(function(item)
            return item:find("^" .. vim.pesc(arg_lead)) ~= nil
          end, items)
        end,
        desc = "Set jdtls inlay hint profile",
      })

      local function on_attach(client, bufnr)
        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
        end
        map("n", "gd", vim.lsp.buf.definition, "Go to definition")
        map("n", "grr", vim.lsp.buf.references, "List references")
        map("n", "grn", vim.lsp.buf.rename, "Rename symbol")
        map("n", "K", vim.lsp.buf.hover, "Hover docs")

        local inlay_hint = vim.lsp.inlay_hint
        if inlay_hint and client.server_capabilities.inlayHintProvider then
          inlay_hint.enable(true, { bufnr = bufnr })
          map("n", "<leader>uh", function()
            local enabled = inlay_hint.is_enabled({ bufnr = bufnr })
            inlay_hint.enable(not enabled, { bufnr = bufnr })
          end, "Toggle inlay hints")
        end

        if client.name == "gopls" then
          map("n", "<leader>uH", function()
            local next_profile = gopls_hint_profile == "minimal" and "verbose" or "minimal"
            apply_gopls_hint_profile(next_profile)
          end, "Toggle gopls hint profile")
        end

        if client.name == "rust_analyzer" then
          map("n", "<leader>uH", function()
            local next_profile = rust_hint_profile == "minimal" and "verbose" or "minimal"
            apply_rust_hint_profile(next_profile)
          end, "Toggle rust-analyzer hint profile")
        end

        if client.name == "basedpyright" then
          map("n", "<leader>uH", function()
            local next_profile = basedpyright_hint_profile == "minimal" and "verbose" or "minimal"
            apply_basedpyright_hint_profile(next_profile)
          end, "Toggle basedpyright hint profile")
        end

        if client.name == "ts_ls" then
          map("n", "<leader>uH", function()
            local next_profile = ts_hint_profile == "minimal" and "verbose" or "minimal"
            apply_ts_hint_profile(next_profile)
          end, "Toggle ts_ls hint profile")
        end

        if client.name == "clangd" then
          map("n", "<leader>uH", function()
            local next_profile = clangd_hint_profile == "minimal" and "verbose" or "minimal"
            apply_clangd_hint_profile(next_profile)
          end, "Toggle clangd hint profile")
        end

        if client.name == "jdtls" then
          map("n", "<leader>uH", function()
            local next_profile = java_hint_profile == "minimal" and "verbose" or "minimal"
            apply_java_hint_profile(next_profile)
          end, "Toggle jdtls hint profile")
        end

        if client.server_capabilities.documentSymbolProvider then
          require("nvim-navic").attach(client, bufnr)
        end
      end

      local function stop_pyright_for_buffer(bufnr)
        for _, pyright_client in ipairs(vim.lsp.get_clients({ bufnr = bufnr, name = "pyright" })) do
          vim.lsp.buf_detach_client(bufnr, pyright_client.id)
          if #vim.lsp.get_buffers_by_client_id(pyright_client.id) == 0 then
            pyright_client:stop()
          end
        end
      end

      vim.lsp.config("gopls", {
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
          gopls = {
            hints = vim.deepcopy(gopls_hint_profiles[gopls_hint_profile]),
          },
        },
      })
      vim.lsp.config("basedpyright", {
        capabilities = capabilities,
        on_attach = function(client, bufnr)
          stop_pyright_for_buffer(bufnr)
          on_attach(client, bufnr)
        end,
        settings = {
          basedpyright = {
            analysis = {
              autoSearchPaths = true,
              inlayHints = vim.deepcopy(basedpyright_hint_profiles[basedpyright_hint_profile]),
            },
          },
        },
        -- Use the project interpreter even when Neovim starts without an activated venv.
        before_init = function(params, config)
          local root_dir = nil
          local root_uri = params and params.rootUri or nil
          local root_path = params and params.rootPath or nil

          if type(root_uri) == "string" and root_uri ~= "" then
            root_dir = vim.uri_to_fname(root_uri)
          elseif type(root_path) == "string" and root_path ~= "" then
            root_dir = root_path
          end

          local resolved = resolve_python(root_dir, vim.api.nvim_buf_get_name(0))
          if resolved and resolved.python then
            config.settings = config.settings or {}
            config.settings.python = config.settings.python or {}
            config.settings.python.pythonPath = resolved.python
            if resolved.venv then
              config.settings.python.venvPath = vim.fs.dirname(resolved.venv)
              config.settings.python.venv = vim.fs.basename(resolved.venv)
            end
          end
        end,
      })
      vim.lsp.config("pyright", {
        autostart = false,
        enabled = false,
      })
      vim.lsp.config("ts_ls", {
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
          typescript = {
            inlayHints = vim.deepcopy(ts_hint_profiles[ts_hint_profile]),
          },
          javascript = {
            inlayHints = vim.deepcopy(ts_hint_profiles[ts_hint_profile]),
          },
        },
      })
      vim.lsp.config("rust_analyzer", {
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
          ["rust-analyzer"] = {
            inlayHints = vim.deepcopy(rust_hint_profiles[rust_hint_profile]),
          },
        },
      })
      vim.lsp.config("clangd", {
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
          clangd = {
            InlayHints = vim.deepcopy(clangd_hint_profiles[clangd_hint_profile]),
          },
        },
      })
      vim.lsp.config("jdtls", {
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
          java = {
            inlayHints = vim.deepcopy(java_hint_profiles[java_hint_profile]),
          },
        },
      })
      vim.lsp.enable({ "gopls", "basedpyright", "ts_ls", "rust_analyzer", "clangd", "jdtls" })
    end,
  }

M["hrsh7th/nvim-cmp"] = {
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        enabled = function()
          return vim.g.cmp_autocomplete_enabled ~= false
        end,
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        preselect = cmp.PreselectMode.None,
        completion = {
          completeopt = "menu,menuone,noselect",
        },
        window = {
          documentation = vim.g.cmp_docs_window_enabled == false
              and cmp.config.disable
            or globals.get_cmp_docs_window_config(cmp),
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-y>"] = cmp.mapping(function(fallback)
            local ok_sidekick, sidekick = pcall(require, "sidekick")
            if ok_sidekick and sidekick.nes_jump_or_apply and sidekick.nes_jump_or_apply() then
              return
            end

            local ok_copilot, copilot = pcall(require, "copilot.suggestion")
            if ok_copilot and copilot.is_visible() then
              copilot.accept()
              return
            end

            if cmp.visible() then
              cmp.confirm({ select = true })
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<C-n>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<C-p>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<CR>"] = cmp.mapping(function(fallback)
            if cmp.visible() and cmp.get_selected_entry() then
              cmp.confirm({ select = false })
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }, {
          { name = "buffer" },
        }),
      })

      cmp.setup.cmdline("/", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "buffer" },
        },
      })

      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
        }, {
          { name = "cmdline" },
        }),
      })

      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end,
  }

M["folke/trouble.nvim"] = {
    "folke/trouble.nvim",
    cmd = "Trouble",
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", desc = "Trouble diagnostics (workspace)" },
      { "<leader>xb", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Trouble diagnostics (buffer)" },
      { "<leader>xq", "<cmd>Trouble qflist toggle<CR>", desc = "Trouble quickfix" },
      { "<leader>xl", "<cmd>Trouble loclist toggle<CR>", desc = "Trouble location list" },
      { "<leader>xs", "<cmd>Trouble symbols toggle focus=false<CR>", desc = "Trouble symbols" },
      { "<leader>xr", "<cmd>Trouble lsp_references toggle focus=false<CR>", desc = "Trouble references" },
      { "gR", "<cmd>Trouble lsp_references toggle focus=false<CR>", desc = "LSP references (Trouble)" },
    },
    opts = {
      focus = true,
      win = {
        type = "split",
        position = "right",
        size = 0.32,
      },
    },
    config = function(_, opts)
      require("trouble").setup(opts)

      vim.api.nvim_create_user_command("TroubleWorkspace", function(cmd_opts)
        local where = vim.trim(cmd_opts.args or "")
        local open_cmd = where ~= "" and ("Trouble diagnostics toggle win.position=" .. where)
          or "Trouble diagnostics toggle"
        vim.cmd(open_cmd)
      end, {
        nargs = "?",
        complete = function(arg_lead)
          local items = { "left", "right", "top", "bottom" }
          return vim.tbl_filter(function(item)
            return item:find("^" .. vim.pesc(arg_lead)) ~= nil
          end, items)
        end,
        desc = "Toggle Trouble workspace diagnostics (left/right/top/bottom)",
      })

      vim.api.nvim_create_user_command("TroubleBuffer", function(cmd_opts)
        local where = vim.trim(cmd_opts.args or "")
        local open_cmd = where ~= "" and ("Trouble diagnostics toggle filter.buf=0 win.position=" .. where)
          or "Trouble diagnostics toggle filter.buf=0"
        vim.cmd(open_cmd)
      end, {
        nargs = "?",
        complete = function(arg_lead)
          local items = { "left", "right", "top", "bottom" }
          return vim.tbl_filter(function(item)
            return item:find("^" .. vim.pesc(arg_lead)) ~= nil
          end, items)
        end,
        desc = "Toggle Trouble buffer diagnostics (left/right/top/bottom)",
      })

      vim.api.nvim_create_user_command("TroubleQf", function(cmd_opts)
        local where = vim.trim(cmd_opts.args or "")
        local open_cmd = where ~= "" and ("Trouble qflist toggle win.position=" .. where)
          or "Trouble qflist toggle"
        vim.cmd(open_cmd)
      end, {
        nargs = "?",
        complete = function(arg_lead)
          local items = { "left", "right", "top", "bottom" }
          return vim.tbl_filter(function(item)
            return item:find("^" .. vim.pesc(arg_lead)) ~= nil
          end, items)
        end,
        desc = "Toggle Trouble quickfix list (left/right/top/bottom)",
      })

      vim.api.nvim_create_user_command("TroubleLoc", function(cmd_opts)
        local where = vim.trim(cmd_opts.args or "")
        local open_cmd = where ~= "" and ("Trouble loclist toggle win.position=" .. where)
          or "Trouble loclist toggle"
        vim.cmd(open_cmd)
      end, {
        nargs = "?",
        complete = function(arg_lead)
          local items = { "left", "right", "top", "bottom" }
          return vim.tbl_filter(function(item)
            return item:find("^" .. vim.pesc(arg_lead)) ~= nil
          end, items)
        end,
        desc = "Toggle Trouble location list (left/right/top/bottom)",
      })

      vim.api.nvim_create_user_command("TroubleRefs", function(cmd_opts)
        local where = vim.trim(cmd_opts.args or "")
        local open_cmd = where ~= "" and ("Trouble lsp_references toggle focus=false win.position=" .. where)
          or "Trouble lsp_references toggle focus=false"
        vim.cmd(open_cmd)
      end, {
        nargs = "?",
        complete = function(arg_lead)
          local items = { "left", "right", "top", "bottom" }
          return vim.tbl_filter(function(item)
            return item:find("^" .. vim.pesc(arg_lead)) ~= nil
          end, items)
        end,
        desc = "Toggle Trouble references (left/right/top/bottom)",
      })

      vim.api.nvim_create_user_command("TroubleSymbols", function(cmd_opts)
        local where = vim.trim(cmd_opts.args or "")
        local open_cmd = where ~= "" and ("Trouble symbols toggle focus=false win.position=" .. where)
          or "Trouble symbols toggle focus=false"
        vim.cmd(open_cmd)
      end, {
        nargs = "?",
        complete = function(arg_lead)
          local items = { "left", "right", "top", "bottom" }
          return vim.tbl_filter(function(item)
            return item:find("^" .. vim.pesc(arg_lead)) ~= nil
          end, items)
        end,
        desc = "Toggle Trouble symbols (left/right/top/bottom)",
      })
    end,
  }

return M
