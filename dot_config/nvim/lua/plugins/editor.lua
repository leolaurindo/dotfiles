local M = {}

M["windwp/nvim-autopairs"] = {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({})
    end,
  }

M["numToStr/Comment.nvim"] = {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup()
    end,
  }

M["folke/flash.nvim"] = {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      modes = {
        char = {
          enabled = false,
        },
      },
    },
    keys = {
      {
        "s",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump()
        end,
        desc = "Flash",
      },
      {
        "S",
        mode = { "n", "x", "o" },
        function()
          require("flash").treesitter()
        end,
        desc = "Flash Treesitter",
      },
      {
        "r",
        mode = "o",
        function()
          require("flash").remote()
        end,
        desc = "Remote Flash",
      },
      {
        "R",
        mode = { "o", "x" },
        function()
          require("flash").treesitter_search()
        end,
        desc = "Treesitter Search",
      },
      {
        "<c-s>",
        mode = { "c" },
        function()
          require("flash").toggle()
        end,
        desc = "Toggle Flash Search",
      },
    },
  }

M["nvim-mini/mini.splitjoin"] = {
    "nvim-mini/mini.splitjoin",
    version = false,
    config = function()
      require("mini.splitjoin").setup({
        mappings = {
          toggle = "gS",
        },
      })
    end,
  }

M["nvim-mini/mini.jump"] = {
    "nvim-mini/mini.jump",
    version = false,
    config = function()
      require("mini.jump").setup({
        mappings = {
          forward = "f",
          backward = "F",
          forward_till = "t",
          backward_till = "T",
          repeat_jump = ";",
        },
        delay = {
          highlight = 0,
        },
      })
    end,
  }

M["nvim-mini/mini.surround"] = {
    "nvim-mini/mini.surround",
    version = false,
    config = function()
      require("mini.surround").setup({
        mappings = {
          add = "<leader>sa",
          delete = "<leader>sd",
          find = "<leader>sf",
          find_left = "<leader>sF",
          highlight = "<leader>sh",
          replace = "<leader>sr",
          suffix_last = "l",
          suffix_next = "n",
        },
      })
    end,
  }

M["nvim-mini/mini.move"] = {
    "nvim-mini/mini.move",
    version = false,
    config = function()
      require("mini.move").setup()
    end,
  }

M["folke/todo-comments.nvim"] = {
    "folke/todo-comments.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      signs = false,
    },
    config = function(_, opts)
      local todo = require("todo-comments")
      todo.setup(opts)
      -- Keep todo-comments as an on-demand list/jump tool only.
      todo.disable()
    end,
    keys = {
      { "<leader>xt", "<cmd>TodoTrouble<CR>", desc = "Todo list (Trouble)" },
      { "<leader>xT", "<cmd>TodoQuickFix<CR>", desc = "Todo list (quickfix)" },
      {
        "<leader>fT",
        function()
          require("snacks.picker").todo_comments({
            cwd = vim.uv.cwd(),
            focus = "list",
          })
        end,
        desc = "Todos (Snacks)",
      },
    },
  }

