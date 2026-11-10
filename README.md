# DevSecOps Pipeline Template

A reusable GitHub Actions pipeline that adds security gates to any Python service:
SAST, secret scanning, dependency scanning, IaC scanning, and container scanning,
with results surfaced in the GitHub Security tab through SARIF.

> Demo project built on a sample app. It contains no employer code or data.

## What it does

| Stage | Tool | Catches |
|---|---|---|
| SAST | CodeQL | Insecure code patterns |
| Secrets | Gitleaks | Credentials committed to the repo |
| SCA | pip-audit | Known-vulnerable dependencies |
| IaC | Checkov | Terraform misconfigurations |
| Container | Trivy | HIGH/CRITICAL image vulnerabilities |
| Gate | `security-gate` job | Blocks merge unless all stages pass |

## Architecture

```
push / PR
   |
   +--> CodeQL -------+
   +--> Gitleaks -----+
   +--> pip-audit ----+--> security-gate --> merge allowed
   +--> Checkov ------+
   +--> Trivy --------+
```

## Use it in your own repo

1. Copy `.github/workflows/security.yml` into your repository.
2. Adjust the paths (`app/`, `terraform/`) and the CodeQL language.
3. In *Settings > Branches*, require the **Security gate** check on `main`.

## Results

Add your screenshots here:

- Passing run on `main`
- Failing run on a demo branch (see `docs/DEMO.md`)
- Security tab with SARIF findings

## Design decisions

- **Fail closed:** Trivy exits non-zero on HIGH/CRITICAL so builds can't ship them.
- **Least privilege:** workflow permissions are read-only except for uploading SARIF.
- **One gate job:** a single required check keeps branch protection simple.

## Roadmap

- [ ] Pin actions to commit SHAs
- [ ] Add SBOM generation (Syft) and image signing (Cosign)
- [ ] Add a DAST stage with OWASP ZAP against the running container
- [ ] Publish as a reusable workflow (`workflow_call`)
