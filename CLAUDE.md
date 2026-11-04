---
last_updated: "2025-12-06T02:00:43Z"
---

# Reusable.Workflows

Reusable GitHub Actions workflows providing standardized CI/CD pipelines for Golang, Python, Terraform/OpenTofu, Docker, and security scanning.

## Quick Start

```bash
# No local setup required - workflows are consumed remotely
# Test changes by referencing your branch in a consumer repository:
# uses: davidnlopes/Reusable.Workflows/.github/workflows/golang.yaml@your-branch
```

## Principles

1. **Pin all third-party actions by SHA with version comment** - Use format `uses: <action>@<sha> # <version>` for security and reproducibility.

2. **Set explicit least-privilege permissions at job level with inline comments** - Define only required permissions with comments explaining their purpose.

3. **PR-triggered workflows must implement three-phase status checks** - Set pending status at start, run validation, then set success/failure via GitHub API using CHECK_NAME environment variable.

4. **Define sensible defaults for all version and path inputs** - Every input parameter must have a reasonable default value to reduce consumer friction.

5. **Support monorepo patterns via directory inputs with working-directory** - Accept directory inputs and use `defaults.run.working-directory` to allow consumers to run workflows in subdirectories.

@docs/architecture.md
@docs/domain.md
@docs/patterns.md
@docs/development.md