M["folke/snacks.nvim"] = {
    "folke/snacks.nvim",
    lazy = false,
    opts = {
      picker = { enabled = true },
      -- Disable netrw replacement so startup stays on Alpha dashboard (capybara).
      -- Snacks explorer remains available via explicit mappings like <leader>fe.
      explorer = {
        enabled = true,
        replace_netrw = false,
      },
      terminal = { enabled = true },
      quickfile = { enabled = true },
    },
    config = function(_, opts)
      local snacks = require("snacks")
      local has_rg = vim.fn.executable("rg") == 1
      local has_fd = vim.fn.executable("fd") == 1
      local has_find = vim.fn.executable("find") == 1

      local file_cmd = has_rg and "rg" or (has_fd and "fd" or (has_find and "find" or "rg"))
      local grep_cmd = has_rg and "rg" or nil

      if not has_rg and not has_fd and not has_find then
        vim.schedule(function()
          vim.notify(
            "Snacks picker: no finder binary found (rg/fd/find). Install ripgrep (rg) for Windows/WSL compatibility.",
            vim.log.levels.WARN
          )
        end)
      elseif not has_rg then
        vim.schedule(function()
          vim.notify(
            "Snacks grep features work best with ripgrep (rg). Consider installing rg on both Windows and WSL.",
            vim.log.levels.INFO
          )
        end)
      end

      opts.picker = opts.picker or {}
      opts.picker.sources = opts.picker.sources or {}

      local function resize_picker_preview(picker, delta)
        if not picker then
          return
        end

        local layout = vim.deepcopy(picker.resolved_layout or {})
        local root = layout.layout
        if type(root) ~= "table" then
          return
        end

        local function find_preview(node, parent)
          if type(node) ~= "table" then
            return nil, nil
          end
          if node.win == "preview" then
            return node, parent
          end
          for _, child in ipairs(node) do
            local preview, preview_parent = find_preview(child, node)
            if preview then
              return preview, preview_parent
            end
          end
          return nil, nil
        end

        local preview, parent = find_preview(root, nil)
        if not preview then
          vim.notify("Snacks picker: current layout has no preview window", vim.log.levels.INFO)
          return
        end

        local dim
        if preview.width ~= nil then
          dim = "width"
        elseif preview.height ~= nil then
          dim = "height"
        elseif parent and parent.box == "horizontal" then
          dim = "width"
        else
          dim = "height"
        end

        local current = preview[dim]
        if current == nil then
          current = dim == "width" and 0.5 or 0.4
        end

        if type(current) == "number" and current > 0 and current <= 1 then
          local min_ratio, max_ratio = 0.2, 0.85
          preview[dim] = math.min(max_ratio, math.max(min_ratio, current + (0.05 * delta)))
        elseif type(current) == "number" then
          local screen = dim == "width" and vim.o.columns or vim.o.lines
          local min_abs = dim == "width" and 20 or 8
          local max_abs = math.max(min_abs, screen - (dim == "width" and 20 or 6))
          preview[dim] = math.min(max_abs, math.max(min_abs, current + (3 * delta)))
        else
          return
        end

        picker:set_layout(layout)
      end

      local function grow_preview(picker)
        resize_picker_preview(picker, 1)
      end

      local function shrink_preview(picker)
        resize_picker_preview(picker, -1)
      end

      opts.picker.win = vim.tbl_deep_extend("force", opts.picker.win or {}, {
        input = {
          keys = {
            ["<C-=>"] = { grow_preview, mode = { "n", "i" } },
            ["<C-+>"] = { grow_preview, mode = { "n", "i" } },
            ["<C-->"] = { shrink_preview, mode = { "n", "i" } },
          },
        },
        list = {
          keys = {
            ["<C-=>"] = grow_preview,
            ["<C-+>"] = grow_preview,
            ["<C-->"] = shrink_preview,
          },
        },
        preview = {
          keys = {
            ["<C-=>"] = grow_preview,
            ["<C-+>"] = grow_preview,
            ["<C-->"] = shrink_preview,
          },
        },
      })

      opts.picker.sources.files = vim.tbl_deep_extend("force", opts.picker.sources.files or {}, {
        cmd = file_cmd,
        hidden = false,
        ignored = false,
        win = {
          input = {
            keys = {
              ["<A-h>"] = { "toggle_hidden", mode = { "n", "i" } },
              ["<A-i>"] = { "toggle_ignored", mode = { "n", "i" } },
            },
          },
          list = {
            keys = {
              ["H"] = "toggle_hidden",
              ["I"] = "toggle_ignored",
            },
          },
        },
      })
      opts.picker.sources.grep = vim.tbl_deep_extend("force", opts.picker.sources.grep or {}, {
        cmd = grep_cmd,
      })
      opts.picker.sources.explorer = vim.tbl_deep_extend("force", opts.picker.sources.explorer or {}, {
        cmd = file_cmd,
        hidden = false,
        ignored = false,
        win = {
          list = {
            keys = {
              ["H"] = "toggle_hidden",
              ["I"] = "toggle_ignored",
            },
          },
        },
      })
      opts.picker.sources.commands = vim.tbl_deep_extend("force", opts.picker.sources.commands or {}, {
        layout = { preset = "vscode" },
        preview = false,
        matcher = {
          frecency = true,
          sort_empty = true,
        },
      })
      opts.picker.layouts = opts.picker.layouts or {}
      opts.picker.layouts.git_log_fullscreen = {
        fullscreen = true,
        layout = {
          backdrop = false,
          min_width = 80,
          min_height = 30,
          box = "vertical",
          border = true,
          title = "{title} {live} {flags}",
          title_pos = "center",
          { win = "input", height = 1, border = "bottom" },
          {
            box = "horizontal",
            { win = "list", width = 0.5, border = "none" },
            { win = "preview", title = "{preview}", width = 0.5, border = "left" },
          },
        },
      }
      snacks.setup(opts)

      local picker = snacks.picker

      vim.api.nvim_create_user_command("Notifications", function()
        snacks.picker.notifications()
      end, { desc = "Open Snacks notifications picker" })

      local function buf_dir()
        return vim.fn.expand("%:p:h")
      end

      local function grep_opts(extra)
        local opts = {
          hidden = true,
          glob = { "!.git/*", "!**/.tmux*", "!**/tmux-*" },
        }
        if extra then
          for key, value in pairs(extra) do
            opts[key] = value
          end
        end
        return opts
      end

      local function current_git_branch()
        if #vim.fs.find(".git", { path = vim.uv.cwd(), upward = true, type = "directory", limit = 1 }) == 0 then
          return nil
        end
        local out = vim.trim(vim.fn.systemlist("git branch --show-current")[1] or "")
        if vim.v.shell_error ~= 0 or out == "" then
          return nil
        end
        return out
      end

      local function latest_workspace_scratch()
        local cwd = vim.fs.normalize(assert(vim.uv.cwd()))
        local branch = current_git_branch()
        local latest_cwd = nil

        for _, item in ipairs(snacks.scratch.list()) do
          if item.cwd == cwd then
            if branch and item.branch == branch then
              return item
            end
            if not latest_cwd then
              latest_cwd = item
            end
          end
        end

        return latest_cwd
      end

      vim.keymap.set("n", "<C-p>", function()
        picker.commands()
      end, { silent = true })
      vim.keymap.set("n", "<leader>ff", function()
        picker.files()
      end, { silent = true, desc = "Find files" })
      vim.keymap.set("n", "<leader>..", function()
        local latest = latest_workspace_scratch()
        if latest then
          snacks.scratch.open({
            icon = latest.icon,
            file = latest.file,
            name = latest.name,
            ft = latest.ft,
          })
          return
        end
        snacks.scratch.open({
          filekey = {
            cwd = true,
            branch = true,
            count = false,
          },
        })
      end, { silent = true, desc = "Scratch latest (workspace)" })
      vim.keymap.set("n", "<leader>.;", function()
        snacks.picker.scratch({
          focus = "list",
          win = {
            list = {
              keys = {
                ["<C-x>"] = "scratch_delete",
              },
            },
          },
        })
      end, { silent = true, desc = "Scratch list" })
      vim.keymap.set("n", "<leader>.n", function()
        snacks.scratch.open({
          filekey = {
            id = tostring(vim.uv.hrtime()),
            cwd = true,
            branch = true,
            count = false,
          },
        })
      end, { silent = true, desc = "Scratch new" })
      vim.keymap.set("n", "<leader>/", function()
        picker.lines({
          preview = false,
          layout = {
            preset = "select",
            layout = {
              width = 0.6,
              min_width = 70,
              max_width = 110,
              height = 0.35,
            },
          },
        })
      end, { silent = true, desc = "Search current buffer lines" })
      vim.keymap.set("n", "<leader>fb", function()
        picker.buffers({
          focus = "list",
        })
      end, { silent = true, desc = "Buffers" })
      vim.keymap.set("n", "<leader>fm", function()
        picker.marks({
          focus = "list",
        })
      end, { silent = true, desc = "Marks" })
      vim.keymap.set("n", "<leader>fq", function()
        picker.qflist({
          focus = "list",
        })
      end, { silent = true, desc = "Quickfix list" })
      vim.keymap.set("n", "<leader>fl", function()
        picker.loclist({
          focus = "list",
        })
      end, { silent = true, desc = "Location list" })
      vim.keymap.set("n", "<leader>fr", function()
        picker.lsp_references({
          focus = "list",
          auto_confirm = false,
          include_declaration = true,
          win = {
            list = {
              keys = {
                ["i"] = { "focus_input", mode = { "n", "x" } },
                ["a"] = { "focus_input", mode = { "n", "x" } },
              },
            },
          },
        })
      end, { silent = true, desc = "References" })
      vim.keymap.set("n", "<leader>fR", function()
        picker.registers({
          focus = "list",
        })
      end, { silent = true, desc = "Registers" })
      vim.keymap.set("n", "<leader>fj", function()
        picker.jumps({
          focus = "list",
        })
      end, { silent = true, desc = "Jumps" })
      vim.keymap.set("n", "<leader>fc", function()
        picker.command_history({
          focus = "list",
        })
      end, { silent = true, desc = "Command history" })
      vim.keymap.set("n", "<leader>f/", function()
        picker.search_history({
          focus = "list",
        })
      end, { silent = true, desc = "Search history" })
      vim.keymap.set("n", "<leader>fd", function()
        picker.diagnostics({
          focus = "list",
        })
      end, { silent = true, desc = "Diagnostics (buffer)" })
      vim.keymap.set("n", "<leader>fD", function()
        picker.diagnostics({
          workspace = true,
          focus = "list",
        })
      end, { silent = true, desc = "Diagnostics (workspace)" })
      local function close_explorer_pickers()
        local open = picker.get({ source = "explorer" }) or {}
        local closed = false
        for _, p in ipairs(open) do
          if p and p.close then
            p:close()
            closed = true
          end
        end
        return closed
      end

      vim.keymap.set("n", "<leader>fe", function()
        close_explorer_pickers()
        snacks.explorer({
          focus = "list",
          auto_close = true,
          jump = { close = true },
          layout = {
            preset = "default",
            preview = true,
          },
          win = {
            input = { keys = { ["<Esc>"] = "cancel" } },
            list = {
              keys = {
                ["<Esc>"] = "cancel",
                ["H"] = "toggle_hidden",
                ["I"] = "toggle_ignored",
              },
            },
            preview = { keys = { ["<Esc>"] = "cancel" } },
          },
        })
      end, { silent = true, desc = "Snacks explorer (floating)" })
      vim.keymap.set("n", "<leader>fg", function()
        picker.grep(grep_opts({
          layout = { preset = "telescope" },
        }))
      end, { silent = true, desc = "Grep project" })
      vim.keymap.set("n", "<leader>fG", function()
        picker.grep(grep_opts({
          cwd = buf_dir(),
          layout = { preset = "telescope" },
        }))
      end, { silent = true, desc = "Grep current dir" })
      vim.keymap.set("n", "<leader>fw", function()
        picker.grep_word({
          layout = { preset = "telescope" },
        })
      end, { silent = true, desc = "Grep word" })
      vim.keymap.set("n", "<leader>fs", function()
        picker.lsp_symbols({
          focus = "list",
          win = {
            list = {
              keys = {
                ["i"] = { "focus_input", mode = { "n", "x" } },
                ["a"] = { "focus_input", mode = { "n", "x" } },
              },
            },
          },
        })
      end, { silent = true, desc = "Document symbols" })
      vim.keymap.set("n", "<leader>fS", function()
        picker.lsp_workspace_symbols({
          focus = "list",
          win = {
            list = {
              keys = {
                ["i"] = { "focus_input", mode = { "n", "x" } },
                ["a"] = { "focus_input", mode = { "n", "x" } },
              },
            },
          },
        })
      end, { silent = true, desc = "Workspace symbols" })
      vim.keymap.set("n", "<leader>ft", function()
        picker.lsp_type_definitions({
          focus = "list",
          auto_confirm = false,
          win = {
            list = {
              keys = {
                ["i"] = { "focus_input", mode = { "n", "x" } },
                ["a"] = { "focus_input", mode = { "n", "x" } },
              },
            },
          },
        })
      end, { silent = true, desc = "Type definitions" })
      vim.keymap.set("n", "<leader>fI", function()
        picker.lsp_implementations({
          focus = "list",
          auto_confirm = false,
          win = {
            list = {
              keys = {
                ["i"] = { "focus_input", mode = { "n", "x" } },
                ["a"] = { "focus_input", mode = { "n", "x" } },
              },
            },
          },
        })
      end, { silent = true, desc = "Implementations" })
      vim.keymap.set("n", "<leader>fi", function()
        picker.lsp_incoming_calls({
          focus = "list",
          auto_confirm = false,
          win = {
            list = {
              keys = {
                ["i"] = { "focus_input", mode = { "n", "x" } },
                ["a"] = { "focus_input", mode = { "n", "x" } },
              },
            },
          },
        })
      end, { silent = true, desc = "Incoming calls" })
      vim.keymap.set("n", "<leader>fo", function()
        picker.lsp_outgoing_calls({
          focus = "list",
          auto_confirm = false,
          win = {
            list = {
              keys = {
                ["i"] = { "focus_input", mode = { "n", "x" } },
                ["a"] = { "focus_input", mode = { "n", "x" } },
              },
            },
          },
        })
      end, { silent = true, desc = "Outgoing calls" })
      vim.keymap.set("n", "<leader>gl", function()
        picker.git_log({
          focus = "list",
          confirm = "focus_preview",
          layout = { preset = "git_log_fullscreen" },
          win = {
            input = {
              keys = {
                ["C"] = { "git_checkout", mode = { "n", "i" } },
              },
            },
            list = {
              keys = {
                ["a"] = { "focus_input", mode = { "n", "x" } },
                ["C"] = { "git_checkout", mode = { "n", "x" } },
              },
            },
            preview = {
              keys = {
                ["<Esc>"] = "focus_list",
              },
            },
          },
        })
      end, { silent = true, desc = "Git log" })
      vim.keymap.set("n", "<leader>gf", function()
        picker.git_log_file({
          layout = { preset = "git_log_fullscreen" },
        })
      end, { silent = true, desc = "Git log file" })
      vim.keymap.set("n", "<leader>gL", function()
        picker.git_log_line({
          layout = { preset = "git_log_fullscreen" },
        })
      end, { silent = true, desc = "Git log line" })
      vim.keymap.set("n", "<leader>gs", function()
        picker.git_status()
      end, { silent = true, desc = "Git status" })
      vim.keymap.set("n", "<leader>gS", function()
        picker.git_stash()
      end, { silent = true, desc = "Git stash" })
      vim.keymap.set("n", "<leader>gd", function()
        picker.git_diff()
      end, { silent = true, desc = "Git diff" })
      vim.keymap.set("n", "<leader>gD", function()
        vim.cmd("DiffviewOpen")
      end, { silent = true, desc = "Diffview open" })
      vim.keymap.set("n", "<leader>gb", function()
        picker.git_branches()
      end, { silent = true, desc = "Git branches" })
      vim.keymap.set({ "n", "t" }, "<leader>'", function()
        snacks.terminal()
      end, { silent = true, desc = "Terminal toggle" })
    end,
  }

M["stevearc/oil.nvim"] = {
    "stevearc/oil.nvim",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      default_file_explorer = false,
    },
  }

M["nvim-neo-tree/neo-tree.nvim"] = {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      close_if_last_window = true,
      popup_border_style = "rounded",
      enable_git_status = true,
      enable_diagnostics = true,
      filesystem = {
        follow_current_file = {
          enabled = true,
          leave_dirs_open = false,
        },
        use_libuv_file_watcher = true,
      },
      window = {
        position = "right",
        width = 36,
        mappings = {
          ["P"] = {
            "toggle_preview",
            config = {
              use_float = true,
              use_snacks_image = true,
              use_image_nvim = true,
            },
          },
        },
      },
    },
  }

return M
