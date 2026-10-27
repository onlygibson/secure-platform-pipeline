# secure-platform-pipeline

> **Warning:** this application is **intentionally vulnerable**. It pins outdated dependencies and contains deliberate weaknesses so security tools have real findings to detect, triage, and fix. Do not deploy it anywhere public or reuse its code.

A hands-on platform engineering project: one small app taken from commit to Kubernetes with security gates at every stage, plus AI-assisted triage and governance.

## The idea

Phase 1 plays the **developer**: a simple Flask API with real-world problems.
Every later phase plays the **platform engineer**: building the guardrails, automation, and developer experience that secure it without slowing the team down.

## Roadmap

| Phase | Focus | Tools |
| --- | --- | --- |
| 1 | Foundation | Flask, Docker, kind, Argo CD |
| 2 | Code and dependency security | GitHub Advanced Security (CodeQL, secret scanning, push protection), Dependabot, Renovate |
| 3 | Containers and supply chain | Trivy, Syft, Grype, Cosign, JFrog Artifactory + Xray, Dependency-Track |
| 4 | IaC and cloud posture | Terraform, Checkov, KICS, Prowler |
| 5 | Policy enforcement | Kyverno |
| 6 | Dynamic testing | OWASP ZAP |
| 7 | Noise reduction | findings-hub (Go): merges and dedupes all scanner output |
| 8 | AI-assisted triage | LLM API with redaction and prompt-injection defenses |
| 9 | AI governance and compliance | AI tool policy, shadow-AI checks, SOC 2 control mapping |

## Known weaknesses (planted on purpose)

| Weakness | Where | Expected detection |
| --- | --- | --- |
| Outdated Flask, Jinja2, Werkzeug, requests, PyYAML, urllib3 | `app/requirements.txt` | Dependabot, Trivy, Grype, Xray |
| Unsafe YAML deserialization (`yaml.load`) | `app/app.py` `/config` | CodeQL |
| Old base image | `Dockerfile` | Trivy, Xray |
| Container runs as root | `Dockerfile` | Kyverno, Checkov |

## Run locally

```bash
docker build -t secure-platform-pipeline:0.1.0 .
docker run --rm -p 8080:8080 secure-platform-pipeline:0.1.0
curl localhost:8080/health
curl "localhost:8080/hello?name=Gibson"
```

## Run on Kubernetes with GitOps (kind + Argo CD)

1. Install `docker`, `kind`, and `kubectl`.
2. Replace `YOUR_GITHUB_USERNAME` in `argocd/application.yaml` and push.
3. Run `./scripts/setup-local.sh`. It builds the image, creates the cluster, installs Argo CD, and registers the app.
4. Argo CD now syncs `helm/secure-platform-pipeline` from `main` automatically.

## Repo layout

```
app/                 Flask API (the "developer's" service)
Dockerfile           Container build
helm/                Kubernetes chart, deployed by Argo CD
argocd/              Argo CD Application (GitOps)
kind/                Local cluster config
scripts/             Setup scripts
terraform/           Phase 4: AWS infrastructure
policies/            Phase 5: Kyverno policies
.github/workflows/   CI security gates
```

## Results

Before-and-after numbers are recorded here as each phase lands.

| Metric | Before | After |
| --- | --- | --- |
| Dependabot alerts | 41 |TBD
| Code scanning alerts | 1 | TBD |
| Critical/high CVEs in image | TBD | TBD |
| Findings shown to developers per PR | TBD | TBD |
