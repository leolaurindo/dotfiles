-- === Diagnostics ===
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = { border = "rounded", source = "if_many" },
})

-- === Toggle inline diagnostics ===
vim.api.nvim_create_user_command("InlineDiagnosticsToggle", function()
  local current_config = vim.diagnostic.config()
  local new_state = not current_config.virtual_text
  vim.diagnostic.config({ virtual_text = new_state })
  print("Inline diagnostics: " .. (new_state and "ON" or "OFF"))
end, { desc = "Toggle inline diagnostic messages" })

vim.api.nvim_create_user_command("DiagUnderlineToggle", function()
  local current_config = vim.diagnostic.config()
  local new_state = not current_config.underline
  vim.diagnostic.config({ underline = new_state })
  vim.notify("Diagnostic underline: " .. (new_state and "ON" or "OFF"))
end, { desc = "Toggle diagnostic underlines" })

vim.api.nvim_create_user_command("DiagSignsToggle", function()
  local current_config = vim.diagnostic.config()
  local new_state = not current_config.signs
  vim.diagnostic.config({ signs = new_state })
  vim.notify("Diagnostic signs: " .. (new_state and "ON" or "OFF"))
end, { desc = "Toggle diagnostic signs" })

-- Alias for quick access
vim.api.nvim_create_user_command("Diag", function()
  vim.cmd("InlineDiagnosticsToggle")
end, { desc = "Toggle inline diagnostics (alias)" })
