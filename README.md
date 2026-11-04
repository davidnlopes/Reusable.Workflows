<!--
---
scope:
  - ".github/workflows/*.yaml"
last_updated: "2025-12-06T02:00:43Z"
---
-->

# Reusable GitHub Workflows

Standardized CI/CD pipelines for your repositories. Drop-in workflows for Golang, Python, Terraform/OpenTofu, Docker, and security scanning.

## Features

- **Multi-language CI** - Pre-built pipelines for Go, Python, Terraform/OpenTofu
- **Docker integration** - Build and push to AWS ECR with OIDC authentication
- **Security scanning** - Trivy vulnerability scanning with PR comments
- **Quality gates** - Pre-commit hooks, semantic PR validation, code coverage
- **Automated releases** - Semantic versioning with conventional commits
- **Monorepo support** - Run workflows in subdirectories via inputs

## Quick Start

Add a workflow file to your repository:

```yaml
# .github/workflows/ci.yml
name: CI
on: [pull_request]

jobs:
  golang:
    uses: davidnlopes/Reusable.Workflows/.github/workflows/golang.yaml@v1
    secrets:
      CODECOV_TOKEN: ${{ secrets.CODECOV_TOKEN }}
```

## Available Workflows

| Workflow | Purpose | Required Secrets |
|----------|---------|------------------|
| `golang.yaml` | Build, test, lint, coverage | `CODECOV_TOKEN` (optional) |
| `python.yaml` | Unit tests, coverage | `CODECOV_TOKEN` (optional) |
| `terraform.yaml` | Validate, plan, apply, destroy | AWS OIDC credentials |
| `docker-build-push.yaml` | Build and push to ECR | AWS OIDC credentials |
| `trivy-scan.yaml` | Security vulnerability scanning | None |
| `semantic-pr.yaml` | Enforce semantic PR titles | None |
| `pre-commit-hooks.yaml` | Run pre-commit hooks | None |
| `dependabot-merge.yaml` | Merge Dependabot PRs after a code owner approves | `DEPENDABOT_MERGE_TOKEN` |

## Usage Examples

### Golang Project

```yaml
jobs:
  ci:
    uses: davidnlopes/Reusable.Workflows/.github/workflows/golang.yaml@v1
    with:
      goVersion: "1.22"
      golangProjectDir: "."
      buildCommand: "make build"
      testCommand: "make test"
    secrets:
      CODECOV_TOKEN: ${{ secrets.CODECOV_TOKEN }}
```

### Python Project

```yaml
jobs:
  ci:
    uses: davidnlopes/Reusable.Workflows/.github/workflows/python.yaml@v1
    with:
      pythonVersion: "3.12"
      setupCommand: "pip install -e .[dev]"
      testCommand: "pytest --cov"
    secrets:
      CODECOV_TOKEN: ${{ secrets.CODECOV_TOKEN }}
```

### Terraform Plan

```yaml
jobs:
  plan:
    uses: davidnlopes/Reusable.Workflows/.github/workflows/terraform.yaml@v1
    with:
      action: plan
      workspace: production
      tfVarsFile: environments/prod.tfvars
      awsRegion: us-east-1
      awsRoleArn: arn:aws:iam::123456789:role/terraform
```

### Security Scanning

```yaml
jobs:
  security:
    uses: davidnlopes/Reusable.Workflows/.github/workflows/trivy-scan.yaml@v1
    with:
      scanDirectory: "."
```

### Semantic PR Validation

```yaml
jobs:
  validate:
    uses: davidnlopes/Reusable.Workflows/.github/workflows/semantic-pr.yaml@v1
```

### Dependabot Merge

A code owner approves a Dependabot PR, or comments `LGTM` on it, and the workflow enables squash auto-merge. The workflow also does two follow-up tasks:

- When a PR falls behind the default branch, it asks Dependabot to rebase the PR.
- When the rebase dismisses the approval, it approves again, but only if the changes match the approved commit.

```yaml
on:
  issue_comment:
    types: [created]
  pull_request_review:
    types: [submitted]
  pull_request:
    types: [synchronize]
  push:
    branches:
      - main

permissions: {}

jobs:
  merge:
    uses: davidnlopes/Reusable.Workflows/.github/workflows/dependabot-merge.yaml@v1
    secrets:
      DEPENDABOT_MERGE_TOKEN: ${{ secrets.DEPENDABOT_MERGE_TOKEN }}
```

`DEPENDABOT_MERGE_TOKEN` is a fine-grained personal access token of a code owner. It needs read and write access to **Contents**, **Pull requests**, and **Workflows**. Store it as an Actions secret and as a Dependabot secret: runs that Dependabot triggers read only Dependabot secrets.

## Self-hosted runners

To run a job on a self-hosted runner, set the `runsOn` input. It defaults to `ubuntu-latest`.

```yaml
jobs:
  test:
    uses: davidnlopes/Reusable.Workflows/.github/workflows/golang.yaml@v1
    with:
      runsOn: my-runner-scale-set
      buildCommand: go build ./...
      testCommand: go test ./...
```

These workflows support `runsOn`: `golang.yaml`, `python.yaml`, `react.yaml`, `terraform.yaml`, `trivy-scan.yaml`, and `pre-commit-hooks.yaml`.

## Version Pinning

Reference workflows using semantic versioning:

- `@v1` - Major version (recommended, receives minor/patch updates)
- `@v1.2` - Minor version (receives patch updates only)
- `@v1.2.3` - Exact version (pinned, no automatic updates)

## Prerequisites

- **All workflows**: GitHub Actions enabled in your repository
- **Coverage workflows**: `CODECOV_TOKEN` secret configured
- **Dependabot merge**: `DEPENDABOT_MERGE_TOKEN` stored as an Actions secret and a Dependabot secret, and auto-merge allowed in the repository settings
- **AWS workflows**: OIDC trust relationship between GitHub and AWS
- **Terraform**: IAM role ARN and tfvars file in repository

## Documentation

- [Architecture](docs/architecture.md) - System design and components
- [Domain](docs/domain.md) - Terminology and business rules
- [Patterns](docs/patterns.md) - Code conventions and examples
- [Development](docs/development.md) - Contributing guidelines

## License

MIT
