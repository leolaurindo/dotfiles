-- === Autocmds: filetype keymaps ===
vim.api.nvim_create_autocmd("FileType", {
  pattern = "fugitive",
  callback = function(args)
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = args.buf, silent = true })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "DiffviewFiles", "DiffviewFileHistory" },
  callback = function(args)
    vim.keymap.set("n", "q", "<cmd>DiffviewClose<CR>", { buffer = args.buf, silent = true })
    vim.keymap.set("n", "<Esc>", "<cmd>DiffviewClose<CR>", { buffer = args.buf, silent = true })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.conceallevel = 2
    vim.opt_local.concealcursor = "nc"
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "alpha",
  callback = function(args)
    vim.keymap.set("n", "r", "<cmd>SessionRestore<CR>", {
      buffer = args.buf,
      silent = true,
      nowait = true,
      desc = "Restore session (cwd)",
    })
    vim.keymap.set("n", "/", "<cmd>DashboardSearchCwd<CR>", {
      buffer = args.buf,
      silent = true,
      nowait = true,
      desc = "Search files (cwd)",
    })
  end,
})

vim.cmd([[
xnoremap @ :<C-u>call ExecuteMacroOverVisualRange()<CR>

function! ExecuteMacroOverVisualRange()
  echo "@".getcmdline()
  execute ":'<,'>normal @".nr2char(getchar())
endfunction
]])
