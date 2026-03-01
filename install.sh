#!/usr/bin/env bash

set -euo pipefail

log() {
  printf '[setup] %s\n' "$*"
}

warn() {
  printf '[setup][warn] %s\n' "$*" >&2
}

have() {
  command -v "$1" >/dev/null 2>&1
}

ensure_local_bin_on_path() {
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
  esac
}

as_root() {
  if [ "${EUID:-$(id -u)}" -eq 0 ]; then
    "$@"
  elif have sudo; then
    sudo "$@"
  else
    return 1
  fi
}

detect_package_manager() {
  if have apt-get; then
    echo apt
  elif have dnf; then
    echo dnf
  elif have pacman; then
    echo pacman
  elif have zypper; then
    echo zypper
  elif have brew; then
    echo brew
  else
    echo none
  fi
}

is_ubuntu() {
  [ -r /etc/os-release ] || return 1

  local id
  local id_like

  id="$(. /etc/os-release && printf '%s' "${ID:-}")"
  id_like="$(. /etc/os-release && printf '%s' "${ID_LIKE:-}")"

  [ "$id" = "ubuntu" ] || [[ "$id_like" == *ubuntu* ]]
}

package_installed() {
  local pm="$1"
  local pkg="$2"

  case "$pm" in
    apt)
      dpkg -s "$pkg" >/dev/null 2>&1
      ;;
    dnf|zypper)
      rpm -q "$pkg" >/dev/null 2>&1
      ;;
    pacman)
      pacman -Qi "$pkg" >/dev/null 2>&1
      ;;
    brew)
      brew list --formula "$pkg" >/dev/null 2>&1
      ;;
    *)
      return 1
      ;;
  esac
}

install_package() {
  local pm="$1"
  local pkg="$2"
  local required="$3"

  if package_installed "$pm" "$pkg"; then
    return 0
  fi

  log "Installing package: $pkg"
  case "$pm" in
    apt)
      as_root apt-get install -y "$pkg" >/dev/null || {
        if [ "$required" = "1" ]; then
          warn "Failed to install required package: $pkg"
          return 1
        fi
        warn "Skipping optional package: $pkg"
      }
      ;;
    dnf)
      as_root dnf install -y "$pkg" >/dev/null || {
        if [ "$required" = "1" ]; then
          warn "Failed to install required package: $pkg"
          return 1
        fi
        warn "Skipping optional package: $pkg"
      }
      ;;
    pacman)
      as_root pacman -S --needed --noconfirm "$pkg" >/dev/null || {
        if [ "$required" = "1" ]; then
          warn "Failed to install required package: $pkg"
          return 1
        fi
        warn "Skipping optional package: $pkg"
      }
      ;;
    zypper)
      as_root zypper --non-interactive install "$pkg" >/dev/null || {
        if [ "$required" = "1" ]; then
          warn "Failed to install required package: $pkg"
          return 1
        fi
        warn "Skipping optional package: $pkg"
      }
      ;;
    brew)
      brew install "$pkg" >/dev/null || {
        if [ "$required" = "1" ]; then
          warn "Failed to install required package: $pkg"
          return 1
        fi
        warn "Skipping optional package: $pkg"
      }
      ;;
    *)
      warn "No supported package manager found"
      return 1
      ;;
  esac
}

install_system_packages() {
  local pm
  pm="$(detect_package_manager)"

  if [ "$pm" = "none" ]; then
    warn "No supported package manager detected; skipping OS package install"
    return 0
  fi

  log "Using package manager: $pm"

  if [ "$pm" = "apt" ]; then
    if ! as_root true >/dev/null 2>&1; then
      warn "sudo/root is required for apt package installation"
      return 1
    fi
    log "Refreshing apt package index"
    as_root apt-get update -y >/dev/null
  fi

  local required_packages=()
  local optional_packages=()

  case "$pm" in
    apt)
      required_packages=(git curl ca-certificates tar gzip unzip xz-utils zsh tmux ripgrep fd-find python3 python3-venv python3-pip golang-go)
      optional_packages=(lazygit lf wslu imagemagick xclip wl-clipboard xsel nodejs npm cargo clang clangd golangci-lint ueberzugpp build-essential)
      ;;
    dnf)
      required_packages=(git curl ca-certificates tar gzip unzip xz zsh tmux ripgrep fd-find python3 python3-pip golang)
      optional_packages=(lazygit lf ImageMagick xclip wl-clipboard nodejs npm cargo clang clang-tools-extra golangci-lint ueberzugpp gcc gcc-c++ make)
      ;;
    pacman)
      required_packages=(git curl ca-certificates tar gzip unzip xz zsh tmux ripgrep fd python python-pip go)
      optional_packages=(lazygit lf imagemagick xclip wl-clipboard xsel nodejs npm rust clang base-devel)
      ;;
    zypper)
      required_packages=(git curl ca-certificates tar gzip unzip xz zsh tmux ripgrep fd python3 python3-pip go)
      optional_packages=(lazygit lf ImageMagick xclip wl-clipboard nodejs npm rust clang-tools gcc gcc-c++ make)
      ;;
    brew)
      required_packages=(git curl ca-certificates gnu-tar gzip unzip xz zsh tmux ripgrep fd python go)
      optional_packages=(lazygit lf imagemagick node rust)
      ;;
  esac

  for pkg in "${required_packages[@]}"; do
    install_package "$pm" "$pkg" 1
  done

  for pkg in "${optional_packages[@]}"; do
    install_package "$pm" "$pkg" 0 || true
  done
}

