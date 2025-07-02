#!/bin/bash

# Script to find kubeconfig file and create a new kubeconfig.yaml in current directory
# Author: Generated script
# Date: July 2, 2025

set -e  # Exit on any error

echo "=== Kubernetes Config Copy Script ==="
echo "Current directory: $(pwd)"
echo

# Function to check if a file exists and is not empty
check_file() {
    local file_path="$1"
    if [[ -f "$file_path" && -s "$file_path" ]]; then
        return 0  # File exists and is not empty
    else
        return 1  # File doesn't exist or is empty
    fi
}

# Array of common kubeconfig locations to check
KUBECONFIG_LOCATIONS=(
    "$HOME/.kube/config"
    "$KUBECONFIG"
    "/etc/kubernetes/admin.conf"
    "/etc/kubernetes/kubelet.conf"
    "$HOME/kubeconfig"
    "$HOME/.kubeconfig"
)

echo "Searching for kubeconfig files..."
FOUND_CONFIG=""

# Check each location
for location in "${KUBECONFIG_LOCATIONS[@]}"; do
    if [[ -n "$location" ]] && check_file "$location"; then
        echo "✓ Found kubeconfig at: $location"
        FOUND_CONFIG="$location"
        break
    elif [[ -n "$location" ]]; then
        echo "✗ Not found or empty: $location"
    fi
done

# Also search for any files with "kubeconfig" in the name
echo
echo "Searching for files with 'kubeconfig' in name..."
SEARCH_RESULTS=$(find "$HOME" -name "*kubeconfig*" -type f 2>/dev/null | head -5)

if [[ -n "$SEARCH_RESULTS" ]]; then
    echo "Found additional kubeconfig files:"
    while IFS= read -r file; do
        if check_file "$file" && [[ -z "$FOUND_CONFIG" ]]; then
            echo "✓ $file (using this one)"
            FOUND_CONFIG="$file"
        else
            echo "  $file"
        fi
    done <<< "$SEARCH_RESULTS"
fi

echo

# Check if we found a valid kubeconfig
if [[ -z "$FOUND_CONFIG" ]]; then
    echo "❌ ERROR: No valid kubeconfig file found!"
    echo "Please ensure you have a kubeconfig file in one of the standard locations:"
    printf '  %s\n' "${KUBECONFIG_LOCATIONS[@]}"
    exit 1
fi

echo "📋 Using kubeconfig from: $FOUND_CONFIG"

# Create the target file path
TARGET_FILE="$(pwd)/kubeconfig.yaml"

# Check if target file already exists
if [[ -f "$TARGET_FILE" ]]; then
    echo "⚠️  Target file already exists: $TARGET_FILE"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        exit 0
    fi
fi

# Copy the kubeconfig content
echo "📝 Copying kubeconfig content to: $TARGET_FILE"

if cp "$FOUND_CONFIG" "$TARGET_FILE"; then
    echo "✅ Successfully created kubeconfig.yaml"
    
    # Display file info
    echo
    echo "File details:"
    echo "  Source: $FOUND_CONFIG"
    echo "  Target: $TARGET_FILE"
    echo "  Size: $(du -h "$TARGET_FILE" | cut -f1)"
    
    # Show first few lines to verify content
    echo
    echo "Content preview (first 10 lines):"
    echo "---"
    head -10 "$TARGET_FILE"
    echo "---"
    
    # Check if it's a valid YAML file
    if command -v yq >/dev/null 2>&1; then
        echo
        if yq eval . "$TARGET_FILE" >/dev/null 2>&1; then
            echo "✅ YAML syntax is valid"
        else
            echo "⚠️  YAML syntax check failed"
        fi
    elif command -v python3 >/dev/null 2>&1; then
        echo
        if python3 -c "import yaml; yaml.safe_load(open('$TARGET_FILE'))" 2>/dev/null; then
            echo "✅ YAML syntax is valid"
        else
            echo "⚠️  YAML syntax check failed"
        fi
    fi
    
    # Test kubectl access if kubectl is available
    if command -v kubectl >/dev/null 2>&1; then
        echo
        echo "Testing cluster access..."
        if KUBECONFIG="$TARGET_FILE" kubectl cluster-info --request-timeout=5s >/dev/null 2>&1; then
            echo "✅ Cluster is accessible with the new kubeconfig"
        else
            echo "⚠️  Could not connect to cluster (this might be expected)"
        fi
    fi
    
else
    echo "❌ ERROR: Failed to copy kubeconfig file"
    exit 1
fi

echo
echo "🎉 Script completed successfully!"
echo "You can now use the kubeconfig.yaml file in the current directory."
echo "To use it with kubectl: export KUBECONFIG=$(pwd)/kubeconfig.yaml"
