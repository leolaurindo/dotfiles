local leader_help = {
  win = nil,
  buf = nil,
  on_key_ns = nil,
}

local leader_key = vim.g.mapleader or "\\"

local function close_leader_help()
  if leader_help.on_key_ns then
    vim.on_key(nil, leader_help.on_key_ns)
    leader_help.on_key_ns = nil
  end

  if leader_help.win and vim.api.nvim_win_is_valid(leader_help.win) then
    pcall(vim.api.nvim_win_close, leader_help.win, true)
  end

  leader_help.win = nil
  leader_help.buf = nil
end

local function collect_leader_family_entries(family)
  local prefix = leader_key .. family
  local entries = {}
  local seen = {}

  for _, map in ipairs(vim.api.nvim_get_keymap("n")) do
    local lhs = map.lhs or ""
    if vim.startswith(lhs, prefix) and lhs ~= prefix and lhs ~= prefix .. "?" then
      local suffix = lhs:sub(#prefix + 1)
      if suffix ~= "" then
        local desc = map.desc
        if not desc or desc == "" then
          desc = (map.rhs and map.rhs ~= "") and map.rhs or "(no desc)"
        end

        local dedupe = suffix .. string.char(31) .. desc
        if not seen[dedupe] then
          seen[dedupe] = true
          table.insert(entries, { suffix = suffix, desc = desc })
        end
      end
    end
  end

  table.sort(entries, function(a, b)
    return a.suffix < b.suffix
  end)

  return "<leader>" .. family, entries
end

local function show_leader_family_help(family)
  close_leader_help()

  local prefix, entries = collect_leader_family_entries(family)
  if #entries == 0 then
    vim.notify("No mappings under " .. prefix, vim.log.levels.INFO)
    return
  end

  local lines = { prefix .. " mappings" }
  for _, entry in ipairs(entries) do
    lines[#lines + 1] = string.format("  %-8s %s", entry.suffix, entry.desc)
  end

  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end
  width = math.min(math.max(width + 2, 26), math.floor(vim.o.columns * 0.6))
  local max_height = math.max(3, vim.o.lines - vim.o.cmdheight - 4)
  local height = math.min(#lines, max_height)
  local row = 1
  local col = math.max(0, vim.o.columns - width - 2)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  leader_help.buf = buf
  leader_help.win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = "single",
    noautocmd = true,
    focusable = false,
  })

  vim.wo[leader_help.win].wrap = false
  vim.wo[leader_help.win].winblend = 10

  local ns = vim.api.nvim_create_namespace("leader_family_help")
  leader_help.on_key_ns = ns
  vim.on_key(function()
    close_leader_help()
  end, ns)
end

local function register_leader_family_help_maps()
  -- NOTE for future agents:
  -- Keep this list explicit to avoid accidental single-key leader groups
  -- (like <leader>e) getting a `?` helper and to avoid startup map scanning.
  -- Add new families here when you intentionally introduce grouped mappings.
  local families = { "a", "d", "f", "g", "j", "q", "t", "u", "x" }

  for _, family in ipairs(families) do
    local _, entries = collect_leader_family_entries(family)
    local min_entries = family == "q" and 1 or 2
    if #entries >= min_entries then
      local lhs = leader_key .. family .. "?"
      if vim.fn.maparg(lhs, "n") == "" then
        vim.keymap.set("n", "<leader>" .. family .. "?", function()
          show_leader_family_help(family)
        end, {
          silent = true,
          desc = "Leader family help",
        })
      end
    end
  end
end

register_leader_family_help_maps()
