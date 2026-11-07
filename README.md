# Reusable GitHub Workflows

Shared GitHub Actions workflows that other repositories call to build, test, scan, and deploy their code. A repository adds a few lines of YAML instead of maintaining its own pipeline, and every caller gets the same checks, pinned actions, and least-privilege permissions.

Each workflow uses the `workflow_call` trigger. Workflows that run on pull requests also report a commit status, such as `Golang CI`, that you can mark as required in branch protection.

## Workflows

| Workflow | What it does | Secrets |
| --- | --- | --- |
| `golang.yaml` | Runs your build and test commands, then uploads coverage to Codecov | `CODECOV_TOKEN` (optional) |
| `python.yaml` | Runs your setup and test commands, then uploads coverage to Codecov | `CODECOV_TOKEN` |
| `react.yaml` | Installs dependencies with npm, pnpm, or Yarn, then lints, tests, builds, and uploads coverage | `CODECOV_TOKEN` |
| `terraform.yaml` | Formats, validates, and runs `plan`, `apply`, or `destroy` with Terraform or OpenTofu, and comments the results on the PR | None, uses AWS OIDC |
| `docker-build.yaml` | Builds a Docker image without pushing it | None |
| `docker-build-push.yaml` | Builds a Docker image and pushes it to Amazon ECR | None, uses AWS OIDC |
| `trivy-scan.yaml` | Scans the repository with Trivy and comments the findings on the PR | None |
| `pre-commit-hooks.yaml` | Runs the repository's pre-commit hooks | None |
| `semantic-pr.yaml` | Checks that the PR title follows conventional commits and that the PR has exactly one `major`, `minor`, or `patch` label | None |
| `dependabot-merge.yaml` | Merges Dependabot PRs after a code owner approves them | `DEPENDABOT_MERGE_TOKEN` |

The input names, defaults, and descriptions live in the `on.workflow_call` block at the top of each file in [`.github/workflows/`](.github/workflows/).

## Usage

Call a workflow from a job in your repository:

```yaml
# .github/workflows/ci.yaml
name: CI
on: [pull_request]

jobs:
  golang:
    uses: davidnlopes/Reusable.Workflows/.github/workflows/golang.yaml@v1
    with:
      buildCommand: go build ./...
      testCommand: go test -coverprofile=coverage.out ./...
    secrets:
      CODECOV_TOKEN: ${{ secrets.CODECOV_TOKEN }}
```

### Pick a version

Every release is tagged three ways:

- `@v1` follows the latest release of that major version. Use this by default.
- `@v1.2` follows patch releases only.
- `@v1.2.3` never changes.

### Inputs most workflows share

- `ignoreErrors` reports success even when the checks fail. Use it to roll out a new check without blocking PRs.
- A directory input, such as `golangProjectDir`, `terraformProjectDir`, or `projectDir`, runs the workflow in a subdirectory of a monorepo.
- `runsOn` picks the runner, and defaults to `ubuntu-latest`. Set it to run on a self-hosted runner.

### Examples

Python:

```yaml
jobs:
  python:
    uses: davidnlopes/Reusable.Workflows/.github/workflows/python.yaml@v1
    with:
      setupCommand: pip install -e .[dev]
      testsCommand: pytest --cov
    secrets:
      CODECOV_TOKEN: ${{ secrets.CODECOV_TOKEN }}
```

Terraform plan:

```yaml
jobs:
  terraform:
    uses: davidnlopes/Reusable.Workflows/.github/workflows/terraform.yaml@v1
    with:
      terraformProjectDir: infra
      terraformAction: plan
      terraformWorkspace: production
      terraformVarsFile: environments/prod.tfvars
      awsRoleArn: arn:aws:iam::123456789012:role/terraform
```

Set `binary: tofu` to use OpenTofu instead of Terraform. The workflow assumes the AWS role in `eu-west-1`.

Docker build and push to ECR:

```yaml
jobs:
  docker:
    uses: davidnlopes/Reusable.Workflows/.github/workflows/docker-build-push.yaml@v1
    with:
      dockerFilePath: Dockerfile
      repository: my-service
      tag: ${{ github.sha }}
      awsRoleArn: arn:aws:iam::123456789012:role/ecr-push
      pushToECR: true
```

The workflow creates the ECR repository when it does not exist. Set `createRepository: false` to turn that off.

Trivy, pre-commit, and semantic PR checks need no inputs:

```yaml
jobs:
  trivy:
    uses: davidnlopes/Reusable.Workflows/.github/workflows/trivy-scan.yaml@v1
  pre-commit:
    uses: davidnlopes/Reusable.Workflows/.github/workflows/pre-commit-hooks.yaml@v1
  semantic-pr:
    uses: davidnlopes/Reusable.Workflows/.github/workflows/semantic-pr.yaml@v1
```

Trivy reads ignore rules from `.trivyignore` when the file exists.

### Merge Dependabot PRs

When a code owner approves a Dependabot PR, or comments `LGTM` on it, the workflow enables squash auto-merge. It also keeps the PR mergeable:

- When the PR falls behind the default branch, it asks Dependabot to rebase the PR.
- When the rebase dismisses the approval, it approves again, but only if the changes match the approved commit.

The workflow reacts to several events, so the calling workflow must listen to all of them:

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

`DEPENDABOT_MERGE_TOKEN` is a fine-grained personal access token of a code owner, with read and write access to **Contents**, **Pull requests**, and **Workflows**. Store it as both an Actions secret and a Dependabot secret, because runs that Dependabot triggers read only Dependabot secrets. Also allow auto-merge in the repository settings.

### Set up AWS access

`terraform.yaml` and `docker-build-push.yaml` sign in to AWS with GitHub OIDC, so they need no stored AWS keys. Before you call them, create an IAM role that trusts GitHub's OIDC provider for your repository, and pass its ARN as `awsRoleArn`.

## Documentation

| Topic | Document | Read it when |
| --- | --- | --- |
| Architecture | [`docs/architecture.md`](docs/architecture.md) | You want to know how the workflows, the shared action, and external services fit together |
| Domain | [`docs/domain.md`](docs/domain.md) | You meet an unfamiliar term or need the rules every workflow follows |
| Patterns | [`docs/patterns.md`](docs/patterns.md) | You add or change a workflow |
| Development | [`docs/development.md`](docs/development.md) | You test a change, open a PR, or want to know how releases work |

## Development

There is nothing to build or install locally. To test a change, push a branch and call the workflow from a test repository by branch name:

```yaml
uses: davidnlopes/Reusable.Workflows/.github/workflows/golang.yaml@your-branch
```

Open the PR with a conventional commit title and exactly one `major`, `minor`, or `patch` label. Merging to `main` publishes a release. See [`docs/development.md`](docs/development.md) for the full process.
