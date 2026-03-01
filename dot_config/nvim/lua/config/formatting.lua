-- === LSP formatting helpers ===
local function organize_imports(bufnr, client_name)
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  local client = nil
  if client_name then
    for _, c in ipairs(clients) do
      if c.name == client_name then
        client = c
        break
      end
    end
  else
    client = clients[1]
  end
  if not client then
    return
  end

  local encoding = client.offset_encoding or nil
  local params = vim.lsp.util.make_range_params(nil, encoding)
  params.context = { only = { "source.organizeImports" } }
  local result = vim.lsp.buf_request_sync(bufnr, "textDocument/codeAction", params, 1000)
  local res = result and result[client.id]
  for _, r in pairs(res and res.result or {}) do
    if r.edit then
      vim.lsp.util.apply_workspace_edit(r.edit, encoding or "utf-8")
    elseif r.command then
      vim.lsp.buf.execute_command(r.command)
    end
  end
end

local function format_python_with_ruff(bufnr)
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  if bufname == "" then
    return
  end

  local function project_root_from_path(path)
    local start = vim.fn.getcwd()
    if path and path ~= "" then
      start = vim.fs.dirname(path)
    end

    local found = vim.fs.find({ ".venv", "pyproject.toml", "setup.cfg", "setup.py", "requirements.txt", ".git" }, {
      path = start,
      upward = true,
    })
    if found and found[1] then
      return vim.fs.dirname(found[1])
    end
    return vim.fn.getcwd()
  end

  local function resolve_ruff_cmd(path)
    local venv = vim.env.VIRTUAL_ENV or vim.env.CONDA_PREFIX
    if venv and venv ~= "" then
      local ruff_candidates = {
        venv .. "/bin/ruff",
        venv .. "/Scripts/ruff.exe",
      }
      for _, ruff in ipairs(ruff_candidates) do
        if vim.fn.executable(ruff) == 1 then
          return { ruff }
        end
      end
    end

    local root = project_root_from_path(path)
    if root and root ~= "" then
      local ruff_candidates = {
        root .. "/.venv/bin/ruff",
        root .. "/.venv/Scripts/ruff.exe",
      }
      for _, ruff in ipairs(ruff_candidates) do
        if vim.fn.executable(ruff) == 1 then
          return { ruff }
        end
      end
    end

    if vim.fn.executable("uv") == 1 then
      return { "uv", "tool", "run", "ruff" }
    end

    if vim.fn.executable("ruff") == 1 then
      return { "ruff" }
    end

    return nil
  end

  local input = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
  local cmd = resolve_ruff_cmd(bufname)
  if not cmd then
    return
  end
  cmd = vim.list_extend(cmd, { "format", "--stdin-filename", bufname, "-" })
  local output = vim.fn.system(cmd, input)
  if vim.v.shell_error ~= 0 then
    return
  end

  local lines = vim.split(output, "\n", { plain = true })
  if #lines > 0 and lines[#lines] == "" then
    table.remove(lines, #lines)
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  pcall(vim.api.nvim_win_set_cursor, 0, cursor)
end

-- === Autocmds: format on save ===
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  callback = function(args)
    organize_imports(args.buf, "gopls")
    vim.lsp.buf.format({
      bufnr = args.buf,
      async = false,
      timeout_ms = 1000,
      filter = function(client)
        return client.name == "gopls"
      end,
    })
  end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.py",
  callback = function(args)
    format_python_with_ruff(args.buf)
  end,
})
