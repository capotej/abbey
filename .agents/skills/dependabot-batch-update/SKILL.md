---
name: dependabot-batch-update
category: github
description: Consolidate multiple open dependabot PRs into a single batch update PR. Uses bundle update for Ruby projects, proper Gemfile.lock regeneration, and consolidated PR creation.
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

## Step 2: Set Up Runtime Environment

**Check for mise.toml or .tool-versions** — if present, use mise to get the correct Ruby/Node/Python version:

```bash
mise trust
eval "$(mise activate bash)"
bundle --version  # verify bundle is available
```

If no mise config and no local runtime available, you cannot properly update Gemfile.lock (SHA256 checksums will be wrong). In this case, ask the user to add a runtime or work around it.

## Step 3: Batch Update Dependencies

For Ruby/Bundler projects:
```bash
# Extract all gem names from dependabot PR titles
bundle update gem1 gem2 gem3 ...  # all at once to let resolver pick compatible versions
```

Do NOT manually edit Gemfile.lock version numbers — the SHA256 checksum `SPEC CHECKSUMS` block will be invalid and bundler will reject the lock file. Always use `bundle update` to regenerate the entire lock file correctly.

## Step 4: Verify

```bash
# Verify versions were updated
grep -E "gem1|gem2" Gemfile.lock

# Run tests to verify compatibility
bundle exec rails test
```

## Step 5: Create Consolidated PR

Create a branch, commit, push, and open a PR with a summary of all consolidated changes (include upstream dependabot PR links in the body).

## Pitfalls

- **Manual Gemfile.lock edits corrupt checksums**: Always use `bundle update`, not sed/patch on the lock file. The `SPEC CHECKSUMS` section contains SHA256 hashes that must match the actual downloaded gems.
- **No runtime = no proper update**: Without Ruby+bundler available, you cannot regenerate valid Gemfile.lock checksums. Check for mise.toml, .tool-versions, or Dockerfile to find the right runtime.
- **Transitive dependencies**: `bundle update` will also update transitive dependencies (e.g., updating puma may update rack). Include these in the PR body as "also picked up."
- **Major version bumps** may have breaking changes — always run tests and note any in the PR body.
- **`gh pr diff --json` is not supported**: Use `gh pr view N --json title,body` or `gh api repos/OWNER/REPO/pulls/N --jq .body` instead to get PR metadata.
