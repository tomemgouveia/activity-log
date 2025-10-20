#!/bin/bash
# Function to log messages
log_message() {
    echo "$(date -u) - $1" >> "$LOG_FILE"
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

REPO="$MIRROR_REPO"
LOCAL_MIRROR="$LOCAL_MIRROR"
BRANCH="$BRANCH"

# Skip silently if no local mirror repo exists
if [ ! -d "\$LOCAL_MIRROR/.git" ]; then
    log_message "Local mirror repository does not exist, please clone first"
    exit 0
fi

MSG="activity: \$(date -u +"%Y-%m-%dT%H:%M:%SZ") from \$(basename \"\$(git rev-parse --show-toplevel 2>/dev/null)\")"

(
cd "\$LOCAL_MIRROR" || exit 0
git pull origin "\$BRANCH" >/dev/null 2>&1 || true
git commit --allow-empty -m "\$MSG" >/dev/null 2>&1 || exit 0
git push origin "\$BRANCH" >/dev/null 2>&1 || true
)
EOF
    chmod +x "$HOOKS_DIR/post-commit"
}

# Function to clone the mirror repository
clone_mirror_repo() {
    if [ ! -d "$LOCAL_MIRROR/.git" ]; then
        log_message "Cloning the mirror repository..."
        git clone "$MIRROR_REPO" "$LOCAL_MIRROR"
    else
        log_message "Mirror repository already exists."
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

# Load configuration
CONFIG_FILE="./config.ini"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Configuration file not found: $CONFIG_FILE"
    # exit 1
else
    source <(grep = "$CONFIG_FILE" | sed 's/ *= */=/g') # Load config variables
    # Default values if not specified in config
    HOOKS_DIR="${HOOKS_DIR:-$HOME/.githooks}"
    LOCAL_MIRROR="${LOCAL_MIRROR:-$HOME/.activity-mirror}"
    LOG_FILE="${LOG_FILE:-$HOME/activity-log.log}"
    
    main
fi