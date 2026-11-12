# Threat Model: DevSecOps Pipeline Template

**Status:** draft. This version covers scope, assets and trust boundaries. The data flow diagram and the STRIDE analysis come next.

## Scope

**In scope**

- The sample Flask app (`app/app.py`) and its Dockerfile
- The container image built on every pipeline run
- The GitHub Actions workflow (`.github/workflows/security.yml`)
- The repository, its branch protection ruleset, and its contributors
- Scanner output: SARIF results, the Security tab, and the ZAP report artifact
- The demo Terraform in `terraform/` (scanned only, never deployed)

**Out of scope for now**

- Any AWS deployment. The Terraform is not applied today. This document will be updated when that changes.
- The security of GitHub's own platform and hosted runners.

## What the system does

On every pull request, GitHub Actions builds the container and runs six scanners: CodeQL, Gitleaks, pip-audit, Checkov, Trivy and OWASP ZAP. A single required check, **Security gate**, must pass before a change can merge into `main`.

## Assets: what we are protecting

| ID | Asset | Why it matters | Where it lives |
|---|---|---|---|
| A1 | Source code and commit history | Tampering changes what ships and what gets scanned | GitHub repository |
| A2 | Pipeline definition (`security.yml`) | If it is altered, a gate can be weakened or removed | `.github/workflows/` |
| A3 | Branch protection ruleset and the Security gate | The control that blocks failing changes from `main` | GitHub repository settings |
| A4 | Workflow token (`GITHUB_TOKEN`) | The only credential the pipeline uses. Permissions are read-only except `security-events: write` | GitHub Actions runtime |
| A5 | Third-party code pulled into builds (actions, pip packages, base image) | A compromised dependency runs inside the pipeline | PyPI, Docker base image, action repositories |
| A6 | Container image | Contains the app and its OS packages | Built on the runner, not published |
| A7 | Scan results and reports | Altered or hidden results would give false assurance | Security tab, ZAP report artifact |
| A8 | Terraform demo code | Would define real cloud resources if it were applied | `terraform/main.tf` |
| A9 | Maintainer's GitHub account | Account takeover would bypass most other controls | GitHub |

**Secrets:** the repository stores no real secrets. Any credential-like value used for testing must be fake and clearly labeled.

## Actors

- **Maintainer:** the repository owner
- **External contributor:** anyone who can open a pull request or fork the public repo
- **Attacker:** an external contributor with bad intent, or someone who compromises a dependency or the maintainer's account
- **Third-party publishers:** maintainers of the actions, packages and images the pipeline depends on

## Trust boundaries

| ID | Boundary | What crosses it | Notes |
|---|---|---|---|
| TB1 | Internet and contributors / GitHub repository | Pull requests, forks, issues | The repo is public. Forked pull requests get a read-only token and no secrets by default |
| TB2 | Repository / GitHub Actions runner | Workflow code and repo contents | The workflow runs on a GitHub-hosted runner, so changes to `security.yml` change what runs |
| TB3 | Runner / third-party sources | Actions, pip packages, base image, scanner databases | Code and data from outside our control enter the build |
| TB4 | Runner / app container | HTTP traffic from ZAP and the health check | The container runs on a private Docker network, with port 8080 mapped to the runner's localhost only |
| TB5 | Pipeline / Security tab and artifacts | SARIF uploads and the ZAP report | Needs `security-events: write`. Results could be altered or suppressed |
| TB6 | Maintainer / GitHub account | Sign-in and sessions | Depends on account authentication settings (see open questions) |
| TB7 | Terraform / cloud account | Infrastructure changes | Not active today. It becomes a boundary when the app is deployed to AWS |

## Open questions to verify

- [ ] Is multi-factor authentication enabled on the maintainer's GitHub account?
- [ ] Are secret scanning and push protection enabled for the repository?
- [ ] Do all workflows use `pull_request` and avoid `pull_request_target`?
- [ ] Which workflow permissions could be reduced further?

## Next steps

1. Draw the data flow diagram with these boundaries (roadmap week 1, step 3).
2. Walk each asset and boundary through STRIDE and record threats (step 4).
3. Record the existing mitigation or the open gap for each threat (step 5).
