set -euo pipefail

pip3 install -r requirements.txt

# Update agents to latest version (runs on every rebuild, bypassing image cache)
echo "Updating Claude Code..."
claude update || true

echo "Updating Codex CLI..."
curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh || true

# --- Persistent data volume ---
# A single Docker volume at ~/.data/ stores all agent data and shell history
# to survive container rebuilds.
DATA="$HOME/.data"
sudo chown "$(id -u):$(id -g)" "$DATA"
mkdir -p "$DATA/claude" "$DATA/shell-history"

# --- Symlink agent data directories into the persistent volume ---
for name in claude codex; do
    vol_dir="$DATA/$name"
    home_dir="$HOME/.$name"
    if [ -d "$home_dir" ] && [ ! -L "$home_dir" ]; then
        if [ -z "$(ls -A "$vol_dir" 2>/dev/null)" ]; then
            cp -a "$home_dir/." "$vol_dir/"
        fi
        rm -rf "$home_dir"
    fi
    ln -sfn "$vol_dir" "$home_dir"
done

# --- Persist Claude Code's top-level config file (~/.claude.json) ---
# Claude Code stores account/session-level state (MCP servers, per-project
# trust decisions, onboarding flags) in ~/.claude.json directly in $HOME,
# separate from the ~/.claude/ directory handled above. It needs the same
# copy-once-then-symlink treatment or it silently resets on every rebuild.
CLAUDE_JSON_VOL="$DATA/claude.json"
if [ -f "$HOME/.claude.json" ] && [ ! -L "$HOME/.claude.json" ]; then
    [ -f "$CLAUDE_JSON_VOL" ] || cp -a "$HOME/.claude.json" "$CLAUDE_JSON_VOL"
    rm -f "$HOME/.claude.json"
fi
ln -sfn "$CLAUDE_JSON_VOL" "$HOME/.claude.json"

# --- GitHub CLI auth (~/.config/gh) ---
mkdir -p "$DATA/gh"
if [ -d "$HOME/.config/gh" ] && [ ! -L "$HOME/.config/gh" ]; then
    if [ -z "$(ls -A "$DATA/gh" 2>/dev/null)" ]; then
        cp -a "$HOME/.config/gh/." "$DATA/gh/"
    fi
    rm -rf "$HOME/.config/gh"
fi
mkdir -p "$HOME/.config"
ln -sfn "$DATA/gh" "$HOME/.config/gh"

# Claude auto mode
CLAUDE_USER_SETTINGS="$HOME/.claude/settings.json"
[ -f "$CLAUDE_USER_SETTINGS" ] || echo '{}' > "$CLAUDE_USER_SETTINGS"
if ! jq -e '.permissions.defaultMode' "$CLAUDE_USER_SETTINGS" &>/dev/null; then
    jq '.permissions = ((.permissions // {}) + { defaultMode: "auto" })' \
        "$CLAUDE_USER_SETTINGS" > "$CLAUDE_USER_SETTINGS.tmp" \
        && mv "$CLAUDE_USER_SETTINGS.tmp" "$CLAUDE_USER_SETTINGS"
fi
