# Demo: make the pipeline fail on purpose

Showing a failing run next to a passing one is the best proof the gates work.
Do these on a throwaway branch (e.g. `demo/failing-checks`) and screenshot the results.

1. **Secret scanning:** add a clearly fake credential to a file, e.g.
   `AWS_SECRET_ACCESS_KEY = "EXAMPLEKEYDONOTUSE000000000000000000000"`.
   Gitleaks should flag it. Never use a real secret.
2. **SCA:** pin an old, known-vulnerable package in `app/requirements.txt`
   and watch `pip-audit` fail.
3. **IaC:** remove the `aws_s3_bucket_public_access_block` resource in
   `terraform/main.tf` and watch Checkov report it.
4. **Container:** switch the Dockerfile base image to an old tag
   (e.g. `python:3.8`) and watch Trivy report HIGH/CRITICAL findings.

Then open a pull request for each and capture:
- the failing run (gate blocks the merge)
- the Security tab populated with SARIF results
- the passing run on `main`
