local jupyter = require("config.jupyter")

-- === Global keymaps ===
local function neo_tree_exec(args, state_config_override)
  local ok, command = pcall(require, "neo-tree.command")
  if not ok then
    return
  end
  command.execute(args, state_config_override)
end

local function neo_tree_toggle_sidebar()
  neo_tree_exec({
    source = "filesystem",
    position = "right",
    reveal = true,
    toggle = true,
  })
end

local function neo_tree_float_preview()
  neo_tree_exec({
    source = "filesystem",
    position = "float",
    reveal = true,
    action = "focus",
  })

  local function enable_preview(attempt)
    local ok_manager, manager = pcall(require, "neo-tree.sources.manager")
    local ok_common, common = pcall(require, "neo-tree.sources.common.commands")
    if not ok_manager or not ok_common then
      return
    end

    local state = manager.get_state("filesystem")
    if not state or state.current_position ~= "float" then
      return
    end

    if not state.winid or not vim.api.nvim_win_is_valid(state.winid) then
      if attempt < 15 then
        vim.defer_fn(function()
          enable_preview(attempt + 1)
        end, 30)
      end
      return
    end

    if not state.tree then
      if attempt < 15 then
        vim.defer_fn(function()
          enable_preview(attempt + 1)
        end, 30)
      end
      return
    end

    local ok_node, node = pcall(function()
      return state.tree:get_node()
    end)
    if not ok_node or not node then
      if attempt < 15 then
        vim.defer_fn(function()
          enable_preview(attempt + 1)
        end, 30)
      end
      return
    end

    if type(common.preview) == "function" then
      local ok_preview = pcall(common.preview, state)
      if not ok_preview and attempt < 15 then
        vim.defer_fn(function()
          enable_preview(attempt + 1)
        end, 30)
      end
    end
  end

  vim.schedule(function()
    enable_preview(1)
  end)
end

vim.api.nvim_create_user_command("NeoTreeFilesystem", function()
  neo_tree_exec({
    source = "filesystem",
    position = "right",
    reveal = true,
    action = "focus",
  })
end, { desc = "Neo-tree filesystem (right)" })

vim.api.nvim_create_user_command("NeoTreeBuffers", function()
  neo_tree_exec({
    source = "buffers",
    position = "right",
    action = "focus",
  })
end, { desc = "Neo-tree buffers (right)" })

vim.api.nvim_create_user_command("NeoTreeGit", function()
  neo_tree_exec({
    source = "git_status",
    position = "right",
    action = "focus",
  })
end, { desc = "Neo-tree git status (right)" })

vim.api.nvim_create_user_command("NeoTreeFloat", function()
  neo_tree_exec({
    source = "filesystem",
    position = "float",
    reveal = true,
    action = "focus",
  })
end, { desc = "Neo-tree filesystem (float)" })

vim.api.nvim_create_user_command("NeoTreeFloatPreview", neo_tree_float_preview, {
  desc = "Neo-tree float with preview",
})

local function toggle_markdown_conceal()
  local ok_render_markdown, render_markdown = pcall(require, "render-markdown")
  local current = vim.opt_local.conceallevel:get()
  if current > 0 then
    vim.opt_local.conceallevel = 0
    vim.opt_local.concealcursor = ""
    if ok_render_markdown and type(render_markdown.buf_disable) == "function" then
      render_markdown.buf_disable()
    end
    vim.notify("Markdown plain text ON", vim.log.levels.INFO)
    return
  end

  vim.opt_local.conceallevel = 2
  vim.opt_local.concealcursor = "nc"
  if ok_render_markdown and type(render_markdown.buf_enable) == "function" then
    render_markdown.buf_enable()
  end
  vim.notify("Markdown plain text OFF", vim.log.levels.INFO)
end

vim.api.nvim_create_user_command("MarkdownToggle", toggle_markdown_conceal, {
  desc = "Toggle markdown conceal rendering",
})
vim.api.nvim_create_user_command("MdToggle", toggle_markdown_conceal, {
  desc = "Toggle markdown conceal rendering",
})
vim.api.nvim_create_user_command("MdTog", toggle_markdown_conceal, {
  desc = "Toggle markdown conceal rendering",
})

vim.keymap.set("n", "<leader>e", neo_tree_toggle_sidebar, { silent = true, desc = "Neo-tree filesystem toggle" })
vim.keymap.set("n", "<leader>E", "<cmd>NeoTreeFloat<CR>", { silent = true, desc = "Neo-tree filesystem float" })
vim.keymap.set("x", "<C-c>", '"+y', { silent = true, desc = "Copy to clipboard" })
vim.keymap.set("x", ".", ":normal .<CR>", { silent = true, desc = "Repeat last change for selection" })
vim.keymap.set("n", "<leader>ai", "<cmd>Opencode<CR>", { silent = true, desc = "Opencode toggle" })

