# secure-platform-pipeline

A small Flask API that I shipped with security problems on purpose, then fixed one by one and built automated checks so they cannot come back.

> **Note:** this is a practice project. The app started out vulnerable by design. The problems below are fixed, but do not deploy it anywhere public.

## What this project shows

1. **Find** real security problems with standard tools (Dependabot, CodeQL, Trivy).
2. **Fix** each one at its root cause, not just the symptom.
3. **Prevent** it from returning with a check that blocks the pull request.

## How a change gets to the cluster

```
Pull request
   -> CI builds the image
   -> Trivy scans the image, Dockerfile, and Helm chart
   -> Smoke tests run against the live container
   -> CodeQL and dependency review run
Merge to main
   -> Image is pushed to GHCR and signed with Cosign
   -> Argo CD syncs the Helm chart to the kind cluster
   -> A Kyverno policy denies pods that are not set to run as non-root
```

## Problems found, root causes, and fixes

| Problem | Root cause | Fix | What stops it coming back |
| --- | --- | --- | --- |
| 41 vulnerable dependency alerts | Libraries were pinned to years-old versions (Flask 0.12.2, PyYAML 5.3, requests 2.19.1, and others), and nothing checked them for known CVEs | Upgraded every library to a patched version (#6) | Dependabot alerts, plus dependency review blocks any PR that adds a high or critical vulnerability |
| Remote code execution through `/config` | The endpoint parsed user input with `yaml.load` and the full `Loader`, which lets a YAML payload create Python objects and run commands | Switched to `yaml.safe_load`, which only builds plain data (#7) | CodeQL on every PR, plus a CI test that sends an attack payload and fails if it is accepted |
| Outdated base image | The Dockerfile used `python:3.8-slim`, which is past end of life and no longer gets security patches | Moved to `python:3.13-slim` (#6) | Trivy fails the build on fixable HIGH or CRITICAL findings |
| 8 vulnerabilities from pip inside the image | pip was left in the final image. The app never uses it at runtime, but its bundled libraries carried known CVEs | Uninstall pip after installing dependencies (#14) | Trivy image scan |
| zlib CVEs in the image | The base image's OS packages were behind on Debian security updates | Run `apt-get upgrade` during the build (#24) | Trivy image scan |
| Container ran as root | The Dockerfile had no `USER` line, so Docker used root by default | Created an unprivileged user (UID 10001) and switched to it (#15) | Helm chart sets `runAsNonRoot`, and a Kyverno policy denies pods that do not |
| Pod had more privileges than it needed | The Helm chart set no security context or resource limits | Read-only filesystem, all capabilities dropped, no privilege escalation, seccomp profile, CPU and memory limits (#16) | Trivy config scan of the chart |

## Results

| Metric | Before | After |
| --- | --- | --- |
| Dependabot alerts | 41 (2 critical, 14 high, 23 moderate, 2 low) | 0 |
| Code scanning alerts | 1 (critical: unsafe YAML deserialization) | 0 |
| Container user | root | Non-root (UID 10001) |
| Image vulnerability gate | None | Build fails on fixable HIGH or CRITICAL findings |
| SBOM | None | CycloneDX SBOM saved on every CI run |
| Image signing | None | Every image pushed from `main` is signed with Cosign |

## Guardrails on `main`

Every change goes through a pull request. Nothing merges unless these pass:

| Check | What it blocks | How I tested it |
| --- | --- | --- |
| CI: build, scan, and smoke test | A broken build, a vulnerable image, a misconfigured Dockerfile or chart, or a reintroduced `yaml.load` attack | First run failed on startup timing; fixed |
| Dependency review | PRs that add a library with a high or critical vulnerability | A PR downgrading PyYAML to 5.3 was blocked while CI passed |
| CodeQL | Unsafe code patterns | Caught `yaml.load`; fixed with `yaml.safe_load` |
| Push protection | Pushes that contain secrets | A throwaway token push was rejected (GH013); token revoked |
| Branch ruleset | Direct pushes, force pushes, deleting `main` | A direct push to `main` was rejected (GH013) |

## Tools used

| Area | Tools |
| --- | --- |
| App and container | Python, Flask, Docker |
| CI/CD | GitHub Actions, GHCR, Argo CD (GitOps) |
| Kubernetes | kind, Helm |
| Security scanning | Dependabot, CodeQL, secret scanning with push protection, Trivy |
| Supply chain | CycloneDX SBOM, Cosign keyless signing |
| Infrastructure as code | Terraform (namespace, app settings, Kyverno install) |
| Policy | Kyverno |

## Run it locally

```bash
docker build -t secure-platform-pipeline:0.6.0 .
docker run --rm -p 8080:8080 secure-platform-pipeline:0.6.0
curl localhost:8080/health
curl "localhost:8080/hello?name=Gibson"
```

## Run it on Kubernetes (kind + Argo CD)

1. Install `docker`, `kind`, and `kubectl`.
2. Run `./scripts/setup-local.sh`. It builds the image, creates the cluster, installs Argo CD, and registers the app.
3. Argo CD now syncs `helm/secure-platform-pipeline` from `main` automatically.

If you fork this repo, point `repoURL` in `argocd/application.yaml` at your fork first.

## Repo layout

```
app/                 Flask API
Dockerfile           Container build
helm/                Kubernetes chart, deployed by Argo CD
argocd/              Argo CD Application (GitOps)
kind/                Local cluster config
scripts/             Local setup script
terraform/k8s/       Namespace, app settings, and Kyverno install
policies/            Kyverno policies and test pods
.github/workflows/   CI: build, scan, test, publish, sign
```
