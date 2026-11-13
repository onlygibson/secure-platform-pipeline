# secure-platform-pipeline

> **Note:** this application **started out intentionally vulnerable**: outdated dependencies and deliberate weaknesses, planted so security tools had real findings to detect, triage, and fix. The planted issues are now fixed (see [Planted weaknesses](#planted-weaknesses-and-how-they-were-fixed)), but it is still a practice project. Do not deploy it anywhere public.

A hands-on platform engineering project: one small app taken from commit to Kubernetes with security gates at every stage, plus AI-assisted triage and governance.

## The idea

Phase 1 plays the **developer**: a simple Flask API with real-world problems.
Every later phase plays the **platform engineer**: building the guardrails, automation, and developer experience that secure it without slowing the team down.

## Roadmap

| Phase | Focus | Tools | Status |
| --- | --- | --- | --- |
| 1 | Foundation | Flask, Docker, kind, Argo CD | Done |
| 2 | Code and dependency security | GitHub Advanced Security (CodeQL, secret scanning, push protection), Dependabot, Renovate | Done |
| 3 | Containers and supply chain | Trivy, Syft, Grype, Cosign, JFrog Artifactory + Xray, Dependency-Track | In progress: Trivy scans, SBOM, and Cosign signing are in CI |
| 4 | IaC and cloud posture | Terraform, Checkov, KICS, Prowler | In progress: Terraform manages the namespace and Kyverno |
| 5 | Policy enforcement | Kyverno | In progress: first policy written |
| 6 | Dynamic testing | OWASP ZAP | Planned |
| 7 | Noise reduction | findings-hub (Go): merges and dedupes all scanner output | Planned |
| 8 | AI-assisted triage | LLM API with redaction and prompt-injection defenses | Planned |
| 9 | AI governance and compliance | AI tool policy, shadow-AI checks, SOC 2 control mapping | Planned |

## Planted weaknesses and how they were fixed

| Weakness | Where | Detected by | Fix |
| --- | --- | --- | --- |
| Outdated Flask, Jinja2, Werkzeug, requests, PyYAML, urllib3 | `app/requirements.txt` | Dependabot | Upgraded to patched versions (#6) |
| Unsafe YAML deserialization (`yaml.load`) | `app/app.py` `/config` | CodeQL | Switched to `yaml.safe_load` (#7) |
| Old base image | `Dockerfile` | Dependabot, Trivy | Moved to `python:3.13-slim` and applied Debian security updates (#6, #24) |
| Container runs as root | `Dockerfile`, Helm chart | Trivy, Kyverno | Runs as UID 10001, and the chart enforces non-root (#15, #16) |

## Run locally

```bash
docker build -t secure-platform-pipeline:0.6.0 .
docker run --rm -p 8080:8080 secure-platform-pipeline:0.6.0
curl localhost:8080/health
curl "localhost:8080/hello?name=Gibson"
```

## Run on Kubernetes with GitOps (kind + Argo CD)

1. Install `docker`, `kind`, and `kubectl`.
2. Run `./scripts/setup-local.sh`. It builds the image, creates the cluster, installs Argo CD, and registers the app.
3. Argo CD now syncs `helm/secure-platform-pipeline` from `main` automatically.

If you fork this repo, point `repoURL` in `argocd/application.yaml` at your fork first.

## Repo layout

```
app/                 Flask API (the "developer's" service)
Dockerfile           Container build
helm/                Kubernetes chart, deployed by Argo CD
argocd/              Argo CD Application (GitOps)
kind/                Local cluster config
scripts/             Setup scripts
terraform/k8s/       Phase 4: namespace, app settings, and Kyverno install (Terraform)
policies/            Phase 5: Kyverno policies and test pods
.github/workflows/   CI security gates
```

## Results

| Metric | Before | After |
| --- | --- | --- |
| Dependabot alerts | 41 (2 critical, 14 high, 23 moderate, 2 low) | 0 |
| Code scanning alerts | 1 (critical: unsafe YAML deserialization) | 0 |
| Container user | root | Non-root (UID 10001), read-only filesystem, all capabilities dropped |
| Image vulnerability gate | None | Trivy fails the build on fixable HIGH/CRITICAL findings |
| SBOM | None | CycloneDX SBOM uploaded on every CI run |
| Image signing | None | Keyless Cosign signature on every image pushed to GHCR from `main` |
| Admission policy | None | Kyverno policy denies pods that do not set `runAsNonRoot` |

## Guardrails on `main`

Every change goes through a pull request. Nothing merges unless these pass:

| Check | What it blocks | How it was tested |
| --- | --- | --- |
| CI: build, scan, and smoke test | A broken build, fixable HIGH/CRITICAL image vulnerabilities, HIGH/CRITICAL Dockerfile or Helm misconfigurations, or a reintroduced `yaml.load` attack | First run failed on startup timing; fixed |
| Dependency review | PRs that add a library with a high or critical vulnerability | PR downgrading PyYAML to 5.3 was blocked while CI passed |
| CodeQL | Unsafe code patterns | Caught `yaml.load`; fixed with `yaml.safe_load` |
| Push protection | Pushes containing secrets | Throwaway token push rejected (GH013); token revoked |
| Branch ruleset | Direct pushes, force pushes, deleting `main` | Direct push to `main` rejected (GH013) |
