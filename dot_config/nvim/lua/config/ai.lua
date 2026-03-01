local globals = require("config.globals")

-- === Copilot helpers & keymaps ===
local function toggle_copilot_attach()
  vim.g.copilot_attached = not vim.g.copilot_attached
  if vim.g.copilot_attached then
    vim.cmd("Copilot attach")
  else
    vim.cmd("Copilot detach")
  end
end
-- Move text up and down
vim.keymap.set("n", "<A-j>", ":m .+1<CR>==", { desc = "Move line down" })
vim.keymap.set("n", "<A-k>", ":m .-2<CR>==", { desc = "Move line up" })
vim.keymap.set("i", "<A-j>", "<Esc>:m .+1<CR>==gi", { desc = "Move line down (Insert)" })
vim.keymap.set("i", "<A-k>", "<Esc>:m .-2<CR>==gi", { desc = "Move line up (Insert)" })
vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

vim.keymap.set("n", "<CR>", "o<Esc>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader><CR>", "o<Esc>", { noremap = true, silent = true })

vim.keymap.set({ "n", "i" }, "<F12>", toggle_copilot_attach, { silent = true, desc = "Copilot toggle" })

local function toggle_cmp_autocomplete()
  vim.g.cmp_autocomplete_enabled = vim.g.cmp_autocomplete_enabled == false
  vim.notify("Autocomplete: " .. (vim.g.cmp_autocomplete_enabled and "ON" or "OFF"))
end

local function apply_cmp_docs_window_setting(enabled)
  vim.g.cmp_docs_window_enabled = enabled

  local ok_cmp, cmp = pcall(require, "cmp")
  if not ok_cmp then
    vim.notify("nvim-cmp docs window: " .. (enabled and "ON" or "OFF") .. " (applies on next InsertEnter)")
    return
  end

  cmp.setup({
    window = {
      documentation = enabled and globals.get_cmp_docs_window_config(cmp) or cmp.config.disable,
    },
  })

  if cmp.visible() then
    cmp.close()
  end

  vim.notify("nvim-cmp docs window: " .. (enabled and "ON" or "OFF"))
end

local function toggle_cmp_docs_window()
  apply_cmp_docs_window_setting(vim.g.cmp_docs_window_enabled == false)
end

local function cmp_entry_native_get_documentation(self)
  local item = self.completion_item
  local documents = {}

  if item.detail and item.detail ~= "" then
    local ft = self.context.filetype or ""
    local dot_index = string.find(ft, "%.")
    if dot_index ~= nil then
      ft = string.sub(ft, 1, dot_index - 1)
    end
    table.insert(documents, {
      kind = "markdown",
      value = ("```%s\n%s\n```"):format(ft, vim.trim(item.detail)),
    })
  end

  local documentation = item.documentation
  if type(documentation) == "string" and documentation ~= "" then
    local value = vim.trim(documentation)
    if value ~= "" then
      table.insert(documents, {
        kind = "plaintext",
        value = value,
      })
    end
  elseif type(documentation) == "table" and documentation.value and documentation.value ~= "" then
    local value = vim.trim(documentation.value)
    if value ~= "" then
      table.insert(documents, {
        kind = documentation.kind or "plaintext",
        value = value,
      })
    end
  end

  return vim.lsp.util.convert_input_to_markdown_lines(documents)
end

local function apply_noice_cmp_docs_override(enabled)
  vim.g.noice_cmp_docs_override_enabled = enabled

  local ok_entry, entry = pcall(require, "cmp.entry")
  if not ok_entry then
    vim.notify("Noice cmp docs override: " .. (enabled and "ON" or "OFF") .. " (applies on next completion)")
    return
  end

  if enabled then
    local ok_override, override = pcall(require, "noice.lsp.override")
    if not ok_override or type(override.cmp_get_documentation) ~= "function" then
      vim.notify("Noice cmp docs override: ON (will apply after Noice loads)", vim.log.levels.WARN)
      return
    end
    entry.get_documentation = override.cmp_get_documentation
  else
    entry.get_documentation = cmp_entry_native_get_documentation
  end

  local ok_cmp, cmp = pcall(require, "cmp")
  if ok_cmp and cmp.visible() then
    cmp.close()
  end

  vim.notify("Noice cmp docs override: " .. (enabled and "ON" or "OFF"))
end

local function toggle_noice_cmp_docs_override()
  apply_noice_cmp_docs_override(vim.g.noice_cmp_docs_override_enabled == false)
end

local native_signature_help_handler = vim.lsp.handlers["textDocument/signatureHelp"]
local native_lsp_buf_signature_help = vim.lsp.buf.signature_help

