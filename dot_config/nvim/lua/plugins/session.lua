local M = {}

M["folke/persistence.nvim"] = {
  "folke/persistence.nvim",
  lazy = false,
  opts = {
    branch = true,
    need = 1,
  },
  config = function(_, opts)
    local persistence = require("persistence")
    local config = require("persistence.config")

    vim.opt.sessionoptions:remove("blank")
    persistence.setup(opts)

    local function is_empty_window(win)
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].modified or vim.bo[buf].buftype ~= "" then
        return false
      end

      if vim.api.nvim_buf_get_name(buf) ~= "" then
        return false
      end

      local lines = vim.api.nvim_buf_get_lines(buf, 0, 2, false)
      return #lines <= 1 and (lines[1] or "") == ""
    end

    local function close_empty_windows()
      local wins = vim.api.nvim_tabpage_list_wins(0)
      if #wins <= 1 then
        return
      end

      for _, win in ipairs(wins) do
        if #vim.api.nvim_tabpage_list_wins(0) <= 1 then
          break
        end
        if vim.api.nvim_win_is_valid(win) and is_empty_window(win) then
          pcall(vim.api.nvim_win_close, win, true)
        end
      end
    end

    local function define_user_command(name, fn, command_opts)
      pcall(vim.api.nvim_del_user_command, name)
      vim.api.nvim_create_user_command(name, fn, command_opts)
    end

    local function session_dir()
      return config.options.dir
    end

    local function session_files()
      return vim.fn.glob(session_dir() .. "*.vim", false, true)
    end

    define_user_command("SessionRestore", function()
      persistence.load()
      vim.schedule(close_empty_windows)
    end, { desc = "Restore session for current working directory" })

    define_user_command("SessionLast", function()
      persistence.load({ last = true })
      vim.schedule(close_empty_windows)
    end, { desc = "Restore last session" })

    define_user_command("SessionStop", function()
      persistence.stop()
      vim.notify("Session autosave disabled for this Neovim instance")
    end, { desc = "Stop session autosave for current Neovim instance" })

    define_user_command("SessionPath", function()
      vim.notify("Session directory: " .. session_dir())
    end, { desc = "Show session storage directory" })

    define_user_command("SessionClean", function()
      local file = persistence.current()
      if vim.fn.filereadable(file) == 0 then
        vim.notify("No session file for current working directory")
        return
      end

      local ok = vim.fn.delete(file) == 0
      if ok then
        vim.notify("Deleted session: " .. vim.fn.fnamemodify(file, ":t"))
      else
        vim.notify("Failed to delete session: " .. file, vim.log.levels.ERROR)
      end
    end, { desc = "Delete session for current working directory" })

    define_user_command("SessionCleanAll", function()
      local files = session_files()
      if #files == 0 then
        vim.notify("No session files to delete")
        return
      end

      local answer = vim.fn.confirm("Delete all session files?", "&Yes\n&No", 2)
      if answer ~= 1 then
        return
      end

      local deleted = 0
      for _, file in ipairs(files) do
        if vim.fn.delete(file) == 0 then
          deleted = deleted + 1
        end
      end

      vim.notify(string.format("Deleted %d/%d session files", deleted, #files))
    end, { desc = "Delete all saved sessions" })

    vim.api.nvim_create_autocmd("User", {
      pattern = "PersistenceLoadPost",
      callback = function()
        vim.schedule(close_empty_windows)
      end,
    })
  end,
}

return M
