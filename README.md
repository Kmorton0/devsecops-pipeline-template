# DevSecOps Pipeline Template

A reusable GitHub Actions pipeline that adds security gates to a Python service: static analysis, secret scanning, dependency scanning, infrastructure-as-code scanning, and container scanning. Findings flow into the GitHub Security tab as SARIF, and a single required check blocks merges that fail.

> Demo project built on a sample app. It contains no employer code, configuration, or data.

## What it does

| Stage | Tool | Catches |
|---|---|---|
| SAST | CodeQL | Insecure code patterns |
| Secrets | Gitleaks | Credentials committed to the repo |
| SCA | pip-audit | Known-vulnerable Python dependencies |
| IaC | Checkov | Terraform misconfigurations |
| Container | Trivy | HIGH/CRITICAL image vulnerabilities |
| Gate | `security-gate` job | Blocks merging unless every stage passes |

```
push / pull request
   |
   +--> CodeQL -------+
   +--> Gitleaks -----+
   +--> pip-audit ----+--> Security gate --> merge allowed
   +--> Checkov ------+
   +--> Trivy --------+
```

## Repository layout

```
.github/workflows/security.yml   the pipeline
app/                             sample Flask app, Dockerfile, requirements
terraform/main.tf                demo S3 + KMS infrastructure (scanned, never deployed)
docs/DEMO.md                     steps to trigger failing checks on purpose
```

## Branch protection

`main` is protected by a repository ruleset that requires the **Security gate** status check. Changes go through pull requests, and the merge button stays disabled until all five scanners pass. Pull request #1 ran all checks (five scanner jobs, three code-scanning results, and the gate) before merging.

## Results

Real findings the pipeline caught while I was building it, and what I did about each:

### 1. Vulnerable dependency (SCA)
pip-audit flagged **Flask 3.0.3** with a known vulnerability (fixed in 3.1.3). I upgraded the pin, and the Trivy report later confirmed every Python package in the image shows **0 vulnerabilities**.

### 2. Infrastructure misconfigurations (IaC)
Checkov reported **5 failed checks** on the first version of the S3 bucket. Triage:

| Check | Decision |
|---|---|
| Encryption with KMS | **Fixed:** added a KMS key with rotation and a key policy |
| Access logging | **Fixed:** added a log bucket and logging configuration |
| Lifecycle configuration | **Fixed:** added expiration and cleanup rules |
| Event notifications | **Skipped:** not needed for a demo bucket (reason documented in code) |
| Cross-region replication | **Skipped:** out of scope for a demo bucket (reason documented in code) |

Skips use `checkov:skip` comments with a written justification, so every exception is reviewable. The log bucket also skips self-logging to avoid a logging loop.

### 3. Container vulnerabilities (Trivy)
Trivy found **49 HIGH findings** in the Debian 13.7 base image, all in OS packages, none in Python code. Most were the same few CVEs repeated across packages (for example, util-linux issues listed under eight packages), and most had **no vendor fix available yet** (status `affected` or `fix_deferred`). Triage:

- Added `apt-get upgrade` to the Dockerfile to pick up available patches (this covered the fixable zlib findings).
- Configured the gate with `ignore-unfixed: true`, so builds fail on vulnerabilities that **can** be patched rather than on ones nobody can fix yet.
- Kept a separate readable report step that prints **all** HIGH/CRITICAL findings, so nothing is hidden.

### 4. Code scanning dashboard
After the fixes, GitHub's Code scanning page showed **200 closed alerts** from earlier runs and **5 open** ones. The 5 open alerts were Checkov's reports of the checks I deliberately skipped (above). I dismissed each as **Won't fix** with a written reason, so the dashboard now records the same decision as the `checkov:skip` comments. CodeQL and Trivy had no open alerts.

### Screenshots

![Passing pipeline run](docs/images/passing-run.png)
*A passing run: all five scanners finish green and the Security gate unlocks merging.*

![Failing pull request blocked by the gate](docs/images/failing-pr.png)
*A pull request with a deliberate misconfiguration: Checkov fails, the Security gate does not pass, and the merge button is disabled.*

![Code scanning dashboard](docs/images/code-scanning.png)
*The Code scanning dashboard after the fixes: 200 earlier alerts closed, and the deliberately skipped checks dismissed with written reasons.*

## Using it in your own repo

1. Copy `.github/workflows/security.yml` into your repository.
2. Adjust the paths (`app/`, `terraform/`) and the CodeQL language.
3. Enable code scanning under *Settings > Advanced Security* so SARIF results appear in the Security tab.
4. Run the pipeline once so the **Security gate** check exists.
5. Under *Settings > Rules > Rulesets*, create a branch ruleset for the default branch that requires the **Security gate** check.

## Design decisions

- **Fail closed, but on actionable findings.** Trivy blocks on fixable HIGH/CRITICAL vulnerabilities; unfixed ones stay visible in the report.
- **Least privilege.** Workflow permissions are read-only except `security-events: write` for uploading SARIF.
- **One required check.** A single gate job keeps branch protection simple as scanners are added or swapped.
- **Documented exceptions.** Every skipped check carries a written reason.

## Lessons learned

- Action versions need checking. A pinned `trivy-action` tag I started with no longer existed, and the project's release notes mention a previously compromised release. Tags can move, so pinning to a commit SHA is the stronger practice (see roadmap).
- Scanner output needs triage. 49 findings turned out to be about a dozen distinct CVEs, most without fixes.
- SARIF output ignores severity filters unless told otherwise (`limit-severities-for-sarif`), which can make a gate fail on findings you never meant to block on.

## Roadmap

- [ ] Pin all actions to commit SHAs
- [ ] Add SBOM generation (Syft) and image signing (Cosign)
- [ ] Add a DAST stage with OWASP ZAP against the running container
- [ ] Move to a minimal or distroless base image to shrink the OS attack surface
- [ ] Publish as a reusable workflow (`workflow_call`)
- [ ] Add a scheduled run to catch newly published CVEs