install_go_tool() {
  local binary="$1"
  local module="$2"

  if have "$binary"; then
    return
  fi

  if ! have go; then
    warn "Go is not installed; cannot install Go tool: $binary"
    return
  fi

  local gopath
  gopath="$(go env GOPATH 2>/dev/null || true)"
  if [ -z "$gopath" ]; then
    gopath="$HOME/go"
  fi

  log "Installing Go tool: $binary"
  GOBIN="$gopath/bin" go install "$module@latest" >/dev/null || warn "Failed installing Go tool: $binary"
}

install_go_tools() {
  if ! have go; then
    warn "Go not found; skipping Go tool installation"
    return
  fi

  install_go_tool gopls golang.org/x/tools/gopls
  install_go_tool dlv github.com/go-delve/delve/cmd/dlv
  install_go_tool golangci-lint github.com/golangci/golangci-lint/cmd/golangci-lint
  install_go_tool gixt github.com/leolaurindo/gixt/cmd/gixt
}

install_gh_cli() {
  if have gh; then
    return
  fi

  local pm
  pm="$(detect_package_manager)"

  if [ "$pm" = "apt" ] && is_ubuntu; then
    log "Installing GitHub CLI from official apt repository (Ubuntu preferred)"

    if ! as_root true >/dev/null 2>&1; then
      warn "sudo/root is required for preferred Ubuntu gh install; falling back"
    else
      if ! have wget; then
        log "Installing wget prerequisite for GitHub CLI"
        as_root apt-get update -y >/dev/null || true
        as_root apt-get install -y wget >/dev/null || warn "Failed to install wget prerequisite"
      fi

      if have wget; then
        local out
        out="$(mktemp)"

        if wget -nv -O"$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg >/dev/null 2>&1; then
          as_root mkdir -p -m 755 /etc/apt/keyrings
          as_root tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null < "$out"
          as_root chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
          as_root mkdir -p -m 755 /etc/apt/sources.list.d
          printf 'deb [arch=%s signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\n' "$(dpkg --print-architecture)" | as_root tee /etc/apt/sources.list.d/github-cli.list >/dev/null
          as_root apt-get update -y >/dev/null
          as_root apt-get install -y gh >/dev/null || warn "Failed to install gh from official apt repository"
        else
          warn "Failed to download GitHub CLI apt keyring; falling back"
        fi

        rm -f "$out"
      fi
    fi

    if have gh; then
      return
    fi
  fi

  local candidate_pkgs=()
  case "$pm" in
    apt)
      candidate_pkgs=(gh github-cli)
      ;;
    dnf)
      candidate_pkgs=(gh github-cli)
      ;;
    pacman)
      candidate_pkgs=(github-cli gh)
      ;;
    zypper)
      candidate_pkgs=(gh github-cli)
      ;;
    brew)
      candidate_pkgs=(gh)
      ;;
  esac

  if [ "${#candidate_pkgs[@]}" -gt 0 ]; then
    for pkg in "${candidate_pkgs[@]}"; do
      install_package "$pm" "$pkg" 0 || true
      if have gh; then
        break
      fi
    done
  fi

  if ! have gh && have go; then
    log "Installing GitHub CLI (gh) via Go fallback"
    install_go_tool gh github.com/cli/cli/v2/cmd/gh
  fi

  if ! have gh; then
    warn "GitHub CLI (gh) is not installed. Install it manually for your distro."
  fi
}

