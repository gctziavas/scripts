#!/bin/bash

# SSH Setup Script for New Machines
# This script configures SSH with secure defaults and generates SSH keys

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if SSH is installed
check_ssh_installed() {
    if ! command -v ssh &> /dev/null; then
        print_error "SSH is not installed. Please install OpenSSH first."
        exit 1
    fi
    print_info "SSH is installed: $(ssh -V 2>&1)"
}

# Function to create .ssh directory with correct permissions
setup_ssh_directory() {
    local ssh_dir="$HOME/.ssh"
    
    if [ ! -d "$ssh_dir" ]; then
        print_info "Creating .ssh directory..."
        mkdir -p "$ssh_dir"
        chmod 700 "$ssh_dir"
        print_info ".ssh directory created with permissions 700"
    else
        print_info ".ssh directory already exists"
        chmod 700 "$ssh_dir"
        print_info "Ensured .ssh directory has correct permissions (700)"
    fi
}

# Function to generate SSH key
generate_ssh_key() {
    local ssh_dir="$HOME/.ssh"
    local key_type="${1:-ed25519}"
    local key_comment="${2:-$(whoami)@$(hostname)}"
    local key_file="$ssh_dir/id_$key_type"
    
    if [ -f "$key_file" ]; then
        print_warning "SSH key already exists at $key_file"
        read -p "Do you want to generate a new key? This will backup the existing key (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Skipping key generation"
            return
        fi
        # Backup existing key
        mv "$key_file" "$key_file.backup.$(date +%Y%m%d%H%M%S)"
        mv "$key_file.pub" "$key_file.pub.backup.$(date +%Y%m%d%H%M%S)"
        print_info "Backed up existing keys"
    fi
    
    print_info "Generating $key_type SSH key..."
    ssh-keygen -t "$key_type" -C "$key_comment" -f "$key_file"
    
    if [ -f "$key_file" ]; then
        chmod 600 "$key_file"
        chmod 644 "$key_file.pub"
        print_info "SSH key generated successfully!"
        print_info "Public key location: $key_file.pub"
        echo
        print_info "Your public key:"
        cat "$key_file.pub"
    else
        print_error "Failed to generate SSH key"
        exit 1
    fi
}

# Function to create SSH config file
create_ssh_config() {
    local ssh_config="$HOME/.ssh/config"
    
    if [ -f "$ssh_config" ]; then
        print_warning "SSH config file already exists"
        read -p "Do you want to backup and create a new config? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Skipping config creation"
            return
        fi
        mv "$ssh_config" "$ssh_config.backup.$(date +%Y%m%d%H%M%S)"
        print_info "Backed up existing config"
    fi
    
    print_info "Creating SSH config file..."
    cat > "$ssh_config" << 'EOF'
# SSH Client Configuration
# Add your host configurations below as needed

# Example:
# Host myserver
#     HostName example.com
#     User yourusername
#     Port 22
#     IdentityFile ~/.ssh/id_ed25519
EOF
    
    chmod 600 "$ssh_config"
    print_info "SSH config file created successfully"
}

# Function to start SSH agent and add key
setup_ssh_agent() {
    local key_type="${1:-ed25519}"
    local key_file="$HOME/.ssh/id_$key_type"
    
    if [ ! -f "$key_file" ]; then
        print_warning "SSH key not found at $key_file. Skipping agent setup."
        return
    fi
    
    print_info "Setting up SSH agent..."
    
    # Check if ssh-agent is running
    if [ -z "$SSH_AUTH_SOCK" ]; then
        eval "$(ssh-agent -s)"
        print_info "SSH agent started"
    else
        print_info "SSH agent already running"
    fi
    
    # Add key to agent
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS specific
        ssh-add --apple-use-keychain "$key_file" 2>/dev/null || ssh-add "$key_file"
    else
        ssh-add "$key_file"
    fi
    
    print_info "SSH key added to agent"
}

# Function to create authorized_keys file
setup_authorized_keys() {
    local auth_keys="$HOME/.ssh/authorized_keys"
    
    if [ ! -f "$auth_keys" ]; then
        print_info "Creating authorized_keys file..."
        touch "$auth_keys"
        chmod 600 "$auth_keys"
        print_info "authorized_keys file created"
    else
        print_info "authorized_keys file already exists"
        chmod 600 "$auth_keys"
    fi
}

# Function to display SSH information
display_ssh_info() {
    local ssh_dir="$HOME/.ssh"
    
    echo
    print_info "=========================================="
    print_info "SSH Setup Complete!"
    print_info "=========================================="
    echo
    print_info "SSH Directory: $ssh_dir"
    print_info "Contents:"
    ls -lah "$ssh_dir"
    echo
    
    if [ -f "$ssh_dir/id_ed25519.pub" ]; then
        print_info "Your Ed25519 public key:"
        cat "$ssh_dir/id_ed25519.pub"
        echo
    fi
    
    if [ -f "$ssh_dir/id_rsa.pub" ]; then
        print_info "Your RSA public key:"
        cat "$ssh_dir/id_rsa.pub"
        echo
    fi
    
    print_info "Next steps:"
    echo "  1. Copy your public key to remote servers:"
    echo "     ssh-copy-id user@hostname"
    echo "  2. Or manually add it to ~/.ssh/authorized_keys on the remote server"
    echo "  3. Test your connection: ssh user@hostname"
    echo "  4. Configure additional hosts in ~/.ssh/config"
}

# Main function
main() {
    echo "=========================================="
    echo "SSH Setup Script"
    echo "=========================================="
    echo
    
    # Check prerequisites
    check_ssh_installed
    
    # Setup SSH directory
    setup_ssh_directory
    
    # Ask for key type
    echo
    print_info "Select SSH key type:"
    echo "  1) Ed25519 (recommended - modern, secure, fast)"
    echo "  2) RSA 4096 (compatible with older systems)"
    read -p "Enter your choice (1-2) [default: 1]: " key_choice
    
    case $key_choice in
        2)
            key_type="rsa"
            key_bits="-b 4096"
            ;;
        *)
            key_type="ed25519"
            key_bits=""
            ;;
    esac
    
    # Get email/comment for key
    read -p "Enter your email for the SSH key comment [default: $(whoami)@$(hostname)]: " key_email
    key_email=${key_email:-"$(whoami)@$(hostname)"}
    
    # Generate SSH key
    if [ "$key_type" = "rsa" ]; then
        ssh-keygen -t rsa -b 4096 -C "$key_email" -f "$HOME/.ssh/id_rsa"
    else
        generate_ssh_key "$key_type" "$key_email"
    fi
    
    # Create SSH config
    create_ssh_config
    
    # Setup authorized_keys
    setup_authorized_keys
    
    # Setup SSH agent
    setup_ssh_agent "$key_type"
    
    # Display information
    display_ssh_info
    
    echo
    print_info "SSH setup completed successfully!"
}

# Run main function
main
