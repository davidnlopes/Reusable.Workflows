---
scope:
  - ".github/workflows/*.yaml"
  - ".github/actions/**"
last_updated: "2025-12-06T02:00:43Z"
---

# Patterns

## Project Structure

```
.github/
├── workflows/           # Reusable workflow definitions
│   ├── golang.yaml
│   ├── python.yaml
│   ├── terraform.yaml
│   ├── docker-build-push.yaml
│   ├── trivy-scan.yaml
│   ├── semantic-pr.yaml
│   ├── pre-commit-hooks.yaml
│   ├── dependabot-merge.yaml
│   ├── dependabot.yaml  # Internal use only (calls dependabot-merge.yaml)
│   └── release.yaml     # Internal use only (push trigger)
├── actions/
│   └── install-common-tools/
│       └── action.yaml  # Composite action for tool installation
├── dependabot.yml
├── labeler-config.yaml
├── CODEOWNERS
└── PULL_REQUEST_TEMPLATE.md
.releaserc.yaml          # Semantic release configuration
```

## Naming Conventions

**Workflow files:** Lowercase with hyphens (e.g., `docker-build-push.yaml`, `semantic-pr.yaml`)

**Job names:** Descriptive titles (e.g., "Build and test", "Unit tests", "Docker Build")

**Check contexts:** Format `<Technology> CI` (e.g., "Golang CI", "Python CI", "Terraform CI")

## Status Check Pattern

All PR-triggered workflows follow a three-phase status pattern:

```yaml
# 1. Set pending status at workflow start
- name: Set pending status
  if: github.event_name == 'pull_request'
  run: |
    gh api repos/${{ github.repository }}/statuses/${{ github.event.pull_request.head.sha }} \
      -f state=pending \
      -f context="$CHECK_NAME" \
      -f description="Running..."

# 2. Run validation steps
- name: Run tests
  run: make test

# 3. Set success/failure based on outcome
- name: Set success status
  if: success()
  run: |
    gh api repos/${{ github.repository }}/statuses/${{ github.event.pull_request.head.sha }} \
      -f state=success \
      -f context="$CHECK_NAME"

- name: Set failure status
  if: failure()
  run: |
    gh api repos/${{ github.repository }}/statuses/${{ github.event.pull_request.head.sha }} \
      -f state=failure \
      -f context="$CHECK_NAME"
```

Reference: `.github/workflows/golang.yaml:51-118`

## Action Pinning Pattern

All third-party actions are pinned by SHA with version comment:

```yaml
- uses: actions/checkout@1af3b93b6815bc44a9784bd300feb67ff0d1eeb3 # v6
- uses: codecov/codecov-action@ad3126e916f78f00edff4ed0317cf185271ccc2d # v5
```

Reference: `.github/workflows/golang.yaml:49`

## Permissions Pattern

Explicit least-privilege permissions at job level with inline comments:

```yaml
permissions:
  contents: read      # checkout repository
  statuses: write     # update commit status
  pull-requests: write # comment on PR
```

Reference: `.github/workflows/golang.yaml:38-42`

## Self-Checkout Pattern

Workflows check out this repository to access shared composite actions:

```yaml
- name: Checkout reusable-workflows repository
  uses: actions/checkout@1af3b93b6815bc44a9784bd300feb67ff0d1eeb3 # v6
  with:
    repository: davidnlopes/Reusable.Workflows
    path: actions

- name: Install tools
  uses: ./actions/.github/actions/install-common-tools
  with:
    go-version: ${{ inputs.goVersion }}
```

Reference: `.github/workflows/golang.yaml:61-70`

## Input/Output Pattern

Common inputs with sensible defaults:

```yaml
on:
  workflow_call:
    inputs:
      goVersion:
        type: string
        default: "1.22"
      golangProjectDir:
        type: string
        default: "."
      ignoreErrors:
        type: boolean
        default: false
    secrets:
      CODECOV_TOKEN:
        required: false
```

Reference: `.github/workflows/golang.yaml:4-30`

## Working Directory Pattern

Support monorepo structures:

```yaml
defaults:
  run:
    working-directory: ${{ inputs.golangProjectDir }}
```

Reference: `.github/workflows/golang.yaml:43-45`

## Error Handling Pattern

Honor `ignoreErrors` input in status updates:

```yaml
- name: Set success status
  if: ${{ (success() || inputs.IgnoreErrors == true) && github.event_name == 'pull_request' }}
  run: # set success status
```

Reference: `.github/workflows/golang.yaml:101`
