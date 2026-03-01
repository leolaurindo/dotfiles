vim.api.nvim_create_user_command("Ct", function()
  vim.cmd("checktime")
end, { desc = "Check file timestamps and reload changed buffers" })

vim.api.nvim_create_user_command("Cclear", function()
  vim.fn.setqflist({}, "r")
  vim.notify("Quickfix list cleared")
end, { desc = "Clear quickfix list" })

vim.cmd([[cnoreabbrev <expr> cclear ((getcmdtype() == ':' && getcmdline() ==# 'cclear') ? 'Cclear' : 'cclear')]])

vim.api.nvim_create_user_command("Lazygit", function(opts)
  local arg = vim.trim(opts.args or "")
  if arg == "" then
    Snacks.lazygit()
  elseif arg == "log" then
    Snacks.lazygit.log()
  elseif arg == "file" then
    Snacks.lazygit.log_file()
  else
    vim.notify("Usage: :Lazygit [log|file]", vim.log.levels.ERROR)
  end
end, {
  nargs = "?",
  complete = function(arg_lead)
    local items = { "log", "file" }
    return vim.tbl_filter(function(item)
      return item:find("^" .. vim.pesc(arg_lead)) ~= nil
    end, items)
  end,
  desc = "Open LazyGit (or log/file views)",
})

vim.api.nvim_create_user_command("RenameFile", function()
  Snacks.rename.rename_file()
end, { desc = "Rename current file with LSP updates" })

vim.api.nvim_create_user_command("Term", function()
  require("snacks").terminal.open()
end, { desc = "Open a new terminal" })

vim.cmd([[cnoreabbrev <expr> . ((getcmdtype() == ':' && getcmdline() =~# '^DiffviewFileHistory\s\+\.$') ? '%' : '.')]])

vim.api.nvim_create_autocmd("CursorHold", {
  callback = function()
    if vim.tbl_isempty(vim.diagnostic.get(0)) then
      return
    end
    vim.diagnostic.open_float(nil, { focus = false })
  end,
})

local function clear_config_module_cache()
  for name in pairs(package.loaded) do
    if name == "config" or vim.startswith(name, "config.") or name == "plugins" or vim.startswith(name, "plugins.") then
      package.loaded[name] = nil
    end
  end
end

vim.api.nvim_create_user_command("Refresh", function()
  clear_config_module_cache()
  local vimrc = vim.env.MYVIMRC or (vim.fn.stdpath("config") .. "/init.lua")
  local ok, err = pcall(vim.cmd, "source " .. vim.fn.fnameescape(vimrc))
  if ok then
    vim.notify("Config refreshed: " .. vimrc)
  else
    vim.notify("Refresh failed: " .. tostring(err), vim.log.levels.ERROR)
  end
end, { desc = "Reload Neovim config" })
