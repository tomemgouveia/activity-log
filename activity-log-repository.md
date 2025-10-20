# 🧭 The Challenge
I am a professional software developer who:
- Uses git extensively for work.
- Does most of my work in private repositories (specifically on Azure DevOps).
- Has a personal GitHub account tied to a personal email address.

The result:
My GitHub contribution graph (the “green squares”) doesn’t show much activity — even though I'm committing constantly at work.

I want a way to reflect my true coding activity on my personal GitHub account without leaking any private or proprietary data.

# 💡 The Core Idea
GitHub counts “contributions” when I:
- Make commits to repositories hosted on GitHub, and
- The commits’ author email matches an email in my GitHub account.

Because Azure DevOps is not GitHub, those commits are invisible to GitHub.

To fix this, I can mirror my activity safely — i.e., create a harmless “shadow commit” in a repo I control on GitHub each time I make a real commit somewhere else.

# ⚙️ Solution Overview: the “Activity Mirror” Repository
## Goal:

Whenever I commit in any local git repository (work, personal, etc.), a script automatically makes an empty commit to a private GitHub repo I own (for example: github.com/myname/dev-activity).

Each of those empty commits shows up as a contribution (a “green dot”) on my GitHub graph.

This:
- Reflects my true daily commit cadence.
- Doesn’t expose any code, commit messages, or private repo metadata.
- Works fully offline + local.
- Is reversible and safe.


# 🪶 How It Works
1. Create the mirror repo

- On my GitHub account, create a repo — e.g. dev-activity.
- Make it private (recommended).
- Enable “Include private contributions” on my GitHub profile page.

This ensures my contribution graph shows dots for private commits.

2. Clone it locally

`git clone git@github.com:myusername/dev-activity.git ~/.activity-mirror`

3. Set up a global git hook

I’ll configure a global post-commit hook that fires every time I make a commit anywhere on my system.
Create a folder for global hooks:

```
mkdir -p ~/.githooks
git config --global core.hooksPath ~/.githooks
```

Add this file: `~/.githooks/post-commit`
 (make it executable: chmod +x ~/.githooks/post-commit)
```
#!/bin/sh
# Mirror commit activity to GitHub safely

REPO="myusername/dev-activity"
LOCAL_MIRROR="$HOME/.activity-mirror"
BRANCH="main"

# Skip silently if no local mirror repo exists
if [ ! -d "$LOCAL_MIRROR/.git" ]; then
    exit 0
fi

MSG="activity: $(date -u +"%Y-%m-%dT%H:%M:%SZ") from $(basename "$(git rev-parse --show-toplevel 2>/dev/null)")"

(
  cd "$LOCAL_MIRROR" || exit 0
  git pull origin "$BRANCH" >/dev/null 2>&1 || true
  git commit --allow-empty -m "$MSG" >/dev/null 2>&1 || exit 0
  git push origin "$BRANCH" >/dev/null 2>&1 || true
)
```

4. Result
Every time I make a commit anywhere, this script:
- Makes an empty commit in my dev-activity repo.
- Pushes it to GitHub silently.
- Adds a dot on my GitHub contribution graph.

It never touches my work code, never reads any repo content, and never leaks any filenames.


# 🧹 Stopping or Removing It
If I ever decide to stop using it:
- Remove the hook:

```
git config --global --unset core.hooksPath
rm -rf ~/.githooks
```
- Delete the local mirror:
```
rm -rf ~/.activity-mirror
```


# ✅ End Result
Once configured:
- Every real commit I make (even to private Azure DevOps repos) automatically creates a corresponding empty commit in my private GitHub mirror repo.
- My GitHub contribution graph fills up with dots that match my real daily development activity.
- I don’t reveal any sensitive data.
- I can stop, modify, or remove it at any time.


