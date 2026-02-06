# CI Approval Issue - Why Workflows Aren't Running

## Problem Summary

GitHub Actions workflows are **starting** but not **running** on pull requests. They show a status of `action_required`, which means they're waiting for manual approval from a repository maintainer.

## Why This Happens

GitHub has a security feature that requires approval for workflows triggered by:
- First-time contributors
- Bots (like GitHub Copilot)
- Pull requests from forks
- External contributors

This is a security measure to prevent potentially malicious code from running in your GitHub Actions runners.

## Current Status

When checking recent workflow runs:
- ✅ Workflows on **push events** to master/dev branches run normally
- ⚠️ Workflows on **pull_request events** get stuck with `action_required` status
- ℹ️ No jobs are executed until manual approval is given

## Solution Options

### Option 1: Manual Approval (Immediate)

Repository maintainers with write access can manually approve workflows:

1. Go to the Pull Request page
2. Click on the **"Conversation"** tab
3. Look for the "_n_ workflow(s) awaiting approval" section
4. Click **"Approve workflows to run"**

**Note:** This must be done for each PR from external contributors or bots.

### Option 2: Configure Repository Settings (Permanent Fix)

Repository owners/administrators can change the approval policy:

1. Go to **Repository Settings**
2. Click **Actions** → **General** in the left sidebar
3. Under **"Approval for running fork pull request workflows from contributors"**, choose:
   - **"Require approval for first-time contributors"** (default)
   - **"Require approval for first-time contributors who are new to GitHub"**
   - **"Require approval for all external contributors"**

**Recommended:** Use "Require approval for first-time contributors" which will allow workflows to run automatically once a contributor has had at least one commit or PR merged.

### Option 3: Use Different Trigger Events

For workflows that should run on every PR without approval, consider using:
- `pull_request_target` (⚠️ **Security Warning**: Runs in the base branch context with full access to secrets)
- `push` events only (limits when workflows run)

**Note:** `pull_request_target` should only be used if you carefully review the security implications, as it runs with elevated privileges.

## Verification

To verify workflows are running correctly after implementing a solution:

```bash
# Check recent workflow runs
gh run list --repo lskatz/Kalamari --limit 10

# Check status of workflows for a specific PR
gh run list --repo lskatz/Kalamari --branch <branch-name>
```

## References

- [GitHub Docs: Approving workflow runs from forks](https://docs.github.com/en/actions/managing-workflow-runs/approving-workflow-runs-from-public-forks)
- [GitHub Docs: Managing GitHub Actions settings](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository)

## Impact on Current PR

The current PR (copilot/investigate-ci-start-issue) has workflows waiting for approval:
- Validate taxonomy
- Genera-with-Kraken2  
- Listeria-with-Kraken1
- Pull-down-all-accessions

These workflows need manual approval to run since they were triggered by the Copilot bot.
