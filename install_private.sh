#!/usr/bin/env sh
set -eu

repo="$HOME/dotfiles-private"
chez="$HOME/.local/share/chezmoi"
repo_name="leolaurindo/dotfiles-private"

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) is not installed."
  echo "  Windows (winget): winget install GitHub.cli"
  echo "  Linux: https://github.com/cli/cli/blob/trunk/docs/install_linux.md#debian"
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "GitHub CLI is not authenticated."
  echo "Run: gh auth login. Then re-run this script."
  exit 1
fi

if [ -d "$repo/.git" ]; then
  echo "Repo already exists at $repo, skipping clone."
else
  gh repo clone "$repo_name" "$repo"


fi

mkdir -p \
  "$chez" \
  "$chez/dot_config/private_jrnl" \
  "$chez/dot_config/opencode"

cp "$repo/dot_gitconfig" "$chez/dot_gitconfig"
cp -R "$repo/dot_config/private_jrnl/." "$chez/dot_config/private_jrnl/"
cp -R "$repo/dot_config/opencode/." "$chez/dot_config/opencode/"

if [ "${1:-}" = "--ssh" ]; then
  bash "$repo/setup_ssh.sh"
fi

# cleanup

rm -rf "$repo"
