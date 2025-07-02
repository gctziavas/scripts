#!/bin/bash

set -e

# Ensure we are running as a non-root user
if [ "$(id -u)" = "0" ]; then
    echo "❌ Please run this script as a non-root user, NOT with sudo."
    exit 1
fi

# Explicitly set KUBECONFIG env variable to user's kubeconfig path
export KUBECONFIG="$HOME/.kube/config"
LOCK_FILE="$HOME/.kube/config.lock"

# Clean up kubeconfig lock file if it exists
cleanup_lock_file() {
    if [ -f "$LOCK_FILE" ]; then
        echo "🧹 Removing existing kubeconfig lock file at $LOCK_FILE"
        rm -f "$LOCK_FILE"
    fi
}

# Function: Install kind if missing
install_kind() {
    if command -v kind &>/dev/null; then
        echo "✅ kind is already installed."
        return
    fi

    echo "🔧 Installing kind..."

    KIND_VERSION=$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | grep tag_name | cut -d '"' -f 4)
    KIND_BINARY_URL="https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}/kind-linux-amd64"

    curl -Lo ./kind "$KIND_BINARY_URL"
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind

    echo "✅ kind installed successfully."
}

# Function: Install kubectl if missing
install_kubectl_if_missing() {
    if ! command -v kubectl &>/dev/null; then
        echo "⚠️ kubectl not found, installing kubectl first..."
        curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
        echo "✅ kubectl installed."
    else
        echo "✅ kubectl is already installed."
    fi
}

# Function: Create kind cluster
create_cluster() {
    echo "🛠 Creating a kind Kubernetes cluster named 'kind-cluster'..."
    cleanup_lock_file
    kind create cluster --name kind-cluster --kubeconfig "$KUBECONFIG"
}

# Function: Verify cluster
verify_cluster() {
    echo "🔍 Verifying cluster nodes..."
    kubectl --kubeconfig "$KUBECONFIG" cluster-info --context kind-kind-cluster
    kubectl --kubeconfig "$KUBECONFIG" get nodes
}

# Run the steps
install_kubectl_if_missing
install_kind
create_cluster
verify_cluster

echo "🎉 kind Kubernetes cluster is ready!"
