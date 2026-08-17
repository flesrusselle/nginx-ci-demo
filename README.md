# nginx-ci-demo

[![Build and Scan](https://github.com/flesrusselle/nginx-ci-demo/actions/workflows/build-and-scan.yml/badge.svg)](https://github.com/flesrusselle/nginx-ci-demo/actions/workflows/build-and-scan.yml)
[![Deploy (kind)](https://github.com/flesrusselle/nginx-ci-demo/actions/workflows/deploy-kind.yml/badge.svg)](https://github.com/flesrusselle/nginx-ci-demo/actions/workflows/deploy-kind.yml)
[![Validation (PR)](https://github.com/flesrusselle/nginx-ci-demo/actions/workflows/validation.yml/badge.svg)](https://github.com/flesrusselle/nginx-ci-demo/actions/workflows/validation.yml)
[![Publish Chart (Pages)](https://github.com/flesrusselle/nginx-ci-demo/actions/workflows/publish-chart.yml/badge.svg)](https://github.com/flesrusselle/nginx-ci-demo/actions/workflows/publish-chart.yml)

[![Helm Repo](https://img.shields.io/website?down_color=lightgrey&down_message=unavailable&label=Helm%20Repo&up_message=available&url=https%3A%2F%2Fflesrusselle.github.io%2Fnginx-ci-demo)](https://flesrusselle.github.io/nginx-ci-demo)

A working CI/CD demo for a minimal nginx static site using GitHub Actions.

Features
- Build Docker image with buildx and push to GitHub Container Registry (GHCR)
- Image scanning in CI with Trivy and Grype
- SBOM generation (Syft) and artifact upload
- Lint + validation workflow that runs on PRs and feature-branch commits
- Ephemeral Kubernetes (kind) in CI + Helm chart for end-to-end deployment inside Actions
- Publish Helm chart to GitHub Pages (Helm repo)

Repository layout
- Dockerfile, .dockerignore: container build files
- app/: static nginx site and config
- chart/nginx-demo/: Helm chart used for deploying to Kubernetes
- .github/workflows/
  - build-and-scan.yml: builds image, runs scans, generates SBOM, pushes to GHCR
  - deploy-kind.yml: creates a kind cluster, installs Helm, deploys the chart, verifies
  - validation.yml: runs on pull_request and on push to non-main branches; runs linters and chart validation
  - publish-chart.yml: packages Helm chart and publishes to GitHub Pages (Helm repo)

Quick demo (what CI does)
1. Push or open a PR to main. On push to main the build-and-scan workflow runs: builds image, runs hadolint, generates SBOM, scans with Trivy & Grype, and pushes the image to ghcr.io/${{ github.repository_owner }}/nginx-ci-demo:${{ github.sha }}.
2. When the build workflow succeeds it triggers the deploy-kind workflow which spins up a kind cluster and deploys the Helm chart using the just-built image.
3. The publish-chart workflow runs on push to main and packages + publishes the Helm chart to GitHub Pages as a Helm repository.
4. The validation workflow runs on PRs (opened/synchronize/reopened) and on pushes to non-main branches — it runs hadolint and helm lint.

Helm repo (GitHub Pages)
- The workflows publish the packaged Helm chart to GitHub Pages at:
  https://flesrusselle.github.io/nginx-ci-demo
- Add this repo to Helm with:
  helm repo add nginx-ci-demo https://flesrusselle.github.io/nginx-ci-demo
  helm repo update
  helm search repo nginx-ci-demo

SBOMs
- The build workflow generates an SBOM for the pushed image using Syft and uploads it as a workflow artifact named `sbom`.
- You can download SBOMs from the Actions run artifacts for inspection or compliance.

One-command demo: trigger build and download SBOM (gh CLI)
We added a small helper script that uses the GitHub CLI (gh) to trigger the build-and-scan workflow and download the `sbom` artifact when the run completes.

Prerequisites
- GitHub CLI installed and authenticated (gh auth login)

Usage
- Run the script from the repository root:
  scripts/trigger_and_fetch_sbom.sh

What it does
1. Triggers the `build-and-scan` workflow via `gh workflow run`.
2. Polls for the most recent run of that workflow on the main branch.
3. When the run completes, downloads the `sbom` artifact into the local artifacts/ directory.

Local development and testing (macOS)
These commands show how to build & deploy locally to a kind cluster on macOS and access the site.

Prerequisites
- Homebrew
- Docker Desktop (or Docker Engine)
- kind: brew install kind
- kubectl: brew install kubectl
- helm: brew install helm

Option A — Pull image from GHCR (public image)
1. Build & push via GitHub Actions (or use an existing image published by the workflow).
2. Create a local kind cluster:
   kind create cluster
3. Install chart from Helm repo (published to GitHub Pages by the CI):
   helm repo add nginx-ci-demo https://flesrusselle.github.io/nginx-ci-demo
   helm repo update
   helm install my-nginx nginx-ci-demo/nginx-ci-demo --namespace demo --create-namespace --set image.repository=ghcr.io/flesrusselle/nginx-ci-demo --set image.tag=latest
4. Port-forward to access locally:
   kubectl port-forward -n demo svc/nginx-ci-demo 8080:80
   open http://127.0.0.1:8080

Option B — Use a locally-built image and load into kind (recommended for iterative development)
1. Build locally:
   docker build -t ghcr.io/flesrusselle/nginx-ci-demo:local .
2. Create kind cluster if not exists:
   kind create cluster
3. Load image into kind:
   kind load docker-image ghcr.io/flesrusselle/nginx-ci-demo:local
4. Install chart from local path, overriding to use local tag:
   helm install my-nginx ./chart/nginx-demo --namespace demo --create-namespace --set image.repository=ghcr.io/flesrusselle/nginx-ci-demo --set image.tag=local
5. Port-forward and open:
   kubectl port-forward -n demo svc/nginx-ci-demo 8080:80
   open http://127.0.0.1:8080

Notes
- If using GHCR images, ensure image visibility and package permissions. For a public repo, images may be pulled without auth. For private scenarios, configure docker login to ghcr.io using a PAT.
- The workflows use the built-in GITHUB_TOKEN and request packages: write permission for publishing images.
- SBOMs and scan results are available as Actions artifacts / logs.

Troubleshooting
- Build or push fails: check Actions logs; if GHCR push fails you may need a PAT with write:packages and set it as secret.GPR_PAT
- Kind cluster pod pending: check resource constraints on the runner; restart or reduce resource requests.

Badge details
- Build and Scan: runs build, scan, SBOM generation, and pushes images to GHCR
- Deploy (kind): triggered after a successful build on main to deploy into ephemeral kind
- Validation (PR): runs on pull requests and non-main pushes (hadolint, helm lint)
- Publish Chart (Pages): packages chart and deploys to GitHub Pages
- Helm Repo: availability check of the published Helm chart index (via shields.io website badge)

License: MIT
