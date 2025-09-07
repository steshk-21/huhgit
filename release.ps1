# huhgit Release Script
# This script builds and releases huhgit for multiple platforms

param(
    [string]$Version = "",
    [switch]$DryRun = $false,
    [switch]$SkipTests = $false,
    [string]$OutputDir = "dist"
)

# Colors for output
$ErrorColor = "Red"
$SuccessColor = "Green"
$InfoColor = "Cyan"
$WarningColor = "Yellow"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Test-Command {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

function Get-Version {
    if ($Version) {
        return $Version
    }
    
    # Try to get version from git tags
    try {
        $latestTag = git describe --tags --abbrev=0 2>$null
        if ($latestTag) {
            $version = $latestTag.TrimStart('v')
            Write-ColorOutput "Using version from latest tag: $version" $InfoColor
            return $version
        }
    }
    catch {
        Write-ColorOutput "No git tags found, using default version" $WarningColor
    }
    
    return "0.1.0"
}

function Test-Environment {
    Write-ColorOutput "Checking environment..." $InfoColor
    
    if (-not (Test-Command "go")) {
        Write-ColorOutput "Error: Go is not installed or not in PATH" $ErrorColor
        exit 1
    }
    
    if (-not (Test-Command "git")) {
        Write-ColorOutput "Error: Git is not installed or not in PATH" $ErrorColor
        exit 1
    }
    
    $goVersion = go version
    Write-ColorOutput "Go version: $goVersion" $SuccessColor
    
    # Check if we're in a git repository
    if (-not (Test-Path ".git")) {
        Write-ColorOutput "Error: Not in a git repository" $ErrorColor
        exit 1
    }
    
    # Check for uncommitted changes
    $gitStatus = git status --porcelain
    if ($gitStatus -and -not $DryRun) {
        Write-ColorOutput "Warning: You have uncommitted changes:" $WarningColor
        Write-Host $gitStatus
        $response = Read-Host "Continue anyway? (y/N)"
        if ($response -ne "y" -and $response -ne "Y") {
            exit 1
        }
    }
}

function Invoke-Tests {
    if ($SkipTests) {
        Write-ColorOutput "Skipping tests..." $WarningColor
        return
    }
    
    Write-ColorOutput "Running tests..." $InfoColor
    go test ./...
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "Tests failed!" $ErrorColor
        exit 1
    }
    Write-ColorOutput "Tests passed!" $SuccessColor
}