install_latest_lazygit() {
  if have lazygit; then
    return
  fi

  if ! have curl; then
    warn "curl is required to install lazygit"
    return
  fi

  local os
  local arch
  os="$(uname -s)"
  arch="$(uname -m)"

  if [ "$os" != "Linux" ]; then
    warn "Automatic lazygit fallback install is currently Linux-only"
    return
  fi

  case "$arch" in
    x86_64|amd64) arch="x86_64" ;;
    aarch64|arm64) arch="arm64" ;;
    *)
      warn "Unsupported architecture for lazygit fallback: $arch"
      return
      ;;
  esac

  local version
  version="$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest | sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p' | head -n1)"

  if [ -z "$version" ]; then
    warn "Could not resolve latest lazygit version"
    return
  fi

  local tmpdir
  tmpdir="$(mktemp -d)"
  local archive="lazygit_${version}_Linux_${arch}.tar.gz"
  local url="https://github.com/jesseduffield/lazygit/releases/download/v${version}/${archive}"

  log "Installing lazygit v${version} from GitHub releases"
  curl -fL "$url" -o "$tmpdir/$archive" || {
    warn "Failed downloading lazygit release archive"
    rm -rf "$tmpdir"
    return
  }

  tar -xzf "$tmpdir/$archive" -C "$tmpdir" || {
    warn "Failed extracting lazygit archive"
    rm -rf "$tmpdir"
    return
  }

  mkdir -p "$HOME/.local/bin"
  install -m 0755 "$tmpdir/lazygit" "$HOME/.local/bin/lazygit" || {
    warn "Failed installing lazygit binary"
    rm -rf "$tmpdir"
    return
  }

  rm -rf "$tmpdir"
}

install_latest_neovim() {
  if ! have curl; then
    warn "curl is required to install latest Neovim"
    return
  fi

  local os
  local arch
  os="$(uname -s)"
  arch="$(uname -m)"

  local asset=""
  case "$os" in
    Linux)
      case "$arch" in
        x86_64|amd64) asset="nvim-linux-x86_64.tar.gz" ;;
        aarch64|arm64) asset="nvim-linux-arm64.tar.gz" ;;
        *)
          warn "Unsupported architecture for Neovim auto-install: $arch"
          return
          ;;
      esac
      ;;
    Darwin)
      case "$arch" in
        x86_64|amd64) asset="nvim-macos-x86_64.tar.gz" ;;
        arm64) asset="nvim-macos-arm64.tar.gz" ;;
        *)
          warn "Unsupported architecture for Neovim auto-install: $arch"
          return
          ;;
      esac
      ;;
    *)
      warn "Automatic Neovim install not supported on OS: $os"
      return
      ;;
  esac

  local tmpdir
  tmpdir="$(mktemp -d)"
  local url="https://github.com/neovim/neovim/releases/latest/download/${asset}"
  local extract_dir="${asset%.tar.gz}"

  log "Installing latest Neovim from official release"
  curl -fL "$url" -o "$tmpdir/nvim.tar.gz" || {
    warn "Failed downloading latest Neovim archive"
    rm -rf "$tmpdir"
    return
  }

  tar -xzf "$tmpdir/nvim.tar.gz" -C "$tmpdir" || {
    warn "Failed extracting Neovim archive"
    rm -rf "$tmpdir"
    return
  }

  mkdir -p "$HOME/.local/opt" "$HOME/.local/bin"
  rm -rf "$HOME/.local/opt/nvim"
  mv "$tmpdir/$extract_dir" "$HOME/.local/opt/nvim" || {
    warn "Failed moving Neovim into ~/.local/opt/nvim"
    rm -rf "$tmpdir"
    return
  }

  ln -sf "$HOME/.local/opt/nvim/bin/nvim" "$HOME/.local/bin/nvim"
  rm -rf "$tmpdir"
}

ensure_fd_alias() {
  if ! have fd && have fdfind; then
    log "Creating local fd -> fdfind alias"
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  fi
}

install_uv() {
  local env_file="$HOME/.local/bin/env"
  if [ -f "$env_file" ]; then
    # shellcheck disable=SC1090
    . "$env_file"
  fi

  if have uv; then
    return
  fi

  if ! have curl; then
    warn "curl is required to install uv"
    return
  fi

  log "Installing uv"
  curl -LsSf https://astral.sh/uv/install.sh | sh

  if [ -f "$env_file" ]; then
    # shellcheck disable=SC1090
    . "$env_file"
  fi
}

install_opencode_cli() {
  if ! have curl; then
    warn "curl is required to install opencode CLI"
    return
  fi

  log "Installing opencode CLI via official installer"
  curl -fsSL https://opencode.ai/install | bash >/dev/null || {
    warn "Failed to install opencode CLI"
    return
  }

  local opencode_bin="$HOME/.opencode/bin/opencode"
  if [ ! -x "$opencode_bin" ]; then
    warn "Official installer completed but $opencode_bin was not found"
  fi
}

check_unmanaged_tools() {
  if [ ! -x "/home/linuxbrew/.linuxbrew/bin/brew" ] && ! have brew; then
    warn "brew is not installed. Your zsh config currently sources Linuxbrew shellenv."
  fi

  if [ ! -d "$HOME/.opencode/bin" ] && ! have opencode; then
    warn "opencode CLI was not found (~/.opencode/bin). Install it separately if you use :Opencode in Neovim."
  fi
}

