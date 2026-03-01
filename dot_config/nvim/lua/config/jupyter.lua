-- === Jupyter + Molten helpers ===
local function jupyter_project_info(bufnr)
  local uv = vim.uv or vim.loop
  local bufname = vim.api.nvim_buf_get_name(bufnr or 0)
  local start = (bufname ~= "" and vim.fs.dirname(bufname)) or uv.cwd()

  local found = vim.fs.find(".venv", { path = start, upward = true, type = "directory" })
  local venv = found and found[1] or nil
  if not venv then
    return nil
  end

  local root = vim.fs.dirname(venv)
  local project = vim.fs.basename(root)
  local kernel = project:gsub("%s+", "-"):gsub("[^%w_-]", ""):lower()
  if kernel == "" then
    kernel = "python-project"
  end

  return {
    root = root,
    venv = venv,
    project = project,
    kernel = kernel,
  }
end

local function is_jupytext_marker(line)
  return line:match("^%s*#%s*%%%%") ~= nil
end

local function is_jupytext_markdown_marker(line)
  return is_jupytext_marker(line) and line:lower():find("%[markdown%]", 1, false) ~= nil
end

local function ensure_molten_loaded()
  local manifest = vim.fn.stdpath("data") .. "/rplugin.vim"
  if vim.fn.filereadable(manifest) == 1 and vim.fn.exists(":MoltenInit") ~= 2 then
    pcall(vim.cmd, "silent source " .. vim.fn.fnameescape(manifest))
  end

  local ok, lazy = pcall(require, "lazy")
  if ok and lazy and lazy.load then
    pcall(lazy.load, { plugins = { "molten-nvim" } })
  end
end

local function current_buffer_kernel_id()
  if vim.fn.exists("*MoltenRunningKernels") ~= 1 then
    local hinted = vim.b._jupyter_kernel_id
    if type(hinted) == "string" and hinted ~= "" then
      return hinted
    end
    return nil
  end

  local ok, kernels = pcall(vim.fn.MoltenRunningKernels, true)
  if not ok or type(kernels) ~= "table" or #kernels == 0 then
    local hinted = vim.b._jupyter_kernel_id
    if type(hinted) == "string" and hinted ~= "" then
      return hinted
    end
    return nil
  end

  local kernel = kernels[1]
  if type(kernel) ~= "string" or kernel == "" then
    local hinted = vim.b._jupyter_kernel_id
    if type(hinted) == "string" and hinted ~= "" then
      return hinted
    end
    return nil
  end

  vim.b._jupyter_kernel_id = kernel
  return kernel
end

local function ensure_buffer_kernel_id()
  local existing = current_buffer_kernel_id()
  if existing then
    return existing
  end

  local info = jupyter_project_info(0)
  if not info then
    vim.notify("No project .venv found for Molten init", vim.log.levels.ERROR)
    return nil
  end

  if vim.fn.exists(":MoltenInit") ~= 2 then
    vim.notify("MoltenInit is unavailable", vim.log.levels.ERROR)
    return nil
  end

  local ok = pcall(vim.cmd, "MoltenInit " .. vim.fn.fnameescape(info.kernel))
  if not ok then
    vim.notify("Failed to initialize Molten kernel", vim.log.levels.ERROR)
    return nil
  end

  vim.b._jupyter_kernel_id = info.kernel

  if vim.fn.exists("*MoltenRunningKernels") ~= 1 then
    return info.kernel
  end

  local resolved = nil
  vim.wait(4000, function()
    resolved = current_buffer_kernel_id()
    return resolved ~= nil
  end, 50)

  if resolved then
    return resolved
  end

  vim.notify("Kernel attach check timed out; continuing with requested kernel", vim.log.levels.WARN)
  return info.kernel
end

