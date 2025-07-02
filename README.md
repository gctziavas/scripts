# Scripts Collection

A collection of useful scripts for development, deployment, and automation tasks. This repository contains scripts for various purposes including Kubernetes management, development tools, and general automation utilities.

## 📁 Current Scripts

### Kubernetes & Container Management

| Script | Description | Usage |
|--------|-------------|-------|
| [`k8s_resource_report.sh`](./k8s_resource_report.sh) | Comprehensive Kubernetes cluster resource explorer and reporter | `./k8s_resource_report.sh [--markdown] [--kubeconfig path]` |
| [`install_kubectl.sh`](./install_kubectl.sh) | Automated kubectl installation with shell completion setup | `./install_kubectl.sh` |
| [`uninstall_kubectl.sh`](./uninstall_kubectl.sh) | Clean removal of kubectl installation | `./uninstall_kubectl.sh` |
| [`install_docker.sh`](./install_docker.sh) | Automated Docker CE and Docker Compose installation for Ubuntu | `sudo ./install_docker.sh` |
| [`install_k9s.sh`](./install_k9s.sh) | Install K9s - terminal-based Kubernetes cluster management UI | `sudo ./install_k9s.sh [--version v0.32.7]` |
| [`kind_cluster_create.sh`](./kind_cluster_create.sh) | Create local Kubernetes cluster using Kind | `./kind_cluster_create.sh` |
| [`kind_cluster_remove.sh`](./kind_cluster_remove.sh) | Remove Kind cluster and cleanup | `./kind_cluster_remove.sh` |
| [`retrieve_kubeconfig.sh`](./retrieve_kubeconfig.sh) | Retrieve and configure kubeconfig for cluster access | `./retrieve_kubeconfig.sh` |

### Development Tools

| Script | Description | Usage |
|--------|-------------|-------|
| [`cleanup_intellij.sh`](./cleanup_intellij.sh) | Clean IntelliJ IDEA project files (.idea, .iml, build dirs) | `./cleanup_intellij.sh [-d project_directory]` |

## 🚀 Quick Start

### Prerequisites

Make sure the scripts are executable:

```bash
chmod +x *.sh
```

### Kubernetes Workflow Example

1. **Install Docker** (if not already installed):
   ```bash
   sudo ./install_docker.sh
   ```

2. **Install kubectl** (if not already installed):
   ```bash
   ./install_kubectl.sh
   ```

3. **Install K9s** for better cluster management:
   ```bash
   sudo ./install_k9s.sh
   ```

4. **Create a local cluster**:
   ```bash
   ./kind_cluster_create.sh
   ```

5. **Generate cluster resource report**:
   ```bash
   ./k8s_resource_report.sh --markdown --markdown-name my-cluster-report.md
   ```

6. **Explore cluster with K9s**:
   ```bash
   k9s
   ```

7. **Clean up when done**:
   ```bash
   ./kind_cluster_remove.sh
   ```

## 📖 Detailed Usage

### K8s Resource Report

The `k8s_resource_report.sh` script provides comprehensive cluster analysis:

```bash
# Basic cluster exploration
./k8s_resource_report.sh

# Generate markdown report
./k8s_resource_report.sh --markdown

# Use custom kubeconfig
./k8s_resource_report.sh --kubeconfig ~/.kube/my-config

# Install metrics server and generate report
./k8s_resource_report.sh --markdown --metrics-server
```

**Features:**
- Cluster information and node details
- Resource usage and capacity analysis
- Pod, service, and deployment inventory
- Storage and networking configuration
- Markdown report generation
- Metrics server integration

### Docker Management

```bash
# Install Docker CE and Docker Compose
sudo ./install_docker.sh
```

**Features:**
- Removes old Docker versions cleanly
- Installs latest Docker CE and CLI tools
- Installs Docker Compose v2.2.3
- Sets up proper permissions and services
- Provides verification and next steps

### K9s Management

```bash
# Install K9s with default version
sudo ./install_k9s.sh

# Install specific version
sudo ./install_k9s.sh --version v0.32.6
```

