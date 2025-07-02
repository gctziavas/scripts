#!/bin/bash

set -e

# Docker Installation Script for Ubuntu
# This script installs Docker CE and Docker Compose

echo "🐳 Starting Docker installation..."

# Remove old versions of Docker
echo "🧹 Removing old Docker versions..."
apt-get remove -y docker docker-engine docker.io containerd runc || true

# Update package index
echo "📦 Updating package index..."
apt-get update

# Install prerequisites
echo "🔧 Installing prerequisites..."
apt-get install -y ca-certificates curl gnupg lsb-release python3-pip

# Add Docker's official GPG key
echo "🔑 Adding Docker's GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up the stable repository
echo "📋 Setting up Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index again
echo "📦 Updating package index with Docker repository..."
apt-get update

# Install Docker CE
echo "🐳 Installing Docker CE..."
apt-get install -y docker-ce docker-ce-cli containerd.io

# Show available Docker CE versions
echo "📋 Available Docker CE versions:"
apt-cache madison docker-ce

# Enable Docker services
echo "🚀 Enabling Docker services..."
systemctl enable docker.service
systemctl enable containerd.service

# Install Docker Compose
echo "🔨 Installing Docker Compose..."
mkdir -p ~/.docker/cli-plugins/
curl -SL https://github.com/docker/compose/releases/download/v2.2.3/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose
chmod +x ~/.docker/cli-plugins/docker-compose

# Set permissions for Docker socket
echo "🔐 Setting Docker socket permissions..."
chown $USER /var/run/docker.sock

# Copy Docker Compose to system-wide location
echo "📋 Installing Docker Compose system-wide..."
cp ~/.docker/cli-plugins/docker-compose /usr/local/bin/docker-compose

# Verify installations
echo "✅ Verifying Docker installation..."
docker --version

echo "✅ Verifying Docker Compose installation..."
docker-compose version

echo "🎉 Docker installation completed successfully!"
echo ""
echo "💡 Next steps:"
echo "   1. You may need to log out and back in for group permissions to take effect"
echo "   2. Test Docker: docker run hello-world"
echo "   3. Test Docker Compose: docker-compose --version"
echo ""
echo "🔧 Useful commands:"
echo "   - Start Docker: sudo systemctl start docker"
echo "   - Stop Docker: sudo systemctl stop docker"
echo "   - Check status: sudo systemctl status docker"
echo "   - Add user to docker group: sudo usermod -aG docker \$USER"
