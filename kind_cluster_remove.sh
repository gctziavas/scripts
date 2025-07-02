#!/bin/bash

set -e

unset KUBECONFIG

KUBECONFIG_PATH="$HOME/.kube/config"
LOCK_FILE="$HOME/.kube/config.lock"
KIND_CLUSTER_NAME="kind-cluster"

echo "🧹 Deleting kind cluster named '$KIND_CLUSTER_NAME'..."
kind delete cluster --name "$KIND_CLUSTER_NAME" --kubeconfig "$KUBECONFIG_PATH" || echo "⚠️ Cluster not found or already deleted."

echo "🧹 Removing kubeconfig file and lock if they exist..."
rm -f "$KUBECONFIG_PATH"
rm -f "$LOCK_FILE"

echo "✅ Cleanup done."
