#!/bin/bash

set -e

# K9s Installation Script for Ubuntu/Debian
# K9s is a terminal-based UI for Kubernetes clusters

K9S_VERSION="v0.32.7"  # Updated to latest stable version
ARCH="amd64"
OS="linux"

echo "🚀 Installing K9s - Kubernetes CLI To Manage Your Clusters In Style!"
echo "📦 Version: $K9S_VERSION"
echo ""

# Function to show help
show_help() {
    cat << EOF
K9s Installation Script

K9s is a terminal-based UI for Kubernetes clusters that provides a fast way to review 
and resolve day-to-day issues in Kubernetes environments.

Usage: $0 [OPTIONS]

OPTIONS:
    -v, --version VERSION    Specify K9s version to install (default: $K9S_VERSION)
    -h, --help              Show this help message

EXAMPLES:
    $0                      # Install default version
    $0 -v v0.32.6          # Install specific version

REQUIREMENTS:
    - Ubuntu/Debian system
    - sudo privileges
    - Internet connection

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            K9S_VERSION="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Validate version format
if [[ ! "$K9S_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "❌ Error: Invalid version format. Use format like 'v0.32.7'"
    exit 1
fi

# Create temporary directory for download
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

echo "📥 Downloading K9s $K9S_VERSION..."
DEB_FILE="k9s_${OS}_${ARCH}.deb"
DOWNLOAD_URL="https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_${OS}_${ARCH}.deb"

# Download with error handling
if ! wget -q --show-progress "$DOWNLOAD_URL" -O "$DEB_FILE"; then
    echo "❌ Error: Failed to download K9s from $DOWNLOAD_URL"
    echo "💡 Please check if the version $K9S_VERSION exists at: https://github.com/derailed/k9s/releases"
    exit 1
fi

echo "📦 Installing K9s package..."
sudo apt update -qq
sudo apt install -y "./$DEB_FILE"

echo "🧹 Cleaning up downloaded file..."
cd - > /dev/null
rm -rf "$TEMP_DIR"

echo "✅ Verifying installation..."
if command -v k9s &> /dev/null; then
    K9S_INSTALLED_VERSION=$(k9s version --short 2>/dev/null | head -1 || echo "Unable to get version")
    echo "   K9s version: $K9S_INSTALLED_VERSION"
else
    echo "❌ Error: K9s installation failed"
    exit 1
fi

echo ""
echo "🎉 K9s installation completed successfully!"
echo ""
echo "💡 Quick start:"
echo "   k9s                    # Launch K9s (requires kubeconfig)"
echo "   k9s --kubeconfig PATH  # Use specific kubeconfig"
echo "   k9s --context CONTEXT  # Use specific context"
echo "   k9s help               # Show help"
echo ""
echo "🔗 Resources:"
echo "   - Documentation: https://k9scli.io/"
echo "   - GitHub: https://github.com/derailed/k9s"
echo "   - Keyboard shortcuts: Press '?' in K9s"
