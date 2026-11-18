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
| `docker.yaml` | Builds the targets of your `docker-bake.hcl` with Docker Buildx Bake, and pushes them to a registry when asked | `REGISTRY_PASSWORD` (optional), or AWS OIDC for Amazon ECR |
| `trivy-scan.yaml` | Scans the repository with Trivy and comments the findings on the PR | None |
| `pre-commit-hooks.yaml` | Runs the repository's pre-commit hooks | None |
| `semantic-pr.yaml` | Checks that the PR title follows conventional commits and that the PR has exactly one `major`, `minor`, or `patch` label | None |
| `labeler.yaml` | Labels the PR from the changed files, using the shared label rules. Needs a runner that can run Docker container actions | None |

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

Docker images:

`docker.yaml` runs `docker buildx bake` on the Bake file in your repository, so the file decides the targets, Dockerfiles, platforms, tags, and labels. A minimal `docker-bake.hcl`:

```hcl
variable "VERSION" {
  default = "dev"
}

target "default" {
  context   = "."
  platforms = ["linux/amd64", "linux/arm64"]
  tags      = ["ghcr.io/my-org/my-app:${VERSION}"]
}
```

The caller builds on pull requests and pushes on `main`:

```yaml
jobs:
  docker:
    permissions:
      contents: read
      statuses: write
      packages: write
      id-token: write
    uses: davidnlopes/Reusable.Workflows/.github/workflows/docker.yaml@v1
    with:
      registry: ghcr.io
      version: ${{ github.sha }}
      push: ${{ github.event_name == 'push' }}
```

The job requests all four permissions, so the caller must grant them even when it never pushes.

- `ghcr.io` logs in with `GITHUB_TOKEN`. Other registries take `registryUsername` and the `REGISTRY_PASSWORD` secret.
- For Amazon ECR, set `registry` to the ECR host and `awsRoleArn` to a role the workflow assumes with OIDC. The workflow reads the AWS region from the host unless you set `awsRegion`.
- `version` reaches the Bake file as the `VERSION` variable. `set` takes Bake overrides, one per line, such as `*.platform=linux/amd64`.
- The workflow installs QEMU only when a target platform differs from the runner's architecture. Set `setupQemu: false` on a runner that cannot install binfmt emulators, or `true` to always install them.

Trivy, pre-commit, semantic PR, and labeler checks need no inputs:

```yaml
jobs:
  trivy:
    uses: davidnlopes/Reusable.Workflows/.github/workflows/trivy-scan.yaml@v1
  pre-commit:
    uses: davidnlopes/Reusable.Workflows/.github/workflows/pre-commit-hooks.yaml@v1
  semantic-pr:
    uses: davidnlopes/Reusable.Workflows/.github/workflows/semantic-pr.yaml@v1
  labeler:
    uses: davidnlopes/Reusable.Workflows/.github/workflows/labeler.yaml@v1
```

Trivy reads ignore rules from `.trivyignore.yaml` when the file exists, and otherwise from `.trivyignore`. Only `.trivyignore.yaml` can limit a rule to some paths. On a `pull_request` event, Trivy also scans the base branch, and the check fails only on findings that the base branch does not have. A version bump of a package that is still vulnerable counts as new only when it adds an advisory. The PR comment lists the base branch's findings separately. Other events fail on every finding.

### Set up AWS access

`terraform.yaml` and `docker.yaml` sign in to AWS with GitHub OIDC, so they need no stored AWS keys. Before you call them, create an IAM role that trusts GitHub's OIDC provider for your repository, and pass its ARN as `awsRoleArn`.

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