install_oh_my_zsh() {
  local omz_dir="$HOME/.oh-my-zsh"

  if [ -s "$omz_dir/oh-my-zsh.sh" ]; then
    return
  fi

  if ! have git; then
    warn "git is required to install oh-my-zsh"
    return
  fi

  log "Installing oh-my-zsh"

  if [ ! -d "$omz_dir" ]; then
    git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh "$omz_dir" >/dev/null
    return
  fi

  local tmpdir
  tmpdir="$(mktemp -d)"
  git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh "$tmpdir/ohmyzsh" >/dev/null || {
    warn "Failed cloning oh-my-zsh"
    rm -rf "$tmpdir"
    return
  }

  cp -a "$tmpdir/ohmyzsh/." "$omz_dir/"
  rm -rf "$tmpdir"
}

install_zsh_autosuggestions() {
  local target="$HOME/.zsh/zsh-autosuggestions"
  mkdir -p "$HOME/.zsh"

  if [ -d "$target/.git" ]; then
    log "Updating zsh-autosuggestions"
    git -C "$target" pull --ff-only >/dev/null || warn "Could not update zsh-autosuggestions"
    return
  fi

  log "Installing zsh-autosuggestions"
  git clone https://github.com/zsh-users/zsh-autosuggestions "$target" >/dev/null
}

install_tpm() {
  local target="$HOME/.tmux/plugins/tpm"
  mkdir -p "$HOME/.tmux/plugins"

  if [ -d "$target/.git" ]; then
    log "Updating tmux plugin manager (TPM)"
    git -C "$target" pull --ff-only >/dev/null || warn "Could not update TPM"
    return
  fi

  log "Installing tmux plugin manager (TPM)"
  git clone https://github.com/tmux-plugins/tpm "$target" >/dev/null
}

install_nvm_and_node() {
  local nvm_dir="$HOME/.nvm"
  if [ ! -s "$nvm_dir/nvm.sh" ]; then
    if ! have curl; then
      warn "curl is required to install nvm"
      return
    fi
    log "Installing nvm"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash >/dev/null
  fi

  if [ -s "$nvm_dir/nvm.sh" ]; then
    # shellcheck disable=SC1090
    . "$nvm_dir/nvm.sh"
    log "Installing Node.js LTS via nvm"
    nvm install --lts >/dev/null
    nvm alias default 'lts/*' >/dev/null
  fi
}

setup_nvim_python_host() {
  if ! have uv; then
    warn "uv is not available; skipping Neovim host python setup"
    return
  fi

  local env_file="$HOME/.local/bin/env"
  if [ -f "$env_file" ]; then
    # shellcheck disable=SC1090
    . "$env_file"
  fi

  local host_venv="$HOME/.venvs/nvim"
  local host_python="$host_venv/bin/python"

  log "Creating Neovim host virtual environment"
  uv venv "$host_venv" >/dev/null

  log "Installing Neovim host python packages"
  uv pip install --python "$host_python" --upgrade pynvim jupyter_client nbformat pillow ipykernel >/dev/null
}

install_tmux_plugins() {
  local installer="$HOME/.tmux/plugins/tpm/bin/install_plugins"

  if ! have tmux; then
    warn "tmux not found; skipping TPM plugin install"
    return
  fi

  if [ ! -x "$installer" ]; then
    warn "TPM installer not found; skipping tmux plugin install"
    return
  fi

  log "Installing tmux plugins via TPM"
  tmux start-server >/dev/null 2>&1 || true
  "$installer" >/dev/null || warn "TPM plugin installation reported an error"
}

sync_nvim() {
  if ! have nvim; then
    warn "Neovim not found; skipping Lazy sync"
    return
  fi

  log "Syncing Neovim plugins with Lazy"
  nvim --headless "+Lazy! sync" +qa >/dev/null || warn "Lazy sync failed; run ':Lazy sync' manually"

  log "Updating Neovim remote plugins"
  nvim --headless "+UpdateRemotePlugins" +qa >/dev/null || warn "UpdateRemotePlugins failed; run it manually"
}

main() {
  log "Starting dotfiles bootstrap"

  ensure_local_bin_on_path

  install_system_packages
  install_gh_cli
  install_latest_lazygit
  install_latest_neovim
  ensure_fd_alias

  install_uv
  install_opencode_cli
  check_unmanaged_tools
  install_oh_my_zsh
  install_zsh_autosuggestions
  install_tpm
  install_nvm_and_node

  setup_nvim_python_host
  install_go_tools
  install_tmux_plugins
  sync_nvim

  log "Bootstrap complete"
  log "If this is a fresh machine: apply your chezmoi source with: chezmoi apply and run install_private.sh --ssh"
  
}

main "$@"