local function apply_lsp_signature_help_setting(enabled, opts)
  opts = opts or {}
  vim.g.lsp_signature_help_enabled = enabled

  local ok_noice_config, noice_config = pcall(require, "noice.config")
  local noice_running = ok_noice_config and noice_config and noice_config.is_running and noice_config.is_running()

  if ok_noice_config and noice_config and noice_config.options then
    noice_config.options.lsp = noice_config.options.lsp or {}
    noice_config.options.lsp.signature = vim.tbl_deep_extend("force", noice_config.options.lsp.signature or {}, {
      enabled = enabled,
      auto_open = {
        enabled = enabled,
      },
    })
  end

  if enabled then
    if native_signature_help_handler then
      vim.lsp.handlers["textDocument/signatureHelp"] = native_signature_help_handler
    end

    if noice_running then
      local ok_noice_lsp, noice_lsp = pcall(require, "noice.lsp")
      local ok_noice_sig, noice_signature = pcall(require, "noice.lsp.signature")
      if ok_noice_sig and type(noice_signature.setup) == "function" then
        noice_signature.setup()
      end
      if ok_noice_lsp and type(noice_lsp.signature) == "function" then
        vim.lsp.buf.signature_help = noice_lsp.signature
      elseif native_lsp_buf_signature_help then
        vim.lsp.buf.signature_help = native_lsp_buf_signature_help
      end
    elseif native_lsp_buf_signature_help then
      vim.lsp.buf.signature_help = native_lsp_buf_signature_help
    end
  else
    pcall(vim.api.nvim_del_augroup_by_name, "noice_lsp_signature")
    vim.lsp.buf.signature_help = function()
      return nil
    end
    vim.lsp.handlers["textDocument/signatureHelp"] = function()
      return nil
    end
    pcall(vim.cmd, "silent! NoiceDismiss")
  end

  if not opts.silent then
    vim.notify("LSP signature popup: " .. (enabled and "ON" or "OFF"))
  end
end

local function toggle_lsp_signature_help()
  apply_lsp_signature_help_setting(vim.g.lsp_signature_help_enabled == false)
end

local function toggle_sidekick_nes()
  local enabled = vim.g.sidekick_nes ~= false
  vim.g.sidekick_nes = not enabled

  local ok, nes = pcall(require, "sidekick.nes")
  if ok then
    nes.enable(vim.g.sidekick_nes)
  end

  vim.notify("Sidekick NES: " .. (vim.g.sidekick_nes and "ON" or "OFF"))
end

vim.api.nvim_create_user_command("CmpToggle", toggle_cmp_autocomplete, { desc = "Toggle nvim-cmp autocomplete" })
vim.api.nvim_create_user_command("CmpDocsToggle", toggle_cmp_docs_window, { desc = "Toggle nvim-cmp docs window" })
vim.api.nvim_create_user_command("NesToggle", toggle_sidekick_nes, { desc = "Toggle Sidekick NES" })
vim.api.nvim_create_user_command("NoiceCmpDocsToggle", toggle_noice_cmp_docs_override,
  { desc = "Toggle Noice cmp docs override" })
vim.api.nvim_create_user_command("LspSignatureToggle", toggle_lsp_signature_help, { desc = "Toggle LSP signature popup" })
vim.keymap.set("n", "<leader>ua", toggle_cmp_autocomplete, { silent = true, desc = "Toggle autocomplete" })
vim.keymap.set("n", "<leader>uD", toggle_cmp_docs_window, { silent = true, desc = "Toggle nvim-cmp docs window" })
vim.keymap.set("n", "<leader>uN", toggle_sidekick_nes, { silent = true, desc = "Toggle Sidekick NES" })
vim.keymap.set("n", "<leader>uM", toggle_noice_cmp_docs_override,
  { silent = true, desc = "Toggle Noice cmp docs override" })
vim.keymap.set("n", "<leader>us", toggle_lsp_signature_help, { silent = true, desc = "Toggle LSP signature popup" })
vim.keymap.set("n", "<leader>uc", toggle_copilot_attach, { silent = true, desc = "Toggle Copilot" })

apply_lsp_signature_help_setting(vim.g.lsp_signature_help_enabled ~= false, { silent = true })

local function ai_accept_review_first()
  local ok_sidekick, sidekick = pcall(require, "sidekick")
  if ok_sidekick and sidekick.nes_jump_or_apply and sidekick.nes_jump_or_apply() then
    return true
  end

  local ok_copilot, copilot = pcall(require, "copilot.suggestion")
  if ok_copilot and copilot.is_visible() then
    copilot.accept()
    return true
  end

  return false
end

local function dismiss_one_suggestion()
  -- NOTE for future agents: user wants soft dismiss only (one layer per press).
  local ok_nes, nes = pcall(require, "sidekick.nes")
  if ok_nes and nes.have and nes.have() then
    nes.clear()
    return true
  end

  local ok_copilot, copilot = pcall(require, "copilot.suggestion")
  if ok_copilot and copilot.is_visible() then
    copilot.dismiss()
    return true
  end

  local ok_cmp, cmp = pcall(require, "cmp")
  if ok_cmp and cmp.visible() then
    cmp.close()
    return true
  end

  return false
end

vim.keymap.set("n", "<leader>an", ai_accept_review_first, { silent = true, desc = "AI accept (NES/Copilot)" })
vim.keymap.set("n", "<leader>ad", dismiss_one_suggestion, { silent = true, desc = "AI dismiss one" })
vim.keymap.set("i", "<C-y>", function()
  if ai_accept_review_first() then
    return ""
  end
  return "<C-y>"
end, { expr = true, silent = true, desc = "AI accept (NES/Copilot)" })
vim.keymap.set("i", "<C-e>", function()
  if dismiss_one_suggestion() then
    return ""
  end
  return "<C-e>"
end, { expr = true, silent = true, desc = "AI dismiss one" })
