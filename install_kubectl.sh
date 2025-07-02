#!/bin/bash

set -e

# Function: Check and install kubectl
install_kubectl() {
    echo "🔧 Downloading latest kubectl..."
    KUBECTL_VERSION=$(curl -Ls https://dl.k8s.io/release/stable.txt)
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    curl -LO "https://dl.k8s.io/${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256"

    echo "🔒 Verifying kubectl checksum..."
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check

    echo "✅ Installing kubectl..."
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl.sha256 kubectl

    CURRENT_SHELL=$(basename "$SHELL")
    echo "💡 Detected shell: $CURRENT_SHELL"

    if [[ "$CURRENT_SHELL" == "bash" ]]; then
        echo "💡 Addid export line to ~/.bashrc..."
        if ! grep -q 'export PATH=$PATH:/usr/local/bin' ~/.bashrc; then
            echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
        fi
        echo "🔄 Reloading ~/.bashrc..."
        source ~/.bashrc
    elif [[ "$CURRENT_SHELL" == "zsh" ]]; then
        echo "💡 Adding export line to ~/.zshrc..."
        if ! grep -q 'export PATH=$PATH:/usr/local/bin' ~/.zshrc; then
            echo 'export PATH=$PATH:/usr/local/bin' >> ~/.zshrc
        fi
        echo "🔄 Reloading ~/.zshrc"
        source ~/.zshrc
    else
        echo "⚠️ Unsupported shell: $CURRENT_SHELL. Please add 'export PATH' manually to your shell configuration file."
    fi
}

# Function: Set up shell autocompletion
setup_completion() {
    CURRENT_SHELL=$(basename "$SHELL")
    echo "💡 Detected shell: $CURRENT_SHELL"

    if [[ "$CURRENT_SHELL" == "bash" ]]; then
        echo "📦 Installing bash-completion..."
        if ! dpkg -s bash-completion &>/dev/null; then
            sudo apt-get update
            sudo apt-get install -y bash-completion
        fi

        if ! grep -q '/usr/share/bash-completion/bash_completion' ~/.bashrc; then
            echo "💡 Enabling bash-completion in ~/.bashrc..."
            echo 'source /usr/share/bash-completion/bash_completion' >> ~/.bashrc
        fi

        if ! grep -q 'source <(kubectl completion bash)' ~/.bashrc; then
            echo "⚙️  Adding kubectl completion to ~/.bashrc..."
            echo 'source <(kubectl completion bash)' >> ~/.bashrc
        fi

        if ! grep -q 'alias k=kubectl' ~/.bashrc; then
            echo "🔁 Adding kubectl alias 'k' and completion..."
            echo 'alias k=kubectl' >> ~/.bashrc
            echo 'complete -o default -F __start_kubectl k' >> ~/.bashrc
        fi

        echo "🔄 Reloading ~/.bashrc..."
        source ~/.bashrc

    elif [[ "$CURRENT_SHELL" == "zsh" ]]; then
        echo "⚙️  Setting up kubectl autocompletion for Zsh..."

        if ! grep -q 'autoload -Uz compinit' ~/.zshrc; then
            echo "🔧 Enabling compinit in ~/.zshrc..."
            echo 'autoload -Uz compinit' >> ~/.zshrc
            echo 'compinit' >> ~/.zshrc
        fi

        if ! grep -q 'source <(kubectl completion zsh)' ~/.zshrc; then
            echo "📜 Adding kubectl zsh completion to ~/.zshrc..."
            echo 'source <(kubectl completion zsh)' >> ~/.zshrc
        fi

        echo "⚠️ Please restart your terminal session or run 'source ~/.zshrc' manually in your Zsh shell to activate changes."

    else
        echo "⚠️ Unsupported shell: $CURRENT_SHELL. Manual configuration may be required."
    fi
}

# Function: Install kubectl-convert plugin
install_kubectl_convert() {
    echo "📦 Downloading kubectl-convert plugin..."
    KUBECTL_VERSION=$(curl -Ls https://dl.k8s.io/release/stable.txt)
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl-convert"
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl-convert.sha256"

    echo "🔒 Verifying kubectl-convert checksum..."
    echo "$(cat kubectl-convert.sha256)  kubectl-convert" | sha256sum --check

    echo "✅ Installing kubectl-convert..."
    sudo install -o root -g root -m 0755 kubectl-convert /usr/local/bin/kubectl-convert

    echo "🧪 Verifying plugin installation..."
    if kubectl convert --help &>/dev/null; then
        echo "✅ kubectl-convert installed successfully."
    else
        echo "❌ kubectl-convert installation failed."
    fi

    echo "🧹 Cleaning up kubectl-convert files..."
    rm kubectl-convert kubectl-convert.sha256
}

# Run all setup steps
install_kubectl
setup_completion
install_kubectl_convert

echo "🎉 All tools installed and configured successfully."
