# Ubuntu 20.04 Deprecation - Workflow Queue Issue

## Problem

After approving workflows in PR #59, they remained stuck in "queued" status for over 30 minutes without executing. The workflows were requesting runners with `ubuntu-20.04`, but no runners were available.

## Root Cause

**Ubuntu 20.04 is no longer available on GitHub Actions hosted runners.**

According to the [actions/runner-images repository](https://github.com/actions/runner-images), the currently available Ubuntu versions are:
- ✅ ubuntu-24.04 (latest)
- ✅ ubuntu-22.04 (stable)
- ❌ ubuntu-20.04 (deprecated/removed)

When workflows specify an unavailable OS version, they get stuck in the queue indefinitely (up to 45 minutes before being discarded) because GitHub cannot find matching runners.

## Solution Implemented

Updated all workflow files to use `ubuntu-22.04` instead of `ubuntu-20.04`:

### Files Changed

1. `.github/workflows/unit-testing.yml` (Pull-down-all-accessions)
2. `.github/workflows/validateTaxonomy.yml` (Validate taxonomy)
3. `.github/workflows/unit-testing.Listeria.Kraken1.yml` (Listeria-with-Kraken1)
4. `.github/workflows/unit-testing.Yersinia.Kraken2.yml` (Genera-with-Kraken2)

Each file was updated from:
```yaml
matrix:
  os: ['ubuntu-20.04']
```

To:
```yaml
matrix:
  os: ['ubuntu-22.04']
```

## Why Ubuntu 22.04?

- **ubuntu-22.04**: Stable, widely used, well-supported for production workflows
- **ubuntu-24.04**: Newest version (labeled as `ubuntu-latest`), but may have compatibility issues with older tools

We chose ubuntu-22.04 for stability and compatibility with the existing Perl 5.32 and bioinformatics tools used in these workflows.

## Testing

After the update, new workflow runs will need to be approved (for first-time contributors) and should then execute successfully on ubuntu-22.04 runners.

## Future Considerations

- Monitor GitHub's announcements about OS deprecations
- Consider using `ubuntu-latest` for automatic updates, but test thoroughly first
- Ubuntu versions typically get 2-3 years of support after initial release on GitHub Actions

## References

- [GitHub Actions Runner Images](https://github.com/actions/runner-images)
- [Available GitHub-hosted runners](https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners/about-github-hosted-runners)
