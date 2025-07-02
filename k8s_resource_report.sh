#!/bin/bash

# Default values
# Use KUBECONFIG env var if set, otherwise try ./kubeconfig.yaml
if [[ -n "$KUBECONFIG" ]]; then
    DEFAULT_KUBECONFIG="$KUBECONFIG"
elif [[ -f "./kubeconfig.yaml" ]]; then
    DEFAULT_KUBECONFIG="./kubeconfig.yaml"
else
    DEFAULT_KUBECONFIG=""
fi

DEFAULT_MARKDOWN_FILE="k8s_resources_report.md"
KUBECONFIG_PATH="$DEFAULT_KUBECONFIG"
MARKDOWN_OUTPUT=false
MARKDOWN_FILE=""
INSTALL_METRICS_SERVER=false
CONVERT_TO_PDF=false

# Function to show help
show_help() {
    local default_display="KUBECONFIG env var → ./kubeconfig.yaml → fail"
    if [[ -n "$DEFAULT_KUBECONFIG" ]]; then
        default_display="$DEFAULT_KUBECONFIG"
    fi
    
    cat << EOF
Kubernetes Cluster Explorer

Usage: $0 [OPTIONS]

OPTIONS:
    -k, --kubeconfig PATH    Path to kubeconfig file (default: $default_display)
    -md, --markdown          Output in markdown format
    -mn, --markdown-name     Markdown output file name (default: $DEFAULT_MARKDOWN_FILE)
    -pdf, --pdf              Convert markdown to PDF (requires pandoc)
    -m, --metrics-server     Install metrics server if not present (for resource usage data)
    -h, --help               Show this help message

EXAMPLES:
    $0                                          # Basic cluster exploration
    $0 --markdown                               # Generate markdown report (saves to $DEFAULT_MARKDOWN_FILE)
    $0 -k ~/.kube/config                        # Use custom kubeconfig
    $0 --kubeconfig /path/to/config --markdown  # Custom kubeconfig with markdown output
    $0 --markdown --markdown-name my-report.md  # Custom markdown file name
    $0 --metrics-server                         # Install metrics server for resource usage data
    $0 --markdown --metrics-server              # Generate report with metrics server installation
    $0 --markdown --pdf                         # Generate markdown report and convert to PDF
    $0 --markdown --pdf --markdown-name report.md  # Custom markdown file name and convert to PDF

KUBECONFIG PRIORITY:
    1. Command line argument (-k/--kubeconfig)
    2. KUBECONFIG environment variable
    3. ./kubeconfig.yaml (if exists)
    4. Fail with error

REQUIREMENTS FOR PDF CONVERSION:
    Linux: sudo apt install pandoc wkhtmltopdf
    macOS:  brew install pandoc wkhtmltopdf
    - pandoc is required for markdown to PDF conversion
    - wkhtmltopdf is recommended for better PDF formatting

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -k|--kubeconfig)
            KUBECONFIG_PATH="$2"
            shift 2
            ;;
        -md|--markdown)
            MARKDOWN_OUTPUT=true
            shift
            ;;
        -mn|--markdown-name)
            MARKDOWN_FILE="$2"
            shift 2
            ;;
        -pdf|--pdf)
            CONVERT_TO_PDF=true
            # PDF conversion requires markdown output
            MARKDOWN_OUTPUT=true
            shift
            ;;
        -m|--metrics-server)
            INSTALL_METRICS_SERVER=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Validate kubeconfig file exists
if [[ -z "$KUBECONFIG_PATH" ]]; then
    echo "Error: No kubeconfig file found."
    echo "Set KUBECONFIG environment variable or ensure ./kubeconfig.yaml exists"
    echo "Use -k or --kubeconfig to specify a valid path"
    exit 1
elif [[ ! -f "$KUBECONFIG_PATH" ]]; then
    echo "Error: Kubeconfig file not found: $KUBECONFIG_PATH"
    echo "Use -k or --kubeconfig to specify a valid path"
    exit 1