vim.keymap.set("n", "<leader>jk", "<cmd>CreateKernel<CR>", { silent = true, desc = "Create project kernel" })
vim.keymap.set("n", "<leader>jK", "<cmd>CreateKernel!<CR>", { silent = true, desc = "Create kernel + MoltenInit" })
vim.keymap.set("n", "<leader>jI", jupyter.molten_init_project_kernel, { silent = true, desc = "Molten init project kernel" })
vim.keymap.set("n", "<leader>jn", function()
  jupyter.jump_jupytext_cell(1)
end, { silent = true, desc = "Next # %% cell" })
vim.keymap.set("n", "<leader>jp", function()
  jupyter.jump_jupytext_cell(-1)
end, { silent = true, desc = "Previous # %% cell" })
vim.keymap.set("n", "<leader>jC", function()
  jupyter.insert_jupytext_cell_below(false)
end, { silent = true, desc = "Insert # %% cell below" })
vim.keymap.set("n", "<leader>jc", function()
  jupyter.insert_jupytext_cell_below(true)
end, { silent = true, desc = "Insert # %% cell below + insert" })
vim.keymap.set("n", "<leader>jr", jupyter.run_current_jupytext_cell, { silent = true, desc = "Run current # %% cell" })
vim.keymap.set("n", "<leader>ja", jupyter.run_all_jupytext_cells, { silent = true, desc = "Run all # %% code cells" })
vim.keymap.set("n", "<leader>jR", "<cmd>MoltenReevaluateCell<CR>", { silent = true, desc = "Re-run active Molten cell" })
vim.keymap.set("n", "<leader>jl", "<cmd>MoltenEvaluateLine<CR>", { silent = true, desc = "Run current line" })
vim.keymap.set("x", "<leader>jr", ":<C-u>MoltenEvaluateVisual<CR>gv", { silent = true, desc = "Run visual selection" })
vim.keymap.set("n", "<leader>jo", "<cmd>MoltenShowOutput<CR>", { silent = true, desc = "Show output" })
vim.keymap.set("n", "<leader>jb", "<cmd>MoltenOpenInBrowser<CR>", { silent = true, desc = "Open HTML output in browser" })
vim.keymap.set("n", "<leader>ji", "<cmd>MoltenImagePopup<CR>", { silent = true, desc = "Open image output" })
vim.keymap.set("n", "<leader>jh", "<cmd>MoltenHideOutput<CR>", { silent = true, desc = "Hide output" })
vim.keymap.set("n", "<leader>je", "<cmd>noautocmd MoltenEnterOutput<CR>", { silent = true, desc = "Enter output window" })
vim.keymap.set("n", "<leader>jd", "<cmd>MoltenDelete<CR>", { silent = true, desc = "Delete active Molten cell" })
vim.keymap.set("n", "<leader>jD", "<cmd>JupyterDoctor<CR>", { silent = true, desc = "Jupyter setup doctor" })
vim.keymap.set("n", "<leader>jx", "<cmd>JupytextExport<CR>", { silent = true, desc = "Export .py to .ipynb" })

local molten_output_group = vim.api.nvim_create_augroup("MoltenOutputMappings", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = molten_output_group,
  pattern = "molten_output",
  callback = function(ev)
    vim.keymap.set("n", "<Esc>", jupyter.leave_molten_output_window, {
      buffer = ev.buf,
      silent = true,
      desc = "Leave Molten output",
    })
    vim.keymap.set("n", "q", jupyter.leave_molten_output_window, {
      buffer = ev.buf,
      silent = true,
      desc = "Leave Molten output",
    })
  end,
})

-- === Custom scroll commands ===
-- <C-e> scrolls 3 lines instead of 1
vim.keymap.set("n", "<C-e>", "3<C-e>", { silent = true, desc = "Scroll down 3 lines" })
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { silent = true, desc = "Clear search highlights" })
vim.keymap.set("n", "<leader>o", "<cmd>AerialToggle<CR>", { silent = true })
vim.keymap.set("n", "<leader>O", "<cmd>AerialNavToggle<CR>", { silent = true })
vim.keymap.set("n", "gl", vim.diagnostic.open_float, { silent = true, desc = "Line diagnostics" })
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { silent = true, desc = "Prev diagnostic" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { silent = true, desc = "Next diagnostic" })
vim.keymap.set("n", "]q", "<cmd>cnext<CR>zz", { silent = true, desc = "Quickfix next" })
vim.keymap.set("n", "[q", "<cmd>cprev<CR>zz", { silent = true, desc = "Quickfix prev" })
vim.keymap.set("n", "]Q", "<cmd>clast<CR>zz", { silent = true, desc = "Quickfix last" })
vim.keymap.set("n", "[Q", "<cmd>cfirst<CR>zz", { silent = true, desc = "Quickfix first" })
vim.keymap.set("n", "]l", "<cmd>lnext<CR>zz", { silent = true, desc = "Location list next" })
vim.keymap.set("n", "[l", "<cmd>lprev<CR>zz", { silent = true, desc = "Location list prev" })
vim.keymap.set("n", "]L", "<cmd>llast<CR>zz", { silent = true, desc = "Location list last" })
vim.keymap.set("n", "[L", "<cmd>lfirst<CR>zz", { silent = true, desc = "Location list first" })
vim.keymap.set("n", "<leader>qo", "<cmd>copen<CR>", { silent = true, desc = "Quickfix open" })
vim.keymap.set("n", "<leader>lo", "<cmd>lopen<CR>", { silent = true, desc = "Location list open" })
vim.keymap.set("n", "<leader>udd", "<cmd>InlineDiagnosticsToggle<CR>", { silent = true, desc = "Diagnostics: toggle inline" })
vim.keymap.set("n", "<leader>udu", "<cmd>DiagUnderlineToggle<CR>", { silent = true, desc = "Diagnostics: toggle underline" })
vim.keymap.set("n", "<leader>uds", "<cmd>DiagSignsToggle<CR>", { silent = true, desc = "Diagnostics: toggle signs" })