function Build-Binaries {
    param([string]$Version)
    
    Write-ColorOutput "Building binaries for version $Version..." $InfoColor
    
    # Create output directory
    if (Test-Path $OutputDir) {
        Remove-Item $OutputDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
    
    # Define build targets
    $targets = @(
        @{ GOOS = "windows"; GOARCH = "amd64"; EXT = ".exe"; NAME = "huhgit-windows-amd64.exe" },
        @{ GOOS = "windows"; GOARCH = "arm64"; EXT = ".exe"; NAME = "huhgit-windows-arm64.exe" },
        @{ GOOS = "linux"; GOARCH = "amd64"; EXT = ""; NAME = "huhgit-linux-amd64" },
        @{ GOOS = "linux"; GOARCH = "arm64"; EXT = ""; NAME = "huhgit-linux-arm64" },
        @{ GOOS = "darwin"; GOARCH = "amd64"; EXT = ""; NAME = "huhgit-darwin-amd64" },
        @{ GOOS = "darwin"; GOARCH = "arm64"; EXT = ""; NAME = "huhgit-darwin-arm64" },
        @{ GOOS = "android"; GOARCH = "arm64"; EXT = ""; NAME = "huhgit-android-arm64" },
        @{ GOOS = "android"; GOARCH = "amd64"; EXT = ""; NAME = "huhgit-android-amd64" }
    )
    
    $ldflags = "-X main.version=$Version -s -w"
    
    foreach ($target in $targets) {
        Write-ColorOutput "Building $($target.NAME)..." $InfoColor
        
        $env:GOOS = $target.GOOS
        $env:GOARCH = $target.GOARCH
        $env:CGO_ENABLED = "0"
        
        $outputPath = Join-Path $OutputDir $target.NAME
        
        $buildCmd = "go build -ldflags `"$ldflags`" -o `"$outputPath`" ."
        
        if ($DryRun) {
            Write-ColorOutput "DRY RUN: $buildCmd" $WarningColor
        } else {
            Invoke-Expression $buildCmd
            if ($LASTEXITCODE -ne 0) {
                Write-ColorOutput "Failed to build $($target.NAME)" $ErrorColor
                exit 1
            }
            
            # Get file size
            $fileSize = (Get-Item $outputPath).Length
            $fileSizeKB = [math]::Round($fileSize / 1KB, 2)
            Write-ColorOutput "✓ Built $($target.NAME) ($fileSizeKB KB)" $SuccessColor
        }
    }
    
    # Reset environment variables
    Remove-Item Env:GOOS -ErrorAction SilentlyContinue
    Remove-Item Env:GOARCH -ErrorAction SilentlyContinue
    Remove-Item Env:CGO_ENABLED -ErrorAction SilentlyContinue
}

function New-Release {
    param([string]$Version)
    
    if ($DryRun) {
        Write-ColorOutput "DRY RUN: Would create GitHub release for version $Version" $WarningColor
        return
    }
    
    Write-ColorOutput "Creating GitHub release..." $InfoColor
    
    # Check if GitHub CLI is available
    if (Test-Command "gh") {
        $releaseNotes = @"
## What's New in v$Version

- Bug fixes and improvements
- Cross-platform binaries available
- Android support added

## Downloads

Binaries are available for:
- Windows (amd64, arm64)
- Linux (amd64, arm64) 
- macOS (amd64, arm64)
- Android (arm64, amd64)

## Installation

Download the appropriate binary for your platform and add it to your PATH.

### Android Installation
For Android devices, you can install the binary using Termux or similar terminal emulator:
1. Download the appropriate Android binary
2. Transfer to your device
3. Make executable: `chmod +x huhgit-android-*`
4. Run: `./huhgit-android-*`
"@
        
        $releaseCmd = "gh release create v$Version --title `"Release v$Version`" --notes `"$releaseNotes`""
        
        # Add all built binaries to the release
        $binaries = Get-ChildItem $OutputDir -File
        foreach ($binary in $binaries) {
            $releaseCmd += " `"$($binary.FullName)`""
        }
        
        Write-ColorOutput "Creating release with command: $releaseCmd" $InfoColor
        Invoke-Expression $releaseCmd
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✓ GitHub release created successfully!" $SuccessColor
        } else {
            Write-ColorOutput "Failed to create GitHub release" $ErrorColor
            exit 1
        }
    } else {
        Write-ColorOutput "GitHub CLI (gh) not found. Skipping automatic release creation." $WarningColor
        Write-ColorOutput "You can manually create a release at: https://github.com/Cod-e-Codes/huhgit/releases/new" $InfoColor
        Write-ColorOutput "Upload the following files:" $InfoColor
        Get-ChildItem $OutputDir -File | ForEach-Object { Write-Host "  - $($_.Name)" }
    }
}

function Show-Summary {
    param([string]$Version)
    
    Write-ColorOutput "`n=== Release Summary ===" $InfoColor
    Write-ColorOutput "Version: $Version" $SuccessColor
    Write-ColorOutput "Output Directory: $OutputDir" $SuccessColor
    
    if (Test-Path $OutputDir) {
        $binaries = Get-ChildItem $OutputDir -File
        Write-ColorOutput "Built Binaries:" $SuccessColor
        foreach ($binary in $binaries) {
            $size = [math]::Round($binary.Length / 1KB, 2)
            Write-Host "  - $($binary.Name) ($size KB)"
        }
    }
    
    Write-ColorOutput "`nNext Steps:" $InfoColor
    Write-Host "1. Test the binaries on different platforms"
    Write-Host "2. Create a GitHub release (if not done automatically)"
    Write-Host "3. Update documentation with new version"
    Write-Host "4. Announce the release"
}

# Main execution
try {
    Write-ColorOutput "huhgit Release Script" $InfoColor
    Write-ColorOutput "====================" $InfoColor
    
    $version = Get-Version
    Write-ColorOutput "Release version: $version" $InfoColor
    
    if ($DryRun) {
        Write-ColorOutput "DRY RUN MODE - No actual changes will be made" $WarningColor
    }
    
    Test-Environment
    Invoke-Tests
    Build-Binaries -Version $version
    New-Release -Version $version
    Show-Summary -Version $version
    
    Write-ColorOutput "`nRelease process completed successfully!" $SuccessColor
}
catch {
    Write-ColorOutput "`nRelease process failed: $($_.Exception.Message)" $ErrorColor
    exit 1
}
