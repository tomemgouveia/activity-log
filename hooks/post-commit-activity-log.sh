#!/bin/sh
# Mirror commit activity to GitHub safely
# This hook logs commit activity to a central activity-log repository
set -eu

# Load configuration from config file
CONFIG_FILE="$HOME/.config/activity-log-config.ini"

# Initialize variables with defaults
REPO=""
LOCAL_MIRROR="$HOME/.activity-mirror"
BRANCH="main"

if [ -f "$CONFIG_FILE" ]; then
    # Parse config file safely (skip comments and empty lines)
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        case "$key" in
            '#'* | '') continue ;;
        esac
        # Remove leading/trailing whitespace
        key=$(echo "$key" | xargs 2>/dev/null || echo "$key")
        value=$(echo "$value" | xargs 2>/dev/null || echo "$value")
        # Set the variable (do not export)
        case "$key" in
            ACTIVITY_LOG_REPO) REPO="$value" ;;
            ACTIVITY_LOG_MIRROR) LOCAL_MIRROR="$value" ;;
            ACTIVITY_LOG_BRANCH) BRANCH="$value" ;;
        esac
    done < "$CONFIG_FILE"
fi

# Exit silently if no repository is configured
if [ -z "$REPO" ]; then
    exit 0
fi

# Function to log messages with timestamp
log() {
    echo "$(date '+%H:%M:%S') [activity-log] $1" >&2
}

# 0) Re-entrancy guard: if we're already logging, do nothing.
if [ "${ACTIVITY_LOGGING:-}" = "1" ]; then
    exit 0
fi

# 1) Skip when the commit happens inside the activity-log repository itself.
TOP="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
# Compare absolute path to the configured local mirror directory
if [ "$TOP" = "$LOCAL_MIRROR" ]; then
    exit 0
fi
# Fallback: skip by repo name to be resilient if paths differ
if [ "$(basename "$TOP")" = "activity-log" ]; then
    exit 0
fi

# 2) Skip silently if no local mirror repo exists
if [ ! -d "$LOCAL_MIRROR/.git" ]; then
    exit 0
fi

# 3) Create a message and write an empty commit to the mirror repo with hooks disabled there.
REPO_NAME="$(basename "$TOP")"
USER_EMAIL="$(git config user.email)"
MSG="activity: $(date -u '+%Y-%m-%d %H:%M:%S UTC') by $USER_EMAIL"

log "Logging activity from $REPO_NAME"

(
cd "$LOCAL_MIRROR" || exit 0
git pull -q origin "$BRANCH" || true
# Disable hooks for this commit to avoid recursion, and set a guard env var as well.
if ACTIVITY_LOGGING=1 git -c core.hooksPath=/dev/null commit --allow-empty -m "$MSG" >/dev/null 2>&1; then
    if git push -q origin "$BRANCH" 2>/dev/null; then
        log "✓ Activity logged successfully"
    else
        log "⚠ Failed to push activity log"
    fi
else
    log "⚠ Failed to create activity commit"
fi
)
