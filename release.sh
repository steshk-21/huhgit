#!/bin/bash

# huhgit Release Script
# This script builds and releases huhgit for multiple platforms

set -e  # Exit on any error

# Default values
VERSION=""
DRY_RUN=false
SKIP_TESTS=false
OUTPUT_DIR="dist"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to get version
get_version() {
    if [ -n "$VERSION" ]; then
        echo "$VERSION"
        return
    fi
    
    # Try to get version from git tags
    if command_exists git; then
        local latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
        if [ -n "$latest_tag" ]; then
            local version=$(echo "$latest_tag" | sed 's/^v//')
            print_color "$CYAN" "Using version from latest tag: $version"
            echo "$version"
            return
        fi
    fi
    
    print_color "$YELLOW" "No git tags found, using default version"
    echo "0.1.0"
}

# Function to test environment
test_environment() {
    print_color "$BLUE" "Checking environment..."
    
    if ! command_exists go; then
        print_color "$RED" "Error: Go is not installed or not in PATH"
        exit 1
    fi
    
    if ! command_exists git; then
        print_color "$RED" "Error: Git is not installed or not in PATH"
        exit 1
    fi
    
    local go_version=$(go version)
    print_color "$GREEN" "Go version: $go_version"
    
    # Check if we're in a git repository
    if [ ! -d ".git" ]; then
        print_color "$RED" "Error: Not in a git repository"
        exit 1
    fi
    
    # Check for uncommitted changes
    if [ "$DRY_RUN" = false ]; then
        local git_status=$(git status --porcelain)
        if [ -n "$git_status" ]; then
            print_color "$YELLOW" "Warning: You have uncommitted changes:"
            echo "$git_status"
            read -p "Continue anyway? (y/N): " response
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    fi
}

# Function to run tests
run_tests() {
    if [ "$SKIP_TESTS" = true ]; then
        print_color "$YELLOW" "Skipping tests..."
        return
    fi
    
    print_color "$BLUE" "Running tests..."
    
    # Set environment variables to avoid Android CGO issues
    GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go test ./...
    if [ $? -ne 0 ]; then
        print_color "$RED" "Tests failed!"
        exit 1
    fi
    print_color "$GREEN" "Tests passed!"
}

# Function to build binaries
build_binaries() {
    local version=$1
    
    print_color "$BLUE" "Building binaries for version $version..."
    
    # Create output directory
    if [ -d "$OUTPUT_DIR" ]; then
        rm -rf "$OUTPUT_DIR"
    fi
    mkdir -p "$OUTPUT_DIR"
    
    # Define build targets
    local targets=(
        "windows/amd64/huhgit-windows-amd64.exe"
        "windows/arm64/huhgit-windows-arm64.exe"
        "linux/amd64/huhgit-linux-amd64"
        "linux/arm64/huhgit-linux-arm64"
        "darwin/amd64/huhgit-darwin-amd64"
        "darwin/arm64/huhgit-darwin-arm64"
    )
    
    local ldflags="-X main.version=$version -s -w"
    
    for target in "${targets[@]}"; do
        IFS='/' read -r goos goarch name <<< "$target"
        
        print_color "$BLUE" "Building $name..."
        
        if [ "$DRY_RUN" = true ]; then
            print_color "$YELLOW" "DRY RUN: GOOS=$goos GOARCH=$goarch CGO_ENABLED=0 go build -ldflags \"$ldflags\" -o \"$OUTPUT_DIR/$name\" ."
        else
            GOOS=$goos GOARCH=$goarch CGO_ENABLED=0 go build -ldflags "$ldflags" -o "$OUTPUT_DIR/$name" .
            
            if [ $? -ne 0 ]; then
                print_color "$RED" "Failed to build $name"
                exit 1
            fi
            
            # Get file size
            local file_size=$(stat -f%z "$OUTPUT_DIR/$name" 2>/dev/null || stat -c%s "$OUTPUT_DIR/$name" 2>/dev/null || echo "0")
            local file_size_kb=$((file_size / 1024))
            print_color "$GREEN" "✓ Built $name ($file_size_kb KB)"
        fi
    done
}

