---
scope:
  - ".github/workflows/*.yaml"
  - ".github/actions/**"
last_updated: "2025-12-06T02:00:43Z"
---

# Architecture

## Overview

This repository provides reusable GitHub Actions workflows using the `workflow_call` trigger pattern. Consumer repositories reference these workflows remotely, and workflows access shared tooling through a composite action that installs common tools.

## Components

### Reusable Workflows

**Location:** `.github/workflows/`

**Responsibility:** Provide complete CI/CD pipelines for specific technology stacks and tasks.

**Workflows:**
- `golang.yaml` - Build, test, lint, and coverage for Go projects
- `python.yaml` - Unit tests and coverage for Python projects
- `terraform.yaml` - Validate, plan/apply/destroy for Terraform/OpenTofu
- `docker.yaml` - Build Docker images from the caller's Bake file, and push them to a registry
- `docker-build.yaml` - Deprecated, replaced by `docker.yaml`
- `docker-build-push.yaml` - Deprecated, replaced by `docker.yaml`
- `trivy-scan.yaml` - Security vulnerability scanning
- `semantic-pr.yaml` - Enforce semantic PR titles and labels
- `pre-commit-hooks.yaml` - Run pre-commit hooks in CI
- `release.yaml` - Automated semantic versioning (internal use only)

**Interactions:** Called by consumer repositories via `uses:` directive. All consumer-facing workflows use `workflow_call` trigger.

### Composite Actions

**Location:** `.github/actions/`

**Responsibility:** Encapsulate shared step sequences for tool installation.

**Actions:**
- `install-common-tools/` - Installs Go, Python, Terraform, OpenTofu, TFLint, Trivy, pre-commit, uv, Poetry based on inputs

**Interactions:** Called by reusable workflows after checking out this repository to the `actions/` path.

## Data Flow

```
Consumer Repository
        │
        ▼ (workflow_call)
Reusable Workflow
        │
        ├──► Checkout consumer repo
        │
        ├──► Checkout this repo to actions/
        │
        ├──► Install tools via composite action
        │
        ├──► Run validation steps
        │
        └──► Post results
             ├──► GitHub Status API (PR checks)
             ├──► PR Comments (plans, scan results)
             └──► External Services (Codecov)
```

## External Dependencies

| Service | Integration | Used By |
|---------|-------------|---------|
| AWS | OIDC authentication for ECR and Terraform | docker.yaml, docker-build-push.yaml, terraform.yaml |
| Codecov | Coverage reporting | golang.yaml, python.yaml |
| GitHub API | Status checks and PR comments | All PR workflows |

## Key Architectural Decisions

**Self-checkout pattern:** Workflows check out this repository to access the composite action. This enables sharing the `install-common-tools` action across all workflows without duplicating installation logic.

**Three-phase status checks:** All PR workflows set pending status immediately, run validation, then set final status. This provides immediate feedback that the workflow has started and ensures accurate final state reporting.

**workflow_call for consumers:** All workflows intended for external consumption use `workflow_call` trigger. Only internal workflows (release.yaml) use push/PR triggers. This provides a clean API boundary.