fi

# Set default markdown file name if not specified
if [[ "$MARKDOWN_OUTPUT" == "true" && -z "$MARKDOWN_FILE" ]]; then
    MARKDOWN_FILE="$DEFAULT_MARKDOWN_FILE"
fi

# Set kubeconfig
export KUBECONFIG="$KUBECONFIG_PATH"

# Function to check and install metrics server
install_metrics_server() {
    echo "Checking if metrics server is installed..."
    if ! kubectl get deployment metrics-server -n kube-system &>/dev/null; then
        echo "Installing metrics server..."
        kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
        echo "Patching metrics server for kind cluster..."
        kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
        echo "Waiting for metrics server to be ready..."
        kubectl wait --for=condition=available --timeout=120s deployment/metrics-server -n kube-system
    else
        echo "Metrics server is already installed."
    fi
}

# Function to convert markdown to PDF
convert_to_pdf() {
    local markdown_file="$1"
    local pdf_file="${markdown_file%.md}.pdf"
    
    echo "Converting markdown to PDF..."
    
    # Check if pandoc is installed
    if ! command -v pandoc &> /dev/null; then
        echo "Error: pandoc is not installed."
        # Detect OS and provide appropriate installation instructions
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "Install pandoc on macOS with: brew install pandoc"
            echo "For better PDF formatting, also install: brew install wkhtmltopdf"
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            echo "Install pandoc on Linux with: sudo apt install pandoc"
            echo "For better PDF formatting, also install: sudo apt install wkhtmltopdf"
        else
            echo "Install pandoc for your system. Visit: https://pandoc.org/installing.html"
        fi
        return 1
    fi
    
    # Try to convert with wkhtmltopdf engine first (better formatting)
    if command -v wkhtmltopdf &> /dev/null; then
        echo "Using wkhtmltopdf engine for better PDF formatting..."
        
        # Create a temporary CSS file for better cross-platform compatibility
        local temp_css=$(mktemp)
        cat > "$temp_css" << 'EOF'
body { 
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; 
    margin: 40px; 
    line-height: 1.6;
}
pre { 
    background-color: #f5f5f5; 
    padding: 10px; 
    border-radius: 5px; 
    overflow-x: auto; 
    font-family: 'SF Mono', Monaco, 'Cascadia Code', 'Roboto Mono', Consolas, 'Courier New', monospace;
}
code { 
    background-color: #f5f5f5; 
    padding: 2px 4px; 
    border-radius: 3px; 
    font-family: 'SF Mono', Monaco, 'Cascadia Code', 'Roboto Mono', Consolas, 'Courier New', monospace;
}
h1, h2, h3 { 
    color: #2c3e50; 
    margin-top: 2em;
    margin-bottom: 1em;
}
table { 
    border-collapse: collapse; 
    width: 100%; 
    margin: 1em 0;
}
th, td { 
    border: 1px solid #ddd; 
    padding: 8px; 
    text-align: left; 
}
th { 
    background-color: #f2f2f2; 
    font-weight: bold;
}
EOF
        
        pandoc "$markdown_file" -f markdown -t html5 --pdf-engine=wkhtmltopdf \
            --css "$temp_css" \
            --pdf-engine-opt=--page-size --pdf-engine-opt=A4 \
            --pdf-engine-opt=--margin-top --pdf-engine-opt=20mm \
            --pdf-engine-opt=--margin-bottom --pdf-engine-opt=20mm \
            --pdf-engine-opt=--margin-left --pdf-engine-opt=15mm \
            --pdf-engine-opt=--margin-right --pdf-engine-opt=15mm \
            -o "$pdf_file" 2>/dev/null
        
        # Clean up temporary CSS file
        rm -f "$temp_css"
    else
        echo "Using default PDF engine..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "For better formatting on macOS, install: brew install wkhtmltopdf"
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            echo "For better formatting on Linux, install: sudo apt install wkhtmltopdf"
        fi
        pandoc "$markdown_file" -f markdown -t pdf -o "$pdf_file"
    fi
    
    if [[ $? -eq 0 ]]; then
        echo "PDF report saved to: $pdf_file"
        return 0
    else
        echo "Error: Failed to convert markdown to PDF"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "On macOS, you might also try: brew install --cask basictex"
        fi
        return 1
    fi
}

