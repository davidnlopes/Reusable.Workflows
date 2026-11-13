---
scope:
  - ".releaserc.yaml"
  - "renovate.json"
  - ".github/PULL_REQUEST_TEMPLATE.md"
  - ".github/labeler-config.yaml"
  - ".github/CODEOWNERS"
last_updated: "2025-12-06T02:00:43Z"
---

# Development

## Prerequisites

- GitHub account with repository access
- A test repository to validate workflow changes

## Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/davidnlopes/Reusable.Workflows.git
   cd Reusable.Workflows
   ```

2. No local build or install steps required - workflows are consumed remotely by other repositories.

## Testing Workflow Changes

Since workflows run in GitHub Actions, test changes by referencing your branch from a consumer repository:

```yaml
# In your test repository's workflow
jobs:
  test:
    uses: davidnlopes/Reusable.Workflows/.github/workflows/golang.yaml@your-branch-name
```

## Contributing

1. Fork the repository
2. Create a feature branch with a descriptive name
3. Make changes following conventional commit format:
   - `feat:` for new features (triggers minor version bump)
   - `fix:` for bug fixes (triggers patch version bump)
   - `feat!:` or `BREAKING CHANGE:` for breaking changes (triggers major version bump)
   - `chore:`, `docs:`, `style:`, `refactor:`, `test:` for non-release changes

4. Open a pull request with a semantic title (enforced by semantic-pr.yaml)
5. Add exactly one semver label: `major`, `minor`, or `patch`
6. Request review from @dnlopes (CODEOWNERS)

## Release Process

Releases are automated via semantic-release on push to main:

1. Analyzes commits since last release using conventional commit format
2. Determines version bump (major/minor/patch)
3. Creates GitHub release with changelog
4. Tags with multiple formats for flexible consumption:
   - `vX.Y.Z` - exact version
   - `vX.Y` - minor version
   - `vX` - major version

## Common Tasks

**Add a new reusable workflow:**
1. Create `workflow.yaml` in `.github/workflows/`
2. Use `on: workflow_call:` trigger
3. Define inputs with sensible defaults
4. Add `ignoreErrors` input
5. Implement three-phase status check pattern
6. Use self-checkout pattern to access composite actions
7. Pin all third-party actions by SHA

**Update tool versions:**
1. Modify default version in workflow inputs
2. Update `install-common-tools` action if needed
3. Test in a consumer repository
