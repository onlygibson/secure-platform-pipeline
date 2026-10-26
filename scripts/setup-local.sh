#!/usr/bin/env bash
# Phase 1 local setup: kind cluster + Argo CD + the sample app via GitOps.
# Requires: docker, kind, kubectl. Run from the repo root.
set -euo pipefail

IMAGE="secure-platform-pipeline:0.1.0"

echo "==> Building image"
docker build -t "$IMAGE" .

echo "==> Creating kind cluster (skips if it exists)"
kind get clusters | grep -q '^spp$' || kind create cluster --config kind/cluster.yaml

echo "==> Loading image into kind"
kind load docker-image "$IMAGE" --name spp

echo "==> Installing Argo CD"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd --server-side -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd rollout status deploy/argocd-server --timeout=300s

echo "==> Registering the app with Argo CD"
if grep -q YOUR_GITHUB_USERNAME argocd/application.yaml; then
  echo "Edit argocd/application.yaml with your GitHub username, push, then rerun." >&2
  exit 1
fi
kubectl apply -f argocd/application.yaml

echo "==> Argo CD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
echo "UI:  kubectl -n argocd port-forward svc/argocd-server 8443:443  ->  https://localhost:8443"
echo "App: kubectl -n spp port-forward svc/secure-platform-pipeline 8080:80  ->  curl localhost:8080/health"
