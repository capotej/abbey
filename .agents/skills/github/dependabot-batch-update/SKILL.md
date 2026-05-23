---
name: dependabot-batch-update
description: Consolidate multiple open dependabot PRs into a single batch update PR. Uses bundle update for Ruby projects, proper Gemfile.lock regeneration, and consolidated PR creation.
author: hermclaw
---

# Dependabot Batch Update

Combine multiple open dependabot PRs into a single consolidated PR to reduce PR noise and CI runs.

## When to Use

User asks to combine/consolidate multiple open dependabot PRs into one, or when there are 3+ pending dependabot PRs and the user prefers fewer, larger dependency updates.

## Step 1: List Open Dependabot PRs

```bash
gh pr list --repo capotej/abbey --label dependencies --state open \
  --json number,title,headRefName,url --limit 50
```

Parse the titles to extract dependency name, old version, and new version:
```bash
# Title format: "Bump <dep> from <old> to <new>"
```

## Step 2: Get Local Clone

Check for existing clone first:
```bash
REPOS_DIR=~/.hermes-openrouter/github-repos
if [ -d "$REPOS_DIR/abbey/.git" ]; then
  cd "$REPOS_DIR/abbey"
else
  mkdir -p "$REPOS_DIR"
  gh repo fork capotej/abbey --clone=false  # if working on a fork
  git clone https://github.com/hermclaw/abbey.git "$REPOS_DIR/abbey"
  cd "$REPOS_DIR/abbey"
  git remote add upstream https://github.com/capotej/abbey.git
fi
```

## Step 3: Set Up Runtime Environment

**Check for mise.toml or .tool-versions** — if present, use mise to get the correct Ruby/Node/Python version:

```bash
# Ruby projects with mise:
mise trust
eval "$(mise activate bash)"
bundle --version  # verify bundle is available
```

If no mise config and no local runtime available, you cannot properly update Gemfile.lock (SHA256 checksums will be wrong). In this case, ask the user to add a runtime or work around it.

## Step 4: Batch Update Dependencies

For Ruby/Bundler projects:
```bash
# Extract all gem names from dependabot PR titles
bundle update gem1 gem2 gem3 ...  # all at once to let resolver pick compatible versions
```

Do NOT manually edit Gemfile.lock version numbers — the SHA256 checksum `SPEC CHECKSUMS` block will be invalid and bundler will reject the lock file. Always use `bundle update` to regenerate the entire lock file correctly.

## Step 5: Verify

```bash
# Verify versions were updated
grep -E "gem1|gem2" Gemfile.lock

# Run tests to verify compatibility
bundle exec rails test  # or appropriate test command
```

## Step 6: Create Consolidated PR

```bash
git checkout -b feat/batch-dependency-updates
git add Gemfile.lock
git commit -m "chore: batch update N dependencies (dependabot consolidation)"

# Push to fork (token auth required for HTTPS):
git remote add fork "https://x-access-token:$GH_TOKEN@github.com/hermclaw/abbey.git" 2>/dev/null || true
git push fork feat/batch-dependency-updates

# Create PR on fork:
gh pr create --repo hermclaw/abbey \
  --head feat/batch-dependency-updates \
  --base main \
  --title "chore: batch update N dependencies (dependabot consolidation)" \
  --body "<table of all changes with upstream PR links>"
```

## Pitfalls

- **Manual Gemfile.lock edits corrupt checksums**: Always use `bundle update`, not sed/patch on the lock file. The `SPEC CHECKSUMS` section contains SHA256 hashes that must match the actual downloaded gems.
- **No runtime = no proper update**: Without Ruby+bundler available, you cannot regenerate valid Gemfile.lock checksums. Check for mise.toml, .tool-versions, or Dockerfile to find the right runtime.
- **Transitive dependencies**: `bundle update` will also update transitive dependencies (e.g., updating puma may update rack). Include these in the PR body as "also picked up."
- **Puma major version bumps** (e.g., 7.x → 8.x) may have breaking changes — always run tests and note breaking changes in the PR body.
- **`gh pr diff --json` is not supported**: Use `gh pr view N --json title,body` or `gh api repos/capotej/abbey/pulls/N --jq .body` instead to get PR metadata.
- **Pushing to fork requires token in URL**: When pushing via HTTPS, set the fork remote to `https://x-access-token:$GH_TOKEN@github.com/hermclaw/abbey.git` — bare `https://github.com/hermclaw/abbey.git` will prompt for credentials and fail in non-interactive sessions.
- **Worktree branches can't be force-deleted**: If you created a branch in the current worktree, `git branch -D` will fail. Use `git reset --hard upstream/main` to reset the branch pointer instead.
