-- === Winbar: navic breadcrumbs ===
-- Always visible winbar with smart shortening
_G._navic_winbar = function()
  local ok, navic = pcall(require, "nvim-navic")
  if not ok then
    return " "  -- Return space to keep winbar visible
  end
  
  local location = navic.get_location()
  if not location or location == "" then
    return " "  -- Return space to keep winbar visible
  end
  
  -- Winbar has more space - use 80% of window width for breadcrumbs
  local win_width = vim.api.nvim_win_get_width(0)
  local max_width = math.floor(win_width * 0.8)
  
  -- If breadcrumbs fit, show them
  if #location <= max_width then
    return location
  end
  
  -- Shorten from the beginning, keeping the end (most specific parts)
  -- Prioritize lower level (more specific) elements
  local separator = " > "
  local parts = vim.split(location, separator, { plain = true })
  
  -- Start from the end and add parts until we exceed max width
  local result = ""
  for i = #parts, 1, -1 do
    local part = parts[i]
    local new_result = part .. (result == "" and "" or separator .. result)
    
    if #new_result + 3 <= max_width then  -- +3 for "…" prefix
      result = new_result
    else
      break
    end
  end
  
  -- Add ellipsis if we truncated
  if result ~= location then
    result = "…" .. separator .. result
  end
  
  return result
end
vim.o.winbar = "%{%v:lua._navic_winbar()%}"

-- === Theme picker ===
vim.api.nvim_create_user_command("DashboardSearchCwd", function()
  local ok, snacks = pcall(require, "snacks")
  if not ok or not snacks or not snacks.picker then
    return
  end

  snacks.picker.files({
    cwd = vim.fn.getcwd(),
    hidden = false,
    ignored = false,
    focus = "input",
    layout = {
      preset = "select",
      layout = {
        width = 0.7,
        min_width = 70,
        max_width = 120,
        height = 0.36,
      },
    },
  })
end, { desc = "Dashboard search files in current working directory" })

vim.api.nvim_create_user_command("Theme", function()
  require("snacks").picker.colorschemes()
end, { desc = "Colorscheme picker" })

local onedark_styles = { "dark", "darker", "cool", "deep", "warm", "warmer", "light" }

vim.api.nvim_create_user_command("OneDark", function(opts)
  local function apply(style)
    local ok = pcall(vim.cmd.colorscheme, "onedark-" .. style)
    if ok then
      return
    end

    local loaded = pcall(function()
      require("lazy").load({ plugins = { "onedark.nvim" } })
    end)
    if not loaded then
      vim.notify("Failed to load onedark.nvim", vim.log.levels.ERROR)
      return
    end

    local ok_theme, onedark = pcall(require, "onedark")
    if not ok_theme then
      vim.notify("onedark.nvim is not available", vim.log.levels.ERROR)
      return
    end

    vim.o.background = style == "light" and "light" or "dark"
    onedark.setup({ style = style })
    onedark.load()
  end

  if opts.args == "" then
    vim.ui.select(onedark_styles, { prompt = "OneDark style" }, function(choice)
      if choice then
        apply(choice)
      end
    end)
    return
  end

  local style = string.lower(vim.trim(opts.args))
  if not vim.tbl_contains(onedark_styles, style) then
    vim.notify(("Invalid OneDark style: %s"):format(opts.args), vim.log.levels.ERROR)
    return
  end

  apply(style)
end, {
  nargs = "?",
  complete = function()
    return onedark_styles
  end,
  desc = "Apply OneDark style",
})

vim.api.nvim_create_user_command("Maps", function()
  Snacks.picker.keymaps()
end, { desc = "Keymaps picker" })



-- === Outline commands ===
vim.api.nvim_create_user_command("Outline", function()
  vim.cmd("AerialToggle")
end, { desc = "Toggle outline sidebar" })

vim.api.nvim_create_user_command("OutlineFull", function()
  vim.cmd("AerialNavToggle")
end, { desc = "Toggle outline navigation window" })

-- === Typewriter mode ===
-- :TW toggles typewriter mode (auto-center cursor every time cursor moves)
local typewriter_enabled = false

vim.api.nvim_create_user_command("TW", function()
  local ok, stay_centered = pcall(require, "stay-centered")
  if ok then
    stay_centered.toggle()
    typewriter_enabled = not typewriter_enabled
    print("Typewriter mode: " .. (typewriter_enabled and "ON" or "OFF"))
  else
    print("Error: stay-centered.nvim not loaded")
  end
end, { desc = "Toggle typewriter mode" })


-- === Theme tweaks ===
local tokyonight_linenr_state = {
  applied = false,
  cursorline = nil,
  cursorlineopt = nil,
}

local function apply_tokyonight_line_numbers()
  if vim.g.colors_name ~= "tokyonight-night" then
    if tokyonight_linenr_state.applied then
      if tokyonight_linenr_state.cursorline ~= nil then
        vim.opt.cursorline = tokyonight_linenr_state.cursorline
      end
      if tokyonight_linenr_state.cursorlineopt ~= nil then
        vim.opt.cursorlineopt = tokyonight_linenr_state.cursorlineopt
      end
      tokyonight_linenr_state.applied = false
    end
    return
  end

  if not tokyonight_linenr_state.applied then
    tokyonight_linenr_state.cursorline = vim.opt.cursorline:get()
    tokyonight_linenr_state.cursorlineopt = vim.opt.cursorlineopt:get()
  end

  vim.opt.cursorline = true
  vim.opt.cursorlineopt = "number"
  tokyonight_linenr_state.applied = true

  local ok, tokyonight = pcall(require, "tokyonight.colors")
  if not ok then
    return
  end

  local colors = tokyonight.setup({ style = "night" })
  local line_nr = colors.comment or colors.fg_gutter or colors.fg_dark
  local cursor_nr = colors.orange or colors.fg

  vim.api.nvim_set_hl(0, "LineNr", { fg = line_nr })
  vim.api.nvim_set_hl(0, "CursorLineNr", { fg = cursor_nr })

  if pcall(vim.api.nvim_get_hl, 0, { name = "LineNrAbove" }) then
    vim.api.nvim_set_hl(0, "LineNrAbove", { fg = line_nr })
  end
  if pcall(vim.api.nvim_get_hl, 0, { name = "LineNrBelow" }) then
    vim.api.nvim_set_hl(0, "LineNrBelow", { fg = line_nr })
  end
end

local linenr_group = vim.api.nvim_create_augroup("TokyonightLineNr", { clear = true })
vim.api.nvim_create_autocmd("ColorScheme", {
  group = linenr_group,
  callback = apply_tokyonight_line_numbers,
})

-- === Colorscheme ===
-- default theme: tokyonight (same as your current)
vim.cmd.colorscheme("tokyonight-night")
-- vim.cmd.colorscheme("catppuccin-mocha") -- optional: quick switch target
apply_tokyonight_line_numbers()