# Install metrics server if needed
if [[ "$INSTALL_METRICS_SERVER" == "true" ]]; then
    install_metrics_server
fi

# Function to run the main script content
run_cluster_exploration() {
if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo "# Kubernetes Cluster Report"
    echo "Generated on: $(date)"
    echo "Kubeconfig: $KUBECONFIG_PATH"
    echo ""
else
    echo "=== Kubernetes Cluster Explorer ==="
    echo "Using kubeconfig: $KUBECONFIG_PATH"
    echo ""
fi

if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo "## 1. Cluster Information"
    echo '```'
else
    echo "1. Cluster Info:"
fi
kubectl cluster-info
if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo '```'
fi
echo ""

if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo "## 2. Nodes"
    echo '```'
else
    echo "2. Nodes:"
fi
kubectl get nodes -o wide
if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo '```'
fi
echo ""

if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo "## 3. Namespaces"
    echo '```'
else
    echo "3. Namespaces:"
fi
kubectl get namespaces
if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo '```'
fi
echo ""

if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo "## 4. All Pods"
    echo '```'
else
    echo "4. All Pods:"
fi
kubectl get pods --all-namespaces -o wide
if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo '```'
fi
echo ""

if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo "## 5. Services"
    echo '```'
else
    echo "5. Services:"
fi
kubectl get services --all-namespaces
if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo '```'
fi
echo ""

if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo "## 6. Deployments"
    echo '```'
else
    echo "6. Deployments:"
fi
kubectl get deployments --all-namespaces
if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo '```'
fi
echo ""

if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo "## 7. Storage Classes"
    echo '```'
else
    echo "7. Storage Classes:"
fi
kubectl get storageclass
if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo '```'
fi
echo ""

if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo "## 8. Persistent Volumes"
    echo '```'
else
    echo "8. Persistent Volumes:"
fi
kubectl get pv
if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo '```'
fi
echo ""

if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo "## 9. ConfigMaps"
    echo '```'
else
    echo "9. ConfigMaps:"
fi
kubectl get configmaps --all-namespaces
if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo '```'
fi
echo ""

if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo "## 10. Secrets"
    echo '```'
else
    echo "10. Secrets:"
fi
kubectl get secrets --all-namespaces
if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo '```'
fi
echo ""

if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo "## Resource Summary"
    echo '```'
else
    echo "=== Quick Resource Summary ==="
fi
kubectl top nodes 2>/dev/null || echo "Metrics server not available"
if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo '```'
fi
echo ""

if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo "## Compute Resources"
    echo ""
    echo "### Node Capacity and Allocatable Resources"
    echo '```'
else
    echo "=== Compute Resources ==="
    echo "Node Resource Capacity and Allocatable:"
fi
kubectl describe nodes | grep -E "(Name:|Capacity:|Allocatable:)" -A 10
if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo '```'
fi
echo ""

if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo "### Resource Requests and Limits by Pod"
    echo '```'
else
    echo "Resource Requests and Limits by Namespace:"
fi
kubectl get pods --all-namespaces -o=jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\t"}{.spec.containers[*].resources.requests.cpu}{"\t"}{.spec.containers[*].resources.requests.memory}{"\t"}{.spec.containers[*].resources.limits.cpu}{"\t"}{.spec.containers[*].resources.limits.memory}{"\n"}{end}' | column -t -s $'\t' | head -20
if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo '```'
fi
echo ""

if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo "### Current Resource Usage"
    echo '```'
else
    echo "Node Resource Usage (if metrics-server is available):"
fi
kubectl top pods --all-namespaces 2>/dev/null || echo "Metrics server not available - install with: kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml"
if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo '```'
fi
echo ""

if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo "## Storage Information"
    echo ""
    echo "### Persistent Volume Claims"
    echo '```'
else
    echo "Persistent Volume Claims:"
fi
kubectl get pvc --all-namespaces
if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo '```'
fi
echo ""

if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo "### Storage Usage"
    echo '```'
else
    echo "Storage Usage:"
fi
kubectl get pv -o custom-columns=NAME:.metadata.name,CAPACITY:.spec.capacity.storage,ACCESS:.spec.accessModes,STATUS:.status.phase,CLAIM:.spec.claimRef.name
if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo '```'
fi
echo ""

# Additional Resource Management Commands
if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo "## Additional Resource Management Information"
    echo ""
    echo "### Resource Quotas"
    echo '```'
else
    echo "=== Additional Resource Management ==="
    echo "Resource Quotas:"
fi
kubectl get resourcequota --all-namespaces
if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo '```'
fi
echo ""

if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo "### Limit Ranges"
    echo '```'
else
    echo "Limit Ranges:"
fi
kubectl get limitrange --all-namespaces
if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo '```'
fi
echo ""

if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo "### Network Policies"
    echo '```'
else
    echo "Network Policies:"
fi
kubectl get networkpolicies --all-namespaces
if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo '```'
fi
echo ""

if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo "### Ingress Controllers"
    echo '```'
else
    echo "Ingress Controllers:"
fi
kubectl get ingress --all-namespaces
if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo '```'
fi
echo ""

if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo "## Available API Resources"
    echo '```'
else
    echo "=== Available API Resources ==="
fi
kubectl api-resources --verbs=list --namespaced -o name | head -20
echo "... (run 'kubectl api-resources' for full list)"
if [[ "$MARKDOWN_OUTPUT" == "true" ]]; then
    echo '```'
    echo ""
    echo "## Useful Commands for Resource Management"
    echo ""
    echo '```bash'
    echo "# Monitor resource usage in real-time"
    echo "watch kubectl top pods --all-namespaces"
    echo ""
    echo "# Get detailed resource information for a specific pod"
    echo "kubectl describe pod <pod-name> -n <namespace>"
    echo ""
    echo "# Check events across all namespaces"
    echo "kubectl get events --all-namespaces --sort-by='.lastTimestamp'"
    echo ""
    echo "# Get resource usage by node"
    echo "kubectl top nodes"
    echo ""
    echo "# List all containers and their resource requests/limits"
    echo "kubectl get pods --all-namespaces -o=jsonpath='{range .items[*]}{.metadata.namespace}{\"/\"}{.metadata.name}{\"\\n\"}{range .spec.containers[*]}{\"  Container: \"}{.name}{\"\\n\"}{\"  CPU Request: \"}{.resources.requests.cpu}{\"\\n\"}{\"  Memory Request: \"}{.resources.requests.memory}{\"\\n\"}{\"  CPU Limit: \"}{.resources.limits.cpu}{\"\\n\"}{\"  Memory Limit: \"}{.resources.limits.memory}{\"\\n\"}{end}{\"\\n\"}{end}'"
    echo ""
    echo "# Generate cluster resource report"
    echo "./k8s-explore.sh --markdown --markdown-name k8s_resources_report.md"
    echo '```'
fi
}

# Execute the cluster exploration
if [[ "$MARKDOWN_OUTPUT" == "true" && -n "$MARKDOWN_FILE" ]]; then
    echo "Generating markdown report: $MARKDOWN_FILE"
    run_cluster_exploration > "$MARKDOWN_FILE"
    echo "Report saved to: $MARKDOWN_FILE"
    
    # Convert to PDF if requested
    if [[ "$CONVERT_TO_PDF" == "true" ]]; then
        convert_to_pdf "$MARKDOWN_FILE"
    fi
else
    run_cluster_exploration
fi
