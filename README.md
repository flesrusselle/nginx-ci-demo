# nginx-ci-demo

A working CI/CD demo for a minimal nginx static site using GitHub Actions.

Features
- Build Docker image with buildx and push to GitHub Container Registry (GHCR)
- Image scanning in CI with Trivy and Grype
- Lint + validation workflow that runs on PRs and feature-branch commits
- Ephemeral Kubernetes (kind) in CI + Helm chart for end-to-end deployment inside Actions

Repository layout
- Dockerfile, .dockerignore: container build files
- app/: static nginx site and config
- chart/nginx-demo/: Helm chart used for deploying to Kubernetes
- .github/workflows/
  - build-and-scan.yml: builds image, runs scans, pushes to GHCR, triggers deploy workflow
  - deploy-kind.yml: creates a kind cluster, installs Helm, deploys the chart, verifies
  - validation.yml: runs on pull_request and on push to branches; runs linters and chart validation

Quick demo (what CI does)
1. Push or open a PR to main. On push to main the build-and-scan workflow runs: builds image, scans it, and pushes to ghcr.io/${{ github.repository_owner }}/nginx-ci-demo:${{ github.sha }}.
2. When the build workflow succeeds it triggers the deploy-kind workflow which spins up a kind cluster and deploys the Helm chart using the just-built image.
3. The validation workflow runs on PRs (opened/synchronize/reopened) and on pushes to feature branches — it runs hadolint and helm lint.

Notes on GHCR visibility
- For the simplest demo make the repo public (this repo is public). When packages are created by Actions they’re publicly accessible (packages visibility must be set in package settings if needed). The workflows in this repo use the GITHUB_TOKEN to push to GHCR; GitHub Actions provide the required permissions in the workflow.

License: MIT