**Features:**
- Downloads and installs latest stable K9s version
- Validates installation and provides version info
- Includes helpful quick start commands
- Terminal-based Kubernetes cluster management UI

### Kubectl Management

```bash
# Install kubectl with shell completion
./install_kubectl.sh

# Remove kubectl completely
./uninstall_kubectl.sh
```

### Kind Cluster Management

```bash
# Create local cluster
./kind_cluster_create.sh

# Remove cluster and cleanup
./kind_cluster_remove.sh

# Retrieve kubeconfig after cluster creation
./retrieve_kubeconfig.sh
```

### Development Tools

#### IntelliJ Project Cleanup

```bash
# Clean current directory
./cleanup_intellij.sh

# Clean specific project directory
./cleanup_intellij.sh -d /path/to/project

# Clean current directory (explicit)
./cleanup_intellij.sh --directory
```

**Features:**
- Recursively removes .idea directories
- Deletes all .iml files
- Cleans build directories (out, target)
- Provides safety warnings and cleanup summary
- Supports custom project directory paths

## 🔧 Adding New Scripts

When adding new scripts to this collection:

1. **Make them executable**: `chmod +x script-name.sh`
2. **Add a shebang**: Start with `#!/bin/bash`
3. **Include error handling**: Use `set -e` for strict error handling
4. **Add help/usage**: Include `-h` or `--help` option
5. **Document in README**: Update this README with script description
6. **Follow naming convention**: Use descriptive names with underscores

### Script Template

```bash
#!/bin/bash

set -e

# Default values
DEFAULT_VALUE="example"

# Function to show help
show_help() {
    cat << EOF
Script Description

Usage: $0 [OPTIONS]

OPTIONS:
    -h, --help               Show this help message
    -v, --verbose            Enable verbose output

EXAMPLES:
    $0                       # Basic usage
    $0 --verbose             # With verbose output

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Main script logic here
echo "Script execution completed successfully!"
```

## 📂 Directory Structure

```
scripts/
├── README.md                    # This file
├── LICENSE                      # Apache License 2.0
├── .gitignore                   # Git ignore rules
├── k8s_resource_report.sh       # Kubernetes cluster analyzer
├── install_kubectl.sh           # kubectl installer
├── uninstall_kubectl.sh         # kubectl uninstaller
├── install_docker.sh            # Docker CE and Compose installer
├── install_k9s.sh               # K9s Kubernetes UI installer
├── kind_cluster_create.sh       # Kind cluster creator
├── kind_cluster_remove.sh       # Kind cluster remover
├── retrieve_kubeconfig.sh       # Kubeconfig retriever
└── cleanup_intellij.sh          # IntelliJ project cleanup tool
```

## 🛠️ Categories for Future Scripts

This repository is organized to accommodate various types of scripts:

- **🚢 Container & Orchestration**: Docker, Kubernetes, container management
- **☁️ Cloud & Infrastructure**: AWS, GCP, Azure, Terraform scripts
- **🔧 Development Tools**: Build scripts, testing utilities, linters
- **📊 Monitoring & Logging**: Health checks, log analysis, metrics collection
- **🔐 Security & Compliance**: Security scans, compliance checks, credential management
- **📦 Package Management**: Dependency management, version control
- **🗃️ Database & Storage**: Database operations, backup/restore scripts
- **🌐 Network & Connectivity**: Network diagnostics, connectivity tests
- **🔄 CI/CD & Automation**: Pipeline scripts, deployment automation
- **🧹 Maintenance & Cleanup**: System cleanup, log rotation, maintenance tasks


## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🔗 Useful Resources

- [Bash Best Practices](https://mywiki.wooledge.org/BashGuide/Practices)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Documentation](https://docs.docker.com/)
- [Shell Script Best Practices](https://github.com/anordal/shellharden/blob/master/how_to_do_things_safely_in_bash.md)

---

*This repository is designed to be a growing collection of useful scripts. Feel free to contribute and improve existing scripts or add new ones that could benefit the development workflow.*
