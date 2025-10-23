#!/bin/bash
# Function to log messages to terminal
log_message() {
    echo "$(date -u) ✓ $1"
}

# Function to set up global hooks
setup_hooks() {
    log_message "Setting up global git hooks..."
    mkdir -p "$HOOKS_DIR"
    git config --global core.hooksPath "$HOOKS_DIR"
}

# Function to install the post-commit hook
install_post_commit_hook() {
    log_message "Installing post-commit hook..."
    cat > "$HOOKS_DIR/post-commit" <<EOF
#!/bin/sh
# Mirror commit activity to GitHub safely
set -eu

REPO="$MIRROR_REPO"
LOCAL_MIRROR="$LOCAL_MIRROR"
BRANCH="$BRANCH"

# Function to log messages with timestamp
log() {
    echo "\$(date '+%H:%M:%S') [activity-log] \$1" >&2
}

# 0) Re-entrancy guard: if we're already logging, do nothing.
if [ "\${ACTIVITY_LOGGING:-}" = "1" ]; then
    exit 0
fi

# 1) Skip when the commit happens inside the activity-log repository itself.
TOP="\$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
# Compare absolute path to the configured local mirror directory
if [ "\$TOP" = "\$LOCAL_MIRROR" ]; then
    exit 0
fi
# Fallback: skip by repo name to be resilient if paths differ
if [ "\$(basename "\$TOP")" = "activity-log" ]; then
    exit 0
fi

# 2) Skip silently if no local mirror repo exists
if [ ! -d "\$LOCAL_MIRROR/.git" ]; then
    exit 0
fi

# 3) Create a message and write an empty commit to the mirror repo with hooks disabled there.
REPO_NAME="\$(basename "\$TOP")"
USER_EMAIL="\$(git config user.email)"
MSG="activity: \$(date -u '+%Y-%m-%d %H:%M:%S UTC') by \$USER_EMAIL"

log "Logging activity from \$REPO_NAME"

(
cd "\$LOCAL_MIRROR" || exit 0
git pull -q origin "\$BRANCH" || true
# Disable hooks for this commit to avoid recursion, and set a guard env var as well.
if ACTIVITY_LOGGING=1 git -c core.hooksPath=/dev/null commit --allow-empty -m "\$MSG" >/dev/null 2>&1; then
    if git push -q origin "\$BRANCH" 2>/dev/null; then
        log "✓ Activity logged successfully"
    else
        log "⚠ Failed to push activity log"
    fi
else
    log "⚠ Failed to create activity commit"
fi
)
EOF
    chmod +x "$HOOKS_DIR/post-commit"
}

# Function to clone the mirror repository
clone_mirror_repo() {
    # Skip cloning - we're already IN the mirror repository
    # This function is kept for backward compatibility but does nothing
    log_message "Mirror repository is current directory: $LOCAL_MIRROR"
    
    # Verify we're in a git repository
    if [ ! -d "$LOCAL_MIRROR/.git" ]; then
        log_message "ERROR: $LOCAL_MIRROR is not a git repository!"
        echo "ERROR: $LOCAL_MIRROR is not a git repository!" >&2
        return 1
    fi
}

# Main setup process
main() {
    log_message "Starting setup process..."
    setup_hooks
    install_post_commit_hook
    clone_mirror_repo
    log_message "Setup process complete!"
}

# Setup Hook Script for Activity Log
set -e

# Load configuration safely
CONFIG_FILE="./config.ini"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Parse config file safely (skip comments and empty lines)
while IFS='=' read -r key value; do
    # Skip comments and empty lines
    case "$key" in
        '#'* | '') continue ;;
    esac
    # Remove leading/trailing whitespace
    key=$(echo "$key" | xargs)
    value=$(echo "$value" | xargs)
    # Expand $HOME and other variables in the value
    eval "export $key=\"$value\""
done < "$CONFIG_FILE"

# Set defaults if not specified in config
HOOKS_DIR="${HOOKS_DIR:-$HOME/.githooks}"
LOCAL_MIRROR="${LOCAL_MIRROR:-$HOME/.activity-mirror}"

main