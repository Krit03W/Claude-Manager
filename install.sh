#!/usr/bin/env bash
# install.sh — link the worker commands into ~/.local/bin and set up Claude Code.
# Safe to re-run. Existing files are backed up as *.bak-<timestamp>.
set -euo pipefail
repo="$(cd "$(dirname "$0")" && pwd)"
bin_dir="${BIN_DIR:-$HOME/.local/bin}"
ts="$(date +%Y%m%d%H%M%S)"
mkdir -p "$bin_dir"

say() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m  %s\n' "$*"; }

say "Checking dependencies"
for c in claude jq perl; do command -v "$c" >/dev/null || warn "missing: $c"; done
command -v agy >/dev/null || warn "agy (Antigravity CLI) not found — agyw will not work until it is installed and logged in"

say "Linking commands into $bin_dir"
for f in "$repo"/bin/*; do
  name="$(basename "$f")"; dest="$bin_dir/$name"
  chmod +x "$f"
  if [[ -e "$dest" && ! -L "$dest" ]]; then mv "$dest" "$dest.bak-$ts"; warn "backed up $dest"; fi
  ln -sfn "$f" "$dest"; echo "    $name -> $f"
done
case ":$PATH:" in *":$bin_dir:"*) ;; *) warn "$bin_dir is not on PATH — add it to your shell profile";; esac

say "Credentials"
if [[ -f "$repo/.env" ]]; then echo "    .env exists (not touched)"
else cp "$repo/.env.example" "$repo/.env"; chmod 600 "$repo/.env"; warn "created $repo/.env — fill it in, then run scripts/ds-check.sh"; fi

say "Claude Code instructions (~/.claude/CLAUDE.md)"
mkdir -p "$HOME/.claude"
marker="<!-- claude-manager:workers -->"
if grep -qF "$marker" "$HOME/.claude/CLAUDE.md" 2>/dev/null; then
  echo "    worker section already present (edit it by hand to update)"
else
  { echo; echo "$marker"; cat "$repo/templates/CLAUDE.md"; } >> "$HOME/.claude/CLAUDE.md"
  echo "    appended worker section"
fi

say "Done. One manual step left:"
cat <<'EOF'
    So Claude can call the workers without asking every time, add these to
    "permissions" -> "allow" in ~/.claude/settings.json:

      "Bash(ds *)", "Bash(agyw *)", "Bash(ds-log*)", "Bash(agyw-log*)"
EOF
