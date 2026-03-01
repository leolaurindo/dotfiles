local M = {}

vim.g.cmp_docs_window_enabled = vim.g.cmp_docs_window_enabled ~= false
vim.g.noice_cmp_docs_override_enabled = vim.g.noice_cmp_docs_override_enabled ~= false
vim.g.lsp_signature_help_enabled = vim.g.lsp_signature_help_enabled == true

local function get_cmp_docs_window_config(cmp)
  local wide_height = 40
  local border = "none"
  if cmp and cmp.config and cmp.config.window and cmp.config.window.get_border then
    border = cmp.config.window.get_border()
  end

  return {
    max_height = math.floor(wide_height * (wide_height / vim.o.lines)),
    max_width = math.floor((wide_height * 2) * (vim.o.columns / (wide_height * 2 * 16 / 9))),
    border = border,
    winhighlight = "FloatBorder:NormalFloat",
    winblend = vim.o.pumblend,
    col_offset = 0,
  }
end

M.get_cmp_docs_window_config = get_cmp_docs_window_config

return M
