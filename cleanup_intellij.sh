#!/bin/bash

set -e

# Default to current directory
PROJECT_DIR="$(pwd)"

print_help() {
    cat << EOF
Project Cleanup Script for IntelliJ Projects

This script recursively cleans up IntelliJ IDEA-related files and build artifacts.
It removes the following from the specified directory (or current directory by default):
  - .idea directories
  - *.iml files
  - out and target directories

Usage: $0 [OPTIONS]

OPTIONS:
    -d, --directory DIR      Specify the project directory (default: current directory)
                            If used without an argument, the current directory is assumed.
    -h, --help              Show this help message and exit

EXAMPLES:
    $0                      # Clean current directory
    $0 -d /path/to/project  # Clean specific directory
    $0 --directory          # Clean current directory (explicit)

SAFETY:
    This script will permanently delete files and directories.
    Make sure you have backups if needed before running.

EOF
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -d|--directory)
            # Check if next argument is another flag or empty
            if [[ -n "$2" && "$2" != -* ]]; then
                PROJECT_DIR="$2"
                shift
            else
                PROJECT_DIR="$(pwd)"
            fi
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
    shift
done

# Validate directory exists
if [[ ! -d "$PROJECT_DIR" ]]; then
    echo "❌ Error: Directory does not exist: $PROJECT_DIR"
    exit 1
fi

echo "🧹 IntelliJ Project Cleanup Script"
echo "📁 Using project directory: $PROJECT_DIR"
echo ""

# Step 1: Delete .idea directory and all *.iml files
echo "🗂️  Deleting .idea directories..."
IDEA_DIRS=$(find "$PROJECT_DIR" -name ".idea" -type d 2>/dev/null | wc -l)
if [[ $IDEA_DIRS -gt 0 ]]; then
    find "$PROJECT_DIR" -name ".idea" -type d -exec rm -rf {} + 2>/dev/null || true
    echo "   ✅ Removed $IDEA_DIRS .idea directories"
else
    echo "   ℹ️  No .idea directories found"
fi

echo "📄 Deleting *.iml files..."
IML_FILES=$(find "$PROJECT_DIR" -name "*.iml" -type f 2>/dev/null | wc -l)
if [[ $IML_FILES -gt 0 ]]; then
    find "$PROJECT_DIR" -name "*.iml" -type f -exec rm -f {} + 2>/dev/null || true
    echo "   ✅ Removed $IML_FILES .iml files"
else
    echo "   ℹ️  No .iml files found"
fi

# Step 2: Delete out and target directories
echo "🏗️  Deleting build directories (out, target)..."
BUILD_DIRS=$(find "$PROJECT_DIR" \( -name "out" -o -name "target" \) -type d 2>/dev/null | wc -l)
if [[ $BUILD_DIRS -gt 0 ]]; then
    find "$PROJECT_DIR" \( -name "out" -o -name "target" \) -type d -exec rm -rf {} + 2>/dev/null || true
    echo "   ✅ Removed $BUILD_DIRS build directories"
else
    echo "   ℹ️  No build directories found"
fi

echo ""
echo "🎉 Cleanup completed successfully!"
echo ""
echo "💡 Summary of cleaned items:"
echo "   - .idea directories: $IDEA_DIRS"
echo "   - .iml files: $IML_FILES"  
echo "   - build directories: $BUILD_DIRS"
