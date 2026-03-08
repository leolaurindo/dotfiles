local M = {}
local uv = vim.uv or vim.loop

local function read_file(path)
  local fd = uv.fs_open(path, "r", 438)
  if not fd then
    return nil
  end

  local stat = uv.fs_fstat(fd)
  if not stat or not stat.size then
    uv.fs_close(fd)
    return nil
  end

  local data = uv.fs_read(fd, stat.size, 0)
  uv.fs_close(fd)
  return data
end

local function gitpad_context()
  local bufname = vim.api.nvim_buf_get_name(0)
  local start_path = bufname ~= "" and bufname or uv.cwd()
  local stat = uv.fs_stat(start_path)
  local search_from = start_path
  if stat and stat.type ~= "directory" then
    search_from = vim.fs.dirname(start_path)
  end

  local git_marker = vim.fs.find(".git", {
    path = search_from,
    upward = true,
    limit = 1,
  })[1]

  if not git_marker then
    return nil
  end

  local repo_root = vim.fs.dirname(git_marker)
  local git_dir = git_marker
  local git_stat = uv.fs_stat(git_marker)

  if git_stat and git_stat.type == "file" then
    local pointer = read_file(git_marker)
    local rel_git_dir = pointer and pointer:match("gitdir:%s*(.-)%s*$")
    if rel_git_dir and rel_git_dir ~= "" then
      local is_abs = rel_git_dir:match("^%a:[/\\]") ~= nil or rel_git_dir:sub(1, 1) == "/"
      if is_abs then
        git_dir = vim.fs.normalize(rel_git_dir)
      else
        git_dir = vim.fs.normalize(repo_root .. "/" .. rel_git_dir)
      end
    end
  end

  return {
    repo_name = vim.fs.basename(repo_root),
    git_dir = git_dir,
  }
end

local function ensure_gitpad_file(ctx, filename, default_text)
  local gitpad = require("gitpad")
  local notes_dir = vim.fs.normalize(gitpad.config.dir .. "/" .. ctx.repo_name)

  if not uv.fs_stat(notes_dir) then
    vim.fn.mkdir(notes_dir, "p")
  end

  local path = vim.fs.normalize(notes_dir .. "/" .. filename)
  if not uv.fs_stat(path) then
    local fd = uv.fs_open(path, "w", 438)
    if fd then
      if gitpad.config.default_text == nil then
        uv.fs_write(fd, default_text)
      end
      uv.fs_close(fd)
    end
  end

  return path
end

local function clean_branch_name(branch)
  if not branch or branch == "" then
    return nil
  end

  return branch:gsub("%s+", "-"):gsub("/", ":")
end

local function current_branch_name(ctx)
  local head_path = vim.fs.normalize(ctx.git_dir .. "/HEAD")
  local head = read_file(head_path)
  if not head then
    return nil
  end

  local ref = head:match("^ref:%s*(.-)%s*$")
  if not ref then
    return "detached-head"
  end

  local branch = ref:match("^refs/heads/(.+)$")
  if not branch then
    return nil
  end

  return clean_branch_name(branch)
end

local function toggle_gitpad_project_fast()
  local ctx = gitpad_context()
  if not ctx then
    vim.notify("[gitpad.nvim] Current directory is not a git repository", vim.log.levels.WARN)
    return
  end

  local path = ensure_gitpad_file(ctx, "gitpad.md", "# Gitpad\n\nThis is your Gitpad file.\n")
  require("gitpad").toggle_window({ path = path })
end

local function toggle_gitpad_branch_fast(opts)
  local ctx = gitpad_context()
  if not ctx then
    vim.notify("[gitpad.nvim] Current directory is not a git repository", vim.log.levels.WARN)
    return
  end

  local branch = current_branch_name(ctx)
  if not branch then
    vim.notify("[gitpad.nvim] Unable to resolve current branch", vim.log.levels.WARN)
    return
  end

  local filename = branch .. "-branchpad.md"
  local default_text = "# " .. filename .. " Branchpad\n\nThis is your gitpad branch file.\n"
  local path = ensure_gitpad_file(ctx, filename, default_text)
  require("gitpad").toggle_window(vim.tbl_deep_extend("force", opts or {}, { path = path }))
end

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

M["yujinyuz/gitpad.nvim"] = {
    "yujinyuz/gitpad.nvim",
    event = "VeryLazy",
    config = function()
      require("gitpad").setup({
        dir = vim.fn.stdpath("data") .. "/gitpad",
        on_attach = function(bufnr)
          vim.wo.conceallevel = 0
          vim.wo.concealcursor = ""

          vim.keymap.set("n", "<Esc><Esc>", "<cmd>update<CR><cmd>close<CR>", {
            buffer = bufnr,
            desc = "gitpad save and close",
          })
          vim.keymap.set("i", "<Esc><Esc>", "<Esc><cmd>update<CR><cmd>close<CR>", {
            buffer = bufnr,
            desc = "gitpad save and close",
          })

          vim.keymap.set("n", "<leader>pm", function()
            if vim.wo.conceallevel == 0 then
              vim.wo.conceallevel = 2
            else
              vim.wo.conceallevel = 0
            end
          end, { buffer = bufnr, desc = "gitpad toggle markdown render" })
        end,
      })
    end,
    keys = {
      {
        "<leader>pp",
        function()
          toggle_gitpad_project_fast()
        end,
        desc = "gitpad project",
      },
      {
        "<leader>pb",
        function()
          toggle_gitpad_branch_fast()
        end,
        desc = "gitpad branch",
      },
      {
        "<leader>pvs",
        function()
          toggle_gitpad_branch_fast({ window_type = "split", split_win_opts = { split = "right" } })
        end,
        desc = "gitpad branch vertical split",
      },
      {
        "<leader>pd",
        function()
          local date_filename = "daily-" .. os.date("%Y-%m-%d.md")
          require("gitpad").toggle_gitpad({ filename = date_filename }) -- or require('gitpad').toggle_gitpad({ filename = date_filename, title = 'Daily notes' })
        end,
        desc = "gitpad daily notes",
      },
      {
        "<leader>pf",
        function()
          local filename = vim.fn.expand("%:p") -- or just use vim.fn.bufname()
          if filename == "" then
            vim.notify("empty bufname")
            return
          end
          filename = vim.fn.pathshorten(filename, 2) .. ".md"
          require("gitpad").toggle_gitpad({ filename = filename }) -- or require('gitpad').toggle_gitpad({ filename = filename, title = 'Current file notes' })
        end,
        desc = "gitpad per file notes",
      },
    },
  }

return M
