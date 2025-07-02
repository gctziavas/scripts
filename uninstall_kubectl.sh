#!/bin/bash

set -e

echo "🧹 Uninstalling manually installed kubectl and kubectl-convert..."

# Remove kubectl and kubectl-convert binaries
sudo rm -f /usr/local/bin/kubectl
sudo rm -f /usr/local/bin/kubectl-convert
echo "✅ Removed binaries from /usr/local/bin"

# Detect current shell
CURRENT_SHELL=$(basename "$SHELL")
echo "💡 Detected shell: $CURRENT_SHELL"

# Function to remove lines from a file safely
remove_line() {
    local file=$1
    local pattern=$2
    grep -q "$pattern" "$file" && sed -i "/$pattern/d" "$file"
}

# Remove kubectl completion and alias from shell config
if [[ "$CURRENT_SHELL" == "bash" ]]; then
    echo "🔧 Cleaning ~/.bashrc..."
    remove_line ~/.bashrc "kubectl completion bash"
    remove_line ~/.bashrc "alias k=kubectl"
    remove_line ~/.bashrc "complete -o default -F __start_kubectl k"
    remove_line ~/.bashrc "bash_completion"
    source ~/.bashrc
elif [[ "$CURRENT_SHELL" == "zsh" ]]; then
    echo "🔧 Cleaning ~/.zshrc..."
    remove_line ~/.zshrc "kubectl completion zsh"
    remove_line ~/.zshrc "autoload -Uz compinit"
    remove_line ~/.zshrc "compinit"
    source ~/.zshrc
else
    echo "⚠️ Unsupported shell: $CURRENT_SHELL. Please manually clean your shell config."
fi

echo "✅ kubectl and kubectl-convert uninstalled successfully."