# Function to create release
create_release() {
    local version=$1
    
    if [ "$DRY_RUN" = true ]; then
        print_color "$YELLOW" "DRY RUN: Would create GitHub release for version $version"
        return
    fi
    
    print_color "$BLUE" "Creating GitHub release..."
    
    # Check if GitHub CLI is available
    if command_exists gh; then
        local release_notes="## What's New in v$version

- Bug fixes and improvements
- Cross-platform binaries available

## Downloads

Binaries are available for:
- Windows (amd64, arm64)
- Linux (amd64, arm64) 
- macOS (amd64, arm64)

## Installation

Download the appropriate binary for your platform and add it to your PATH."
        
        # Build the gh command
        local gh_cmd="gh release create v$version --title \"Release v$version\" --notes \"$release_notes\""
        
        # Add all built binaries to the release
        for binary in "$OUTPUT_DIR"/*; do
            if [ -f "$binary" ]; then
                gh_cmd="$gh_cmd \"$binary\""
            fi
        done
        
        print_color "$BLUE" "Creating release with command: $gh_cmd"
        eval $gh_cmd
        
        if [ $? -eq 0 ]; then
            print_color "$GREEN" "✓ GitHub release created successfully!"
        else
            print_color "$RED" "Failed to create GitHub release"
            exit 1
        fi
    else
        print_color "$YELLOW" "GitHub CLI (gh) not found. Skipping automatic release creation."
        print_color "$BLUE" "You can manually create a release at: https://github.com/Cod-e-Codes/huhgit/releases/new"
        print_color "$BLUE" "Upload the following files:"
        for binary in "$OUTPUT_DIR"/*; do
            if [ -f "$binary" ]; then
                echo "  - $(basename "$binary")"
            fi
        done
    fi
}

# Function to show summary
show_summary() {
    local version=$1
    
    print_color "$BLUE" ""
    print_color "$BLUE" "=== Release Summary ==="
    print_color "$GREEN" "Version: $version"
    print_color "$GREEN" "Output Directory: $OUTPUT_DIR"
    
    if [ -d "$OUTPUT_DIR" ]; then
        print_color "$GREEN" "Built Binaries:"
        for binary in "$OUTPUT_DIR"/*; do
            if [ -f "$binary" ]; then
                local file_size=$(stat -f%z "$binary" 2>/dev/null || stat -c%s "$binary" 2>/dev/null || echo "0")
                local file_size_kb=$((file_size / 1024))
                echo "  - $(basename "$binary") ($file_size_kb KB)"
            fi
        done
    fi
    
    print_color "$BLUE" ""
    print_color "$BLUE" "Next Steps:"
    echo "1. Test the binaries on different platforms"
    echo "2. Create a GitHub release (if not done automatically)"
    echo "3. Update documentation with new version"
    echo "4. Announce the release"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -v, --version VERSION    Specify version (default: auto-detect from git tags)"
    echo "  -d, --dry-run           Show what would be done without making changes"
    echo "  -s, --skip-tests        Skip running tests"
    echo "  -o, --output DIR        Output directory (default: dist)"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                      # Basic release with auto-detected version"
    echo "  $0 -v 1.0.0            # Release with specific version"
    echo "  $0 --dry-run           # Test the script without making changes"
    echo "  $0 --skip-tests        # Build without running tests"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -s|--skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_color "$RED" "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main execution
main() {
    print_color "$CYAN" "huhgit Release Script"
    print_color "$CYAN" "===================="
    
    local version=$(get_version)
    print_color "$BLUE" "Release version: $version"
    
    if [ "$DRY_RUN" = true ]; then
        print_color "$YELLOW" "DRY RUN MODE - No actual changes will be made"
    fi
    
    test_environment
    run_tests
    build_binaries "$version"
    create_release "$version"
    show_summary "$version"
    
    print_color "$GREEN" ""
    print_color "$GREEN" "Release process completed successfully!"
}

# Run main function
main