local function molten_evaluate_range(start_line, end_line, kernel_id)
  if vim.fn.exists("*MoltenEvaluateRange") == 1 then
    if kernel_id and kernel_id ~= "" then
      local ok_with_kernel = pcall(vim.fn.MoltenEvaluateRange, kernel_id, start_line, end_line, 1, 999999)
      if ok_with_kernel then
        return true
      end
      local ok_without_kernel = pcall(vim.fn.MoltenEvaluateRange, start_line, end_line, 1, 999999)
      if ok_without_kernel then
        return true
      end
    else
      local ok_without_kernel = pcall(vim.fn.MoltenEvaluateRange, start_line, end_line, 1, 999999)
      if ok_without_kernel then
        return true
      end
    end
  end

  if vim.fn.exists(":MoltenEvaluateVisual") == 2 then
    local end_text = vim.fn.getline(end_line)
    local end_col = math.max(1, #end_text)
    vim.fn.setpos("'<", { 0, start_line, 1, 0 })
    vim.fn.setpos("'>", { 0, end_line, end_col, 0 })
    local cmd = "MoltenEvaluateVisual"
    if kernel_id and kernel_id ~= "" then
      cmd = cmd .. " " .. vim.fn.fnameescape(kernel_id)
    end
    local ok_eval = pcall(vim.cmd, cmd)
    if ok_eval then
      return true
    end

    local ok_eval_no_kernel = pcall(vim.cmd, "MoltenEvaluateVisual")
    if ok_eval_no_kernel then
      return true
    end
  end

  return false
end

local function current_jupytext_cell_range(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local total = #lines
  if total == 0 then
    return nil
  end

  local row = vim.api.nvim_win_get_cursor(0)[1]
  row = math.max(1, math.min(row, total))

  local start_line = 1
  for i = row, 1, -1 do
    if is_jupytext_marker(lines[i]) then
      start_line = i
      break
    end
  end

  local end_line = total
  for i = row + 1, total do
    if is_jupytext_marker(lines[i]) then
      end_line = i - 1
      break
    end
  end

  local code_start = start_line
  if lines[start_line] and is_jupytext_marker(lines[start_line]) then
    code_start = start_line + 1
  end

  while end_line >= code_start and (lines[end_line] or ""):match("^%s*$") do
    end_line = end_line - 1
  end

  return code_start, end_line
end

local function run_current_jupytext_cell()
  ensure_molten_loaded()

  local kernel_id = ensure_buffer_kernel_id()
  if not kernel_id then
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local start_line, end_line = current_jupytext_cell_range(bufnr)
  if not start_line or not end_line or start_line > end_line then
    vim.notify("Current Jupytext cell is empty", vim.log.levels.WARN)
    return
  end

  if molten_evaluate_range(start_line, end_line, kernel_id) then
    return
  end

  vim.notify(
    "Molten is unavailable. Run :Lazy sync, :UpdateRemotePlugins, and ensure Neovim host has pynvim + jupyter_client.",
    vim.log.levels.ERROR
  )
end

local function run_all_jupytext_cells()
  ensure_molten_loaded()
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  if #lines == 0 then
    vim.notify("Buffer is empty", vim.log.levels.WARN)
    return
  end

  local ranges = {}
  local markers = {}
  for i, line in ipairs(lines) do
    if is_jupytext_marker(line) then
      table.insert(markers, i)
    end
  end

  if #markers == 0 then
    local first = 1
    local last = #lines
    while first <= last and (lines[first] or ""):match("^%s*$") do
      first = first + 1
    end
    while last >= first and (lines[last] or ""):match("^%s*$") do
      last = last - 1
    end
    if first <= last then
      table.insert(ranges, { first, last })
    end
  else
    for idx, marker_line in ipairs(markers) do
      local marker_text = lines[marker_line] or ""
      if not is_jupytext_markdown_marker(marker_text) then
        local start_line = marker_line + 1
        local next_marker = markers[idx + 1] or (#lines + 1)
        local end_line = next_marker - 1

        while end_line >= start_line and (lines[end_line] or ""):match("^%s*$") do
          end_line = end_line - 1
        end

        if start_line <= end_line then
          table.insert(ranges, { start_line, end_line })
        end
      end
    end
  end

  if #ranges == 0 then
    vim.notify("No runnable Jupytext code cells found", vim.log.levels.WARN)
    return
  end

  local function run_with_kernel(kernel_id)
    if vim.fn.exists(":MoltenDeinit") == 2 and current_buffer_kernel_id() ~= nil then
      pcall(vim.cmd, "MoltenDeinit")
    end

    local done = false
    local augroup = vim.api.nvim_create_augroup("JupyterRunAllInit", { clear = true })

    local function finish(msg, level)
      if done then
        return
      end
      done = true
      pcall(vim.api.nvim_del_augroup_by_id, augroup)
      if msg then
        vim.notify(msg, level or vim.log.levels.INFO)
      end
    end

    vim.api.nvim_create_autocmd("User", {
      group = augroup,
      pattern = "MoltenKernelReady",
      once = true,
      callback = function()
        for _, range in ipairs(ranges) do
          local ok_define = pcall(vim.fn.MoltenDefineCell, range[1], range[2], kernel_id)
          if not ok_define then
            finish("Run all failed while defining cells", vim.log.levels.ERROR)
            return
          end
        end

        local ok_run = pcall(vim.cmd, "MoltenReevaluateAll")
        if not ok_run then
          finish("Run all failed while starting execution", vim.log.levels.ERROR)
          return
        end

        finish(("Running %d cell(s) sequentially"):format(#ranges), vim.log.levels.INFO)
      end,
    })

    local ok_init = pcall(vim.cmd, "MoltenInit " .. vim.fn.fnameescape(kernel_id))
    if not ok_init then
      finish("Failed to initialize selected kernel", vim.log.levels.ERROR)
      return
    end

    vim.defer_fn(function()
      if not done then
        finish("Run all timed out waiting for kernel readiness", vim.log.levels.WARN)
      end
    end, 30000)
  end

  local attached = current_buffer_kernel_id()
  if attached then
    run_with_kernel(attached)
    return
  end

  local info = jupyter_project_info(0)
  local options = {}
  local seen = {}
  local function push(k)
    if type(k) ~= "string" or k == "" or seen[k] then
      return
    end
    seen[k] = true
    table.insert(options, k)
  end

  if vim.fn.exists("*MoltenAvailableKernels") == 1 then
    local ok, available = pcall(vim.fn.MoltenAvailableKernels)
    if ok and type(available) == "table" then
      for _, k in ipairs(available) do
        push(k)
      end
    end
  end
  if info and info.kernel then
    push(info.kernel)
  end

  if #options == 0 then
    vim.notify("No kernels available. Run :CreateKernel first.", vim.log.levels.ERROR)
    return
  end

  if #options == 1 then
    run_with_kernel(options[1])
    return
  end

  local choices = { "Select kernel for Run All:" }
  for i, k in ipairs(options) do
    choices[#choices + 1] = ("%d. %s"):format(i, k)
  end

  local picked = vim.fn.inputlist(choices)
  if picked < 1 or picked > #options then
    vim.notify("Run all cancelled", vim.log.levels.INFO)
    return
  end

  run_with_kernel(options[picked])
end

local function jump_jupytext_cell(direction)
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local total = #lines
  if total == 0 then
    return
  end

  local row = vim.api.nvim_win_get_cursor(0)[1]
  if direction > 0 then
    for i = row + 1, total do
      if is_jupytext_marker(lines[i]) then
        vim.api.nvim_win_set_cursor(0, { i, 0 })
        return
      end
    end
    vim.notify("No next Jupytext cell", vim.log.levels.INFO)
    return
  end

  for i = row - 1, 1, -1 do
    if is_jupytext_marker(lines[i]) then
      vim.api.nvim_win_set_cursor(0, { i, 0 })
      return
    end
  end
  vim.notify("No previous Jupytext cell", vim.log.levels.INFO)
end

local function insert_jupytext_cell_below(enter_insert)
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  if #lines == 1 and (lines[1] or "") == "" then
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "# %%", "" })
    vim.api.nvim_win_set_cursor(0, { 2, 0 })
    if enter_insert then
      vim.cmd("startinsert")
    end
    return
  end

  local _, end_line = current_jupytext_cell_range(bufnr)
  end_line = end_line or #lines
  vim.api.nvim_buf_set_lines(bufnr, end_line, end_line, false, { "", "# %%", "" })
  vim.api.nvim_win_set_cursor(0, { end_line + 3, 0 })
  if enter_insert then
    vim.cmd("startinsert")
  end
end

local function molten_init_project_kernel()
  ensure_molten_loaded()

  local info = jupyter_project_info(0)
  if not info then
    vim.notify("Molten init: .venv not found (searched upward)", vim.log.levels.ERROR)
    return
  end

  local ok_init, err = pcall(vim.cmd, "MoltenInit " .. vim.fn.fnameescape(info.kernel))
  if not ok_init then
    vim.notify(
      "Molten init unavailable. Ensure rplugin is registered and Neovim host has pynvim + jupyter_client + nbformat.",
      vim.log.levels.ERROR
    )
    vim.notify(tostring(err), vim.log.levels.ERROR)
  else
    vim.b._jupyter_kernel_id = info.kernel
  end
end

local function leave_molten_output_window()
  local current = vim.api.nvim_get_current_win()
  local previous = vim.fn.win_getid(vim.fn.winnr("#"))

  pcall(vim.cmd, "MoltenHideOutput")

  if previous ~= 0 and previous ~= current and vim.api.nvim_win_is_valid(previous) then
    vim.fn.win_gotoid(previous)
    return
  end

  pcall(vim.cmd, "wincmd p")
end

local function jupyter_doctor()
  ensure_molten_loaded()

  local info = jupyter_project_info(0)
  local lines = {}
  local function add(msg)
    table.insert(lines, msg)
  end

  local function yesno(v)
    return v and "yes" or "no"
  end

  local function import_ok(py, mod)
    if not py or py == "" or vim.fn.executable(py) ~= 1 then
      return false
    end
    local result = vim.system({ py, "-c", "import " .. mod }, { text = true }):wait()
    return result.code == 0
  end

  local host_python = vim.g.python3_host_prog
  if not host_python or host_python == "" then
    host_python = vim.fn.exepath("python3")
  end

  local is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
  local is_wsl = vim.fn.has("wsl") == 1
  local in_tmux = vim.env.TMUX and vim.env.TMUX ~= ""
  local tmux_passthrough = "n/a"
  local tmux_version = "n/a"
  if in_tmux and vim.fn.executable("tmux") == 1 then
    tmux_passthrough = vim.trim(vim.fn.system({ "tmux", "show", "-gv", "allow-passthrough" }))
    tmux_version = vim.trim(vim.fn.system({ "tmux", "display-message", "-p", "#{version}" }))
  end

  add("JupyterDoctor")
  add("")
  add(("OS: %s"):format(is_wsl and "WSL" or (is_windows and "Windows" or "Unix")))
  add(("uv on PATH: %s"):format(yesno(vim.fn.executable("uv") == 1)))
  add(("Molten command available: %s"):format(yesno(vim.fn.exists(":MoltenInit") == 2)))
  add(("Molten range function available: %s"):format(yesno(vim.fn.exists("*MoltenEvaluateRange") == 1)))
  add(("Neovim host python: %s"):format(host_python ~= "" and host_python or "not found"))
  add(("host has pynvim: %s"):format(yesno(import_ok(host_python, "pynvim"))))
  add(("host has jupyter_client: %s"):format(yesno(import_ok(host_python, "jupyter_client"))))
  add(("host has nbformat: %s"):format(yesno(import_ok(host_python, "nbformat"))))
  add(("host has pillow (PIL): %s"):format(yesno(import_ok(host_python, "PIL"))))
  add(("TERM_PROGRAM: %s"):format(vim.env.TERM_PROGRAM or ""))
  add(("TERM: %s"):format(vim.env.TERM or ""))
  add(("inside tmux: %s"):format(yesno(in_tmux)))
  add(("tmux version: %s"):format(tmux_version))
  add(("tmux allow-passthrough: %s"):format(tmux_passthrough))
  add(("ueberzugpp available: %s"):format(yesno(vim.fn.executable("ueberzugpp") == 1)))
  add(("wslview available: %s"):format(yesno(vim.fn.executable("wslview") == 1)))
  add(("imagemagick available: %s"):format(yesno(vim.fn.executable("magick") == 1 or vim.fn.executable("convert") == 1)))
  add(("molten image provider: %s"):format(vim.g.molten_image_provider or "unset"))
  add(("molten image location: %s"):format(vim.g.molten_image_location or "unset"))
  add(("molten auto image popup: %s"):format(yesno(vim.g.molten_auto_image_popup == true)))
  add(("molten open cmd: %s"):format(vim.g.molten_open_cmd or "default"))

  if info then
    add(("project root: %s"):format(info.root))
    add(("project .venv found: %s"):format(yesno(vim.fn.isdirectory(info.venv) == 1)))
    local ipykernel_ok = vim.system({ "uv", "run", "python", "-c", "import ipykernel" }, { cwd = info.root, text = true }):wait().code == 0
    local jupytext_ok = vim.system({ "uv", "run", "python", "-c", "import jupytext" }, { cwd = info.root, text = true }):wait().code == 0
    add(("project has ipykernel: %s"):format(yesno(ipykernel_ok)))
    add(("project has jupytext: %s"):format(yesno(jupytext_ok)))
  else
    add("project .venv found: no")
  end

  add("")
  if vim.g.molten_image_provider == "none" then
    add("Inline image backend is disabled in this config (molten_image_provider=none).")
    add("Use image popup (<leader>ji) and browser output (<leader>jb) instead.")
  elseif vim.g.molten_image_provider == "image.nvim" then
    add("Inline image backend is enabled via image.nvim.")
    add("This setup targets virtual inline images (molten_image_location=virt).")
  else
    add(("Inline image backend is enabled via %s."):format(vim.g.molten_image_provider))
  end

  if in_tmux and vim.g.molten_image_provider == "image.nvim" then
    local major, minor = tmux_version:match("^(%d+)%.(%d+)")
    major = tonumber(major)
    minor = tonumber(minor)
    if major and minor and (major < 3 or (major == 3 and minor < 6)) then
      add("tmux < 3.6 detected: SIXEL in Windows Terminal may show placeholder text.")
      add("Restart tmux with tmux 3.6a+ (brew tmux works) for reliable SIXEL rendering.")
    end
  end

  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "JupyterDoctor" })
end

vim.api.nvim_create_user_command("CreateKernel", function(opts)
  local info = jupyter_project_info(0)
  if not info then
    vim.notify("CreateKernel: .venv not found (searched upward)", vim.log.levels.ERROR)
    return
  end

  if vim.fn.executable("uv") ~= 1 then
    vim.notify("CreateKernel: `uv` not found on PATH", vim.log.levels.ERROR)
    return
  end

  local result = vim.system({
    "uv", "run", "python", "-m", "ipykernel", "install",
    "--user",
    "--name", info.kernel,
    "--display-name", ("Python (%s)"):format(info.project),
  }, { cwd = info.root, text = true }):wait()

  if result.code ~= 0 then
    local err = (result.stderr ~= "" and result.stderr)
      or (result.stdout ~= "" and result.stdout)
      or ("exit code " .. result.code)
    vim.notify("CreateKernel failed:\n" .. err, vim.log.levels.ERROR)
    return
  end

  vim.notify(("Kernel created: %s"):format(info.kernel), vim.log.levels.INFO)

  local auto_init = opts.bang or vim.g.create_kernel_auto_molten
  if auto_init then
    molten_init_project_kernel()
  end
end, {
  bang = true,
  desc = "Create Jupyter kernel from project .venv",
})

vim.api.nvim_create_user_command("JupytextExport", function()
  if vim.fn.executable("uv") ~= 1 then
    vim.notify("JupytextExport: `uv` not found on PATH", vim.log.levels.ERROR)
    return
  end

  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    vim.notify("JupytextExport: save this buffer first", vim.log.levels.ERROR)
    return
  end

  if vim.bo.modified then
    vim.cmd("write")
  end

  local info = jupyter_project_info(0)
  if not info then
    vim.notify("JupytextExport: .venv not found (searched upward)", vim.log.levels.ERROR)
    return
  end

  local out = file:gsub("%.py$", ".ipynb")
  if out == file then
    vim.notify("JupytextExport: current file is not a .py notebook", vim.log.levels.ERROR)
    return
  end

  local result = vim.system({
    "uv", "run", "jupytext",
    "--to", "ipynb",
    "--output", out,
    file,
  }, { cwd = info.root, text = true }):wait()

  if result.code ~= 0 then
    local err = (result.stderr ~= "" and result.stderr)
      or (result.stdout ~= "" and result.stdout)
      or ("exit code " .. result.code)
    vim.notify("JupytextExport failed:\n" .. err, vim.log.levels.ERROR)
    return
  end

  vim.notify("Exported notebook: " .. vim.fn.fnamemodify(out, ":."), vim.log.levels.INFO)
end, { desc = "Export current Jupytext .py as .ipynb" })

vim.api.nvim_create_user_command("JupyterRunAll", run_all_jupytext_cells, {
  desc = "Run all Jupytext code cells in buffer",
})

vim.api.nvim_create_user_command("JupyterDoctor", jupyter_doctor, {
  desc = "Diagnose Jupyter + Molten + image setup",
})

vim.api.nvim_create_autocmd("User", {
  pattern = "MoltenKernelReady",
  callback = function(e)
    local kernel_id = e.data and e.data.kernel_id
    if type(kernel_id) ~= "string" or kernel_id == "" then
      return
    end
    local bufnr = e.buf
    if type(bufnr) == "number" and bufnr > 0 and vim.api.nvim_buf_is_valid(bufnr) then
      vim.b[bufnr]._jupyter_kernel_id = kernel_id
    else
      vim.b._jupyter_kernel_id = kernel_id
    end
  end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "MoltenDeinitPost",
  callback = function(e)
    local bufnr = e.buf
    if type(bufnr) == "number" and bufnr > 0 and vim.api.nvim_buf_is_valid(bufnr) then
      vim.b[bufnr]._jupyter_kernel_id = nil
    else
      vim.b._jupyter_kernel_id = nil
    end
  end,
})

local M = {
  molten_init_project_kernel = molten_init_project_kernel,
  jump_jupytext_cell = jump_jupytext_cell,
  insert_jupytext_cell_below = insert_jupytext_cell_below,
  run_current_jupytext_cell = run_current_jupytext_cell,
  run_all_jupytext_cells = run_all_jupytext_cells,
  leave_molten_output_window = leave_molten_output_window,
}

return M
