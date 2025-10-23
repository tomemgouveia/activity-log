# Activity Log

A GitHub repository that automatically tracks commit activity across all your projects.

## Repository Structure

- `hooks/` - Pre-commit compatible hook scripts
- `standalone_script/` - Standalone global git hook setup (legacy/alternative approach)
- `activity-log-repository.md` - Documentation about the activity log concept
- `SETUP_FIXES.md` - Troubleshooting guide

## Usage

There are two ways to use this activity logger:

### Option 1: Using with pre-commit (Recommended)

This approach works seamlessly with pre-commit and allows you to use other pre-commit hooks.

#### Prerequisites
1. Install [pre-commit](https://pre-commit.com/): `pip install pre-commit`
2. **Create your own activity-log repository** on GitHub (e.g., `your-username/activity-log`)
3. Clone it locally as your mirror:
   ```bash
   git clone git@github.com:YOUR-USERNAME/YOUR-ACTIVITY-LOG-REPO.git ~/.activity-mirror
   ```

#### Configuration

Create a configuration file at `~/.config/activity-log-config.ini`:

1. Copy the config template:
   ```bash
   mkdir -p ~/.config
   curl -o ~/.config/activity-log-config.ini https://raw.githubusercontent.com/tomemgouveia/activity-log/main/config.ini.dist
   # OR
   cp config.ini.dist ~/.config/activity-log-config.ini
   ```

2. Edit `~/.config/activity-log-config.ini` with your repository:
   ```ini
   ACTIVITY_LOG_REPO=git@github.com:YOUR-USERNAME/YOUR-ACTIVITY-LOG-REPO.git
   ACTIVITY_LOG_MIRROR=$HOME/.activity-mirror
   ACTIVITY_LOG_BRANCH=main
   ```

**Important**: Without setting `ACTIVITY_LOG_REPO`, the hook will silently do nothing (no errors, no logging).

#### Setup in any repository

Add to your `.pre-commit-config.yaml`:

```yaml
repos:
  # ... your existing pre-commit hooks ...
  
  # Activity logger - runs AFTER successful commits
  - repo: https://github.com/tomemgouveia/activity-log
    rev: main  # or a specific tag/commit
    hooks:
      - id: activity-log
```

Then install the post-commit hook type (in addition to regular pre-commit hooks):

```bash
pre-commit install                        # Install pre-commit hooks (if not already done)
pre-commit install --hook-type post-commit  # Install post-commit hooks
```

**Note**: The `activity-log` hook runs **after** your commit succeeds, not before. It won't block or interfere with your existing pre-commit hooks (linters, formatters, etc.), which run before the commit.

#### Example: Complete setup from scratch

```bash
# 1. Install pre-commit
pip install pre-commit

# 2. Create and configure your activity log
git clone git@github.com:YOUR-USERNAME/YOUR-ACTIVITY-LOG-REPO.git ~/.activity-mirror
mkdir -p ~/.config
cat > ~/.config/activity-log-config.ini <<EOF
ACTIVITY_LOG_REPO=git@github.com:YOUR-USERNAME/YOUR-ACTIVITY-LOG-REPO.git
ACTIVITY_LOG_MIRROR=$HOME/.activity-mirror
ACTIVITY_LOG_BRANCH=main
EOF

# 3. In your project repository, create .pre-commit-config.yaml
cat > .pre-commit-config.yaml <<EOF
repos:
  # Add your other pre-commit hooks here (linters, formatters, etc.)
  
  # Activity logger - runs after successful commits
  - repo: https://github.com/tomemgouveia/activity-log
    rev: main
    hooks:
      - id: activity-log
EOF

# 4. Install both hook types
pre-commit install                        # For pre-commit hooks
pre-commit install --hook-type post-commit  # For post-commit hooks

# Done! Now every commit will be logged to your activity repository
```

### Option 2: Global Git Hook (Standalone)

See the `standalone_script/` directory for the legacy approach using `core.hooksPath`. 

**Note**: This approach conflicts with pre-commit's installation process. Use Option 1 if you need pre-commit compatibility.

## How It Works

Every time you make a commit in any repository (with the hook installed):
1. The post-commit hook triggers
2. It creates an empty commit in the activity-log repository with a timestamp
3. The commit is pushed to GitHub, creating a visible activity log

The hook includes safeguards to:
- Prevent infinite recursion
- Skip commits made within the activity-log repository itself
- Handle missing local mirror gracefully
- Avoid interfering with your actual commits

## License

MIT
